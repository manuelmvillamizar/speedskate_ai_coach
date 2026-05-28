import '../infrastructure/garmin_json_importer.dart';

class GarminTrainingBridgeResult {
  final bool hasTraining;
  final GarminImportedTraining? training;
  final GarminImportedDailySummary? dailySummary;
  final List<GarminImportedTraining> recentTrainings;

  const GarminTrainingBridgeResult({
    required this.hasTraining,
    this.training,
    this.dailySummary,
    this.recentTrainings = const [],
  });
}

class GarminTrainingBridge {
  static Future<GarminTrainingBridgeResult> loadLatestTraining({
    required String athleteId,
  }) async {
    try {
      final path = 'assets/data/garmin/$athleteId/garmin_latest_training.json';

      final result = await GarminJsonImporter.readFromPath(path);

      return GarminTrainingBridgeResult(
        hasTraining: result.latestTraining != null,
        training: result.latestTraining,
        dailySummary: result.dailySummary,
        recentTrainings: result.recentTrainings,
      );
    } catch (_) {
      return const GarminTrainingBridgeResult(
        hasTraining: false,
        training: null,
        dailySummary: null,
        recentTrainings: [],
      );
    }
  }
}
