"""Service tâches — CRUD, envoi groupé, mise à jour du statut."""
from __future__ import annotations

import uuid
from datetime import date
from typing import Optional

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.task import Task
from app.schemas.task_schema import TaskCreateIn, TaskStatusIn, TaskUpdateIn
from app.utils.task_helpers import get_task_style


class TaskService:

    @staticmethod
    async def get_by_date(
        db: AsyncSession, patient_id: uuid.UUID, task_date: date
    ) -> list[Task]:
        result = await db.execute(
            select(Task)
            .where(Task.patient_id == patient_id, Task.task_date == task_date)
            .order_by(Task.created_at)
        )
        return list(result.scalars().all())

    @staticmethod
    async def get_by_id(db: AsyncSession, task_id: uuid.UUID) -> Optional[Task]:
        result = await db.execute(select(Task).where(Task.id == task_id))
        return result.scalar_one_or_none()

    @staticmethod
    async def create(
        db: AsyncSession, caregiver_id: uuid.UUID, data: TaskCreateIn
    ) -> Task:
        task = Task(
            patient_id=data.patient_id,
            caregiver_id=caregiver_id,
            title=data.title,
            color=data.color,
            image=data.image,
            task_date=data.task_date,
            sub_tasks=[s.model_dump() for s in data.sub_tasks],
            status={},
        )
        db.add(task)
        await db.flush()
        return task

    @staticmethod
    async def bulk_replace(
        db: AsyncSession,
        caregiver_id: uuid.UUID,
        patient_id: uuid.UUID,
        task_date: date,
        raw_tasks: list[dict],
    ) -> list[Task]:
        """
        Remplace toutes les tâches d'un patient pour une date donnée.
        Groupe les tâches par type (mirror de Flutter sendTasks).
        raw_tasks = [{"type": "medicine", "time": "08:00", "detail": "Levodopa"}, ...]
        """
        # Supprimer les tâches existantes
        await db.execute(
            delete(Task).where(
                Task.patient_id == patient_id, Task.task_date == task_date
            )
        )
        await db.flush()

        # Grouper par type
        grouped: dict[str, list[dict]] = {}
        for t in raw_tasks:
            grouped.setdefault(t["type"], []).append(t)

        created: list[Task] = []
        for task_type, items in grouped.items():
            style = get_task_style(task_type)
            task = Task(
                patient_id=patient_id,
                caregiver_id=caregiver_id,
                title=task_type,
                color=style["color"],
                image=style["image"],
                task_date=task_date,
                sub_tasks=[
                    {"title": f"{item.get('time', '')} {item.get('detail', '')}".strip()}
                    for item in items
                ],
                status={},
            )
            db.add(task)
            created.append(task)

        await db.flush()
        return created

    @staticmethod
    async def update(
        db: AsyncSession, task: Task, data: TaskUpdateIn
    ) -> Task:
        for field, value in data.model_dump(exclude_none=True).items():
            if field == "sub_tasks" and value is not None:
                setattr(task, field, [s.model_dump() for s in value])
            else:
                setattr(task, field, value)
        db.add(task)
        await db.flush()
        return task

    @staticmethod
    async def update_status(
        db: AsyncSession, task: Task, data: TaskStatusIn
    ) -> Task:
        """
        Mise à jour du statut d'une sous-tâche.
        Mirror de Flutter SupabaseService.updateTaskStatus.
        """
        current = dict(task.status or {})
        current[data.sub_key] = data.color
        task.status = current
        db.add(task)
        await db.flush()
        return task

    @staticmethod
    async def delete(db: AsyncSession, task: Task) -> None:
        await db.delete(task)
        await db.flush()
