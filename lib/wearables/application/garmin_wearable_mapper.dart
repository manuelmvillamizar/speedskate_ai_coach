import '../../wearable_integration_service.dart';
import '../infrastructure/garmin_json_importer.dart';

class GarminWearableMapper {
  static WearableDailyData toWearableData(GarminImportedTraining training) {
    final estimatedSleepMinutes = 450;

    final estimatedStress = training.highIntensityRatio > 0.30
        ? 72
        : training.highIntensityRatio > 0.18
        ? 55
        : 35;

    final estimatedHrv = training.internalLoad > 300
        ? 42
        : training.internalLoad > 220
        ? 50
        : 60;

    final estimatedBodyBattery = training.internalLoad > 300
        ? 28
        : training.internalLoad > 220
        ? 45
        : 72;

    final soreness = training.internalLoad > 320
        ? 8
        : training.internalLoad > 220
        ? 6
        : 3;

    final estimatedRhr = training.internalLoad > 300
        ? 62
        : training.internalLoad > 220
        ? 57
        : 52;

    final estimatedRpe = training.highIntensityRatio > 0.30
        ? 9
        : training.highIntensityRatio > 0.18
        ? 7
        : 5;

    return WearableDailyData(
      date: training.startTime ?? DateTime.now(),

      sleepMinutes: estimatedSleepMinutes,
      hrv: estimatedHrv,
      restingHeartRate: estimatedRhr,
      stress: estimatedStress,
      soreness: soreness,

      activeCalories: (training.internalLoad * 8).round(),
      steps: (training.distanceKm * 1400).round(),
      trainingLoad: training.internalLoad,
      bodyBattery: estimatedBodyBattery,

      zone1Minutes: training.zone1Minutes.round(),
      zone2Minutes: training.zone2Minutes.round(),
      zone3Minutes: training.zone3Minutes.round(),
      zone4Minutes: training.zone4Minutes.round(),
      zone5Minutes: training.zone5Minutes.round(),

      averageHeartRate: training.averageHeartRate.round(),
      maxHeartRate: training.maxHeartRate.round(),

      rpe: estimatedRpe,

      totalTrainingMinutes: training.durationMinutes.round(),
      totalDistanceKm: training.distanceKm,

      source: 'garmin_training_estimated',
      hasRealDailyHealth: false,
      hasImportedTraining: true,
    );
  }
}

