
"""
Auth Router
POST /api/auth/register  — inscription email+mot de passe
POST /api/auth/login     — connexion (OAuth2 password flow)
POST /api/auth/role      — assigner un rôle après inscription
GET  /api/auth/me        — profil de l'utilisateur connecté
"""
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm

from app.core.dependencies import CurrentUser, DbDep
from app.core.security import create_access_token
from app.schemas.user_schema import RegisterIn, RoleAssign, TokenOut, UserOut
from app.services.auth_service import AuthService

router = APIRouter()


@router.post("/register", response_model=TokenOut, status_code=status.HTTP_201_CREATED)
async def register(db: DbDep, body: RegisterIn):
    """Créer un nouveau compte."""
    user = await AuthService.register(db, body)
    token = create_access_token(str(user.id))
    return TokenOut(access_token=token, user=UserOut.model_validate(user))


@router.post("/login", response_model=TokenOut)
async def login(
    db: DbDep,
    form_data: Annotated[OAuth2PasswordRequestForm, Depends()],
):
    """Connexion — le champ 'username' correspond à l'email."""
    user = await AuthService.authenticate(db, form_data.username, form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email ou mot de passe incorrect",
            headers={"WWW-Authenticate": "Bearer"},
        )
    token = create_access_token(str(user.id))
    return TokenOut(access_token=token, user=UserOut.model_validate(user))


@router.post("/role", response_model=UserOut)
async def assign_role(db: DbDep, body: RoleAssign, current_user: CurrentUser):
    """Assigner un rôle à l'utilisateur connecté (patient / caregiver / médecin)."""
    user = await AuthService.assign_role(db, current_user, body.role)
    return UserOut.model_validate(user)


@router.get("/me", response_model=UserOut)
async def me(current_user: CurrentUser):
    """Retourner le profil de l'utilisateur connecté."""
    return UserOut.model_validate(current_user)
