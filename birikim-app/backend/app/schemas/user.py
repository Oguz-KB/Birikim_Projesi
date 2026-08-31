from pydantic import BaseModel, UUID4, ConfigDict
from decimal import Decimal
from datetime import datetime
from typing import Optional

class UserRuleSettingsUpdate(BaseModel):
    self_tax_rate: Optional[Decimal] = None
    roundup_enabled: Optional[bool] = None
    roundup_unit: Optional[Decimal] = None
    waiting_room_hours: Optional[int] = None
    waiting_room_threshold: Optional[Decimal] = None

class UserRuleSettingsOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID4
    user_id: UUID4
    self_tax_rate: Decimal
    roundup_enabled: bool
    roundup_unit: Decimal
    waiting_room_hours: int
    waiting_room_threshold: Decimal
    valid_from: datetime
    valid_to: Optional[datetime] = None
