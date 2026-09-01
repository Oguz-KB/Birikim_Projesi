from sqlalchemy import Column, String, Numeric, Boolean, Integer, ForeignKey, DateTime, func, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid
from app.db import Base

class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String, unique=True, nullable=False)
    display_name = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())

    rule_settings = relationship("UserRuleSettings", back_populates="user", cascade="all, delete-orphan")
    goals = relationship("Goal", back_populates="owner", cascade="all, delete-orphan")
    transactions = relationship("Transaction", back_populates="user", cascade="all, delete-orphan")
    pending_purchases = relationship("PendingPurchase", back_populates="user", cascade="all, delete-orphan")
    goal_memberships = relationship("GoalMember", back_populates="user", cascade="all, delete-orphan")
    categories = relationship("Category", back_populates="user", cascade="all, delete-orphan")

class UserRuleSettings(Base):
    __tablename__ = "user_rule_settings"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    self_tax_rate = Column(Numeric(5, 4), nullable=False, default=0.10)
    roundup_enabled = Column(Boolean, nullable=False, default=True)
    roundup_unit = Column(Numeric(10, 2), nullable=False, default=10.00)
    waiting_room_hours = Column(Integer, nullable=False, default=24)
    waiting_room_threshold = Column(Numeric(12, 2), nullable=False, default=200.00)
    valid_from = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    valid_to = Column(DateTime(timezone=True), nullable=True)

    user = relationship("User", back_populates="rule_settings")
    transactions = relationship("Transaction", back_populates="rule_settings")
