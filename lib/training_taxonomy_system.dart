enum NeuralDemand { none, low, moderate, high, maximal }

enum MetabolicDemand { none, low, moderate, high, extreme }

enum ReactiveDemand { none, low, moderate, high, extreme }

enum TechnicalDemand { low, moderate, high, elite }

enum RecoveryCost { minimal, low, moderate, high, extreme }

enum TrainingDensityTolerance { low, moderate, high }

enum TrainingSurface { track, road, gym, bike, indoor, mixed }

enum TrainingEnvironment { technical, physiological, tactical, recovery, gym }

enum SessionCompatibility {
  recoveryOnly,
  lowIntensityOnly,
  technicalOnly,
  aerobicOnly,
  neuralCompatible,
  metabolicCompatible,
  universal,
}

enum FatigueType { neural, metabolic, muscular, reactive, systemic }

enum AthleteConstraint {
  lowReadiness,
  highInjuryRisk,
  tendonPain,
  excessiveNeuralLoad,
  excessiveMetabolicLoad,
  taperProtection,
  recoveryRequired,
  highAcwr,
  lowHrv,
}

enum SessionPriority { optional, complementary, important, key, critical }

class TrainingTaxonomyProfile {
  final String sessionId;

  // =========================
  // LOAD PROFILE
  // =========================

  final NeuralDemand neuralDemand;

  final MetabolicDemand metabolicDemand;

  final ReactiveDemand reactiveDemand;

  final TechnicalDemand technicalDemand;

  final RecoveryCost recoveryCost;

  final int estimatedStressScore;

  final int estimatedRecoveryHours;

  // =========================
  // TRAINING BEHAVIOR
  // =========================

  final bool speedFocused;

  final bool accelerationFocused;

  final bool lactateFocused;

  final bool aerobicFocused;

  final bool tacticalFocused;

  final bool technicalFocused;

  final bool gymFocused;

  final bool recoveryFocused;

  final bool taperFriendly;

  // =========================
  // ADAPTATION PROFILE
  // =========================

  final List<FatigueType> primaryFatigue;

  final List<FatigueType> secondaryFatigue;

  final TrainingDensityTolerance densityTolerance;

  // =========================
  // SESSION MANAGEMENT
  // =========================

  final SessionCompatibility nextDayCompatibility;

  final List<SessionCompatibility> compatibleWith;

  final List<AthleteConstraint> avoidIf;

  final List<String> idealSequencing;

  final List<String> avoidSequencing;

  // =========================
  // ENVIRONMENT
  // =========================

  final TrainingSurface surface;

  final TrainingEnvironment environment;

  final SessionPriority priority;

  const TrainingTaxonomyProfile({
    required this.sessionId,
    required this.neuralDemand,
    required this.metabolicDemand,
    required this.reactiveDemand,
    required this.technicalDemand,
    required this.recoveryCost,
    required this.estimatedStressScore,
    required this.estimatedRecoveryHours,
    required this.speedFocused,
    required this.accelerationFocused,
    required this.lactateFocused,
    required this.aerobicFocused,
    required this.tacticalFocused,
    required this.technicalFocused,
    required this.gymFocused,
    required this.recoveryFocused,
    required this.taperFriendly,
    required this.primaryFatigue,
    required this.secondaryFatigue,
    required this.densityTolerance,
    required this.nextDayCompatibility,
    required this.compatibleWith,
    required this.avoidIf,
    required this.idealSequencing,
    required this.avoidSequencing,
    required this.surface,
    required this.environment,
    required this.priority,
  });
}

