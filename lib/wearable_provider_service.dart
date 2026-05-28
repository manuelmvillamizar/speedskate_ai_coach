import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'garmin_connection_service.dart';
import 'wearable_integration_service.dart';
import 'wearables/application/garmin_daily_summary_mapper.dart';
import 'wearables/application/garmin_data_fusion_mapper.dart';
import 'wearables/application/garmin_training_bridge.dart';

enum WearableProviderType { demo, manual, garmin, polar, appleHealth }

enum WearableConnectionStatus {
  disconnected,
  connecting,
  connected,
  failed,
  permissionDenied,
}

class WearableProviderConnection {
  final WearableProviderType provider;
  final WearableConnectionStatus status;
  final String message;
  final DateTime updatedAt;
  final String? authorizationUrl;
  final String athleteId;

  const WearableProviderConnection({
    required this.provider,
    required this.status,
    required this.message,
    required this.updatedAt,
    this.authorizationUrl,
    required this.athleteId,
  });

  bool get isConnected => status == WearableConnectionStatus.connected;

  Map<String, dynamic> toMap() {
    return {
      'provider': provider.name,
      'status': status.name,
      'message': message,
      'updatedAt': updatedAt.toIso8601String(),
      'authorizationUrl': authorizationUrl,
      'athleteId': athleteId,
    };
  }

  factory WearableProviderConnection.fromMap(Map<String, dynamic> map) {
    return WearableProviderConnection(
      provider: WearableProviderType.values.firstWhere(
        (e) => e.name == map['provider'],
        orElse: () => WearableProviderType.demo,
      ),
      status: WearableConnectionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => WearableConnectionStatus.disconnected,
      ),
      message: map['message'] ?? '',
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
      authorizationUrl: map['authorizationUrl']?.toString(),
      athleteId: map['athleteId']?.toString() ?? '',
    );
  }
}

class WearableProviderService {
  static String _providerKey(String athleteId) =>
      'speedskate_provider_$athleteId';

  static String _connectionKey(String athleteId) =>
      'speedskate_connection_$athleteId';

  static Future<WearableProviderConnection> connect(
    WearableProviderType provider, {
    String? athleteId,
  }) async {
    late final WearableProviderConnection connection;

    switch (provider) {
      case WearableProviderType.demo:
        connection = WearableProviderConnection(
          athleteId: athleteId ?? 'active-athlete',
          provider: provider,
          status: WearableConnectionStatus.connected,
          message: 'Modo demo conectado.',
          updatedAt: DateTime.now(),
        );
        break;

      case WearableProviderType.manual:
        connection = WearableProviderConnection(
          athleteId: athleteId ?? 'active-athlete',
          provider: provider,
          status: WearableConnectionStatus.connected,
          message: 'Entrada manual habilitada.',
          updatedAt: DateTime.now(),
        );
        break;

      case WearableProviderType.garmin:
        final garmin = await GarminConnectionService.connect(
          athleteId: athleteId ?? 'active-athlete',
        );

        connection = WearableProviderConnection(
          athleteId: athleteId ?? 'active-athlete',
          provider: provider,
          status: _statusFromGarmin(garmin.state),
          message: garmin.message,
          updatedAt: garmin.updatedAt,
          authorizationUrl: garmin.authorizationUrl,
        );
        break;

      case WearableProviderType.polar:
        connection = WearableProviderConnection(
          athleteId: athleteId ?? 'active-athlete',
          provider: provider,
          status: WearableConnectionStatus.disconnected,
          message: 'Polar requiere Polar AccessLink API y backend.',
          updatedAt: DateTime.now(),
        );
        break;

      case WearableProviderType.appleHealth:
        connection = WearableProviderConnection(
          athleteId: athleteId ?? 'active-athlete',
          provider: provider,
          status: WearableConnectionStatus.disconnected,
          message: 'Apple Watch requiere HealthKit.',
          updatedAt: DateTime.now(),
        );
        break;
    }

    await saveProvider(
      athleteId: athleteId ?? 'active-athlete',
      provider: provider,
    );
    await saveConnection(connection);

    return connection;
  }

  static WearableConnectionStatus _statusFromGarmin(
    GarminConnectionState state,
  ) {
    switch (state) {
      case GarminConnectionState.connected:
        return WearableConnectionStatus.connected;

      case GarminConnectionState.needsAuthorization:
        return WearableConnectionStatus.permissionDenied;

      case GarminConnectionState.failed:
        return WearableConnectionStatus.failed;

      case GarminConnectionState.notConfigured:
        return WearableConnectionStatus.disconnected;
    }
  }

  static Future<void> saveProvider({
    required String athleteId,
    required WearableProviderType provider,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_providerKey(athleteId), provider.name);
  }

