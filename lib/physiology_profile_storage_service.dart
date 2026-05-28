import 'package:hive_flutter/hive_flutter.dart';

import 'athlete_physiology_profile.dart';

class PhysiologyProfileStorageService {
  static const String _boxName = 'speedskate_physiology_profiles_v3';

  static Future<Box> _box() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }

    return Hive.box(_boxName);
  }

  static Future<void> initialize() async {
    await _box();
  }

  static Future<void> saveProfile(AthletePhysiologyProfile profile) async {
    final box = await _box();

    await box.put(profile.athleteId, {
      'athleteId': profile.athleteId,
      'baselineHrv': profile.baselineHrv,
      'baselineRestingHeartRate': profile.baselineRestingHeartRate,
      'averageSleepHours': profile.averageSleepHours,
      'averageStress': profile.averageStress,
      'fatigueAccumulationRate': profile.fatigueAccumulationRate,
      'recoveryRate': profile.recoveryRate,
      'strengthResponse': profile.strengthResponse,
      'enduranceResponse': profile.enduranceResponse,
      'speedResponse': profile.speedResponse,
      'competitionResponse': profile.competitionResponse,
      'maxWeeklyLoad': profile.maxWeeklyLoad,
      'maxDailyLoad': profile.maxDailyLoad,
      'maxGymLoad': profile.maxGymLoad,
      'maxSkatingKm': profile.maxSkatingKm,
      'adaptationScore': profile.adaptationScore,
      'readinessTrend': profile.readinessTrend,
      'fatigueSensitivity': profile.fatigueSensitivity.name,
      'recoveryProfile': profile.recoveryProfile.name,
      'accumulatedHighFatigueDays': profile.accumulatedHighFatigueDays,
      'accumulatedRedDays': profile.accumulatedRedDays,
      'successfulTapers': profile.successfulTapers,
      'poorRecoveryBlocks': profile.poorRecoveryBlocks,
      'strengthDevelopmentLevel': profile.strengthDevelopmentLevel,
      'speedDevelopmentLevel': profile.speedDevelopmentLevel,
      'enduranceDevelopmentLevel': profile.enduranceDevelopmentLevel,
      'technicalDevelopmentLevel': profile.technicalDevelopmentLevel,
      'tacticalDevelopmentLevel': profile.tacticalDevelopmentLevel,
      'sprintFinishCapability': profile.sprintFinishCapability,
      'raceConsistency': profile.raceConsistency,
      'recoveryCapability': profile.recoveryCapability,
      'worldClassPotentialScore': profile.worldClassPotentialScore,
      'totalTrainingDaysLearned': profile.totalTrainingDaysLearned,
      'totalSessionsLearned': profile.totalSessionsLearned,
      'totalCompetitionsLearned': profile.totalCompetitionsLearned,
      'lastUpdated': profile.lastUpdated.toIso8601String(),
    });
  }

  static Future<AthletePhysiologyProfile?> loadProfile(String athleteId) async {
    final box = await _box();

    final raw = box.get(athleteId);

    if (raw == null) {
      return null;
    }

    final map = Map<String, dynamic>.from(raw);

    return AthletePhysiologyProfile(
      athleteId: map['athleteId'],
      baselineHrv: (map['baselineHrv'] ?? 55).toDouble(),
      baselineRestingHeartRate: map['baselineRestingHeartRate'] ?? 52,
      averageSleepHours: (map['averageSleepHours'] ?? 7.5).toDouble(),
      averageStress: map['averageStress'] ?? 40,
      fatigueAccumulationRate: (map['fatigueAccumulationRate'] ?? 1.0)
          .toDouble(),
      recoveryRate: (map['recoveryRate'] ?? 1.0).toDouble(),
      strengthResponse: (map['strengthResponse'] ?? 1.0).toDouble(),
      enduranceResponse: (map['enduranceResponse'] ?? 1.0).toDouble(),
      speedResponse: (map['speedResponse'] ?? 1.0).toDouble(),
      competitionResponse: (map['competitionResponse'] ?? 1.0).toDouble(),
      maxWeeklyLoad: (map['maxWeeklyLoad'] ?? 1000).toDouble(),
      maxDailyLoad: (map['maxDailyLoad'] ?? 180).toDouble(),
      maxGymLoad: (map['maxGymLoad'] ?? 16000).toDouble(),
      maxSkatingKm: (map['maxSkatingKm'] ?? 40).toDouble(),
      adaptationScore: (map['adaptationScore'] ?? 50).toDouble(),
      readinessTrend: (map['readinessTrend'] ?? 0).toDouble(),
      fatigueSensitivity: _fatigueSensitivityFromString(
        map['fatigueSensitivity'] ?? 'moderate',
      ),
      recoveryProfile: _recoveryProfileFromString(
        map['recoveryProfile'] ?? 'normal',
      ),
      accumulatedHighFatigueDays: map['accumulatedHighFatigueDays'] ?? 0,
      accumulatedRedDays: map['accumulatedRedDays'] ?? 0,
      successfulTapers: map['successfulTapers'] ?? 0,
      poorRecoveryBlocks: map['poorRecoveryBlocks'] ?? 0,
      strengthDevelopmentLevel: (map['strengthDevelopmentLevel'] ?? 40)
          .toDouble(),
      speedDevelopmentLevel: (map['speedDevelopmentLevel'] ?? 40).toDouble(),
      enduranceDevelopmentLevel: (map['enduranceDevelopmentLevel'] ?? 40)
          .toDouble(),
      technicalDevelopmentLevel: (map['technicalDevelopmentLevel'] ?? 40)
          .toDouble(),
      tacticalDevelopmentLevel: (map['tacticalDevelopmentLevel'] ?? 40)
          .toDouble(),
      sprintFinishCapability: (map['sprintFinishCapability'] ?? 40).toDouble(),
      raceConsistency: (map['raceConsistency'] ?? 40).toDouble(),
      recoveryCapability: (map['recoveryCapability'] ?? 40).toDouble(),
      worldClassPotentialScore: (map['worldClassPotentialScore'] ?? 35)
          .toDouble(),
      totalTrainingDaysLearned: map['totalTrainingDaysLearned'] ?? 0,
      totalSessionsLearned: map['totalSessionsLearned'] ?? 0,
      totalCompetitionsLearned: map['totalCompetitionsLearned'] ?? 0,
      lastUpdated:
          DateTime.tryParse(map['lastUpdated'] ?? '') ?? DateTime.now(),
    );
  }

  static FatigueSensitivity _fatigueSensitivityFromString(String value) {
    return FatigueSensitivity.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FatigueSensitivity.moderate,
    );
  }

  static RecoveryProfile _recoveryProfileFromString(String value) {
    return RecoveryProfile.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RecoveryProfile.normal,
    );
  }
}


