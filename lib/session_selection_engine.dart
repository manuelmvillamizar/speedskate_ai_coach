import 'athlete_adaptation_layer.dart';
import 'athlete_performance_context.dart';
import 'athlete_program_service.dart';

import 'training_library/master_training_library.dart';
import 'training_library/training_library_models.dart';

class SessionSelectionResult {
  final TrainingSessionTemplate session;
  final double score;
  final List<String> reasons;

  const SessionSelectionResult({
    required this.session,
    required this.score,
    required this.reasons,
  });
}

class SessionSelectionEngine {
  static SessionSelectionResult? selectSession({
    required AthletePerformanceContext context,
    required TrainingLibraryCategory category,
    required bool needsNeural,
    required bool needsMetabolic,
    required bool taperMode,
  }) {
    final adaptation = AthleteAdaptationLayer.build(context);
    final athlete = context.athlete;

    final readiness = context.currentReadiness;
    final injuryRisk = context.currentInjuryRisk;
    final fatigue = context.currentFatigueStatus;
    final acwr = context.acwr;

    var candidates = MasterTrainingLibrary.sessions.where((session) {
      if (session.category != category) return false;

      if (!_modalityCompatible(session, athlete.type)) return false;

      if (taperMode && !session.taperCompatible) return false;

      if (needsNeural && !session.neuralFocused) return false;

      if (needsMetabolic && !session.metabolicFocused) return false;

      return true;
    }).toList();

    if (candidates.isEmpty) {
      candidates = MasterTrainingLibrary.sessions.where((session) {
        return session.category == category &&
            _modalityCompatible(session, athlete.type);
      }).toList();
    }

    if (candidates.isEmpty) {
      candidates = MasterTrainingLibrary.sessions.where((session) {
        return _modalityCompatible(session, athlete.type);
      }).toList();
    }

    if (candidates.isEmpty) return null;

    double bestScore = -9999;
    TrainingSessionTemplate? bestSession;
    List<String> bestReasons = [];

    for (final session in candidates) {
      final evaluation = _scoreSession(
        session: session,
        context: context,
        adaptation: adaptation,
        readiness: readiness,
        injuryRisk: injuryRisk,
        fatigue: fatigue,
        acwr: acwr,
        taperMode: taperMode,
        needsNeural: needsNeural,
        needsMetabolic: needsMetabolic,
      );

      if (evaluation.score > bestScore) {
        bestScore = evaluation.score;
        bestSession = session;
        bestReasons = evaluation.reasons;
      }
    }

    if (bestSession == null) return null;

    return SessionSelectionResult(
      session: bestSession,
      score: bestScore,
      reasons: bestReasons,
    );
  }

