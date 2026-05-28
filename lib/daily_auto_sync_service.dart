import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'athlete_context_service.dart';
import 'athlete_physiology_profile.dart';
import 'athlete_program_service.dart';
import 'daily_log_storage_service.dart';
import 'daily_pipeline_cache_service.dart';
import 'daily_training_assignment_service.dart';
import 'daily_training_pipeline_service.dart';
import 'physiology_profile_storage_service.dart';
import 'wearable_integration_service.dart';
import 'wearable_provider_service.dart';

class DailyAutoSyncService extends ChangeNotifier {
  static const String _lastSyncKey = 'speedskate_last_auto_sync_v1';

  bool syncing = false;
  String message = 'Sincronización automática lista.';
  DateTime? lastSyncAt;

  Future<void> runAutoSync({
    required AthleteProgramService athleteService,
    required AthleteContextService athleteContext,
    required WearableIntegrationService wearableService,
    required DailyTrainingAssignmentService assignmentService,
    bool force = false,
  }) async {
    if (syncing) return;

    final athlete = athleteService.activeAthlete;

    if (athlete == null) {
      message = 'No hay atleta activo.';
      notifyListeners();
      return;
    }

    final today = DateTime.now();
    final alreadySyncedToday = await _alreadySyncedToday(athlete.id);

    if (alreadySyncedToday && !force) {
      message = 'El plan de hoy ya está actualizado.';
      notifyListeners();
      return;
    }

    syncing = true;
    message = force
        ? 'Forzando sincronización y recalculando plan diario...'
        : 'Actualizando datos y plan diario...';
    notifyListeners();

    try {
      athleteContext.setActiveAthlete(athlete);

      if (force) {
        await DailyPipelineCacheService.clearSnapshot(
          athleteId: athlete.id,
          date: today,
        );
      }

      final provider = await WearableProviderService.loadSavedProvider(
        athleteId: athlete.id,
      );

      if (provider == null) {
        message = force
            ? 'No hay wearable conectado. Cache diario reiniciado.'
            : 'No hay wearable conectado. Se conserva el plan actual.';
        syncing = false;
        notifyListeners();
        return;
      }

      final wearable = await WearableProviderService.fetchToday(
        provider: provider,
        athleteId: athlete.id,
      );

      if (wearable != null) {
        await wearableService.setToday(
          provider: WearableProviderService.providerName(provider),
          data: wearable,
        );

        athleteContext.setWearableData(wearable);
      } else if (wearableService.today != null) {
        athleteContext.setWearableData(wearableService.today!);
      }

      final profile =
          await PhysiologyProfileStorageService.loadProfile(athlete.id) ??
          AthletePhysiologyProfile(athleteId: athlete.id);

      final logs = await DailyLogStorageService.loadLogs(athlete.id);

      final activeWearable = athleteContext.activeWearable;

      final hasFreshWearable =
          activeWearable != null &&
          activeWearable.date.year == today.year &&
          activeWearable.date.month == today.month &&
          activeWearable.date.day == today.day;

      final hasReliableWearable =
          hasFreshWearable &&
          activeWearable.source != 'demo' &&
          activeWearable.source != 'demo_history' &&
          activeWearable.source != 'unknown' &&
          activeWearable.source != 'cache';

      if (force || hasReliableWearable) {
        await DailyPipelineCacheService.clearSnapshot(
          athleteId: athlete.id,
          date: today,
        );
      }

      final result = await DailyTrainingPipelineService.run(
        athlete: athlete,
        athleteContext: athleteContext,
        profile: profile,
        initialLogs: logs,
        date: today,
        useCache: !force && !hasReliableWearable,
      );

      // �o. NUEVO: actualizar el estado diario en AthleteContextService
      athleteContext.updateDailyState(result.dailyState);

      await assignmentService.saveDraft(
        athleteId: athlete.id,
        day: result.adjustedDay,
      );

      await assignmentService.sendToday(athlete.id);

      lastSyncAt = DateTime.now();

      await _saveLastSync(athlete.id, lastSyncAt!);

      message = force
          ? 'Sincronización forzada completada. Plan diario recalculado y enviado.'
          : 'Plan diario actualizado automáticamente y enviado al atleta.';
    } catch (error) {
      message = 'No se pudo actualizar automáticamente: $error';
    }

    syncing = false;
    notifyListeners();
  }

  Future<bool> _alreadySyncedToday(String athleteId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('${_lastSyncKey}_$athleteId');

    if (raw == null || raw.isEmpty) return false;

    final saved = DateTime.tryParse(raw);

    if (saved == null) return false;

    final now = DateTime.now();

    lastSyncAt = saved;

    return saved.year == now.year &&
        saved.month == now.month &&
        saved.day == now.day;
  }

  Future<void> _saveLastSync(String athleteId, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_lastSyncKey}_$athleteId', date.toIso8601String());
  }

  Future<void> resetSyncForAthlete(String athleteId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_lastSyncKey}_$athleteId');

    await DailyPipelineCacheService.clearSnapshot(
      athleteId: athleteId,
      date: DateTime.now(),
    );

    lastSyncAt = null;
    message = 'Sincronización y cache diario reiniciados.';
    notifyListeners();
  }
}
