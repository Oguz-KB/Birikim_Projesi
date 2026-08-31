from pydantic import BaseModel, UUID4, ConfigDict
from decimal import Decimal
from datetime import datetime
from typing import Optional

class PendingPurchaseOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID4
    user_id: UUID4
    category_id: UUID4
    amount: Decimal
    created_at: datetime
    expires_at: datetime
    resolution: str
    resolved_at: Optional[datetime] = None
    resulting_transaction_id: Optional[UUID4] = None
