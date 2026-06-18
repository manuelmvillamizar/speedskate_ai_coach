import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class WeightHistoryEntry {
  final String id;
  final String athleteId;
  final DateTime date;
  final double weightKg;
  final String? note;

  const WeightHistoryEntry({
    required this.id,
    required this.athleteId,
    required this.date,
    required this.weightKg,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'athleteId': athleteId,
      'date': date.toIso8601String(),
      'weightKg': weightKg,
      'note': note,
    };
  }

  factory WeightHistoryEntry.fromJson(Map<String, dynamic> json) {
    return WeightHistoryEntry(
      id: json['id'] as String,
      athleteId: json['athleteId'] as String,
      date: DateTime.parse(json['date'] as String),
      weightKg: (json['weightKg'] as num).toDouble(),
      note: json['note'] as String?,
    );
  }
}

class AthleteWeightSummary {
  final WeightHistoryEntry? latestEntry;
  final double? changeLast4WeeksKg;
  final bool hasRapidChange;
  final String? rapidChangeMessage;

  const AthleteWeightSummary({
    required this.latestEntry,
    required this.changeLast4WeeksKg,
    required this.hasRapidChange,
    required this.rapidChangeMessage,
  });
}

class AthleteWeightHistoryService {
  static const String _storageKey = 'athlete_weight_history_entries_v1';

  static Future<List<WeightHistoryEntry>> getEntriesForAthlete(
    String athleteId,
  ) async {
    final allEntries = await _getAllEntries();

    final entries =
        allEntries.where((entry) => entry.athleteId == athleteId).toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    return entries;
  }

  static Future<WeightHistoryEntry?> getLatestEntry(String athleteId) async {
    final entries = await getEntriesForAthlete(athleteId);
    if (entries.isEmpty) return null;
    return entries.first;
  }

  static Future<WeightHistoryEntry> addEntry({
    required String athleteId,
    required DateTime date,
    required double weightKg,
    String? note,
  }) async {
    final entry = WeightHistoryEntry(
      id: '${athleteId}_${date.millisecondsSinceEpoch}',
      athleteId: athleteId,
      date: DateTime(date.year, date.month, date.day),
      weightKg: weightKg,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
    );

    final entries = await _getAllEntries();

    entries.removeWhere(
      (existing) =>
          existing.athleteId == athleteId && _isSameDay(existing.date, date),
    );

    entries.add(entry);

    await _saveAllEntries(entries);

    return entry;
  }

  static Future<void> deleteEntry(String entryId) async {
    final entries = await _getAllEntries()
      ..removeWhere((entry) => entry.id == entryId);

    await _saveAllEntries(entries);
  }

  static Future<AthleteWeightSummary> getSummary(String athleteId) async {
    final entries = await getEntriesForAthlete(athleteId);

    if (entries.isEmpty) {
      return const AthleteWeightSummary(
        latestEntry: null,
        changeLast4WeeksKg: null,
        hasRapidChange: false,
        rapidChangeMessage: null,
      );
    }

    final latest = entries.first;
    final fourWeeksAgo = latest.date.subtract(const Duration(days: 28));

    final referenceEntries = entries
        .where(
          (entry) =>
              entry.date.isBefore(fourWeeksAgo) ||
              _isSameDay(entry.date, fourWeeksAgo),
        )
        .toList();

    WeightHistoryEntry? referenceEntry;

    if (referenceEntries.isNotEmpty) {
      referenceEntry = referenceEntries.first;
    } else if (entries.length >= 2) {
      referenceEntry = entries.last;
    }

    final change = referenceEntry == null
        ? null
        : latest.weightKg - referenceEntry.weightKg;

    final hasRapidChange = change != null && change.abs() >= 2.0;

    return AthleteWeightSummary(
      latestEntry: latest,
      changeLast4WeeksKg: change,
      hasRapidChange: hasRapidChange,
      rapidChangeMessage: hasRapidChange
          ? _buildRapidChangeMessage(change)
          : null,
    );
  }

  static Future<List<WeightHistoryEntry>> _getAllEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(WeightHistoryEntry.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveAllEntries(List<WeightHistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();

    entries.sort((a, b) => b.date.compareTo(a.date));

    final encoded = jsonEncode(entries.map((entry) => entry.toJson()).toList());

    await prefs.setString(_storageKey, encoded);
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _buildRapidChangeMessage(double changeKg) {
    final direction = changeKg > 0 ? 'subió' : 'bajó';
    final value = changeKg.abs().toStringAsFixed(1);

    return 'Cambio rápido: el peso $direction $value kg en las últimas semanas. Revisar fatiga, disponibilidad y rendimiento.';
  }
}
