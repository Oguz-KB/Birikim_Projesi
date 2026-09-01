from sqlalchemy.orm import Session
from app.models import PendingPurchase, Transaction, UserRuleSettings
from app.rule_engine import resolve_abandoned_purchase

def write_abandoned_transaction(db: Session, pending: PendingPurchase, user_settings: UserRuleSettings) -> Transaction:
    total_diverted = resolve_abandoned_purchase(pending.amount)
    new_tx = Transaction(
        user_id=pending.user_id,
        category_id=pending.category_id,
        raw_amount=pending.amount,
        self_tax_amount=0,
        roundup_amount=0,
        total_diverted=total_diverted,
        rule_settings_id=user_settings.id,
        source='abandoned_purchase'
    )
    db.add(new_tx)
    db.flush()
    return new_tx
