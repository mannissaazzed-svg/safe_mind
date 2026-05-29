from __future__ import annotations

import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class AppointmentIn(BaseModel):
    patient_id: Optional[uuid.UUID] = None
    doctor_name: str
    specialty: Optional[str] = None
    location: Optional[str] = None
    appointment_date: datetime
    notes: Optional[str] = None


class AppointmentUpdateIn(BaseModel):
    doctor_name: Optional[str] = None
    specialty: Optional[str] = None
    location: Optional[str] = None
    appointment_date: Optional[datetime] = None
    notes: Optional[str] = None


class AppointmentOut(BaseModel):
    id: uuid.UUID
    caregiver_id: uuid.UUID
    patient_id: Optional[uuid.UUID]
    doctor_name: str
    specialty: Optional[str]
    location: Optional[str]
    appointment_date: datetime
    notes: Optional[str]
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}