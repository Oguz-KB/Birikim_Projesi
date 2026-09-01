from pydantic import BaseModel, UUID4, ConfigDict, field_serializer
from decimal import Decimal

class CategoryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID4
    name: str
    is_guilty_pleasure: bool
    penalty_multiplier: Decimal

    @field_serializer("penalty_multiplier")
    def serialize_decimal(self, value: Decimal, _info) -> str:
        return str(value)
