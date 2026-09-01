from fastapi import APIRouter, Depends, HTTPException, Header, status
from sqlalchemy.orm import Session
from sqlalchemy import select
from pydantic import UUID4
from typing import List

from ..db import get_db
from ..models.category import Category
from ..schemas.category import CategoryOut, CategoryCreate, CategoryUpdate

router = APIRouter(
    prefix="/categories",
    tags=["categories"]
)

@router.get("/", response_model=List[CategoryOut])
def get_categories(x_user_id: UUID4 = Header(...), db: Session = Depends(get_db)):
    """
    Kategori listesini döner. Global ve kullanıcıya özel kategorileri birleştirir.
    """
    stmt = select(Category).where((Category.user_id == None) | (Category.user_id == x_user_id))
    categories = db.execute(stmt).scalars().all()
    return categories

@router.post("/", response_model=CategoryOut, status_code=status.HTTP_201_CREATED)
def create_category(category: CategoryCreate, x_user_id: UUID4 = Header(...), db: Session = Depends(get_db)):
    # Check max limit of 10 custom categories
    stmt_count = select(Category).where(Category.user_id == x_user_id)
    user_cats = db.execute(stmt_count).scalars().all()
    if len(user_cats) >= 10:
        raise HTTPException(status_code=400, detail="Maksimum 10 özel kategori ekleyebilirsiniz.")
        
    new_cat = Category(
        user_id=x_user_id,
        name=category.name,
        is_guilty_pleasure=category.is_guilty_pleasure,
        penalty_multiplier=category.penalty_multiplier
    )
    db.add(new_cat)
    db.commit()
    db.refresh(new_cat)
    return new_cat

@router.put("/{category_id}", response_model=CategoryOut)
def update_category(category_id: UUID4, category_update: CategoryUpdate, x_user_id: UUID4 = Header(...), db: Session = Depends(get_db)):
    cat = db.get(Category, category_id)
    if not cat:
        raise HTTPException(status_code=404, detail="Category not found")
        
    # Kendi kategorisi veya sistem kategorisi ise düzenlemeye izin ver
    if cat.user_id is not None and cat.user_id != x_user_id:
        raise HTTPException(status_code=403, detail="Başkasına ait kategorileri düzenleyemezsiniz.")
        
    update_data = category_update.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(cat, key, value)
        
    db.commit()
    db.refresh(cat)
    return cat

@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_category(category_id: UUID4, x_user_id: UUID4 = Header(...), db: Session = Depends(get_db)):
    cat = db.get(Category, category_id)
    if not cat:
        raise HTTPException(status_code=404, detail="Category not found")
        
    if cat.user_id != x_user_id:
        raise HTTPException(status_code=403, detail="Sadece kendi eklediğiniz kategorileri silebilirsiniz.")
        
    db.delete(cat)
    db.commit()
    return None
