from fastapi import APIRouter
from app.core.supabase_client import supabase

router = APIRouter()

@router.get("/users")
def get_users():

    response = supabase.table(
        "users"
    ).select("*").execute()

    return response.data