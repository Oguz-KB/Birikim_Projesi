from fastapi import APIRouter, HTTPException, Depends, Header, status, Response
from sqlalchemy.orm import Session
from sqlalchemy import select
from typing import List, Union
from pydantic import UUID4

from app.db import get_db
from app.schemas.transaction import TransactionCreate, TransactionOut, WithdrawCreate
from app.schemas.pending_purchase import PendingPurchaseOut
import app.models as models
from app.rule_engine import (
    RuleSettings, CategoryInfo, apply_rules,
    should_enter_waiting_room, waiting_room_expiry
)

router = APIRouter(prefix="/transactions", tags=["transactions"])

@router.post("/", response_model=Union[PendingPurchaseOut, TransactionOut], status_code=status.HTTP_201_CREATED)
def create_transaction(
    transaction: TransactionCreate, 
    response: Response,
    x_user_id: UUID4 = Header(...),
    db: Session = Depends(get_db)
):
    # Fetch active user settings
    stmt_settings = select(models.UserRuleSettings).where(
        models.UserRuleSettings.user_id == x_user_id,
        models.UserRuleSettings.valid_to.is_(None)
    )
    user_settings = db.execute(stmt_settings).scalar_one_or_none()
    
    if not user_settings:
        raise HTTPException(status_code=404, detail="Active user settings not found")
        
    # Fetch category
    category = db.get(models.Category, transaction.category_id)
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
        
    rs = RuleSettings(
        self_tax_rate=user_settings.self_tax_rate,
        roundup_enabled=user_settings.roundup_enabled,
        roundup_unit=user_settings.roundup_unit,
        waiting_room_hours=user_settings.waiting_room_hours,
        waiting_room_threshold=user_settings.waiting_room_threshold,
    )
    
    cat_info = CategoryInfo(
        is_guilty_pleasure=category.is_guilty_pleasure,
        penalty_multiplier=category.penalty_multiplier
    )

    if should_enter_waiting_room(transaction.raw_amount, rs):
        expires_at = waiting_room_expiry(rs)
        pending = models.PendingPurchase(
            user_id=x_user_id,
            category_id=category.id,
            amount=transaction.raw_amount,
            expires_at=expires_at,
            resolution='pending'
        )
        db.add(pending)
        db.commit()
        db.refresh(pending)
        response.status_code = status.HTTP_202_ACCEPTED
        return pending

    # Otherwise, apply rules and create transaction
    breakdown = apply_rules(transaction.raw_amount, rs, cat_info)
    
    new_tx = models.Transaction(
        user_id=x_user_id,
        category_id=category.id,
        raw_amount=breakdown.raw_amount,
        self_tax_amount=breakdown.self_tax_amount,
        roundup_amount=breakdown.roundup_amount,
        total_diverted=breakdown.total_diverted,
        rule_settings_id=user_settings.id,
        source='self_tax'
    )
    db.add(new_tx)
    db.commit()
    db.refresh(new_tx)
    
    return new_tx

@router.get("/", response_model=List[TransactionOut])
def get_transactions(
    skip: int = 0, 
    limit: int = 100, 
    x_user_id: UUID4 = Header(...),
    db: Session = Depends(get_db)
):
    stmt = select(models.Transaction).where(models.Transaction.user_id == x_user_id).offset(skip).limit(limit)
    transactions = db.execute(stmt).scalars().all()
    return transactions

@router.post("/withdraw", response_model=TransactionOut, status_code=status.HTTP_201_CREATED)
def withdraw_savings(
    withdraw: WithdrawCreate,
    x_user_id: UUID4 = Header(...),
    db: Session = Depends(get_db)
):
    # Fetch active user settings to link the transaction
    stmt_settings = select(models.UserRuleSettings).where(
        models.UserRuleSettings.user_id == x_user_id,
        models.UserRuleSettings.valid_to.is_(None)
    )
    user_settings = db.execute(stmt_settings).scalar_one_or_none()
    
    if not user_settings:
        raise HTTPException(status_code=404, detail="Active user settings not found")
        
    # We need a dummy category for withdrawals, or we can use the first category available
    # A cleaner way is to create a "Withdrawal" category, but for now we can just pick the first global category.
    # In Phase 2 we will clean up categories. Let's just get any category.
    stmt_cat = select(models.Category).limit(1)
    category = db.execute(stmt_cat).scalar_one_or_none()
    
    if not category:
        raise HTTPException(status_code=404, detail="No category found")

    new_tx = models.Transaction(
        user_id=x_user_id,
        category_id=category.id,
        raw_amount=0,  # It's not a real expense
        self_tax_amount=0,
        roundup_amount=0,
        total_diverted=-abs(withdraw.amount),  # Negative value deducts from total savings
        rule_settings_id=user_settings.id,
        source='self_tax',  # Using 'self_tax' to satisfy DB CheckConstraint ("source IN ('self_tax', 'abandoned_purchase')")
        goal_id=withdraw.goal_id
    )
    
    db.add(new_tx)
    
    if withdraw.goal_id:
        goal = db.get(models.Goal, withdraw.goal_id)
        if goal and goal.owner_user_id == x_user_id:
            goal.is_completed = True
            
    db.commit()
    db.refresh(new_tx)
    
    return new_tx
