enum TrainingBlockType {
  skating,
  strength,
  cycling,
  recovery,
  mobility,
  activation,
  technical,
  aerobic,
}

enum TrainingBlockMoment { morning, afternoon, evening }

enum TrainingStimulus {
  recovery,
  mobility,
  technical,
  aerobic,
  anaerobic,
  lactateTolerance,
  neuromuscular,
  maxStrength,
  power,
  strengthEndurance,
  plyometric,
  speed,
  tactical,
}

enum TrainingEnergySystem {
  none,
  aerobic,
  anaerobicAlactic,
  anaerobicLactic,
  mixed,
}

enum NeuromuscularLoad { none, low, moderate, high, maximal }

class DailyTrainingBlock {
  final TrainingBlockType type;
  final TrainingBlockMoment moment;
  final String title;
  final String description;
  final int durationMinutes;
  final double km;
  final int targetLoad;
  final int targetHeartRateZone;
  final bool recoveryFocused;
  final bool taperFocused;
  final String aiReason;

  final TrainingStimulus stimulus;
  final TrainingEnergySystem energySystem;
  final NeuromuscularLoad neuromuscularLoad;

  // =========================
  // PLAN PROFESIONAL DETALLADO
  // =========================

  final List<String> warmup;
  final List<String> mainSet;
  final List<String> exercises;
  final List<String> strengthExercises;
  final List<String> plyometricExercises;
  final List<String> technicalCues;
  final List<String> tacticalCues;
  final List<String> cooldown;
  final List<String> coachingNotes;
  final List<String> stopCriteria;

  const DailyTrainingBlock({
    required this.type,
    required this.moment,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.km,
    required this.targetLoad,
    required this.targetHeartRateZone,
    required this.recoveryFocused,
    required this.taperFocused,
    required this.aiReason,
    this.stimulus = TrainingStimulus.technical,
    this.energySystem = TrainingEnergySystem.mixed,
    this.neuromuscularLoad = NeuromuscularLoad.low,
    this.warmup = const [],
    this.mainSet = const [],
    this.exercises = const [],
    this.strengthExercises = const [],
    this.plyometricExercises = const [],
    this.technicalCues = const [],
    this.tacticalCues = const [],
    this.cooldown = const [],
    this.coachingNotes = const [],
    this.stopCriteria = const [],
  });

  bool get isHighNeuromuscular {
    return neuromuscularLoad == NeuromuscularLoad.high ||
        neuromuscularLoad == NeuromuscularLoad.maximal;
  }

  bool get isStrengthStimulus {
    return stimulus == TrainingStimulus.maxStrength ||
        stimulus == TrainingStimulus.power ||
        stimulus == TrainingStimulus.strengthEndurance;
  }

  bool get isSpeedStimulus {
    return stimulus == TrainingStimulus.speed ||
        stimulus == TrainingStimulus.neuromuscular ||
        stimulus == TrainingStimulus.plyometric;
  }

  bool get isRecoveryStimulus {
    return recoveryFocused ||
        stimulus == TrainingStimulus.recovery ||
        stimulus == TrainingStimulus.mobility;
  }

  bool get isMetabolicHeavy {
    return energySystem == TrainingEnergySystem.anaerobicLactic ||
        stimulus == TrainingStimulus.lactateTolerance ||
        stimulus == TrainingStimulus.anaerobic;
  }

  bool get hasProfessionalDetails {
    return warmup.isNotEmpty ||
        mainSet.isNotEmpty ||
        exercises.isNotEmpty ||
        strengthExercises.isNotEmpty ||
        plyometricExercises.isNotEmpty ||
        technicalCues.isNotEmpty ||
        tacticalCues.isNotEmpty ||
        cooldown.isNotEmpty ||
        coachingNotes.isNotEmpty ||
        stopCriteria.isNotEmpty;
  }

