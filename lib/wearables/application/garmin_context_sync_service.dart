import '../../athlete_context_service.dart';
import '../../athlete_physiology_profile.dart';
import '../../athlete_program_service.dart';
import '../../daily_log_storage_service.dart';
import '../../daily_pipeline_cache_service.dart';
import '../../daily_training_assignment_service.dart';
import '../../daily_training_pipeline_service.dart';
import '../../physiology_profile_storage_service.dart';
import '../../wearable_integration_service.dart';
import 'garmin_training_bridge.dart';
import 'garmin_wearable_mapper.dart';
import 'wearable_sync_orchestrator.dart';

class GarminContextSyncResult {
  final bool success;
  final String message;

  const GarminContextSyncResult({required this.success, required this.message});
}

class GarminContextSyncService {
  static Future<GarminContextSyncResult> syncToAthleteContext({
    required AthleteProgramService athleteService,
    required AthleteContextService athleteContext,
    required WearableIntegrationService wearableService,
    required DailyTrainingAssignmentService assignmentService,
    bool sendToAthlete = true,
    WearableDailyData? externalWearableData,
    String externalSource = 'external',
  }) async {
    final athlete = athleteService.activeAthlete;

    if (athlete == null) {
      return const GarminContextSyncResult(
        success: false,
        message: 'No hay atleta activo.',
      );
    }

    athleteContext.setActiveAthlete(athlete);

    final sync = externalWearableData == null
        ? await WearableSyncOrchestrator.syncGarmin(athleteId: athlete.id)
        : await _syncFromExternalWearable(
            externalWearableData: externalWearableData,
            externalSource: externalSource,
          );

    if (!sync.success || sync.wearable == null) {
      return GarminContextSyncResult(success: false, message: sync.message);
    }

    final wearable = sync.wearable!;

    final mergedHistory = <WearableDailyData>[...sync.history, wearable];

    final uniqueByDay = <String, WearableDailyData>{};

    for (final item in mergedHistory) {
      final key =
          '${item.date.year}-${item.date.month.toString().padLeft(2, '0')}-${item.date.day.toString().padLeft(2, '0')}';
      uniqueByDay[key] = item;
    }

    final orderedHistory = uniqueByDay.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final item in orderedHistory) {
      await wearableService.setToday(provider: sync.provider, data: item);
      athleteContext.setWearableData(item);
    }

    await wearableService.setToday(provider: sync.provider, data: wearable);
    athleteContext.setWearableData(wearable);

    final today = DateTime.now();

    await DailyPipelineCacheService.clearSnapshot(
      athleteId: athlete.id,
      date: today,
    );

    final profile =
        await PhysiologyProfileStorageService.loadProfile(athlete.id) ??
        AthletePhysiologyProfile(athleteId: athlete.id);

    final logs = await DailyLogStorageService.loadLogs(athlete.id);

    final result = await DailyTrainingPipelineService.run(
      athlete: athlete,
      athleteContext: athleteContext,
      profile: profile,
      initialLogs: logs,
      date: today,
      useCache: false,
    );

    await assignmentService.saveDraft(
      athleteId: athlete.id,
      day: result.adjustedDay,
    );

    if (sendToAthlete) {
      await assignmentService.sendToday(athlete.id);
    }

    final historyText = orderedHistory.length > 1
        ? ' Historial cargado: ${orderedHistory.length} registros.'
        : '';

    return GarminContextSyncResult(
      success: true,
      message:
          '${sync.message}$historyText Fuente: ${sync.source}. Disponibilidad ${result.dailyState.readiness}, fatiga ${result.dailyState.fatigueStatus.toUpperCase()}. Plan diario recalculado${sendToAthlete ? ' y enviado al atleta' : ''}.',
    );
  }

  static Future<WearableSyncResult> _syncFromExternalWearable({
    required WearableDailyData externalWearableData,
    required String externalSource,
  }) async {
    final imported = await GarminTrainingBridge.loadLatestTraining(
      athleteId: externalWearableData.source,
    );

    final importedHistory = imported.recentTrainings
        .map(GarminWearableMapper.toWearableData)
        .where((item) {
          return item.trainingLoad > 0 ||
              item.totalTrainingMinutes > 0 ||
              item.totalDistanceKm > 0 ||
              item.totalZoneMinutes > 0;
        })
        .toList();

    importedHistory.removeWhere((item) {
      return item.date.year == externalWearableData.date.year &&
          item.date.month == externalWearableData.date.month &&
          item.date.day == externalWearableData.date.day;
    });

    importedHistory.add(externalWearableData);
    importedHistory.sort((a, b) => a.date.compareTo(b.date));

    return WearableSyncResult(
      success: true,
      provider: 'Garmin',
      source: externalSource,
      message: 'Garmin sincronizado desde backend normalizado.',
      wearable: externalWearableData,
      history: importedHistory,
    );
  }
}
