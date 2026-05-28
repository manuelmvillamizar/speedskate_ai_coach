from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from services.garmin_service import GarminService

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


@app.get("/garmin/sync")
def sync_garmin():
    return garmin_service.sync()


@app.get("/garmin/normalized")
def get_normalized_garmin():
    return garmin_service.get_normalized()