import '../../garmin_connection_service.dart';
import '../../wearable_integration_service.dart';
import 'garmin_data_fusion_mapper.dart';
import 'garmin_training_bridge.dart';
import 'garmin_wearable_mapper.dart';

class WearableSyncResult {
  final bool success;
  final String provider;
  final String source;
  final String message;
  final WearableDailyData? wearable;
  final List<WearableDailyData> history;

  const WearableSyncResult({
    required this.success,
    required this.provider,
    required this.source,
    required this.message,
    required this.wearable,
    this.history = const [],
  });
}

class WearableSyncOrchestrator {
  static Future<WearableSyncResult> syncGarmin({
    required String athleteId,
  }) async {
    WearableDailyData? dailySummary;

    try {
      dailySummary = await GarminConnectionService.fetchToday(
        athleteId: athleteId,
      );
    } catch (_) {
      dailySummary = null;
    }

    final imported = await GarminTrainingBridge.loadLatestTraining(
      athleteId: athleteId,
    );

    final latestTraining = imported.hasTraining ? imported.training : null;

    final fused = GarminDataFusionMapper.fuse(
      dailySummary: dailySummary,
      latestTraining: latestTraining,
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

    if (fused != null) {
      importedHistory.removeWhere((item) {
        return item.date.year == fused.date.year &&
            item.date.month == fused.date.month &&
            item.date.day == fused.date.day;
      });

      importedHistory.add(fused);
    }

    importedHistory.sort((a, b) => a.date.compareTo(b.date));

    if (fused == null && importedHistory.isEmpty) {
      return const WearableSyncResult(
        success: false,
        provider: 'Garmin',
        source: 'none',
        message:
            'No se pudo obtener Garmin real ni entrenamiento Garmin importado.',
        wearable: null,
      );
    }

    final source = dailySummary != null && latestTraining != null
        ? 'garmin_daily_real_plus_training_import'
        : dailySummary != null
        ? 'garmin_daily_real'
        : latestTraining != null
        ? 'garmin_training_import'
        : importedHistory.isNotEmpty
        ? 'garmin_recent_training_import'
        : 'none';

    return WearableSyncResult(
      success: true,
      provider: 'Garmin',
      source: source,
      message: _messageForSource(source, importedHistory.length),
      wearable: fused ?? importedHistory.last,
      history: importedHistory,
    );
  }

  static String _messageForSource(String source, int historyCount) {
    final historyText = historyCount > 1
        ? ' Historial importado: $historyCount registros.'
        : '';

    switch (source) {
      case 'garmin_daily_real_plus_training_import':
        return 'Garmin sincronizado con datos diarios reales y entrenamiento realizado.$historyText';
      case 'garmin_daily_real':
        return 'Garmin sincronizado con datos diarios reales.$historyText';
      case 'garmin_training_import':
        return 'Garmin sincronizado usando entrenamiento importado como respaldo.$historyText';
      case 'garmin_recent_training_import':
        return 'Garmin sincronizado usando historial reciente importado.$historyText';
      default:
        return 'Garmin sincronizado.$historyText';
    }
  }
}
