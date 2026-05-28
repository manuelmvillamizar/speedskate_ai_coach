import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'athlete_daily_state.dart';
import 'athlete_program_service.dart';
import 'fatigue_engine.dart';
import 'training_history_service.dart';
import 'wearable_integration_service.dart';

import 'physiology/baseline/baseline_models.dart';
import 'physiology/baseline/dynamic_baseline_service.dart';
import 'physiology/data_quality/data_quality_layer.dart';
import 'physiology/fatigue/fatigue_systems_engine.dart';
import 'physiology/readiness/hybrid_readiness_engine.dart';

class AthleteContextService extends ChangeNotifier {
  static const String _storageKey = 'speedskate_athlete_context_storage_v2';

  AthleteProgramProfile? _activeAthlete;

  final Map<String, List<TrainingHistoryEntry>> _historyByAthlete = {};
  final Map<String, WearableDailyData> _wearableByAthlete = {};
  final Map<String, List<WearableDailyData>> _wearableHistoryByAthlete = {};
  final Map<String, String> _fatigueByAthlete = {};
  final Map<String, int> _readinessByAthlete = {};
  final Map<String, AthleteDailyState> _dailyStateByAthlete = {};

  final Map<String, DynamicBaseline> _baselineByAthlete = {};
  final Map<String, DataQualityReport> _dataQualityByAthlete = {};
  final Map<String, FatigueSystemsProfile> _fatigueSystemsByAthlete = {};
  final Map<String, HybridReadinessResult> _hybridReadinessByAthlete = {};

  bool _loaded = false;

  bool get loaded => _loaded;

  AthleteProgramProfile? get activeAthlete => _activeAthlete;

  String? get activeAthleteId => _activeAthlete?.id;

  bool get hasActiveAthlete => _activeAthlete != null;

  List<TrainingHistoryEntry> get activeHistory {
    final id = activeAthleteId;
    if (id == null) return [];
    return List.unmodifiable(_historyByAthlete[id] ?? []);
  }

  WearableDailyData? get activeWearable {
    final id = activeAthleteId;
    if (id == null) return null;
    return _wearableByAthlete[id];
  }

  List<WearableDailyData> get wearableHistory {
    final id = activeAthleteId;
    if (id == null) return [];
    return List.unmodifiable(_wearableHistoryByAthlete[id] ?? []);
  }

  DynamicBaseline? get activeDynamicBaseline {
    final id = activeAthleteId;
    if (id == null) return null;
    return _baselineByAthlete[id];
  }

  DataQualityReport? get activeDataQuality {
    final id = activeAthleteId;
    if (id == null) return null;
    return _dataQualityByAthlete[id];
  }

  FatigueSystemsProfile? get activeFatigueSystems {
    final id = activeAthleteId;
    if (id == null) return null;
    return _fatigueSystemsByAthlete[id];
  }

  HybridReadinessResult? get activeHybridReadiness {
    final id = activeAthleteId;
    if (id == null) return null;
    return _hybridReadinessByAthlete[id];
  }

  String get activeFatigueStatus {
    final id = activeAthleteId;
    if (id == null) return 'green';
    return _fatigueByAthlete[id] ?? 'green';
  }

  int get activeReadinessScore {
    final id = activeAthleteId;
    if (id == null) return 100;
    return _readinessByAthlete[id] ?? 100;
  }

  AthleteDailyState? get currentDailyState {
    final id = activeAthleteId;
    if (id == null) return null;
    return _dailyStateByAthlete[id];
  }

  Future<void> initialize() async {
    if (_loaded) return;

    await _load();

    _loaded = true;
    notifyListeners();
  }

  void setActiveAthlete(AthleteProgramProfile athlete) {
    _activeAthlete = athlete;

    _historyByAthlete.putIfAbsent(athlete.id, () => []);
    _wearableHistoryByAthlete.putIfAbsent(athlete.id, () => []);
    _fatigueByAthlete.putIfAbsent(athlete.id, () => 'green');
    _readinessByAthlete.putIfAbsent(athlete.id, () => 100);

    _recalculateInternalPhysiologyForAthlete(athlete.id);

    _save();
    notifyListeners();
  }

