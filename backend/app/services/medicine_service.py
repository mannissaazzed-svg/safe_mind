"""Service médicaments — catalogue, médicaments patient."""
from __future__ import annotations

import uuid
from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.medicine import Medicine, PatientMedicine
from app.schemas.medicine_schema import PatientMedicineIn


class MedicineService:

    

    @staticmethod
    async def list_catalogue(
        db: AsyncSession, disease_type: str
    ) -> list[Medicine]:
        result = await db.execute(
            select(Medicine)
            .where(Medicine.disease_type == disease_type)
            .order_by(Medicine.name)
        )
        return list(result.scalars().all())

    @staticmethod
    async def find_by_barcode(
        db: AsyncSession, barcode: str
    ) -> Optional[Medicine]:
        result = await db.execute(
            select(Medicine).where(Medicine.barcode == barcode)
        )
        return result.scalar_one_or_none()

    
    @staticmethod
    async def add(
        db: AsyncSession, caregiver_id: uuid.UUID, data: PatientMedicineIn
    ) -> PatientMedicine:
        pm = PatientMedicine(
            caregiver_id=caregiver_id,
            patient_id=data.patient_id,
            name=data.name,
            dose=data.dose,
            frequency=data.frequency,
            image_url=data.image_url,
            disease_type=data.disease_type,
        )
        db.add(pm)
        await db.flush()
        return pm

    @staticmethod
    async def list_by_caregiver(
        db: AsyncSession, caregiver_id: uuid.UUID
    ) -> list[PatientMedicine]:
        result = await db.execute(
            select(PatientMedicine)
            .where(PatientMedicine.caregiver_id == caregiver_id)
            .order_by(PatientMedicine.created_at.desc())
        )
        return list(result.scalars().all())

    @staticmethod
    async def list_by_patient(
        db: AsyncSession, patient_id: uuid.UUID
    ) -> list[PatientMedicine]:
        """Utilisé par l'écran MedicinesPage du patient."""
        result = await db.execute(
            select(PatientMedicine)
            .where(PatientMedicine.patient_id == patient_id)
            .order_by(PatientMedicine.created_at.desc())
        )
        return list(result.scalars().all())

    @staticmethod
    async def delete(
        db: AsyncSession, pm_id: uuid.UUID, caregiver_id: uuid.UUID
    ) -> bool:
        result = await db.execute(
            select(PatientMedicine).where(
                PatientMedicine.id == pm_id,
                PatientMedicine.caregiver_id == caregiver_id,
            )
        )
        pm = result.scalar_one_or_none()
        if not pm:
            return False
        await db.delete(pm)
        await db.flush()
        return True
