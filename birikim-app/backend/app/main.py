from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db import get_db
from app.routers import transactions, pending_purchases, goals, users
from sqlalchemy import text

app = FastAPI(title="Birikim App API", version="0.1.0")

app.include_router(transactions.router)
app.include_router(pending_purchases.router)
app.include_router(goals.router)
app.include_router(users.router)

@app.get("/health")
def health_check(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
        return {"status": "ok", "db": "connected"}
    except Exception as e:
        raise HTTPException(status_code=503, detail="Database connection failed")
