from sqlalchemy import Column, String, Boolean, Numeric, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid
from app.db import Base

class Category(Base):
    __tablename__ = "categories"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True) # Nullable because global categories don't have a user
    name = Column(String, nullable=False)
    is_guilty_pleasure = Column(Boolean, nullable=False, default=False)
    penalty_multiplier = Column(Numeric(4, 2), nullable=False, default=1.00)

    user = relationship("User", back_populates="categories")
    transactions = relationship("Transaction", back_populates="category")
    pending_purchases = relationship("PendingPurchase", back_populates="category")
