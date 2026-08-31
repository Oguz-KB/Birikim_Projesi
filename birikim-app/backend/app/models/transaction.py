from sqlalchemy import Column, Numeric, ForeignKey, DateTime, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid
from app.db import Base

class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    category_id = Column(UUID(as_uuid=True), ForeignKey("categories.id"), nullable=False)
    raw_amount = Column(Numeric(12, 2), nullable=False)
    self_tax_amount = Column(Numeric(12, 2), nullable=False)
    roundup_amount = Column(Numeric(12, 2), nullable=False, default=0)
    total_diverted = Column(Numeric(12, 2), nullable=False)
    rule_settings_id = Column(UUID(as_uuid=True), ForeignKey("user_rule_settings.id"), nullable=False)
    goal_id = Column(UUID(as_uuid=True), ForeignKey("goals.id"), nullable=True)
    reversal_of = Column(UUID(as_uuid=True), ForeignKey("transactions.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())

    user = relationship("User", back_populates="transactions")
    category = relationship("Category", back_populates="transactions")
    rule_settings = relationship("UserRuleSettings", back_populates="transactions")
    goal = relationship("Goal", back_populates="transactions")
    reversal = relationship("Transaction", remote_side=[id])
    pending_purchases = relationship("PendingPurchase", back_populates="resulting_transaction")
