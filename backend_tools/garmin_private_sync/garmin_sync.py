import argparse
import json
import os
import re
import zipfile
from pathlib import Path
from datetime import date
from dotenv import load_dotenv
from garminconnect import Garmin
import fitdecode


BASE_DIR = Path(__file__).resolve().parent
ATHLETES_DIR = BASE_DIR / "athletes"


def normalize_athlete_id(value: str) -> str:
    value = (value or "").strip()

    if not value:
        raise ValueError("athlete_id no puede estar vacío.")

    if not re.match(r"^[a-zA-Z0-9_-]+$", value):
        raise ValueError(
            "athlete_id inválido. Usa solo letras, números, guion o guion bajo."
        )

    return value


def get_athlete_paths(athlete_id: str) -> dict:
    athlete_id = normalize_athlete_id(athlete_id)

    athlete_dir = ATHLETES_DIR / athlete_id
    activities_dir = athlete_dir / "activities"
    daily_summary_path = athlete_dir / "daily_summary.json"
    latest_training_path = athlete_dir / "garmin_latest_training.json"
    env_path = athlete_dir / ".env"

    athlete_dir.mkdir(parents=True, exist_ok=True)
    activities_dir.mkdir(parents=True, exist_ok=True)

    return {
        "athlete_id": athlete_id,
        "athlete_dir": athlete_dir,
        "activities_dir": activities_dir,
        "daily_summary_path": daily_summary_path,
        "latest_training_path": latest_training_path,
        "env_path": env_path,
    }


def load_athlete_credentials(env_path: Path) -> tuple[str, str]:
    if not env_path.exists():
        raise RuntimeError(
            f"No existe el archivo .env para este atleta:\n{env_path}\n\n"
            "Crea el archivo con:\n"
            "GARMIN_EMAIL=correo_del_atleta\n"
            "GARMIN_PASSWORD=password_del_atleta"
        )

    load_dotenv(env_path, override=True)

    email = os.getenv("GARMIN_EMAIL")
    password = os.getenv("GARMIN_PASSWORD")

    if not email or not password:
        raise RuntimeError(
            f"Faltan GARMIN_EMAIL o GARMIN_PASSWORD en:\n{env_path}"
        )

    return email, password


def is_fit_file(path: Path) -> bool:
    try:
        data = path.read_bytes()[:32]
        return b".FIT" in data
    except Exception:
        return False


def extract_fit_if_zip(path: Path) -> Path | None:
    try:
        if not zipfile.is_zipfile(path):
            return None

        with zipfile.ZipFile(path, "r") as z:
            for name in z.namelist():
                if name.lower().endswith(".fit"):
                    output_path = path.with_suffix(".fit")
                    with z.open(name) as source, open(output_path, "wb") as target:
                        target.write(source.read())
                    return output_path

    except Exception as e:
        print("No se pudo extraer ZIP:", e)

    return None


def parse_fit(path: Path) -> list[dict]:
    records = []

    with fitdecode.FitReader(path) as fit:
        for frame in fit:
            if frame.frame_type == fitdecode.FIT_FRAME_DATA and frame.name == "record":
                row = {}
                for field in frame.fields:
                    row[field.name] = field.value
                records.append(row)

    return records


def download_activity_file(client: Garmin, activity_id: str, activities_dir: Path) -> Path:
    output_path = activities_dir / f"{activity_id}.bin"

    if output_path.exists():
        return output_path

    raw_file = client.download_activity(
        activity_id,
        dl_fmt=client.ActivityDownloadFormat.ORIGINAL,
    )

    with open(output_path, "wb") as f:
        f.write(raw_file)

    return output_path


def safe_get_number(data, keys, default=None):
    if not isinstance(data, dict):
        return default

    for key in keys:
        value = data.get(key)
        if isinstance(value, (int, float)):
            return value

    return default


def get_daily_summary(client: Garmin, target_date: date) -> dict:
    date_str = target_date.strftime("%Y-%m-%d")

    summary = {
        "date": date_str,
    }

    try:
        user_summary = client.get_user_summary(date_str)
    except Exception as e:
        print("No se pudo obtener user_summary:", e)
        user_summary = None

    try:
        sleep_data = client.get_sleep_data(date_str)
    except Exception as e:
        print("No se pudo obtener sleep_data:", e)
        sleep_data = None

    try:
        hrv_data = client.get_hrv_data(date_str)
    except Exception as e:
        print("No se pudo obtener hrv_data:", e)
        hrv_data = None

    try:
        stress_data = client.get_stress_data(date_str)
    except Exception as e:
        print("No se pudo obtener stress_data:", e)
        stress_data = None

    try:
        body_battery = client.get_body_battery(date_str)
    except Exception as e:
        print("No se pudo obtener body_battery:", e)
        body_battery = None

    sleep_seconds = safe_get_number(
        sleep_data,
        ["totalSleepSeconds", "sleepTimeSeconds", "totalSleepDuration"],
    )

    if sleep_seconds is not None and sleep_seconds > 0:
        summary["sleepMinutes"] = round(sleep_seconds / 60)

    resting_hr = safe_get_number(
        user_summary,
        ["restingHeartRate", "minRestingHeartRate"],
    )

    if resting_hr is not None and resting_hr > 0:
        summary["restingHeartRate"] = round(resting_hr)

    stress = safe_get_number(
        stress_data,
        ["averageStressLevel", "avgStressLevel", "stressLevel"],
    )

    if stress is not None and stress >= 0:
        summary["stress"] = round(stress)

    hrv = safe_get_number(
        hrv_data,
        ["weeklyAverage", "lastNightAvg", "hrvValue", "average"],
    )

    if hrv is not None and hrv > 0:
        summary["hrv"] = round(hrv)

    body_battery_value = None

    if isinstance(body_battery, dict):
        body_battery_value = safe_get_number(
            body_battery,
            ["mostRecentValue", "charged", "bodyBattery"],
        )

    if isinstance(body_battery, list) and body_battery:
        last_item = body_battery[-1]
        if isinstance(last_item, dict):
            body_battery_value = safe_get_number(
                last_item,
                ["bodyBattery", "value", "mostRecentValue"],
            )

    if body_battery_value is not None and body_battery_value >= 0:
        summary["bodyBattery"] = round(body_battery_value)

    return summary


