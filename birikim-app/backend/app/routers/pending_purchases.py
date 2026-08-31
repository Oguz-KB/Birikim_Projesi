from fastapi import APIRouter, HTTPException
from app.schemas import PendingPurchaseOut
from typing import List

router = APIRouter(prefix="/pending-purchases", tags=["pending_purchases"])

@router.get("/", response_model=List[PendingPurchaseOut])
def get_pending_purchases():
    raise HTTPException(status_code=501, detail="not implemented yet")

@router.post("/{purchase_id}/resolve")
def resolve_pending_purchase(purchase_id: str):
    raise HTTPException(status_code=501, detail="not implemented yet")
