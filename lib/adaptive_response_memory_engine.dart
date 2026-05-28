import 'adaptive_response_memory.dart';
import 'daily_athlete_log.dart';
import 'wearable_integration_service.dart';
import 'physiology/models/strength_load_state.dart';

class AdaptiveResponseMemoryEngine {
  static AdaptiveResponseMemory update({
    required AdaptiveResponseMemory memory,
    required WearableDailyData wearableData,
    required DailyAthleteLog? previousLog,
    required int readiness,
    required int soreness,
    required StrengthLoadState strengthLoadState,
  }) {
    final response = _classifyResponse(
      wearableData: wearableData,
      readiness: readiness,
      soreness: soreness,
    );

    var updated = memory;

    if (previousLog != null) {
      updated = _learnFromPreviousSession(
        memory: updated,
        previousLog: previousLog,
        response: response,
      );
    }

    updated = _learnFromStrengthLoad(
      memory: updated,
      strengthLoadState: strengthLoadState,
      response: response,
    );

    return updated.copyWith(
      positiveResponses:
          updated.positiveResponses + (response == _AdaptiveResponse.good ? 1 : 0),
      negativeResponses:
          updated.negativeResponses + (response == _AdaptiveResponse.poor ? 1 : 0),
      lastUpdated: DateTime.now(),
    );
  }

  static _AdaptiveResponse _classifyResponse({
    required WearableDailyData wearableData,
    required int readiness,
    required int soreness,
  }) {
    var score = 0;

    if (readiness >= 78) {
      score += 2;
    } else if (readiness < 60) {
      score -= 2;
    }

    if (soreness <= 4) {
      score += 1;
    } else if (soreness >= 7) {
      score -= 2;
    }

    if (wearableData.sleepHours >= 7.5) {
      score += 1;
    } else if (wearableData.sleepHours < 6) {
      score -= 1;
    }

    if (wearableData.stress <= 40) {
      score += 1;
    } else if (wearableData.stress >= 70) {
      score -= 1;
    }

    if (score >= 2) {
      return _AdaptiveResponse.good;
    }

    if (score <= -2) {
      return _AdaptiveResponse.poor;
    }

    return _AdaptiveResponse.neutral;
  }

  static AdaptiveResponseMemory _learnFromPreviousSession({
    required AdaptiveResponseMemory memory,
    required DailyAthleteLog previousLog,
    required _AdaptiveResponse response,
  }) {
    var sprintTolerance = memory.sprintTolerance;
    var lactateTolerance = memory.lactateTolerance;
    var doubleSessionTolerance = memory.doubleSessionTolerance;
    var z5Tolerance = memory.z5Tolerance;

    final sessionType = previousLog.performedSessionType.toLowerCase();

    final isSprint = sessionType.contains('speed') ||
        sessionType.contains('sprint') ||
        sessionType.contains('velocidad') ||
        sessionType.contains('aceleracion');

    final isLactate = sessionType.contains('lactate') ||
        sessionType.contains('lactato') ||
        sessionType.contains('anaerobic') ||
        previousLog.highIntensityMinutes >= 25;

    final isDoubleSession = previousLog.performedMinutes >= 100 ||
        previousLog.performedLoad >= 85;

    final hasZ5 = previousLog.zone5Minutes >= 8;

    if (isSprint) {
      sprintTolerance = _adjustTolerance(sprintTolerance, response);
    }

    if (isLactate) {
      lactateTolerance = _adjustTolerance(lactateTolerance, response);
    }

    if (isDoubleSession) {
      doubleSessionTolerance =
          _adjustTolerance(doubleSessionTolerance, response);
    }

    if (hasZ5) {
      z5Tolerance = _adjustTolerance(z5Tolerance, response);
    }

    return memory.copyWith(
      sprintTolerance: sprintTolerance,
      lactateTolerance: lactateTolerance,
      doubleSessionTolerance: doubleSessionTolerance,
      z5Tolerance: z5Tolerance,
    );
  }

  static AdaptiveResponseMemory _learnFromStrengthLoad({
    required AdaptiveResponseMemory memory,
    required StrengthLoadState strengthLoadState,
    required _AdaptiveResponse response,
  }) {
    var gymTolerance = memory.gymTolerance;
    var jumpTolerance = memory.jumpTolerance;
    var taperResponse = memory.taperResponse;

    final hasGymLoad = strengthLoadState.externalStrengthLoadKg > 0 ||
        strengthLoadState.totalMechanicalLoadKg > 0;

    final hasJumpLoad = strengthLoadState.reactiveJumpLoadKg > 0 ||
        strengthLoadState.tendonStress >= 50;

    if (hasGymLoad) {
      gymTolerance = _adjustTolerance(gymTolerance, response);
    }

    if (hasJumpLoad) {
      jumpTolerance = _adjustTolerance(jumpTolerance, response);
    }

    if (strengthLoadState.adaptationSignal == 'controlled_strength_stimulus' &&
        response == _AdaptiveResponse.good) {
      taperResponse = (taperResponse + 0.005).clamp(0.70, 1.30).toDouble();
    }

    return memory.copyWith(
      gymTolerance: gymTolerance,
      jumpTolerance: jumpTolerance,
      taperResponse: taperResponse,
    );
  }

  static double _adjustTolerance(
    double current,
    _AdaptiveResponse response,
  ) {
    switch (response) {
      case _AdaptiveResponse.good:
        return (current + 0.015).clamp(0.70, 1.30).toDouble();

      case _AdaptiveResponse.poor:
        return (current - 0.025).clamp(0.70, 1.30).toDouble();

      case _AdaptiveResponse.neutral:
        return current;
    }
  }
}

enum _AdaptiveResponse {
  good,
  neutral,
  poor,
}