class TrainingTaxonomySystem {
  static const Map<String, TrainingTaxonomyProfile> profiles = {
    // =========================================================
    // SPEED STARTS
    // =========================================================
    'speed_starts_001': TrainingTaxonomyProfile(
      sessionId: 'speed_starts_001',

      neuralDemand: NeuralDemand.maximal,

      metabolicDemand: MetabolicDemand.low,

      reactiveDemand: ReactiveDemand.high,

      technicalDemand: TechnicalDemand.high,

      recoveryCost: RecoveryCost.high,

      estimatedStressScore: 82,

      estimatedRecoveryHours: 36,

      speedFocused: true,

      accelerationFocused: true,

      lactateFocused: false,

      aerobicFocused: false,

      tacticalFocused: false,

      technicalFocused: true,

      gymFocused: false,

      recoveryFocused: false,

      taperFriendly: true,

      primaryFatigue: [FatigueType.neural, FatigueType.reactive],

      secondaryFatigue: [FatigueType.muscular],

      densityTolerance: TrainingDensityTolerance.low,

      nextDayCompatibility: SessionCompatibility.recoveryOnly,

      compatibleWith: [
        SessionCompatibility.recoveryOnly,
        SessionCompatibility.technicalOnly,
      ],

      avoidIf: [
        AthleteConstraint.lowReadiness,
        AthleteConstraint.highInjuryRisk,
        AthleteConstraint.excessiveNeuralLoad,
        AthleteConstraint.tendonPain,
      ],

      idealSequencing: ['recovery', 'mobility', 'technical low intensity'],

      avoidSequencing: ['heavy plyometrics', 'max velocity', 'lactate session'],

      surface: TrainingSurface.track,

      environment: TrainingEnvironment.technical,

      priority: SessionPriority.key,
    ),

    // =========================================================
    // LACTATE
    // =========================================================
    'lactate_tolerance_001': TrainingTaxonomyProfile(
      sessionId: 'lactate_tolerance_001',

      neuralDemand: NeuralDemand.moderate,

      metabolicDemand: MetabolicDemand.extreme,

      reactiveDemand: ReactiveDemand.low,

      technicalDemand: TechnicalDemand.high,

      recoveryCost: RecoveryCost.extreme,

      estimatedStressScore: 91,

      estimatedRecoveryHours: 48,

      speedFocused: false,

      accelerationFocused: false,

      lactateFocused: true,

      aerobicFocused: false,

      tacticalFocused: true,

      technicalFocused: true,

      gymFocused: false,

      recoveryFocused: false,

      taperFriendly: false,

      primaryFatigue: [FatigueType.metabolic, FatigueType.systemic],

      secondaryFatigue: [FatigueType.muscular],

      densityTolerance: TrainingDensityTolerance.low,

      nextDayCompatibility: SessionCompatibility.recoveryOnly,

      compatibleWith: [
        SessionCompatibility.recoveryOnly,
        SessionCompatibility.aerobicOnly,
      ],

      avoidIf: [
        AthleteConstraint.lowReadiness,
        AthleteConstraint.highAcwr,
        AthleteConstraint.lowHrv,
        AthleteConstraint.excessiveMetabolicLoad,
        AthleteConstraint.taperProtection,
      ],

      idealSequencing: ['recovery', 'bike regeneration', 'technical easy'],

      avoidSequencing: ['heavy gym', 'sprint neural', 'double intensity'],

      surface: TrainingSurface.track,

      environment: TrainingEnvironment.physiological,

      priority: SessionPriority.key,
    ),

    // =========================================================
    // MAX STRENGTH
    // =========================================================
    'strength_max_001': TrainingTaxonomyProfile(
      sessionId: 'strength_max_001',

      neuralDemand: NeuralDemand.high,

      metabolicDemand: MetabolicDemand.moderate,

      reactiveDemand: ReactiveDemand.moderate,

      technicalDemand: TechnicalDemand.moderate,

      recoveryCost: RecoveryCost.high,

      estimatedStressScore: 78,

      estimatedRecoveryHours: 36,

      speedFocused: false,

      accelerationFocused: true,

      lactateFocused: false,

      aerobicFocused: false,

      tacticalFocused: false,

      technicalFocused: false,

      gymFocused: true,

      recoveryFocused: false,

      taperFriendly: false,

      primaryFatigue: [FatigueType.neural, FatigueType.muscular],

      secondaryFatigue: [FatigueType.reactive],

      densityTolerance: TrainingDensityTolerance.moderate,

      nextDayCompatibility: SessionCompatibility.technicalOnly,

      compatibleWith: [
        SessionCompatibility.technicalOnly,
        SessionCompatibility.aerobicOnly,
      ],

      avoidIf: [
        AthleteConstraint.lowReadiness,
        AthleteConstraint.highInjuryRisk,
        AthleteConstraint.excessiveNeuralLoad,
      ],

      idealSequencing: ['technical skating', 'easy aerobic'],

      avoidSequencing: ['heavy plyometric', 'max sprint'],

      surface: TrainingSurface.gym,

      environment: TrainingEnvironment.gym,

      priority: SessionPriority.key,
    ),

    // =========================================================
    // RECOVERY
    // =========================================================
    'recovery_001': TrainingTaxonomyProfile(
      sessionId: 'recovery_001',

      neuralDemand: NeuralDemand.none,

      metabolicDemand: MetabolicDemand.low,

      reactiveDemand: ReactiveDemand.none,

      technicalDemand: TechnicalDemand.low,

      recoveryCost: RecoveryCost.minimal,

      estimatedStressScore: 10,

      estimatedRecoveryHours: 6,

      speedFocused: false,

      accelerationFocused: false,

      lactateFocused: false,

      aerobicFocused: false,

      tacticalFocused: false,

      technicalFocused: false,

      gymFocused: false,

      recoveryFocused: true,

      taperFriendly: true,

      primaryFatigue: [],

      secondaryFatigue: [],

      densityTolerance: TrainingDensityTolerance.high,

      nextDayCompatibility: SessionCompatibility.universal,

      compatibleWith: [SessionCompatibility.universal],

      avoidIf: [],

      idealSequencing: ['anything'],

      avoidSequencing: [],

      surface: TrainingSurface.bike,

      environment: TrainingEnvironment.recovery,

      priority: SessionPriority.important,
    ),
  };

