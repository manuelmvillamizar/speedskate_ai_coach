import 'athlete_program_service.dart';
import 'athlete_physiology_profile.dart';
import 'daily_athlete_log.dart';
import 'wearable_integration_service.dart';

import 'physiology/baseline/baseline_models.dart';
import 'physiology/data_quality/data_quality_layer.dart';
import 'physiology/fatigue/fatigue_systems_engine.dart';
import 'physiology/readiness/hybrid_readiness_engine.dart';

class AthletePerformanceContext {
  final AthleteProgramProfile athlete;
  AthletePhysiologyProfile physiologyProfile;
  final List<DailyAthleteLog> dailyLogs;
  WearableDailyData? latestWearableData;

  int currentReadiness;
  String currentFatigueStatus;
  double currentInjuryRisk;

  double readinessTrend;
  double fatigueTrend;
  double adaptationTrend;

  final List<AthleteTrainingWeek> seasonWeeks;

  final DynamicBaseline? dynamicBaseline;
  final DataQualityReport? dataQuality;
  final FatigueSystemsProfile? fatigueSystems;
  final HybridReadinessResult? hybridReadiness;

  AthletePerformanceContext({
    required this.athlete,
    required this.physiologyProfile,
    this.dailyLogs = const [],
    this.latestWearableData,
    this.currentReadiness = 75,
    this.currentFatigueStatus = 'green',
    this.currentInjuryRisk = 10,
    this.readinessTrend = 0,
    this.fatigueTrend = 0,
    this.adaptationTrend = 0,
    this.seasonWeeks = const [],
    this.dynamicBaseline,
    this.dataQuality,
    this.fatigueSystems,
    this.hybridReadiness,
  });

  List<DailyAthleteLog> get sortedLogs {
    final logs = [...dailyLogs];
    logs.sort((a, b) => a.date.compareTo(b.date));
    return logs;
  }

  List<DailyAthleteLog> get last7Days {
    final logs = sortedLogs;
    if (logs.length <= 7) return logs;
    return logs.sublist(logs.length - 7);
  }

  List<DailyAthleteLog> get last30Days {
    final logs = sortedLogs;
    if (logs.length <= 30) return logs;
    return logs.sublist(logs.length - 30);
  }

  double get acuteLoad {
    if (last7Days.isEmpty) return 0.0;

    return last7Days.fold<double>(0.0, (sum, log) => sum + log.internalLoad) /
        last7Days.length;
  }

  double get chronicLoad {
    if (last30Days.isEmpty) return 0.0;

    return last30Days.fold<double>(0.0, (sum, log) => sum + log.internalLoad) /
        last30Days.length;
  }

  double get acwr {
    if (chronicLoad == 0) return 1.0;
    return acuteLoad / chronicLoad;
  }

  double get averageReadiness {
    if (last30Days.isEmpty) return currentReadiness.toDouble();

    return last30Days.fold<double>(0.0, (sum, log) => sum + log.readiness) /
        last30Days.length;
  }

  double get averageInjuryRisk {
    if (last30Days.isEmpty) return currentInjuryRisk;

    return last30Days.fold<double>(0.0, (sum, log) => sum + log.injuryRisk) /
        last30Days.length;
  }

  bool get hasTrustedPhysiology {
    final quality = dataQuality;
    if (quality == null) return false;
    return quality.canAdaptTraining;
  }

  bool get canLearnPhysiology {
    final quality = dataQuality;
    if (quality == null) return false;
    return quality.canLearn;
  }

  bool get hasHighNeuralFatigue {
    final fatigue = fatigueSystems;
    if (fatigue == null) return false;
    return fatigue.neural.score >= 65 && fatigue.neural.confidence >= 0.45;
  }

  bool get hasHighMetabolicFatigue {
    final fatigue = fatigueSystems;
    if (fatigue == null) return false;
    return fatigue.metabolic.score >= 65 &&
        fatigue.metabolic.confidence >= 0.45;
  }

  bool get hasHighTissueStress {
    final fatigue = fatigueSystems;
    if (fatigue == null) return false;
    return fatigue.tissueStress.score >= 60 &&
        fatigue.tissueStress.confidence >= 0.45;
  }

  bool get hasHighCardiovascularFatigue {
    final fatigue = fatigueSystems;
    if (fatigue == null) return false;
    return fatigue.cardiovascular.score >= 65 &&
        fatigue.cardiovascular.confidence >= 0.45;
  }

  bool get hasHighMuscularFatigue {
    final fatigue = fatigueSystems;
    if (fatigue == null) return false;
    return fatigue.muscular.score >= 65 && fatigue.muscular.confidence >= 0.45;
  }

  bool get possibleOvertraining {
    if (hasTrustedPhysiology && fatigueSystems != null) {
      return fatigueSystems!.overallScore >= 75 &&
          currentReadiness < 60 &&
          currentInjuryRisk > 55;
    }

    return acwr > 1.5 && averageReadiness < 60 && averageInjuryRisk > 60;
  }

  bool get needsRecoveryBlock {
    final lowReadinessDays = last7Days
        .where((log) => log.readiness < 60)
        .length;

    if (hasTrustedPhysiology && fatigueSystems != null) {
      return lowReadinessDays >= 3 ||
          fatigueSystems!.overallScore >= 75 ||
          hasHighNeuralFatigue ||
          hasHighTissueStress;
    }

    return lowReadinessDays >= 4;
  }

  bool get positiveTaperResponse {
    if (dynamicBaseline != null && dataQuality?.canAdaptTraining == true) {
      final hrvTrend = dynamicBaseline!.hrv.trendNormalized;
      final sleepTrend = dynamicBaseline!.sleepHours.trendNormalized;
      final stressTrend = dynamicBaseline!.stress.trendNormalized;

      return hrvTrend > 0.04 && sleepTrend >= 0 && stressTrend <= 0.03;
    }

    return readinessTrend > 5 && fatigueTrend < 0;
  }

  bool get positiveAdaptation {
    if (dynamicBaseline != null && dataQuality?.canLearn == true) {
      return dynamicBaseline!.confidence >= 0.65 &&
          dynamicBaseline!.globalTrendNormalized > 0.03 &&
          currentReadiness > 72;
    }

    return adaptationTrend > 5 && averageReadiness > 75;
  }
}
