import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'athlete_daily_state.dart';
import 'integrated_training_day.dart';
import 'training_intervention_engine.dart';

class DailyPipelineSnapshot {
  final String athleteId;
  final DateTime date;
  final DateTime createdAt;
  final IntegratedTrainingDay trainingDay;
  final AthleteDailyState dailyState;
  final TrainingInterventionResult intervention;

  const DailyPipelineSnapshot({
    required this.athleteId,
    required this.date,
    required this.createdAt,
    required this.trainingDay,
    required this.dailyState,
    required this.intervention,
  });

  Map<String, dynamic> toMap() {
    return {
      'athleteId': athleteId,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'trainingDay': trainingDay.toMap(),
      'dailyState': dailyState.toMap(),
      'intervention': intervention.toMap(),
    };
  }

  factory DailyPipelineSnapshot.fromMap(Map<String, dynamic> map) {
    return DailyPipelineSnapshot(
      athleteId: map['athleteId']?.toString() ?? '',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      trainingDay: IntegratedTrainingDay.fromMap(
        Map<String, dynamic>.from(map['trainingDay'] ?? {}),
      ),
      dailyState: AthleteDailyState.fromMap(
        Map<String, dynamic>.from(map['dailyState'] ?? {}),
      ),
      intervention: TrainingInterventionResult.fromMap(
        Map<String, dynamic>.from(map['intervention'] ?? {}),
      ),
    );
  }
}

class DailyPipelineCacheService {
  static const String _storagePrefix = 'speedskate_daily_pipeline_cache_v1';

  static Future<void> saveSnapshot({
    required String athleteId,
    required DateTime date,
    required IntegratedTrainingDay trainingDay,
    required AthleteDailyState dailyState,
    required TrainingInterventionResult intervention,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final snapshot = DailyPipelineSnapshot(
      athleteId: athleteId,
      date: _cleanDate(date),
      createdAt: DateTime.now(),
      trainingDay: trainingDay,
      dailyState: dailyState,
      intervention: intervention,
    );

    await prefs.setString(_key(athleteId, date), jsonEncode(snapshot.toMap()));
  }

  static Future<DailyPipelineSnapshot?> loadSnapshot({
    required String athleteId,
    required DateTime date,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(athleteId, date));

      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);

      if (decoded is! Map) return null;

      final snapshot = DailyPipelineSnapshot.fromMap(
        Map<String, dynamic>.from(decoded),
      );

      if (snapshot.athleteId != athleteId) return null;
      if (!_isSameDay(snapshot.date, date)) return null;

      return snapshot;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> hasSnapshot({
    required String athleteId,
    required DateTime date,
  }) async {
    final snapshot = await loadSnapshot(athleteId: athleteId, date: date);

    return snapshot != null;
  }

  static Future<void> clearSnapshot({
    required String athleteId,
    required DateTime date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(athleteId, date));
  }

  static Future<void> clearAllForAthlete(String athleteId) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    final prefix = '$_storagePrefix:$athleteId:';

    for (final key in keys) {
      if (key.startsWith(prefix)) {
        await prefs.remove(key);
      }
    }
  }

  static String _key(String athleteId, DateTime date) {
    final clean = _cleanDate(date);
    final year = clean.year.toString().padLeft(4, '0');
    final month = clean.month.toString().padLeft(2, '0');
    final day = clean.day.toString().padLeft(2, '0');

    return '$_storagePrefix:$athleteId:$year-$month-$day';
  }

  static DateTime _cleanDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
