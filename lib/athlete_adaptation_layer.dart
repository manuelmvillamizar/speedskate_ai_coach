import 'adaptive_response_memory.dart';
import 'athlete_performance_context.dart';
import 'athlete_program_service.dart';
import 'daily_athlete_log.dart';

class AthleteAdaptationProfile {
  final double neuralTolerance;
  final double metabolicTolerance;
  final double lactateTolerance;
  final double reactiveTolerance;
  final double taperNeed;
  final double recoveryNeed;
  final double densityTolerance;

  final bool toleratesNeuralLoad;
  final bool strugglesWithLactate;
  final bool needsLongerTaper;
  final bool needsReactiveProtection;
  final bool toleratesDoubleIntensity;

  final String summary;

  const AthleteAdaptationProfile({
    required this.neuralTolerance,
    required this.metabolicTolerance,
    required this.lactateTolerance,
    required this.reactiveTolerance,
    required this.taperNeed,
    required this.recoveryNeed,
    required this.densityTolerance,
    required this.toleratesNeuralLoad,
    required this.strugglesWithLactate,
    required this.needsLongerTaper,
    required this.needsReactiveProtection,
    required this.toleratesDoubleIntensity,
    required this.summary,
  });
}

class AthleteAdaptationLayer {
  static AthleteAdaptationProfile build(
    AthletePerformanceContext context, {
    AdaptiveResponseMemory? adaptiveMemory,
  }) {
    final athlete = context.athlete;
    final profile = context.physiologyProfile;
    final logs = context.sortedLogs;

    final last14 = _last(logs, 14);

    final avgReadiness14 = _avgReadiness(last14, context.currentReadiness);
    final avgSoreness14 = _avgSoreness(last14);
    final avgInjuryRisk14 = _avgInjuryRisk(last14, context.currentInjuryRisk);

    final highIntensity7 = _sumHighIntensity(_last(logs, 7));
    final highIntensity14 = _sumHighIntensity(last14);
    final zone5_14 = _sumZone5(last14);
    final neuralDays14 = _neuralDays(last14);
    final metabolicDays14 = _metabolicDays(last14);

    final poorRecoveryDays14 = last14.where((log) => log.readiness < 60).length;

    double neuralTolerance = 1.0;
    double metabolicTolerance = 1.0;
    double lactateTolerance = 1.0;
    double reactiveTolerance = 1.0;
    double taperNeed = 1.0;
    double recoveryNeed = 1.0;
    double densityTolerance = 1.0;

    if (athlete.type == AthleteProgramType.sprinter) {
      neuralTolerance += 0.10;
      metabolicTolerance -= 0.05;
      lactateTolerance -= 0.08;
    }

    if (athlete.type == AthleteProgramType.endurance) {
      metabolicTolerance += 0.10;
      neuralTolerance -= 0.05;
      reactiveTolerance -= 0.06;
    }

    if (athlete.type == AthleteProgramType.mixed) {
      neuralTolerance += 0.04;
      metabolicTolerance += 0.04;
    }

    if (profile.speedResponse > 1.12 && avgReadiness14 >= 72) {
      neuralTolerance += 0.12;
    }

    if (profile.enduranceResponse > 1.12 && avgReadiness14 >= 72) {
      metabolicTolerance += 0.10;
    }

    if (profile.recoveryRate < 0.90 || poorRecoveryDays14 >= 4) {
      recoveryNeed += 0.18;
      taperNeed += 0.12;
      densityTolerance -= 0.12;
    }

    if (profile.fatigueAccumulationRate > 1.25) {
      recoveryNeed += 0.15;
      densityTolerance -= 0.15;
      neuralTolerance -= 0.08;
      metabolicTolerance -= 0.08;
    }

    if (adaptiveMemory != null) {
      neuralTolerance *= adaptiveMemory.sprintTolerance;
      metabolicTolerance *= adaptiveMemory.lactateTolerance;
      lactateTolerance *= adaptiveMemory.lactateTolerance;
      reactiveTolerance *= adaptiveMemory.jumpTolerance;
      densityTolerance *= adaptiveMemory.doubleSessionTolerance;
      taperNeed *= (2 - adaptiveMemory.taperResponse);

      if (adaptiveMemory.strugglesWithJumps) {
        reactiveTolerance -= 0.12;
        recoveryNeed += 0.08;
      }

      if (adaptiveMemory.strugglesWithLactate) {
        lactateTolerance -= 0.15;
        metabolicTolerance -= 0.10;
      }

      if (adaptiveMemory.strugglesWithZ5) {
        neuralTolerance -= 0.12;
      }

      if (adaptiveMemory.toleratesSprint) {
        neuralTolerance += 0.12;
      }

      if (adaptiveMemory.toleratesGym) {
        neuralTolerance += 0.08;
      }

      if (adaptiveMemory.respondsWellToTaper) {
        taperNeed -= 0.10;
      }

      if (adaptiveMemory.needsLongerTaper) {
        taperNeed += 0.12;
      }

      if (adaptiveMemory.toleratesDoubleSession) {
        densityTolerance += 0.10;
      }
    }

    if (avgSoreness14 >= 6 || avgInjuryRisk14 >= 55) {
      reactiveTolerance -= 0.18;
      recoveryNeed += 0.12;
    }

    if (zone5_14 >= 45 && avgReadiness14 < 70) {
      neuralTolerance -= 0.15;
      reactiveTolerance -= 0.12;
    }

    if (highIntensity14 >= 160 && avgReadiness14 < 72) {
      metabolicTolerance -= 0.15;
      lactateTolerance -= 0.18;
    }

    if (metabolicDays14 >= 5 && avgReadiness14 < 70) {
      lactateTolerance -= 0.20;
      recoveryNeed += 0.10;
    }

    if (neuralDays14 >= 5 && avgReadiness14 < 70) {
      neuralTolerance -= 0.18;
      reactiveTolerance -= 0.15;
    }

    if (highIntensity7 >= 80 && avgReadiness14 >= 75 && avgInjuryRisk14 < 45) {
      densityTolerance += 0.10;
    }

    final dataQuality = context.dataQuality;
    final baseline = context.dynamicBaseline;
    final fatigueSystems = context.fatigueSystems;

    if (dataQuality != null && baseline != null) {
      if (!dataQuality.canAdaptTraining) {
        recoveryNeed += 0.08;
        densityTolerance -= 0.06;
      }

      if (dataQuality.canLearn) {
        if (baseline.hrv.trendNormalized > 0.05 &&
            baseline.sleepHours.trendNormalized >= 0) {
          recoveryNeed -= 0.05;
          densityTolerance += 0.04;
        }

        if (baseline.hrv.trendNormalized < -0.08) {
          recoveryNeed += 0.10;
          neuralTolerance -= 0.08;
          densityTolerance -= 0.06;
        }

        if (baseline.sleepHours.trendNormalized < -0.06) {
          recoveryNeed += 0.08;
          metabolicTolerance -= 0.05;
          lactateTolerance -= 0.05;
        }

        if (baseline.stress.trendNormalized > 0.08) {
          recoveryNeed += 0.08;
          densityTolerance -= 0.06;
        }
      }
    }

    if (fatigueSystems != null && fatigueSystems.overallConfidence >= 0.45) {
      if (fatigueSystems.neural.score >= 65) {
        neuralTolerance -= 0.12;
        densityTolerance -= 0.08;
        recoveryNeed += 0.10;
      }

      if (fatigueSystems.metabolic.score >= 65) {
        metabolicTolerance -= 0.12;
        lactateTolerance -= 0.12;
        recoveryNeed += 0.08;
      }

      if (fatigueSystems.tissueStress.score >= 60) {
        reactiveTolerance -= 0.16;
        recoveryNeed += 0.10;
      }

      if (fatigueSystems.cardiovascular.score >= 65) {
        metabolicTolerance -= 0.08;
        recoveryNeed += 0.10;
      }

      if (fatigueSystems.muscular.score >= 65) {
        neuralTolerance -= 0.05;
        reactiveTolerance -= 0.08;
        recoveryNeed += 0.08;
      }
    }

    neuralTolerance = neuralTolerance.clamp(0.70, 1.30);
    metabolicTolerance = metabolicTolerance.clamp(0.70, 1.30);
    lactateTolerance = lactateTolerance.clamp(0.65, 1.25);
    reactiveTolerance = reactiveTolerance.clamp(0.65, 1.25);
    taperNeed = taperNeed.clamp(0.85, 1.35);
    recoveryNeed = recoveryNeed.clamp(0.85, 1.40);
    densityTolerance = densityTolerance.clamp(0.70, 1.25);

    final toleratesNeuralLoad =
        neuralTolerance >= 1.08 &&
        avgReadiness14 >= 72 &&
        avgInjuryRisk14 < 50 &&
        !context.hasHighNeuralFatigue;

    final strugglesWithLactate =
        lactateTolerance <= 0.88 || metabolicDays14 >= 5;

    final needsLongerTaper =
        taperNeed >= 1.12 ||
        profile.successfulTapers < profile.poorRecoveryBlocks;

    final needsReactiveProtection =
        reactiveTolerance <= 0.88 ||
        avgSoreness14 >= 6 ||
        context.hasHighTissueStress;

    final toleratesDoubleIntensity =
        densityTolerance >= 1.08 &&
        avgReadiness14 >= 76 &&
        avgInjuryRisk14 < 45 &&
        poorRecoveryDays14 <= 2 &&
        !context.hasHighNeuralFatigue &&
        !context.hasHighMetabolicFatigue;

    return AthleteAdaptationProfile(
      neuralTolerance: neuralTolerance,
      metabolicTolerance: metabolicTolerance,
      lactateTolerance: lactateTolerance,
      reactiveTolerance: reactiveTolerance,
      taperNeed: taperNeed,
      recoveryNeed: recoveryNeed,
      densityTolerance: densityTolerance,
      toleratesNeuralLoad: toleratesNeuralLoad,
      strugglesWithLactate: strugglesWithLactate,
      needsLongerTaper: needsLongerTaper,
      needsReactiveProtection: needsReactiveProtection,
      toleratesDoubleIntensity: toleratesDoubleIntensity,
      summary: _summary(
        toleratesNeuralLoad: toleratesNeuralLoad,
        strugglesWithLactate: strugglesWithLactate,
        needsLongerTaper: needsLongerTaper,
        needsReactiveProtection: needsReactiveProtection,
        toleratesDoubleIntensity: toleratesDoubleIntensity,
      ),
    );
  }

