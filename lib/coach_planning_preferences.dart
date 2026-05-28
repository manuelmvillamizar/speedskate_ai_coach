enum CoachPlanningStyle {
  balanced,
  speedFocused,
  enduranceFocused,
  strengthFocused,
  technicalFocused,
}

class CoachPlanningPreferences {
  final bool useSeasonPlanning;
  final bool allowDoubleSessions;
  final bool allowCycling;

  final int skatingSessionsPerWeek;
  final int strengthSessionsPerWeek;
  final int cyclingSessionsPerWeek;
  final int plyometricSessionsPerWeek;
  final int mobilitySessionsPerWeek;
  final int coreSessionsPerWeek;

  final bool prioritizeSpeed;
  final bool prioritizeEndurance;
  final bool prioritizeStrength;
  final bool prioritizeTechnique;

  final CoachPlanningStyle planningStyle;

  const CoachPlanningPreferences({
    this.useSeasonPlanning = true,
    this.allowDoubleSessions = true,
    this.allowCycling = true,
    this.skatingSessionsPerWeek = 8,
    this.strengthSessionsPerWeek = 3,
    this.cyclingSessionsPerWeek = 2,
    this.plyometricSessionsPerWeek = 2,
    this.mobilitySessionsPerWeek = 4,
    this.coreSessionsPerWeek = 3,
    this.prioritizeSpeed = true,
    this.prioritizeEndurance = true,
    this.prioritizeStrength = true,
    this.prioritizeTechnique = true,
    this.planningStyle = CoachPlanningStyle.balanced,
  });

  int get totalWeeklySessions {
    return skatingSessionsPerWeek +
        strengthSessionsPerWeek +
        (allowCycling ? cyclingSessionsPerWeek : 0) +
        plyometricSessionsPerWeek +
        mobilitySessionsPerWeek +
        coreSessionsPerWeek;
  }

  CoachPlanningPreferences copyWith({
    bool? useSeasonPlanning,
    bool? allowDoubleSessions,
    bool? allowCycling,
    int? skatingSessionsPerWeek,
    int? strengthSessionsPerWeek,
    int? cyclingSessionsPerWeek,
    int? plyometricSessionsPerWeek,
    int? mobilitySessionsPerWeek,
    int? coreSessionsPerWeek,
    bool? prioritizeSpeed,
    bool? prioritizeEndurance,
    bool? prioritizeStrength,
    bool? prioritizeTechnique,
    CoachPlanningStyle? planningStyle,
  }) {
    return CoachPlanningPreferences(
      useSeasonPlanning: useSeasonPlanning ?? this.useSeasonPlanning,
      allowDoubleSessions: allowDoubleSessions ?? this.allowDoubleSessions,
      allowCycling: allowCycling ?? this.allowCycling,
      skatingSessionsPerWeek:
          skatingSessionsPerWeek ?? this.skatingSessionsPerWeek,
      strengthSessionsPerWeek:
          strengthSessionsPerWeek ?? this.strengthSessionsPerWeek,
      cyclingSessionsPerWeek:
          cyclingSessionsPerWeek ?? this.cyclingSessionsPerWeek,
      plyometricSessionsPerWeek:
          plyometricSessionsPerWeek ?? this.plyometricSessionsPerWeek,
      mobilitySessionsPerWeek:
          mobilitySessionsPerWeek ?? this.mobilitySessionsPerWeek,
      coreSessionsPerWeek: coreSessionsPerWeek ?? this.coreSessionsPerWeek,
      prioritizeSpeed: prioritizeSpeed ?? this.prioritizeSpeed,
      prioritizeEndurance: prioritizeEndurance ?? this.prioritizeEndurance,
      prioritizeStrength: prioritizeStrength ?? this.prioritizeStrength,
      prioritizeTechnique: prioritizeTechnique ?? this.prioritizeTechnique,
      planningStyle: planningStyle ?? this.planningStyle,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'useSeasonPlanning': useSeasonPlanning,
      'allowDoubleSessions': allowDoubleSessions,
      'allowCycling': allowCycling,
      'skatingSessionsPerWeek': skatingSessionsPerWeek,
      'strengthSessionsPerWeek': strengthSessionsPerWeek,
      'cyclingSessionsPerWeek': cyclingSessionsPerWeek,
      'plyometricSessionsPerWeek': plyometricSessionsPerWeek,
      'mobilitySessionsPerWeek': mobilitySessionsPerWeek,
      'coreSessionsPerWeek': coreSessionsPerWeek,
      'prioritizeSpeed': prioritizeSpeed,
      'prioritizeEndurance': prioritizeEndurance,
      'prioritizeStrength': prioritizeStrength,
      'prioritizeTechnique': prioritizeTechnique,
      'planningStyle': planningStyle.name,
    };
  }

  factory CoachPlanningPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const CoachPlanningPreferences();

    return CoachPlanningPreferences(
      useSeasonPlanning: map['useSeasonPlanning'] == true,
      allowDoubleSessions: map['allowDoubleSessions'] != false,
      allowCycling: map['allowCycling'] != false,
      skatingSessionsPerWeek:
          (map['skatingSessionsPerWeek'] as num?)?.toInt() ?? 8,
      strengthSessionsPerWeek:
          (map['strengthSessionsPerWeek'] as num?)?.toInt() ?? 3,
      cyclingSessionsPerWeek:
          (map['cyclingSessionsPerWeek'] as num?)?.toInt() ?? 2,
      plyometricSessionsPerWeek:
          (map['plyometricSessionsPerWeek'] as num?)?.toInt() ?? 2,
      mobilitySessionsPerWeek:
          (map['mobilitySessionsPerWeek'] as num?)?.toInt() ?? 4,
      coreSessionsPerWeek: (map['coreSessionsPerWeek'] as num?)?.toInt() ?? 3,
      prioritizeSpeed: map['prioritizeSpeed'] != false,
      prioritizeEndurance: map['prioritizeEndurance'] != false,
      prioritizeStrength: map['prioritizeStrength'] != false,
      prioritizeTechnique: map['prioritizeTechnique'] != false,
      planningStyle: CoachPlanningStyle.values.firstWhere(
        (style) => style.name == map['planningStyle']?.toString(),
        orElse: () => CoachPlanningStyle.balanced,
      ),
    );
  }
}
