"""
Map Router — GPS, zones sécurisées, lieux favoris, alertes.

Correspond aux Flutter screens :
  - PatientMapScreen   (patient)
  - CompanionMapScreen (caregiver)

GPS
  POST /api/map/location               — pousser la position GPS
  GET  /api/map/location/{user_id}     — lire la dernière position

ZONE SÉCURISÉE
  PUT  /api/map/safe-zone              — créer/mettre à jour
  GET  /api/map/safe-zone/{patient_id} — lire

LIEUX FAVORIS
  GET    /api/map/places/{user_id}     — liste
  POST   /api/map/places               — ajouter
  DELETE /api/map/places/{id}          — supprimer

ALERTES
  POST   /api/map/alerts                               — créer (SOS / zone)
  GET    /api/map/alerts/companion/{id}                — liste pour caregiver
  GET    /api/map/alerts/companion/{id}/unread         — dernière non lue
  PATCH  /api/map/alerts/{id}/read                     — marquer comme lue
"""
import uuid

from fastapi import APIRouter, HTTPException, status

from app.core.dependencies import CaregiverOnly, CurrentUser, DbDep
from app.schemas.map_schema import (
    AlertIn,
    AlertOut,
    LocationOut,
    LocationPushIn,
    SafeZoneIn,
    SafeZoneOut,
    SavedPlaceIn,
    SavedPlaceOut,
)
from app.services.map_service import MapService

router = APIRouter()




@router.post("/location", response_model=LocationOut)
async def push_location(db: DbDep, body: LocationPushIn, current_user: CurrentUser):
    """
    Patient envoie sa position GPS (upsert).
    Mirror de Flutter _pushLocation → supabase.from('locations').upsert(...)
    """
    loc = await MapService.push_location(db, current_user.id, body)
    return LocationOut.model_validate(loc)


@router.get("/location/{user_id}", response_model=LocationOut)
async def get_location(db: DbDep, user_id: uuid.UUID, _: CurrentUser):
    """
    Lire la dernière position d'un utilisateur.
    Utilisé par CompanionMapScreen._loadPatientLocation.
    """
    loc = await MapService.get_location(db, user_id)
    if not loc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Position introuvable — l'utilisateur n'a jamais partagé sa localisation",
        )
    return LocationOut.model_validate(loc)




@router.put("/safe-zone", response_model=SafeZoneOut)
async def upsert_safe_zone(db: DbDep, body: SafeZoneIn, _: CaregiverOnly):
    """
    Créer ou mettre à jour la zone sécurisée d'un patient.
    Mirror de Flutter _updateSafeZone → supabase.from('safe_zones').upsert(...)
    """
    zone = await MapService.upsert_safe_zone(db, body)
    return SafeZoneOut.model_validate(zone)


@router.get("/safe-zone/{patient_id}", response_model=SafeZoneOut)
async def get_safe_zone(db: DbDep, patient_id: uuid.UUID, _: CurrentUser):
    """
    Lire la zone sécurisée d'un patient.
    Utilisé par PatientMapScreen._loadSafeZone et CompanionMapScreen._loadSafeZone.
    """
    zone = await MapService.get_safe_zone(db, patient_id)
    if not zone:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Aucune zone sécurisée définie pour ce patient",
        )
    return SafeZoneOut.model_validate(zone)




@router.get("/places/{user_id}", response_model=list[SavedPlaceOut])
async def list_places(db: DbDep, user_id: uuid.UUID, _: CurrentUser):
    """
    Lieux favoris d'un utilisateur.
    Mirror de Flutter _loadSavedPlaces → supabase.from('saved_places').select()
    """
    return await MapService.list_places(db, user_id)


@router.post("/places", response_model=SavedPlaceOut, status_code=status.HTTP_201_CREATED)
async def add_place(db: DbDep, body: SavedPlaceIn, current_user: CurrentUser):
    """Ajouter un lieu favori."""
    place = await MapService.add_place(db, current_user.id, body)
    return SavedPlaceOut.model_validate(place)


@router.delete("/places/{place_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_place(db: DbDep, place_id: int, current_user: CurrentUser):
    """Supprimer un lieu favori."""
    deleted = await MapService.delete_place(db, place_id, current_user.id)
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lieu introuvable")




@router.post("/alerts", response_model=AlertOut, status_code=status.HTTP_201_CREATED)
async def create_alert(db: DbDep, body: AlertIn, _: CurrentUser):
    """
    Créer une alerte SOS ou de zone.
    Mirror de Flutter _sendSOS / _sendZoneAlert →
      supabase.from('alerts').insert({patient_id, companion_id, type, distance_meters})
    """
    alert = await MapService.create_alert(db, body)
    return AlertOut.model_validate(alert)


@router.get("/alerts/companion/{companion_id}", response_model=list[AlertOut])
async def list_alerts(
    db: DbDep, companion_id: uuid.UUID, _: CaregiverOnly, limit: int = 10
):
    """
    Historique des alertes pour un caregiver.
    Mirror de Flutter _loadRecentAlerts.
    """
    alerts = await MapService.list_alerts(db, companion_id, limit)
    return [AlertOut.model_validate(a) for a in alerts]


@router.get("/alerts/companion/{companion_id}/unread", response_model=AlertOut | None)
async def get_unread_alert(db: DbDep, companion_id: uuid.UUID, _: CaregiverOnly):
    """
    Dernière alerte non lue — pilote la bannière temps réel de CompanionMapScreen.
    Mirror de Flutter _listenAlerts stream.
    """
    alert = await MapService.get_latest_unread(db, companion_id)
    return AlertOut.model_validate(alert) if alert else None


@router.patch("/alerts/{alert_id}/read", response_model=AlertOut)
async def mark_alert_read(db: DbDep, alert_id: int, _: CaregiverOnly):
    """
    Marquer une alerte comme lue (caregiver ferme la bannière).
    Mirror de Flutter _dismissAlert → supabase.from('alerts').update({is_read: true})
    """
    alert = await MapService.mark_alert_read(db, alert_id)
    if not alert:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Alerte introuvable")
    return AlertOut.model_validate(alert)
