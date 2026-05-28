import '../../speedskate_ai/orchestration/wearable_to_training_pipeline.dart';

class LiveReadinessState {
  final double readinessScore;

  final bool shouldReduceLoad;
  final bool shouldBlockIntensity;
  final bool shouldForceRecovery;

  final double internalLoad;
  final double highIntensityMinutes;

  const LiveReadinessState({
    required this.readinessScore,
    required this.shouldReduceLoad,
    required this.shouldBlockIntensity,
    required this.shouldForceRecovery,
    required this.internalLoad,
    required this.highIntensityMinutes,
  });
}

class LiveReadinessService {
  static Future<LiveReadinessState> getTodayReadiness() async {
    final pipeline = await WearableToTrainingPipeline.process(
      athleteId: 'global-athlete',
    );

    return LiveReadinessState(
      readinessScore: pipeline.readinessScore,
      shouldReduceLoad: pipeline.shouldReduceLoad,
      shouldBlockIntensity: pipeline.shouldBlockIntensity,
      shouldForceRecovery: pipeline.shouldForceRecovery,
      internalLoad: pipeline.internalLoad,
      highIntensityMinutes: pipeline.highIntensityMinutes,
    );
  }
}
