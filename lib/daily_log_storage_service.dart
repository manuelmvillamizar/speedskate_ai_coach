import 'package:hive/hive.dart';

import 'daily_athlete_log.dart';

class DailyLogStorageService {
  static const String _boxName = 'daily_logs';

  static Future<void> saveLog(DailyAthleteLog log) async {
    final box = await Hive.openBox(_boxName);

    final existing = await loadLogs(log.athleteId);

    existing.removeWhere((item) {
      return item.date.year == log.date.year &&
          item.date.month == log.date.month &&
          item.date.day == log.date.day;
    });

    existing.add(log);
    existing.sort((a, b) => a.date.compareTo(b.date));

    await box.put(log.athleteId, existing.map(_encode).toList());
  }

  static Future<List<DailyAthleteLog>> loadLogs(String athleteId) async {
    final box = await Hive.openBox(_boxName);

    final raw = box.get(athleteId);

    if (raw == null) return [];

    final list = List<dynamic>.from(raw);

    return list
        .map((item) => _decode(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  static Map<String, dynamic> _encode(DailyAthleteLog log) {
    return {
      'athleteId': log.athleteId,
      'date': log.date.toIso8601String(),

      'plannedSessionType': log.plannedSessionType,
      'plannedLoad': log.plannedLoad,
      'plannedMinutes': log.plannedMinutes,
      'plannedKm': log.plannedKm,

      'performedSessionType': log.performedSessionType,
      'performedLoad': log.performedLoad,
      'performedMinutes': log.performedMinutes,
      'performedKm': log.performedKm,

      'completedAsPlanned': log.completedAsPlanned,

      'hrv': log.hrv,
      'restingHeartRate': log.restingHeartRate,
      'sleepHours': log.sleepHours,
      'stressLevel': log.stressLevel,
      'averageHeartRate': log.averageHeartRate,
      'maxHeartRate': log.maxHeartRate,

      'rpe': log.rpe,
      'soreness': log.soreness,
      'motivation': log.motivation,
      'readiness': log.readiness,

      'overloadDetected': log.overloadDetected,
      'recoveryRecommended': log.recoveryRecommended,
      'injuryRisk': log.injuryRisk,

      'aiDecision': log.aiDecision,
      'aiNotes': log.aiNotes,

      'internalLoad': log.internalLoad,
      'externalLoad': log.externalLoad,

      'zone1Minutes': log.zone1Minutes,
      'zone2Minutes': log.zone2Minutes,
      'zone3Minutes': log.zone3Minutes,
      'zone4Minutes': log.zone4Minutes,
      'zone5Minutes': log.zone5Minutes,
    };
  }

  static DailyAthleteLog _decode(Map<String, dynamic> json) {
    return DailyAthleteLog(
      athleteId: json['athleteId'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),

      plannedSessionType: json['plannedSessionType'] ?? '',
      plannedLoad: (json['plannedLoad'] as num?)?.round() ?? 0,
      plannedMinutes: (json['plannedMinutes'] as num?)?.round() ?? 0,
      plannedKm: (json['plannedKm'] as num?)?.toDouble() ?? 0.0,

      performedSessionType: json['performedSessionType'] ?? '',
      performedLoad: (json['performedLoad'] as num?)?.round() ?? 0,
      performedMinutes: (json['performedMinutes'] as num?)?.round() ?? 0,
      performedKm: (json['performedKm'] as num?)?.toDouble() ?? 0.0,

      completedAsPlanned: json['completedAsPlanned'] ?? false,

      hrv: (json['hrv'] as num?)?.toDouble() ?? 55.0,
      restingHeartRate: (json['restingHeartRate'] as num?)?.round() ?? 52,
      sleepHours: (json['sleepHours'] as num?)?.toDouble() ?? 7.5,
      stressLevel: (json['stressLevel'] as num?)?.toDouble() ?? 40.0,
      averageHeartRate: (json['averageHeartRate'] as num?)?.round() ?? 0,
      maxHeartRate: (json['maxHeartRate'] as num?)?.round() ?? 0,

      rpe: (json['rpe'] as num?)?.round() ?? 0,
      soreness: (json['soreness'] as num?)?.round() ?? 3,
      motivation: (json['motivation'] as num?)?.round() ?? 5,
      readiness: (json['readiness'] as num?)?.round() ?? 75,

      overloadDetected: json['overloadDetected'] ?? false,
      recoveryRecommended: json['recoveryRecommended'] ?? false,
      injuryRisk: (json['injuryRisk'] as num?)?.toDouble() ?? 10.0,

      aiDecision: json['aiDecision'] ?? '',
      aiNotes: json['aiNotes'] ?? '',

      internalLoad: (json['internalLoad'] as num?)?.toDouble() ?? 0.0,
      externalLoad: (json['externalLoad'] as num?)?.toDouble() ?? 0.0,

      zone1Minutes: (json['zone1Minutes'] as num?)?.round() ?? 0,
      zone2Minutes: (json['zone2Minutes'] as num?)?.round() ?? 0,
      zone3Minutes: (json['zone3Minutes'] as num?)?.round() ?? 0,
      zone4Minutes: (json['zone4Minutes'] as num?)?.round() ?? 0,
      zone5Minutes: (json['zone5Minutes'] as num?)?.round() ?? 0,
    );
  }
}


