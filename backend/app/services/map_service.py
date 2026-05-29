"""Service cartographique — GPS, zones sécurisées, lieux favoris, alertes."""
from __future__ import annotations

import uuid
from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.map_models import Alert, Location, SafeZone, SavedPlace
from app.schemas.map_schema import AlertIn, LocationPushIn, SafeZoneIn, SavedPlaceIn


class MapService:

   

    @staticmethod
    async def push_location(
        db: AsyncSession, user_id: uuid.UUID, data: LocationPushIn
    ) -> Location:
        """
        Upsert de la position GPS.
        Mirror de Flutter _pushLocation → supabase.from('locations').upsert(...)
        """
        result = await db.execute(
            select(Location).where(Location.user_id == user_id)
        )
        loc = result.scalar_one_or_none()
        if loc:
            loc.latitude = data.latitude
            loc.longitude = data.longitude
            loc.speed = data.speed
        else:
            loc = Location(
                user_id=user_id,
                latitude=data.latitude,
                longitude=data.longitude,
                speed=data.speed,
            )
            db.add(loc)
        await db.flush()
        return loc

    @staticmethod
    async def get_location(
        db: AsyncSession, user_id: uuid.UUID
    ) -> Optional[Location]:
        result = await db.execute(
            select(Location).where(Location.user_id == user_id)
        )
        return result.scalar_one_or_none()

    
    @staticmethod
    async def upsert_safe_zone(
        db: AsyncSession, data: SafeZoneIn
    ) -> SafeZone:
        """
        Mirror de Flutter _updateSafeZone → supabase.from('safe_zones').upsert(...)
        """
        result = await db.execute(
            select(SafeZone).where(SafeZone.patient_id == data.patient_id)
        )
        zone = result.scalar_one_or_none()
        if zone:
            zone.center_lat = data.center_lat
            zone.center_lng = data.center_lng
            zone.radius_meters = data.radius_meters
            zone.label = data.label
        else:
            zone = SafeZone(
                patient_id=data.patient_id,
                center_lat=data.center_lat,
                center_lng=data.center_lng,
                radius_meters=data.radius_meters,
                label=data.label,
            )
            db.add(zone)
        await db.flush()
        return zone

    @staticmethod
    async def get_safe_zone(
        db: AsyncSession, patient_id: uuid.UUID
    ) -> Optional[SafeZone]:
        result = await db.execute(
            select(SafeZone).where(SafeZone.patient_id == patient_id)
        )
        return result.scalar_one_or_none()

    
    @staticmethod
    async def list_places(
        db: AsyncSession, user_id: uuid.UUID
    ) -> list[SavedPlace]:
        """Mirror de Flutter _loadSavedPlaces."""
        result = await db.execute(
            select(SavedPlace)
            .where(SavedPlace.user_id == user_id)
            .order_by(SavedPlace.label)
        )
        return list(result.scalars().all())

    @staticmethod
    async def add_place(
        db: AsyncSession, user_id: uuid.UUID, data: SavedPlaceIn
    ) -> SavedPlace:
        place = SavedPlace(
            user_id=user_id,
            label=data.label,
            latitude=data.latitude,
            longitude=data.longitude,
            icon=data.icon,
        )
        db.add(place)
        await db.flush()
        return place

    @staticmethod
    async def delete_place(
        db: AsyncSession, place_id: int, user_id: uuid.UUID
    ) -> bool:
        result = await db.execute(
            select(SavedPlace).where(
                SavedPlace.id == place_id, SavedPlace.user_id == user_id
            )
        )
        place = result.scalar_one_or_none()
        if not place:
            return False
        await db.delete(place)
        await db.flush()
        return True

    

    @staticmethod
    async def create_alert(db: AsyncSession, data: AlertIn) -> Alert:
        """
        SOS ou alerte de zone.
        Mirror de Flutter _sendSOS / _sendZoneAlert →
          supabase.from('alerts').insert({...})
        """
        alert = Alert(
            patient_id=data.patient_id,
            companion_id=data.companion_id,
            type=data.type,
            distance_meters=data.distance_meters,
        )
        db.add(alert)
        await db.flush()
        return alert

    @staticmethod
    async def list_alerts(
        db: AsyncSession, companion_id: uuid.UUID, limit: int = 10
    ) -> list[Alert]:
        """Mirror de Flutter _loadRecentAlerts."""
        result = await db.execute(
            select(Alert)
            .where(Alert.companion_id == companion_id)
            .order_by(Alert.created_at.desc())
            .limit(limit)
        )
        return list(result.scalars().all())

    @staticmethod
    async def get_latest_unread(
        db: AsyncSession, companion_id: uuid.UUID
    ) -> Optional[Alert]:
        """Dernière alerte non lue — pilote la bannière CompanionMapScreen."""
        result = await db.execute(
            select(Alert)
            .where(
                Alert.companion_id == companion_id,
                Alert.is_read == False,  # noqa: E712
            )
            .order_by(Alert.created_at.desc())
            .limit(1)
        )
        return result.scalar_one_or_none()

    @staticmethod
    async def mark_alert_read(
        db: AsyncSession, alert_id: int
    ) -> Optional[Alert]:
        """Mirror de Flutter _dismissAlert."""
        result = await db.execute(
            select(Alert).where(Alert.id == alert_id)
        )
        alert = result.scalar_one_or_none()
        if alert:
            alert.is_read = True
            db.add(alert)
            await db.flush()
        return alert
