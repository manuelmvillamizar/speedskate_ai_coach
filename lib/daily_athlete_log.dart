class DailyAthleteLog {
  final String athleteId;
  final DateTime date;

  final String plannedSessionType;
  final int plannedLoad;
  final int plannedMinutes;
  final double plannedKm;

  final String performedSessionType;
  final int performedLoad;
  final int performedMinutes;
  final double performedKm;

  final bool completedAsPlanned;

  final double hrv;
  final int restingHeartRate;
  final double sleepHours;
  final double stressLevel;
  final int averageHeartRate;
  final int maxHeartRate;

  final int rpe;
  final int soreness;
  final int motivation;
  final int readiness;

  final bool overloadDetected;
  final bool recoveryRecommended;
  final double injuryRisk;

  final String aiDecision;
  final String aiNotes;

  final double internalLoad;
  final double externalLoad;

  final int zone1Minutes;
  final int zone2Minutes;
  final int zone3Minutes;
  final int zone4Minutes;
  final int zone5Minutes;

  // =========================
  // UNIVERSAL BODY STRESS MODEL
  // =========================
  // Estos campos permiten que la app entienda el estrés real oculto
  // de cualquier trabajo: patines, ruta, bici, gimnasio, físico,
  // pliometría, competencia, técnica o recuperación.

  final double neuralStress;
  final double muscleStress;
  final double tendonStress;
  final double metabolicStress;
  final double cardiovascularStress;
  final double mechanicalStress;
  final double technicalStress;
  final double coordinationStress;
  final double terrainStress;
  final double intermittentStress;
  final double recoveryCost;

  const DailyAthleteLog({
    required this.athleteId,
    required this.date,

    this.plannedSessionType = '',
    this.plannedLoad = 0,
    this.plannedMinutes = 0,
    this.plannedKm = 0.0,

    this.performedSessionType = '',
    this.performedLoad = 0,
    this.performedMinutes = 0,
    this.performedKm = 0.0,

    this.completedAsPlanned = false,

    this.hrv = 55.0,
    this.restingHeartRate = 52,
    this.sleepHours = 7.5,
    this.stressLevel = 40.0,
    this.averageHeartRate = 0,
    this.maxHeartRate = 0,

    this.rpe = 0,
    this.soreness = 3,
    this.motivation = 5,
    this.readiness = 75,

    this.overloadDetected = false,
    this.recoveryRecommended = false,
    this.injuryRisk = 10.0,

    this.aiDecision = '',
    this.aiNotes = '',

    this.internalLoad = 0.0,
    this.externalLoad = 0.0,

    this.zone1Minutes = 0,
    this.zone2Minutes = 0,
    this.zone3Minutes = 0,
    this.zone4Minutes = 0,
    this.zone5Minutes = 0,

    this.neuralStress = 0.0,
    this.muscleStress = 0.0,
    this.tendonStress = 0.0,
    this.metabolicStress = 0.0,
    this.cardiovascularStress = 0.0,
    this.mechanicalStress = 0.0,
    this.technicalStress = 0.0,
    this.coordinationStress = 0.0,
    this.terrainStress = 0.0,
    this.intermittentStress = 0.0,
    this.recoveryCost = 0.0,
  });

  int get totalZoneMinutes {
    return zone1Minutes +
        zone2Minutes +
        zone3Minutes +
        zone4Minutes +
        zone5Minutes;
  }

  int get lowIntensityMinutes {
    return zone1Minutes + zone2Minutes;
  }

  int get moderateIntensityMinutes {
    return zone3Minutes;
  }

  int get highIntensityMinutes {
    return zone4Minutes + zone5Minutes;
  }

  double get highIntensityRatio {
    final total = totalZoneMinutes;

    if (total <= 0) return 0.0;

    return highIntensityMinutes / total;
  }

  bool get hasZoneData {
    return totalZoneMinutes > 0;
  }

  double get totalBodyStress {
    return neuralStress +
        muscleStress +
        tendonStress +
        metabolicStress +
        cardiovascularStress +
        mechanicalStress +
        technicalStress +
        coordinationStress +
        terrainStress +
        intermittentStress;
  }

  double get hiddenBodyStress {
    return mechanicalStress +
        terrainStress +
        intermittentStress +
        coordinationStress +
        technicalStress;
  }

  bool get hasHiddenStress {
    return hiddenBodyStress >= 45;
  }

  bool get hasHighNeuralStress {
    return neuralStress >= 65;
  }

  bool get hasHighMuscleStress {
    return muscleStress >= 65;
  }

  bool get hasHighTendonStress {
    return tendonStress >= 65;
  }

  bool get hasHighMetabolicStress {
    return metabolicStress >= 65;
  }

  bool get hasHighMechanicalStress {
    return mechanicalStress >= 65 || terrainStress >= 65;
  }

  bool get requiresProtection {
    return neuralStress >= 75 ||
        tendonStress >= 75 ||
        muscleStress >= 75 ||
        recoveryCost >= 75 ||
        hiddenBodyStress >= 80;
  }

  DailyAthleteLog copyWith({
    String? athleteId,
    DateTime? date,
    String? plannedSessionType,
    int? plannedLoad,
    int? plannedMinutes,
    double? plannedKm,
    String? performedSessionType,
    int? performedLoad,
    int? performedMinutes,
    double? performedKm,
    bool? completedAsPlanned,
    double? hrv,
    int? restingHeartRate,
    double? sleepHours,
    double? stressLevel,
    int? averageHeartRate,
    int? maxHeartRate,
    int? rpe,
    int? soreness,
    int? motivation,
    int? readiness,
    bool? overloadDetected,
    bool? recoveryRecommended,
    double? injuryRisk,
    String? aiDecision,
    String? aiNotes,
    double? internalLoad,
    double? externalLoad,
    int? zone1Minutes,
    int? zone2Minutes,
    int? zone3Minutes,
    int? zone4Minutes,
    int? zone5Minutes,
    double? neuralStress,
    double? muscleStress,
    double? tendonStress,
    double? metabolicStress,
    double? cardiovascularStress,
    double? mechanicalStress,
    double? technicalStress,
    double? coordinationStress,
    double? terrainStress,
    double? intermittentStress,
    double? recoveryCost,
  }) {
    return DailyAthleteLog(
      athleteId: athleteId ?? this.athleteId,
      date: date ?? this.date,
      plannedSessionType: plannedSessionType ?? this.plannedSessionType,
      plannedLoad: plannedLoad ?? this.plannedLoad,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      plannedKm: plannedKm ?? this.plannedKm,
      performedSessionType: performedSessionType ?? this.performedSessionType,
      performedLoad: performedLoad ?? this.performedLoad,
      performedMinutes: performedMinutes ?? this.performedMinutes,
      performedKm: performedKm ?? this.performedKm,
      completedAsPlanned: completedAsPlanned ?? this.completedAsPlanned,
      hrv: hrv ?? this.hrv,
      restingHeartRate: restingHeartRate ?? this.restingHeartRate,
      sleepHours: sleepHours ?? this.sleepHours,
      stressLevel: stressLevel ?? this.stressLevel,
      averageHeartRate: averageHeartRate ?? this.averageHeartRate,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      rpe: rpe ?? this.rpe,
      soreness: soreness ?? this.soreness,
      motivation: motivation ?? this.motivation,
      readiness: readiness ?? this.readiness,
      overloadDetected: overloadDetected ?? this.overloadDetected,
      recoveryRecommended: recoveryRecommended ?? this.recoveryRecommended,
      injuryRisk: injuryRisk ?? this.injuryRisk,
      aiDecision: aiDecision ?? this.aiDecision,
      aiNotes: aiNotes ?? this.aiNotes,
      internalLoad: internalLoad ?? this.internalLoad,
      externalLoad: externalLoad ?? this.externalLoad,
      zone1Minutes: zone1Minutes ?? this.zone1Minutes,
      zone2Minutes: zone2Minutes ?? this.zone2Minutes,
      zone3Minutes: zone3Minutes ?? this.zone3Minutes,
      zone4Minutes: zone4Minutes ?? this.zone4Minutes,
      zone5Minutes: zone5Minutes ?? this.zone5Minutes,
      neuralStress: neuralStress ?? this.neuralStress,
      muscleStress: muscleStress ?? this.muscleStress,
      tendonStress: tendonStress ?? this.tendonStress,
      metabolicStress: metabolicStress ?? this.metabolicStress,
      cardiovascularStress: cardiovascularStress ?? this.cardiovascularStress,
      mechanicalStress: mechanicalStress ?? this.mechanicalStress,
      technicalStress: technicalStress ?? this.technicalStress,
      coordinationStress: coordinationStress ?? this.coordinationStress,
      terrainStress: terrainStress ?? this.terrainStress,
      intermittentStress: intermittentStress ?? this.intermittentStress,
      recoveryCost: recoveryCost ?? this.recoveryCost,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'athleteId': athleteId,
      'date': date.toIso8601String(),
      'plannedSessionType': plannedSessionType,
      'plannedLoad': plannedLoad,
      'plannedMinutes': plannedMinutes,
      'plannedKm': plannedKm,
      'performedSessionType': performedSessionType,
      'performedLoad': performedLoad,
      'performedMinutes': performedMinutes,
      'performedKm': performedKm,
      'completedAsPlanned': completedAsPlanned,
      'hrv': hrv,
      'restingHeartRate': restingHeartRate,
      'sleepHours': sleepHours,
      'stressLevel': stressLevel,
      'averageHeartRate': averageHeartRate,
      'maxHeartRate': maxHeartRate,
      'rpe': rpe,
      'soreness': soreness,
      'motivation': motivation,
      'readiness': readiness,
      'overloadDetected': overloadDetected,
      'recoveryRecommended': recoveryRecommended,
      'injuryRisk': injuryRisk,
      'aiDecision': aiDecision,
      'aiNotes': aiNotes,
      'internalLoad': internalLoad,
      'externalLoad': externalLoad,
      'zone1Minutes': zone1Minutes,
      'zone2Minutes': zone2Minutes,
      'zone3Minutes': zone3Minutes,
      'zone4Minutes': zone4Minutes,
      'zone5Minutes': zone5Minutes,
      'neuralStress': neuralStress,
      'muscleStress': muscleStress,
      'tendonStress': tendonStress,
      'metabolicStress': metabolicStress,
      'cardiovascularStress': cardiovascularStress,
      'mechanicalStress': mechanicalStress,
      'technicalStress': technicalStress,
      'coordinationStress': coordinationStress,
      'terrainStress': terrainStress,
      'intermittentStress': intermittentStress,
      'recoveryCost': recoveryCost,
    };
  }

  factory DailyAthleteLog.fromMap(Map<String, dynamic> map) {
    return DailyAthleteLog(
      athleteId: map['athleteId']?.toString() ?? '',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      plannedSessionType: map['plannedSessionType']?.toString() ?? '',
      plannedLoad: (map['plannedLoad'] as num?)?.round() ?? 0,
      plannedMinutes: (map['plannedMinutes'] as num?)?.round() ?? 0,
      plannedKm: (map['plannedKm'] as num?)?.toDouble() ?? 0.0,
      performedSessionType: map['performedSessionType']?.toString() ?? '',
      performedLoad: (map['performedLoad'] as num?)?.round() ?? 0,
      performedMinutes: (map['performedMinutes'] as num?)?.round() ?? 0,
      performedKm: (map['performedKm'] as num?)?.toDouble() ?? 0.0,
      completedAsPlanned: map['completedAsPlanned'] == true,
      hrv: (map['hrv'] as num?)?.toDouble() ?? 55.0,
      restingHeartRate: (map['restingHeartRate'] as num?)?.round() ?? 52,
      sleepHours: (map['sleepHours'] as num?)?.toDouble() ?? 7.5,
      stressLevel: (map['stressLevel'] as num?)?.toDouble() ?? 40.0,
      averageHeartRate: (map['averageHeartRate'] as num?)?.round() ?? 0,
      maxHeartRate: (map['maxHeartRate'] as num?)?.round() ?? 0,
      rpe: (map['rpe'] as num?)?.round() ?? 0,
      soreness: (map['soreness'] as num?)?.round() ?? 3,
      motivation: (map['motivation'] as num?)?.round() ?? 5,
      readiness: (map['readiness'] as num?)?.round() ?? 75,
      overloadDetected: map['overloadDetected'] == true,
      recoveryRecommended: map['recoveryRecommended'] == true,
      injuryRisk: (map['injuryRisk'] as num?)?.toDouble() ?? 10.0,
      aiDecision: map['aiDecision']?.toString() ?? '',
      aiNotes: map['aiNotes']?.toString() ?? '',
      internalLoad: (map['internalLoad'] as num?)?.toDouble() ?? 0.0,
      externalLoad: (map['externalLoad'] as num?)?.toDouble() ?? 0.0,
      zone1Minutes: (map['zone1Minutes'] as num?)?.round() ?? 0,
      zone2Minutes: (map['zone2Minutes'] as num?)?.round() ?? 0,
      zone3Minutes: (map['zone3Minutes'] as num?)?.round() ?? 0,
      zone4Minutes: (map['zone4Minutes'] as num?)?.round() ?? 0,
      zone5Minutes: (map['zone5Minutes'] as num?)?.round() ?? 0,
      neuralStress: (map['neuralStress'] as num?)?.toDouble() ?? 0.0,
      muscleStress: (map['muscleStress'] as num?)?.toDouble() ?? 0.0,
      tendonStress: (map['tendonStress'] as num?)?.toDouble() ?? 0.0,
      metabolicStress: (map['metabolicStress'] as num?)?.toDouble() ?? 0.0,
      cardiovascularStress:
          (map['cardiovascularStress'] as num?)?.toDouble() ?? 0.0,
      mechanicalStress: (map['mechanicalStress'] as num?)?.toDouble() ?? 0.0,
      technicalStress: (map['technicalStress'] as num?)?.toDouble() ?? 0.0,
      coordinationStress:
          (map['coordinationStress'] as num?)?.toDouble() ?? 0.0,
      terrainStress: (map['terrainStress'] as num?)?.toDouble() ?? 0.0,
      intermittentStress:
          (map['intermittentStress'] as num?)?.toDouble() ?? 0.0,
      recoveryCost: (map['recoveryCost'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
