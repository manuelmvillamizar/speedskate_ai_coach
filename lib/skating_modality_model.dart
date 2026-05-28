import 'athlete_program_service.dart';

enum SkatingModality { sprint, endurance, mixed }

enum SkatingEventFamily {
  sprint100m,
  sprint200m,
  sprint500m,
  sprint1000m,
  oneLap,
  endurance1000m,
  points5000mTrack,
  elimination10k,
  points5000mRoad,
  marathon,
}

enum SkatingPreparationPhase {
  generalPreparation,
  specificPreparation,
  preCompetition,
  competition,
  transition,
}

class SkatingModalityProfile {
  final SkatingModality modality;
  final List<SkatingEventFamily> eventFamilies;

  final double strengthPriority;
  final double powerPriority;
  final double maxSpeedPriority;
  final double accelerationPriority;
  final double aerobicBasePriority;
  final double specificEndurancePriority;
  final double lactateTolerancePriority;
  final double tacticalPriority;
  final double technicalPriority;
  final double recoveryPriority;
  final double corePriority;
  final double upperBodyPriority;
  final double antagonistPriority;
  final double plyometricPriority;
  final double cyclingPriority;
  final double mobilityPriority;

  const SkatingModalityProfile({
    required this.modality,
    required this.eventFamilies,
    required this.strengthPriority,
    required this.powerPriority,
    required this.maxSpeedPriority,
    required this.accelerationPriority,
    required this.aerobicBasePriority,
    required this.specificEndurancePriority,
    required this.lactateTolerancePriority,
    required this.tacticalPriority,
    required this.technicalPriority,
    required this.recoveryPriority,
    required this.corePriority,
    required this.upperBodyPriority,
    required this.antagonistPriority,
    required this.plyometricPriority,
    required this.cyclingPriority,
    required this.mobilityPriority,
  });

  bool get isSprint => modality == SkatingModality.sprint;

  bool get isEndurance => modality == SkatingModality.endurance;

  bool get isMixed => modality == SkatingModality.mixed;

  String get modalityLabel {
    switch (modality) {
      case SkatingModality.sprint:
        return 'Velocidad';
      case SkatingModality.endurance:
        return 'Fondo';
      case SkatingModality.mixed:
        return 'Mixto';
    }
  }

  String get mainSportLogic {
    switch (modality) {
      case SkatingModality.sprint:
        return 'Perfil de velocidad: prioriza fuerza máxima, potencia, aceleración, velocidad máxima y técnica específica. Mantiene resistencia mínima para tolerar rondas, recuperar entre esfuerzos y sostener calidad.';
      case SkatingModality.endurance:
        return 'Perfil de fondo: prioriza base aeróbica, resistencia específica, economía, táctica y tolerancia al volumen. Mantiene fuerza, potencia, aceleraciones y remate para puntos, metas volantes, ataques y cierre final.';
      case SkatingModality.mixed:
        return 'Perfil mixto: combina fuerza, velocidad, resistencia, lactato, técnica y táctica. Busca equilibrio entre capacidad de acelerar, sostener ritmo y cerrar fuerte.';
    }
  }

  Map<String, double> toPriorityMap() {
    return {
      'strength': strengthPriority,
      'power': powerPriority,
      'maxSpeed': maxSpeedPriority,
      'acceleration': accelerationPriority,
      'aerobicBase': aerobicBasePriority,
      'specificEndurance': specificEndurancePriority,
      'lactateTolerance': lactateTolerancePriority,
      'tactical': tacticalPriority,
      'technical': technicalPriority,
      'recovery': recoveryPriority,
      'core': corePriority,
      'upperBody': upperBodyPriority,
      'antagonist': antagonistPriority,
      'plyometric': plyometricPriority,
      'cycling': cyclingPriority,
      'mobility': mobilityPriority,
    };
  }
}

class SkatingWeeklyDose {
  final int skatingDays;
  final int strengthDays;
  final int plyometricDays;
  final int cyclingDays;
  final int coreDays;
  final int upperBodyDays;
  final int antagonistDays;
  final int mobilityDays;
  final int recoveryDays;

  final String primaryFocus;
  final String secondaryFocus;
  final String coachingNote;

  const SkatingWeeklyDose({
    required this.skatingDays,
    required this.strengthDays,
    required this.plyometricDays,
    required this.cyclingDays,
    required this.coreDays,
    required this.upperBodyDays,
    required this.antagonistDays,
    required this.mobilityDays,
    required this.recoveryDays,
    required this.primaryFocus,
    required this.secondaryFocus,
    required this.coachingNote,
  });
}

