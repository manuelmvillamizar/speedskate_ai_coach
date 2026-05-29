// lib/garmin_backend_api_service.dart

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;

import 'wearable_integration_service.dart';

class GarminSyncResult {
  final bool success;
  final String message;
  final WearableDailyData? wearableData;
  final List<Map<String, dynamic>>? activities;

  GarminSyncResult({
    required this.success,
    required this.message,
    this.wearableData,
    this.activities,
  });
}

class GarminBackendApiService {
  // Cambia solo esta línea si cambia la IP de tu PC.
  static String developmentIp = '192.168.1.121';

  static String get _baseUrl {
    return 'https://speedskate-ai-coach.onrender.com';
  }

  static Future<GarminSyncResult> syncGarmin({
    required String athleteId,
    Function(String)? onProgress,
  }) async {
    try {
      onProgress?.call('Conectando con backend...');

      final url = Uri.parse('$_baseUrl/garmin/normalized?athleteId=$athleteId');

      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 180));

      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(jsonDecode(response.body));

        onProgress?.call('Datos recibidos del backend');

        final wearableData = _parseWearableData(data);

        return GarminSyncResult(
          success: wearableData != null,
          message: data['message']?.toString() ?? 'Sincronización completada',
          wearableData: wearableData,
          activities: List<Map<String, dynamic>>.from(data['sessions'] ?? []),
        );
      }

      return GarminSyncResult(
        success: false,
        message: 'Error del backend: ${response.statusCode}',
      );
    } catch (e) {
      return GarminSyncResult(
        success: false,
        message: 'No se pudo conectar con el backend: $e',
      );
    }
  }

  static WearableDailyData? _parseWearableData(Map<String, dynamic> data) {
    final rawSummary = data['summary'];

    if (rawSummary is! Map) {
      return null;
    }

    final summary = Map<String, dynamic>.from(rawSummary);

    final hrv = _intFromAny(
      summary['hrv'] ??
          summary['hrv_rmssd'] ??
          summary['hrv_rmssd_ms'] ??
          summary['last_night_hrv'] ??
          summary['nightly_hrv'],
    );

    final stats = Map<String, dynamic>.from(data['stats'] ?? {});

    final sleepData = Map<String, dynamic>.from(data['sleep_data'] ?? {});
    final dailySleep = Map<String, dynamic>.from(
      sleepData['dailySleepDTO'] ?? {},
    );

    final stressData = Map<String, dynamic>.from(data['stress_data'] ?? {});

    final sleepMinutes = _sleepMinutesFromSummary(summary) > 0
        ? _sleepMinutesFromSummary(summary)
        : (_intFromAny(dailySleep['sleepTimeSeconds']) / 60).round();

    final restingHeartRate = _intFromAny(
      summary['resting_hr'] ??
          summary['restingHeartRate'] ??
          summary['resting_heart_rate'] ??
          stats['restingHeartRate'],
    );

    final stress = _intFromAny(
      summary['avg_stress'] ??
          summary['stress'] ??
          summary['average_stress'] ??
          stressData['avgStressLevel'],
    );

    final bodyBattery = _intFromAny(
      summary['body_battery_current'] ??
          summary['bodyBattery'] ??
          summary['body_battery'] ??
          stats['bodyBatteryMostRecentValue'],
    );

    final steps = _intFromAny(
      summary['steps'] ??
          summary['totalSteps'] ??
          summary['total_steps'] ??
          stats['totalSteps'],
    );
    final activeCalories = _intFromAny(
      summary['active_calories'] ??
          summary['activeCalories'] ??
          summary['calories'] ??
          summary['totalCalories'],
    );

    final trainingLoad = _doubleFromAny(
      summary['total_internal_load'] ??
          summary['trainingLoad'] ??
          summary['training_load'],
    );

    final sessions = _sessionsFromData(data);
    final zones = _zonesFromSessions(sessions);

    final totalTrainingMinutes = _totalTrainingMinutesFromSessions(sessions);
    final totalDistanceKm = _totalDistanceKmFromSessions(sessions);

    final averageHeartRate = _averageHeartRateFromSessions(sessions);
    final maxHeartRate = _maxHeartRateFromSessions(sessions);

    final hasRealHrv = hrv > 0;
    final hasRealSleep = sleepMinutes > 0;
    final hasRealStress = stress > 0;
    final hasRealRestingHeartRate = restingHeartRate > 0;
    final hasRealBodyBattery = bodyBattery > 0;
    final hasRealSteps = steps > 0;
    final hasRealCalories = activeCalories > 0;
    final hasRealTrainingLoad = trainingLoad > 0;
    final hasRealZones = zones.total > 0;
    final hasRealHeartRate = averageHeartRate > 0 || maxHeartRate > 0;

    return WearableDailyData(
      date: DateTime.tryParse(data['date']?.toString() ?? '') ?? DateTime.now(),
      sleepMinutes: sleepMinutes,
      hrv: hrv,
      restingHeartRate: restingHeartRate,
      stress: stress,
      soreness: 0,
      activeCalories: activeCalories,
      steps: steps,
      trainingLoad: trainingLoad,
      bodyBattery: bodyBattery,
      zone1Minutes: zones.zone1,
      zone2Minutes: zones.zone2,
      zone3Minutes: zones.zone3,
      zone4Minutes: zones.zone4,
      zone5Minutes: zones.zone5,
      averageHeartRate: averageHeartRate,
      maxHeartRate: maxHeartRate,
      rpe: 0,
      totalTrainingMinutes: totalTrainingMinutes,
      totalDistanceKm: totalDistanceKm,
      source: 'garmin_backend_normalized',
      hasRealDailyHealth:
          hasRealHrv ||
          hasRealSleep ||
          hasRealStress ||
          hasRealRestingHeartRate ||
          hasRealBodyBattery ||
          hasRealSteps,
      hasImportedTraining:
          hasRealTrainingLoad ||
          hasRealZones ||
          totalTrainingMinutes > 0 ||
          totalDistanceKm > 0,
      hasRealHrv: hasRealHrv,
      hasRealSleep: hasRealSleep,
      hasRealStress: hasRealStress,
      hasRealRestingHeartRate: hasRealRestingHeartRate,
      hasRealSoreness: false,
      hasRealCalories: hasRealCalories,
      hasRealSteps: hasRealSteps,
      hasRealBodyBattery: hasRealBodyBattery,
      hasRealZones: hasRealZones,
      hasRealHeartRate: hasRealHeartRate,
      hasRealTrainingLoad: hasRealTrainingLoad,
    );
  }

  static List<Map<String, dynamic>> _sessionsFromData(
    Map<String, dynamic> data,
  ) {
    final raw = data['sessions'] ?? data['activities'];

    if (raw is! List) {
      return [];
    }

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static int _sleepMinutesFromSummary(Map<String, dynamic> summary) {
    final directMinutes = _intFromAny(
      summary['sleep_minutes'] ??
          summary['sleepMinutes'] ??
          summary['total_sleep_minutes'],
    );

    if (directMinutes > 0) {
      return directMinutes;
    }

    final hours = _doubleFromAny(
      summary['sleep_hours'] ??
          summary['sleepHours'] ??
          summary['total_sleep_hours'],
    );

    if (hours > 0) {
      return (hours * 60).round();
    }

    final seconds = _intFromAny(
      summary['sleep_seconds'] ??
          summary['sleepSeconds'] ??
          summary['total_sleep_seconds'],
    );

    if (seconds > 0) {
      return (seconds / 60).round();
    }

    return 0;
  }

  static _GarminZones _zonesFromSessions(List<Map<String, dynamic>> sessions) {
    var zone1 = 0;
    var zone2 = 0;
    var zone3 = 0;
    var zone4 = 0;
    var zone5 = 0;

    for (final session in sessions) {
      zone1 += _zoneFromSession(session, 1);
      zone2 += _zoneFromSession(session, 2);
      zone3 += _zoneFromSession(session, 3);
      zone4 += _zoneFromSession(session, 4);
      zone5 += _zoneFromSession(session, 5);
    }

    return _GarminZones(
      zone1: zone1,
      zone2: zone2,
      zone3: zone3,
      zone4: zone4,
      zone5: zone5,
    );
  }

  static int _zoneFromSession(Map<String, dynamic> session, int zone) {
    final direct = _intFromAny(
      session['zone${zone}Minutes'] ??
          session['zone_$zone'] ??
          session['z$zone'],
    );

    if (direct > 0) {
      return direct;
    }

    final zones = session['zones'];

    if (zones is Map) {
      final zoneMap = Map<String, dynamic>.from(zones);

      return _intFromAny(
        zoneMap['zone$zone'] ??
            zoneMap['zone_$zone'] ??
            zoneMap['z$zone'] ??
            zoneMap['$zone'],
      );
    }

    return 0;
  }

  static int _totalTrainingMinutesFromSessions(
    List<Map<String, dynamic>> sessions,
  ) {
    var total = 0;

    for (final session in sessions) {
      total += _intFromAny(
        session['duration_minutes'] ??
            session['durationMinutes'] ??
            session['moving_duration_minutes'] ??
            session['elapsed_minutes'],
      );

      final seconds = _intFromAny(
        session['duration_seconds'] ??
            session['durationSeconds'] ??
            session['movingDurationSeconds'],
      );

      if (seconds > 0) {
        total += (seconds / 60).round();
      }
    }

    return total;
  }

  static double _totalDistanceKmFromSessions(
    List<Map<String, dynamic>> sessions,
  ) {
    var total = 0.0;

    for (final session in sessions) {
      final km = _doubleFromAny(
        session['distance_km'] ??
            session['distanceKm'] ??
            session['totalDistanceKm'],
      );

      if (km > 0) {
        total += km;
        continue;
      }

      final meters = _doubleFromAny(
        session['distance_meters'] ??
            session['distanceMeters'] ??
            session['distance'],
      );

      if (meters > 0) {
        total += meters / 1000.0;
      }
    }

    return total;
  }

  static int _averageHeartRateFromSessions(
    List<Map<String, dynamic>> sessions,
  ) {
    final values = <int>[];

    for (final session in sessions) {
      final value = _intFromAny(
        session['average_hr'] ??
            session['averageHeartRate'] ??
            session['avg_hr'] ??
            session['avgHeartRate'],
      );

      if (value > 0) {
        values.add(value);
      }
    }

    if (values.isEmpty) {
      return 0;
    }

    final total = values.fold<int>(0, (sum, value) => sum + value);
    return (total / values.length).round();
  }

  static int _maxHeartRateFromSessions(List<Map<String, dynamic>> sessions) {
    var maxValue = 0;

    for (final session in sessions) {
      final value = _intFromAny(
        session['max_hr'] ??
            session['maxHeartRate'] ??
            session['maximum_hr'] ??
            session['maximumHeartRate'],
      );

      if (value > maxValue) {
        maxValue = value;
      }
    }

    return maxValue;
  }

  static int _intFromAny(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.round();
    }

    if (value is num) {
      return value.round();
    }

    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.round() ?? 0;
    }

    return 0;
  }

  static double _doubleFromAny(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }

    return 0.0;
  }
}

class _GarminZones {
  final int zone1;
  final int zone2;
  final int zone3;
  final int zone4;
  final int zone5;

  const _GarminZones({
    required this.zone1,
    required this.zone2,
    required this.zone3,
    required this.zone4,
    required this.zone5,
  });

  int get total => zone1 + zone2 + zone3 + zone4 + zone5;
}
