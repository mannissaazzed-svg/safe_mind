from __future__ import annotations

import uuid
from datetime import datetime
from typing import Literal, Optional

from pydantic import BaseModel, EmailStr, Field, model_validator




class RegisterIn(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6)
    confirm_password: str

    @model_validator(mode="after")
    def passwords_match(self):
        if self.password != self.confirm_password:
            raise ValueError("Les mots de passe ne correspondent pas")
        return self


class LoginIn(BaseModel):
    email: EmailStr
    password: str


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: "UserOut"




class RoleAssign(BaseModel):
    role: Literal["patient", "caregiver", "médecin"]




class LinkByCode(BaseModel):
    """Code = 8 premiers caractères de l'UUID (en majuscules)."""
    code: str = Field(min_length=8, max_length=8)




class CaregiverProfileIn(BaseModel):
    full_name: Optional[str] = None
    disease: Optional[Literal["Alzheimer", "Parkinson", "Alzheimer & Parkinson"]] = None
    avatar_url: Optional[str] = None



class PatientFormIn(BaseModel):
    name: str
    disease: Literal["Alzheimer", "Parkinson", "Alzheimer & Parkinson"]
    patient_age: int = Field(ge=30, le=100)
    patient_phone: str = Field(pattern=r"^(0)(5|6|7)[0-9]{8}$")
    patient_genre: Literal["Homme", "Femme"]
    symptoms: Optional[str] = None




class PatientProfileIn(BaseModel):
    full_name: Optional[str] = None
    avatar_url: Optional[str] = None




class UserOut(BaseModel):
    id: uuid.UUID
    email: str
    full_name: Optional[str]
    avatar_url: Optional[str]
    role: Optional[str]
    disease: Optional[str]
    linked_to: Optional[uuid.UUID]
    patient_filled: bool
    short_code: Optional[str] = None
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}




class PatientHomeOut(BaseModel):
    user_id: uuid.UUID
    full_name: Optional[str]
    avatar_url: Optional[str]
    disease: Optional[str]
    linked_to: Optional[uuid.UUID]
    caregiver_name: Optional[str]
    caregiver_avatar: Optional[str]