class SkatingDayIntent {
  final String title;
  final String objective;
  final String primaryStimulus;
  final String secondaryStimulus;
  final bool includeStrength;
  final bool includePlyometrics;
  final bool includeSkating;
  final bool includeCycling;
  final bool includeCore;
  final bool includeUpperBody;
  final bool includeAntagonists;
  final bool includeMobility;
  final bool recoveryFocused;
  final bool highIntensityAllowed;
  final bool lactateAllowed;
  final bool maxSpeedAllowed;

  const SkatingDayIntent({
    required this.title,
    required this.objective,
    required this.primaryStimulus,
    required this.secondaryStimulus,
    required this.includeStrength,
    required this.includePlyometrics,
    required this.includeSkating,
    required this.includeCycling,
    required this.includeCore,
    required this.includeUpperBody,
    required this.includeAntagonists,
    required this.includeMobility,
    required this.recoveryFocused,
    required this.highIntensityAllowed,
    required this.lactateAllowed,
    required this.maxSpeedAllowed,
  });
}

class SkatingModalityModel {
  static SkatingModalityProfile profileForAthleteType(AthleteProgramType type) {
    switch (type) {
      case AthleteProgramType.sprinter:
        return sprintProfile;
      case AthleteProgramType.endurance:
        return enduranceProfile;
      case AthleteProgramType.mixed:
        return mixedProfile;
    }
  }

  static const SkatingModalityProfile sprintProfile = SkatingModalityProfile(
    modality: SkatingModality.sprint,
    eventFamilies: [
      SkatingEventFamily.sprint100m,
      SkatingEventFamily.sprint200m,
      SkatingEventFamily.sprint500m,
      SkatingEventFamily.sprint1000m,
      SkatingEventFamily.oneLap,
    ],
    strengthPriority: 0.95,
    powerPriority: 1.00,
    maxSpeedPriority: 1.00,
    accelerationPriority: 1.00,
    aerobicBasePriority: 0.38,
    specificEndurancePriority: 0.55,
    lactateTolerancePriority: 0.58,
    tacticalPriority: 0.50,
    technicalPriority: 0.92,
    recoveryPriority: 0.78,
    corePriority: 0.88,
    upperBodyPriority: 0.55,
    antagonistPriority: 0.72,
    plyometricPriority: 0.95,
    cyclingPriority: 0.35,
    mobilityPriority: 0.80,
  );

  static const SkatingModalityProfile enduranceProfile = SkatingModalityProfile(
    modality: SkatingModality.endurance,
    eventFamilies: [
      SkatingEventFamily.endurance1000m,
      SkatingEventFamily.points5000mTrack,
      SkatingEventFamily.elimination10k,
      SkatingEventFamily.points5000mRoad,
      SkatingEventFamily.marathon,
    ],
    strengthPriority: 0.68,
    powerPriority: 0.62,
    maxSpeedPriority: 0.66,
    accelerationPriority: 0.70,
    aerobicBasePriority: 1.00,
    specificEndurancePriority: 1.00,
    lactateTolerancePriority: 0.82,
    tacticalPriority: 0.92,
    technicalPriority: 0.86,
    recoveryPriority: 0.88,
    corePriority: 0.78,
    upperBodyPriority: 0.45,
    antagonistPriority: 0.68,
    plyometricPriority: 0.55,
    cyclingPriority: 0.78,
    mobilityPriority: 0.78,
  );

  static const SkatingModalityProfile mixedProfile = SkatingModalityProfile(
    modality: SkatingModality.mixed,
    eventFamilies: [
      SkatingEventFamily.sprint500m,
      SkatingEventFamily.sprint1000m,
      SkatingEventFamily.endurance1000m,
      SkatingEventFamily.points5000mTrack,
      SkatingEventFamily.elimination10k,
    ],
    strengthPriority: 0.82,
    powerPriority: 0.82,
    maxSpeedPriority: 0.82,
    accelerationPriority: 0.84,
    aerobicBasePriority: 0.78,
    specificEndurancePriority: 0.84,
    lactateTolerancePriority: 0.80,
    tacticalPriority: 0.78,
    technicalPriority: 0.88,
    recoveryPriority: 0.82,
    corePriority: 0.82,
    upperBodyPriority: 0.50,
    antagonistPriority: 0.70,
    plyometricPriority: 0.76,
    cyclingPriority: 0.58,
    mobilityPriority: 0.78,
  );

