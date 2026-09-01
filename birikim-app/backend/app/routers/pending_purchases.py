from fastapi import APIRouter, HTTPException, Depends, Header
from sqlalchemy.orm import Session
from sqlalchemy import select
from typing import List
from pydantic import BaseModel, UUID4
from datetime import datetime, timezone

from app.db import get_db
from app.schemas.pending_purchase import PendingPurchaseOut
import app.models as models
from app.rule_engine import (
    RuleSettings, CategoryInfo, apply_rules, resolve_abandoned_purchase
)
from app.services.pending_purchases import write_abandoned_transaction

router = APIRouter(prefix="/pending-purchases", tags=["pending_purchases"])

class ResolveRequest(BaseModel):
    decision: str  # 'purchased' or 'abandoned'

@router.get("/", response_model=List[PendingPurchaseOut])
def get_pending_purchases(
    skip: int = 0, 
    limit: int = 100, 
    x_user_id: UUID4 = Header(...),
    db: Session = Depends(get_db)
):
    stmt = select(models.PendingPurchase).where(models.PendingPurchase.user_id == x_user_id).offset(skip).limit(limit)
    return db.execute(stmt).scalars().all()

@router.post("/{purchase_id}/resolve", response_model=PendingPurchaseOut)
def resolve_pending_purchase(
    purchase_id: UUID4, 
    req: ResolveRequest, 
    x_user_id: UUID4 = Header(...),
    db: Session = Depends(get_db)
):
    if req.decision not in ('purchased', 'abandoned'):
        raise HTTPException(status_code=422, detail="decision must be 'purchased' or 'abandoned'")

    pending = db.get(models.PendingPurchase, purchase_id)
    if not pending or pending.user_id != x_user_id:
        raise HTTPException(status_code=404, detail="Pending purchase not found")

    if pending.resolution != 'pending':
        raise HTTPException(status_code=409, detail="Purchase already resolved")

    # Fetch active user settings
    stmt_settings = select(models.UserRuleSettings).where(
        models.UserRuleSettings.user_id == x_user_id,
        models.UserRuleSettings.valid_to.is_(None)
    )
    user_settings = db.execute(stmt_settings).scalar_one_or_none()
    if not user_settings:
        raise HTTPException(status_code=404, detail="Active user settings not found")

    new_tx = None
    if req.decision == 'purchased':
        category = db.get(models.Category, pending.category_id)
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
        breakdown = apply_rules(pending.amount, rs, cat_info)
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
    elif req.decision == 'abandoned':
        new_tx = write_abandoned_transaction(db, pending, user_settings)

    db.add(new_tx)
    db.flush() # get new_tx.id

    pending.resolution = req.decision
    pending.resolved_at = datetime.now(timezone.utc)
    pending.resulting_transaction_id = new_tx.id

    db.commit()
    db.refresh(pending)
    return pending
