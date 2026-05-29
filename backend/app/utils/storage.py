"""
Utilitaires Supabase Storage — upload avatar / image médicament.
"""
from __future__ import annotations

import uuid
from typing import Optional

import httpx

from app.core.config import settings


async def upload_bytes(
    bucket: str,
    path: str,
    data: bytes,
    content_type: str = "image/jpeg",
) -> Optional[str]:
    """Upload brut vers Supabase Storage. Retourne l'URL publique ou None."""
    url = f"{settings.SUPABASE_URL}/storage/v1/object/{bucket}/{path}"
    headers = {
        "Authorization": f"Bearer {settings.SUPABASE_SERVICE_KEY}",
        "Content-Type": content_type,
    }
    async with httpx.AsyncClient() as client:
        resp = await client.post(url, content=data, headers=headers)
    if resp.status_code not in (200, 201):
        return None
    return public_url(bucket, path)


def public_url(bucket: str, path: str) -> str:
    return f"{settings.SUPABASE_URL}/storage/v1/object/public/{bucket}/{path}"


def avatar_path(user_id: str) -> str:
    return f"avatars/{user_id}-{uuid.uuid4().hex}.jpg"


def medicine_image_path() -> str:
    return f"med_{uuid.uuid4().hex}.jpg"
