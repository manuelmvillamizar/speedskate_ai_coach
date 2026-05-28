import '../../wearable_integration_service.dart';
import '../infrastructure/garmin_json_importer.dart';

class GarminDailySummaryMapper {
  static WearableDailyData? toWearableData({
    required GarminImportedDailySummary? dailySummary,
    DateTime? fallbackDate,
  }) {
    if (dailySummary == null) return null;

    return WearableDailyData(
      date: dailySummary.date ?? fallbackDate ?? DateTime.now(),

      sleepMinutes: dailySummary.sleepMinutes ?? 0,
      hrv: dailySummary.hrv?.round() ?? 0,
      restingHeartRate: dailySummary.restingHeartRate ?? 0,
      stress: dailySummary.stress ?? 0,
      soreness: 0,

      activeCalories: 0,
      steps: 0,
      trainingLoad: 0,
      bodyBattery: dailySummary.bodyBattery ?? 0,

      zone1Minutes: 0,
      zone2Minutes: 0,
      zone3Minutes: 0,
      zone4Minutes: 0,
      zone5Minutes: 0,

      source: 'garmin_real',
      hasRealDailyHealth: true,
      hasImportedTraining: false,
    );
  }
}

