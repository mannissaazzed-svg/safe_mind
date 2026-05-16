"""
app/schemas/auth_schemas.py
Validation des données auth
"""
from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime


# ── Requêtes entrantes ───────────────────────────────

class RegisterRequest(BaseModel):
    """sign_up.dart — signUpWithEmailPassword()"""
    email: EmailStr
    password: str


class LoginRequest(BaseModel):
    """login.dart — signInWithEmailPassword()"""
    email: EmailStr
    password: str


class OAuthRequest(BaseModel):
    """login.dart — signInWithGoogle/Facebook/Apple()"""
    provider: str         # 'google' | 'facebook' | 'apple'
    oauth_token: str
    email: Optional[EmailStr] = None
    full_name: Optional[str]  = None
    avatar_url: Optional[str] = None


class RefreshRequest(BaseModel):
    refresh_token: str


class SetRoleRequest(BaseModel):
    """person.dart — setRole()"""
    role: str             # 'patient' | 'caregiver' | 'médecin'


class UpdateProfileRequest(BaseModel):
    """
    patient_profile.dart — _save()
    caregiver_profile.dart — _save()
    """
    full_name: Optional[str]     = None
    disease: Optional[str]       = None
    patient_filled: Optional[bool] = None


class LinkByCodeRequest(BaseModel):
    """link_by_code_widget.dart — _link()"""
    code: str             # 8 caractères majuscules


class UpdateFCMTokenRequest(BaseModel):
    """Mise à jour token FCM pour notifications push"""
    fcm_token: str


# ── Réponses sortantes ───────────────────────────────

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user_id: str
    role: Optional[str]      = None
    full_name: Optional[str] = None


class UserResponse(BaseModel):
    """
    Réponse complète utilisateur.
    Utilisée par AuthGate : role, full_name, linked_to, patient_filled, disease
    """
    id: str
    email: str
    role: Optional[str]       = None
    full_name: Optional[str]  = None
    avatar_url: Optional[str] = None
    linked_to: Optional[str]  = None
    disease: Optional[str]    = None
    patient_filled: bool       = False
    created_at: datetime

    class Config:
        from_attributes = True


class MyCodeResponse(BaseModel):
    """my_code.dart — code de liaison 8 caractères"""
    code: str
    user_id: str