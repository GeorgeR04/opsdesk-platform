from fastapi import APIRouter

router = APIRouter()


@router.get("/stats")
def stats():
    # Day 1: placeholder (worker+db Day 2)
    return {"lead_time_avg_minutes": 0, "change_failure_rate": 0.0, "mttr_minutes": 0}
