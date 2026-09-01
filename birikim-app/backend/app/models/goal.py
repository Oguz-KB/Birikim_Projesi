from sqlalchemy import Column, String, Numeric, ForeignKey, DateTime, Boolean, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid
from app.db import Base

class Goal(Base):
    __tablename__ = "goals"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    owner_user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    name = Column(String, nullable=False)
    target_amount = Column(Numeric(12, 2), nullable=False)
    image_url = Column(String, nullable=True)
    is_completed = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())

    owner = relationship("User", back_populates="goals")
    members = relationship("GoalMember", back_populates="goal", cascade="all, delete-orphan")
    transactions = relationship("Transaction", back_populates="goal")

class GoalMember(Base):
    __tablename__ = "goal_members"

    goal_id = Column(UUID(as_uuid=True), ForeignKey("goals.id"), primary_key=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), primary_key=True)
    joined_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())

    goal = relationship("Goal", back_populates="members")
    user = relationship("User", back_populates="goal_memberships")
