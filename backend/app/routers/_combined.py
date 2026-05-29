import uuid

from fastapi import APIRouter, HTTPException, status

from app.core.dependencies import CaregiverOnly, CurrentUser, DbDep
from app.schemas.other_schemas import (
    AppointmentCreate,
    AppointmentOut,
    AppointmentUpdate,
    LocationOut,
    LocationUpdate,
    NotificationOut,
)
from app.services.other_services import AppointmentService, LocationService, NotificationService


appointments_router = APIRouter()


@appointments_router.get("/", response_model=list[AppointmentOut])
async def list_appointments(db: DbDep, current_user: CaregiverOnly):
    return await AppointmentService.list_for_caregiver(db, current_user.id)


@appointments_router.post("/", response_model=AppointmentOut, status_code=status.HTTP_201_CREATED)
async def create_appointment(
    db: DbDep,
    body: AppointmentCreate,
    current_user: CaregiverOnly,
):
    if body.patient_id is None and current_user.linked_to:
        body = body.model_copy(update={"patient_id": current_user.linked_to})
    return await AppointmentService.create(db, current_user.id, body)


@appointments_router.patch("/{appt_id}", response_model=AppointmentOut)
async def update_appointment(
    db: DbDep,
    appt_id: uuid.UUID,
    body: AppointmentUpdate,
    current_user: CaregiverOnly,
):
    appt = await AppointmentService.get_by_id(db, appt_id)
    if not appt or appt.caregiver_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Rendez-vous introuvable")
    return await AppointmentService.update(db, appt, body)


@appointments_router.delete("/{appt_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_appointment(
    db: DbDep,
    appt_id: uuid.UUID,
    current_user: CaregiverOnly,
):
    appt = await AppointmentService.get_by_id(db, appt_id)
    if not appt or appt.caregiver_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Rendez-vous introuvable")
    await AppointmentService.delete(db, appt)



locations_router = APIRouter()


@locations_router.post("/update", response_model=LocationOut)
async def update_location(db: DbDep, body: LocationUpdate, current_user: CurrentUser):
    """Upsert the caller's GPS position (patient or caregiver)."""
    loc = await LocationService.upsert(db, current_user.id, body)
    return LocationOut.model_validate(loc)


@locations_router.get("/patient/{patient_id}", response_model=LocationOut)
async def get_patient_location(
    db: DbDep,
    patient_id: uuid.UUID,
    _: CaregiverOnly,
):
    """Caregiver polls the patient's last known location."""
    loc = await LocationService.get_patient_location(db, patient_id)
    if not loc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Localisation patient introuvable",
        )
    return LocationOut.model_validate(loc)



notifications_router = APIRouter()


@notifications_router.get("/", response_model=list[NotificationOut])
async def list_notifications(db: DbDep, current_user: CurrentUser):
    return await NotificationService.list_for_user(db, current_user.id)


@notifications_router.patch("/{notif_id}/read", response_model=NotificationOut)
async def mark_read(db: DbDep, notif_id: uuid.UUID, _: CurrentUser):
    n = await NotificationService.mark_read(db, notif_id)
    if not n:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification introuvable")
    return NotificationOut.model_validate(n)