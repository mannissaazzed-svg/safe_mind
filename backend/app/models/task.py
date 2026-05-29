import uuid
from datetime import date, datetime

from sqlalchemy import Date, DateTime, String, func
from sqlalchemy.dialects.postgresql import UUID, JSON
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Task(Base):
    __tablename__ = "tasks"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4
    )

    
    patient_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        index=True,
        nullable=False
    )

    caregiver_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        nullable=True
    )

    task_date: Mapped[date] = mapped_column(
        Date,
        index=True,
        nullable=False
    )

   
    title: Mapped[str] = mapped_column(String(100), nullable=False)

    color: Mapped[str | None] = mapped_column(String(30), nullable=True)

    image: Mapped[str | None] = mapped_column(String(255), nullable=True)

    
    sub_tasks: Mapped[list] = mapped_column(JSON, default=list)

    status: Mapped[dict] = mapped_column(JSON, default=dict)

    
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now()
    )