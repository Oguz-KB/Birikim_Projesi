from fastapi import APIRouter, HTTPException
from app.schemas import UserRuleSettingsOut, UserRuleSettingsUpdate

router = APIRouter(prefix="/users", tags=["users"])

@router.get("/{user_id}/settings", response_model=UserRuleSettingsOut)
def get_user_settings(user_id: str):
    raise HTTPException(status_code=501, detail="not implemented yet")

@router.put("/{user_id}/settings", response_model=UserRuleSettingsOut)
def update_user_settings(user_id: str, settings: UserRuleSettingsUpdate):
    raise HTTPException(status_code=501, detail="not implemented yet")
