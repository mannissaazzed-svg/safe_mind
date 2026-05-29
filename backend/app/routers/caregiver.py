"""
Caregiver Router — endpoints pour l'aide-soignant.

PROFIL
  PATCH /api/caregiver/profile          — mettre à jour nom/maladie/avatar
  POST  /api/caregiver/patient-form     — remplir le formulaire médical du patient
  POST  /api/caregiver/link             — lier par code 8 car.
  GET   /api/caregiver/linked-patient   — infos du patient lié

TÂCHES
  GET    /api/caregiver/tasks/{patient_id}/{date}  — lire les tâches
  POST   /api/caregiver/tasks/bulk                — envoyer/remplacer les tâches (sendTasks)
  PATCH  /api/caregiver/tasks/{task_id}           — modifier une tâche
  DELETE /api/caregiver/tasks/{task_id}           — supprimer

MÉDICAMENTS
  GET    /api/caregiver/medicines                         — mes prescriptions
  POST   /api/caregiver/medicines                         — ajouter
  DELETE /api/caregiver/medicines/{id}                    — supprimer
  GET    /api/caregiver/medicines/catalogue/{disease}     — catalogue global
  GET    /api/caregiver/medicines/barcode/{code}          — recherche par code-barre

RENDEZ-VOUS
  GET    /api/caregiver/appointments    — liste
  POST   /api/caregiver/appointments   — créer
  PATCH  /api/caregiver/appointments/{id} — modifier
  DELETE /api/caregiver/appointments/{id} — supprimer
"""
import uuid
from datetime import date

from fastapi import APIRouter, HTTPException, status

from app.core.dependencies import CaregiverOnly, DbDep
from app.schemas.appointment_schema import AppointmentIn, AppointmentOut, AppointmentUpdateIn
from app.schemas.medicine_schema import PatientMedicineIn, PatientMedicineOut, MedicineOut
from app.schemas.task_schema import TaskBulkIn, TaskOut, TaskUpdateIn
from app.schemas.user_schema import CaregiverProfileIn, LinkByCode, PatientFormIn, UserOut
from app.services.appointment_service import AppointmentService
from app.services.medicine_service import MedicineService
from app.services.task_service import TaskService
from app.services.user_service import UserService

router = APIRouter()




@router.get("/profile", response_model=UserOut)
async def get_profile(current_user: CaregiverOnly):
    """Retourner le profil du caregiver."""
    return UserOut.model_validate(current_user)

@router.patch("/profile", response_model=UserOut)
async def update_profile(db: DbDep, body: CaregiverProfileIn, current_user: CaregiverOnly):
    """Mettre à jour le profil du caregiver (nom, maladie suivie, avatar)."""
    user = await UserService.update_caregiver_profile(db, current_user, body)
    return UserOut.model_validate(user)


@router.post("/patient-form", response_model=UserOut)
async def fill_patient_form(db: DbDep, body: PatientFormIn, current_user: CaregiverOnly):
    """
    Remplir le formulaire médical du patient suivi.
    Marque patient_filled=True et synchronise la maladie sur le patient lié.
    """
    user = await UserService.fill_patient_form(db, current_user, body)
    return UserOut.model_validate(user)


@router.post("/link", response_model=UserOut)
async def link_by_code(db: DbDep, body: LinkByCode, current_user: CaregiverOnly):
    """
    Lier le caregiver à un patient via le code à 8 caractères.
    Code = 8 premiers caractères de l'UUID du patient (majuscules).
    """
    user = await UserService.link_by_code(db, current_user, body.code)
    return UserOut.model_validate(user)


@router.get("/linked-patient", response_model=UserOut)
async def get_linked_patient(db: DbDep, current_user: CaregiverOnly):
    """Retourner les informations du patient lié."""
    patient = await UserService.get_linked_patient(db, current_user)
    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Aucun patient lié",
        )
    return UserOut.model_validate(patient)




@router.get("/tasks/{patient_id}/{task_date}", response_model=list[TaskOut])
async def get_tasks(
    db: DbDep,
    patient_id: uuid.UUID,
    task_date: date,
    current_user: CaregiverOnly,
):
    """Lire les tâches d'un patient pour une date donnée (écran Suivi)."""
    return await TaskService.get_by_date(db, patient_id, task_date)


