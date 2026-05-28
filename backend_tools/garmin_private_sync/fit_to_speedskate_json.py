import argparse
import json
import re
from pathlib import Path
from datetime import datetime
import fitdecode


BASE_DIR = Path(__file__).resolve().parent
ATHLETES_DIR = BASE_DIR / "athletes"

MAX_HR_DEFAULT = 190
RESTING_HR_DEFAULT = 52


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

    output_path = athlete_dir / "garmin_latest_training.json"

    daily_summary_path = athlete_dir / "daily_summary.json"

    flutter_output_dir = (
        BASE_DIR.parent.parent
        / "assets"
        / "data"
        / "garmin"
        / athlete_id
    )

    flutter_output_dir.mkdir(parents=True, exist_ok=True)

    flutter_output_path = (
        flutter_output_dir / "garmin_latest_training.json"
    )

    return {
        "athlete_id": athlete_id,
        "athlete_dir": athlete_dir,
        "activities_dir": activities_dir,
        "output_path": output_path,
        "daily_summary_path": daily_summary_path,
        "flutter_output_path": flutter_output_path,
    }


def safe_number(value, default=0.0):
    try:
        if value is None:
            return default

        return float(value)

    except Exception:
        return default


def parse_fit_records(path):
    records = []

    with fitdecode.FitReader(path) as fit:
        for frame in fit:
            if (
                frame.frame_type == fitdecode.FIT_FRAME_DATA
                and frame.name == "record"
            ):
                row = {}

                for field in frame.fields:
                    row[field.name] = field.value

                records.append(row)

    return records


def calculate_hr_zones(records, max_hr=MAX_HR_DEFAULT):
    zone1 = zone2 = zone3 = zone4 = zone5 = 0

    for row in records:
        hr = safe_number(row.get("heart_rate"), 0)

        if hr <= 0:
            continue

        percent = hr / max_hr

        if percent < 0.60:
            zone1 += 1
        elif percent < 0.70:
            zone2 += 1
        elif percent < 0.80:
            zone3 += 1
        elif percent < 0.90:
            zone4 += 1
        else:
            zone5 += 1

    return {
        "zone1Minutes": round(zone1 / 60, 1),
        "zone2Minutes": round(zone2 / 60, 1),
        "zone3Minutes": round(zone3 / 60, 1),
        "zone4Minutes": round(zone4 / 60, 1),
        "zone5Minutes": round(zone5 / 60, 1),
    }


def calculate_training_load(
    records,
    resting_hr=RESTING_HR_DEFAULT,
    max_hr=MAX_HR_DEFAULT,
):
    total = 0.0

    for row in records:
        hr = safe_number(row.get("heart_rate"), 0)

        if hr <= resting_hr:
            continue

        hr_reserve = max_hr - resting_hr

        intensity = (hr - resting_hr) / hr_reserve

        intensity = max(0.0, min(1.0, intensity))

        total += intensity

    return round(total, 1)