  static SkatingWeeklyDose weeklyDose({
    required SkatingModalityProfile profile,
    required SkatingPreparationPhase phase,
    required AthleteProgramLevel level,
  }) {
    final eliteBonus = level == AthleteProgramLevel.elite ? 1 : 0;
    final noviceReduction = level == AthleteProgramLevel.novice ? 1 : 0;

    switch (profile.modality) {
      case SkatingModality.sprint:
        return _sprintWeeklyDose(
          phase: phase,
          eliteBonus: eliteBonus,
          noviceReduction: noviceReduction,
        );
      case SkatingModality.endurance:
        return _enduranceWeeklyDose(
          phase: phase,
          eliteBonus: eliteBonus,
          noviceReduction: noviceReduction,
        );
      case SkatingModality.mixed:
        return _mixedWeeklyDose(
          phase: phase,
          eliteBonus: eliteBonus,
          noviceReduction: noviceReduction,
        );
    }
  }

  static SkatingDayIntent dayIntent({
    required SkatingModalityProfile profile,
    required SkatingPreparationPhase phase,
    required int dayIndex,
    required bool taperRecommended,
    required bool forceRecovery,
    required bool blockIntensity,
  }) {
    if (forceRecovery) {
      return const SkatingDayIntent(
        title: 'Recuperación prioritaria',
        objective:
            'Bajar carga, recuperar sistema nervioso y mantener movilidad sin fatigar.',
        primaryStimulus: 'Recuperación',
        secondaryStimulus: 'Movilidad',
        includeStrength: false,
        includePlyometrics: false,
        includeSkating: false,
        includeCycling: true,
        includeCore: true,
        includeUpperBody: false,
        includeAntagonists: true,
        includeMobility: true,
        recoveryFocused: true,
        highIntensityAllowed: false,
        lactateAllowed: false,
        maxSpeedAllowed: false,
      );
    }

    if (taperRecommended || phase == SkatingPreparationPhase.preCompetition) {
      return _taperIntent(profile: profile, dayIndex: dayIndex);
    }

    switch (profile.modality) {
      case SkatingModality.sprint:
        return _sprintDayIntent(
          phase: phase,
          dayIndex: dayIndex,
          blockIntensity: blockIntensity,
        );
      case SkatingModality.endurance:
        return _enduranceDayIntent(
          phase: phase,
          dayIndex: dayIndex,
          blockIntensity: blockIntensity,
        );
      case SkatingModality.mixed:
        return _mixedDayIntent(
          phase: phase,
          dayIndex: dayIndex,
          blockIntensity: blockIntensity,
        );
    }
  }

  static SkatingPreparationPhase phaseFromCompetitionDistance({
    required int daysToMainCompetition,
  }) {
    if (daysToMainCompetition <= 0) return SkatingPreparationPhase.competition;
    if (daysToMainCompetition <= 10) {
      return SkatingPreparationPhase.preCompetition;
    }
    if (daysToMainCompetition <= 35) {
      return SkatingPreparationPhase.specificPreparation;
    }
    return SkatingPreparationPhase.generalPreparation;
  }

  static SkatingPreparationPhase phaseFromWeekProgress(double progress) {
    if (progress < 0.45) return SkatingPreparationPhase.generalPreparation;
    if (progress < 0.80) return SkatingPreparationPhase.specificPreparation;
    if (progress < 0.95) return SkatingPreparationPhase.preCompetition;
    return SkatingPreparationPhase.competition;
  }

