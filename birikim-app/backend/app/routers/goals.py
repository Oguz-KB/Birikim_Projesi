from fastapi import APIRouter, HTTPException
from app.schemas import GoalCreate, GoalOut
from typing import List

router = APIRouter(prefix="/goals", tags=["goals"])

@router.post("/", response_model=GoalOut, status_code=201)
def create_goal(goal: GoalCreate):
    raise HTTPException(status_code=501, detail="not implemented yet")

@router.get("/", response_model=List[GoalOut])
def get_goals():
    raise HTTPException(status_code=501, detail="not implemented yet")
