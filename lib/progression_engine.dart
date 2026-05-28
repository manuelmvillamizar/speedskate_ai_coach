class ProgressionEngine {
  static double nextWeight({
    required double currentWeight,
    required String level,
    required String athleteType,
  }) {
    double increase = 0;

    if (level == 'Novato') increase = 2.5;
    if (level == 'Competitivo') increase = 5;
    if (level == 'Elite') increase = 2.5;

    if (athleteType == 'Velocista') increase += 2.5;

    return currentWeight + increase;
  }

  static double deload(double currentWeight) {
    return currentWeight * 0.8;
  }
}


