import sys
import os

# Add backend directory to sys.path to be able to import app
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db import SessionLocal, engine, Base
from app.models.user import User, UserRuleSettings
from app.models.category import Category

# Ensure tables are created
Base.metadata.create_all(bind=engine)

def seed_db():
    db = SessionLocal()
    try:
        # Check if user exists
        dev_user = db.query(User).filter(User.email == "dev@birikim.app").first()
        if not dev_user:
            dev_user = User(id="b2839315-a03e-49d5-9469-1ef9132e44fd", email="dev@birikim.app", display_name="Dev User")
            db.add(dev_user)
            db.commit()
            db.refresh(dev_user)
            print(f"Created Dev User: {dev_user.id}")

            # Create rule settings
            settings = UserRuleSettings(
                user_id=dev_user.id,
                self_tax_rate=0.10,
                roundup_enabled=True,
                roundup_unit=10.00,
                waiting_room_hours=24,
                waiting_room_threshold=200.00
            )
            db.add(settings)
            db.commit()
            print("Created Rule Settings for Dev User")
        else:
            print(f"Dev User already exists: {dev_user.id}")

        # Create categories
        categories = [
            {"name": "Market", "is_guilty_pleasure": False, "penalty_multiplier": 1.0},
            {"name": "Ulaşım", "is_guilty_pleasure": False, "penalty_multiplier": 1.0},
            {"name": "Dışarıda Yemek", "is_guilty_pleasure": True, "penalty_multiplier": 3.0},
            {"name": "Eğlence", "is_guilty_pleasure": False, "penalty_multiplier": 1.0},
            {"name": "Diğer", "is_guilty_pleasure": False, "penalty_multiplier": 1.0},
        ]

        for cat_data in categories:
            cat = db.query(Category).filter(Category.name == cat_data["name"]).first()
            if not cat:
                cat = Category(**cat_data)
                db.add(cat)
                print(f"Created category: {cat_data['name']}")
        
        db.commit()
        print("Seeding finished successfully.")
        print(f"\n--- USE THIS MOCK USER_ID IN FLUTTER ---\n{dev_user.id}\n----------------------------------------")

    finally:
        db.close()

if __name__ == "__main__":
    seed_db()
