import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WearableDailyData {
  final DateTime date;

  final int sleepMinutes;
  final int hrv;
  final int restingHeartRate;
  final int stress;
  final int soreness;

  final int activeCalories;
  final int steps;
  final double trainingLoad;
  final int bodyBattery;

  final int zone1Minutes;
  final int zone2Minutes;
  final int zone3Minutes;
  final int zone4Minutes;
  final int zone5Minutes;

  final int averageHeartRate;
  final int maxHeartRate;
  final int rpe;

  final int totalTrainingMinutes;
  final double totalDistanceKm;

  final String source;
  final bool hasRealDailyHealth;
  final bool hasImportedTraining;

  final bool hasRealHrv;
  final bool hasRealSleep;
  final bool hasRealStress;
  final bool hasRealRestingHeartRate;
  final bool hasRealSoreness;
  final bool hasRealCalories;
  final bool hasRealSteps;
  final bool hasRealBodyBattery;
  final bool hasRealZones;
  final bool hasRealHeartRate;
  final bool hasRealTrainingLoad;

  WearableDailyData({
    required this.date,
    int? sleepMinutes,
    double? sleepHours,
    required this.hrv,
    required this.restingHeartRate,
    required this.stress,
    required this.soreness,
    int? activeCalories,
    int? calories,
    required this.steps,
    required this.trainingLoad,
    this.bodyBattery = 0,
    this.zone1Minutes = 0,
    this.zone2Minutes = 0,
    this.zone3Minutes = 0,
    this.zone4Minutes = 0,
    this.zone5Minutes = 0,
    this.averageHeartRate = 0,
    this.maxHeartRate = 0,
    this.rpe = 0,
    this.totalTrainingMinutes = 0,
    this.totalDistanceKm = 0.0,
    this.source = 'unknown',
    this.hasRealDailyHealth = false,
    this.hasImportedTraining = false,
    this.hasRealHrv = false,
    this.hasRealSleep = false,
    this.hasRealStress = false,
    this.hasRealRestingHeartRate = false,
    this.hasRealSoreness = false,
    this.hasRealCalories = false,
    this.hasRealSteps = false,
    this.hasRealBodyBattery = false,
    this.hasRealZones = false,
    this.hasRealHeartRate = false,
    this.hasRealTrainingLoad = false,
  }) : sleepMinutes = sleepMinutes ?? ((sleepHours ?? 0) * 60).round(),
       activeCalories = activeCalories ?? calories ?? 0;

  double get sleepHours => sleepMinutes / 60.0;

  int get calories => activeCalories;

  bool get hasAnyRealRecoveryData {
    return hasRealHrv ||
        hasRealSleep ||
        hasRealStress ||
        hasRealRestingHeartRate ||
        hasRealBodyBattery;
  }

  bool get hasAnyRealTrainingData {
    return hasImportedTraining ||
        hasRealZones ||
        hasRealTrainingLoad ||
        totalTrainingMinutes > 0 ||
        totalDistanceKm > 0;
  }

  bool get isDemo => source == 'demo' || source == 'demo_history';

  bool get isManual => source == 'manual';

  bool get isFromGarmin => source.toLowerCase().contains('garmin');

  int get totalZoneMinutes {
    return zone1Minutes +
        zone2Minutes +
        zone3Minutes +
        zone4Minutes +
        zone5Minutes;
  }

  int get lowIntensityMinutes => zone1Minutes + zone2Minutes;

  int get moderateIntensityMinutes => zone3Minutes;

  int get highIntensityMinutes => zone4Minutes + zone5Minutes;

  double get highIntensityRatio {
    final total = totalZoneMinutes;
    if (total <= 0) return 0;
    return highIntensityMinutes / total;
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'sleepMinutes': sleepMinutes,
      'hrv': hrv,
      'restingHeartRate': restingHeartRate,
      'stress': stress,
      'soreness': soreness,
      'activeCalories': activeCalories,
      'steps': steps,
      'trainingLoad': trainingLoad,
      'bodyBattery': bodyBattery,
      'zone1Minutes': zone1Minutes,
      'zone2Minutes': zone2Minutes,
      'zone3Minutes': zone3Minutes,
      'zone4Minutes': zone4Minutes,
      'zone5Minutes': zone5Minutes,
      'averageHeartRate': averageHeartRate,
      'maxHeartRate': maxHeartRate,
      'rpe': rpe,
      'totalTrainingMinutes': totalTrainingMinutes,
      'totalDistanceKm': totalDistanceKm,
      'source': source,
      'hasRealDailyHealth': hasRealDailyHealth,
      'hasImportedTraining': hasImportedTraining,
      'hasRealHrv': hasRealHrv,
      'hasRealSleep': hasRealSleep,
      'hasRealStress': hasRealStress,
      'hasRealRestingHeartRate': hasRealRestingHeartRate,
      'hasRealSoreness': hasRealSoreness,
      'hasRealCalories': hasRealCalories,
      'hasRealSteps': hasRealSteps,
      'hasRealBodyBattery': hasRealBodyBattery,
      'hasRealZones': hasRealZones,
      'hasRealHeartRate': hasRealHeartRate,
      'hasRealTrainingLoad': hasRealTrainingLoad,
    };
  }

  factory WearableDailyData.fromMap(Map<String, dynamic> map) {
    final sleepMinutes = (map['sleepMinutes'] as num?)?.round() ?? 0;
    final hrv = (map['hrv'] as num?)?.round() ?? 0;
    final restingHeartRate = (map['restingHeartRate'] as num?)?.round() ?? 0;
    final stress = (map['stress'] as num?)?.round() ?? 0;
    final soreness = (map['soreness'] as num?)?.round() ?? 0;
    final activeCalories =
        (map['activeCalories'] as num?)?.round() ??
        (map['calories'] as num?)?.round() ??
        0;
    final steps = (map['steps'] as num?)?.round() ?? 0;
    final trainingLoad = (map['trainingLoad'] as num?)?.toDouble() ?? 0.0;
    final bodyBattery = (map['bodyBattery'] as num?)?.round() ?? 0;

    final zone1 = (map['zone1Minutes'] as num?)?.round() ?? 0;
    final zone2 = (map['zone2Minutes'] as num?)?.round() ?? 0;
    final zone3 = (map['zone3Minutes'] as num?)?.round() ?? 0;
    final zone4 = (map['zone4Minutes'] as num?)?.round() ?? 0;
    final zone5 = (map['zone5Minutes'] as num?)?.round() ?? 0;

    final averageHeartRate = (map['averageHeartRate'] as num?)?.round() ?? 0;
    final maxHeartRate = (map['maxHeartRate'] as num?)?.round() ?? 0;
    final source = map['source']?.toString() ?? 'unknown';

    bool boolValue(String key, bool fallback) {
      final value = map[key];
      if (value is bool) return value;
      return fallback;
    }

    final inferredHasZones = zone1 + zone2 + zone3 + zone4 + zone5 > 0;
    final inferredHasHeartRate = averageHeartRate > 0 || maxHeartRate > 0;

    final hasRealDailyHealth = boolValue(
      'hasRealDailyHealth',
      source.toLowerCase().contains('garmin'),
    );

    final hasImportedTraining = boolValue(
      'hasImportedTraining',
      inferredHasZones || trainingLoad > 0,
    );

    return WearableDailyData(
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      sleepMinutes: sleepMinutes,
      hrv: hrv,
      restingHeartRate: restingHeartRate,
      stress: stress,
      soreness: soreness,
      activeCalories: activeCalories,
      steps: steps,
      trainingLoad: trainingLoad,
      bodyBattery: bodyBattery,
      zone1Minutes: zone1,
      zone2Minutes: zone2,
      zone3Minutes: zone3,
      zone4Minutes: zone4,
      zone5Minutes: zone5,
      averageHeartRate: averageHeartRate,
      maxHeartRate: maxHeartRate,
      rpe: (map['rpe'] as num?)?.round() ?? 0,
      totalTrainingMinutes: (map['totalTrainingMinutes'] as num?)?.round() ?? 0,
      totalDistanceKm: (map['totalDistanceKm'] as num?)?.toDouble() ?? 0.0,
      source: source,
      hasRealDailyHealth: hasRealDailyHealth,
      hasImportedTraining: hasImportedTraining,
      hasRealHrv: boolValue('hasRealHrv', hasRealDailyHealth && hrv > 0),
      hasRealSleep: boolValue(
        'hasRealSleep',
        hasRealDailyHealth && sleepMinutes > 0,
      ),
      hasRealStress: boolValue(
        'hasRealStress',
        hasRealDailyHealth && stress > 0,
      ),
      hasRealRestingHeartRate: boolValue(
        'hasRealRestingHeartRate',
        hasRealDailyHealth && restingHeartRate > 0,
      ),
      hasRealSoreness: boolValue('hasRealSoreness', source == 'manual'),
      hasRealCalories: boolValue(
        'hasRealCalories',
        activeCalories > 0 && !source.contains('demo'),
      ),
      hasRealSteps: boolValue(
        'hasRealSteps',
        steps > 0 && !source.contains('demo'),
      ),
      hasRealBodyBattery: boolValue(
        'hasRealBodyBattery',
        hasRealDailyHealth && bodyBattery > 0,
      ),
      hasRealZones: boolValue(
        'hasRealZones',
        hasImportedTraining && inferredHasZones,
      ),
      hasRealHeartRate: boolValue('hasRealHeartRate', inferredHasHeartRate),
      hasRealTrainingLoad: boolValue(
        'hasRealTrainingLoad',
        hasImportedTraining && trainingLoad > 0,
      ),
    );
  }
}

