"""
Tasks Router (standalone) — opérations sur les tâches accessibles
par le caregiver depuis /api/tasks (en plus de /api/caregiver/tasks).

GET    /api/tasks/{patient_id}/{task_date}  — lire les tâches
POST   /api/tasks/bulk                      — envoyer (bulk replace)
PATCH  /api/tasks/{task_id}                 — modifier
PATCH  /api/tasks/{task_id}/status          — mettre à jour le statut
DELETE /api/tasks/{task_id}                 — supprimer
"""
import uuid
from datetime import date

from fastapi import APIRouter, HTTPException, status

from app.core.dependencies import CaregiverOnly, CurrentUser, DbDep
from app.schemas.task_schema import TaskBulkIn, TaskOut, TaskStatusIn, TaskUpdateIn
from app.services.task_service import TaskService

router = APIRouter()


@router.get("/{patient_id}/{task_date}", response_model=list[TaskOut])
async def get_tasks(
    db: DbDep,
    patient_id: uuid.UUID,
    task_date: date,
    _: CurrentUser,
):
    """Tâches d'un patient pour une date donnée."""
    return await TaskService.get_by_date(db, patient_id, task_date)


@router.post("/bulk", response_model=list[TaskOut], status_code=status.HTTP_201_CREATED)
async def bulk_send(db: DbDep, body: TaskBulkIn, current_user: CaregiverOnly):
    """
    Envoyer / remplacer les tâches pour une date.
    Mirror de Flutter sendTasks() — delete + re-insert groupé par type.
    """
    return await TaskService.bulk_replace(
        db,
        caregiver_id=current_user.id,
        patient_id=body.patient_id,
        task_date=body.task_date,
        raw_tasks=body.tasks,
    )


@router.patch("/{task_id}", response_model=TaskOut)
async def update_task(db: DbDep, task_id: uuid.UUID, body: TaskUpdateIn, _: CaregiverOnly):
    task = await TaskService.get_by_id(db, task_id)
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Tâche introuvable")
    return await TaskService.update(db, task, body)


@router.patch("/{task_id}/status", response_model=TaskOut)
async def update_status(db: DbDep, task_id: uuid.UUID, body: TaskStatusIn, _: CurrentUser):
    """
    Mise à jour du statut d'une sous-tâche (patient confirme/annule).
    Mirror de Flutter SupabaseService.updateTaskStatus.
    """
    task = await TaskService.get_by_id(db, task_id)
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Tâche introuvable")
    return await TaskService.update_status(db, task, body)


@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_task(db: DbDep, task_id: uuid.UUID, _: CaregiverOnly):
    task = await TaskService.get_by_id(db, task_id)
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Tâche introuvable")
    await TaskService.delete(db, task)