  static List<DailyAthleteLog> _last(List<DailyAthleteLog> logs, int count) {
    if (logs.length <= count) return logs;
    return logs.sublist(logs.length - count);
  }

  static double _avgReadiness(List<DailyAthleteLog> logs, int fallback) {
    if (logs.isEmpty) return fallback.toDouble();

    return logs.fold<double>(0, (sum, log) => sum + log.readiness) /
        logs.length;
  }

  static double _avgSoreness(List<DailyAthleteLog> logs) {
    if (logs.isEmpty) return 3.0;

    return logs.fold<double>(0, (sum, log) => sum + log.soreness) / logs.length;
  }

  static double _avgInjuryRisk(List<DailyAthleteLog> logs, double fallback) {
    if (logs.isEmpty) return fallback;

    return logs.fold<double>(0, (sum, log) => sum + log.injuryRisk) /
        logs.length;
  }

  static int _sumHighIntensity(List<DailyAthleteLog> logs) {
    return logs.fold<int>(0, (sum, log) => sum + log.highIntensityMinutes);
  }

  static int _sumZone5(List<DailyAthleteLog> logs) {
    return logs.fold<int>(0, (sum, log) => sum + log.zone5Minutes);
  }

  static int _neuralDays(List<DailyAthleteLog> logs) {
    return logs.where((log) {
      final session = log.performedSessionType.toLowerCase();

      return log.zone5Minutes >= 5 ||
          session.contains('speed') ||
          session.contains('sprint') ||
          session.contains('power') ||
          session.contains('plyometric') ||
          session.contains('salida') ||
          session.contains('velocidad');
    }).length;
  }

  static int _metabolicDays(List<DailyAthleteLog> logs) {
    return logs.where((log) {
      final session = log.performedSessionType.toLowerCase();

      return log.highIntensityMinutes >= 25 ||
          session.contains('lactate') ||
          session.contains('lactato') ||
          session.contains('tempo') ||
          session.contains('interval');
    }).length;
  }

  static String _summary({
    required bool toleratesNeuralLoad,
    required bool strugglesWithLactate,
    required bool needsLongerTaper,
    required bool needsReactiveProtection,
    required bool toleratesDoubleIntensity,
  }) {
    final notes = <String>[];

    if (toleratesNeuralLoad) {
      notes.add('tolera bien carga neural');
    }

    if (strugglesWithLactate) {
      notes.add('muestra sensibilidad a lactato');
    }

    if (needsLongerTaper) {
      notes.add('requiere taper más conservador');
    }

    if (needsReactiveProtection) {
      notes.add('necesita protección reactiva/pliométrica');
    }

    if (toleratesDoubleIntensity) {
      notes.add('tolera mayor densidad de intensidad');
    }

    if (notes.isEmpty) {
      return 'Adaptación estable sin patrón crítico dominante.';
    }

    return 'Perfil adaptativo: ${notes.join(', ')}.';
  }
}