class WearableIntegrationService extends ChangeNotifier {
  static const String _storageKey = 'speedskate_wearable_data_by_athlete_v3';
  static const String _legacyStorageKeyV2 = 'speedskate_wearable_data_v2';
  static const String _legacyStorageKeyV1 = 'speedskate_wearable_data_v1';
  static const String _fallbackAthleteId = 'default_athlete';

  String? _activeAthleteId;

  final Map<String, bool> _connectedByAthlete = {};
  final Map<String, String> _providerByAthlete = {};
  final Map<String, WearableDailyData> _todayByAthlete = {};
  final Map<String, List<WearableDailyData>> _historyByAthlete = {};

  bool _loaded = false;

  bool get loaded => _loaded;

  String get currentAthleteId => _activeAthleteId ?? _fallbackAthleteId;

  void setActiveAthlete(String athleteId) {
    final clean = athleteId.trim();
    if (clean.isEmpty) return;

    _activeAthleteId = clean;
    _ensureAthlete(clean);

    _persist();
    notifyListeners();
  }

  bool isConnectedForAthlete(String athleteId) {
    return _connectedByAthlete[athleteId] ?? false;
  }

  String providerNameForAthlete(String athleteId) {
    return _providerByAthlete[athleteId] ?? 'No wearable connected';
  }

