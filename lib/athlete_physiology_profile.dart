enum FatigueSensitivity { low, moderate, high }

enum RecoveryProfile { fast, normal, slow }

class AthletePhysiologyProfile {
  final String athleteId;

  double baselineHrv;
  int baselineRestingHeartRate;
  double averageSleepHours;
  int averageStress;

  double fatigueAccumulationRate;
  double recoveryRate;

  double strengthResponse;
  double enduranceResponse;
  double speedResponse;
  double competitionResponse;

  double maxWeeklyLoad;
  double maxDailyLoad;
  double maxGymLoad;
  double maxSkatingKm;

  double adaptationScore;
  double readinessTrend;

  FatigueSensitivity fatigueSensitivity;
  RecoveryProfile recoveryProfile;

  int accumulatedHighFatigueDays;
  int accumulatedRedDays;
  int successfulTapers;
  int poorRecoveryBlocks;

  double strengthDevelopmentLevel;
  double speedDevelopmentLevel;
  double enduranceDevelopmentLevel;
  double technicalDevelopmentLevel;
  double tacticalDevelopmentLevel;
  double sprintFinishCapability;
  double raceConsistency;
  double recoveryCapability;
  double worldClassPotentialScore;

  int totalTrainingDaysLearned;
  int totalSessionsLearned;
  int totalCompetitionsLearned;

  DateTime lastUpdated;

