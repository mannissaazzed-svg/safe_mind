from fastapi import APIRouter
from app.schemas.user_schema import UserCreate
from app.core.database import supabase

router = APIRouter(
    prefix="/auth",
    tags=["Auth"]
)

@router.post("/signup")
def signup(user: UserCreate):

    response = supabase.auth.sign_up({
        "email": user.email,
        "password": user.password
    })

    return response