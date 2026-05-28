import '../../training_library/training_library_models.dart';

class SessionConstraintsResult {
  final bool allowed;
  final List<String> reasons;

  const SessionConstraintsResult({
    required this.allowed,
    required this.reasons,
  });
}

class SessionConstraintsEngine {
  static SessionConstraintsResult canPlaceSession({
    required TrainingSessionTemplate candidate,
    required List<TrainingSessionTemplate> sameDaySessions,
    required List<TrainingSessionTemplate> previousDaySessions,
    required double readiness,
    required double acwr,
    required bool taperPhase,
  }) {
    final reasons = <String>[];

    // =========================================================
    // READINESS PROTECTION
    // =========================================================

    if (readiness < 0.35) {
      if (candidate.intensity == TrainingSessionIntensity.high ||
          candidate.intensity == TrainingSessionIntensity.maximal) {
        reasons.add('Readiness demasiado bajo para sesión high/maximal.');
      }
    }

    // =========================================================
    // ACWR PROTECTION
    // =========================================================

    if (acwr > 1.45) {
      if (candidate.metabolicFocused || candidate.neuralFocused) {
        reasons.add('ACWR elevado: evitar carga neural/metabólica alta.');
      }
    }

    // =========================================================
    // TAPER PROTECTION
    // =========================================================

    if (taperPhase) {
      if (!candidate.taperCompatible) {
        reasons.add('Sesión no compatible con taper.');
      }
    }

    // =========================================================
    // SAME DAY STACKING
    // =========================================================

    final sameDayNeuralCount = sameDaySessions
        .where((s) => s.neuralFocused)
        .length;

    if (candidate.neuralFocused && sameDayNeuralCount >= 1) {
      reasons.add('Demasiada carga neural el mismo día.');
    }

    final sameDayMetabolicCount = sameDaySessions
        .where((s) => s.metabolicFocused)
        .length;

    if (candidate.metabolicFocused && sameDayMetabolicCount >= 2) {
      reasons.add('Demasiada carga metabólica el mismo día.');
    }

    final sameDayReactiveCount = sameDaySessions
        .where((s) => s.reactiveFocused)
        .length;

    if (candidate.reactiveFocused && sameDayReactiveCount >= 1) {
      reasons.add('Exceso de carga reactiva el mismo día.');
    }

    // =========================================================
    // REACTIVE PROTECTION
    // =========================================================

    final previousReactiveLoad = previousDaySessions
        .where((s) => s.reactiveFocused)
        .length;

    if (candidate.reactiveFocused && previousReactiveLoad >= 2) {
      reasons.add('Protección reactiva: demasiada carga reactiva acumulada.');
    }

    // =========================================================
    // HIGH INTENSITY STACKING
    // =========================================================

    final previousHighIntensity = previousDaySessions.where((s) {
      return s.intensity == TrainingSessionIntensity.high ||
          s.intensity == TrainingSessionIntensity.maximal;
    }).length;

    final candidateIsHigh =
        candidate.intensity == TrainingSessionIntensity.high ||
        candidate.intensity == TrainingSessionIntensity.maximal;

    if (candidateIsHigh && previousHighIntensity >= 2) {
      reasons.add('Demasiadas sesiones intensas acumuladas.');
    }

    // =========================================================
    // LACTATE + STRENGTH PROTECTION
    // =========================================================

    final sameDayLactate = sameDaySessions.any(
      (s) => s.category == TrainingLibraryCategory.lactate,
    );

    final candidateStrength =
        candidate.category == TrainingLibraryCategory.strength;

    if (sameDayLactate && candidateStrength) {
      reasons.add('Evitar fuerza pesada junto con lactato.');
    }

    // =========================================================
    // DOUBLE METABOLIC PROTECTION
    // =========================================================

    final previousMetabolicHigh = previousDaySessions.any(
      (s) =>
          s.metabolicFocused &&
          (s.intensity == TrainingSessionIntensity.high ||
              s.intensity == TrainingSessionIntensity.maximal),
    );

    if (candidate.metabolicFocused && previousMetabolicHigh) {
      reasons.add('Carga metabólica alta en días consecutivos.');
    }

    // =========================================================
    // ADUCTOR PROTECTION
    // =========================================================

    final adductorTags = ['adductor', 'curve', 'lateral'];

    final previousAdductorLoad = previousDaySessions.where((s) {
      return s.tags.any((tag) => adductorTags.contains(tag));
    }).length;

    final candidateAdductor = candidate.tags.any(
      (tag) => adductorTags.contains(tag),
    );

    if (candidateAdductor && previousAdductorLoad >= 2) {
      reasons.add('Protección de aductores por acumulación.');
    }

    // =========================================================
    // ACHILLES / DISTAL LOAD PROTECTION
    // =========================================================

    final distalTags = [
      'ankle',
      'achilles',
      'reactive',
      'plyometric',
      'distal-load',
    ];

    final previousDistalLoad = previousDaySessions.where((s) {
      return s.tags.any((tag) => distalTags.contains(tag));
    }).length;

    final candidateDistal = candidate.tags.any(
      (tag) => distalTags.contains(tag),
    );

    if (candidateDistal && previousDistalLoad >= 3) {
      reasons.add('Protección distal/Aquiles por acumulación.');
    }

    // =========================================================
    // RECOVERY DAY PROTECTION
    // =========================================================

    final previousRecoveryCount = previousDaySessions
        .where((s) => s.recoverySession)
        .length;

    if (previousRecoveryCount == 0 && readiness < 0.45 && candidateIsHigh) {
      reasons.add('Necesidad de recuperación antes de otra carga alta.');
    }

    // =========================================================
    // FINAL RESULT
    // =========================================================

    return SessionConstraintsResult(allowed: reasons.isEmpty, reasons: reasons);
  }
}


