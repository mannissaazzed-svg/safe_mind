from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import decode_token

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")


DbDep = Annotated[AsyncSession, Depends(get_db)]


async def get_current_user(
    token: Annotated[str, Depends(oauth2_scheme)],
    db: DbDep,
):
    from app.models.user import User
    from sqlalchemy import select

    exc = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Identifiants invalides",
        headers={"WWW-Authenticate": "Bearer"},
    )
    user_id = decode_token(token)
    if not user_id:
        raise exc
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise exc
    return user


def require_role(*roles: str):
    """Factory — retourne une dépendance qui impose un rôle."""
    async def _check(current_user=Depends(get_current_user)):
        if current_user.role not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Réservé aux rôles : {', '.join(roles)}",
            )
        return current_user
    return _check



CurrentUser  = Annotated[object, Depends(get_current_user)]
PatientOnly  = Annotated[object, Depends(require_role("patient"))]
CaregiverOnly = Annotated[object, Depends(require_role("caregiver"))]
DoctorOnly   = Annotated[object, Depends(require_role("médecin"))]
AnyStaff     = Annotated[object, Depends(require_role("caregiver", "médecin"))]
