class FatigueEngine {
  static String calculateStatus({
    required double gymLoad,
    required double skateKm,
    required int minutes,
  }) {
    final score = calculateLoadScore(
      gymLoad: gymLoad,
      skateKm: skateKm,
      minutes: minutes,
    );

    return statusFromScore(score);
  }

  static double calculateLoadScore({
    required double gymLoad,
    required double skateKm,
    required int minutes,
  }) {
    double score = 0;

    score += gymLoad / 1000;
    score += skateKm * 2;
    score += minutes * 0.5;

    return score;
  }

  static String statusFromScore(double score) {
    if (score < 50) return 'green';
    if (score < 90) return 'yellow';
    if (score < 130) return 'orange';
    return 'red';
  }

  static int readinessScore({
    required double gymLoad,
    required double skateKm,
    required int minutes,

    /// 0 means: no real sleep data available.
    int sleepHours = 0,

    /// 0 means: no real stress data available.
    int stress = 0,

    /// 0 means: no real HRV data available.
    int hrv = 0,

    /// 0 means: no real athlete baseline available.
    int normalHrv = 0,

    /// 0 means: no real resting heart rate data available.
    int restingHeartRate = 0,

    /// 0 means: no real resting heart rate baseline available.
    int normalRestingHeartRate = 0,

    /// 0 means: no real soreness data available.
    int soreness = 0,
  }) {
    final loadScore = calculateLoadScore(
      gymLoad: gymLoad,
      skateKm: skateKm,
      minutes: minutes,
    );

    int readiness = 100;

    // Training load is always valid because it comes from planned/logged load.
    readiness -= (loadScore * 0.35).round();

    // Sleep: only evaluate if real sleep exists.
    if (sleepHours > 0) {
      if (sleepHours < 6) readiness -= 15;
      if (sleepHours < 5) readiness -= 10;
    }

    // Stress: only evaluate if real stress exists.
    if (stress > 0) {
      if (stress > 65) readiness -= 12;
      if (stress > 80) readiness -= 10;
    }

    // HRV: only evaluate if both current HRV and baseline are real.
    if (hrv > 0 && normalHrv > 0) {
      if (hrv < normalHrv - 10) readiness -= 12;
      if (hrv < normalHrv - 20) readiness -= 10;
    }

    // Resting HR: only evaluate if both current RHR and baseline are real.
    if (restingHeartRate > 0 && normalRestingHeartRate > 0) {
      final rhrIncrease = restingHeartRate - normalRestingHeartRate;

      if (rhrIncrease >= 7) readiness -= 12;
      if (rhrIncrease >= 12) readiness -= 10;
    }

    // Soreness: only evaluate if real soreness exists.
    if (soreness > 0) {
      if (soreness >= 6) readiness -= 10;
      if (soreness >= 8) readiness -= 12;
    }

    if (readiness < 0) return 0;
    if (readiness > 100) return 100;
    return readiness;
  }

  static String readinessStatus(int readiness) {
    if (readiness >= 80) return 'green';
    if (readiness >= 60) return 'yellow';
    if (readiness >= 40) return 'orange';
    return 'red';
  }

  static bool shouldBlockProgression(String status) {
    return status == 'orange' || status == 'red';
  }

  static bool shouldForceRecovery(String status) {
    return status == 'red';
  }

  static double acuteChronicRatio({
    required double acuteLoad7Days,
    required double chronicLoad28Days,
  }) {
    if (chronicLoad28Days <= 0) return 0;
    return acuteLoad7Days / (chronicLoad28Days / 4);
  }

  static String injuryRiskStatus(double ratio) {
    if (ratio < 0.8) return 'yellow';
    if (ratio <= 1.3) return 'green';
    if (ratio <= 1.5) return 'orange';
    return 'red';
  }

  static String recommendationEs({
    required String status,
    required int readiness,
    required double acuteChronicRatio,
  }) {
    if (status == 'red' || readiness < 40 || acuteChronicRatio > 1.5) {
      return 'Riesgo alto: bloquear progresión, evitar intensidad y priorizar recuperación.';
    }

    if (status == 'orange' || readiness < 60 || acuteChronicRatio > 1.3) {
      return 'Fatiga acumulada: reducir volumen, evitar cargas máximas y mantener técnica.';
    }

    if (status == 'yellow' || readiness < 80) {
      return 'Estado moderado: mantener estímulo, pero sin aumentar carga.';
    }

    return 'Estado óptimo: se permite progresión si la técnica es estable.';
  }

  static String recommendationEn({
    required String status,
    required int readiness,
    required double acuteChronicRatio,
  }) {
    if (status == 'red' || readiness < 40 || acuteChronicRatio > 1.5) {
      return 'High risk: block progression, avoid intensity and prioritize recovery.';
    }

    if (status == 'orange' || readiness < 60 || acuteChronicRatio > 1.3) {
      return 'Accumulated fatigue: reduce volume, avoid maximal loads and maintain technique.';
    }

    if (status == 'yellow' || readiness < 80) {
      return 'Moderate state: keep stimulus, but do not increase load.';
    }

    return 'Optimal state: progression is allowed if technique remains stable.';
  }

  static String recommendationDe({
    required String status,
    required int readiness,
    required double acuteChronicRatio,
  }) {
    if (status == 'red' || readiness < 40 || acuteChronicRatio > 1.5) {
      return 'Hohes Risiko: Progression blockieren, Intensität vermeiden und Regeneration priorisieren.';
    }

    if (status == 'orange' || readiness < 60 || acuteChronicRatio > 1.3) {
      return 'Kumulierte Ermüdung: Volumen reduzieren, Maximallasten vermeiden und Technik erhalten.';
    }

    if (status == 'yellow' || readiness < 80) {
      return 'Moderater Zustand: Reiz beibehalten, aber Belastung nicht erhöhen.';
    }

    return 'Optimaler Zustand: Progression ist erlaubt, wenn die Technik stabil bleibt.';
  }
}
