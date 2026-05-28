class AdaptiveResponseMemory {
  final String athleteId;

  final double sprintTolerance;
  final double lactateTolerance;
  final double gymTolerance;
  final double jumpTolerance;
  final double doubleSessionTolerance;
  final double taperResponse;
  final double z5Tolerance;

  final int positiveResponses;
  final int negativeResponses;

  final DateTime lastUpdated;

  const AdaptiveResponseMemory({
    required this.athleteId,
    this.sprintTolerance = 1.0,
    this.lactateTolerance = 1.0,
    this.gymTolerance = 1.0,
    this.jumpTolerance = 1.0,
    this.doubleSessionTolerance = 1.0,
    this.taperResponse = 1.0,
    this.z5Tolerance = 1.0,
    this.positiveResponses = 0,
    this.negativeResponses = 0,
    required this.lastUpdated,
  });

  factory AdaptiveResponseMemory.initial(String athleteId) {
    return AdaptiveResponseMemory(
      athleteId: athleteId,
      lastUpdated: DateTime.now(),
    );
  }

  AdaptiveResponseMemory copyWith({
    double? sprintTolerance,
    double? lactateTolerance,
    double? gymTolerance,
    double? jumpTolerance,
    double? doubleSessionTolerance,
    double? taperResponse,
    double? z5Tolerance,
    int? positiveResponses,
    int? negativeResponses,
    DateTime? lastUpdated,
  }) {
    return AdaptiveResponseMemory(
      athleteId: athleteId,
      sprintTolerance: sprintTolerance ?? this.sprintTolerance,
      lactateTolerance: lactateTolerance ?? this.lactateTolerance,
      gymTolerance: gymTolerance ?? this.gymTolerance,
      jumpTolerance: jumpTolerance ?? this.jumpTolerance,
      doubleSessionTolerance:
          doubleSessionTolerance ?? this.doubleSessionTolerance,
      taperResponse: taperResponse ?? this.taperResponse,
      z5Tolerance: z5Tolerance ?? this.z5Tolerance,
      positiveResponses: positiveResponses ?? this.positiveResponses,
      negativeResponses: negativeResponses ?? this.negativeResponses,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'athleteId': athleteId,
      'sprintTolerance': sprintTolerance,
      'lactateTolerance': lactateTolerance,
      'gymTolerance': gymTolerance,
      'jumpTolerance': jumpTolerance,
      'doubleSessionTolerance': doubleSessionTolerance,
      'taperResponse': taperResponse,
      'z5Tolerance': z5Tolerance,
      'positiveResponses': positiveResponses,
      'negativeResponses': negativeResponses,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory AdaptiveResponseMemory.fromMap(Map<String, dynamic> map) {
    final athleteId = map['athleteId']?.toString() ?? '';

    return AdaptiveResponseMemory(
      athleteId: athleteId,
      sprintTolerance:
          (map['sprintTolerance'] as num?)?.toDouble() ?? 1.0,
      lactateTolerance:
          (map['lactateTolerance'] as num?)?.toDouble() ?? 1.0,
      gymTolerance:
          (map['gymTolerance'] as num?)?.toDouble() ?? 1.0,
      jumpTolerance:
          (map['jumpTolerance'] as num?)?.toDouble() ?? 1.0,
      doubleSessionTolerance:
          (map['doubleSessionTolerance'] as num?)?.toDouble() ?? 1.0,
      taperResponse:
          (map['taperResponse'] as num?)?.toDouble() ?? 1.0,
      z5Tolerance:
          (map['z5Tolerance'] as num?)?.toDouble() ?? 1.0,
      positiveResponses:
          (map['positiveResponses'] as num?)?.round() ?? 0,
      negativeResponses:
          (map['negativeResponses'] as num?)?.round() ?? 0,
      lastUpdated: DateTime.tryParse(
            map['lastUpdated']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }

  bool get toleratesSprint => sprintTolerance >= 1.08;
  bool get strugglesWithSprint => sprintTolerance <= 0.92;

  bool get toleratesLactate => lactateTolerance >= 1.08;
  bool get strugglesWithLactate => lactateTolerance <= 0.92;

  bool get toleratesGym => gymTolerance >= 1.08;
  bool get strugglesWithGym => gymTolerance <= 0.92;

  bool get toleratesJumps => jumpTolerance >= 1.08;
  bool get strugglesWithJumps => jumpTolerance <= 0.92;

  bool get toleratesDoubleSession => doubleSessionTolerance >= 1.08;
  bool get strugglesWithDoubleSession => doubleSessionTolerance <= 0.92;

  bool get respondsWellToTaper => taperResponse >= 1.08;
  bool get needsLongerTaper => taperResponse <= 0.92;

  bool get toleratesZ5 => z5Tolerance >= 1.08;
  bool get strugglesWithZ5 => z5Tolerance <= 0.92;
}


