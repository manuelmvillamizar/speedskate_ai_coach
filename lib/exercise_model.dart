enum ExerciseCategory { strength, machine, olympic, plyometric, core, mobility }

class Exercise {
  final String name;
  final ExerciseCategory category;

  final String descriptionEs;
  final String descriptionEn;
  final String descriptionDe;

  final String muscles;
  final String level;
  final String equipment;

  final String imagePath;

  final String? gifPath;
  final String? videoPath;

  final List<String> techniqueStepsEs;
  final List<String> techniqueStepsEn;
  final List<String> techniqueStepsDe;

  final List<String> commonMistakesEs;
  final List<String> commonMistakesEn;
  final List<String> commonMistakesDe;

  final String skatingTransferEs;
  final String skatingTransferEn;
  final String skatingTransferDe;

  const Exercise({
    required this.name,
    required this.category,
    required this.descriptionEs,
    required this.descriptionEn,
    required this.descriptionDe,
    required this.muscles,
    required this.level,
    required this.equipment,
    required this.imagePath,

    this.gifPath,
    this.videoPath,

    this.techniqueStepsEs = const [],
    this.techniqueStepsEn = const [],
    this.techniqueStepsDe = const [],

    this.commonMistakesEs = const [],
    this.commonMistakesEn = const [],
    this.commonMistakesDe = const [],

    this.skatingTransferEs = '',
    this.skatingTransferEn = '',
    this.skatingTransferDe = '',
  });
}