  static SkatingWeeklyDose _sprintWeeklyDose({
    required SkatingPreparationPhase phase,
    required int eliteBonus,
    required int noviceReduction,
  }) {
    switch (phase) {
      case SkatingPreparationPhase.generalPreparation:
        return SkatingWeeklyDose(
          skatingDays: 4,
          strengthDays: (3 + eliteBonus - noviceReduction).clamp(1, 4),
          plyometricDays: (2 + eliteBonus - noviceReduction).clamp(1, 3),
          cyclingDays: 1,
          coreDays: 3,
          upperBodyDays: 2,
          antagonistDays: 2,
          mobilityDays: 4,
          recoveryDays: 1,
          primaryFocus: 'Fuerza máxima, potencia base y técnica.',
          secondaryFocus: 'Base aeróbica mínima y tolerancia a rondas.',
          coachingNote:
              'El velocista debe construir motor neuromuscular sin perder capacidad de recuperación.',
        );
      case SkatingPreparationPhase.specificPreparation:
        return SkatingWeeklyDose(
          skatingDays: 4,
          strengthDays: (2 + eliteBonus - noviceReduction).clamp(1, 3),
          plyometricDays: 2,
          cyclingDays: 1,
          coreDays: 3,
          upperBodyDays: 1,
          antagonistDays: 2,
          mobilityDays: 4,
          recoveryDays: 1,
          primaryFocus: 'Salidas, aceleración y velocidad máxima.',
          secondaryFocus: 'Fuerza potencia, lactato controlado y técnica.',
          coachingNote:
              'La fuerza se transforma hacia velocidad específica y calidad de pista.',
        );
      case SkatingPreparationPhase.preCompetition:
        return const SkatingWeeklyDose(
          skatingDays: 4,
          strengthDays: 1,
          plyometricDays: 1,
          cyclingDays: 1,
          coreDays: 2,
          upperBodyDays: 1,
          antagonistDays: 1,
          mobilityDays: 5,
          recoveryDays: 2,
          primaryFocus: 'Frescura, velocidad técnica y confianza.',
          secondaryFocus: 'Mantener chispa sin generar fatiga.',
          coachingNote:
              'En taper no se gana forma: se protege velocidad y se baja fatiga.',
        );
      case SkatingPreparationPhase.competition:
        return const SkatingWeeklyDose(
          skatingDays: 3,
          strengthDays: 0,
          plyometricDays: 0,
          cyclingDays: 1,
          coreDays: 1,
          upperBodyDays: 0,
          antagonistDays: 1,
          mobilityDays: 4,
          recoveryDays: 2,
          primaryFocus: 'Competir fresco y rápido.',
          secondaryFocus: 'Activación, movilidad y recuperación.',
          coachingNote:
              'La prioridad es rendimiento competitivo, no acumular carga.',
        );
      case SkatingPreparationPhase.transition:
        return const SkatingWeeklyDose(
          skatingDays: 2,
          strengthDays: 1,
          plyometricDays: 0,
          cyclingDays: 1,
          coreDays: 2,
          upperBodyDays: 1,
          antagonistDays: 2,
          mobilityDays: 4,
          recoveryDays: 3,
          primaryFocus: 'Recuperación y reconstrucción.',
          secondaryFocus: 'Movilidad, estabilidad y base suave.',
          coachingNote:
              'Descargar sin perder hábitos de movimiento ni tono general.',
        );
    }
  }

  static SkatingWeeklyDose _enduranceWeeklyDose({
    required SkatingPreparationPhase phase,
    required int eliteBonus,
    required int noviceReduction,
  }) {
    switch (phase) {
      case SkatingPreparationPhase.generalPreparation:
        return SkatingWeeklyDose(
          skatingDays: (5 + eliteBonus - noviceReduction).clamp(3, 6),
          strengthDays: 2,
          plyometricDays: 1,
          cyclingDays: 2,
          coreDays: 3,
          upperBodyDays: 1,
          antagonistDays: 2,
          mobilityDays: 4,
          recoveryDays: 1,
          primaryFocus: 'Base aeróbica, fuerza general y economía técnica.',
          secondaryFocus:
              'Mantener aceleraciones cortas y coordinación neuromuscular.',
          coachingNote:
              'El fondista no es solo volumen: debe conservar velocidad y capacidad de cambio.',
        );
      case SkatingPreparationPhase.specificPreparation:
        return SkatingWeeklyDose(
          skatingDays: (5 + eliteBonus - noviceReduction).clamp(3, 6),
          strengthDays: 2,
          plyometricDays: 1,
          cyclingDays: 1,
          coreDays: 3,
          upperBodyDays: 1,
          antagonistDays: 2,
          mobilityDays: 4,
          recoveryDays: 1,
          primaryFocus:
              'Resistencia específica, cambios de ritmo, puntos y eliminación.',
          secondaryFocus: 'Fuerza resistencia, remate y velocidad bajo fatiga.',
          coachingNote:
              'Las pruebas de fondo exigen acelerar, responder ataques y cerrar fuerte.',
        );
      case SkatingPreparationPhase.preCompetition:
        return const SkatingWeeklyDose(
          skatingDays: 4,
          strengthDays: 1,
          plyometricDays: 1,
          cyclingDays: 1,
          coreDays: 2,
          upperBodyDays: 1,
          antagonistDays: 1,
          mobilityDays: 5,
          recoveryDays: 2,
          primaryFocus: 'Afinar ritmo, remate y frescura.',
          secondaryFocus: 'Reducir volumen manteniendo chispa.',
          coachingNote:
              'El taper de fondo conserva ritmo competitivo y sprint final sin fatigar.',
        );
      case SkatingPreparationPhase.competition:
        return const SkatingWeeklyDose(
          skatingDays: 3,
          strengthDays: 0,
          plyometricDays: 0,
          cyclingDays: 1,
          coreDays: 1,
          upperBodyDays: 0,
          antagonistDays: 1,
          mobilityDays: 4,
          recoveryDays: 2,
          primaryFocus: 'Competir con energía y capacidad de remate.',
          secondaryFocus: 'Activación, movilidad y recuperación.',
          coachingNote:
              'En competencia se protege frescura para responder ataques y rematar.',
        );
      case SkatingPreparationPhase.transition:
        return const SkatingWeeklyDose(
          skatingDays: 2,
          strengthDays: 1,
          plyometricDays: 0,
          cyclingDays: 2,
          coreDays: 2,
          upperBodyDays: 1,
          antagonistDays: 2,
          mobilityDays: 4,
          recoveryDays: 3,
          primaryFocus: 'Recuperar, descargar y mantener base suave.',
          secondaryFocus: 'Movilidad, técnica y estabilidad.',
          coachingNote:
              'Transición no significa parar todo: se baja carga y se restaura.',
        );
    }
  }

