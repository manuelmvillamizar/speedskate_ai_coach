import 'dart:convert';
import 'dart:io';

import 'wearable_integration_service.dart';

enum GarminConnectionState {
  notConfigured,
  needsAuthorization,
  connected,
  failed,
}

class GarminConnectionResult {
  final GarminConnectionState state;
  final String message;
  final DateTime updatedAt;
  final String? authorizationUrl;

  const GarminConnectionResult({
    required this.state,
    required this.message,
    required this.updatedAt,
    this.authorizationUrl,
  });

  bool get isConnected => state == GarminConnectionState.connected;
}

class GarminConnectionService {
  static const bool garminApiConfigured = false;

  // Cuando tengas backend real:
  // static const bool garminApiConfigured = true;
  // static const String backendBaseUrl = 'https://tu-backend.com';
  static const String backendBaseUrl = '';

  static Future<GarminConnectionResult> connect({
    required String athleteId,
  }) async {
    if (!garminApiConfigured || backendBaseUrl.isEmpty) {
      return GarminConnectionResult(
        state: GarminConnectionState.notConfigured,
        message:
            'Garmin está preparado. Falta configurar backend, credenciales Garmin Health API y autorización del atleta.',
        updatedAt: DateTime.now(),
      );
    }

    try {
      final uri = Uri.parse(
        '$backendBaseUrl/garmin/connect?athleteId=$athleteId',
      );

      final response = await _getJson(uri);

      final connected = response['connected'] == true;
      final authorizationUrl = response['authorizationUrl']?.toString();

      if (connected) {
        return GarminConnectionResult(
          state: GarminConnectionState.connected,
          message: response['message']?.toString() ?? 'Garmin conectado.',
          updatedAt: DateTime.now(),
        );
      }

      return GarminConnectionResult(
        state: GarminConnectionState.needsAuthorization,
        message:
            response['message']?.toString() ??
            'El atleta debe autorizar la app desde Garmin Connect.',
        updatedAt: DateTime.now(),
        authorizationUrl: authorizationUrl,
      );
    } catch (error) {
      return GarminConnectionResult(
        state: GarminConnectionState.failed,
        message: 'No se pudo conectar con Garmin: $error',
        updatedAt: DateTime.now(),
      );
    }
  }

  static Future<WearableDailyData?> fetchToday({
    required String athleteId,
  }) async {
    if (!garminApiConfigured || backendBaseUrl.isEmpty) {
      return null;
    }

    final now = DateTime.now();
    final date =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    final uri = Uri.parse(
      '$backendBaseUrl/garmin/daily?athleteId=$athleteId&date=$date',
    );

    final json = await _getJson(uri);

    return fromGarminDailySummary(athleteId: athleteId, json: json);
  }

