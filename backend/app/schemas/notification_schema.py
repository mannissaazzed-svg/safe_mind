from __future__ import annotations

import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class NotificationOut(BaseModel):
    id: uuid.UUID
    recipient_id: uuid.UUID
    title: str
    body: str
    type: Optional[str]
    is_read: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class NotificationIn(BaseModel):
    recipient_id: uuid.UUID
    title: str
    body: str
    type: Optional[str] = None
