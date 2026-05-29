"""
Notifications Router

GET   /api/notifications           — liste des notifications
PATCH /api/notifications/{id}/read — marquer une notification comme lue
PATCH /api/notifications/read-all  — tout marquer comme lu
"""
import uuid

from fastapi import APIRouter, HTTPException, status

from app.core.dependencies import CurrentUser, DbDep
from app.schemas.notification_schema import NotificationOut
from app.services.notification_service import NotificationService

router = APIRouter()


@router.get("/", response_model=list[NotificationOut])
async def list_notifications(db: DbDep, current_user: CurrentUser):
    """Toutes les notifications de l'utilisateur connecté."""
    return await NotificationService.list_for_user(db, current_user.id)


@router.patch("/{notif_id}/read", response_model=NotificationOut)
async def mark_read(db: DbDep, notif_id: uuid.UUID, current_user: CurrentUser):
    """Marquer une notification comme lue."""
    n = await NotificationService.mark_read(db, notif_id, current_user.id)
    if not n:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification introuvable",
        )
    return NotificationOut.model_validate(n)


@router.patch("/read-all", response_model=dict)
async def mark_all_read(db: DbDep, current_user: CurrentUser):
    """Marquer toutes les notifications comme lues."""
    count = await NotificationService.mark_all_read(db, current_user.id)
    return {"marked_read": count}
