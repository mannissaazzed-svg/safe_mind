from __future__ import annotations

import uuid
from datetime import date, datetime
from typing import Any, Optional

from pydantic import BaseModel, Field


class SubTaskIn(BaseModel):
    title: str 


class TaskCreateIn(BaseModel):
    patient_id: uuid.UUID
    task_date: date
    title: str  
    color: str
    image: str
    sub_tasks: list[SubTaskIn] = Field(default_factory=list)


class TaskUpdateIn(BaseModel):
    title: Optional[str] = None
    color: Optional[str] = None
    image: Optional[str] = None
    sub_tasks: Optional[list[SubTaskIn]] = None


class TaskStatusIn(BaseModel):
    """Mise à jour du statut d'une sous-tâche par le patient."""
    sub_key: str  
    color: str     


class TaskBulkIn(BaseModel):
    """
    Envoi groupé de tâches pour une date donnée.
    Remplace toutes les tâches existantes pour ce patient/date.
    Correspond à Flutter sendTasks().
    """
    patient_id: uuid.UUID
    task_date: date
    tasks: list[dict]


class TaskOut(BaseModel):
    id: uuid.UUID
    patient_id: uuid.UUID
    title: str
    color: str
    image: str
    task_date: date
    sub_tasks: list[Any]
    status: dict[str, Any]
    created_at: datetime

    model_config = {"from_attributes": True}
