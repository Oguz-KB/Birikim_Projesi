from pydantic import BaseModel, UUID4, ConfigDict
from decimal import Decimal
from datetime import datetime

class GoalCreate(BaseModel):
    name: str
    target_amount: Decimal
    image_url: str | None = None

class GoalUpdate(BaseModel):
    name: str | None = None
    target_amount: Decimal | None = None
    image_url: str | None = None
    is_completed: bool | None = None

class GoalOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID4
    owner_user_id: UUID4
    name: str
    target_amount: Decimal
    image_url: str | None
    is_completed: bool
    created_at: datetime