  AthletePhysiologyProfile({
    required this.athleteId,
    this.baselineHrv = 55,
    this.baselineRestingHeartRate = 52,
    this.averageSleepHours = 7.5,
    this.averageStress = 40,
    this.fatigueAccumulationRate = 1.0,
    this.recoveryRate = 1.0,
    this.strengthResponse = 1.0,
    this.enduranceResponse = 1.0,
    this.speedResponse = 1.0,
    this.competitionResponse = 1.0,
    this.maxWeeklyLoad = 1000,
    this.maxDailyLoad = 180,
    this.maxGymLoad = 16000,
    this.maxSkatingKm = 40,
    this.adaptationScore = 50,
    this.readinessTrend = 0,
    this.fatigueSensitivity = FatigueSensitivity.moderate,
    this.recoveryProfile = RecoveryProfile.normal,
    this.accumulatedHighFatigueDays = 0,
    this.accumulatedRedDays = 0,
    this.successfulTapers = 0,
    this.poorRecoveryBlocks = 0,
    this.strengthDevelopmentLevel = 40,
    this.speedDevelopmentLevel = 40,
    this.enduranceDevelopmentLevel = 40,
    this.technicalDevelopmentLevel = 40,
    this.tacticalDevelopmentLevel = 40,
    this.sprintFinishCapability = 40,
    this.raceConsistency = 40,
    this.recoveryCapability = 40,
    this.worldClassPotentialScore = 35,
    this.totalTrainingDaysLearned = 0,
    this.totalSessionsLearned = 0,
    this.totalCompetitionsLearned = 0,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  void updateBaselines({
    required int hrv,
    required int restingHeartRate,
    required double sleepHours,
    required int stress,
  }) {
    baselineHrv = ((baselineHrv * 0.9) + (hrv * 0.1));
    baselineRestingHeartRate =
        ((baselineRestingHeartRate * 0.9) + (restingHeartRate * 0.1)).round();
    averageSleepHours = ((averageSleepHours * 0.9) + (sleepHours * 0.1));
    averageStress = ((averageStress * 0.9) + (stress * 0.1)).round();

    lastUpdated = DateTime.now();
  }

  void learnFromTrainingResponse({
    required String sessionType,
    required int readiness,
    required int soreness,
    required int hrv,
    required int restingHeartRate,
  }) {
    totalTrainingDaysLearned++;
    totalSessionsLearned++;

    final hrvDrop = baselineHrv - hrv;
    final rhrIncrease = restingHeartRate - baselineRestingHeartRate;

    double fatigueImpact = 0;
    fatigueImpact += hrvDrop * 0.5;
    fatigueImpact += rhrIncrease * 1.5;
    fatigueImpact += soreness * 2;

    if (fatigueImpact > 25) {
      fatigueAccumulationRate += 0.02;
    } else {
      fatigueAccumulationRate -= 0.01;
    }

    fatigueAccumulationRate = fatigueAccumulationRate.clamp(0.6, 2.0);

    if (readiness < 50) {
      poorRecoveryBlocks++;
    }

    if (poorRecoveryBlocks > 6) {
      recoveryProfile = RecoveryProfile.slow;
      recoveryCapability = (recoveryCapability - 0.4).clamp(0, 100);
    }

    if (poorRecoveryBlocks < 2 && readiness > 75) {
      recoveryProfile = RecoveryProfile.fast;
      recoveryCapability = (recoveryCapability + 0.3).clamp(0, 100);
    }

    if (sessionType == 'strength') {
      strengthResponse =
          ((strengthResponse * 0.95) + ((100 - fatigueImpact) / 100) * 0.05)
              .clamp(0.5, 1.5);
      strengthDevelopmentLevel =
          (strengthDevelopmentLevel + _developmentGain(readiness)).clamp(
            0,
            100,
          );
    }

    if (sessionType == 'endurance') {
      enduranceResponse =
          ((enduranceResponse * 0.95) + ((100 - fatigueImpact) / 100) * 0.05)
              .clamp(0.5, 1.5);
      enduranceDevelopmentLevel =
          (enduranceDevelopmentLevel + _developmentGain(readiness)).clamp(
            0,
            100,
          );
    }

    if (sessionType == 'speed') {
      speedResponse =
          ((speedResponse * 0.95) + ((100 - fatigueImpact) / 100) * 0.05).clamp(
            0.5,
            1.5,
          );
      speedDevelopmentLevel =
          (speedDevelopmentLevel + _developmentGain(readiness)).clamp(0, 100);
      sprintFinishCapability =
          (sprintFinishCapability + _developmentGain(readiness) * 0.8).clamp(
            0,
            100,
          );
    }

    if (sessionType == 'competition') {
      competitionResponse =
          ((competitionResponse * 0.95) + ((100 - fatigueImpact) / 100) * 0.05)
              .clamp(0.5, 1.5);
      totalCompetitionsLearned++;
      raceConsistency = (raceConsistency + _developmentGain(readiness) * 0.8)
          .clamp(0, 100);
      tacticalDevelopmentLevel =
          (tacticalDevelopmentLevel + _developmentGain(readiness) * 0.6).clamp(
            0,
            100,
          );
    }

    if (sessionType == 'technical') {
      technicalDevelopmentLevel =
          (technicalDevelopmentLevel + _developmentGain(readiness)).clamp(
            0,
            100,
          );
    }

    if (readiness < 60) {
      accumulatedHighFatigueDays++;
    }

    if (readiness < 40) {
      accumulatedRedDays++;
    }

    if (readiness > 75) {
      accumulatedHighFatigueDays = (accumulatedHighFatigueDays - 1).clamp(
        0,
        999,
      );
    }

    if (readiness > 85) {
      accumulatedRedDays = (accumulatedRedDays - 1).clamp(0, 999);
    }

    adaptationScore = ((adaptationScore * 0.95) + readiness * 0.05).clamp(
      0,
      100,
    );

    readinessTrend = ((readinessTrend * 0.8) + readiness * 0.2);

    _updateWorldClassPotential();

    lastUpdated = DateTime.now();
  }

  double _developmentGain(int readiness) {
    if (readiness >= 85) return 0.45;
    if (readiness >= 75) return 0.30;
    if (readiness >= 65) return 0.18;
    if (readiness >= 55) return 0.08;
    return 0.0;
  }

  void _updateWorldClassPotential() {
    worldClassPotentialScore =
        (strengthDevelopmentLevel * 0.16 +
                speedDevelopmentLevel * 0.18 +
                enduranceDevelopmentLevel * 0.16 +
                technicalDevelopmentLevel * 0.14 +
                tacticalDevelopmentLevel * 0.10 +
                sprintFinishCapability * 0.12 +
                raceConsistency * 0.08 +
                recoveryCapability * 0.06)
            .clamp(0, 100);
  }

  bool shouldReduceLoad() {
    return accumulatedRedDays >= 2 || fatigueAccumulationRate > 1.4;
  }

  bool shouldBlockIntensity() {
    return accumulatedRedDays >= 3;
  }

  bool needsRecoveryMicrocycle() {
    return accumulatedHighFatigueDays >= 5;
  }

  bool isHighResponderToSpeed() {
    return speedResponse > 1.15;
  }

  bool isSensitiveToStrength() {
    return strengthResponse < 0.85;
  }
}


