import time
import os
from celery import Celery
from sqlalchemy.orm import Session

from worker.db import SessionLocal
from worker.models import Change, Stats

BROKER = os.getenv("CELERY_BROKER_URL", os.getenv("REDIS_URL", "redis://redis:6379/0"))
BACKEND = os.getenv("CELERY_RESULT_BACKEND", BROKER)
celery_app = Celery("opsdesk", broker=BROKER, backend=BACKEND)

@celery_app.task(name="worker.tasks.process_change")
def process_change(change_id: str):
    db: Session = SessionLocal()
    try:
        c = db.query(Change).filter(Change.id == change_id).first()
        if not c:
            return {"ok": False, "reason": "change_not_found"}

        # Simu KPI: stats globales (simple mais démontrable)
        now = time.time()
        lead_time = max(0.0, (now - c.created_at) / 60.0)

        s = db.query(Stats).filter(Stats.id == "global").first()
        if not s:
            s = Stats(
                id="global",
                lead_time_avg_minutes=lead_time,
                change_failure_rate=0.0,
                mttr_minutes=0.0,
                updated_at=now,
            )
            db.add(s)
        else:
            # moyenne glissante “simple”
            s.lead_time_avg_minutes = (s.lead_time_avg_minutes * 0.8) + (lead_time * 0.2)
            s.updated_at = now

        db.commit()
        return {"ok": True}
    finally:
        db.close()
