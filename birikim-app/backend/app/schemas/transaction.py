from pydantic import BaseModel, UUID4, ConfigDict
from decimal import Decimal
from datetime import datetime
from typing import Optional

class TransactionCreate(BaseModel):
    category_id: UUID4
    raw_amount: Decimal

class TransactionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID4
    user_id: UUID4
    category_id: UUID4
    raw_amount: Decimal
    self_tax_amount: Decimal
    roundup_amount: Decimal
    total_diverted: Decimal
    rule_settings_id: UUID4
    goal_id: Optional[UUID4] = None
    reversal_of: Optional[UUID4] = None
    created_at: datetime