  static SkatingWeeklyDose _mixedWeeklyDose({
    required SkatingPreparationPhase phase,
    required int eliteBonus,
    required int noviceReduction,
  }) {
    switch (phase) {
      case SkatingPreparationPhase.generalPreparation:
        return SkatingWeeklyDose(
          skatingDays: 4,
          strengthDays: 2,
          plyometricDays: 1,
          cyclingDays: 1,
          coreDays: 3,
          upperBodyDays: 1,
          antagonistDays: 2,
          mobilityDays: 4,
          recoveryDays: 1,
          primaryFocus: 'Base, fuerza, técnica y tolerancia a la carga.',
          secondaryFocus: 'Velocidad técnica y resistencia específica mínima.',
          coachingNote:
              'El perfil mixto necesita equilibrio entre potencia, ritmo y recuperación.',
        );
      case SkatingPreparationPhase.specificPreparation:
        return SkatingWeeklyDose(
          skatingDays: 5,
          strengthDays: 2,
          plyometricDays: 1,
          cyclingDays: 1,
          coreDays: 3,
          upperBodyDays: 1,
          antagonistDays: 2,
          mobilityDays: 4,
          recoveryDays: 1,
          primaryFocus: 'Velocidad específica, ritmo y lactato controlado.',
          secondaryFocus: 'Fuerza potencia, táctica y cambios de ritmo.',
          coachingNote:
              'El mixto debe sostener intensidad y tener capacidad de acelerar.',
        );
      case SkatingPreparationPhase.preCompetition:
        return const SkatingWeeklyDose(
          skatingDays: 4,
          strengthDays: 1,
          plyometricDays: 1,
          cyclingDays: 1,
          coreDays: 2,
          upperBodyDays: 1,
          antagonistDays: 1,
          mobilityDays: 5,
          recoveryDays: 2,
          primaryFocus: 'Frescura, velocidad, ritmo y precisión técnica.',
          secondaryFocus: 'Mantener estímulo sin acumular fatiga.',
          coachingNote:
              'El taper mixto protege tanto velocidad como ritmo competitivo.',
        );
      case SkatingPreparationPhase.competition:
        return const SkatingWeeklyDose(
          skatingDays: 3,
          strengthDays: 0,
          plyometricDays: 0,
          cyclingDays: 1,
          coreDays: 1,
          upperBodyDays: 0,
          antagonistDays: 1,
          mobilityDays: 4,
          recoveryDays: 2,
          primaryFocus: 'Competir con velocidad, ritmo y frescura.',
          secondaryFocus: 'Activación y recuperación.',
          coachingNote:
              'La prioridad es competir, no buscar adaptaciones nuevas.',
        );
      case SkatingPreparationPhase.transition:
        return const SkatingWeeklyDose(
          skatingDays: 2,
          strengthDays: 1,
          plyometricDays: 0,
          cyclingDays: 1,
          coreDays: 2,
          upperBodyDays: 1,
          antagonistDays: 2,
          mobilityDays: 4,
          recoveryDays: 3,
          primaryFocus: 'Recuperación activa y reconstrucción.',
          secondaryFocus: 'Movilidad, core y técnica suave.',
          coachingNote:
              'Se descarga manteniendo estructura mínima de movimiento.',
        );
    }
  }

