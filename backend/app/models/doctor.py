"""
app/models/doctor.py
Table 'doctors'

Pages concernées :
- medecin/Doctor_Registration.dart : _submit() → INSERT doctors
- medecin/dashboard.dart : _loadMedecinInfo() → SELECT FROM doctors
"""
import uuid
from datetime import datetime
from sqlalchemy import String, DateTime, Text, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID
from app.core.database import Base


class Doctor(Base):
    __tablename__ = "doctors"

    # Même id que users
    id: Mapped[str] = mapped_column(
        UUID(as_uuid=False),
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True
    )
    full_name: Mapped[str]      = mapped_column(String(255), nullable=False)
    phone: Mapped[str]          = mapped_column(String(50), nullable=True)
    hospital: Mapped[str]       = mapped_column(String(255), nullable=True)
    license_number: Mapped[str] = mapped_column(String(100), nullable=True, unique=True)
    # 'Neurologue'|'Généraliste'|'Psychiatre'|'Gériatre'|'Autre'
    speciality: Mapped[str]     = mapped_column(String(100), nullable=True)
    avatar_url: Mapped[str]     = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )

    patients: Mapped[list["PatientMed"]] = relationship(  # noqa
        "PatientMed", back_populates="doctor"
    )
    appointments: Mapped[list["Appointment"]] = relationship( # noqa
        "Appointment", back_populates="doctor"
    )