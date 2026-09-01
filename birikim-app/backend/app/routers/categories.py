from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List

from ..db import get_db
from ..models.category import Category
from ..schemas.category import CategoryOut

router = APIRouter(
    prefix="/categories",
    tags=["categories"]
)

@router.get("/", response_model=List[CategoryOut])
def get_categories(db: Session = Depends(get_db)):
    """
    Kategori listesini döner.
    """
    categories = db.query(Category).all()
    return categories
