import '../../wearables/application/garmin_training_bridge.dart';

class WearableTrainingPipelineResult {
  final bool hasWearableData;

  final double internalLoad;
  final double highIntensityMinutes;

  final double averageHeartRate;
  final double maxHeartRate;

  final double readinessScore;

  final bool shouldReduceLoad;
  final bool shouldBlockIntensity;
  final bool shouldForceRecovery;

  const WearableTrainingPipelineResult({
    required this.hasWearableData,
    required this.internalLoad,
    required this.highIntensityMinutes,
    required this.averageHeartRate,
    required this.maxHeartRate,
    required this.readinessScore,
    required this.shouldReduceLoad,
    required this.shouldBlockIntensity,
    required this.shouldForceRecovery,
  });
}

class WearableToTrainingPipeline {
  static Future<WearableTrainingPipelineResult> process({
    required String athleteId,
  }) async {
    final wearable = await GarminTrainingBridge.loadLatestTraining(
      athleteId: athleteId,
    );

    if (!wearable.hasTraining || wearable.training == null) {
      return const WearableTrainingPipelineResult(
        hasWearableData: false,
        internalLoad: 0,
        highIntensityMinutes: 0,
        averageHeartRate: 0,
        maxHeartRate: 0,
        readinessScore: 50,
        shouldReduceLoad: false,
        shouldBlockIntensity: false,
        shouldForceRecovery: false,
      );
    }

    final training = wearable.training!;

    double readiness = 100;

    bool reduceLoad = false;
    bool blockIntensity = false;
    bool forceRecovery = false;

    if (training.internalLoad > 250) {
      readiness -= 15;
      reduceLoad = true;
    }

    if (training.highIntensityMinutes > 20) {
      readiness -= 20;
      blockIntensity = true;
    }

    if (training.maxHeartRate > 185) {
      readiness -= 10;
    }

    if (training.highIntensityRatio > 0.35) {
      readiness -= 20;
      reduceLoad = true;
    }

    if (training.internalLoad > 350) {
      readiness -= 25;
      forceRecovery = true;
      blockIntensity = true;
    }

    readiness = readiness.clamp(0, 100);

    return WearableTrainingPipelineResult(
      hasWearableData: true,
      internalLoad: training.internalLoad,
      highIntensityMinutes: training.highIntensityMinutes,
      averageHeartRate: training.averageHeartRate,
      maxHeartRate: training.maxHeartRate,
      readinessScore: readiness,
      shouldReduceLoad: reduceLoad,
      shouldBlockIntensity: blockIntensity,
      shouldForceRecovery: forceRecovery,
    );
  }
}
