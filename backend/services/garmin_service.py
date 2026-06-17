import os
from pathlib import Path
from datetime import date, datetime

from dotenv import load_dotenv
from garminconnect import Garmin

BASE_DIR = Path(__file__).resolve().parent.parent.parent
ATHLETES_DIR = BASE_DIR / "backend_tools" / "garmin_private_sync" / "athletes"


class GarminService:
    def __init__(self):
        self.clients = {}

    def _env_path(self, athlete_id: str):
        return ATHLETES_DIR / athlete_id / ".env"

    def _load_credentials(self, athlete_id: str):
        env_path = self._env_path(athlete_id)

        if not env_path.exists():
            raise RuntimeError(f"No existe .env para atleta: {athlete_id}")

        load_dotenv(env_path, override=True)

        email = os.getenv("GARMIN_EMAIL")
        password = os.getenv("GARMIN_PASSWORD")

        if not email or not password:
            raise RuntimeError(f"Faltan credenciales Garmin para: {athlete_id}")

        return email, password

    def login(self, athlete_id: str):
        if athlete_id not in self.clients:
            email, password = self._load_credentials(athlete_id)

            print(f"🔐 Login Garmin para atleta: {athlete_id}")
            self.clients[athlete_id] = Garmin(email, password)
            self.clients[athlete_id].login()
            print(f"✅ Login exitoso para atleta: {athlete_id}")

        return self.clients[athlete_id]

    def sync(self, athlete_id: str, target_date: str | None = None):
        client = self.login(athlete_id)

        today = target_date or date.today().strftime("%Y-%m-%d")

        athlete_dir = ATHLETES_DIR / athlete_id
        activities_dir = athlete_dir / "activities"
        activities_dir.mkdir(parents=True, exist_ok=True)

        print(f"\n📡 Sincronizando Garmin para atleta: {athlete_id}")
        print(f"   Fecha: {today}")

        try:
            activities_raw = client.get_activities(0, 30)
            activities = []

            for activity in activities_raw:
                print(
                    "🔎 ACTIVITY:",
                    activity.get("activityName"),
                    activity.get("activityType", {}),
                    activity.get("startTimeLocal"),
                    activity.get("duration"),
                    activity.get("distance"),
                )

                start = (
                    activity.get("startTimeLocal")
                    or activity.get("startTimeGMT")
                    or activity.get("startTime")
                    or ""
                )

                if str(start).startswith(today):
                    activities.append(activity)

            print(f"   ✅ Actividades obtenidas para {today}: {len(activities)}")

        except Exception as e:
            print(f"   ❌ ERROR activities: {e}")
            activities = []

        try:
            stats = client.get_stats(today)
            print(
                f"   ✅ Stats obtenidos: "
                f"{list(stats.keys()) if isinstance(stats, dict) else 'OK'}"
            )
        except Exception as e:
            print(f"   ❌ ERROR stats: {e}")
            stats = {}

        try:
            sleep_data = client.get_sleep_data(today)
            print(f"   ✅ Sleep data: {sleep_data is not None}")
        except Exception as e:
            print(f"   ❌ ERROR sleep_data: {e}")
            sleep_data = {}

        try:
            hrv_data = client.get_hrv_data(today)
            print(f"   ✅ HRV data: {hrv_data is not None}")
        except Exception as e:
            print(f"   ❌ ERROR hrv_data: {e}")
            hrv_data = {}

        try:
            stress_data = client.get_stress_data(today)
            print(f"   ✅ Stress data: {stress_data is not None}")
        except Exception as e:
            print(f"   ❌ ERROR stress_data: {e}")
            stress_data = {}

        try:
            body_battery_data = client.get_body_battery(today, today)
            print(f"   ✅ Body battery data: {body_battery_data is not None}")
        except Exception as e:
            print(f"   ❌ ERROR body_battery_data: {e}")
            body_battery_data = {}

        return {
            "status": "connected",
            "source": "garmin",
            "date": today,
            "activities": activities,
            "stats": stats,
            "sleep_data": sleep_data,
            "hrv_data": hrv_data,
            "stress_data": stress_data,
            "body_battery_data": body_battery_data,
        }

    def get_normalized(self, athlete_id: str, target_date: str | None = None):
        raw = self.sync(athlete_id, target_date)

        activities = raw.get("activities", [])
        stats = raw.get("stats", {})
        sleep_data = raw.get("sleep_data", {})
        hrv_data = raw.get("hrv_data", {})
        stress_data = raw.get("stress_data", {})
        body_battery_data = raw.get("body_battery_data", {})

        days = {}

        for activity in activities:
            start_time = (
                activity.get("startTimeLocal")
                or activity.get("startTimeGMT")
                or activity.get("startTime")
                or raw.get("date")
            )

            activity_date = str(start_time)[:10]

            if activity_date not in days:
                days[activity_date] = {
                    "date": activity_date,
                    "sessions": [],
                    "summary": {
                        "total_sessions": 0,
                        "total_duration_min": 0,
                        "total_distance_km": 0,
                        "total_internal_load": 0,
                    },
                }

            duration_sec = activity.get("duration") or 0
            distance_m = activity.get("distance") or 0
            avg_hr = activity.get("averageHR")
            max_hr = activity.get("maxHR")
            aerobic_te = activity.get("aerobicTrainingEffect")
            anaerobic_te = activity.get("anaerobicTrainingEffect")
            label = activity.get("trainingEffectLabel")

            duration_min = round(duration_sec / 60, 1)
            distance_km = round(distance_m / 1000, 2)

            session = {
                "activity_id": activity.get("activityId"),
                "name": activity.get("activityName"),
                "session_type": self._detect_session_type(activity),
                "start_time": start_time,
                "duration_sec": duration_sec,
                "duration_min": duration_min,
                "distance_m": distance_m,
                "distance_km": distance_km,
                "avg_hr": avg_hr,
                "max_hr": max_hr,
                "hrTimeInZone_1": activity.get("hrTimeInZone_1"),
                "hrTimeInZone_2": activity.get("hrTimeInZone_2"),
                "hrTimeInZone_3": activity.get("hrTimeInZone_3"),
                "hrTimeInZone_4": activity.get("hrTimeInZone_4"),
                "hrTimeInZone_5": activity.get("hrTimeInZone_5"),
                "avg_speed_mps": activity.get("averageSpeed"),
                "max_speed_mps": activity.get("maxSpeed"),
                "calories": activity.get("calories"),
                "aerobic_training_effect": aerobic_te,
                "anaerobic_training_effect": anaerobic_te,
                "training_effect_label": label,
                "body_battery_delta": activity.get("differenceBodyBattery"),
                "internal_load": self._calculate_internal_load(
                    duration_sec,
                    avg_hr,
                    aerobic_te,
                    anaerobic_te,
                ),
            }

            days[activity_date]["sessions"].append(session)
            days[activity_date]["summary"]["total_sessions"] += 1
            days[activity_date]["summary"]["total_duration_min"] += duration_min
            days[activity_date]["summary"]["total_distance_km"] += distance_km
            days[activity_date]["summary"]["total_internal_load"] += session[
                "internal_load"
            ]

        sleep_minutes = self._extract_sleep_minutes(sleep_data)
        hrv = self._extract_hrv(hrv_data)

        resting_hr = self._first_number(
            stats,
            ["restingHeartRate", "minRestingHeartRate", "resting_hr"],
        )

        stress = self._first_number(
            stress_data,
            ["averageStressLevel", "avgStressLevel", "stressLevel"],
        )

        if stress is None:
            stress = self._first_number(
                stats,
                ["averageStressLevel", "avgStressLevel", "stressLevel"],
            )

        body_battery = self._extract_body_battery(body_battery_data)

        if body_battery is None:
            body_battery = self._first_number(
                stats,
                [
                    "bodyBatteryMostRecentValue",
                    "bodyBattery",
                    "body_battery_current",
                ],
            )

        steps = self._first_number(stats, ["totalSteps", "steps"])

        if steps is None:
            steps = self._extract_steps_from_activities(activities)

        if resting_hr is None:
            resting_hr = self._extract_resting_hr_from_activities(activities)

        main_date = raw.get("date")

        if main_date not in days:
            days[main_date] = {
                "date": main_date,
                "sessions": [],
                "summary": {
                    "total_sessions": 0,
                    "total_duration_min": 0,
                    "total_distance_km": 0,
                    "total_internal_load": 0,
                },
            }

        for day in days.values():
            day["summary"]["total_duration_min"] = round(
                day["summary"]["total_duration_min"], 1
            )
            day["summary"]["total_distance_km"] = round(
                day["summary"]["total_distance_km"], 2
            )
            day["summary"]["total_internal_load"] = round(
                day["summary"]["total_internal_load"], 1
            )

        today_summary = days[main_date]["summary"]

        summary = {
            "total_sessions": today_summary["total_sessions"],
            "total_duration_min": today_summary["total_duration_min"],
            "total_distance_km": today_summary["total_distance_km"],
            "total_internal_load": today_summary["total_internal_load"],
            "sleepMinutes": sleep_minutes or 0,
            "hrv": hrv or 0,
            "restingHeartRate": round(resting_hr) if resting_hr is not None else 0,
            "stress": round(stress) if stress is not None else 0,
            "bodyBattery": round(body_battery) if body_battery is not None else 0,
            "steps": round(steps) if steps is not None else 0,
            "body_battery_current": round(body_battery)
            if body_battery is not None
            else 0,
            "resting_hr": round(resting_hr) if resting_hr is not None else 0,
            "avg_stress": round(stress) if stress is not None else 0,
        }

        return {
            "status": "normalized",
            "source": "garmin",
            "date": raw.get("date"),
            "summary": summary,
            "sessions": days[main_date]["sessions"],
            "days": list(days.values()),
            "debug_sources": {
                "has_stats": bool(stats),
                "has_sleep_data": bool(sleep_data),
                "has_hrv_data": bool(hrv_data),
                "has_stress_data": bool(stress_data),
                "has_body_battery_data": bool(body_battery_data),
            },
        }

    def _detect_session_type(self, activity):
        name = (activity.get("activityName") or "").lower()
        activity_type = activity.get("activityType", {}).get("typeKey", "")
        label = activity.get("trainingEffectLabel")

        if "patinaje" in name or "skate" in name:
            return "speed_skating"

        if activity_type == "indoor_cycling":
            return "bike_secondary"

        if label == "RECOVERY":
            return "recovery"

        if label == "SPEED":
            return "speed"

        return activity_type or "unknown"

    def _calculate_internal_load(self, duration_sec, avg_hr, aerobic_te, anaerobic_te):
        duration_min = duration_sec / 60 if duration_sec else 0
        hr_factor = (avg_hr or 100) / 100
        load = duration_min * hr_factor
        load += (aerobic_te or 0) * 10
        load += (anaerobic_te or 0) * 15
        return round(load, 1)

    def _first_number(self, data, keys):
        if not isinstance(data, dict):
            return None

        for key in keys:
            value = data.get(key)

            if isinstance(value, (int, float)):
                return value

            if isinstance(value, str):
                try:
                    return float(value)
                except ValueError:
                    pass

        return None

    def _extract_sleep_minutes(self, sleep_data):
        if not isinstance(sleep_data, dict):
            return 0

        seconds = self._first_number(
            sleep_data,
            [
                "totalSleepSeconds",
                "sleepTimeSeconds",
                "totalSleepDuration",
                "durationInSeconds",
            ],
        )

        if seconds is not None and seconds > 0:
            return round(seconds / 60)

        minutes = self._first_number(
            sleep_data,
            [
                "sleepMinutes",
                "totalSleepMinutes",
            ],
        )

        if minutes is not None and minutes > 0:
            return round(minutes)

        hours = self._first_number(
            sleep_data,
            [
                "sleepHours",
                "totalSleepHours",
            ],
        )

        if hours is not None and hours > 0:
            return round(hours * 60)

        daily_sleep = sleep_data.get("dailySleepDTO")

        if isinstance(daily_sleep, dict):
            seconds = self._first_number(
                daily_sleep,
                [
                    "sleepTimeSeconds",
                    "totalSleepSeconds",
                    "sleepDuration",
                ],
            )

            if seconds is not None and seconds > 0:
                return round(seconds / 60)

            sleep_need = daily_sleep.get("sleepNeed")

            if isinstance(sleep_need, dict):
                actual = self._first_number(
                    sleep_need,
                    [
                        "actual",
                        "baseline",
                    ],
                )

                if actual is not None and actual > 0:
                    return round(actual)

        return 0

    def _extract_hrv(self, hrv_data):
        if not isinstance(hrv_data, dict):
            return 0

        direct = self._first_number(
            hrv_data,
            [
                "weeklyAverage",
                "lastNightAvg",
                "hrvValue",
                "average",
                "avg",
            ],
        )

        if direct is not None and direct > 0:
            return round(direct)

        hrv_summary = hrv_data.get("hrvSummary")

        if isinstance(hrv_summary, dict):
            value = self._first_number(
                hrv_summary,
                [
                    "weeklyAverage",
                    "lastNightAvg",
                    "lastNightAverage",
                    "average",
                    "hrvValue",
                ],
            )

            if value is not None and value > 0:
                return round(value)

        hrv_values = hrv_data.get("hrvValues")

        if isinstance(hrv_values, list) and hrv_values:
            values = []

            for item in hrv_values:
                if isinstance(item, dict):
                    value = self._first_number(
                        item,
                        [
                            "hrv",
                            "value",
                            "rmssd",
                            "hrvValue",
                        ],
                    )

                    if value is not None and value > 0:
                        values.append(value)

            if values:
                return round(sum(values) / len(values))

        return 0

    def _extract_body_battery(self, body_battery_data):
        values = []

        if isinstance(body_battery_data, dict):
            direct = self._first_number(
                body_battery_data,
                [
                    "mostRecentValue",
                    "bodyBattery",
                    "value",
                    "bodyBatteryMostRecentValue",
                ],
            )

            if direct is not None and direct > 0:
                return direct

            array = body_battery_data.get("bodyBatteryValuesArray")
            if isinstance(array, list):
                for item in array:
                    if isinstance(item, list) and len(item) >= 2:
                        value = item[1]
                        if isinstance(value, (int, float)) and value > 0:
                            values.append(value)

        if isinstance(body_battery_data, list):
            for day in body_battery_data:
                if not isinstance(day, dict):
                    continue

                direct = self._first_number(
                    day,
                    [
                        "mostRecentValue",
                        "bodyBattery",
                        "value",
                        "bodyBatteryMostRecentValue",
                    ],
                )

                if direct is not None and direct > 0:
                    values.append(direct)

                array = day.get("bodyBatteryValuesArray")
                if isinstance(array, list):
                    for item in array:
                        if isinstance(item, list) and len(item) >= 2:
                            value = item[1]
                            if isinstance(value, (int, float)) and value > 0:
                                values.append(value)

        if values:
            return values[-1]

        return None

    def _extract_steps_from_activities(self, activities):
        total = 0

        if not isinstance(activities, list):
            return None

        for activity in activities:
            if not isinstance(activity, dict):
                continue

            value = self._first_number(activity, ["steps"])

            if value is not None and value > 0:
                total += value

        return total if total > 0 else None

    def _extract_resting_hr_from_activities(self, activities):
        values = []

        if not isinstance(activities, list):
            return None

        for activity in activities:
            if not isinstance(activity, dict):
                continue

            value = self._first_number(
                activity,
                ["restingHeartRate", "minHeartRate", "averageHR"],
            )

            if value is not None and value > 0:
                values.append(value)

        if values:
            return min(values)

        return None
