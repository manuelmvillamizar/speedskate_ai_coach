import '../training_library/gym/gym_exercise_parser.dart';
import 'models/strength_load_state.dart';

class StrengthLoadCalculator {
  static StrengthLoadState calculate({
    required List<GymExerciseParsed> exercises,
    required double athleteWeightKg,
  }) {
    double externalStrengthLoadKg = 0;
    double reactiveJumpLoadKg = 0;

    double neuralStress = 0;
    double muscleStress = 0;
    double tendonStress = 0;

    for (final exercise in exercises) {
      final sets = _extractSets(exercise.prescription);
      final reps = _extractReps(exercise.prescription);

      final load = _extractLoad(exercise);

      final totalVolume = sets * reps * load;

      externalStrengthLoadKg += totalVolume;

      if (exercise.explosive) {
        reactiveJumpLoadKg +=
            (athleteWeightKg * reps * sets * 1.8);
      }

      // =====================================================
      // NEURAL STRESS
      // =====================================================

      if (exercise.explosive) {
        neuralStress += 12;
      }

      if (_isHeavy(exercise)) {
        neuralStress += 10;
      }

      if (_isMaxStrength(exercise)) {
        neuralStress += 15;
      }

      // =====================================================
      // MUSCLE STRESS
      // =====================================================

      muscleStress += (totalVolume / 1200);

      if (reps >= 10) {
        muscleStress += 8;
      }

      // =====================================================
      // TENDON STRESS
      // =====================================================

      if (exercise.explosive) {
        tendonStress += 14;
      }

      if (exercise.unilateral) {
        tendonStress += 6;
      }

      if (_isReactive(exercise)) {
        tendonStress += 10;
      }
    }

    final totalMechanicalLoadKg =
        externalStrengthLoadKg +
            reactiveJumpLoadKg;

    neuralStress =
        neuralStress.clamp(0, 100);

    muscleStress =
        muscleStress.clamp(0, 100);

    tendonStress =
        tendonStress.clamp(0, 100);

    return StrengthLoadState(
      externalStrengthLoadKg:
          externalStrengthLoadKg.roundToDouble(),

      reactiveJumpLoadKg:
          reactiveJumpLoadKg.roundToDouble(),

      totalMechanicalLoadKg:
          totalMechanicalLoadKg.roundToDouble(),

      neuralStress:
    neuralStress.roundToDouble(),

muscleStress:
    muscleStress.roundToDouble(),

tendonStress:
    tendonStress.roundToDouble(),

      adaptationSignal: _signal(
        neuralStress: neuralStress,
        muscleStress: muscleStress,
        tendonStress: tendonStress,
      ),
    );
  }

  static int _extractSets(String? prescription) {
    if (prescription == null) return 3;

    final match = RegExp(
      r'(\d+)\s*[x�]\s*(\d+)',
    ).firstMatch(prescription);

    if (match == null) return 3;

    return int.tryParse(
          match.group(1) ?? '',
        ) ??
        3;
  }

  static int _extractReps(String? prescription) {
    if (prescription == null) return 6;

    final match = RegExp(
      r'(\d+)\s*[x�]\s*(\d+)',
    ).firstMatch(prescription);

    if (match == null) return 6;

    return int.tryParse(
          match.group(2) ?? '',
        ) ??
        6;
  }

  static double _extractLoad(
    GymExerciseParsed exercise,
  ) {
    final percentage =
        exercise.percentage;

    if (percentage != null) {
      final value = percentage
          .replaceAll('%', '')
          .trim();

      final pct =
          double.tryParse(value);

      if (pct != null) {
        return pct * 1.2;
      }
    }

    if (exercise.rpe != null) {
      return 85;
    }

    if (exercise.explosive) {
      return 45;
    }

    return 60;
  }

  static bool _isHeavy(
    GymExerciseParsed exercise,
  ) {
    if (exercise.rpe == null) return false;

    return exercise.rpe!
        .contains('8');
  }

  static bool _isMaxStrength(
    GymExerciseParsed exercise,
  ) {
    final pct = exercise.percentage;

    if (pct == null) return false;

    final value = double.tryParse(
      pct.replaceAll('%', '').trim(),
    );

    if (value == null) return false;

    return value >= 85;
  }

  static bool _isReactive(
    GymExerciseParsed exercise,
  ) {
    return exercise.explosive &&
        exercise.physiologicalGoal != null;
  }

  static String _signal({
    required double neuralStress,
    required double muscleStress,
    required double tendonStress,
  }) {
    if (neuralStress >= 80 ||
        tendonStress >= 80) {
      return 'requires_recovery';
    }

    if (muscleStress >= 65) {
      return 'controlled_strength_stimulus';
    }

    if (neuralStress >= 60 &&
        muscleStress < 60) {
      return 'neural_power_stimulus';
    }

    return 'normal_strength_stimulus';
  }
}


