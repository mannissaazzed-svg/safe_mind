from __future__ import annotations

import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field




class MedicineOut(BaseModel):
    id: uuid.UUID
    name: str
    dose: Optional[str]
    frequency: int
    disease_type: str
    barcode: Optional[str]
    image_url: Optional[str]

    model_config = {"from_attributes": True}




class PatientMedicineIn(BaseModel):
    patient_id: Optional[uuid.UUID] = None
    name: str
    dose: Optional[str] = None
    frequency: int = Field(default=1, ge=1, le=4)
    image_url: Optional[str] = None
    disease_type: Optional[str] = None


class PatientMedicineOut(BaseModel):
    id: uuid.UUID
    caregiver_id: uuid.UUID
    patient_id: Optional[uuid.UUID]
    name: str
    dose: Optional[str]
    frequency: int
    image_url: Optional[str]
    disease_type: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}