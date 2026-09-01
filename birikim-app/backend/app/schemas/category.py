from pydantic import BaseModel, UUID4, ConfigDict, field_serializer
from decimal import Decimal

class CategoryCreate(BaseModel):
    name: str
    is_guilty_pleasure: bool = False
    penalty_multiplier: Decimal = Decimal('1.00')

class CategoryUpdate(BaseModel):
    name: str | None = None
    is_guilty_pleasure: bool | None = None
    penalty_multiplier: Decimal | None = None

class CategoryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID4
    user_id: UUID4 | None
    name: str
    is_guilty_pleasure: bool
    penalty_multiplier: Decimal

    @field_serializer("penalty_multiplier")
    def serialize_decimal(self, value: Decimal, _info) -> str:
        return str(value)
