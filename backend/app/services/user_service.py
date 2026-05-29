"""Service utilisateur — profil, liaison caregiver↔patient, formulaire médical."""
from __future__ import annotations

import uuid
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.schemas.user_schema import (
    CaregiverProfileIn,
    PatientFormIn,
    PatientProfileIn,
)


class UserService:

    

    @staticmethod
    async def update_caregiver_profile(
        db: AsyncSession, user: User, data: CaregiverProfileIn
    ) -> User:
        for field, value in data.model_dump(exclude_none=True).items():
            setattr(user, field, value)
        db.add(user)
        await db.flush()
        return user

    

    @staticmethod
    async def fill_patient_form(
        db: AsyncSession, caregiver: User, data: PatientFormIn
    ) -> User:
        print("DATA RECEIVED:", data.model_dump())
        """
        Le caregiver remplit le profil médical de son patient.
        Met à jour patient_filled=True et synchronise la maladie sur le patient lié.
        """
        caregiver.disease = data.disease
        caregiver.patient_filled = True
        caregiver.patient_age = data.patient_age
        caregiver.patient_phone = data.patient_phone
        caregiver.patient_genre = data.patient_genre
        caregiver.symptoms = data.symptoms

        # Synchroniser la maladie sur le patient lié
        if caregiver.linked_to:
            result = await db.execute(
                select(User).where(User.id == caregiver.linked_to)
            )
            patient = result.scalar_one_or_none()
            if patient:
                patient.disease = data.disease
                db.add(patient)

        db.add(caregiver)
        await db.flush()
        return caregiver
    

    

    @staticmethod
    async def link_by_code(db: AsyncSession, initiator: User, code: str) -> User:
        code = code.upper()
        result = await db.execute(
            select(User).where(User.short_code == code)
        )
        target = result.scalar_one_or_none()
        if not target or target.id == initiator.id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Aucun utilisateur trouvé avec ce code",
            )

    
        
        if initiator.role == "caregiver" and target.role == "patient":
            initiator.linked_to = target.id

        if initiator.disease:
            target.disease = initiator.disease
            db.add(target)

    # patient → caregiver
     
        elif initiator.role == "patient" and target.role == "caregiver":
            target.linked_to = initiator.id

            if target.disease:
                initiator.disease = target.disease

            db.add(target)
            
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Liaison impossible entre ces deux rôles",
                )

     
        db.add(initiator)
        await db.flush()
        return initiator

    

    @staticmethod
    async def update_patient_profile(
        db: AsyncSession, user: User, data: PatientProfileIn
    ) -> User:
        for field, value in data.model_dump(exclude_none=True).items():
            setattr(user, field, value)
        db.add(user)
        await db.flush()
        return user

    @staticmethod
    async def update_avatar(db: AsyncSession, user: User, url: str) -> User:
        user.avatar_url = url
        db.add(user)
        await db.flush()
        return user

    
    @staticmethod
    async def get_patient_home_data(db: AsyncSession, patient: User) -> dict:
        """
        Retourne les données nécessaires à l'écran Home Flutter.
        Si la maladie n'est pas définie, on la récupère depuis le caregiver lié
        et on la synchronise (mirror de Flutter Home._fetchUserData).
        """
        disease = patient.disease
        caregiver_name: Optional[str] = None
        caregiver_avatar: Optional[str] = None

        if not disease:
            
            result = await db.execute(
                select(User).where(
                    User.linked_to == patient.id, User.role == "caregiver"
                )
            )
            caregiver = result.scalar_one_or_none()
            if caregiver and caregiver.disease:
                patient.disease = caregiver.disease
                disease = caregiver.disease
                db.add(patient)
                await db.flush()

        if patient.linked_to:
            result = await db.execute(
                select(User).where(User.id == patient.linked_to)
            )
            linked = result.scalar_one_or_none()
            if linked:
                caregiver_name = linked.full_name
                caregiver_avatar = linked.avatar_url

        return {
            "user_id": patient.id,
            "full_name": patient.full_name,
            "avatar_url": patient.avatar_url,
            "disease": disease,
            "linked_to": patient.linked_to,
            "caregiver_name": caregiver_name,
            "caregiver_avatar": caregiver_avatar,
        }

    

    @staticmethod
    async def update_doctor_profile(db: AsyncSession, user: User, data: dict) -> User:
        for field, value in data.items():
            if value is not None and hasattr(user, field):
                setattr(user, field, value)
        db.add(user)
        await db.flush()
        return user

    

    @staticmethod
    async def get_linked_patient(
        db: AsyncSession, caregiver: User
    ) -> Optional[User]:
        if not caregiver.linked_to:
            return None
        result = await db.execute(
            select(User).where(User.id == caregiver.linked_to)
        )
        return result.scalar_one_or_none()






