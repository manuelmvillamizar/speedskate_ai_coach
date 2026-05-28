class PerformancePrediction {
  final double readinessScore;
  final double injuryRisk;
  final double performanceScore;
  final double recoveryScore;

  final String readinessStatus;
  final String recommendation;

  const PerformancePrediction({
    required this.readinessScore,
    required this.injuryRisk,
    required this.performanceScore,
    required this.recoveryScore,
    required this.readinessStatus,
    required this.recommendation,
  });
}

class AIPerformancePredictor {
  static PerformancePrediction predict({
    required int hrv,
    required int sleepMinutes,
    required int restingHeartRate,
    required int stress,
    required int soreness,
    required double acuteLoad,
    required double chronicLoad,
    required double gymLoad,
    required double skateKm,
    required int trainingMinutes,

    required double baselineHrv,
    required int baselineRestingHeartRate,
    required double averageSleepHours,
    required int averageStress,
    required double maxDailyLoad,
    required double maxGymLoad,
    required double maxSkatingKm,
    required double fatigueAccumulationRate,
    required double recoveryRate,
  }) {
    double readiness = 100;

    final sleepHours = sleepMinutes / 60.0;

    final safeBaselineHrv = baselineHrv <= 0 ? 55.0 : baselineHrv;
    final safeAverageSleep = averageSleepHours <= 0 ? 7.5 : averageSleepHours;
    final safeMaxDailyLoad = maxDailyLoad <= 0 ? 180.0 : maxDailyLoad;
    final safeMaxGymLoad = maxGymLoad <= 0 ? 16000.0 : maxGymLoad;
    final safeMaxSkatingKm = maxSkatingKm <= 0 ? 40.0 : maxSkatingKm;

    // =========================
    // HRV RELATIVA AL ATLETA
    // =========================

    final hrvDropPercent = (safeBaselineHrv - hrv) / safeBaselineHrv;

    if (hrvDropPercent <= -0.08) {
      readiness += 5;
    } else if (hrvDropPercent >= 0.25) {
      readiness -= 22;
    } else if (hrvDropPercent >= 0.15) {
      readiness -= 14;
    } else if (hrvDropPercent >= 0.08) {
      readiness -= 7;
    }

    // =========================
    // SUE�'O RELATIVO AL ATLETA
    // =========================

    final sleepDeficit = safeAverageSleep - sleepHours;

    if (sleepDeficit <= -0.5) {
      readiness += 4;
    } else if (sleepDeficit >= 2.0) {
      readiness -= 22;
    } else if (sleepDeficit >= 1.0) {
      readiness -= 14;
    } else if (sleepDeficit >= 0.5) {
      readiness -= 7;
    }

    // =========================
    // FC REPOSO RELATIVA AL ATLETA
    // =========================

    final restingHeartRateIncrease =
        restingHeartRate - baselineRestingHeartRate;

    if (restingHeartRateIncrease >= 10) {
      readiness -= 20;
    } else if (restingHeartRateIncrease >= 7) {
      readiness -= 14;
    } else if (restingHeartRateIncrease >= 4) {
      readiness -= 8;
    } else if (restingHeartRateIncrease <= -4) {
      readiness += 4;
    }

    // =========================
    // ESTR�?S RELATIVO AL ATLETA
    // =========================

    final stressIncrease = stress - averageStress;

    if (stressIncrease >= 25) {
      readiness -= 14;
    } else if (stressIncrease >= 15) {
      readiness -= 9;
    } else if (stressIncrease >= 8) {
      readiness -= 5;
    }

    readiness -= stress * 0.12;

    // =========================
    // SORENESS
    // =========================

    readiness -= soreness * 3.2;

    // =========================
    // ACWR
    // =========================

    double acwr = 1.0;

    if (chronicLoad > 0) {
      acwr = acuteLoad / chronicLoad;
    }

    double injuryRisk = 12;

    if (acwr > 1.8) {
      injuryRisk += 35;
      readiness -= 18;
    } else if (acwr > 1.5) {
      injuryRisk += 25;
      readiness -= 12;
    } else if (acwr > 1.3) {
      injuryRisk += 12;
      readiness -= 6;
    }

    if (acwr < 0.65 && chronicLoad > 0) {
      readiness -= 5;
    }

    // =========================
    // CARGA DIARIA VS TOLERANCIA INDIVIDUAL
    // =========================

    final dailyLoadRatio = acuteLoad / safeMaxDailyLoad;

    if (dailyLoadRatio > 1.15) {
      readiness -= 14;
      injuryRisk += 18;
    } else if (dailyLoadRatio > 1.0) {
      readiness -= 8;
      injuryRisk += 10;
    }

    // =========================
    // GYM VS TOLERANCIA INDIVIDUAL
    // =========================

    final gymRatio = gymLoad / safeMaxGymLoad;

    if (gymRatio > 1.2) {
      readiness -= 12;
      injuryRisk += 12;
    } else if (gymRatio > 1.0) {
      readiness -= 7;
      injuryRisk += 7;
    }

    // =========================
    // SKATING KM VS TOLERANCIA INDIVIDUAL
    // =========================

    final skatingRatio = skateKm / safeMaxSkatingKm;

    if (skatingRatio > 1.2) {
      readiness -= 12;
      injuryRisk += 12;
    } else if (skatingRatio > 1.0) {
      readiness -= 7;
      injuryRisk += 7;
    }

    // =========================
    // MINUTOS
    // =========================

    if (trainingMinutes > 180) {
      readiness -= 16;
      injuryRisk += 10;
    } else if (trainingMinutes > 150) {
      readiness -= 10;
      injuryRisk += 6;
    } else if (trainingMinutes > 120) {
      readiness -= 5;
    }

    // =========================
    // SENSIBILIDAD / RECUPERACI�"N INDIVIDUAL
    // =========================

    final fatiguePenalty = (fatigueAccumulationRate - 1.0) * 18.0;
    readiness -= fatiguePenalty;

    final recoveryBonus = (recoveryRate - 1.0) * 10.0;
    readiness += recoveryBonus;

    // =========================
    // RECOVERY SCORE
    // =========================

    double recovery = 100;

    recovery -= soreness * 4;
    recovery -= stress * 0.25;
    recovery -= hrvDropPercent.clamp(0.0, 1.0) * 30;
    recovery -= restingHeartRateIncrease.clamp(0, 20) * 1.4;
    recovery += recoveryBonus;

    recovery = recovery.clamp(0, 100);

    // =========================
    // LIMITES
    // =========================

    readiness = readiness.clamp(0, 100);
    injuryRisk = injuryRisk.clamp(0, 100);

    // =========================
    // PERFORMANCE
    // =========================

    double performance =
        (readiness * 0.55) + (recovery * 0.25) + ((100 - injuryRisk) * 0.20);

    performance = performance.clamp(0, 100);

    // =========================
    // STATUS
    // =========================

    String status = 'green';

    if (readiness < 80) {
      status = 'yellow';
    }

    if (readiness < 60) {
      status = 'orange';
    }

    if (readiness < 40) {
      status = 'red';
    }

    // =========================
    // RECOMMENDATION
    // =========================

    String recommendation =
        'Estado favorable. Mantener el estímulo planificado.';

    if (status == 'yellow') {
      recommendation =
          'Señales leves de carga interna. Mantener calidad, sin aumentar volumen.';
    }

    if (status == 'orange') {
      recommendation =
          'Fatiga acumulada. Evitar intensidad máxima y reducir volumen.';
    }

    if (status == 'red') {
      recommendation =
          'Riesgo alto de sobrecarga. Priorizar recuperación y bloquear intensidad.';
    }

    return PerformancePrediction(
      readinessScore: readiness,
      injuryRisk: injuryRisk,
      performanceScore: performance,
      recoveryScore: recovery,
      readinessStatus: status,
      recommendation: recommendation,
    );
  }
}


