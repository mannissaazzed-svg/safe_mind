"""
app/models/location.py
Tables GPS

Pages concernées :
- patient/patient_location.dart (PatientMapScreen) :
    updateLocation() → patient_locations
    safe_zones, saved_places, alerts

- soignant/map.dart (CompanionMapScreen) :
    getPatientStream() → patient_locations
    alerts (zone_exit, zone_enter, sos)
"""
import uuid
from datetime import datetime
from sqlalchemy import String, Float, DateTime, ForeignKey, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID
from app.core.database import Base


# ── Table patient_locations ───────────────────────────
class PatientLocation(Base):
    """
    UPSERT à chaque mise à jour GPS.
    Correspond à SupabaseService.updateLocation()
    et _pushLocation() dans patient_location.dart
    """
    __tablename__ = "patient_locations"

    user_id: Mapped[str] = mapped_column(
        UUID(as_uuid=False),
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True
    )
    latitude: Mapped[float]  = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    speed: Mapped[float]     = mapped_column(Float, nullable=True)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )

    user: Mapped["User"] = relationship("User", back_populates="location") # noqa


# ── Table safe_zones ──────────────────────────────────
class SafeZone(Base):
    """
    Zone sécurisée du patient.
    Correspond à SafeZone dans patient_location.dart :
    - _loadSafeZone()
    - _sendZoneAlert() (zone_exit / zone_enter)
    """
    __tablename__ = "safe_zones"

    id: Mapped[str] = mapped_column(
        UUID(as_uuid=False), primary_key=True,
        default=lambda: str(uuid.uuid4())
    )
    patient_id: Mapped[str] = mapped_column(
        UUID(as_uuid=False),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False, unique=True
    )
    center_lat: Mapped[float]     = mapped_column(Float, nullable=False)
    center_lng: Mapped[float]     = mapped_column(Float, nullable=False)
    radius_meters: Mapped[float]  = mapped_column(Float, nullable=False, default=200.0)
    created_at: Mapped[datetime]  = mapped_column(DateTime, default=datetime.utcnow)

    patient: Mapped["User"] = relationship("User", back_populates="safe_zone") # noqa


# ── Table saved_places ────────────────────────────────
class SavedPlace(Base):
    """
    Lieux enregistrés par le patient.
    Correspond à SavedPlace dans patient_location.dart :
    - _loadSavedPlaces()
    - _goToSavedPlace()
    Champs : id, label, latitude, longitude, icon (emoji)
    """
    __tablename__ = "saved_places"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[str] = mapped_column(
        UUID(as_uuid=False),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False, index=True
    )
    label: Mapped[str]    = mapped_column(String(255), nullable=False)
    latitude: Mapped[float]  = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    icon: Mapped[str]     = mapped_column(String(10), default="📍")
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    user: Mapped["User"] = relationship("User", back_populates="saved_places") # noqa


# ── Table alerts ──────────────────────────────────────
class Alert(Base):
    """
    Alertes GPS et SOS.
    Correspond à _sendZoneAlert() et _sendSOS() dans patient_location.dart
    Types : 'zone_exit' | 'zone_enter' | 'sos'
    """
    __tablename__ = "alerts"

    id: Mapped[str] = mapped_column(
        UUID(as_uuid=False), primary_key=True,
        default=lambda: str(uuid.uuid4())
    )
    patient_id: Mapped[str] = mapped_column(
        UUID(as_uuid=False),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False, index=True
    )
    companion_id: Mapped[str] = mapped_column(
        UUID(as_uuid=False), nullable=True
    )
    # 'zone_exit' | 'zone_enter' | 'sos'
    type: Mapped[str]            = mapped_column(String(50), nullable=False)
    distance_meters: Mapped[float] = mapped_column(Float, nullable=True)
    is_read: Mapped[bool]        = mapped_column(default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    patient: Mapped["User"] = relationship(               # noqa
        "User", back_populates="alerts_as_patient",
        foreign_keys=[patient_id]
    )