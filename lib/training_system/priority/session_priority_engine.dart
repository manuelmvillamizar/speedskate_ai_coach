import '../../training_library/training_library_models.dart';

class SessionPriorityScore {
  final TrainingSessionTemplate session;
  final double score;
  final List<String> reasons;

  const SessionPriorityScore({
    required this.session,
    required this.score,
    required this.reasons,
  });
}

class SessionPriorityEngine {
  static List<SessionPriorityScore> rankSessions({
    required List<TrainingSessionTemplate> candidates,
    required TrainingLibraryModality targetModality,
    required double readiness,
    required double acwr,
    required bool taperPhase,
    required bool needsNeuralStimulus,
    required bool needsMetabolicStimulus,
    required bool protectReactiveLoad,
    int limit = 10,
  }) {
    final scored = candidates.map((session) {
      double score = 50;
      final reasons = <String>[];

      if (session.matchesModality(targetModality)) {
        score += 18;
        reasons.add('Compatible con modalidad.');
      }

      if (taperPhase && session.taperCompatible) {
        score += 18;
        reasons.add('Compatible con taper.');
      }

      if (taperPhase && !session.taperCompatible) {
        score -= 35;
        reasons.add('Penalizada por taper.');
      }

      if (needsNeuralStimulus && session.neuralFocused) {
        score += 16;
        reasons.add('Aporta estímulo neural.');
      }

      if (needsNeuralStimulus && !session.neuralFocused) {
        score -= 6;
      }

      if (needsMetabolicStimulus && session.metabolicFocused) {
        score += 16;
        reasons.add('Aporta estímulo metabólico.');
      }

      if (needsMetabolicStimulus && !session.metabolicFocused) {
        score -= 6;
      }

      if (protectReactiveLoad && session.reactiveFocused) {
        score -= 28;
        reasons.add('Penalizada por protección reactiva.');
      }

      if (readiness < 0.45) {
        if (session.recoverySession ||
            session.intensity == TrainingSessionIntensity.recovery) {
          score += 28;
          reasons.add('Adecuada para readiness bajo.');
        }

        if (session.intensity == TrainingSessionIntensity.high ||
            session.intensity == TrainingSessionIntensity.maximal) {
          score -= 35;
          reasons.add('Penalizada por readiness bajo.');
        }
      }

      if (readiness >= 0.75) {
        if (session.neuralFocused || session.metabolicFocused) {
          score += 8;
          reasons.add('Readiness alto permite estímulo de calidad.');
        }
      }

      if (acwr > 1.45) {
        if (session.recoverySession ||
            session.intensity == TrainingSessionIntensity.recovery) {
          score += 22;
          reasons.add('ACWR alto favorece recuperación.');
        }

        if (session.metabolicFocused || session.neuralFocused) {
          score -= 25;
          reasons.add('Penalizada por ACWR alto.');
        }
      }

      if (session.technicalFocused) {
        score += 6;
        reasons.add('Refuerza calidad técnica.');
      }

      if (session.recoverySession && readiness >= 0.80 && !taperPhase) {
        score -= 8;
        reasons.add('Menor prioridad si el atleta está fresco.');
      }

      score = score.clamp(0, 100);

      return SessionPriorityScore(
        session: session,
        score: score,
        reasons: reasons,
      );
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));

    if (scored.length <= limit) {
      return scored;
    }

    return scored.sublist(0, limit);
  }

  static SessionPriorityScore? bestSession({
    required List<TrainingSessionTemplate> candidates,
    required TrainingLibraryModality targetModality,
    required double readiness,
    required double acwr,
    required bool taperPhase,
    required bool needsNeuralStimulus,
    required bool needsMetabolicStimulus,
    required bool protectReactiveLoad,
  }) {
    final ranked = rankSessions(
      candidates: candidates,
      targetModality: targetModality,
      readiness: readiness,
      acwr: acwr,
      taperPhase: taperPhase,
      needsNeuralStimulus: needsNeuralStimulus,
      needsMetabolicStimulus: needsMetabolicStimulus,
      protectReactiveLoad: protectReactiveLoad,
      limit: 1,
    );

    if (ranked.isEmpty) return null;

    return ranked.first;
  }
}


