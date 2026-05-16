"""
app/schemas/task_schemas.py
Validation tâches — soignant/tasks.dart, patient/patient.dart
"""
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class TaskCreateRequest(BaseModel):
    """sendTasks() dans SupabaseService"""
    patient_id: str
    task_date: datetime
    title: str
    type: str     # 'food'|'sport'|'brain'|'doctor'|'medicine'
    time: str     # "08:00"
    detail: str   # "Déjeuner équilibré"


class TaskUpdateRequest(BaseModel):
    """updateTask() dans SupabaseService"""
    title: str
    type: str
    time: str
    detail: str


class TaskStatusRequest(BaseModel):
    """
    updateTaskStatus() dans SupabaseService
    sub_key = texte complet de la sous-tâche (ex: "08:00 Déjeuner")
    color   = 'green' | 'orange' | 'red'
    """
    sub_key: str
    color: str


class TaskResponse(BaseModel):
    id: str
    patient_id: str
    task_date: datetime
    title: str
    type: str
    color: Optional[str]  = None
    image: Optional[str]  = None
    sub_tasks: list        = []
    status: dict           = {}
    created_at: datetime

    class Config:
        from_attributes = True


"""
app/schemas/medicine_schemas.py
Validation médicaments — patient/medicaments.dart, soignant/medicine_form.dart
"""
from typing import Optional
from datetime import datetime


class MedicineLibraryResponse(BaseModel):
    """Table medicines — bibliothèque globale"""
    id: str
    name: str
    image_url: Optional[str] = None
    description: Optional[str] = None
    disease_type: Optional[str] = None

    class Config:
        from_attributes = True


class PatientMedicineCreateRequest(BaseModel):
    """soignant/medicine_form.dart — créer prescription"""
    patient_id: str
    name: str
    dose: Optional[str] = None
    frequency: Optional[int] = None
    image_url: Optional[str] = None
    notes: Optional[str] = None


class PatientMedicineUpdateRequest(BaseModel):
    name: Optional[str] = None
    dose: Optional[str] = None
    frequency: Optional[int] = None
    notes: Optional[str] = None


class PatientMedicineResponse(BaseModel):
    """
    Correspond aux champs affichés dans medicaments.dart :
    name, dose, frequency, image_url
    """
    id: str
    patient_id: str
    name: str
    dose: Optional[str] = None
    frequency: Optional[int] = None
    image_url: Optional[str] = None
    notes: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


"""
app/schemas/location_schemas.py
Validation GPS — patient_location.dart, soignant/map.dart
"""


class LocationUpdateRequest(BaseModel):
    """updateLocation() + _pushLocation()"""
    latitude: float
    longitude: float
    speed: Optional[float] = None


class LocationResponse(BaseModel):
    user_id: str
    latitude: float
    longitude: float
    speed: Optional[float] = None
    updated_at: datetime

    class Config:
        from_attributes = True


class SafeZoneCreateRequest(BaseModel):
    """Création/modification zone sécurisée"""
    patient_id: str
    center_lat: float
    center_lng: float
    radius_meters: float = 200.0


class SafeZoneResponse(BaseModel):
    id: str
    patient_id: str
    center_lat: float
    center_lng: float
    radius_meters: float
    created_at: datetime

    class Config:
        from_attributes = True


class SavedPlaceCreateRequest(BaseModel):
    """_loadSavedPlaces() — lieux enregistrés"""
    label: str
    latitude: float
    longitude: float
    icon: str = "📍"


class SavedPlaceResponse(BaseModel):
    id: int
    user_id: str
    label: str
    latitude: float
    longitude: float
    icon: str
    created_at: datetime

    class Config:
        from_attributes = True


class AlertResponse(BaseModel):
    """_sendSOS() / _sendZoneAlert()"""
    id: str
    patient_id: str
    companion_id: Optional[str] = None
    type: str
    distance_meters: Optional[float] = None
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True