  static Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final client = HttpClient();

    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response = await request.close();

      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}: $body');
      }

      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      throw Exception('Respuesta Garmin inválida.');
    } finally {
      client.close(force: true);
    }
  }

  static WearableDailyData fromGarminDailySummary({
    required String athleteId,
    required Map<String, dynamic> json,
  }) {
    final now = DateTime.now();

    final daily = _mapFromAny(json['dailySummary']) ?? json;
    final sleep = _mapFromAny(json['sleep']) ?? {};
    final stressDetails = _mapFromAny(json['stressDetails']) ?? {};
    final bodyBatteryDetails = _mapFromAny(json['bodyBattery']) ?? {};
    final training = _mapFromAny(json['training']) ?? {};
    final activity = _mapFromAny(json['activity']) ?? {};
    final zones = _extractZones(
      json: json,
      daily: daily,
      training: training,
      activity: activity,
    );

    return WearableDailyData(
      date:
          _dateFromJson(
            daily['date'] ??
                daily['calendarDate'] ??
                json['date'] ??
                json['calendarDate'],
          ) ??
          DateTime(now.year, now.month, now.day),
      hrv:
          _intFromJson(
            daily['hrv'] ??
                daily['hrvAverage'] ??
                daily['lastNightAvgHrv'] ??
                json['hrv'],
          ) ??
          55,
      restingHeartRate:
          _intFromJson(
            daily['restingHeartRate'] ??
                daily['restingHR'] ??
                daily['minHeartRate'] ??
                json['restingHeartRate'],
          ) ??
          52,
      sleepHours:
          _sleepHoursFromJson(
            sleep['sleepSeconds'] ??
                sleep['durationInSeconds'] ??
                sleep['totalSleepSeconds'] ??
                daily['sleepSeconds'] ??
                json['sleepHours'],
          ) ??
          7.5,
      stress:
          _intFromJson(
            stressDetails['averageStressLevel'] ??
                daily['averageStressLevel'] ??
                daily['stress'] ??
                json['stress'],
          ) ??
          40,
      soreness: _intFromJson(json['soreness']) ?? 3,
      trainingLoad:
          _doubleFromJson(
            training['trainingLoad'] ??
                training['load'] ??
                activity['trainingLoad'] ??
                daily['trainingLoad'] ??
                daily['activityTrainingLoad'] ??
                json['trainingLoad'],
          ) ??
          0,
      calories:
          _intFromJson(
            daily['activeKilocalories'] ??
                daily['totalKilocalories'] ??
                activity['activeKilocalories'] ??
                activity['calories'] ??
                json['calories'],
          ) ??
          0,
      steps: _intFromJson(daily['steps'] ?? json['steps']) ?? 0,
      bodyBattery:
          _intFromJson(
            bodyBatteryDetails['bodyBatteryMostRecentValue'] ??
                bodyBatteryDetails['mostRecentValue'] ??
                daily['bodyBattery'] ??
                json['bodyBattery'],
          ) ??
          50,
      zone1Minutes: zones.zone1,
      zone2Minutes: zones.zone2,
      zone3Minutes: zones.zone3,
      zone4Minutes: zones.zone4,
      zone5Minutes: zones.zone5,
    );
  }

  static _GarminZones _extractZones({
    required Map<String, dynamic> json,
    required Map<String, dynamic> daily,
    required Map<String, dynamic> training,
    required Map<String, dynamic> activity,
  }) {
    final direct = _GarminZones(
      zone1:
          _minutesFromAny(
            json['zone1Minutes'] ??
                json['z1Minutes'] ??
                daily['zone1Minutes'] ??
                training['zone1Minutes'] ??
                activity['zone1Minutes'],
          ) ??
          0,
      zone2:
          _minutesFromAny(
            json['zone2Minutes'] ??
                json['z2Minutes'] ??
                daily['zone2Minutes'] ??
                training['zone2Minutes'] ??
                activity['zone2Minutes'],
          ) ??
          0,
      zone3:
          _minutesFromAny(
            json['zone3Minutes'] ??
                json['z3Minutes'] ??
                daily['zone3Minutes'] ??
                training['zone3Minutes'] ??
                activity['zone3Minutes'],
          ) ??
          0,
      zone4:
          _minutesFromAny(
            json['zone4Minutes'] ??
                json['z4Minutes'] ??
                daily['zone4Minutes'] ??
                training['zone4Minutes'] ??
                activity['zone4Minutes'],
          ) ??
          0,
      zone5:
          _minutesFromAny(
            json['zone5Minutes'] ??
                json['z5Minutes'] ??
                daily['zone5Minutes'] ??
                training['zone5Minutes'] ??
                activity['zone5Minutes'],
          ) ??
          0,
    );

    if (direct.total > 0) return direct;

    final fromTimeInZone =
        _zonesFromMap(json['timeInZone']) ??
        _zonesFromMap(json['zones']) ??
        _zonesFromMap(daily['timeInZone']) ??
        _zonesFromMap(daily['zones']) ??
        _zonesFromMap(training['timeInZone']) ??
        _zonesFromMap(training['zones']) ??
        _zonesFromMap(activity['timeInZone']) ??
        _zonesFromMap(activity['zones']);

    if (fromTimeInZone != null && fromTimeInZone.total > 0) {
      return fromTimeInZone;
    }

    final activities = json['activities'];
    if (activities is List) {
      var total = const _GarminZones();

      for (final item in activities) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);

          final zones = _extractZones(
            json: map,
            daily: map,
            training: _mapFromAny(map['training']) ?? {},
            activity: _mapFromAny(map['activity']) ?? map,
          );

          total = total.add(zones);
        }
      }

      if (total.total > 0) return total;
    }

    return const _GarminZones();
  }

  static _GarminZones? _zonesFromMap(dynamic value) {
    if (value == null) return null;

    if (value is List) {
      return _zonesFromList(value);
    }

    if (value is! Map) return null;

    final map = Map<String, dynamic>.from(value);

    return _GarminZones(
      zone1:
          _minutesFromAny(
            map['zone1'] ?? map['z1'] ?? map['1'] ?? map['zone1Minutes'],
          ) ??
          0,
      zone2:
          _minutesFromAny(
            map['zone2'] ?? map['z2'] ?? map['2'] ?? map['zone2Minutes'],
          ) ??
          0,
      zone3:
          _minutesFromAny(
            map['zone3'] ?? map['z3'] ?? map['3'] ?? map['zone3Minutes'],
          ) ??
          0,
      zone4:
          _minutesFromAny(
            map['zone4'] ?? map['z4'] ?? map['4'] ?? map['zone4Minutes'],
          ) ??
          0,
      zone5:
          _minutesFromAny(
            map['zone5'] ?? map['z5'] ?? map['5'] ?? map['zone5Minutes'],
          ) ??
          0,
    );
  }

  static _GarminZones _zonesFromList(List<dynamic> list) {
    var z1 = 0;
    var z2 = 0;
    var z3 = 0;
    var z4 = 0;
    var z5 = 0;

    for (final item in list) {
      if (item is! Map) continue;

      final map = Map<String, dynamic>.from(item);
      final zoneNumber =
          _intFromJson(map['zone']) ??
          _intFromJson(map['zoneNumber']) ??
          _intFromJson(map['hrZone']);

      final minutes =
          _minutesFromAny(
            map['minutes'] ??
                map['durationMinutes'] ??
                map['seconds'] ??
                map['durationSeconds'] ??
                map['timeInSeconds'],
          ) ??
          0;

      switch (zoneNumber) {
        case 1:
          z1 += minutes;
          break;
        case 2:
          z2 += minutes;
          break;
        case 3:
          z3 += minutes;
          break;
        case 4:
          z4 += minutes;
          break;
        case 5:
          z5 += minutes;
          break;
      }
    }

    return _GarminZones(zone1: z1, zone2: z2, zone3: z3, zone4: z4, zone5: z5);
  }

  static int? _minutesFromAny(dynamic value) {
    if (value == null) return null;

    if (value is int) {
      if (value > 300) return (value / 60).round();
      return value;
    }

    if (value is double) {
      if (value > 300) return (value / 60).round();
      return value.round();
    }

    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed == null) return null;
      if (parsed > 300) return (parsed / 60).round();
      return parsed.round();
    }

    return null;
  }

  static Map<String, dynamic>? _mapFromAny(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static int? _intFromJson(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _doubleFromJson(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static double? _sleepHoursFromJson(dynamic value) {
    if (value == null) return null;

    if (value is double) {
      if (value > 24) return value / 3600.0;
      return value;
    }

    if (value is int) {
      if (value > 24) return value / 3600.0;
      return value.toDouble();
    }

    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed == null) return null;
      if (parsed > 24) return parsed / 3600.0;
      return parsed;
    }

    return null;
  }

  static DateTime? _dateFromJson(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

class _GarminZones {
  final int zone1;
  final int zone2;
  final int zone3;
  final int zone4;
  final int zone5;

  const _GarminZones({
    this.zone1 = 0,
    this.zone2 = 0,
    this.zone3 = 0,
    this.zone4 = 0,
    this.zone5 = 0,
  });

  int get total => zone1 + zone2 + zone3 + zone4 + zone5;

  _GarminZones add(_GarminZones other) {
    return _GarminZones(
      zone1: zone1 + other.zone1,
      zone2: zone2 + other.zone2,
      zone3: zone3 + other.zone3,
      zone4: zone4 + other.zone4,
      zone5: zone5 + other.zone5,
    );
  }
}


