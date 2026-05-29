"""
Doctor Router — endpoints pour le médecin.

GET   /api/doctor/profile          — profil
PATCH /api/doctor/profile          — mettre à jour profil
GET   /api/doctor/patients         — liste des patients
GET   /api/doctor/patients/{id}    — détail d'un patient
"""
from typing import Optional

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select

from app.core.dependencies import CurrentUser, DbDep, DoctorOnly
from app.models.user import User
from app.schemas.user_schema import UserOut

router = APIRouter()


class DoctorProfileIn(BaseModel):
    full_name: Optional[str] = None
    specialty: Optional[str] = None
    clinic_name: Optional[str] = None
    clinic_address: Optional[str] = None
    phone: Optional[str] = None
    avatar_url: Optional[str] = None


@router.get("/profile", response_model=UserOut)
async def get_profile(current_user: DoctorOnly):
    """Retourner le profil du médecin connecté."""
    return UserOut.model_validate(current_user)


@router.patch("/profile", response_model=UserOut)
async def update_profile(db: DbDep, body: DoctorProfileIn, current_user: DoctorOnly):
    """Mettre à jour le profil du médecin."""
    from app.services.user_service import UserService
    user = await UserService.update_doctor_profile(
        db, current_user, body.model_dump(exclude_none=True)
    )
    return UserOut.model_validate(user)


@router.get("/patients", response_model=list[UserOut])
async def list_patients(db: DbDep, current_user: DoctorOnly):
    """Liste de tous les patients (accès médecin)."""
    result = await db.execute(
        select(User).where(User.role == "patient", User.is_active == True)  # noqa: E712
    )
    return [UserOut.model_validate(u) for u in result.scalars().all()]


@router.get("/patients/{patient_id}", response_model=UserOut)
async def get_patient(db: DbDep, patient_id: str, current_user: DoctorOnly):
    """Détail d'un patient spécifique."""
    result = await db.execute(
        select(User).where(User.id == patient_id, User.role == "patient")
    )
    patient = result.scalar_one_or_none()
    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient introuvable",
        )
    return UserOut.model_validate(patient)
