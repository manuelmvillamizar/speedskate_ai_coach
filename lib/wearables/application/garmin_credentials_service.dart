import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GarminCredentialsService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static String _credentialsKey(String athleteId) {
    return 'garmin_credentials_$athleteId';
  }

  static Future<bool> hasCredentials(String athleteId) async {
    final raw = await _storage.read(key: _credentialsKey(athleteId));

    if (raw == null || raw.isEmpty) return false;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;

      final email = data['email']?.toString().trim() ?? '';
      final password = data['password']?.toString().trim() ?? '';

      return email.isNotEmpty && password.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<void> saveCredentials({
    required String athleteId,
    required String email,
    required String password,
  }) async {
    final payload = jsonEncode({
      'athleteId': athleteId,
      'email': email.trim(),
      'password': password.trim(),
      'savedAt': DateTime.now().toIso8601String(),
    });

    await _storage.write(key: _credentialsKey(athleteId), value: payload);
  }

  static Future<void> clearCredentials(String athleteId) async {
    await _storage.delete(key: _credentialsKey(athleteId));
  }

  static Future<String?> readEmail(String athleteId) async {
    final raw = await _storage.read(key: _credentialsKey(athleteId));

    if (raw == null || raw.isEmpty) return null;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final email = data['email']?.toString().trim();

      if (email == null || email.isEmpty) return null;

      return email;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> readPassword(String athleteId) async {
    final raw = await _storage.read(key: _credentialsKey(athleteId));

    if (raw == null || raw.isEmpty) return null;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final password = data['password']?.toString().trim();

      if (password == null || password.isEmpty) return null;

      return password;
    } catch (_) {
      return null;
    }
  }
}