  WearableDailyData? todayForAthlete(String athleteId) {
    return _todayByAthlete[athleteId];
  }

  List<WearableDailyData> historyForAthlete(String athleteId) {
    return List.unmodifiable(_historyByAthlete[athleteId] ?? []);
  }

  bool get connected => isConnectedForAthlete(currentAthleteId);

  String get providerName => providerNameForAthlete(currentAthleteId);

  WearableDailyData? get today => todayForAthlete(currentAthleteId);

  List<WearableDailyData> get history => historyForAthlete(currentAthleteId);

  WearableIntegrationService() {
    loadPersistedData();
  }

  Future<void> loadPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final rawV3 = prefs.getString(_storageKey);

      if (rawV3 != null && rawV3.isNotEmpty) {
        _loadV3(rawV3);
      } else {
        await _migrateLegacyIfNeeded(prefs);
      }
    } catch (_) {
      _connectedByAthlete.clear();
      _providerByAthlete.clear();
      _todayByAthlete.clear();
      _historyByAthlete.clear();
      _activeAthleteId = null;
    }

    _loaded = true;
    notifyListeners();
  }

  void _loadV3(String raw) {
    final decoded = Map<String, dynamic>.from(jsonDecode(raw));

    _activeAthleteId = decoded['activeAthleteId']?.toString();

    final connectedMap = Map<String, dynamic>.from(decoded['connected'] ?? {});
    final providerMap = Map<String, dynamic>.from(decoded['providers'] ?? {});
    final todayMap = Map<String, dynamic>.from(decoded['today'] ?? {});
    final historyMap = Map<String, dynamic>.from(decoded['history'] ?? {});

    connectedMap.forEach((athleteId, value) {
      _connectedByAthlete[athleteId] = value == true;
    });

    providerMap.forEach((athleteId, value) {
      _providerByAthlete[athleteId] =
          value?.toString() ?? 'No wearable connected';
    });

    todayMap.forEach((athleteId, rawToday) {
      if (rawToday is Map) {
        _todayByAthlete[athleteId] = WearableDailyData.fromMap(
          Map<String, dynamic>.from(rawToday),
        );
      }
    });

    historyMap.forEach((athleteId, rawList) {
      final list = rawList is List ? rawList : <dynamic>[];

      _historyByAthlete[athleteId] =
          list
              .whereType<Map>()
              .map(
                (item) =>
                    WearableDailyData.fromMap(Map<String, dynamic>.from(item)),
              )
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));
    });

    if (_activeAthleteId != null) {
      _ensureAthlete(_activeAthleteId!);
    }
  }

  Future<void> _migrateLegacyIfNeeded(SharedPreferences prefs) async {
    final rawV2 = prefs.getString(_legacyStorageKeyV2);
    final rawV1 = prefs.getString(_legacyStorageKeyV1);
    final raw = rawV2 ?? rawV1;

    if (raw == null || raw.isEmpty) {
      _ensureAthlete(_fallbackAthleteId);
      return;
    }

    final decoded = Map<String, dynamic>.from(jsonDecode(raw));

    final athleteId = _fallbackAthleteId;
    _activeAthleteId = athleteId;

    _connectedByAthlete[athleteId] = decoded['connected'] == true;
    _providerByAthlete[athleteId] =
        decoded['providerName']?.toString() ?? 'No wearable connected';

    final todayRaw = decoded['today'];
    if (todayRaw is Map) {
      _todayByAthlete[athleteId] = WearableDailyData.fromMap(
        Map<String, dynamic>.from(todayRaw),
      );
    }

    final historyRaw = decoded['history'] is List
        ? List<dynamic>.from(decoded['history'])
        : <dynamic>[];

    _historyByAthlete[athleteId] =
        historyRaw
            .whereType<Map>()
            .map(
              (item) =>
                  WearableDailyData.fromMap(Map<String, dynamic>.from(item)),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    await _persist();
  }

  void _ensureAthlete(String athleteId) {
    _connectedByAthlete.putIfAbsent(athleteId, () => false);
    _providerByAthlete.putIfAbsent(athleteId, () => 'No wearable connected');
    _historyByAthlete.putIfAbsent(athleteId, () => []);
  }

  Future<void> connectDemo({String? athleteId}) async {
    final id = athleteId ?? currentAthleteId;
    _ensureAthlete(id);

    _connectedByAthlete[id] = true;
    _providerByAthlete[id] = 'Demo Wearable';

    final demoToday = WearableDailyData(
      date: DateTime.now(),
      sleepMinutes: 450,
      hrv: 58,
      restingHeartRate: 51,
      stress: 35,
      soreness: 3,
      activeCalories: 720,
      steps: 9800,
      trainingLoad: 82,
      bodyBattery: 74,
      zone1Minutes: 18,
      zone2Minutes: 28,
      zone3Minutes: 16,
      zone4Minutes: 8,
      zone5Minutes: 2,
      averageHeartRate: 138,
      maxHeartRate: 178,
      rpe: 5,
      totalTrainingMinutes: 72,
      totalDistanceKm: 18.5,
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

    final demoHistory = <WearableDailyData>[];

    for (int i = 27; i >= 0; i--) {
      final isHardDay = i % 5 == 0;
      final isRecoveryDay = i % 4 == 0;

      final z1 = isRecoveryDay ? 35 : 18;
      final z2 = isRecoveryDay ? 25 : 28;
      final z3 = isHardDay ? 22 : 12;
      final z4 = isHardDay ? 15 : 5;
      final z5 = isHardDay ? 6 : 1;
      final totalMinutes = z1 + z2 + z3 + z4 + z5;

      demoHistory.add(
        WearableDailyData(
          date: DateTime.now().subtract(Duration(days: i)),
          sleepMinutes: 390 + (i % 5) * 18,
          hrv: 48 + (i % 9),
          restingHeartRate: 50 + (i % 6),
          stress: 30 + (i % 7) * 5,
          soreness: 2 + (i % 5),
          activeCalories: 550 + (i % 8) * 45,
          steps: 7000 + (i % 9) * 550,
          trainingLoad: 60 + (i % 10) * 8,
          bodyBattery: 55 + (i % 8) * 4,
          zone1Minutes: z1,
          zone2Minutes: z2,
          zone3Minutes: z3,
          zone4Minutes: z4,
          zone5Minutes: z5,
          averageHeartRate: isHardDay ? 152 : 132,
          maxHeartRate: isHardDay ? 186 : 162,
          rpe: isHardDay ? 7 : 4,
          totalTrainingMinutes: totalMinutes,
          totalDistanceKm: isHardDay ? 22.0 : 14.0,
          source: 'demo_history',
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
        ),
      );
    }

    _todayByAthlete[id] = demoToday;
    _historyByAthlete[id] = demoHistory;

    await _persist();
    notifyListeners();
  }

  Future<void> setToday({
    String? athleteId,
    required String provider,
    required WearableDailyData data,
  }) async {
    final id = athleteId ?? currentAthleteId;
    _ensureAthlete(id);

    _connectedByAthlete[id] = true;
    _providerByAthlete[id] = provider;
    _todayByAthlete[id] = data;

    final athleteHistory = _historyByAthlete[id]!;

    athleteHistory.removeWhere((item) => _isSameDay(item.date, data.date));
    athleteHistory.add(data);
    athleteHistory.sort((a, b) => a.date.compareTo(b.date));

    if (athleteHistory.length > 90) {
      athleteHistory.removeRange(0, athleteHistory.length - 90);
    }

    await _persist();
    notifyListeners();
  }

  Future<void> disconnect({String? athleteId}) async {
    final id = athleteId ?? currentAthleteId;
    _ensureAthlete(id);

    _connectedByAthlete[id] = false;
    _providerByAthlete[id] = 'No wearable connected';
    _todayByAthlete.remove(id);
    _historyByAthlete[id] = [];

    await _persist();
    notifyListeners();
  }

  Future<void> updateManualData({
    String? athleteId,
    required int sleepMinutes,
    required int hrv,
    required int restingHeartRate,
    required int stress,
    required int soreness,
    required int activeCalories,
    required int steps,
    required double trainingLoad,
    int bodyBattery = 0,
    int zone1Minutes = 0,
    int zone2Minutes = 0,
    int zone3Minutes = 0,
    int zone4Minutes = 0,
    int zone5Minutes = 0,
    int averageHeartRate = 0,
    int maxHeartRate = 0,
    int rpe = 0,
    int totalTrainingMinutes = 0,
    double totalDistanceKm = 0.0,
  }) async {
    final hasZones =
        zone1Minutes +
            zone2Minutes +
            zone3Minutes +
            zone4Minutes +
            zone5Minutes >
        0;

    final data = WearableDailyData(
      date: DateTime.now(),
      sleepMinutes: sleepMinutes,
      hrv: hrv,
      restingHeartRate: restingHeartRate,
      stress: stress,
      soreness: soreness,
      activeCalories: activeCalories,
      steps: steps,
      trainingLoad: trainingLoad,
      bodyBattery: bodyBattery,
      zone1Minutes: zone1Minutes,
      zone2Minutes: zone2Minutes,
      zone3Minutes: zone3Minutes,
      zone4Minutes: zone4Minutes,
      zone5Minutes: zone5Minutes,
      averageHeartRate: averageHeartRate,
      maxHeartRate: maxHeartRate,
      rpe: rpe,
      totalTrainingMinutes: totalTrainingMinutes,
      totalDistanceKm: totalDistanceKm,
      source: 'manual',
      hasRealDailyHealth: false,
      hasImportedTraining: totalTrainingMinutes > 0 || hasZones,
      hasRealHrv: hrv > 0,
      hasRealSleep: sleepMinutes > 0,
      hasRealStress: stress > 0,
      hasRealRestingHeartRate: restingHeartRate > 0,
      hasRealSoreness: soreness > 0,
      hasRealCalories: activeCalories > 0,
      hasRealSteps: steps > 0,
      hasRealBodyBattery: bodyBattery > 0,
      hasRealZones: hasZones,
      hasRealHeartRate: averageHeartRate > 0 || maxHeartRate > 0,
      hasRealTrainingLoad: trainingLoad > 0,
    );

    await setToday(
      athleteId: athleteId,
      provider: 'Manual / Wearable',
      data: data,
    );
  }

  Future<void> clearPersistedData({String? athleteId}) async {
    final prefs = await SharedPreferences.getInstance();

    if (athleteId == null) {
      _connectedByAthlete.clear();
      _providerByAthlete.clear();
      _todayByAthlete.clear();
      _historyByAthlete.clear();
      _activeAthleteId = null;

      await prefs.remove(_storageKey);
      await prefs.remove(_legacyStorageKeyV2);
      await prefs.remove(_legacyStorageKeyV1);
    } else {
      _connectedByAthlete.remove(athleteId);
      _providerByAthlete.remove(athleteId);
      _todayByAthlete.remove(athleteId);
      _historyByAthlete.remove(athleteId);

      await _persist();
    }

    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();

    final todayMap = <String, dynamic>{};
    _todayByAthlete.forEach((athleteId, data) {
      todayMap[athleteId] = data.toMap();
    });

    final historyMap = <String, dynamic>{};
    _historyByAthlete.forEach((athleteId, items) {
      historyMap[athleteId] = items.map((item) => item.toMap()).toList();
    });

    final data = {
      'activeAthleteId': _activeAthleteId,
      'connected': _connectedByAthlete,
      'providers': _providerByAthlete,
      'today': todayMap,
      'history': historyMap,
    };

    await prefs.setString(_storageKey, jsonEncode(data));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int? get realSleepHoursRounded {
    if (today == null || !today!.hasRealSleep) return null;
    return today!.sleepHours.round();
  }

  int? get realHrv {
    if (today == null || !today!.hasRealHrv) return null;
    return today!.hrv;
  }

  int? get realRestingHeartRate {
    if (today == null || !today!.hasRealRestingHeartRate) return null;
    return today!.restingHeartRate;
  }

  int? get realStress {
    if (today == null || !today!.hasRealStress) return null;
    return today!.stress;
  }

  int? get realSoreness {
    if (today == null || !today!.hasRealSoreness) return null;
    return today!.soreness;
  }

  int get sleepHoursRounded => today?.sleepHours.round() ?? 0;
  int get sleepHours => today?.sleepHours.round() ?? 0;
  int get hrv => today?.hrv ?? 0;
  int get restingHeartRate => today?.restingHeartRate ?? 0;
  int get stress => today?.stress ?? 0;
  int get soreness => today?.soreness ?? 0;
  int get zone1Minutes => today?.zone1Minutes ?? 0;
  int get zone2Minutes => today?.zone2Minutes ?? 0;
  int get zone3Minutes => today?.zone3Minutes ?? 0;
  int get zone4Minutes => today?.zone4Minutes ?? 0;
  int get zone5Minutes => today?.zone5Minutes ?? 0;
  int get highIntensityMinutes => today?.highIntensityMinutes ?? 0;
  int get averageHeartRate => today?.averageHeartRate ?? 0;
  int get maxHeartRate => today?.maxHeartRate ?? 0;
  int get rpe => today?.rpe ?? 0;
  int get totalTrainingMinutes => today?.totalTrainingMinutes ?? 0;
  double get totalDistanceKm => today?.totalDistanceKm ?? 0.0;

  double get averageTrainingLoad28Days {
    if (history.isEmpty) return 0;
    final recent = history.length > 28
        ? history.sublist(history.length - 28)
        : history;

    final total = recent.fold<double>(
      0,
      (sum, item) => sum + item.trainingLoad,
    );

    return total / recent.length;
  }

  double get trainingLoad7Days {
    if (history.isEmpty) return 0;
    final recent = history.length > 7
        ? history.sublist(history.length - 7)
        : history;

    return recent.fold<double>(0, (sum, item) => sum + item.trainingLoad);
  }

  double get trainingLoad28Days {
    if (history.isEmpty) return 0;
    final recent = history.length > 28
        ? history.sublist(history.length - 28)
        : history;

    return recent.fold<double>(0, (sum, item) => sum + item.trainingLoad);
  }

  int get highIntensityMinutes7Days {
    if (history.isEmpty) return 0;
    final recent = history.length > 7
        ? history.sublist(history.length - 7)
        : history;

    return recent.fold<int>(0, (sum, item) => sum + item.highIntensityMinutes);
  }

  int get highIntensityMinutes28Days {
    if (history.isEmpty) return 0;
    final recent = history.length > 28
        ? history.sublist(history.length - 28)
        : history;

    return recent.fold<int>(0, (sum, item) => sum + item.highIntensityMinutes);
  }
}
