import uuid
from datetime import datetime, date

from sqlalchemy import Date, DateTime, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Appointment(Base):
    __tablename__ = "appointments"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    patient_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True))
    caregiver_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True))

    appointment_date: Mapped[date] = mapped_column(Date)
    time: Mapped[str] = mapped_column(String(20))

    status: Mapped[str | None] = mapped_column(String(50))

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())