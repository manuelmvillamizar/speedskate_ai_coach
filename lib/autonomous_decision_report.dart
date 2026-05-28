import 'athlete_daily_state.dart';
import 'integrated_training_day.dart';
import 'training_intervention_engine.dart';

class AutonomousDecisionReport {
  final String title;
  final String summary;
  final List<String> appliedAdjustments;
  final List<String> physiologicalFactors;
  final List<String> performanceProtections;

  const AutonomousDecisionReport({
    required this.title,
    required this.summary,
    required this.appliedAdjustments,
    required this.physiologicalFactors,
    required this.performanceProtections,
  });
}

class AutonomousDecisionReportBuilder {
  static AutonomousDecisionReport build({
    required AthleteDailyState state,
    required TrainingInterventionResult intervention,
    required IntegratedTrainingDay originalDay,
    required IntegratedTrainingDay adjustedDay,
  }) {
    final appliedAdjustments = <String>[];
    final physiologicalFactors = <String>[];
    final performanceProtections = <String>[];

    if (state.shouldForceRecovery) {
      appliedAdjustments.add('Sesión orientada a recuperación activa.');
      performanceProtections.add('Se protegió la recuperación general.');
    }

    if (state.shouldBlockIntensity || intervention.blockHighIntensity) {
      appliedAdjustments.add('Alta intensidad limitada para el día.');
      performanceProtections.add('Se evitó acumulación excesiva en Z4/Z5.');
    }

    if (state.shouldReduceLoad || intervention.reduceVolume) {
      appliedAdjustments.add('Volumen total reducido.');
      performanceProtections.add('Se controló la carga residual del día.');
    }

    if (intervention.blockHeavyStrength) {
      appliedAdjustments.add('Fuerza pesada retirada o limitada.');
      performanceProtections.add('Se protegió el sistema neuromuscular.');
    }

    if (intervention.blockDoubleSession) {
      appliedAdjustments.add('Doble sesión de riesgo evitada.');
      performanceProtections.add('Se redujo la densidad de carga diaria.');
    }

    if (intervention.blockHeavyStrength) {
      appliedAdjustments.add('Pliometría o carga reactiva protegida.');
      performanceProtections.add('Se redujo estrés tendinoso y neuromuscular.');
    }

    if (state.taperRecommended || intervention.protectCompetition) {
      appliedAdjustments.add('Frescura competitiva protegida.');
      performanceProtections.add('Se conservó velocidad sin acumular fatiga.');
    }

    if (adjustedDay.totalLoad < originalDay.totalLoad) {
      final diff = originalDay.totalLoad - adjustedDay.totalLoad;
      appliedAdjustments.add('Carga reducida en $diff puntos.');
    }

    if (adjustedDay.totalMinutes < originalDay.totalMinutes) {
      final diff = originalDay.totalMinutes - adjustedDay.totalMinutes;
      appliedAdjustments.add('Duración reducida en $diff minutos.');
    }

    if (state.readiness < 60) {
      physiologicalFactors.add('Disponibilidad baja: ${state.readiness}/100.');
    } else if (state.readiness < 80) {
      physiologicalFactors.add(
        'Disponibilidad moderada: ${state.readiness}/100.',
      );
    } else {
      physiologicalFactors.add(
        'Disponibilidad favorable: ${state.readiness}/100.',
      );
    }

    if (state.injuryRisk >= 60) {
      physiologicalFactors.add(
        'Riesgo de lesión elevado: ${state.injuryRisk.toStringAsFixed(0)}/100.',
      );
    } else {
      physiologicalFactors.add(
        'Riesgo controlado: ${state.injuryRisk.toStringAsFixed(0)}/100.',
      );
    }

    if (state.acwr > 1.5) {
      physiologicalFactors.add(
        'ACWR alto (${state.acwr.toStringAsFixed(2)}): carga aguda por encima de tolerancia.',
      );
    } else if (state.acwr > 1.3) {
      physiologicalFactors.add(
        'ACWR en zona de precaución (${state.acwr.toStringAsFixed(2)}).',
      );
    } else {
      physiologicalFactors.add(
        'ACWR estable (${state.acwr.toStringAsFixed(2)}).',
      );
    }

    final wearable = state.wearable;
    final profile = state.physiologyProfile;

    if (wearable != null) {
      if (wearable.hrv < profile.baselineHrv * 0.90) {
        physiologicalFactors.add('HRV por debajo de la base individual.');
      }

      if (wearable.restingHeartRate > profile.baselineRestingHeartRate + 6) {
        physiologicalFactors.add('FC reposo elevada frente a la base.');
      }

      if (wearable.sleepHours < 6.5) {
        physiologicalFactors.add('Sueño insuficiente para carga alta.');
      }

      if (wearable.stress >= 65) {
        physiologicalFactors.add('Estrés diario elevado.');
      }

      if (wearable.highIntensityMinutes >= 25) {
        physiologicalFactors.add('Alta intensidad reciente acumulada.');
      }
    }

    if (appliedAdjustments.isEmpty) {
      appliedAdjustments.add('Plan conservado sin cambios críticos.');
    }

    if (performanceProtections.isEmpty) {
      performanceProtections.add('Se mantuvo el estímulo principal del día.');
    }

    return AutonomousDecisionReport(
      title: 'Control de carga del día',
      summary: _summary(state),
      appliedAdjustments: appliedAdjustments,
      physiologicalFactors: physiologicalFactors,
      performanceProtections: performanceProtections,
    );
  }

  static String _summary(AthleteDailyState state) {
    if (state.shouldForceRecovery) {
      return 'El plan se orientó a recuperación para proteger adaptación y continuidad.';
    }

    if (state.shouldBlockIntensity) {
      return 'El plan limitó la intensidad para evitar sobrecarga fisiológica.';
    }

    if (state.shouldReduceLoad) {
      return 'El plan ajustó la carga para mantener calidad sin acumular fatiga.';
    }

    if (state.taperRecommended) {
      return 'El plan protegió frescura y velocidad para rendimiento competitivo.';
    }

    return 'El plan mantiene el estímulo principal con control fisiológico estable.';
  }
}


