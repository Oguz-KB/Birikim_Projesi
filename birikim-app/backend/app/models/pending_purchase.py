from sqlalchemy import Column, String, Numeric, ForeignKey, DateTime, func, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid
from app.db import Base

class PendingPurchase(Base):
    __tablename__ = "pending_purchases"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    category_id = Column(UUID(as_uuid=True), ForeignKey("categories.id"), nullable=False)
    amount = Column(Numeric(12, 2), nullable=False)
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    expires_at = Column(DateTime(timezone=True), nullable=False)
    resolution = Column(String, CheckConstraint("resolution IN ('purchased', 'abandoned', 'pending')"), default='pending')
    resolved_at = Column(DateTime(timezone=True), nullable=True)
    resulting_transaction_id = Column(UUID(as_uuid=True), ForeignKey("transactions.id"), nullable=True)

    user = relationship("User", back_populates="pending_purchases")
    category = relationship("Category", back_populates="pending_purchases")
    resulting_transaction = relationship("Transaction", back_populates="pending_purchases")
