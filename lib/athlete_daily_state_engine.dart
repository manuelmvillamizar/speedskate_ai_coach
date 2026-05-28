import 'athlete_daily_state.dart';
import 'athlete_physiology_profile.dart';
import 'daily_athlete_log.dart';
import 'wearable_integration_service.dart';
import 'ai_performance_predictor.dart';

import 'physiology/models/strength_load_state.dart';

class AthleteDailyStateEngine {
  static AthleteDailyState build({
    required String athleteId,
    required AthletePhysiologyProfile profile,
    required List<DailyAthleteLog> logs,
    required WearableDailyData? wearable,

    StrengthLoadState strengthLoadState = const StrengthLoadState(
      externalStrengthLoadKg: 0,
      reactiveJumpLoadKg: 0,
      totalMechanicalLoadKg: 0,
      neuralStress: 0,
      muscleStress: 0,
      tendonStress: 0,
      adaptationSignal: 'none',
    ),
  }) {
    final sortedLogs = List<DailyAthleteLog>.from(logs)
      ..sort((a, b) => a.date.compareTo(b.date));

    final latestLog = sortedLogs.isEmpty ? null : sortedLogs.last;

    final last7Days = sortedLogs.length <= 7
        ? sortedLogs
        : sortedLogs.sublist(sortedLogs.length - 7);

    final last30Days = sortedLogs.length <= 30
        ? sortedLogs
        : sortedLogs.sublist(sortedLogs.length - 30);

    final double acuteLoad = last7Days.isEmpty
        ? 0.0
        : last7Days.fold<double>(0.0, (sum, log) => sum + log.internalLoad) /
              last7Days.length;

    final double chronicLoad = last30Days.isEmpty
        ? 0.0
        : last30Days.fold<double>(0.0, (sum, log) => sum + log.internalLoad) /
              last30Days.length;

    final double acwr = chronicLoad == 0 ? 1.0 : acuteLoad / chronicLoad;

    final highIntensityMinutesToday = _todayHighIntensityMinutes(
      logs: sortedLogs,
      wearable: wearable,
    );

    final highIntensityRatioToday = _todayHighIntensityRatio(
      logs: sortedLogs,
      wearable: wearable,
    );

    final highIntensityMinutes7Days = _sumHighIntensityMinutes(last7Days);
    final highIntensityMinutes30Days = _sumHighIntensityMinutes(last30Days);
    final zone5Minutes7Days = _sumZone5Minutes(last7Days);

    final prediction = AIPerformancePredictor.predict(
      hrv: wearable?.hrv ?? profile.baselineHrv.round(),
      sleepMinutes: ((wearable?.sleepHours ?? profile.averageSleepHours) * 60)
          .round(),
      restingHeartRate:
          wearable?.restingHeartRate ?? profile.baselineRestingHeartRate,
      stress: wearable?.stress ?? profile.averageStress,
      soreness: wearable?.soreness ?? 3,
      acuteLoad: acuteLoad,
      chronicLoad: chronicLoad,
      gymLoad: _lastGymLoad(sortedLogs),
      skateKm: _lastSkateKm(sortedLogs),
      trainingMinutes: _lastMinutes(sortedLogs),
      baselineHrv: profile.baselineHrv,
      baselineRestingHeartRate: profile.baselineRestingHeartRate,
      averageSleepHours: profile.averageSleepHours,
      averageStress: profile.averageStress,
      maxDailyLoad: profile.maxDailyLoad,
      maxGymLoad: profile.maxGymLoad,
      maxSkatingKm: profile.maxSkatingKm,
      fatigueAccumulationRate: profile.fatigueAccumulationRate,
      recoveryRate: profile.recoveryRate,
    );

    var readiness = prediction.readinessScore;
    var injuryRisk = prediction.injuryRisk;

    // ===================================================
    // STRENGTH LOAD INTEGRATION
    // ===================================================

    if (strengthLoadState.neuralStress >= 80) {
      readiness -= 15;
      injuryRisk += 14;
    } else if (strengthLoadState.neuralStress >= 65) {
      readiness -= 10;
      injuryRisk += 10;
    } else if (strengthLoadState.neuralStress >= 50) {
      readiness -= 6;
      injuryRisk += 5;
    }

    if (strengthLoadState.tendonStress >= 80) {
      readiness -= 10;
      injuryRisk += 15;
    } else if (strengthLoadState.tendonStress >= 65) {
      readiness -= 6;
      injuryRisk += 8;
    }

    if (strengthLoadState.muscleStress >= 80) {
      readiness -= 8;
      injuryRisk += 6;
    } else if (strengthLoadState.muscleStress >= 65) {
      readiness -= 4;
      injuryRisk += 4;
    }

    // ===================================================
    // HIDDEN BODY STRESS INTEGRATION
    // ===================================================

    if (latestLog != null) {
      if (latestLog.neuralStress >= 80) {
        readiness -= 12;
        injuryRisk += 10;
      } else if (latestLog.neuralStress >= 65) {
        readiness -= 7;
        injuryRisk += 6;
      }

      if (latestLog.tendonStress >= 80 || latestLog.mechanicalStress >= 80) {
        readiness -= 10;
        injuryRisk += 14;
      } else if (latestLog.tendonStress >= 65 ||
          latestLog.mechanicalStress >= 65) {
        readiness -= 6;
        injuryRisk += 8;
      }

      if (latestLog.muscleStress >= 80) {
        readiness -= 8;
        injuryRisk += 6;
      } else if (latestLog.muscleStress >= 65) {
        readiness -= 4;
        injuryRisk += 4;
      }

      if (latestLog.intermittentStress >= 75) {
        readiness -= 8;
        injuryRisk += 6;
      } else if (latestLog.intermittentStress >= 60) {
        readiness -= 4;
        injuryRisk += 3;
      }

      if (latestLog.recoveryCost >= 80) {
        readiness -= 12;
        injuryRisk += 10;
      } else if (latestLog.recoveryCost >= 65) {
        readiness -= 7;
        injuryRisk += 5;
      }

      if (latestLog.hiddenBodyStress >= 85) {
        readiness -= 10;
        injuryRisk += 8;
      } else if (latestLog.hiddenBodyStress >= 65) {
        readiness -= 5;
        injuryRisk += 4;
      }
    }

    // ===================================================
    // EXISTING LOAD LOGIC
    // ===================================================

    if (highIntensityRatioToday >= 0.35) {
      readiness -= 10;
      injuryRisk += 10;
    } else if (highIntensityRatioToday >= 0.25) {
      readiness -= 6;
      injuryRisk += 6;
    }

    if (highIntensityMinutesToday >= 35) {
      readiness -= 8;
      injuryRisk += 8;
    } else if (highIntensityMinutesToday >= 25) {
      readiness -= 5;
      injuryRisk += 5;
    }

    if (highIntensityMinutes7Days >= 120) {
      readiness -= 12;
      injuryRisk += 14;
    } else if (highIntensityMinutes7Days >= 90) {
      readiness -= 8;
      injuryRisk += 9;
    } else if (highIntensityMinutes7Days >= 65) {
      readiness -= 4;
      injuryRisk += 5;
    }

    if (zone5Minutes7Days >= 28) {
      readiness -= 10;
      injuryRisk += 14;
    } else if (zone5Minutes7Days >= 18) {
      readiness -= 6;
      injuryRisk += 8;
    }

    if (highIntensityMinutes30Days >= 360) {
      readiness -= 8;
      injuryRisk += 10;
    } else if (highIntensityMinutes30Days >= 280) {
      readiness -= 5;
      injuryRisk += 6;
    }

    readiness = readiness.clamp(0, 100);
    injuryRisk = injuryRisk.clamp(0, 100);

    final shouldReduceLoad =
        readiness < 70 ||
        injuryRisk > 50 ||
        highIntensityRatioToday >= 0.25 ||
        highIntensityMinutes7Days >= 90 ||
        strengthLoadState.neuralStress >= 65 ||
        (latestLog?.recoveryCost ?? 0) >= 65 ||
        (latestLog?.hiddenBodyStress ?? 0) >= 70 ||
        (latestLog?.mechanicalStress ?? 0) >= 65;

    final shouldBlockIntensity =
        readiness < 55 ||
        injuryRisk > 70 ||
        strengthLoadState.neuralStress >= 80 ||
        strengthLoadState.tendonStress >= 80 ||
        (latestLog?.neuralStress ?? 0) >= 75 ||
        (latestLog?.intermittentStress ?? 0) >= 75 ||
        (latestLog?.recoveryCost ?? 0) >= 75 ||
        (latestLog?.mechanicalStress ?? 0) >= 75 ||
        (readiness < 65 && highIntensityRatioToday >= 0.25) ||
        highIntensityMinutes7Days >= 120 ||
        zone5Minutes7Days >= 28;

    final shouldForceRecovery =
        readiness < 40 ||
        injuryRisk > 82 ||
        strengthLoadState.requiresRecovery ||
        (latestLog?.recoveryCost ?? 0) >= 85 ||
        (latestLog?.hiddenBodyStress ?? 0) >= 85 ||
        (latestLog?.neuralStress ?? 0) >= 85 ||
        (latestLog?.tendonStress ?? 0) >= 85 ||
        (readiness < 50 && highIntensityMinutes7Days >= 100);

    final taperRecommended =
        (acwr > 1.4 && readiness < 65) ||
        (highIntensityMinutes7Days >= 90 && readiness < 70) ||
        (highIntensityRatioToday >= 0.30 && readiness < 70) ||
        (latestLog?.recoveryCost ?? 0) >= 70 ||
        (latestLog?.hiddenBodyStress ?? 0) >= 75 ||
        (latestLog?.neuralStress ?? 0) >= 75 ||
        (latestLog?.mechanicalStress ?? 0) >= 75;

    return AthleteDailyState(
      athleteId: athleteId,
      date: DateTime.now(),
      wearable: wearable,
      log: latestLog,
      physiologyProfile: profile,
      strengthLoadState: strengthLoadState,
      readiness: readiness.round(),
      injuryRisk: injuryRisk,
      fatigueStatus: _fatigueStatus(readiness),
      acuteLoad: acuteLoad,
      chronicLoad: chronicLoad,
      acwr: acwr,
      shouldReduceLoad: shouldReduceLoad,
      shouldBlockIntensity: shouldBlockIntensity,
      shouldForceRecovery: shouldForceRecovery,
      taperRecommended: taperRecommended,
      aiSummary: _summary(
        readiness: readiness.round(),
        injuryRisk: injuryRisk,
        acwr: acwr,
        highIntensityRatioToday: highIntensityRatioToday,
        highIntensityMinutes7Days: highIntensityMinutes7Days,
        zone5Minutes7Days: zone5Minutes7Days,
        strengthLoadState: strengthLoadState,
        latestLog: latestLog,
      ),
      aiRecommendation: _recommendation(
        baseRecommendation: prediction.recommendation,
        shouldReduceLoad: shouldReduceLoad,
        shouldBlockIntensity: shouldBlockIntensity,
        shouldForceRecovery: shouldForceRecovery,
        taperRecommended: taperRecommended,
        highIntensityMinutes7Days: highIntensityMinutes7Days,
        highIntensityRatioToday: highIntensityRatioToday,
        latestLog: latestLog,
      ),
    );
  }

