from pydantic import BaseModel
from typing import Optional

class UserCreate(BaseModel):
    email: str
    password: str

class RoleUpdate(BaseModel):
    role: str

class UserProfile(BaseModel):
    full_name: Optional[str]
    disease: Optional[str]