from fastapi import APIRouter, HTTPException, Depends, Header
from app.schemas.goal import GoalCreate, GoalOut, GoalUpdate
from typing import List
from sqlalchemy.orm import Session
from sqlalchemy import select
from pydantic import UUID4
import app.models as models
from app.db import get_db

router = APIRouter(prefix="/goals", tags=["goals"])

@router.post("/", response_model=GoalOut, status_code=201)
def create_goal(
    goal: GoalCreate, 
    x_user_id: UUID4 = Header(...),
    db: Session = Depends(get_db)
):
    new_goal = models.Goal(
        owner_user_id=x_user_id,
        name=goal.name,
        target_amount=goal.target_amount,
        image_url=goal.image_url
    )
    db.add(new_goal)
    db.commit()
    db.refresh(new_goal)
    return new_goal

@router.get("/", response_model=List[GoalOut])
def get_goals(
    x_user_id: UUID4 = Header(...),
    db: Session = Depends(get_db)
):
    stmt = select(models.Goal).where(models.Goal.owner_user_id == x_user_id).order_by(models.Goal.created_at.desc())
    return db.execute(stmt).scalars().all()

@router.put("/{goal_id}", response_model=GoalOut)
def update_goal(
    goal_id: UUID4,
    goal_update: GoalUpdate,
    x_user_id: UUID4 = Header(...),
    db: Session = Depends(get_db)
):
    goal = db.get(models.Goal, goal_id)
    if not goal or goal.owner_user_id != x_user_id:
        raise HTTPException(status_code=404, detail="Goal not found")
    
    update_data = goal_update.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(goal, key, value)
        
    db.commit()
    db.refresh(goal)
    return goal

@router.delete("/{goal_id}", status_code=204)
def delete_goal(
    goal_id: UUID4,
    x_user_id: UUID4 = Header(...),
    db: Session = Depends(get_db)
):
    goal = db.get(models.Goal, goal_id)
    if not goal or goal.owner_user_id != x_user_id:
        raise HTTPException(status_code=404, detail="Goal not found")
    
    db.delete(goal)
    db.commit()
    return None