def summarize_fit(path):
    records = parse_fit_records(path)

    if not records:
        return None

    first = records[0]
    last = records[-1]

    start_time = first.get("timestamp")
    end_time = last.get("timestamp")

    duration_seconds = 0

    if isinstance(start_time, datetime) and isinstance(end_time, datetime):
        duration_seconds = max(
            0,
            (end_time - start_time).total_seconds(),
        )
    else:
        duration_seconds = len(records)

    distance_m = safe_number(last.get("distance"), 0)

    heart_rates = [
        safe_number(row.get("heart_rate"), 0)
        for row in records
        if safe_number(row.get("heart_rate"), 0) > 0
    ]

    speeds = [
        safe_number(row.get("enhanced_speed"), 0)
        for row in records
        if safe_number(row.get("enhanced_speed"), 0) > 0
    ]

    cadences = [
        safe_number(row.get("cadence"), 0)
        for row in records
        if safe_number(row.get("cadence"), 0) > 0
    ]

    avg_hr = (
        round(sum(heart_rates) / len(heart_rates), 1)
        if heart_rates
        else 0
    )

    max_hr = round(max(heart_rates), 1) if heart_rates else 0

    avg_speed_ms = (
        round(sum(speeds) / len(speeds), 2)
        if speeds
        else 0
    )

    max_speed_ms = round(max(speeds), 2) if speeds else 0

    avg_speed_kmh = round(avg_speed_ms * 3.6, 2)

    max_speed_kmh = round(max_speed_ms * 3.6, 2)

    avg_cadence = (
        round(sum(cadences) / len(cadences), 1)
        if cadences
        else 0
    )

    max_cadence = round(max(cadences), 1) if cadences else 0

    zones = calculate_hr_zones(records)

    internal_load = calculate_training_load(records)

    high_intensity_minutes = (
        zones["zone4Minutes"] + zones["zone5Minutes"]
    )

    total_minutes = round(duration_seconds / 60, 1)

    high_intensity_ratio = (
        round(high_intensity_minutes / total_minutes, 3)
        if total_minutes > 0
        else 0
    )

    sport_type = (
        "skating"
        if "position_lat" in first and distance_m > 0
        else "indoor"
    )

    return {
        "source": "garmin_fit_private_sync",
        "file": path.name,
        "sportType": sport_type,
        "startTime": str(start_time),
        "endTime": str(end_time),
        "durationSeconds": round(duration_seconds, 1),
        "durationMinutes": total_minutes,
        "distanceMeters": round(distance_m, 2),
        "distanceKm": round(distance_m / 1000, 2),
        "averageHeartRate": avg_hr,
        "maxHeartRate": max_hr,
        "averageSpeedMs": avg_speed_ms,
        "maxSpeedMs": max_speed_ms,
        "averageSpeedKmh": avg_speed_kmh,
        "maxSpeedKmh": max_speed_kmh,
        "averageCadence": avg_cadence,
        "maxCadence": max_cadence,
        "zone1Minutes": zones["zone1Minutes"],
        "zone2Minutes": zones["zone2Minutes"],
        "zone3Minutes": zones["zone3Minutes"],
        "zone4Minutes": zones["zone4Minutes"],
        "zone5Minutes": zones["zone5Minutes"],
        "highIntensityMinutes": round(
            high_intensity_minutes,
            1,
        ),
        "highIntensityRatio": high_intensity_ratio,
        "internalLoad": internal_load,
        "recordCount": len(records),
    }


def load_daily_summary(path):
    if not path.exists():
        return None

    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)

    except Exception as e:
        print(f"No se pudo cargar daily summary: {e}")

    return None


def export_json(path, data):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


def process_athlete(athlete_id: str):
    paths = get_athlete_paths(athlete_id)

    print("--------------------------------")
    print("Procesando atleta:")
    print(paths["athlete_id"])

    fit_files = sorted(
        paths["activities_dir"].glob("*.fit"),
        key=lambda p: p.stat().st_mtime,
        reverse=True,
    )

    if not fit_files:
        raise RuntimeError(
            f"No hay archivos .fit para {athlete_id}"
        )

    daily_summary = load_daily_summary(
        paths["daily_summary_path"]
    )

    summaries = []

    for fit_file in fit_files:
        try:
            summary = summarize_fit(fit_file)

            if summary:
                summaries.append(summary)

        except Exception as e:
            print(
                f"No se pudo procesar {fit_file.name}: {e}"
            )

    if not summaries:
        raise RuntimeError(
            "No se pudo generar ningún resumen válido."
        )

    latest = summaries[0]

    output = {
        "athleteId": athlete_id,
        "generatedAt": datetime.now().isoformat(),
        "latestTraining": latest,
        "recentTrainings": summaries[:10],
    }

    if daily_summary:
        output["dailySummary"] = daily_summary

    export_json(paths["output_path"], output)

    export_json(paths["flutter_output_path"], output)

    print("--------------------------------")
    print("JSON generado:")
    print(paths["output_path"])

    print("--------------------------------")
    print("JSON exportado a Flutter:")
    print(paths["flutter_output_path"])

    print("--------------------------------")
    print(
        f"Daily summary incluido: "
        f"{daily_summary is not None}"
    )

    print("--------------------------------")
    print(json.dumps(
        latest,
        indent=2,
        ensure_ascii=False,
    ))


def main():
    parser = argparse.ArgumentParser(
        description=(
            "Convierte actividades Garmin FIT "
            "a JSON multi-atleta."
        )
    )

    parser.add_argument(
        "athlete_id",
        help="ID del atleta",
    )

    args = parser.parse_args()

    process_athlete(args.athlete_id)


if __name__ == "__main__":
    main()