  static double _lastGymLoad(List<DailyAthleteLog> logs) {
    if (logs.isEmpty) return 0.0;

    return logs.last.externalLoad;
  }

  static double _lastSkateKm(List<DailyAthleteLog> logs) {
    if (logs.isEmpty) return 0.0;

    return logs.last.performedKm;
  }

  static int _lastMinutes(List<DailyAthleteLog> logs) {
    if (logs.isEmpty) return 0;

    return logs.last.performedMinutes;
  }

  static int _todayHighIntensityMinutes({
    required List<DailyAthleteLog> logs,
    required WearableDailyData? wearable,
  }) {
    if (wearable != null && wearable.totalZoneMinutes > 0) {
      return wearable.highIntensityMinutes;
    }

    if (logs.isEmpty) return 0;

    return logs.last.highIntensityMinutes;
  }

  static double _todayHighIntensityRatio({
    required List<DailyAthleteLog> logs,
    required WearableDailyData? wearable,
  }) {
    if (wearable != null && wearable.totalZoneMinutes > 0) {
      return wearable.highIntensityRatio;
    }

    if (logs.isEmpty) return 0.0;

    return logs.last.highIntensityRatio;
  }

  static int _sumHighIntensityMinutes(List<DailyAthleteLog> logs) {
    return logs.fold<int>(0, (sum, log) => sum + log.highIntensityMinutes);
  }

