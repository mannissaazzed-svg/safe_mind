"""
app/models/medicine.py
Tables médicaments

Pages concernées :
- patient/medicaments.dart (MedicinesPage) :
    patient_medicines : StreamBuilder filtre par patient_id
    medicines         : bibliothèque globale (image_url)

- soignant/medicine_form.dart (MedicineForm) :
    CRUD sur patient_medicines
"""
import uuid
from datetime import datetime
from sqlalchemy import String, Integer, DateTime, Text, ForeignKey, Float
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID
from app.core.database import Base


# ── Table medicines (bibliothèque globale) ────────────
class Medicine(Base):
    """
    Bibliothèque globale de médicaments.
    Dans medicaments.dart : query .from('medicines').select('image_url').eq('name', ...)
    """
    __tablename__ = "medicines"

    id: Mapped[str] = mapped_column(
        UUID(as_uuid=False), primary_key=True,
        default=lambda: str(uuid.uuid4())
    )
    name: Mapped[str]       = mapped_column(String(255), nullable=False, unique=True, index=True)
    image_url: Mapped[str]  = mapped_column(Text, nullable=True)
    description: Mapped[str]= mapped_column(Text, nullable=True)
    # 'Alzheimer' | 'Parkinson' | 'Alzheimer & Parkinson' | null (universel)
    disease_type: Mapped[str] = mapped_column(String(100), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    patient_medicines: Mapped[list["PatientMedicine"]] = relationship( # noqa
        "PatientMedicine", back_populates="medicine_ref"
    )


# ── Table patient_medicines ───────────────────────────
class PatientMedicine(Base):
    """
    Médicaments prescrits à un patient spécifique.
    Dans medicaments.dart :
      .from('patient_medicines').stream(primaryKey: ['id']).eq('patient_id', ...)
    Champs affichés : name, dose, frequency, image_url
    """
    __tablename__ = "patient_medicines"

    id: Mapped[str] = mapped_column(
        UUID(as_uuid=False), primary_key=True,
        default=lambda: str(uuid.uuid4())
    )

    # Lien patient
    patient_id: Mapped[str] = mapped_column(
        UUID(as_uuid=False),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False, index=True
    )

    # Lien bibliothèque (optionnel)
    medicine_id: Mapped[str] = mapped_column(
        UUID(as_uuid=False),
        ForeignKey("medicines.id", ondelete="SET NULL"),
        nullable=True
    )

    # Données directes (soignant peut entrer sans passer par bibliothèque)
    name: Mapped[str]       = mapped_column(String(255), nullable=False)
    dose: Mapped[str]       = mapped_column(String(100), nullable=True)   # "5mg"
    frequency: Mapped[int]  = mapped_column(Integer, nullable=True)        # fois/jour
    image_url: Mapped[str]  = mapped_column(Text, nullable=True)
    notes: Mapped[str]      = mapped_column(Text, nullable=True)

    # Soignant qui a prescrit
    prescribed_by: Mapped[str] = mapped_column(
        UUID(as_uuid=False), nullable=True
    )

    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )

    patient: Mapped["User"] = relationship(                # noqa
        "User", back_populates="patient_medicines",
        foreign_keys=[patient_id]
    )
    medicine_ref: Mapped["Medicine"] = relationship(       # noqa
        "Medicine", back_populates="patient_medicines"
    )