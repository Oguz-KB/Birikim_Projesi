from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from sqlalchemy import select
from datetime import datetime, timezone
from pydantic import UUID4

from app.db import get_db
from app.schemas.user import UserRuleSettingsOut, UserRuleSettingsUpdate
import app.models as models

router = APIRouter(prefix="/users", tags=["users"])

@router.get("/{user_id}/settings", response_model=UserRuleSettingsOut)
def get_user_settings(user_id: UUID4, db: Session = Depends(get_db)):
    stmt = select(models.UserRuleSettings).where(
        models.UserRuleSettings.user_id == user_id,
        models.UserRuleSettings.valid_to.is_(None)
    )
    settings = db.execute(stmt).scalar_one_or_none()
    if not settings:
        raise HTTPException(status_code=404, detail="Active user settings not found")
    return settings

@router.put("/{user_id}/settings", response_model=UserRuleSettingsOut)
def update_user_settings(user_id: UUID4, update_data: UserRuleSettingsUpdate, db: Session = Depends(get_db)):
    stmt = select(models.UserRuleSettings).where(
        models.UserRuleSettings.user_id == user_id,
        models.UserRuleSettings.valid_to.is_(None)
    )
    old_settings = db.execute(stmt).scalar_one_or_none()
    if not old_settings:
        raise HTTPException(status_code=404, detail="Active user settings not found")

    old_settings.valid_to = datetime.now(timezone.utc)
    
    new_settings = models.UserRuleSettings(
        user_id=user_id,
        self_tax_rate=update_data.self_tax_rate if update_data.self_tax_rate is not None else old_settings.self_tax_rate,
        roundup_enabled=update_data.roundup_enabled if update_data.roundup_enabled is not None else old_settings.roundup_enabled,
        roundup_unit=update_data.roundup_unit if update_data.roundup_unit is not None else old_settings.roundup_unit,
        waiting_room_hours=update_data.waiting_room_hours if update_data.waiting_room_hours is not None else old_settings.waiting_room_hours,
        waiting_room_threshold=update_data.waiting_room_threshold if update_data.waiting_room_threshold is not None else old_settings.waiting_room_threshold
    )
    db.add(new_settings)
    db.commit()
    db.refresh(new_settings)
    return new_settings

@router.post("/{user_id}/reset")
def reset_user_data(user_id: UUID4, db: Session = Depends(get_db)):
    # Kullanıcının tüm işlemlerini ve bekleyen harcamalarını sil
    db.execute(models.PendingPurchase.__table__.delete().where(models.PendingPurchase.user_id == user_id))
    db.execute(models.Transaction.__table__.delete().where(models.Transaction.user_id == user_id))
    db.commit()
    return {"status": "ok", "message": "Tüm veriler sıfırlandı"}