  static int _sumZone5Minutes(List<DailyAthleteLog> logs) {
    return logs.fold<int>(0, (sum, log) => sum + log.zone5Minutes);
  }

  static String _fatigueStatus(double readiness) {
    if (readiness < 40) return 'red';

    if (readiness < 60) return 'orange';

    if (readiness < 80) return 'yellow';

    return 'green';
  }

  static String _summary({
    required int readiness,
    required double injuryRisk,
    required double acwr,
    required double highIntensityRatioToday,
    required int highIntensityMinutes7Days,
    required int zone5Minutes7Days,
    required StrengthLoadState strengthLoadState,
    required DailyAthleteLog? latestLog,
  }) {
    if ((latestLog?.recoveryCost ?? 0) >= 80) {
      return 'Coste de recuperación alto detectado: ajustar la próxima carga.';
    }

    if ((latestLog?.hiddenBodyStress ?? 0) >= 80) {
      return 'Estrés corporal oculto elevado: el entrenamiento fue más costoso de lo que parece por distancia o pulso.';
    }

    if ((latestLog?.intermittentStress ?? 0) >= 75) {
      return 'Intermitencias y cambios de ritmo con alto coste fisiológico.';
    }

    if ((latestLog?.mechanicalStress ?? 0) >= 75 ||
        (latestLog?.terrainStress ?? 0) >= 75) {
      return 'Estrés mecánico elevado: proteger fuerza pesada, saltos y carga tendinosa.';
    }

    if ((latestLog?.neuralStress ?? 0) >= 75) {
      return 'Alta fatiga neural detectada por intensidad, intermitencias o carga oculta.';
    }

    if (strengthLoadState.hasHighNeuralStress) {
      return 'Alta fatiga neural detectada por carga de fuerza y potencia.';
    }

    if (strengthLoadState.hasHighTendonStress) {
      return 'Estrés tendón elevado. Proteger saltos y pliometría.';
    }

    if (readiness < 40) {
      return 'Fatiga crítica detectada. Recuperación recomendada.';
    }

    if (injuryRisk > 70) {
      return 'Riesgo alto de lesión.';
    }

    if (highIntensityMinutes7Days >= 120) {
      return 'Exceso de alta intensidad acumulada.';
    }

    if (zone5Minutes7Days >= 28) {
      return 'Exceso de Z5 acumulada.';
    }

    if (highIntensityRatioToday >= 0.30) {
      return 'Ratio alto de intensidad Z4/Z5.';
    }

    if (acwr > 1.5) {
      return 'Carga aguda excesiva.';
    }

    if (readiness > 80) {
      return 'Adaptación positiva.';
    }

    return 'Estado fisiológico estable.';
  }

