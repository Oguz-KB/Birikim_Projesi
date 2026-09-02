from fastapi import APIRouter, Depends, Header
from sqlalchemy.orm import Session
from sqlalchemy import select, func
from pydantic import UUID4
from datetime import datetime, timezone
from decimal import Decimal

from app.db import get_db
import app.models as models

router = APIRouter(prefix="/analytics", tags=["analytics"])

@router.get("/summary")
def get_analytics_summary(x_user_id: UUID4 = Header(...), db: Session = Depends(get_db)):
    # 1. Kullanıcının kayıt tarihini al
    user = db.get(models.User, x_user_id)
    if not user:
        # Fallback if user doesn't exist (e.g. mock user), just assume active since 1 day for safety
        days_active = 1
    else:
        now = datetime.now(timezone.utc)
        created_at = user.created_at
        if created_at.tzinfo is None:
            created_at = created_at.replace(tzinfo=timezone.utc)
        delta = now - created_at
        days_active = max(1, delta.days) # Minimum 1 gün kabul edelim (0'a bölme hatası almamak için)

    # 2. Toplam birikimi hesapla (transactions tablosundan total_diverted toplamı)
    stmt_total_savings = select(func.sum(models.Transaction.total_diverted)).where(
        models.Transaction.user_id == x_user_id
    )
    total_savings = db.execute(stmt_total_savings).scalar() or Decimal('0.00')

    # Günlük ortalama
    daily_average = float(total_savings) / days_active if days_active > 0 else 0.0

    # 3. Kategori bazlı ceza (zaaf) dağılımı
    # Sadece self_tax olanları toplayalım (roundup veya hedefe harcama -withdrawal- hariç)
    # total_diverted yerine self_tax_amount'a veya source='self_tax' olanlara bakabiliriz.
    stmt_category_stats = (
        select(
            models.Category.name,
            func.sum(models.Transaction.self_tax_amount).label('total_tax')
        )
        .join(models.Transaction, models.Transaction.category_id == models.Category.id)
        .where(
            models.Transaction.user_id == x_user_id,
            models.Transaction.self_tax_amount > 0
        )
        .group_by(models.Category.id, models.Category.name)
    )
    
    category_stats_raw = db.execute(stmt_category_stats).all()
    
    category_breakdown = []
    for cat_name, total_tax in category_stats_raw:
        category_breakdown.append({
            "category_name": cat_name,
            "total_tax_paid": float(total_tax)
        })

    # Hedef ile ilgili projeksiyon metni
    # Eğer days_active < 7 ise analiz ediliyor diyeceğiz.
    stmt_goal = select(models.Goal).where(
        models.Goal.owner_user_id == x_user_id
    ).order_by(models.Goal.created_at.desc()).limit(1)
    
    active_goal = db.execute(stmt_goal).scalar_one_or_none()
    
    projection_text = ""
    if active_goal:
        remaining_amount = float(active_goal.target_amount) - float(total_savings)
        if remaining_amount <= 0:
            projection_text = "Hedefine ulaştın! Satın alabilirsin 🎉"
        elif days_active < 7:
            days_left_for_analysis = 7 - days_active
            projection_text = f"Birikim hızın analiz ediliyor... (Tahmin için kalan süre: {days_left_for_analysis} gün)"
        elif daily_average <= 0:
            projection_text = "Henüz düzenli birikim yapmıyorsun, harcama yaptıkça hedefine yaklaşacaksın!"
        else:
            estimated_days_left = int(remaining_amount / daily_average)
            projection_text = f"Harika gidiyorsun! Mevcut hızınla {estimated_days_left} gün sonra hedefine ulaşacaksın."
    
    return {
        "days_active": days_active,
        "total_savings": float(total_savings),
        "daily_average": daily_average,
        "projection_text": projection_text,
        "category_breakdown": category_breakdown
    }

@router.get("/badges")
def get_badges(x_user_id: UUID4 = Header(...), db: Session = Depends(get_db)):
    # 1. Days Active
    user = db.get(models.User, x_user_id)
    if not user:
        days_active = 1
    else:
        now = datetime.now(timezone.utc)
        created_at = user.created_at
        if created_at.tzinfo is None:
            created_at = created_at.replace(tzinfo=timezone.utc)
        days_active = max(1, (now - created_at).days)

    # 2. Total Savings
    stmt_total_savings = select(func.sum(models.Transaction.total_diverted)).where(
        models.Transaction.user_id == x_user_id
    )
    total_savings = db.execute(stmt_total_savings).scalar() or Decimal('0.00')
    total_savings_float = float(total_savings)

    # 3. Abandoned Pending Purchases (Sabır Taşı)
    stmt_abandoned = select(func.count(models.PendingPurchase.id)).where(
        models.PendingPurchase.user_id == x_user_id,
        models.PendingPurchase.resolution == 'abandoned'
    )
    abandoned_count = db.execute(stmt_abandoned).scalar() or 0

    # Define Badges
    categories = [
        {
            "id": "savings",
            "name": "Tasarruf Ustası",
            "description": "Bugüne kadar kumbaraya attığın toplam tutar.",
            "current_value": total_savings_float,
            "unit": "TL",
            "badges": [
                {"id": "sav_bronze", "name": "Acemi Birikimci", "tier": "bronze", "target": 500},
                {"id": "sav_silver", "name": "İyi Birikimci", "tier": "silver", "target": 2500},
                {"id": "sav_gold", "name": "Usta Birikimci", "tier": "gold", "target": 10000},
            ]
        },
        {
            "id": "patience",
            "name": "Sabır Taşı",
            "description": "Bekleme odasında süresi dolduğunda iradene sahip çıkıp 'Vazgeçtim' dediğin ürün sayısı.",
            "current_value": abandoned_count,
            "unit": "Ürün",
            "badges": [
                {"id": "pat_bronze", "name": "Kararlı", "tier": "bronze", "target": 1},
                {"id": "pat_silver", "name": "İradeli", "tier": "silver", "target": 5},
                {"id": "pat_gold", "name": "Münzevi", "tier": "gold", "target": 20},
            ]
        },
        {
            "id": "streak",
            "name": "İstikrar",
            "description": "Kayıt olduğun günden bugüne geçen aktif süre.",
            "current_value": days_active,
            "unit": "Gün",
            "badges": [
                {"id": "str_bronze", "name": "Hevesli", "tier": "bronze", "target": 7},
                {"id": "str_silver", "name": "Sadık", "tier": "silver", "target": 30},
                {"id": "str_gold", "name": "Efsane", "tier": "gold", "target": 100},
            ]
        }
    ]

    # Calculate status
    for cat in categories:
        current = cat["current_value"]
        for b in cat["badges"]:
            target = b["target"]
            is_earned = current >= target
            progress = min(1.0, float(current) / float(target)) if target > 0 else 1.0
            b["is_earned"] = is_earned
            b["progress"] = progress

    return categories