  static TrainingTaxonomyProfile? getProfile(String sessionId) {
    return profiles[sessionId];
  }

  static bool isHighNeural(TrainingTaxonomyProfile profile) {
    return profile.neuralDemand == NeuralDemand.high ||
        profile.neuralDemand == NeuralDemand.maximal;
  }

  static bool isHighMetabolic(TrainingTaxonomyProfile profile) {
    return profile.metabolicDemand == MetabolicDemand.high ||
        profile.metabolicDemand == MetabolicDemand.extreme;
  }

  static bool isReactiveHeavy(TrainingTaxonomyProfile profile) {
    return profile.reactiveDemand == ReactiveDemand.high ||
        profile.reactiveDemand == ReactiveDemand.extreme;
  }

  static bool requiresLongRecovery(TrainingTaxonomyProfile profile) {
    return profile.recoveryCost == RecoveryCost.high ||
        profile.recoveryCost == RecoveryCost.extreme;
  }

  static bool taperCompatible(TrainingTaxonomyProfile profile) {
    return profile.taperFriendly;
  }

  static bool compatibleNextDay({
    required TrainingTaxonomyProfile today,
    required TrainingTaxonomyProfile next,
  }) {
    if (today.nextDayCompatibility == SessionCompatibility.universal) {
      return true;
    }

    if (today.nextDayCompatibility == SessionCompatibility.recoveryOnly &&
        next.recoveryFocused) {
      return true;
    }

    if (today.nextDayCompatibility == SessionCompatibility.technicalOnly &&
        next.technicalFocused &&
        !next.lactateFocused) {
      return true;
    }

    if (today.nextDayCompatibility == SessionCompatibility.aerobicOnly &&
        next.aerobicFocused &&
        !next.lactateFocused) {
      return true;
    }

    if (today.nextDayCompatibility == SessionCompatibility.lowIntensityOnly &&
        next.estimatedStressScore <= 40) {
      return true;
    }

    return false;
  }

  static int calculateCombinedStress(List<TrainingTaxonomyProfile> sessions) {
    return sessions.fold<int>(
      0,
      (sum, session) => sum + session.estimatedStressScore,
    );
  }

  static bool excessiveNeuralSequence(List<TrainingTaxonomyProfile> sessions) {
    final highNeural = sessions.where(isHighNeural).length;

    return highNeural >= 3;
  }

  static bool excessiveMetabolicSequence(
    List<TrainingTaxonomyProfile> sessions,
  ) {
    final metabolic = sessions.where(isHighMetabolic).length;

    return metabolic >= 3;
  }

  static bool excessiveReactiveSequence(
    List<TrainingTaxonomyProfile> sessions,
  ) {
    final reactive = sessions.where(isReactiveHeavy).length;

    return reactive >= 3;
  }

  static int estimatedWeeklyRecoveryHours(
    List<TrainingTaxonomyProfile> sessions,
  ) {
    return sessions.fold<int>(
      0,
      (sum, session) => sum + session.estimatedRecoveryHours,
    );
  }
}


