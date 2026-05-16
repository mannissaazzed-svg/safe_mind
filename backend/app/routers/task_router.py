from fastapi import APIRouter
from app.core.database import supabase

router = APIRouter(
    prefix="/tasks",
    tags=["Tasks"]
)

@router.get("/{patient_id}")
def get_tasks(patient_id: str):

    data = (
        supabase
        .table("tasks")
        .select("*")
        .eq("patient_id", patient_id)
        .execute()
    )

    return data.data