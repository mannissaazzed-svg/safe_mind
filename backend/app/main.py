from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.database import Base, engine
from app.routers import (
    appointments,
    auth,
    caregiver,
    doctor,
    locations,
    map_router,
    medicines,
    notifications,
    patient,
    tasks,
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Créer toutes les tables au démarrage."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield


app = FastAPI(
    title="SafeMind API",
    description=(
        "Backend pour l'application SafeMind — "
        "suivi des patients Alzheimer & Parkinson"
    ),
    version="2.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


app.include_router(auth.router,          prefix="/api/auth",         tags=["Auth"])


app.include_router(caregiver.router,     prefix="/api/caregiver",    tags=["Caregiver"])


app.include_router(patient.router,       prefix="/api/patient",      tags=["Patient"])


app.include_router(doctor.router,        prefix="/api/doctor",       tags=["Médecin"])


app.include_router(tasks.router,         prefix="/api/tasks",        tags=["Tasks"])
app.include_router(medicines.router,     prefix="/api/medicines",    tags=["Medicines"])
app.include_router(appointments.router,  prefix="/api/appointments", tags=["Appointments"])
app.include_router(notifications.router, prefix="/api/notifications",tags=["Notifications"])


app.include_router(locations.router,     prefix="/api/locations",    tags=["Locations"])
app.include_router(map_router.router,    prefix="/api/map",          tags=["Map & GPS"])


@app.get("/", tags=["Health"])
async def root():
    return {"status": "ok", "message": "SafeMind API v2 is running ✓"}
