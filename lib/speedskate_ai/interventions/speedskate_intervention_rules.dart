import '../../physiology/recovery/live_readiness_service.dart';

class SpeedSkateInterventionDecision {
  final String status;
  final String title;
  final String recommendation;

  final bool reduceLoad;
  final bool blockIntensity;
  final bool forceRecovery;

  final bool removePlyometrics;
  final bool removeHeavyStrength;
  final bool removeLactate;
  final bool reduceVolume;
  final bool allowSpeedQuality;

  const SpeedSkateInterventionDecision({
    required this.status,
    required this.title,
    required this.recommendation,
    required this.reduceLoad,
    required this.blockIntensity,
    required this.forceRecovery,
    required this.removePlyometrics,
    required this.removeHeavyStrength,
    required this.removeLactate,
    required this.reduceVolume,
    required this.allowSpeedQuality,
  });
}

class SpeedSkateInterventionRules {
  static Future<SpeedSkateInterventionDecision> fromGarminReadiness() async {
    final readiness = await LiveReadinessService.getTodayReadiness();

    if (readiness.shouldForceRecovery || readiness.readinessScore < 40) {
      return const SpeedSkateInterventionDecision(
        status: 'red',
        title: 'Recuperación obligatoria',
        recommendation:
            'Bloquear intensidad. Usar movilidad, técnica suave o bici Z1.',
        reduceLoad: true,
        blockIntensity: true,
        forceRecovery: true,
        removePlyometrics: true,
        removeHeavyStrength: true,
        removeLactate: true,
        reduceVolume: true,
        allowSpeedQuality: false,
      );
    }

    if (readiness.shouldBlockIntensity || readiness.readinessScore < 60) {
      return const SpeedSkateInterventionDecision(
        status: 'orange',
        title: 'Fatiga alta',
        recommendation:
            'Quitar lactato, velocidad máxima, pliometría y fuerza pesada.',
        reduceLoad: true,
        blockIntensity: true,
        forceRecovery: false,
        removePlyometrics: true,
        removeHeavyStrength: true,
        removeLactate: true,
        reduceVolume: true,
        allowSpeedQuality: false,
      );
    }

    if (readiness.shouldReduceLoad || readiness.readinessScore < 80) {
      return const SpeedSkateInterventionDecision(
        status: 'yellow',
        title: 'Carga controlada',
        recommendation:
            'Mantener técnica y velocidad corta. Reducir volumen total.',
        reduceLoad: true,
        blockIntensity: false,
        forceRecovery: false,
        removePlyometrics: true,
        removeHeavyStrength: false,
        removeLactate: true,
        reduceVolume: true,
        allowSpeedQuality: true,
      );
    }

    return const SpeedSkateInterventionDecision(
      status: 'green',
      title: 'Listo para calidad',
      recommendation:
          'Mantener estímulo planificado. Se permite intensidad controlada.',
      reduceLoad: false,
      blockIntensity: false,
      forceRecovery: false,
      removePlyometrics: false,
      removeHeavyStrength: false,
      removeLactate: false,
      reduceVolume: false,
      allowSpeedQuality: true,
    );
  }
}


