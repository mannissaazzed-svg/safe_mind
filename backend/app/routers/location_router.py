from fastapi import APIRouter
from app.core.database import supabase

router = APIRouter(
    prefix="/locations",
    tags=["Locations"]
)

@router.get("/{user_id}")
def get_location(user_id: str):

    data = (
        supabase
        .table("patient_locations")
        .select("*")
        .eq("user_id", user_id)
        .execute()
    )

    return data.data