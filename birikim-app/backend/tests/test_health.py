from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health_check():
    response = client.get("/health")
    # For testing without a real DB running, we expect a 503 or 200 depending on environment.
    # Since we can't guarantee a running Postgres DB in the current env, we just verify the endpoint exists.
    assert response.status_code in (200, 503)
    
    if response.status_code == 200:
        assert response.json() == {"status": "ok", "db": "connected"}
    else:
        assert response.json() == {"detail": "Database connection failed"}
