import 'athlete_physiology_profile.dart';
import 'wearable_integration_service.dart';
import 'physiology/models/strength_load_state.dart';
import 'physiology/data_quality/data_quality_layer.dart';

class PhysiologyLearningEngine {
  static AthletePhysiologyProfile processDailyMetrics({
    required AthletePhysiologyProfile profile,
    required WearableDailyData wearableData,
    required String sessionType,
    required int sessionLoad,
    required int soreness,
    required int readiness,
    StrengthLoadState strengthLoadState = const StrengthLoadState(
      externalStrengthLoadKg: 0,
      reactiveJumpLoadKg: 0,
      totalMechanicalLoadKg: 0,
      neuralStress: 0,
      muscleStress: 0,
      tendonStress: 0,
      adaptationSignal: 'none',
    ),
    DataQualityReport? dataQuality,
  }) {
    final hasRequiredRealData =
        wearableData.hasRealHrv == true &&
        wearableData.hasRealRestingHeartRate == true &&
        wearableData.hasRealSleep == true &&
        wearableData.hasRealStress == true;

    final canLearnFromQuality = dataQuality == null || dataQuality.canLearn;

    if (!hasRequiredRealData || !canLearnFromQuality) {
      return profile;
    }

    profile.updateBaselines(
      hrv: wearableData.hrv.round(),
      restingHeartRate: wearableData.restingHeartRate,
      sleepHours: wearableData.sleepHours,
      stress: wearableData.stress.round(),
    );

    profile.learnFromTrainingResponse(
      sessionType: sessionType,
      readiness: readiness,
      soreness: soreness,
      hrv: wearableData.hrv.round(),
      restingHeartRate: wearableData.restingHeartRate,
    );

    _updateLoadTolerance(
      profile: profile,
      sessionLoad: sessionLoad,
      readiness: readiness,
    );

    _updateStrengthTolerance(
      profile: profile,
      strengthLoadState: strengthLoadState,
      wearableData: wearableData,
      soreness: soreness,
      readiness: readiness,
    );

    _updateRecoveryRate(
      profile: profile,
      wearableData: wearableData,
      readiness: readiness,
    );

    return profile;
  }

  static void _updateLoadTolerance({
    required AthletePhysiologyProfile profile,
    required int sessionLoad,
    required int readiness,
  }) {
    if (readiness >= 80) {
      profile.maxDailyLoad += 1.5;
    }

    if (readiness < 50) {
      profile.maxDailyLoad -= 2;
    }

    if (sessionLoad > profile.maxDailyLoad && readiness < 55) {
      profile.maxWeeklyLoad -= 5;
    }

    profile.maxDailyLoad = profile.maxDailyLoad.clamp(60, 350).toDouble();
    profile.maxWeeklyLoad = profile.maxWeeklyLoad.clamp(300, 2500).toDouble();
  }

  static void _updateStrengthTolerance({
    required AthletePhysiologyProfile profile,
    required StrengthLoadState strengthLoadState,
    required WearableDailyData wearableData,
    required int soreness,
    required int readiness,
  }) {
    if (strengthLoadState.adaptationSignal == 'none') {
      return;
    }

    final hrvDrop = profile.baselineHrv - wearableData.hrv;
    final rhrIncrease =
        wearableData.restingHeartRate - profile.baselineRestingHeartRate;

    final poorResponse =
        readiness < 60 || soreness >= 7 || hrvDrop >= 12 || rhrIncrease >= 6;

    final goodResponse =
        readiness >= 78 && soreness <= 4 && hrvDrop <= 5 && rhrIncrease <= 3;

    if (strengthLoadState.neuralStress >= 65) {
      if (poorResponse) {
        profile.fatigueAccumulationRate += 0.03;
        profile.speedResponse -= 0.015;
      } else if (goodResponse) {
        profile.speedResponse += 0.015;
        profile.recoveryCapability += 0.25;
      }
    }

    if (strengthLoadState.muscleStress >= 65) {
      if (poorResponse) {
        profile.strengthResponse -= 0.015;
        profile.maxGymLoad -= 150;
      } else if (goodResponse) {
        profile.strengthResponse += 0.02;
        profile.maxGymLoad += 120;
        profile.strengthDevelopmentLevel += 0.35;
      }
    }

    if (strengthLoadState.tendonStress >= 65) {
      if (poorResponse) {
        profile.fatigueAccumulationRate += 0.025;
        profile.recoveryCapability -= 0.25;
      } else if (goodResponse) {
        profile.recoveryCapability += 0.15;
      }
    }

    if (strengthLoadState.reactiveJumpLoadKg > 0 && goodResponse) {
      profile.speedDevelopmentLevel += 0.25;
      profile.sprintFinishCapability += 0.20;
    }

    if (strengthLoadState.externalStrengthLoadKg > 0 && goodResponse) {
      profile.strengthDevelopmentLevel += 0.25;
    }

    if (strengthLoadState.requiresRecovery && poorResponse) {
      profile.poorRecoveryBlocks += 1;
    }

    profile.fatigueAccumulationRate = profile.fatigueAccumulationRate
        .clamp(0.6, 2.0)
        .toDouble();

    profile.speedResponse = profile.speedResponse.clamp(0.5, 1.5).toDouble();
    profile.strengthResponse = profile.strengthResponse
        .clamp(0.5, 1.5)
        .toDouble();

    profile.maxGymLoad = profile.maxGymLoad.clamp(4000, 40000).toDouble();

    profile.strengthDevelopmentLevel = profile.strengthDevelopmentLevel
        .clamp(0, 100)
        .toDouble();

    profile.speedDevelopmentLevel = profile.speedDevelopmentLevel
        .clamp(0, 100)
        .toDouble();

    profile.sprintFinishCapability = profile.sprintFinishCapability
        .clamp(0, 100)
        .toDouble();

    profile.recoveryCapability = profile.recoveryCapability
        .clamp(0, 100)
        .toDouble();

    profile.lastUpdated = DateTime.now();
  }