  void clearActiveAthlete() {
    _activeAthlete = null;

    _save();
    notifyListeners();
  }

  void addTrainingEntry(TrainingHistoryEntry entry) {
    final athlete = _activeAthlete;
    if (athlete == null) return;

    _historyByAthlete.putIfAbsent(athlete.id, () => []);
    _historyByAthlete[athlete.id]!.add(entry);

    _recalculateInternalPhysiologyForAthlete(athlete.id);

    _save();
    notifyListeners();
  }

  void setWearableData(WearableDailyData data) {
    final athlete = _activeAthlete;
    if (athlete == null) return;

    _wearableByAthlete[athlete.id] = data;

    _wearableHistoryByAthlete.putIfAbsent(athlete.id, () => []);
    final history = _wearableHistoryByAthlete[athlete.id]!;

    final index = history.indexWhere(
      (e) =>
          e.date.year == data.date.year &&
          e.date.month == data.date.month &&
          e.date.day == data.date.day,
    );

    if (index == -1) {
      history.add(data);
    } else {
      history[index] = data;
    }

    history.sort((a, b) => a.date.compareTo(b.date));

    if (history.length > 90) {
      history.removeRange(0, history.length - 90);
    }

    _recalculateInternalPhysiologyForAthlete(athlete.id);

    _save();
    notifyListeners();
  }

  void updateDailyState(AthleteDailyState state) {
    _dailyStateByAthlete[state.athleteId] = state;

    _save();
    notifyListeners();
  }

  void _recalculateInternalPhysiologyForAthlete(String athleteId) {
    final history = _historyByAthlete[athleteId] ?? [];
    final wearable = _wearableByAthlete[athleteId];

    final lastEntry = history.isEmpty ? null : history.last;

    final gymLoad = lastEntry?.gymKg ?? 0;
    final skateKm = lastEntry?.skateKm ?? 0;
    final minutes = lastEntry?.minutes ?? 0;

    final fatigueStatus = FatigueEngine.calculateStatus(
      gymLoad: gymLoad,
      skateKm: skateKm,
      minutes: minutes,
    );

    _fatigueByAthlete[athleteId] = fatigueStatus;

    if (wearable == null) {
      final readiness = FatigueEngine.readinessScore(
        gymLoad: gymLoad,
        skateKm: skateKm,
        minutes: minutes,
      );

      _readinessByAthlete[athleteId] = readiness;
      return;
    }

    final wearableHistory = _wearableHistoryByAthlete[athleteId] ?? [];

    final baselinePoints =
        wearableHistory.map(_baselinePointFromWearable).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    final baseline = DynamicBaselineService.calculate(
      history: baselinePoints,
      window: BaselineWindow.mediumTerm,
    );

    final dataQuality = DataQualityLayer.evaluateBaseline(baseline);

    final todayPoint = _baselinePointFromWearable(wearable);

    final hasRealSoreness = wearable.hasRealSoreness == true;
    final soreness = hasRealSoreness ? wearable.soreness : 0;

    final fatigueSystems = FatigueSystemsEngine.calculate(
      today: todayPoint,
      baseline: baseline,
      dataQuality: dataQuality,
      gymLoad: gymLoad,
      skateKm: skateKm,
      minutes: minutes,
      zone5Minutes: wearable.zone5Minutes,
      highIntensityMinutes: wearable.highIntensityMinutes,
      soreness: soreness,
    );

    final hybridReadiness = HybridReadinessEngine.calculate(
      gymLoad: gymLoad,
      skateKm: skateKm,
      minutes: minutes,
      today: todayPoint,
      baseline: baseline,
      dataQuality: dataQuality,
      fatigueSystems: fatigueSystems,
      soreness: soreness,
    );

    _baselineByAthlete[athleteId] = baseline;
    _dataQualityByAthlete[athleteId] = dataQuality;
    _fatigueSystemsByAthlete[athleteId] = fatigueSystems;
    _hybridReadinessByAthlete[athleteId] = hybridReadiness;

    _readinessByAthlete[athleteId] = hybridReadiness.score;
  }

