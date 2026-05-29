"""
Medicines Router (standalone) — catalogue + médicaments patient.

GET  /api/medicines/catalogue/{disease_type}  — catalogue par maladie
GET  /api/medicines/barcode/{barcode}          — recherche par code-barre
GET  /api/medicines/patient                    — mes prescriptions (caregiver)
POST /api/medicines/patient                    — ajouter une prescription
DELETE /api/medicines/patient/{id}             — supprimer une prescription
GET  /api/medicines/my                         — médicaments du patient connecté
"""
import uuid

from fastapi import APIRouter, HTTPException, status

from app.core.dependencies import CaregiverOnly, DbDep, PatientOnly
from app.schemas.medicine_schema import MedicineOut, PatientMedicineIn, PatientMedicineOut
from app.services.medicine_service import MedicineService

router = APIRouter()




@router.get("/catalogue/{disease_type}", response_model=list[MedicineOut])
async def list_catalogue(db: DbDep, disease_type: str, _: CaregiverOnly):
    """Catalogue de médicaments pour un type de maladie."""
    return await MedicineService.list_catalogue(db, disease_type)


@router.get("/barcode/{barcode}", response_model=MedicineOut)
async def find_by_barcode(db: DbDep, barcode: str, _: CaregiverOnly):
    """Recherche par code-barre (scanner MedicineForm)."""
    med = await MedicineService.find_by_barcode(db, barcode)
    if not med:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Code-barre non trouvé",
        )
    return med




@router.get("/patient", response_model=list[PatientMedicineOut])
async def list_by_caregiver(db: DbDep, current_user: CaregiverOnly):
    """Toutes les prescriptions créées par ce caregiver."""
    return await MedicineService.list_by_caregiver(db, current_user.id)


@router.post("/patient", response_model=PatientMedicineOut, status_code=status.HTTP_201_CREATED)
async def add_medicine(db: DbDep, body: PatientMedicineIn, current_user: CaregiverOnly):
    """Ajouter un médicament pour le patient lié."""
    if body.patient_id is None and current_user.linked_to:
        body = body.model_copy(update={"patient_id": current_user.linked_to})
    return await MedicineService.add(db, current_user.id, body)


@router.delete("/patient/{pm_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_medicine(db: DbDep, pm_id: uuid.UUID, current_user: CaregiverOnly):
    """Supprimer une prescription."""
    deleted = await MedicineService.delete(db, pm_id, current_user.id)
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Médicament introuvable")




@router.get("/my", response_model=list[PatientMedicineOut])
async def my_medicines(db: DbDep, current_user: PatientOnly):
    """Médicaments prescrits au patient connecté (MedicinesPage)."""
    return await MedicineService.list_by_patient(db, current_user.id)