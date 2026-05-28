import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'daily_training_assignment.dart';
import 'integrated_training_day.dart';

class DailyTrainingAssignmentService extends ChangeNotifier {
  static const String _storageKey = 'speedskate_daily_assignments_v1';

  final Map<String, List<DailyTrainingAssignment>> _assignmentsByAthlete = {};

  bool _loaded = false;

  bool get loaded => _loaded;

  DailyTrainingAssignmentService() {
    loadPersistedAssignments();
  }

  List<DailyTrainingAssignment> assignmentsForAthlete(String athleteId) {
    return List.unmodifiable(_assignmentsByAthlete[athleteId] ?? []);
  }

  DailyTrainingAssignment? todayAssignmentForAthlete(String athleteId) {
    final today = DateTime.now();

    final assignments = _assignmentsByAthlete[athleteId] ?? [];

    for (final assignment in assignments.reversed) {
      final sameDay =
          assignment.date.year == today.year &&
          assignment.date.month == today.month &&
          assignment.date.day == today.day;

      if (sameDay) return assignment;
    }

    return null;
  }

  Future<void> saveDraft({
    required String athleteId,
    required IntegratedTrainingDay day,
  }) async {
    final assignment = DailyTrainingAssignment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      athleteId: athleteId,
      date: day.date,
      trainingDay: day,
      createdAt: DateTime.now(),
      status: DailyTrainingAssignmentStatus.draft,
    );

    _assignmentsByAthlete.putIfAbsent(athleteId, () => []);

    _assignmentsByAthlete[athleteId]!.removeWhere((existing) {
      return existing.date.year == day.date.year &&
          existing.date.month == day.date.month &&
          existing.date.day == day.date.day;
    });

    _assignmentsByAthlete[athleteId]!.add(assignment);

    await _persist();

    notifyListeners();
  }

  Future<void> sendToday(String athleteId) async {
    final assignments = _assignmentsByAthlete[athleteId];

    if (assignments == null || assignments.isEmpty) {
      return;
    }

    final today = todayAssignmentForAthlete(athleteId);

    if (today == null) return;

    final index = assignments.indexWhere((item) => item.id == today.id);

    if (index == -1) return;

    assignments[index] = today.copyWith(
      sentAt: DateTime.now(),
      status: DailyTrainingAssignmentStatus.sent,
    );

    await _persist();

    notifyListeners();
  }

  Future<void> loadPersistedAssignments() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final raw = prefs.getString(_storageKey);

      if (raw == null || raw.isEmpty) {
        _loaded = true;
        notifyListeners();
        return;
      }

      final decoded = jsonDecode(raw);

      final map = Map<String, dynamic>.from(decoded);

      _assignmentsByAthlete.clear();

      map.forEach((athleteId, value) {
        final list = List<dynamic>.from(value);

        _assignmentsByAthlete[athleteId] = list
            .map(
              (item) => DailyTrainingAssignment.fromMap(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      });

      _loaded = true;

      notifyListeners();
    } catch (_) {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    _assignmentsByAthlete.clear();

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_storageKey);

    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();

    final map = <String, dynamic>{};

    _assignmentsByAthlete.forEach((athleteId, assignments) {
      map[athleteId] = assignments.map((item) => item.toMap()).toList();
    });

    await prefs.setString(_storageKey, jsonEncode(map));
  }
}


