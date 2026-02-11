import time

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.db import get_db
from app.models import Change as ChangeModel
from app.queue import celery_app

router = APIRouter()


class Change(BaseModel):
    id: str
    title: str
    status: str = "OPEN"
    created_at: float = 0


@router.get("/changes", response_model=list[Change])
def list_changes(db: Session = Depends(get_db)):
    rows = db.query(ChangeModel).all()
    return [Change(id=r.id, title=r.title, status=r.status, created_at=r.created_at) for r in rows]


@router.post("/changes", response_model=Change)
def create_change(c: Change, db: Session = Depends(get_db)):
    if c.created_at == 0:
        c.created_at = time.time()
    row = ChangeModel(id=c.id, title=c.title, status=c.status, created_at=c.created_at)
    db.add(row)
    db.commit()

    # enqueue worker processing
    celery_app.send_task("worker.tasks.process_change", args=[c.id])
    return c