def save_daily_summary(client: Garmin, daily_summary_path: Path) -> dict:
    today = date.today()
    summary = get_daily_summary(client, today)

    with open(daily_summary_path, "w", encoding="utf-8") as f:
        json.dump(summary, f, indent=2, ensure_ascii=False)

    print("--------------------------------")
    print("Daily summary generado:")
    print(daily_summary_path)
    print(json.dumps(summary, indent=2, ensure_ascii=False))

    return summary


def convert_value(value):
    if hasattr(value, "isoformat"):
        return value.isoformat()

    return value


def summarize_activity(activity: dict, fit_path: Path | None, records_count: int) -> dict:
    return {
        "activityId": activity.get("activityId"),
        "activityName": activity.get("activityName"),
        "startTimeLocal": activity.get("startTimeLocal"),
        "distance": activity.get("distance"),
        "duration": activity.get("duration"),
        "activityType": activity.get("activityType"),
        "fitFile": str(fit_path) if fit_path else None,
        "recordsCount": records_count,
    }


def save_latest_training(
    athlete_id: str,
    latest_training_path: Path,
    daily_summary: dict,
    activities: list[dict],
) -> None:
    payload = {
        "athleteId": athlete_id,
        "source": "garmin_private_sync",
        "generatedAt": date.today().isoformat(),
        "dailySummary": daily_summary,
        "activities": activities,
    }

    with open(latest_training_path, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2, ensure_ascii=False, default=convert_value)

    print("--------------------------------")
    print("Archivo Garmin latest generado:")
    print(latest_training_path)


def sync_athlete(athlete_id: str, max_activities: int) -> None:
    paths = get_athlete_paths(athlete_id)

    print("--------------------------------")
    print("Sincronizando atleta:")
    print(paths["athlete_id"])
    print("Carpeta del atleta:")
    print(paths["athlete_dir"])

    email, password = load_athlete_credentials(paths["env_path"])

    client = Garmin(email, password)
    client.login()

    daily_summary = save_daily_summary(
        client=client,
        daily_summary_path=paths["daily_summary_path"],
    )

    activities = client.get_activities(0, max_activities)

    print("--------------------------------")
    print(f"Actividades encontradas: {len(activities)}")

    processed_activities = []

    for activity in activities:
        activity_id = str(activity["activityId"])

        print("--------------------------------")
        print("ID:", activity_id)
        print("Nombre:", activity.get("activityName"))
        print("Fecha:", activity.get("startTimeLocal"))
        print("Distancia:", activity.get("distance"))
        print("Duración:", activity.get("duration"))

        downloaded_path = download_activity_file(
            client=client,
            activity_id=activity_id,
            activities_dir=paths["activities_dir"],
        )

        fit_path = None

        if is_fit_file(downloaded_path):
            fit_path = downloaded_path.with_suffix(".fit")
            if not fit_path.exists():
                downloaded_path.rename(fit_path)
        else:
            fit_path = extract_fit_if_zip(downloaded_path)

        if fit_path is None or not fit_path.exists():
            print("Archivo descargado, pero no contiene FIT válido:", downloaded_path)
            try:
                print("Primeros bytes:", downloaded_path.read_bytes()[:40])
            except Exception:
                pass

            processed_activities.append(
                summarize_activity(
                    activity=activity,
                    fit_path=None,
                    records_count=0,
                )
            )
            continue

        print("FIT listo:", fit_path)

        records = parse_fit(fit_path)

        print("Registros FIT:", len(records))

        if records:
            print("Campos disponibles:", list(records[0].keys())[:25])

        processed_activities.append(
            summarize_activity(
                activity=activity,
                fit_path=fit_path,
                records_count=len(records),
            )
        )

    save_latest_training(
        athlete_id=paths["athlete_id"],
        latest_training_path=paths["latest_training_path"],
        daily_summary=daily_summary,
        activities=processed_activities,
    )


def main():
    parser = argparse.ArgumentParser(
        description="Sincroniza datos Garmin privados por atleta."
    )

    parser.add_argument(
        "athlete_id",
        help="ID del atleta. Ejemplo: athlete_001, juan_perez, patinadora_a",
    )

    parser.add_argument(
        "--max-activities",
        type=int,
        default=10,
        help="Cantidad máxima de actividades Garmin a descargar.",
    )

    args = parser.parse_args()

    sync_athlete(
        athlete_id=args.athlete_id,
        max_activities=args.max_activities,
    )


if __name__ == "__main__":
    main()