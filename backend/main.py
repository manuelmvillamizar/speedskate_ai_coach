from pathlib import Path

from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# ✅ Import correcto para Render
from backend.services.garmin_service import GarminService
app = FastAPI(
    title="SpeedSkate AI Coach Backend",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

garmin_service = GarminService()


class GarminConnectRequest(BaseModel):
    athleteId: str
    email: str
    password: str


@app.get("/")
def root():
    return {
        "status": "ok",
        "message": "SpeedSkate AI Coach backend running",
    }


@app.get("/health")
def health_check():
    return {
        "status": "healthy",
    }


@app.post("/garmin/connect")
def connect_garmin(payload: GarminConnectRequest):
    athlete_id = payload.athleteId.strip()
    email = payload.email.strip()
    password = payload.password.strip()

    # Ruta base para los datos del atleta
    athlete_dir = (
        Path("backend_tools")
        / "garmin_private_sync"
        / "athletes"
        / athlete_id
    )

    activities_dir = athlete_dir / "activities"
    env_path = athlete_dir / ".env"

    # Crear directorios si no existen
    athlete_dir.mkdir(parents=True, exist_ok=True)
    activities_dir.mkdir(parents=True, exist_ok=True)

    # Guardar credenciales en .env del atleta
    with open(env_path, "w", encoding="utf-8") as f:
        f.write(f"GARMIN_EMAIL={email}\n")
        f.write(f"GARMIN_PASSWORD={password}\n")

    return {
        "ok": True,
        "athleteId": athlete_id,
        "message": "Credenciales Garmin guardadas correctamente",
    }


@app.get("/garmin/sync")
def sync_garmin(
    athleteId: str = Query(...),
):
    return garmin_service.sync(
        athlete_id=athleteId,
    )


@app.get("/garmin/normalized")
def get_normalized_garmin(
    athleteId: str = Query(...),
):
    return garmin_service.get_normalized(
        athlete_id=athleteId,
    )