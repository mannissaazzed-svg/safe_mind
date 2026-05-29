"""Service rendez-vous médecin."""
from __future__ import annotations

import uuid
from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.appointment import Appointment
from app.schemas.appointment_schema import AppointmentIn, AppointmentUpdateIn


class AppointmentService:

    @staticmethod
    async def list_for_caregiver(
        db: AsyncSession, caregiver_id: uuid.UUID
    ) -> list[Appointment]:
        result = await db.execute(
            select(Appointment)
            .where(Appointment.caregiver_id == caregiver_id)
            .order_by(Appointment.appointment_date)
        )
        return list(result.scalars().all())

    @staticmethod
    async def get_by_id(
        db: AsyncSession, appt_id: uuid.UUID
    ) -> Optional[Appointment]:
        result = await db.execute(
            select(Appointment).where(Appointment.id == appt_id)
        )
        return result.scalar_one_or_none()

    @staticmethod
    async def create(
        db: AsyncSession, caregiver_id: uuid.UUID, data: AppointmentIn
    ) -> Appointment:
        appt = Appointment(
            caregiver_id=caregiver_id,
            patient_id=data.patient_id,
            doctor_name=data.doctor_name,
            specialty=data.specialty,
            location=data.location,
            appointment_date=data.appointment_date,
            notes=data.notes,
        )
        db.add(appt)
        await db.flush()
        return appt

    @staticmethod
    async def update(
        db: AsyncSession, appt: Appointment, data: AppointmentUpdateIn
    ) -> Appointment:
        for field, value in data.model_dump(exclude_none=True).items():
            setattr(appt, field, value)
        db.add(appt)
        await db.flush()
        return appt

    @staticmethod
    async def delete(db: AsyncSession, appt: Appointment) -> None:
        await db.delete(appt)
        await db.flush()
