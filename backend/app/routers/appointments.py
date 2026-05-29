"""
Appointments Router (standalone) — rendez-vous médecin.

GET    /api/appointments           — liste des RDV du caregiver
POST   /api/appointments           — créer un RDV
PATCH  /api/appointments/{id}      — modifier
DELETE /api/appointments/{id}      — supprimer
"""
import uuid

from fastapi import APIRouter, HTTPException, status

from app.core.dependencies import CaregiverOnly, DbDep
from app.schemas.appointment_schema import AppointmentIn, AppointmentOut, AppointmentUpdateIn
from app.services.appointment_service import AppointmentService

router = APIRouter()


@router.get("/", response_model=list[AppointmentOut])
async def list_appointments(db: DbDep, current_user: CaregiverOnly):
    """Liste des rendez-vous (écran RendezVous Flutter)."""
    return await AppointmentService.list_for_caregiver(db, current_user.id)


@router.post("/", response_model=AppointmentOut, status_code=status.HTTP_201_CREATED)
async def create_appointment(db: DbDep, body: AppointmentIn, current_user: CaregiverOnly):
    """Créer un rendez-vous médecin."""
    if body.patient_id is None and current_user.linked_to:
        body = body.model_copy(update={"patient_id": current_user.linked_to})
    return await AppointmentService.create(db, current_user.id, body)


@router.patch("/{appt_id}", response_model=AppointmentOut)
async def update_appointment(
    db: DbDep, appt_id: uuid.UUID, body: AppointmentUpdateIn, current_user: CaregiverOnly
):
    """Modifier un rendez-vous."""
    appt = await AppointmentService.get_by_id(db, appt_id)
    if not appt or appt.caregiver_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Rendez-vous introuvable")
    return await AppointmentService.update(db, appt, body)


@router.delete("/{appt_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_appointment(db: DbDep, appt_id: uuid.UUID, current_user: CaregiverOnly):
    """Supprimer un rendez-vous."""
    appt = await AppointmentService.get_by_id(db, appt_id)
    if not appt or appt.caregiver_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Rendez-vous introuvable")
    await AppointmentService.delete(db, appt)
