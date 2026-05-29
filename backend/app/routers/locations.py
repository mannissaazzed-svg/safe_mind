"""
Locations Router (legacy) — alias vers map router pour la compatibilité.
Les nouveaux endpoints GPS sont sous /api/map/location.
Ce router expose les mêmes endpoints sous /api/locations pour
la compatibilité avec les anciennes intégrations.

POST /api/locations/push              — pousser la position GPS
GET  /api/locations/{user_id}         — lire la dernière position
"""
import uuid

from fastapi import APIRouter, HTTPException, status

from app.core.dependencies import CurrentUser, DbDep
from app.schemas.map_schema import LocationOut, LocationPushIn
from app.services.map_service import MapService

router = APIRouter()


@router.post("/push", response_model=LocationOut)
async def push_location(db: DbDep, body: LocationPushIn, current_user: CurrentUser):
    """Upsert de la position GPS du patient."""
    loc = await MapService.push_location(db, current_user.id, body)
    return LocationOut.model_validate(loc)


@router.get("/{user_id}", response_model=LocationOut)
async def get_location(db: DbDep, user_id: uuid.UUID, _: CurrentUser):
    """Lire la dernière position GPS d'un utilisateur."""
    loc = await MapService.get_location(db, user_id)
    if not loc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Position introuvable",
        )
    return LocationOut.model_validate(loc)