  static Future<WearableProviderType?> loadSavedProvider({
    required String athleteId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_providerKey(athleteId));

    if (raw == null) return null;

    return WearableProviderType.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => WearableProviderType.demo,
    );
  }

  static Future<void> saveConnection(
    WearableProviderConnection connection,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _connectionKey(connection.athleteId),
      jsonEncode(connection.toMap()),
    );
  }

  static Future<WearableProviderConnection?> loadConnection({
    required String athleteId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_connectionKey(athleteId));

    if (raw == null || raw.isEmpty) {
      return null;
    }

    final map = jsonDecode(raw);

    return WearableProviderConnection.fromMap(Map<String, dynamic>.from(map));
  }

  static Future<void> clearConnection({required String athleteId}) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_providerKey(athleteId));

    await prefs.remove(_connectionKey(athleteId));
  }

  static Future<WearableDailyData?> fetchToday({
    required WearableProviderType provider,
    required String athleteId,
  }) async {
    switch (provider) {
      case WearableProviderType.demo:
        return demoData(athleteId: athleteId);

      case WearableProviderType.manual:
        return null;

      case WearableProviderType.garmin:
        final imported = await GarminTrainingBridge.loadLatestTraining(
          athleteId: athleteId,
        );

        final latestTraining = imported.hasTraining ? imported.training : null;

        final dailySummaryWearable = GarminDailySummaryMapper.toWearableData(
          dailySummary: imported.dailySummary,
          fallbackDate: latestTraining?.startTime,
        );

        return GarminDataFusionMapper.fuse(
          dailySummary: dailySummaryWearable,
          latestTraining: latestTraining,
        );

      case WearableProviderType.polar:
        return null;

      case WearableProviderType.appleHealth:
        return null;
    }
  }

  static WearableDailyData demoData({required String athleteId}) {
    final now = DateTime.now();

    return WearableDailyData(
      date: DateTime(now.year, now.month, now.day),
      hrv: 58,
      restingHeartRate: 51,
      sleepMinutes: 456,
      stress: 35,
      soreness: 3,
      trainingLoad: 72,
      activeCalories: 2450,
      steps: 8400,
      bodyBattery: 74,
      zone1Minutes: 18,
      zone2Minutes: 28,
      zone3Minutes: 16,
      zone4Minutes: 8,
      zone5Minutes: 2,
      source: 'demo',
      hasRealDailyHealth: false,
      hasImportedTraining: false,
      hasRealHrv: false,
      hasRealSleep: false,
      hasRealStress: false,
      hasRealRestingHeartRate: false,
      hasRealSoreness: false,
      hasRealCalories: false,
      hasRealSteps: false,
      hasRealBodyBattery: false,
      hasRealZones: false,
      hasRealHeartRate: false,
      hasRealTrainingLoad: false,
    );
  }

  static WearableDailyData fromGarminJson({
    required String athleteId,
    required Map<String, dynamic> json,
  }) {
    return GarminConnectionService.fromGarminDailySummary(
      athleteId: athleteId,
      json: json,
    );
  }

  static WearableDailyData fromPolarJson({
    required String athleteId,
    required Map<String, dynamic> json,
  }) {
    final now = DateTime.now();

    final hrv = _intFromJson(json['hrv']) ?? 0;

    final restingHeartRate = _intFromJson(json['restingHeartRate']) ?? 0;

    final sleepHours = _doubleFromJson(json['sleepHours']) ?? 0;

    final stress = _intFromJson(json['stress']) ?? 0;

    final soreness = _intFromJson(json['soreness']) ?? 0;

    final trainingLoad = _doubleFromJson(json['trainingLoad']) ?? 0;

    final calories = _intFromJson(json['calories']) ?? 0;

    final steps = _intFromJson(json['steps']) ?? 0;

    final bodyBattery = _intFromJson(json['bodyBattery']) ?? 0;

    final zone1 = _zoneMinutes(json, 1);
    final zone2 = _zoneMinutes(json, 2);
    final zone3 = _zoneMinutes(json, 3);
    final zone4 = _zoneMinutes(json, 4);
    final zone5 = _zoneMinutes(json, 5);

    return WearableDailyData(
      date:
          _dateFromJson(json['date']) ?? DateTime(now.year, now.month, now.day),
      hrv: hrv,
      restingHeartRate: restingHeartRate,
      sleepMinutes: (sleepHours * 60).round(),
      stress: stress,
      soreness: soreness,
      trainingLoad: trainingLoad,
      activeCalories: calories,
      steps: steps,
      bodyBattery: bodyBattery,
      zone1Minutes: zone1,
      zone2Minutes: zone2,
      zone3Minutes: zone3,
      zone4Minutes: zone4,
      zone5Minutes: zone5,
      source: 'polar_import',
      hasRealDailyHealth:
          hrv > 0 || sleepHours > 0 || stress > 0 || restingHeartRate > 0,
      hasImportedTraining:
          trainingLoad > 0 || zone1 + zone2 + zone3 + zone4 + zone5 > 0,
      hasRealHrv: hrv > 0,
      hasRealSleep: sleepHours > 0,
      hasRealStress: stress > 0,
      hasRealRestingHeartRate: restingHeartRate > 0,
      hasRealSoreness: soreness > 0,
      hasRealCalories: calories > 0,
      hasRealSteps: steps > 0,
      hasRealBodyBattery: bodyBattery > 0,
      hasRealZones: zone1 + zone2 + zone3 + zone4 + zone5 > 0,
      hasRealHeartRate: restingHeartRate > 0,
      hasRealTrainingLoad: trainingLoad > 0,
    );
  }

  static WearableDailyData fromAppleHealthJson({
    required String athleteId,
    required Map<String, dynamic> json,
  }) {
    final now = DateTime.now();

    final hrv = _intFromJson(json['hrv']) ?? 0;

    final restingHeartRate = _intFromJson(json['restingHeartRate']) ?? 0;

    final sleepHours = _doubleFromJson(json['sleepHours']) ?? 0;

    final stress = _intFromJson(json['stress']) ?? 0;

    final soreness = _intFromJson(json['soreness']) ?? 0;

    final trainingLoad = _doubleFromJson(json['trainingLoad']) ?? 0;

    final calories = _intFromJson(json['calories']) ?? 0;

    final steps = _intFromJson(json['steps']) ?? 0;

    final bodyBattery = _intFromJson(json['bodyBattery']) ?? 0;

    final zone1 = _zoneMinutes(json, 1);
    final zone2 = _zoneMinutes(json, 2);
    final zone3 = _zoneMinutes(json, 3);
    final zone4 = _zoneMinutes(json, 4);
    final zone5 = _zoneMinutes(json, 5);

    return WearableDailyData(
      date:
          _dateFromJson(json['date']) ?? DateTime(now.year, now.month, now.day),
      hrv: hrv,
      restingHeartRate: restingHeartRate,
      sleepMinutes: (sleepHours * 60).round(),
      stress: stress,
      soreness: soreness,
      trainingLoad: trainingLoad,
      activeCalories: calories,
      steps: steps,
      bodyBattery: bodyBattery,
      zone1Minutes: zone1,
      zone2Minutes: zone2,
      zone3Minutes: zone3,
      zone4Minutes: zone4,
      zone5Minutes: zone5,
      source: 'apple_health_import',
      hasRealDailyHealth:
          hrv > 0 || sleepHours > 0 || stress > 0 || restingHeartRate > 0,
      hasImportedTraining:
          trainingLoad > 0 || zone1 + zone2 + zone3 + zone4 + zone5 > 0,
      hasRealHrv: hrv > 0,
      hasRealSleep: sleepHours > 0,
      hasRealStress: stress > 0,
      hasRealRestingHeartRate: restingHeartRate > 0,
      hasRealSoreness: soreness > 0,
      hasRealCalories: calories > 0,
      hasRealSteps: steps > 0,
      hasRealBodyBattery: bodyBattery > 0,
      hasRealZones: zone1 + zone2 + zone3 + zone4 + zone5 > 0,
      hasRealHeartRate: restingHeartRate > 0,
      hasRealTrainingLoad: trainingLoad > 0,
    );
  }

  static String providerName(WearableProviderType provider) {
    switch (provider) {
      case WearableProviderType.demo:
        return 'Demo';

      case WearableProviderType.manual:
        return 'Manual';

      case WearableProviderType.garmin:
        return 'Garmin';

      case WearableProviderType.polar:
        return 'Polar';

      case WearableProviderType.appleHealth:
        return 'Apple Watch';
    }
  }

  static String providerDescription(WearableProviderType provider) {
    switch (provider) {
      case WearableProviderType.demo:
        return 'Usa datos simulados para probar el pipeline IA.';

      case WearableProviderType.manual:
        return 'Permite ingresar métricas fisiológicas manualmente.';

      case WearableProviderType.garmin:
        return 'Sincroniza datos diarios y zonas desde Garmin Connect mediante backend.';

      case WearableProviderType.polar:
        return 'Preparado para Polar AccessLink API.';

      case WearableProviderType.appleHealth:
        return 'Preparado para HealthKit.';
    }
  }

  static int _zoneMinutes(Map<String, dynamic> json, int zone) {
    final direct = _intFromJson(json['zone${zone}Minutes']);

    if (direct != null) {
      return direct;
    }

    final z = _intFromJson(json['z${zone}Minutes']);

    if (z != null) {
      return z;
    }

    final timeInZone = json['timeInZone'];

    if (timeInZone is Map) {
      final map = Map<String, dynamic>.from(timeInZone);

      final value =
          _intFromJson(map['zone$zone']) ??
          _intFromJson(map['z$zone']) ??
          _intFromJson(map['$zone']);

      if (value != null) {
        return value;
      }
    }

    final zones = json['zones'];

    if (zones is Map) {
      final map = Map<String, dynamic>.from(zones);

      final value =
          _intFromJson(map['zone$zone']) ??
          _intFromJson(map['z$zone']) ??
          _intFromJson(map['$zone']);

      if (value != null) {
        return value;
      }
    }

    return 0;
  }

  static int? _intFromJson(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    if (value is double) {
      return value.round();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }

  static double? _doubleFromJson(dynamic value) {
    if (value == null) return null;

    if (value is double) return value;

    if (value is int) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  static DateTime? _dateFromJson(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