  BaselineDataPoint _baselinePointFromWearable(WearableDailyData data) {
    final hasAnyRealData =
        data.hasRealHrv == true ||
        data.hasRealSleep == true ||
        data.hasRealStress == true ||
        data.hasRealRestingHeartRate == true;

    return BaselineDataPoint(
      date: data.date,
      hrv: data.hasRealHrv == true ? data.hrv.toDouble() : null,
      restingHeartRate: data.hasRealRestingHeartRate == true
          ? data.restingHeartRate
          : null,
      sleepHours: data.hasRealSleep == true ? data.sleepHours : null,
      stress: data.hasRealStress == true ? data.stress : null,
      bodyBattery: data.bodyBattery > 0 ? data.bodyBattery : null,
      hasValidWearableData: hasAnyRealData,
      isExcluded: !hasAnyRealData,
      exclusionReason: hasAnyRealData
          ? null
          : BaselineExclusionReason.missingData,
    );
  }

  bool get shouldBlockProgression {
    return FatigueEngine.shouldBlockProgression(activeFatigueStatus);
  }

  bool get shouldForceRecovery {
    return FatigueEngine.shouldForceRecovery(activeFatigueStatus);
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final wearableMap = <String, dynamic>{};
      _wearableByAthlete.forEach((athleteId, wearable) {
        wearableMap[athleteId] = wearable.toMap();
      });

      final wearableHistoryMap = <String, dynamic>{};
      _wearableHistoryByAthlete.forEach((athleteId, history) {
        wearableHistoryMap[athleteId] = history
            .map((item) => item.toMap())
            .toList();
      });

      final dailyStateMap = <String, dynamic>{};
      _dailyStateByAthlete.forEach((athleteId, state) {
        dailyStateMap[athleteId] = state.toMap();
      });

      final map = {
        'activeAthleteId': _activeAthlete?.id,
        'fatigue': _fatigueByAthlete,
        'readiness': _readinessByAthlete,
        'wearables': wearableMap,
        'wearableHistory': wearableHistoryMap,
        'dailyStates': dailyStateMap,
      };

      await prefs.setString(_storageKey, jsonEncode(map));
    } catch (_) {}
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;

      final map = jsonDecode(raw);

      final fatigue = Map<String, dynamic>.from(map['fatigue'] ?? {});
      final readiness = Map<String, dynamic>.from(map['readiness'] ?? {});
      final wearables = Map<String, dynamic>.from(map['wearables'] ?? {});
      final wearableHistory = Map<String, dynamic>.from(
        map['wearableHistory'] ?? {},
      );
      final dailyStates = Map<String, dynamic>.from(map['dailyStates'] ?? {});

      fatigue.forEach((key, value) {
        _fatigueByAthlete[key] = value.toString();
      });

      readiness.forEach((key, value) {
        _readinessByAthlete[key] = (value as num?)?.toInt() ?? 100;
      });

      wearables.forEach((athleteId, rawWearable) {
        final wearable = Map<String, dynamic>.from(rawWearable);
        _wearableByAthlete[athleteId] = WearableDailyData.fromMap(wearable);
      });

      wearableHistory.forEach((athleteId, rawList) {
        final list = rawList as List<dynamic>? ?? [];

        _wearableHistoryByAthlete[athleteId] = list.map((rawItem) {
          final map = Map<String, dynamic>.from(rawItem);
          return WearableDailyData.fromMap(map);
        }).toList()..sort((a, b) => a.date.compareTo(b.date));
      });

      dailyStates.forEach((athleteId, rawState) {
        final state = Map<String, dynamic>.from(rawState);
        _dailyStateByAthlete[athleteId] = AthleteDailyState.fromMap(state);
      });

      for (final athleteId in _wearableByAthlete.keys) {
        _recalculateInternalPhysiologyForAthlete(athleteId);
      }
    } catch (_) {}
  }
}
