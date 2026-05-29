"""Service notifications in-app."""
from __future__ import annotations

import uuid
from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.notification import Notification


class NotificationService:

    @staticmethod
    async def list_for_user(
        db: AsyncSession, user_id: uuid.UUID
    ) -> list[Notification]:
        result = await db.execute(
            select(Notification)
            .where(Notification.recipient_id == user_id)
            .order_by(Notification.created_at.desc())
        )
        return list(result.scalars().all())

    @staticmethod
    async def create(
        db: AsyncSession,
        recipient_id: uuid.UUID,
        title: str,
        body: str,
        type_: Optional[str] = None,
    ) -> Notification:
        n = Notification(
            recipient_id=recipient_id, title=title, body=body, type=type_
        )
        db.add(n)
        await db.flush()
        return n

    @staticmethod
    async def mark_read(
        db: AsyncSession, notif_id: uuid.UUID, user_id: uuid.UUID
    ) -> Optional[Notification]:
        result = await db.execute(
            select(Notification).where(
                Notification.id == notif_id,
                Notification.recipient_id == user_id,
            )
        )
        n = result.scalar_one_or_none()
        if n:
            n.is_read = True
            db.add(n)
            await db.flush()
        return n

    @staticmethod
    async def mark_all_read(db: AsyncSession, user_id: uuid.UUID) -> int:
        result = await db.execute(
            select(Notification).where(
                Notification.recipient_id == user_id,
                Notification.is_read == False,  # noqa: E712
            )
        )
        notifs = result.scalars().all()
        for n in notifs:
            n.is_read = True
            db.add(n)
        await db.flush()
        return len(notifs)