@router.post("/tasks/bulk", response_model=list[TaskOut], status_code=status.HTTP_201_CREATED)
async def send_tasks(db: DbDep, body: TaskBulkIn, current_user: CaregiverOnly):
    """
    Envoyer / remplacer les tâches d'un patient pour une date.
    Mirror exact de Flutter sendTasks() — supprime puis recrée groupé par type.
    """
    tasks = await TaskService.bulk_replace(
        db,
        caregiver_id=current_user.id,
        patient_id=body.patient_id,
        task_date=body.task_date,
        raw_tasks=body.tasks,
    )
    return tasks


@router.patch("/tasks/{task_id}", response_model=TaskOut)
async def update_task(
    db: DbDep,
    task_id: uuid.UUID,
    body: TaskUpdateIn,
    current_user: CaregiverOnly,
):
    """Modifier une tâche existante."""
    task = await TaskService.get_by_id(db, task_id)
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Tâche introuvable")
    return await TaskService.update(db, task, body)


@router.delete("/tasks/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_task(db: DbDep, task_id: uuid.UUID, current_user: CaregiverOnly):
    """Supprimer une tâche."""
    task = await TaskService.get_by_id(db, task_id)
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Tâche introuvable")
    await TaskService.delete(db, task)




@router.get("/medicines/catalogue/{disease_type}", response_model=list[MedicineOut])
async def list_catalogue(db: DbDep, disease_type: str, current_user: CaregiverOnly):
    """Catalogue de médicaments pour un type de maladie (MedicineForm — liste suggestions)."""
    return await MedicineService.list_catalogue(db, disease_type)


@router.get("/medicines/barcode/{barcode}", response_model=MedicineOut)
async def find_by_barcode(db: DbDep, barcode: str, current_user: CaregiverOnly):
    """Recherche d'un médicament par code-barre (scanner)."""
    med = await MedicineService.find_by_barcode(db, barcode)
    if not med:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Code-barre non trouvé dans le catalogue",
        )
    return med


@router.get("/medicines", response_model=list[PatientMedicineOut])
async def list_medicines(db: DbDep, current_user: CaregiverOnly):
    """Mes prescriptions pour le patient lié."""
    return await MedicineService.list_by_caregiver(db, current_user.id)


@router.post("/medicines", response_model=PatientMedicineOut, status_code=status.HTTP_201_CREATED)
async def add_medicine(db: DbDep, body: PatientMedicineIn, current_user: CaregiverOnly):
    """
    Ajouter un médicament pour le patient.
    Si patient_id absent, utilise le patient lié au caregiver.
    """
    if body.patient_id is None and current_user.linked_to:
        body = body.model_copy(update={"patient_id": current_user.linked_to})
    return await MedicineService.add(db, current_user.id, body)


@router.delete("/medicines/{pm_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_medicine(db: DbDep, pm_id: uuid.UUID, current_user: CaregiverOnly):
    """Supprimer une prescription."""
    deleted = await MedicineService.delete(db, pm_id, current_user.id)
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Médicament introuvable")



@router.get("/appointments", response_model=list[AppointmentOut])
async def list_appointments(db: DbDep, current_user: CaregiverOnly):
    """Liste des rendez-vous (écran RendezVous)."""
    return await AppointmentService.list_for_caregiver(db, current_user.id)


@router.post("/appointments", response_model=AppointmentOut, status_code=status.HTTP_201_CREATED)
async def create_appointment(db: DbDep, body: AppointmentIn, current_user: CaregiverOnly):
    """Créer un rendez-vous médecin."""
    if body.patient_id is None and current_user.linked_to:
        body = body.model_copy(update={"patient_id": current_user.linked_to})
    return await AppointmentService.create(db, current_user.id, body)


@router.patch("/appointments/{appt_id}", response_model=AppointmentOut)
async def update_appointment(
    db: DbDep, appt_id: uuid.UUID, body: AppointmentUpdateIn, current_user: CaregiverOnly
):
    """Modifier un rendez-vous."""
    appt = await AppointmentService.get_by_id(db, appt_id)
    if not appt or appt.caregiver_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Rendez-vous introuvable")
    return await AppointmentService.update(db, appt, body)


@router.delete("/appointments/{appt_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_appointment(db: DbDep, appt_id: uuid.UUID, current_user: CaregiverOnly):
    """Supprimer un rendez-vous."""
    appt = await AppointmentService.get_by_id(db, appt_id)
    if not appt or appt.caregiver_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Rendez-vous introuvable")
    await AppointmentService.delete(db, appt)