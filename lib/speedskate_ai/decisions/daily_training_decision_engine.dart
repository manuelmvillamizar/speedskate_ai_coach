import '../interventions/speedskate_intervention_rules.dart';

class DailyTrainingDecision {
  final String readinessColor;

  final bool reduceLoad;
  final bool blockIntensity;
  final bool forceRecovery;

  final bool removePlyometrics;
  final bool removeHeavyStrength;
  final bool removeLactate;

  final bool allowSpeedQuality;

  final String coachRecommendation;

  const DailyTrainingDecision({
    required this.readinessColor,
    required this.reduceLoad,
    required this.blockIntensity,
    required this.forceRecovery,
    required this.removePlyometrics,
    required this.removeHeavyStrength,
    required this.removeLactate,
    required this.allowSpeedQuality,
    required this.coachRecommendation,
  });
}

class DailyTrainingDecisionEngine {
  static Future<DailyTrainingDecision> generate() async {
    final intervention =
        await SpeedSkateInterventionRules.fromGarminReadiness();

    return DailyTrainingDecision(
      readinessColor: intervention.status,
      reduceLoad: intervention.reduceLoad,
      blockIntensity: intervention.blockIntensity,
      forceRecovery: intervention.forceRecovery,
      removePlyometrics: intervention.removePlyometrics,
      removeHeavyStrength: intervention.removeHeavyStrength,
      removeLactate: intervention.removeLactate,
      allowSpeedQuality: intervention.allowSpeedQuality,
      coachRecommendation: intervention.recommendation,
    );
  }
}


