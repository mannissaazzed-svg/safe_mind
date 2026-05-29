"""Service d'authentification — inscription, connexion, rôle."""
from __future__ import annotations
from app.utils.code_generator import generate_short_code
import uuid
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import hash_password, verify_password
from app.models.user import User
from app.schemas.user_schema import RegisterIn


class AuthService:

    @staticmethod
    async def get_by_id(db: AsyncSession, user_id: str | uuid.UUID) -> Optional[User]:
        result = await db.execute(select(User).where(User.id == user_id))
        return result.scalar_one_or_none()

    @staticmethod
    async def get_by_email(db: AsyncSession, email: str) -> Optional[User]:
        result = await db.execute(select(User).where(User.email == email))
        return result.scalar_one_or_none()

    @staticmethod
    async def register(db: AsyncSession, data: RegisterIn) -> User:
        existing = await AuthService.get_by_email(db, data.email)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Un compte avec cet email existe déjà",
            )
        user = User(
    email=data.email,
    hashed_password=hash_password(data.password),
    )
        db.add(user)
        await db.flush()  # id generated
        user.short_code = generate_short_code(user.id)
        await db.flush()  # save short_code
        return user

    @staticmethod
    async def authenticate(
        db: AsyncSession, email: str, password: str
    ) -> Optional[User]:
        user = await AuthService.get_by_email(db, email)
        if not user or not user.hashed_password:
            return None
        if not verify_password(password, user.hashed_password):
            return None
        return user

    @staticmethod
    async def assign_role(db: AsyncSession, user: User, role: str) -> User:
        user.role = role
        db.add(user)
        await db.flush()
        return user
