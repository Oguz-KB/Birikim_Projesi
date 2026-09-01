from sqlalchemy.orm import Session
from sqlalchemy import select
from datetime import datetime, timezone
import asyncio

import app.models as models
from app.db import SessionLocal
from app.services.pending_purchases import write_abandoned_transaction

def process_expired_pending_purchases(db: Session):
    now = datetime.now(timezone.utc)
    stmt = select(models.PendingPurchase).where(
        models.PendingPurchase.resolution == 'pending',
        models.PendingPurchase.expires_at <= now
    )
    expired_purchases = db.execute(stmt).scalars().all()
    
    count = 0
    for pending in expired_purchases:
        stmt_settings = select(models.UserRuleSettings).where(
            models.UserRuleSettings.user_id == pending.user_id,
            models.UserRuleSettings.valid_to.is_(None)
        )
        user_settings = db.execute(stmt_settings).scalar_one_or_none()
        if not user_settings:
            continue
            
        new_tx = write_abandoned_transaction(db, pending, user_settings)
        
        pending.resolution = 'abandoned'
        pending.resolved_at = now
        pending.resulting_transaction_id = new_tx.id
        count += 1
        
    db.commit()
    return count

async def background_task_loop():
    while True:
        try:
            with SessionLocal() as db:
                process_expired_pending_purchases(db)
        except Exception as e:
            print(f"Error in background task: {e}")
        await asyncio.sleep(60)