  static SkatingDayIntent _sprintDayIntent({
    required SkatingPreparationPhase phase,
    required int dayIndex,
    required bool blockIntensity,
  }) {
    if (blockIntensity) {
      return const SkatingDayIntent(
        title: 'Velocidad técnica controlada',
        objective:
            'Conservar coordinación y postura de velocidad sin acumular fatiga.',
        primaryStimulus: 'Técnica',
        secondaryStimulus: 'Movilidad',
        includeStrength: false,
        includePlyometrics: false,
        includeSkating: true,
        includeCycling: false,
        includeCore: true,
        includeUpperBody: false,
        includeAntagonists: true,
        includeMobility: true,
        recoveryFocused: false,
        highIntensityAllowed: false,
        lactateAllowed: false,
        maxSpeedAllowed: false,
      );
    }

    final day = dayIndex % 7;

    if (phase == SkatingPreparationPhase.generalPreparation) {
      if (day == 0 || day == 3) {
        return const SkatingDayIntent(
          title: 'Fuerza máxima + técnica',
          objective:
              'Construir base de fuerza para empuje lateral, salida y posición baja.',
          primaryStimulus: 'Fuerza máxima',
          secondaryStimulus: 'Técnica',
          includeStrength: true,
          includePlyometrics: false,
          includeSkating: true,
          includeCycling: false,
          includeCore: true,
          includeUpperBody: true,
          includeAntagonists: true,
          includeMobility: true,
          recoveryFocused: false,
          highIntensityAllowed: true,
          lactateAllowed: false,
          maxSpeedAllowed: false,
        );
      }

      if (day == 2 || day == 5) {
        return const SkatingDayIntent(
          title: 'Potencia + aceleración',
          objective:
              'Transformar fuerza en aceleración y contactos rápidos de calidad.',
          primaryStimulus: 'Potencia',
          secondaryStimulus: 'Aceleración',
          includeStrength: true,
          includePlyometrics: true,
          includeSkating: true,
          includeCycling: false,
          includeCore: true,
          includeUpperBody: false,
          includeAntagonists: true,
          includeMobility: true,
          recoveryFocused: false,
          highIntensityAllowed: true,
          lactateAllowed: false,
          maxSpeedAllowed: true,
        );
      }
    }

    if (phase == SkatingPreparationPhase.specificPreparation) {
      if (day == 1 || day == 4) {
        return const SkatingDayIntent(
          title: 'Salidas + velocidad máxima',
          objective:
              'Desarrollar salida, aceleración y velocidad específica con recuperación completa.',
          primaryStimulus: 'Velocidad',
          secondaryStimulus: 'Potencia',
          includeStrength: true,
          includePlyometrics: true,
          includeSkating: true,
          includeCycling: false,
          includeCore: true,
          includeUpperBody: false,
          includeAntagonists: true,
          includeMobility: true,
          recoveryFocused: false,
          highIntensityAllowed: true,
          lactateAllowed: false,
          maxSpeedAllowed: true,
        );
      }

      if (day == 3) {
        return const SkatingDayIntent(
          title: 'Resistencia específica de velocidad',
          objective:
              'Sostener velocidad y tolerar rondas sin perder técnica ni postura.',
          primaryStimulus: 'Velocidad prolongada',
          secondaryStimulus: 'Tolerancia lactato',
          includeStrength: false,
          includePlyometrics: false,
          includeSkating: true,
          includeCycling: false,
          includeCore: true,
          includeUpperBody: false,
          includeAntagonists: true,
          includeMobility: true,
          recoveryFocused: false,
          highIntensityAllowed: true,
          lactateAllowed: true,
          maxSpeedAllowed: false,
        );
      }
    }

    return const SkatingDayIntent(
      title: 'Recuperación activa y movilidad',
      objective: 'Facilitar recuperación manteniendo tono, movilidad y core.',
      primaryStimulus: 'Recuperación',
      secondaryStimulus: 'Core',
      includeStrength: false,
      includePlyometrics: false,
      includeSkating: false,
      includeCycling: true,
      includeCore: true,
      includeUpperBody: false,
      includeAntagonists: true,
      includeMobility: true,
      recoveryFocused: true,
      highIntensityAllowed: false,
      lactateAllowed: false,
      maxSpeedAllowed: false,
    );
  }

