import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GarminCredentialsService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String backendBaseUrl =
      'https://speedskate-ai-coach.onrender.com';

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
    final cleanAthleteId = athleteId.trim();
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    final payload = jsonEncode({
      'athleteId': cleanAthleteId,
      'email': cleanEmail,
      'password': cleanPassword,
      'savedAt': DateTime.now().toIso8601String(),
    });

    await _storage.write(key: _credentialsKey(cleanAthleteId), value: payload);

    await _sendCredentialsToBackend(
      athleteId: cleanAthleteId,
      email: cleanEmail,
      password: cleanPassword,
    );
  }

  static Future<void> _sendCredentialsToBackend({
    required String athleteId,
    required String email,
    required String password,
  }) async {
    final client = HttpClient();

    try {
      final uri = Uri.parse('$backendBaseUrl/garmin/connect');

      final request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      request.write(
        jsonEncode({
          'athleteId': athleteId,
          'email': email,
          'password': password,
        }),
      );

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Backend ${response.statusCode}: $body');
      }
    } finally {
      client.close(force: true);
    }
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
