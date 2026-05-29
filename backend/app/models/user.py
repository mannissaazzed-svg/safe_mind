import uuid
from datetime import datetime

from sqlalchemy import String, DateTime, Boolean, func, Integer
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class User(Base):
    __tablename__ = "users"

    
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4
    )

    
    email: Mapped[str] = mapped_column(
        String(255),
        unique=True,
        index=True,
        nullable=False
    )

    hashed_password: Mapped[str] = mapped_column(
        String(255),
        nullable=False
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

   
    full_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    name: Mapped[str | None] = mapped_column(String(255), nullable=True)

    role: Mapped[str | None] = mapped_column(String(50), nullable=True)
    disease: Mapped[str | None] = mapped_column(String(100), nullable=True)

    avatar_url: Mapped[str | None] = mapped_column(String(255), nullable=True)

    
    linked_to: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), nullable=True)
    linked_user_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), nullable=True)
    associated_patient_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), nullable=True)

    connection_code: Mapped[str | None] = mapped_column(String(100), nullable=True)
    short_code: Mapped[str | None] = mapped_column(String(100), nullable=True)
    doctor_code: Mapped[str | None] = mapped_column(String(100), nullable=True)

    
    patient_filled: Mapped[bool] = mapped_column(Boolean, default=False)
    is_online: Mapped[bool] = mapped_column(Boolean, default=False)
    name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    patient_age: Mapped[int | None] = mapped_column(Integer, nullable=True)
    patient_phone: Mapped[str | None] = mapped_column(String(50), nullable=True)
    patient_genre: Mapped[str | None] = mapped_column(String(20), nullable=True)

    symptoms: Mapped[str | None] = mapped_column(String(255), nullable=True)

   
    last_seen: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now()
    )

    def __repr__(self) -> str:
        return f"<User {self.email}>"