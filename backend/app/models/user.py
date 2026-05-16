"""
app/models/user.py
Table 'users' — utilisée par TOUTES les pages Flutter

Pages concernées :
- login.dart           : email, hashed_password
- sign_up.dart         : création compte
- person.dart          : role
- patient_profile.dart : full_name, avatar_url, linked_to, disease, patient_filled
- caregiver_profile.dart : full_name, avatar_url, linked_to, disease, patient_filled
- auth_gate.dart       : role, full_name, linked_to, patient_filled, disease
- home.dart (patient)  : full_name, avatar_url, disease
- caregiver.dart       : full_name, avatar_url, linked_to
"""
import uuid
from datetime import datetime
from sqlalchemy import String, Boolean, DateTime, Text, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID
from app.core.database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(
        UUID(as_uuid=False), primary_key=True,
        default=lambda: str(uuid.uuid4())
    )

    # ── Auth ─────────────────────────────────────────
    email: Mapped[str] = mapped_column(
        String(255), unique=True, nullable=False, index=True
    )
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=True)

    # ── Rôle — person.dart ────────────────────────────
    # 'patient' | 'caregiver' | 'médecin' | null
    role: Mapped[str] = mapped_column(String(50), nullable=True)

    # ── Profil — patient_profile.dart / caregiver_profile.dart ──
    full_name: Mapped[str] = mapped_column(String(255), nullable=True)
    avatar_url: Mapped[str] = mapped_column(Text, nullable=True)

    # ── Maladie — caregiver_profile.dart ─────────────
    # 'Alzheimer' | 'Parkinson' | 'Alzheimer & Parkinson'
    disease: Mapped[str] = mapped_column(String(100), nullable=True)

    # ── Liaison — link_by_code_widget.dart ───────────
    # soignant.linked_to = patient.id  |  patient.linked_to = soignant.id
    linked_to: Mapped[str] = mapped_column(
        UUID(as_uuid=False),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )

    # ── formulaire.dart — PatientForm ────────────────
    patient_filled: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )

    # ── OAuth ─────────────────────────────────────────
    oauth_provider: Mapped[str] = mapped_column(String(50), nullable=True)
    oauth_id: Mapped[str] = mapped_column(String(255), nullable=True)

    # ── FCM — notifications.dart ──────────────────────
    fcm_token: Mapped[str] = mapped_column(String(500), nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )

    # ── Relations ────────────────────────────────────
    tasks: Mapped[list["Task"]] = relationship(           # noqa
        "Task", back_populates="patient",
        foreign_keys="Task.patient_id"
    )
    location: Mapped["PatientLocation"] = relationship(   # noqa
        "PatientLocation", back_populates="user", uselist=False
    )
    notifications: Mapped[list["Notification"]] = relationship( # noqa
        "Notification", back_populates="user"
    )
    patient_medicines: Mapped[list["PatientMedicine"]] = relationship( # noqa
        "PatientMedicine", back_populates="patient",
        foreign_keys="PatientMedicine.patient_id"
    )
    safe_zone: Mapped["SafeZone"] = relationship(         # noqa
        "SafeZone", back_populates="patient", uselist=False
    )
    saved_places: Mapped[list["SavedPlace"]] = relationship( # noqa
        "SavedPlace", back_populates="user"
    )
    alerts_as_patient: Mapped[list["Alert"]] = relationship( # noqa
        "Alert", back_populates="patient",
        foreign_keys="Alert.patient_id"
    )

    def __repr__(self):
        return f"<User {self.email} role={self.role}>"