import '../../wearable_integration_service.dart';
import '../infrastructure/garmin_json_importer.dart';
import 'garmin_wearable_mapper.dart';

class GarminDataFusionMapper {
  static WearableDailyData? fuse({
    required WearableDailyData? dailySummary,
    required GarminImportedTraining? latestTraining,
  }) {
    if (dailySummary == null && latestTraining == null) {
      return null;
    }

    // CASO 1: Solo training import (estimado, sin salud diaria real)
    if (dailySummary == null && latestTraining != null) {
      return GarminWearableMapper.toWearableData(latestTraining);
    }

    // CASO 2: Solo daily summary real (sin entrenamiento importado)
    if (dailySummary != null && latestTraining == null) {
      return WearableDailyData(
        date: dailySummary.date,
        sleepMinutes: dailySummary.sleepMinutes,
        hrv: dailySummary.hrv,
        restingHeartRate: dailySummary.restingHeartRate,
        stress: dailySummary.stress,
        soreness: dailySummary.soreness,
        activeCalories: dailySummary.activeCalories,
        steps: dailySummary.steps,
        trainingLoad: dailySummary.trainingLoad,
        bodyBattery: dailySummary.bodyBattery,
        zone1Minutes: dailySummary.zone1Minutes,
        zone2Minutes: dailySummary.zone2Minutes,
        zone3Minutes: dailySummary.zone3Minutes,
        zone4Minutes: dailySummary.zone4Minutes,
        zone5Minutes: dailySummary.zone5Minutes,
        averageHeartRate: dailySummary.averageHeartRate,
        maxHeartRate: dailySummary.maxHeartRate,
        rpe: dailySummary.rpe,
        totalTrainingMinutes: dailySummary.totalTrainingMinutes,
        totalDistanceKm: dailySummary.totalDistanceKm,
        source: 'garmin_real',
        hasRealDailyHealth: true,
        hasImportedTraining: false,
      );
    }

    // CASO 3: Fusi�n real (daily summary + training import) ? PIPELINE PRINCIPAL
    final daily = dailySummary!;
    final training = latestTraining!;

    final hasTrainingLoad = training.internalLoad > 0;
    final hasTrainingZones =
        training.zone1Minutes +
            training.zone2Minutes +
            training.zone3Minutes +
            training.zone4Minutes +
            training.zone5Minutes >
        0;

    final estimatedActiveCalories = (training.internalLoad * 8).round();
    final estimatedSteps = (training.distanceKm * 1400).round();

    return WearableDailyData(
      date: training.startTime ?? daily.date,

      sleepMinutes: daily.sleepMinutes,
      hrv: daily.hrv,
      restingHeartRate: daily.restingHeartRate,
      stress: daily.stress,
      soreness: daily.soreness,
      bodyBattery: daily.bodyBattery,

      activeCalories: daily.activeCalories > 0
          ? daily.activeCalories
          : estimatedActiveCalories,

      steps: daily.steps > 0 ? daily.steps : estimatedSteps,

      trainingLoad: hasTrainingLoad
          ? training.internalLoad
          : daily.trainingLoad,

      zone1Minutes: hasTrainingZones
          ? training.zone1Minutes.round()
          : daily.zone1Minutes,

      zone2Minutes: hasTrainingZones
          ? training.zone2Minutes.round()
          : daily.zone2Minutes,

      zone3Minutes: hasTrainingZones
          ? training.zone3Minutes.round()
          : daily.zone3Minutes,

      zone4Minutes: hasTrainingZones
          ? training.zone4Minutes.round()
          : daily.zone4Minutes,

      zone5Minutes: hasTrainingZones
          ? training.zone5Minutes.round()
          : daily.zone5Minutes,

      averageHeartRate: training.averageHeartRate > 0
          ? training.averageHeartRate.round()
          : daily.averageHeartRate,

      maxHeartRate: training.maxHeartRate > 0
          ? training.maxHeartRate.round()
          : daily.maxHeartRate,

      rpe: _estimatedRpe(
        highIntensityRatio: training.highIntensityRatio,
        fallback: daily.rpe,
      ),

      totalTrainingMinutes: training.durationMinutes > 0
          ? training.durationMinutes.round()
          : daily.totalTrainingMinutes,

      totalDistanceKm: training.distanceKm > 0
          ? training.distanceKm
          : daily.totalDistanceKm,

      source: 'garmin_fusion',
      hasRealDailyHealth: true,
      hasImportedTraining: true,
    );
  }

  static int _estimatedRpe({
    required double highIntensityRatio,
    required int fallback,
  }) {
    if (fallback > 0) return fallback;

    if (highIntensityRatio > 0.30) return 9;
    if (highIntensityRatio > 0.18) return 7;
    if (highIntensityRatio > 0.08) return 5;

    return 3;
  }
}

