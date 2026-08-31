from pydantic import BaseModel, UUID4, ConfigDict
from decimal import Decimal
from datetime import datetime

class GoalCreate(BaseModel):
    name: str
    target_amount: Decimal

class GoalOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID4
    owner_user_id: UUID4
    name: str
    target_amount: Decimal
    created_at: datetime
