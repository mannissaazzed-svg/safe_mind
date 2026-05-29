"""
Patient Router — endpoints pour le patient.

PROFIL & HOME
  PATCH /api/patient/profile              — mettre à jour profil
  GET   /api/patient/home                 — données écran Home (maladie, caregiver)
  POST  /api/patient/link                 — lier par code du caregiver

TÂCHES (lecture + statut)
  GET   /api/patient/tasks/{date}         — tâches du jour
  PATCH /api/patient/tasks/{id}/status    — confirmer/annuler une sous-tâche

MÉDICAMENTS (lecture seule)
  GET   /api/patient/medicines            — mes médicaments prescrits
"""
import uuid
from datetime import date

from fastapi import APIRouter, HTTPException, status

from app.core.dependencies import DbDep, PatientOnly
from app.schemas.medicine_schema import PatientMedicineOut
from app.schemas.task_schema import TaskOut, TaskStatusIn
from app.schemas.user_schema import LinkByCode, PatientHomeOut, PatientProfileIn, UserOut
from app.services.medicine_service import MedicineService
from app.services.task_service import TaskService
from app.services.user_service import UserService

router = APIRouter()



@router.get("/profile", response_model=UserOut)
async def get_profile(current_user: PatientOnly):
    """Retourner le profil du patient."""
    return UserOut.model_validate(current_user)



@router.patch("/profile", response_model=UserOut)
async def update_profile(db: DbDep, body: PatientProfileIn, current_user: PatientOnly):
    """Mettre à jour le profil du patient (nom, avatar)."""
    user = await UserService.update_patient_profile(db, current_user, body)
    return UserOut.model_validate(user)


@router.get("/home", response_model=PatientHomeOut)
async def patient_home(db: DbDep, current_user: PatientOnly):
    """
    Données pour l'écran Home Flutter :
    maladie (synchronisée depuis caregiver si absente), nom/avatar caregiver.
    """
    data = await UserService.get_patient_home_data(db, current_user)
    return PatientHomeOut(**data)


@router.post("/link", response_model=UserOut)
async def link_to_caregiver(db: DbDep, body: LinkByCode, current_user: PatientOnly):
    """
    Le patient entre le code de son caregiver pour se lier.
    (LinkByCodeWidget — currentRole='patient')
    """
    user = await UserService.link_by_code(db, current_user, body.code)
    return UserOut.model_validate(user)




@router.get("/tasks/{task_date}", response_model=list[TaskOut])
async def get_tasks(db: DbDep, task_date: date, current_user: PatientOnly):
    """
    Tâches du patient pour une date (PatientPage + streamTasksByDate).
    """
    return await TaskService.get_by_date(db, current_user.id, task_date)


@router.patch("/tasks/{task_id}/status", response_model=TaskOut)
async def update_task_status(
    db: DbDep, task_id: uuid.UUID, body: TaskStatusIn, current_user: PatientOnly
):
    """
    Le patient confirme (vert/orange) ou annule (rouge) une sous-tâche.
    Mirror de Flutter showTaskDialog → SupabaseService.updateTaskStatus.
    """
    task = await TaskService.get_by_id(db, task_id)
    if not task or task.patient_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Tâche introuvable")
    return await TaskService.update_status(db, task, body)




@router.get("/medicines", response_model=list[PatientMedicineOut])
async def get_medicines(db: DbDep, current_user: PatientOnly):
    """
    Médicaments prescrits au patient (MedicinesPage StreamBuilder).
    """
    return await MedicineService.list_by_patient(db, current_user.id)
