class StrengthLoadState {
  final double externalStrengthLoadKg;
  final double reactiveJumpLoadKg;
  final double totalMechanicalLoadKg;

  final double neuralStress;
  final double muscleStress;
  final double tendonStress;

  final String adaptationSignal;

  const StrengthLoadState({
    required this.externalStrengthLoadKg,
    required this.reactiveJumpLoadKg,
    required this.totalMechanicalLoadKg,
    required this.neuralStress,
    required this.muscleStress,
    required this.tendonStress,
    required this.adaptationSignal,
  });

  factory StrengthLoadState.empty() {
    return const StrengthLoadState(
      externalStrengthLoadKg: 0,
      reactiveJumpLoadKg: 0,
      totalMechanicalLoadKg: 0,
      neuralStress: 0,
      muscleStress: 0,
      tendonStress: 0,
      adaptationSignal: 'none',
    );
  }

  bool get hasHighNeuralStress => neuralStress >= 75;

  bool get hasHighTendonStress => tendonStress >= 75;

  bool get hasHighMuscleStress => muscleStress >= 75;

  bool get requiresRecovery =>
      hasHighNeuralStress ||
      hasHighTendonStress ||
      hasHighMuscleStress;
}


