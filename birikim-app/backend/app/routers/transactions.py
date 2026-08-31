from fastapi import APIRouter, HTTPException
from app.schemas import TransactionCreate, TransactionOut
from typing import List

router = APIRouter(prefix="/transactions", tags=["transactions"])

@router.post("/", response_model=TransactionOut, status_code=201)
def create_transaction(transaction: TransactionCreate):
    raise HTTPException(status_code=501, detail="not implemented yet")

@router.get("/", response_model=List[TransactionOut])
def get_transactions():
    raise HTTPException(status_code=501, detail="not implemented yet")
