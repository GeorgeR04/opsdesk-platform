from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from sqlalchemy import String, Float

class Base(DeclarativeBase):
    pass

class Change(Base):
    __tablename__ = "changes"
    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    title: Mapped[str] = mapped_column(String(256))
    status: Mapped[str] = mapped_column(String(32))
    created_at: Mapped[float] = mapped_column(Float)

class Stats(Base):
    __tablename__ = "stats"
    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    lead_time_avg_minutes: Mapped[float] = mapped_column(Float)
    change_failure_rate: Mapped[float] = mapped_column(Float)
    mttr_minutes: Mapped[float] = mapped_column(Float)
    updated_at: Mapped[float] = mapped_column(Float)
