enum TrainingLibraryCategory {
  speed,
  acceleration,
  maxVelocity,
  lactate,
  endurance,
  tempo,
  technical,
  tactical,
  strength,
  power,
  plyometric,
  core,
  mobility,
  recovery,
  cycling,
  test,
  prehab,
}

enum TrainingLibraryModality { sprinter, endurance, mixed, universal }

enum TrainingSessionIntensity { recovery, low, moderate, high, maximal }

class TrainingSessionTemplate {
  final String id;
  final int number;
  final String title;

  final TrainingLibraryCategory category;
  final TrainingLibraryModality modality;
  final TrainingSessionIntensity intensity;

  final String objective;
  final String type;

  final List<String> warmup;
  final List<String> mainSet;
  final List<String> complementary;
  final List<String> technicalCues;
  final List<String> commonErrors;
  final List<String> cutCriteria;
  final String coachNotes;

  final bool skatingSession;
  final bool gymSession;
  final bool cyclingSession;
  final bool recoverySession;

  final bool neuralFocused;
  final bool metabolicFocused;
  final bool reactiveFocused;
  final bool technicalFocused;
  final bool taperCompatible;

  final List<String> tags;

  const TrainingSessionTemplate({
    required this.id,
    required this.number,
    required this.title,
    required this.category,
    required this.modality,
    required this.intensity,
    required this.objective,
    required this.type,
    required this.warmup,
    required this.mainSet,
    required this.complementary,
    required this.technicalCues,
    required this.commonErrors,
    required this.cutCriteria,
    required this.coachNotes,
    required this.skatingSession,
    required this.gymSession,
    required this.cyclingSession,
    required this.recoverySession,
    required this.neuralFocused,
    required this.metabolicFocused,
    required this.reactiveFocused,
    required this.technicalFocused,
    required this.taperCompatible,
    required this.tags,
  });

  bool get isHighIntensity {
    return intensity == TrainingSessionIntensity.high ||
        intensity == TrainingSessionIntensity.maximal;
  }

  bool get isLowStress {
    return intensity == TrainingSessionIntensity.recovery ||
        intensity == TrainingSessionIntensity.low;
  }

  bool get isSpeedRelated {
    return category == TrainingLibraryCategory.speed ||
        category == TrainingLibraryCategory.acceleration ||
        category == TrainingLibraryCategory.maxVelocity;
  }

  bool get isEnduranceRelated {
    return category == TrainingLibraryCategory.endurance ||
        category == TrainingLibraryCategory.tempo ||
        category == TrainingLibraryCategory.tactical;
  }

  bool get isStrengthRelated {
    return category == TrainingLibraryCategory.strength ||
        category == TrainingLibraryCategory.power ||
        category == TrainingLibraryCategory.core ||
        category == TrainingLibraryCategory.prehab;
  }

  bool get isRecoveryCompatible {
    return recoverySession ||
        category == TrainingLibraryCategory.recovery ||
        category == TrainingLibraryCategory.mobility ||
        intensity == TrainingSessionIntensity.recovery;
  }

  bool matchesModality(TrainingLibraryModality target) {
    return modality == TrainingLibraryModality.universal ||
        target == TrainingLibraryModality.universal ||
        modality == target;
  }

  bool hasTag(String value) {
    final target = value.toLowerCase().trim();

    return tags.any((tag) => tag.toLowerCase().trim() == target);
  }

  String get categoryName {
    return category.name;
  }

  String get modalityName {
    return modality.name;
  }

  String get intensityName {
    return intensity.name;
  }
}


