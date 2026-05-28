class GymLoadCalculation {
  final double externalStrengthLoadKg;
  final double reactiveJumpLoadKg;
  final double totalMechanicalLoadKg;
  final double neuralStress;
  final double muscleStress;
  final double tendonStress;
  final String adaptationSignal;

  const GymLoadCalculation({
    required this.externalStrengthLoadKg,
    required this.reactiveJumpLoadKg,
    required this.totalMechanicalLoadKg,
    required this.neuralStress,
    required this.muscleStress,
    required this.tendonStress,
    required this.adaptationSignal,
  });
}

class GymLoadCalculator {
  static GymLoadCalculation calculate({
    required double athleteBodyWeightKg,
    required List<GymStrengthSetInput> strengthSets,
    required List<GymJumpSetInput> jumpSets,
  }) {
    double externalStrengthLoad = 0;
    double reactiveJumpLoad = 0;

    double neuralStress = 0;
    double muscleStress = 0;
    double tendonStress = 0;

    for (final set in strengthSets) {
      final setLoad = set.series * set.reps * set.externalWeightKg;
      externalStrengthLoad += setLoad;

      final intensityFactor = _intensityFactor(set.intensityPercent);
      final rpeFactor = _rpeFactor(set.rpe);

      neuralStress += setLoad * intensityFactor * rpeFactor * 0.0012;
      muscleStress += setLoad * 0.0010;
      tendonStress += setLoad * 0.00055;
    }

    for (final set in jumpSets) {
      final jumpLoad =
          set.contacts * athleteBodyWeightKg * set.reactivityMultiplier;

      reactiveJumpLoad += jumpLoad;

      neuralStress += jumpLoad * 0.0016;
      muscleStress += jumpLoad * 0.0007;
      tendonStress += jumpLoad * 0.0014;
    }

    final totalMechanicalLoad = externalStrengthLoad + reactiveJumpLoad;

    neuralStress = neuralStress.clamp(0, 100);
    muscleStress = muscleStress.clamp(0, 100);
    tendonStress = tendonStress.clamp(0, 100);

    return GymLoadCalculation(
      externalStrengthLoadKg: externalStrengthLoad,
      reactiveJumpLoadKg: reactiveJumpLoad,
      totalMechanicalLoadKg: totalMechanicalLoad,
      neuralStress: neuralStress,
      muscleStress: muscleStress,
      tendonStress: tendonStress,
      adaptationSignal: _adaptationSignal(
        neuralStress: neuralStress,
        muscleStress: muscleStress,
        tendonStress: tendonStress,
      ),
    );
  }

  static double _intensityFactor(double? percent) {
    if (percent == null || percent <= 0) return 1.0;
    if (percent >= 90) return 1.45;
    if (percent >= 80) return 1.25;
    if (percent >= 70) return 1.10;
    if (percent >= 60) return 1.00;
    return 0.85;
  }

  static double _rpeFactor(double? rpe) {
    if (rpe == null || rpe <= 0) return 1.0;
    if (rpe >= 9) return 1.35;
    if (rpe >= 8) return 1.20;
    if (rpe >= 7) return 1.10;
    return 1.0;
  }

  static String _adaptationSignal({
    required double neuralStress,
    required double muscleStress,
    required double tendonStress,
  }) {
    if (neuralStress >= 75 || tendonStress >= 75) {
      return 'high_neuromuscular_risk';
    }

    if (muscleStress >= 70) {
      return 'high_muscular_load';
    }

    if (neuralStress >= 50 || tendonStress >= 50) {
      return 'moderate_neural_tendon_load';
    }

    return 'controlled_strength_stimulus';
  }
}

class GymStrengthSetInput {
  final int series;
  final int reps;
  final double externalWeightKg;
  final double? intensityPercent;
  final double? rpe;

  const GymStrengthSetInput({
    required this.series,
    required this.reps,
    required this.externalWeightKg,
    this.intensityPercent,
    this.rpe,
  });
}

class GymJumpSetInput {
  final int contacts;
  final double reactivityMultiplier;

  const GymJumpSetInput({
    required this.contacts,
    this.reactivityMultiplier = 1.0,
  });
}


