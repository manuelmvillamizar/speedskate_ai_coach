import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'adaptive_response_memory.dart';

class AdaptiveResponseMemoryStorageService {
  static String _key(String athleteId) {
    return 'adaptive_response_memory_$athleteId';
  }

  static Future<void> saveMemory(AdaptiveResponseMemory memory) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_key(memory.athleteId), jsonEncode(memory.toMap()));
  }

  static Future<AdaptiveResponseMemory> loadMemory(String athleteId) async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_key(athleteId));

    if (raw == null || raw.trim().isEmpty) {
      return AdaptiveResponseMemory.initial(athleteId);
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is Map<String, dynamic>) {
        return AdaptiveResponseMemory.fromMap(decoded);
      }

      if (decoded is Map) {
        return AdaptiveResponseMemory.fromMap(
          Map<String, dynamic>.from(decoded),
        );
      }

      return AdaptiveResponseMemory.initial(athleteId);
    } catch (_) {
      return AdaptiveResponseMemory.initial(athleteId);
    }
  }

  static Future<void> clearMemory(String athleteId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(athleteId));
  }
}
