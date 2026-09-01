import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.db import get_db, SessionLocal
import app.models as models
from datetime import datetime, timedelta, timezone

client = TestClient(app)

@pytest.fixture(scope="module")
def db_session():
    db = SessionLocal()
    yield db
    db.close()

@pytest.fixture(scope="module")
def setup_data(db_session):
    user = db_session.query(models.User).filter_by(email="test@example.com").first()
    if not user:
        user = models.User(email="test@example.com", display_name="Test User")
        db_session.add(user)
        db_session.commit()
        db_session.refresh(user)
    
    cat_normal = db_session.query(models.Category).filter_by(name="Market").first()
    if not cat_normal:
        cat_normal = models.Category(name="Market", is_guilty_pleasure=False, penalty_multiplier=1.0)
        db_session.add(cat_normal)
        
    cat_guilty = db_session.query(models.Category).filter_by(name="Eating Out").first()
    if not cat_guilty:
        cat_guilty = models.Category(name="Eating Out", is_guilty_pleasure=True, penalty_multiplier=3.0)
        db_session.add(cat_guilty)
        
    db_session.commit()
    
    settings = db_session.query(models.UserRuleSettings).filter_by(user_id=user.id).first()
    if not settings:
        settings = models.UserRuleSettings(
            user_id=user.id,
            self_tax_rate=0.10,
            roundup_enabled=True,
            roundup_unit=10.00,
            waiting_room_hours=24,
            waiting_room_threshold=200.00
        )
        db_session.add(settings)
        db_session.commit()
    
    return {
        "user_id": str(user.id),
        "cat_normal_id": str(cat_normal.id),
        "cat_guilty_id": str(cat_guilty.id)
    }

def test_normal_transaction(setup_data, db_session):
    headers = {"x-user-id": setup_data["user_id"]}
    payload = {
        "category_id": setup_data["cat_normal_id"],
        "raw_amount": "87.50"
    }
    resp = client.post("/transactions/", json=payload, headers=headers)
    assert resp.status_code == 201
    data = resp.json()
    assert data["raw_amount"] == "87.50"
    assert "id" in data
    
    # Assert source is self_tax
    tx = db_session.get(models.Transaction, data["id"])
    assert tx.source == "self_tax"

def test_waiting_room_threshold(setup_data):
    headers = {"x-user-id": setup_data["user_id"]}
    payload = {
        "category_id": setup_data["cat_normal_id"],
        "raw_amount": "450.00"
    }
    resp = client.post("/transactions/", json=payload, headers=headers)
    assert resp.status_code == 202
    data = resp.json()
    assert data["amount"] == "450.00"
    assert data["resolution"] == "pending"

def test_resolve_purchased(setup_data):
    headers = {"x-user-id": setup_data["user_id"]}
    payload = {
        "category_id": setup_data["cat_normal_id"],
        "raw_amount": "300.00"
    }
    resp = client.post("/transactions/", json=payload, headers=headers)
    purchase_id = resp.json()["id"]
    
    resolve_payload = {"decision": "purchased"}
    resp2 = client.post(f"/pending-purchases/{purchase_id}/resolve", json=resolve_payload, headers=headers)
    assert resp2.status_code == 200
    assert resp2.json()["resolution"] == "purchased"
    assert resp2.json()["resulting_transaction_id"] is not None

def test_resolve_abandoned(setup_data, db_session):
    headers = {"x-user-id": setup_data["user_id"]}
    payload = {
        "category_id": setup_data["cat_normal_id"],
        "raw_amount": "350.00"
    }
    resp = client.post("/transactions/", json=payload, headers=headers)
    purchase_id = resp.json()["id"]
    
    resolve_payload = {"decision": "abandoned"}
    resp2 = client.post(f"/pending-purchases/{purchase_id}/resolve", json=resolve_payload, headers=headers)
    assert resp2.status_code == 200
    data = resp2.json()
    assert data["resolution"] == "abandoned"
    tx_id = data["resulting_transaction_id"]
    assert tx_id is not None
    
    tx = db_session.get(models.Transaction, tx_id)
    assert tx.raw_amount == 350.00
    assert tx.self_tax_amount == 0
    assert tx.roundup_amount == 0
    assert tx.total_diverted == 350.00
    assert tx.source == "abandoned_purchase"

def test_resolve_conflict(setup_data):
    headers = {"x-user-id": setup_data["user_id"]}
    resp = client.post("/transactions/", json={"category_id": setup_data["cat_normal_id"], "raw_amount": "250.00"}, headers=headers)
    purchase_id = resp.json()["id"]
    
    client.post(f"/pending-purchases/{purchase_id}/resolve", json={"decision": "abandoned"}, headers=headers)
    
    resp3 = client.post(f"/pending-purchases/{purchase_id}/resolve", json={"decision": "purchased"}, headers=headers)
    assert resp3.status_code == 409

def test_background_job(setup_data, db_session):
    from app.background_jobs import process_expired_pending_purchases
    
    pending = models.PendingPurchase(
        user_id=setup_data["user_id"],
        category_id=setup_data["cat_normal_id"],
        amount=500.00,
        expires_at=datetime.now(timezone.utc) - timedelta(hours=1),
        resolution="pending"
    )
    db_session.add(pending)
    db_session.commit()
    
    count = process_expired_pending_purchases(db_session)
    assert count >= 1
    
    db_session.refresh(pending)
    assert pending.resolution == "abandoned"
    tx_id = pending.resulting_transaction_id
    assert tx_id is not None
    
    tx = db_session.get(models.Transaction, tx_id)
    assert tx.raw_amount == 500.00
    assert tx.self_tax_amount == 0
    assert tx.roundup_amount == 0
    assert tx.total_diverted == 500.00
    assert tx.source == "abandoned_purchase"

def test_update_user_settings(setup_data):
    headers = {"x-user-id": setup_data["user_id"]}
    resp = client.get(f"/users/{setup_data['user_id']}/settings", headers=headers)
    assert resp.status_code == 200
    
    new_settings = {
        "self_tax_rate": "0.15"
    }
    resp2 = client.put(f"/users/{setup_data['user_id']}/settings", json=new_settings, headers=headers)
    assert resp2.status_code == 200
    assert resp2.json()["self_tax_rate"] == "0.1500"

def test_get_pending_purchases_pagination(setup_data):
    headers = {"x-user-id": setup_data["user_id"]}
    client.post("/transactions/", json={"category_id": setup_data["cat_normal_id"], "raw_amount": "250.00"}, headers=headers)
    client.post("/transactions/", json={"category_id": setup_data["cat_normal_id"], "raw_amount": "260.00"}, headers=headers)
    client.post("/transactions/", json={"category_id": setup_data["cat_normal_id"], "raw_amount": "270.00"}, headers=headers)
    
    resp = client.get("/pending-purchases/?skip=0&limit=2", headers=headers)
    assert resp.status_code == 200
    assert len(resp.json()) == 2
