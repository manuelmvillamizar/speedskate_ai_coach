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
    return log.toMap();
  }

  static DailyAthleteLog _decode(Map<String, dynamic> json) {
    return DailyAthleteLog.fromMap(json);
  }
}