  DailyTrainingBlock copyWith({
    TrainingBlockType? type,
    TrainingBlockMoment? moment,
    String? title,
    String? description,
    int? durationMinutes,
    double? km,
    int? targetLoad,
    int? targetHeartRateZone,
    bool? recoveryFocused,
    bool? taperFocused,
    String? aiReason,
    TrainingStimulus? stimulus,
    TrainingEnergySystem? energySystem,
    NeuromuscularLoad? neuromuscularLoad,
    List<String>? warmup,
    List<String>? mainSet,
    List<String>? exercises,
    List<String>? strengthExercises,
    List<String>? plyometricExercises,
    List<String>? technicalCues,
    List<String>? tacticalCues,
    List<String>? cooldown,
    List<String>? coachingNotes,
    List<String>? stopCriteria,
  }) {
    return DailyTrainingBlock(
      type: type ?? this.type,
      moment: moment ?? this.moment,
      title: title ?? this.title,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      km: km ?? this.km,
      targetLoad: targetLoad ?? this.targetLoad,
      targetHeartRateZone: targetHeartRateZone ?? this.targetHeartRateZone,
      recoveryFocused: recoveryFocused ?? this.recoveryFocused,
      taperFocused: taperFocused ?? this.taperFocused,
      aiReason: aiReason ?? this.aiReason,
      stimulus: stimulus ?? this.stimulus,
      energySystem: energySystem ?? this.energySystem,
      neuromuscularLoad: neuromuscularLoad ?? this.neuromuscularLoad,
      warmup: warmup ?? this.warmup,
      mainSet: mainSet ?? this.mainSet,
      exercises: exercises ?? this.exercises,
      strengthExercises: strengthExercises ?? this.strengthExercises,
      plyometricExercises: plyometricExercises ?? this.plyometricExercises,
      technicalCues: technicalCues ?? this.technicalCues,
      tacticalCues: tacticalCues ?? this.tacticalCues,
      cooldown: cooldown ?? this.cooldown,
      coachingNotes: coachingNotes ?? this.coachingNotes,
      stopCriteria: stopCriteria ?? this.stopCriteria,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'moment': moment.name,
      'title': title,
      'description': description,
      'durationMinutes': durationMinutes,
      'km': km,
      'targetLoad': targetLoad,
      'targetHeartRateZone': targetHeartRateZone,
      'recoveryFocused': recoveryFocused,
      'taperFocused': taperFocused,
      'aiReason': aiReason,
      'stimulus': stimulus.name,
      'energySystem': energySystem.name,
      'neuromuscularLoad': neuromuscularLoad.name,
      'warmup': warmup,
      'mainSet': mainSet,
      'exercises': exercises,
      'strengthExercises': strengthExercises,
      'plyometricExercises': plyometricExercises,
      'technicalCues': technicalCues,
      'tacticalCues': tacticalCues,
      'cooldown': cooldown,
      'coachingNotes': coachingNotes,
      'stopCriteria': stopCriteria,
    };
  }

  factory DailyTrainingBlock.fromMap(Map<String, dynamic> map) {
    return DailyTrainingBlock(
      type: TrainingBlockType.values.firstWhere(
        (item) => item.name == map['type']?.toString(),
        orElse: () => TrainingBlockType.technical,
      ),
      moment: TrainingBlockMoment.values.firstWhere(
        (item) => item.name == map['moment']?.toString(),
        orElse: () => TrainingBlockMoment.morning,
      ),
      title: map['title']?.toString() ?? 'Bloque de entrenamiento',
      description: map['description']?.toString() ?? '',
      durationMinutes: (map['durationMinutes'] as num?)?.round() ?? 0,
      km: (map['km'] as num?)?.toDouble() ?? 0.0,
      targetLoad: (map['targetLoad'] as num?)?.round() ?? 0,
      targetHeartRateZone: (map['targetHeartRateZone'] as num?)?.round() ?? 1,
      recoveryFocused: map['recoveryFocused'] == true,
      taperFocused: map['taperFocused'] == true,
      aiReason: map['aiReason']?.toString() ?? '',
      stimulus: TrainingStimulus.values.firstWhere(
        (item) => item.name == map['stimulus']?.toString(),
        orElse: () => TrainingStimulus.technical,
      ),
      energySystem: TrainingEnergySystem.values.firstWhere(
        (item) => item.name == map['energySystem']?.toString(),
        orElse: () => TrainingEnergySystem.mixed,
      ),
      neuromuscularLoad: NeuromuscularLoad.values.firstWhere(
        (item) => item.name == map['neuromuscularLoad']?.toString(),
        orElse: () => NeuromuscularLoad.low,
      ),
      warmup: _stringList(map['warmup']),
      mainSet: _stringList(map['mainSet']),
      exercises: _stringList(map['exercises']),
      strengthExercises: _stringList(map['strengthExercises']),
      plyometricExercises: _stringList(map['plyometricExercises']),
      technicalCues: _stringList(map['technicalCues']),
      tacticalCues: _stringList(map['tacticalCues']),
      cooldown: _stringList(map['cooldown']),
      coachingNotes: _stringList(map['coachingNotes']),
      stopCriteria: _stringList(map['stopCriteria']),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return [];

    return value.map((item) => item.toString()).toList();
  }
}