  static String _recommendation({
    required String baseRecommendation,
    required bool shouldReduceLoad,
    required bool shouldBlockIntensity,
    required bool shouldForceRecovery,
    required bool taperRecommended,
    required int highIntensityMinutes7Days,
    required double highIntensityRatioToday,
    required DailyAthleteLog? latestLog,
  }) {
    if (shouldForceRecovery) {
      return 'Priorizar recuperación completa y bloquear fuerza pesada, saltos reactivos, intermitencias fuertes y Z4/Z5.';
    }

    if (shouldBlockIntensity) {
      return 'Bloquear intensidad neural y mantener solo técnica, movilidad, recuperación o carga aeróbica baja.';
    }

    if ((latestLog?.hiddenBodyStress ?? 0) >= 75) {
      return 'Reducir carga: el estrés oculto del entrenamiento fue alto aunque la sesión parezca moderada.';
    }

    if ((latestLog?.mechanicalStress ?? 0) >= 70 ||
        (latestLog?.terrainStress ?? 0) >= 70) {
      return 'Proteger tendones, fuerza pesada y pliometría por estrés mecánico elevado.';
    }

    if ((latestLog?.intermittentStress ?? 0) >= 70) {
      return 'Evitar velocidad máxima y cambios de ritmo fuertes hasta recuperar frescura neural.';
    }

    if (taperRecommended) {
      return 'Reducir volumen y proteger frescura neuromuscular.';
    }

    if (shouldReduceLoad) {
      return 'Reducir carga total y controlar acumulación de estrés.';
    }

    if (highIntensityMinutes7Days >= 65 || highIntensityRatioToday >= 0.20) {
      return '$baseRecommendation Controlar Z4/Z5.';
    }

    return baseRecommendation;
  }
}