  static SkatingDayIntent _enduranceDayIntent({
    required SkatingPreparationPhase phase,
    required int dayIndex,
    required bool blockIntensity,
  }) {
    if (blockIntensity) {
      return const SkatingDayIntent(
        title: 'Base aeróbica controlada',
        objective:
            'Mantener volumen suave y técnica eficiente sin agregar intensidad.',
        primaryStimulus: 'Base aeróbica',
        secondaryStimulus: 'Técnica',
        includeStrength: false,
        includePlyometrics: false,
        includeSkating: true,
        includeCycling: true,
        includeCore: true,
        includeUpperBody: false,
        includeAntagonists: true,
        includeMobility: true,
        recoveryFocused: false,
        highIntensityAllowed: false,
        lactateAllowed: false,
        maxSpeedAllowed: false,
      );
    }

    final day = dayIndex % 7;

    if (phase == SkatingPreparationPhase.generalPreparation) {
      if (day == 0 || day == 3) {
        return const SkatingDayIntent(
          title: 'Base aeróbica + fuerza general',
          objective:
              'Construir motor aeróbico, fuerza estructural y economía técnica.',
          primaryStimulus: 'Base aeróbica',
          secondaryStimulus: 'Fuerza general',
          includeStrength: true,
          includePlyometrics: false,
          includeSkating: true,
          includeCycling: true,
          includeCore: true,
          includeUpperBody: true,
          includeAntagonists: true,
          includeMobility: true,
          recoveryFocused: false,
          highIntensityAllowed: false,
          lactateAllowed: false,
          maxSpeedAllowed: false,
        );
      }

      if (day == 2 || day == 5) {
        return const SkatingDayIntent(
          title: 'Ritmo aeróbico + aceleraciones cortas',
          objective:
              'Desarrollar base sin perder cambios de ritmo ni capacidad de acelerar.',
          primaryStimulus: 'Resistencia',
          secondaryStimulus: 'Aceleraciones',
          includeStrength: false,
          includePlyometrics: true,
          includeSkating: true,
          includeCycling: false,
          includeCore: true,
          includeUpperBody: false,
          includeAntagonists: true,
          includeMobility: true,
          recoveryFocused: false,
          highIntensityAllowed: true,
          lactateAllowed: false,
          maxSpeedAllowed: false,
        );
      }
    }

    if (phase == SkatingPreparationPhase.specificPreparation) {
      if (day == 1 || day == 4) {
        return const SkatingDayIntent(
          title: 'Cambios de ritmo + puntos',
          objective:
              'Preparar ataques, metas volantes, puntos y capacidad de responder aceleraciones.',
          primaryStimulus: 'Resistencia específica',
          secondaryStimulus: 'Táctica',
          includeStrength: false,
          includePlyometrics: false,
          includeSkating: true,
          includeCycling: false,
          includeCore: true,
          includeUpperBody: false,
          includeAntagonists: true,
          includeMobility: true,
          recoveryFocused: false,
          highIntensityAllowed: true,
          lactateAllowed: true,
          maxSpeedAllowed: false,
        );
      }

      if (day == 3) {
        return const SkatingDayIntent(
          title: 'Remate bajo fatiga',
          objective:
              'Entrenar cierre fuerte, sprint final y velocidad después de carga aeróbica.',
          primaryStimulus: 'Velocidad bajo fatiga',
          secondaryStimulus: 'Tolerancia lactato',
          includeStrength: true,
          includePlyometrics: true,
          includeSkating: true,
          includeCycling: false,
          includeCore: true,
          includeUpperBody: false,
          includeAntagonists: true,
          includeMobility: true,
          recoveryFocused: false,
          highIntensityAllowed: true,
          lactateAllowed: true,
          maxSpeedAllowed: true,
        );
      }
    }

    return const SkatingDayIntent(
      title: 'Recuperación aeróbica',
      objective:
          'Facilitar recuperación, mantener circulación y consolidar adaptación.',
      primaryStimulus: 'Recuperación',
      secondaryStimulus: 'Movilidad',
      includeStrength: false,
      includePlyometrics: false,
      includeSkating: false,
      includeCycling: true,
      includeCore: true,
      includeUpperBody: false,
      includeAntagonists: true,
      includeMobility: true,
      recoveryFocused: true,
      highIntensityAllowed: false,
      lactateAllowed: false,
      maxSpeedAllowed: false,
    );
  }

