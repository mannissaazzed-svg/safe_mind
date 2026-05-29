from __future__ import annotations

import uuid
from datetime import datetime
from typing import Literal, Optional

from pydantic import BaseModel, Field



class LocationPushIn(BaseModel):
    latitude: float
    longitude: float
    speed: Optional[float] = None


class LocationOut(BaseModel):
    user_id: uuid.UUID
    latitude: float
    longitude: float
    speed: Optional[float]
    updated_at: datetime

    model_config = {"from_attributes": True}



class SafeZoneIn(BaseModel):
    patient_id: uuid.UUID
    center_lat: float
    center_lng: float
    radius_meters: float = Field(default=200.0, ge=50.0, le=5000.0)
    label: str = "Zone sécurisée"


class SafeZoneOut(BaseModel):
    patient_id: uuid.UUID
    center_lat: float
    center_lng: float
    radius_meters: float
    label: str
    updated_at: datetime

    model_config = {"from_attributes": True}




class SavedPlaceIn(BaseModel):
    label: str = Field(min_length=1, max_length=100)
    latitude: float
    longitude: float
    icon: str = ""


class SavedPlaceOut(BaseModel):
    id: int
    user_id: uuid.UUID
    label: str
    latitude: float
    longitude: float
    icon: str
    created_at: datetime

    model_config = {"from_attributes": True}




class AlertIn(BaseModel):
    patient_id: uuid.UUID
    companion_id: Optional[uuid.UUID] = None
    type: Literal["sos", "zone_exit", "zone_enter"]
    distance_meters: Optional[float] = None


class AlertOut(BaseModel):
    id: int
    patient_id: uuid.UUID
    companion_id: Optional[uuid.UUID]
    type: str
    distance_meters: Optional[float]
    is_read: bool
    created_at: datetime

    model_config = {"from_attributes": True}