  static _SessionEvaluation _scoreSession({
    required TrainingSessionTemplate session,
    required AthletePerformanceContext context,
    required AthleteAdaptationProfile adaptation,
    required int readiness,
    required double injuryRisk,
    required String fatigue,
    required double acwr,
    required bool taperMode,
    required bool needsNeural,
    required bool needsMetabolic,
  }) {
    double score = 50;
    final reasons = <String>[];

    if (_modalityCompatible(session, context.athlete.type)) {
      score += 20;
      reasons.add('Compatible con la modalidad del atleta.');
    }

    if (session.technicalFocused) {
      score += 6;
      reasons.add('Incluye componente técnico.');
    }

    if (needsNeural && session.neuralFocused) {
      score += 18;
      reasons.add('Cumple necesidad neural del día.');
    }

    if (needsMetabolic && session.metabolicFocused) {
      score += 18;
      reasons.add('Cumple necesidad metabólica del día.');
    }

    if (taperMode && session.taperCompatible) {
      score += 28;
      reasons.add('Compatible con taper.');
    }

    if (readiness >= 80) {
      if (_isHighIntensity(session)) {
        score += 14;
        reasons.add('Readiness alto permite sesión de calidad.');
      }
    }

    if (readiness < 70) {
      if (_isHighIntensity(session)) {
        score -= 28;
        reasons.add('Readiness bajo penaliza intensidad alta.');
      }

      if (session.technicalFocused || session.recoverySession) {
        score += 16;
        reasons.add('Readiness bajo favorece técnica o recuperación.');
      }
    }

    if (readiness < 55) {
      if (session.neuralFocused || session.metabolicFocused) {
        score -= 45;
        reasons.add('Readiness muy bajo limita carga neural/metabólica.');
      }
    }

    if (fatigue == 'orange' || fatigue == 'red') {
      if (_isHighIntensity(session)) {
        score -= 35;
        reasons.add('Fatiga elevada penaliza intensidad alta.');
      }

      if (_isLowStress(session)) {
        score += 22;
        reasons.add('Fatiga elevada favorece baja carga.');
      }
    }

    if (injuryRisk >= 60) {
      if (session.reactiveFocused ||
          session.intensity == TrainingSessionIntensity.maximal) {
        score -= 40;
        reasons.add('Riesgo de lesión alto penaliza carga reactiva/máxima.');
      }

      if (session.category == TrainingLibraryCategory.mobility ||
          session.category == TrainingLibraryCategory.prehab ||
          session.category == TrainingLibraryCategory.recovery) {
        score += 25;
        reasons.add('Riesgo alto favorece movilidad, prehab o recuperación.');
      }
    }

    if (acwr > 1.5) {
      if (session.metabolicFocused || _isHighIntensity(session)) {
        score -= 25;
        reasons.add('ACWR alto penaliza carga metabólica/intensa.');
      }

      if (_isLowStress(session)) {
        score += 18;
        reasons.add('ACWR alto favorece sesión de descarga.');
      }
    }

    if (adaptation.toleratesNeuralLoad && session.neuralFocused) {
      score += 12;
      reasons.add('Perfil adaptativo tolera carga neural.');
    }

    if (adaptation.strugglesWithLactate && session.metabolicFocused) {
      score -= 18;
      reasons.add('Perfil sensible a lactato penaliza carga metabólica.');
    }

    if (adaptation.needsReactiveProtection && session.reactiveFocused) {
      score -= 18;
      reasons.add('Necesita protección reactiva.');
    }

    if (adaptation.needsLongerTaper && taperMode && session.taperCompatible) {
      score += 10;
      reasons.add('Necesita taper conservador.');
    }

    if (reasons.isEmpty) {
      reasons.add('Sesión seleccionada por compatibilidad general.');
    }

    return _SessionEvaluation(score: score, reasons: reasons);
  }

  static bool _modalityCompatible(
    TrainingSessionTemplate session,
    AthleteProgramType athleteType,
  ) {
    if (session.modality == TrainingLibraryModality.universal) return true;

    if (athleteType == AthleteProgramType.sprinter) {
      return session.modality == TrainingLibraryModality.sprinter ||
          session.modality == TrainingLibraryModality.mixed;
    }

    if (athleteType == AthleteProgramType.endurance) {
      return session.modality == TrainingLibraryModality.endurance ||
          session.modality == TrainingLibraryModality.mixed;
    }

    return session.modality == TrainingLibraryModality.mixed ||
        session.modality == TrainingLibraryModality.sprinter ||
        session.modality == TrainingLibraryModality.endurance ||
        session.modality == TrainingLibraryModality.universal;
  }

  static bool _isHighIntensity(TrainingSessionTemplate session) {
    return session.intensity == TrainingSessionIntensity.high ||
        session.intensity == TrainingSessionIntensity.maximal;
  }

  static bool _isLowStress(TrainingSessionTemplate session) {
    return session.intensity == TrainingSessionIntensity.recovery ||
        session.intensity == TrainingSessionIntensity.low ||
        session.recoverySession ||
        session.category == TrainingLibraryCategory.recovery ||
        session.category == TrainingLibraryCategory.mobility ||
        session.category == TrainingLibraryCategory.cycling ||
        session.category == TrainingLibraryCategory.prehab;
  }
}

class _SessionEvaluation {
  final double score;
  final List<String> reasons;

  const _SessionEvaluation({required this.score, required this.reasons});
}


