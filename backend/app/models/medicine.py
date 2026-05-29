import uuid
from datetime import datetime

from sqlalchemy import String, Integer, Text, DateTime, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base



class Medicine(Base):
    __tablename__ = "medicines"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4
    )

    name: Mapped[str] = mapped_column(String(255))
    dose: Mapped[str | None] = mapped_column(String(100), nullable=True)
    frequency: Mapped[int] = mapped_column(Integer, default=1)

    disease_type: Mapped[str] = mapped_column(String(50))

    barcode: Mapped[str | None] = mapped_column(String(100), unique=True)

    image_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now()
    )



class PatientMedicine(Base):
    __tablename__ = "patient_medicines"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4
    )

    caregiver_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True))
    patient_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), nullable=True)

    name: Mapped[str] = mapped_column(String(255))
    dose: Mapped[str | None] = mapped_column(String(100), nullable=True)
    frequency: Mapped[int] = mapped_column(Integer, default=1)

    image_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    disease_type: Mapped[str | None] = mapped_column(String(50), nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now()
    )