  static void _updateRecoveryRate({
    required AthletePhysiologyProfile profile,
    required WearableDailyData wearableData,
    required int readiness,
  }) {
    double score = 0;

    if (wearableData.sleepHours >= 8) {
      score += 1;
    }

    if (wearableData.hrv >= profile.baselineHrv) {
      score += 1;
    }

    if (wearableData.restingHeartRate <= profile.baselineRestingHeartRate) {
      score += 1;
    }

    if (wearableData.stress <= 35) {
      score += 1;
    }

    if (readiness >= 80) {
      score += 1;
    }

    if (score >= 4) {
      profile.recoveryRate += 0.02;
    } else {
      profile.recoveryRate -= 0.015;
    }

    profile.recoveryRate = profile.recoveryRate.clamp(0.6, 1.8).toDouble();
  }

  static int estimateReadiness({
    required AthletePhysiologyProfile profile,
    required WearableDailyData wearableData,
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
    final hasRequiredRealData =
        wearableData.hasRealHrv == true &&
        wearableData.hasRealRestingHeartRate == true &&
        wearableData.hasRealSleep == true &&
        wearableData.hasRealStress == true;

    if (!hasRequiredRealData) {
      return 70;
    }

    double readiness = 100;

    final hrvDiff = wearableData.hrv - profile.baselineHrv;
    readiness += hrvDiff * 0.6;

    final rhrDiff =
        wearableData.restingHeartRate - profile.baselineRestingHeartRate;
    readiness -= rhrDiff * 1.8;

    if (wearableData.sleepHours < 6) {
      readiness -= 15;
    }

    if (wearableData.sleepHours >= 8) {
      readiness += 5;
    }

    readiness -= wearableData.stress * 0.25;

    readiness -= strengthLoadState.neuralStress * 0.08;
    readiness -= strengthLoadState.tendonStress * 0.07;
    readiness -= strengthLoadState.muscleStress * 0.05;

    switch (profile.recoveryProfile) {
      case RecoveryProfile.fast:
        readiness += 5;
        break;
      case RecoveryProfile.normal:
        break;
      case RecoveryProfile.slow:
        readiness -= 8;
        break;
    }

    return readiness.clamp(0, 100).round();
  }

  static bool detectOverreaching({
    required AthletePhysiologyProfile profile,
    required WearableDailyData wearableData,
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
    final hasRequiredRealData =
        wearableData.hasRealHrv == true &&
        wearableData.hasRealRestingHeartRate == true &&
        wearableData.hasRealSleep == true;

    if (!hasRequiredRealData) {
      return false;
    }

    final hrvDrop = profile.baselineHrv - wearableData.hrv;

    final rhrIncrease =
        wearableData.restingHeartRate - profile.baselineRestingHeartRate;

    if (hrvDrop > 18 && rhrIncrease > 7 && wearableData.sleepHours < 6.5) {
      return true;
    }

    if (strengthLoadState.neuralStress >= 85 &&
        hrvDrop > 10 &&
        rhrIncrease > 5) {
      return true;
    }

    if (strengthLoadState.tendonStress >= 85 && wearableData.soreness >= 7) {
      return true;
    }

    if (profile.accumulatedRedDays >= 3) {
      return true;
    }

    return false;
  }

  static double injuryRisk({
    required AthletePhysiologyProfile profile,
    required WearableDailyData wearableData,
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
    double risk = 0;

    risk += profile.fatigueAccumulationRate * 20;
    risk += profile.accumulatedRedDays * 8;

    risk += strengthLoadState.neuralStress * 0.10;
    risk += strengthLoadState.tendonStress * 0.16;
    risk += strengthLoadState.muscleStress * 0.07;

    if (wearableData.hasRealSleep == true && wearableData.sleepHours < 6) {
      risk += 10;
    }

    if (wearableData.hasRealStress == true && wearableData.stress > 70) {
      risk += 15;
    }

    if (wearableData.hasRealHrv == true &&
        wearableData.hrv < profile.baselineHrv - 15) {
      risk += 20;
    }

    if (wearableData.hasRealSoreness == true && wearableData.soreness >= 7) {
      risk += 15;
    }

    return risk.clamp(0, 100).toDouble();
  }
}