  static SkatingDayIntent _mixedDayIntent({
    required SkatingPreparationPhase phase,
    required int dayIndex,
    required bool blockIntensity,
  }) {
    if (blockIntensity) {
      return const SkatingDayIntent(
        title: 'Técnica + base controlada',
        objective:
            'Mantener calidad técnica y base suave sin añadir fatiga intensa.',
        primaryStimulus: 'Técnica',
        secondaryStimulus: 'Base aeróbica',
        includeStrength: false,
        includePlyometrics: false,
        includeSkating: true,
        includeCycling: true,
        includeCore: true,
        includeUpperBody: false,
        includeAntagonists: true,
        includeMobility: true,
        recoveryFocused: false,
        highIntensityAllowed: false,
        lactateAllowed: false,
        maxSpeedAllowed: false,
      );
    }

    final day = dayIndex % 7;

    if (day == 0 || day == 3) {
      return const SkatingDayIntent(
        title: 'Fuerza potencia + patines',
        objective:
            'Combinar fuerza, potencia y transferencia técnica hacia pista.',
        primaryStimulus: 'Fuerza potencia',
        secondaryStimulus: 'Técnica',
        includeStrength: true,
        includePlyometrics: true,
        includeSkating: true,
        includeCycling: false,
        includeCore: true,
        includeUpperBody: true,
        includeAntagonists: true,
        includeMobility: true,
        recoveryFocused: false,
        highIntensityAllowed: true,
        lactateAllowed: false,
        maxSpeedAllowed: true,
      );
    }

    if (day == 2 || day == 5) {
      return const SkatingDayIntent(
        title: 'Ritmo + aceleraciones',
        objective:
            'Sostener ritmo competitivo con cambios de velocidad y cierre fuerte.',
        primaryStimulus: 'Ritmo competitivo',
        secondaryStimulus: 'Aceleraciones',
        includeStrength: false,
        includePlyometrics: false,
        includeSkating: true,
        includeCycling: false,
        includeCore: true,
        includeUpperBody: false,
        includeAntagonists: true,
        includeMobility: true,
        recoveryFocused: false,
        highIntensityAllowed: true,
        lactateAllowed: true,
        maxSpeedAllowed: true,
      );
    }

    return const SkatingDayIntent(
      title: 'Recuperación + movilidad',
      objective: 'Recuperar, mantener movilidad y preparar siguiente estímulo.',
      primaryStimulus: 'Recuperación',
      secondaryStimulus: 'Core',
      includeStrength: false,
      includePlyometrics: false,
      includeSkating: false,
      includeCycling: true,
      includeCore: true,
      includeUpperBody: false,
      includeAntagonists: true,
      includeMobility: true,
      recoveryFocused: true,
      highIntensityAllowed: false,
      lactateAllowed: false,
      maxSpeedAllowed: false,
    );
  }

  static SkatingDayIntent _taperIntent({
    required SkatingModalityProfile profile,
    required int dayIndex,
  }) {
    final day = dayIndex % 7;

    if (day == 1 || day == 4) {
      return SkatingDayIntent(
        title: profile.isEndurance
            ? 'Ritmo competitivo corto + remate'
            : 'Velocidad corta + activación',
        objective: profile.isEndurance
            ? 'Mantener ritmo, cambios cortos y remate sin acumular fatiga.'
            : 'Mantener chispa, salida y velocidad técnica sin generar fatiga nueva.',
        primaryStimulus: profile.isEndurance ? 'Ritmo' : 'Velocidad',
        secondaryStimulus: 'Técnica',
        includeStrength: false,
        includePlyometrics: true,
        includeSkating: true,
        includeCycling: false,
        includeCore: true,
        includeUpperBody: false,
        includeAntagonists: true,
        includeMobility: true,
        recoveryFocused: false,
        highIntensityAllowed: true,
        lactateAllowed: false,
        maxSpeedAllowed: true,
      );
    }

    return const SkatingDayIntent(
      title: 'Frescura y movilidad',
      objective:
          'Proteger recuperación, sueño, movilidad y sensación de velocidad.',
      primaryStimulus: 'Recuperación',
      secondaryStimulus: 'Movilidad',
      includeStrength: false,
      includePlyometrics: false,
      includeSkating: false,
      includeCycling: true,
      includeCore: true,
      includeUpperBody: false,
      includeAntagonists: true,
      includeMobility: true,
      recoveryFocused: true,
      highIntensityAllowed: false,
      lactateAllowed: false,
      maxSpeedAllowed: false,
    );
  }
}


