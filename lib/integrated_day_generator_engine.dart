import 'athlete_program_service.dart';
import 'athlete_performance_context.dart';
import 'daily_training_block.dart';
import 'integrated_training_day.dart';
import 'session_selection_engine.dart';
import 'skating_modality_planning_bridge.dart';
import 'training_library/training_library_models.dart';
import 'training_progression_engine.dart';
import 'training_progression_block_builder.dart';

enum _SeasonDayMode {
  normal,
  generalPreparation,
  specificPreparation,
  competition,
  taper,
  transition,
  postCompetitionDeload,
}

enum _BlockPriority { critical, important, optional }

class _AdaptiveModifiers {
  final double volume;
  final double intensity;

  final double strength;
  final double speed;
  final double endurance;

  final double power;
  final double technical;
  final double tactical;
  final double recovery;
  final double plyometric;
  final double core;
  final double upperBody;
  final double bike;

  const _AdaptiveModifiers({
    required this.volume,
    required this.intensity,
    required this.strength,
    required this.speed,
    required this.endurance,
    required this.power,
    required this.technical,
    required this.tactical,
    required this.recovery,
    required this.plyometric,
    required this.core,
    required this.upperBody,
    required this.bike,
  });
}

class _PrioritizedBlock {
  final DailyTrainingBlock block;
  final _BlockPriority priority;

  const _PrioritizedBlock({required this.block, required this.priority});
}

class IntegratedDayGeneratorEngine {
  static IntegratedTrainingDay generate({
    required AthletePerformanceContext context,
    required DateTime date,
  }) {
    final athlete = context.athlete;
    final readiness = context.currentReadiness;
    final fatigue = context.currentFatigueStatus;
    final injuryRisk = context.currentInjuryRisk;
    final acwr = context.fatigueTrend;

    final week = _findWeekForDate(athlete, date);
    final daysToCompetition = _daysToNextCompetition(athlete, date);
    final mode = _seasonModeFromWeek(week, daysToCompetition);

    final specialization =
        SkatingModalityPlanningBridge.specializationForAthlete(athlete);

    final skatingPhase = SkatingModalityPlanningBridge.phaseFromWeek(week);

    final modalityDistribution = SkatingModalityPlanningBridge.distribution(
      specialization: specialization,
      phase: skatingPhase,
    );

    final modifiers = _buildModifiers(
      context: context,
      readiness: readiness,
      injuryRisk: injuryRisk,
      acwr: acwr,
      distribution: modalityDistribution,
      specialization: specialization,
      phase: skatingPhase,
    );

    if (readiness < 40 ||
        fatigue == 'red' ||
        injuryRisk > 75 ||
        context.possibleOvertraining) {
      return _finalizeGeneratedDay(
        _recoveryDay(
          date: date,
          readiness: readiness,
          fatigue: fatigue,
          reason:
              'Fatiga crítica, alto riesgo o posible sobrecarga. Se bloquea intensidad, fuerza pesada y pliometría.',
          week: week,
        ),
      );
    }

    if (week?.postCompetitionDeload == true ||
        mode == _SeasonDayMode.transition) {
      return _finalizeGeneratedDay(
        _deloadDay(
          date: date,
          readiness: readiness,
          fatigue: fatigue,
          acwr: acwr,
          week: week,
          reason: 'Semana de transición o descarga post competencia.',
        ),
      );
    }

    if (week?.taperWeek == true ||
        mode == _SeasonDayMode.taper ||
        daysToCompetition <= 3) {
      return _finalizeGeneratedDay(
        _taperDay(
          context: context,
          date: date,
          readiness: readiness,
          fatigue: fatigue,
          daysToCompetition: daysToCompetition,
          week: week,
        ),
      );
    }

    if (acwr > 1.4 && readiness < 65) {
      return _finalizeGeneratedDay(
        _deloadDay(
          date: date,
          readiness: readiness,
          fatigue: fatigue,
          acwr: acwr,
          week: week,
          reason: 'ACWR elevado y readiness bajo/moderado.',
        ),
      );
    }

    if (readiness < 60 || fatigue == 'orange' || injuryRisk > 60) {
      return _finalizeGeneratedDay(
        _controlledTechnicalDay(
          date: date,
          readiness: readiness,
          fatigue: fatigue,
          week: week,
          reason:
              'Readiness bajo, fatiga moderada o riesgo elevado. Se baja intensidad, se elimina pliometría fuerte y se mantiene técnica.',
        ),
      );
    }

    if (mode == _SeasonDayMode.competition || daysToCompetition <= 7) {
      return _finalizeGeneratedDay(
        _preCompetitionDay(
          context: context,
          date: date,
          readiness: readiness,
          fatigue: fatigue,
          daysToCompetition: daysToCompetition,
          week: week,
        ),
      );
    }

    if (mode == _SeasonDayMode.generalPreparation) {
      return _finalizeGeneratedDay(
        _generalPreparationDay(
          athlete: athlete,
          context: context,
          date: date,
          readiness: readiness,
          fatigue: fatigue,
          week: week,
          modifiers: modifiers,
        ),
      );
    }

    if (mode == _SeasonDayMode.specificPreparation) {
      return _finalizeGeneratedDay(
        _specificPreparationDay(
          athlete: athlete,
          context: context,
          date: date,
          readiness: readiness,
          fatigue: fatigue,
          week: week,
          modifiers: modifiers,
        ),
      );
    }

    switch (athlete.type) {
      case AthleteProgramType.sprinter:
        return _finalizeGeneratedDay(
          _sprinterDay(
            context: context,
            date: date,
            readiness: readiness,
            fatigue: fatigue,
            highReadiness: readiness >= 80,
            week: week,
            modifiers: modifiers,
          ),
        );

      case AthleteProgramType.endurance:
        return _finalizeGeneratedDay(
          _enduranceDay(
            context: context,
            date: date,
            readiness: readiness,
            fatigue: fatigue,
            highReadiness: readiness >= 80,
            week: week,
            modifiers: modifiers,
          ),
        );

      case AthleteProgramType.mixed:
        return _finalizeGeneratedDay(
          _mixedDay(
            context: context,
            date: date,
            readiness: readiness,
            fatigue: fatigue,
            highReadiness: readiness >= 80,
            week: week,
            modifiers: modifiers,
          ),
        );
    }
  }

  static IntegratedTrainingDay _finalizeGeneratedDay(
    IntegratedTrainingDay day,
  ) {
    final professionalDay = _professionalizeDay(day);

    if (professionalDay.recoveryDay || professionalDay.taperMode) {
      return professionalDay;
    }

    final readiness = professionalDay.expectedReadiness;
    final fatigue = professionalDay.expectedFatigue.toLowerCase();

    if (fatigue == 'red' || fatigue == 'orange') {
      return professionalDay;
    }

    if (readiness < 72) {
      return professionalDay;
    }

    final hasEveningBlock = professionalDay.blocks.any(
      (block) => block.moment == TrainingBlockMoment.evening,
    );

    final hasCycling = professionalDay.blocks.any(
      (block) => block.type == TrainingBlockType.cycling,
    );

    final hasHighNeural = professionalDay.blocks.any(
      (block) => block.neuromuscularLoad == NeuromuscularLoad.high ||
          block.neuromuscularLoad == NeuromuscularLoad.maximal,
    );

    final targets = <TrainingProgressionTarget>[];

    if (readiness >= 78 && !hasCycling) {
      targets.add(TrainingProgressionTarget.cyclingVolume);
    }

    if (readiness >= 84 && !hasHighNeural) {
      targets.add(TrainingProgressionTarget.gymPower);
    }

    if (readiness >= 86 && !hasEveningBlock) {
      targets.add(TrainingProgressionTarget.plyometrics);
    }

    if (targets.isEmpty) {
      return professionalDay;
    }

    final decision = TrainingProgressionDecision(
      mode: readiness >= 86
          ? TrainingProgressionMode.addThirdSession
          : TrainingProgressionMode.addSecondSession,
      targets: targets,
      recommendedSessions: readiness >= 86 ? 3 : 2,
      volumeMultiplier: readiness >= 86 ? 1.10 : 1.05,
      intensityMultiplier: readiness >= 86 ? 1.06 : 1.02,
      gymMultiplier: readiness >= 86 ? 1.08 : 1.03,
      plyometricMultiplier: readiness >= 86 ? 1.04 : 0.0,
      reason:
          'Expansi�n autom�tica: el atleta muestra readiness suficiente para a�adir carga controlada.',
    );

    final extraBlocks = TrainingProgressionBlockBuilder.buildExtraBlocks(
      decision: decision,
    );

    if (extraBlocks.isEmpty) {
      return professionalDay;
    }

    final availableExtraBlocks = extraBlocks.where((extraBlock) {
      final sameMoment = professionalDay.blocks.any(
        (block) => block.moment == extraBlock.moment,
      );

      if (sameMoment) {
        return false;
      }

      if (extraBlock.stimulus == TrainingStimulus.plyometric &&
          hasHighNeural) {
        return false;
      }

      return true;
    }).toList();

    if (availableExtraBlocks.isEmpty) {
      return professionalDay;
    }

    final maxBlocks = readiness >= 86 ? 4 : 3;

    final remainingSlots =
        (maxBlocks - professionalDay.blocks.length).clamp(0, 4).toInt();

    if (remainingSlots <= 0) {
      return professionalDay;
    }

    return professionalDay.copyWith(
      blocks: [
        ...professionalDay.blocks,
        ...availableExtraBlocks.take(remainingSlots),
      ],
    );
  }
  static _AdaptiveModifiers _buildModifiers({
    required AthletePerformanceContext context,
    required int readiness,
    required double injuryRisk,
    required double acwr,
    required ModalityTrainingDistribution distribution,
    required SkatingSpecialization specialization,
    required SkatingSeasonPhase phase,
  }) {
    final profile = context.physiologyProfile;

    double volume = 1.0;
    double intensity = 1.0;

    double strength = profile.strengthResponse;
    double speed = profile.speedResponse;
    double endurance = profile.enduranceResponse;

    double power = 1.0;
    double technical = 1.0;
    double tactical = 1.0;
    double recovery = 1.0;
    double plyometric = 1.0;
    double core = 1.0;
    double upperBody = 1.0;
    double bike = 1.0;

    if (readiness >= 85) {
      volume += 0.06;
      intensity += 0.06;
    } else if (readiness < 70) {
      volume -= 0.10;
      intensity -= 0.08;
    }

    if (profile.recoveryRate > 1.2 && readiness >= 75) {
      volume += 0.05;
    }

    if (profile.recoveryRate < 0.85) {
      volume -= 0.08;
    }

    if (profile.fatigueAccumulationRate > 1.25) {
      volume -= 0.10;
      intensity -= 0.08;
    }

    if (profile.fatigueAccumulationRate > 1.5) {
      volume -= 0.15;
      intensity -= 0.12;
    }

    if (injuryRisk > 55) {
      intensity -= 0.10;
      strength -= 0.08;
      speed -= 0.08;
      power -= 0.08;
      plyometric -= 0.12;
    }

    if (acwr > 1.3) {
      volume -= 0.10;
    }

    if (acwr > 1.5) {
      volume -= 0.18;
      intensity -= 0.08;
    }

    switch (specialization) {
      case SkatingSpecialization.sprint:
        speed += 0.12;
        power += 0.12;
        strength += 0.08;
        plyometric += 0.15;
        endurance -= 0.05;
        break;

      case SkatingSpecialization.endurance:
        endurance += 0.14;
        recovery += 0.10;
        tactical += 0.08;
        bike += 0.10;
        speed += 0.04;
        break;

      case SkatingSpecialization.mixed:
        speed += 0.06;
        endurance += 0.06;
        strength += 0.05;
        technical += 0.06;
        break;
    }

    switch (phase) {
      case SkatingSeasonPhase.general:
        volume += 0.08;
        strength += 0.08;
        endurance += 0.08;
        break;

      case SkatingSeasonPhase.specific:
        speed += 0.10;
        power += 0.08;
        technical += 0.08;
        tactical += 0.05;
        break;

      case SkatingSeasonPhase.competition:
        intensity += 0.06;
        speed += 0.12;
        recovery += 0.10;
        volume -= 0.08;
        break;

      case SkatingSeasonPhase.taper:
        volume -= 0.20;
        recovery += 0.20;
        speed += 0.10;
        plyometric -= 0.10;
        break;

      case SkatingSeasonPhase.transition:
        intensity -= 0.20;
        recovery += 0.25;
        bike += 0.15;
        strength -= 0.15;
        power -= 0.15;
        break;
    }

    strength *= (0.75 + distribution.strength);
    speed *= (0.75 + distribution.speed);
    endurance *= (0.75 + distribution.aerobic);

    power *= (0.75 + distribution.power);
    technical *= (0.75 + distribution.technical);
    tactical *= (0.75 + distribution.tactical);

    recovery *= (0.75 + distribution.recovery);
    plyometric *= (0.75 + distribution.plyometric);
    core *= (0.75 + distribution.core);
    upperBody *= (0.75 + distribution.upperBody);
    bike *= (0.75 + distribution.bike);

    return _AdaptiveModifiers(
      volume: volume.clamp(0.50, 1.25).toDouble(),
      intensity: intensity.clamp(0.50, 1.20).toDouble(),
      strength: strength.clamp(0.60, 1.40).toDouble(),
      speed: speed.clamp(0.60, 1.40).toDouble(),
      endurance: endurance.clamp(0.60, 1.40).toDouble(),
      power: power.clamp(0.60, 1.40).toDouble(),
      technical: technical.clamp(0.60, 1.40).toDouble(),
      tactical: tactical.clamp(0.60, 1.40).toDouble(),
      recovery: recovery.clamp(0.60, 1.50).toDouble(),
      plyometric: plyometric.clamp(0.40, 1.40).toDouble(),
      core: core.clamp(0.60, 1.30).toDouble(),
      upperBody: upperBody.clamp(0.60, 1.30).toDouble(),
      bike: bike.clamp(0.60, 1.40).toDouble(),
    );
  }

  static IntegratedTrainingDay _generalPreparationDay({
    required AthleteProgramProfile athlete,
    required AthletePerformanceContext context,
    required DateTime date,
    required int readiness,
    required String fatigue,
    required AthleteTrainingWeek? week,
    required _AdaptiveModifiers modifiers,
  }) {
    final profile = context.physiologyProfile;
    final highReadiness = readiness >= 80;
    final needsSpeed = profile.speedDevelopmentLevel < 65;
    final needsStrength = profile.strengthDevelopmentLevel < 65;

    return IntegratedTrainingDay(
      date: date,
      expectedReadiness: readiness,
      expectedFatigue: fatigue,
      taperMode: false,
      recoveryDay: false,
      aiSummary:
          '${_weekPrefix(week)}Preparación general: construir fuerza, base aeróbica, técnica y velocidad final. En patinaje de velocidad incluso el fondista necesita acelerar y rematar.',
      aiRecommendation:
          'Progresar sin romper adaptación. Priorizar fuerza útil, técnica y aceleraciones controladas.',
      blocks: [
        DailyTrainingBlock(
          type: TrainingBlockType.strength,
          moment: TrainingBlockMoment.morning,
          title: needsStrength
              ? 'Gimnasio: fuerza estructural prioritaria'
              : 'Gimnasio: fuerza estructural + core',
          description:
              'Calentamiento 10 min. Sentadilla o prensa 4x6, peso muerto rumano 3x8, zancadas 3x8 por pierna, core antirotación 3x30s, estabilidad de cadera y tobillo. Sin llegar al fallo.',
          durationMinutes: _minutes(highReadiness ? 65 : 55, modifiers.volume),
          km: 0,
          targetLoad: _load(
            highReadiness ? 70 : 58,
            modifiers.intensity * modifiers.strength,
          ),
          targetHeartRateZone: 2,
          recoveryFocused: false,
          taperFocused: false,
          aiReason:
              'Desarrolla base de fuerza para soportar volumen, curvas, empuje lateral y aceleraciones finales.',
          stimulus: TrainingStimulus.maxStrength,
          energySystem: TrainingEnergySystem.none,
          neuromuscularLoad: highReadiness
              ? NeuromuscularLoad.high
              : NeuromuscularLoad.moderate,
        ),
        _libraryBlockOrFallback(
          context: context,
          category: needsSpeed
              ? TrainingLibraryCategory.acceleration
              : TrainingLibraryCategory.endurance,
          needsNeural: needsSpeed,
          needsMetabolic: false,
          taperMode: false,
          moment: TrainingBlockMoment.afternoon,
          fallback: DailyTrainingBlock(
            type: TrainingBlockType.skating,
            moment: TrainingBlockMoment.afternoon,
            title: athlete.type == AthleteProgramType.endurance
                ? 'Patines: base aeróbica + aceleraciones finales'
                : 'Patines: técnica + base + progresivos',
            description:
                'Rodaje Z2 con postura baja, empuje lateral y curvas. Terminar con 6 progresivos de 12-15 segundos para mantener velocidad final sin fatigar.',
            durationMinutes: _minutes(
              highReadiness ? 75 : 60,
              modifiers.volume * modifiers.endurance,
            ),
            km: _km(highReadiness ? 16 : 12, modifiers.volume),
            targetLoad: _load(
              highReadiness ? 65 : 52,
              modifiers.intensity * modifiers.endurance,
            ),
            targetHeartRateZone: 2,
            recoveryFocused: false,
            taperFocused: false,
            aiReason:
                'Combina base aeróbica con velocidad final para que el atleta pueda responder ataques y cerrar fuerte.',
            stimulus: needsSpeed
                ? TrainingStimulus.speed
                : TrainingStimulus.aerobic,
            energySystem: TrainingEnergySystem.aerobic,
            neuromuscularLoad: needsSpeed
                ? NeuromuscularLoad.moderate
                : NeuromuscularLoad.low,
          ),
        ),
        if (_shouldInclude(modifiers.bike, threshold: 0.85))
          DailyTrainingBlock(
            type: TrainingBlockType.cycling,
            moment: TrainingBlockMoment.evening,
            title: 'Bicicleta regenerativa opcional',
            description:
                'Rodaje muy suave Z1. Solo si las piernas se sienten cargadas. Objetivo: circulación, no entrenamiento extra.',
            durationMinutes: _minutes(
              (20 * modifiers.bike).round(),
              modifiers.volume,
            ),
            km: 0,
            targetLoad: _load(15, modifiers.recovery),
            targetHeartRateZone: 1,
            recoveryFocused: true,
            taperFocused: false,
            aiReason:
                'La bicicleta facilita recuperación activa con bajo impacto mecánico.',
            stimulus: TrainingStimulus.recovery,
            energySystem: TrainingEnergySystem.aerobic,
            neuromuscularLoad: NeuromuscularLoad.low,
          ),
        if (_shouldInclude(modifiers.core, threshold: 0.85))
          DailyTrainingBlock(
            type: TrainingBlockType.mobility,
            moment: TrainingBlockMoment.evening,
            title: 'Core + estabilidad preventiva',
            description:
                'Core antirotación, estabilidad lumbo-pélvica, control de cadera y tobillo. Baja fatiga, alta calidad.',
            durationMinutes: _minutes((18 * modifiers.core).round(), 1.0),
            km: 0,
            targetLoad: _load(18, modifiers.core),
            targetHeartRateZone: 1,
            recoveryFocused: true,
            taperFocused: false,
            aiReason:
                'La estabilidad protege postura, curvas y transferencia de fuerza.',
            stimulus: TrainingStimulus.mobility,
            energySystem: TrainingEnergySystem.none,
            neuromuscularLoad: NeuromuscularLoad.low,
          ),
      ],
    );
  }

  static IntegratedTrainingDay _specificPreparationDay({
    required AthleteProgramProfile athlete,
    required AthletePerformanceContext context,
    required DateTime date,
    required int readiness,
    required String fatigue,
    required AthleteTrainingWeek? week,
    required _AdaptiveModifiers modifiers,
  }) {
    final highReadiness = readiness >= 80;

    if (athlete.type == AthleteProgramType.sprinter) {
      return _sprinterDay(
        context: context,
        date: date,
        readiness: readiness,
        fatigue: fatigue,
        highReadiness: highReadiness,
        week: week,
        modifiers: modifiers,
      );
    }

    if (athlete.type == AthleteProgramType.endurance) {
      return _enduranceSpecificDay(
        context: context,
        date: date,
        readiness: readiness,
        fatigue: fatigue,
        highReadiness: highReadiness,
        week: week,
        modifiers: modifiers,
      );
    }

    return _mixedDay(
      context: context,
      date: date,
      readiness: readiness,
      fatigue: fatigue,
      highReadiness: highReadiness,
      week: week,
      modifiers: modifiers,
    );
  }

  static IntegratedTrainingDay _sprinterDay({
    required AthletePerformanceContext context,
    required DateTime date,
    required int readiness,
    required String fatigue,
    required bool highReadiness,
    required AthleteTrainingWeek? week,
    required _AdaptiveModifiers modifiers,
  }) {
    final profile = context.physiologyProfile;
    final needsBase = profile.enduranceDevelopmentLevel < 55;

    final plannedBlocks = <_PrioritizedBlock>[
      _PrioritizedBlock(
        priority: _BlockPriority.important,
        block: DailyTrainingBlock(
          type: TrainingBlockType.activation,
          moment: TrainingBlockMoment.morning,
          title: 'Activación física + pliometría técnica',
          description:
              'Movilidad dinámica. Skips, pogos, saltos laterales suaves, 4-6 aceleraciones cortas. Contactos bajos, máxima calidad, descanso completo.',
          durationMinutes: _minutes(
            highReadiness ? 30 : 22,
            modifiers.volume * modifiers.speed,
          ),
          km: 0,
          targetLoad: _load(
            highReadiness ? 42 : 30,
            modifiers.intensity * modifiers.speed,
          ),
          targetHeartRateZone: 2,
          recoveryFocused: false,
          taperFocused: false,
          aiReason:
              'La pliometría conecta fuerza con velocidad en pista y se ajusta por speedResponse.',
          stimulus: TrainingStimulus.plyometric,
          energySystem: TrainingEnergySystem.anaerobicAlactic,
          neuromuscularLoad: highReadiness
              ? NeuromuscularLoad.high
              : NeuromuscularLoad.moderate,
        ),
      ),
      _PrioritizedBlock(
        priority: _BlockPriority.important,
        block: DailyTrainingBlock(
          type: TrainingBlockType.strength,
          moment: TrainingBlockMoment.morning,
          title: highReadiness
              ? 'Gimnasio: fuerza explosiva alta'
              : 'Gimnasio: fuerza explosiva controlada',
          description:
              'Levantamiento principal 4x3-5, fuerza unilateral 3x5 por pierna, hinge 3x5, core rígido 3 series. Evitar fallo. Transferencia a salida y empuje lateral.',
          durationMinutes: _minutes(
            highReadiness ? 60 : 50,
            modifiers.volume * modifiers.strength,
          ),
          km: 0,
          targetLoad: _load(
            highReadiness ? 78 : 65,
            modifiers.intensity * modifiers.strength,
          ),
          targetHeartRateZone: 2,
          recoveryFocused: false,
          taperFocused: false,
          aiReason:
              'Desarrolla potencia útil para salida, aceleración y velocidad máxima.',
          stimulus: TrainingStimulus.power,
          energySystem: TrainingEnergySystem.none,
          neuromuscularLoad: highReadiness
              ? NeuromuscularLoad.maximal
              : NeuromuscularLoad.high,
        ),
      ),
      _PrioritizedBlock(
        priority: _BlockPriority.critical,
        block: _libraryBlockOrFallback(
          context: context,
          category: TrainingLibraryCategory.acceleration,
          needsNeural: true,
          needsMetabolic: false,
          taperMode: false,
          moment: TrainingBlockMoment.afternoon,
          durationOverride: _minutes(highReadiness ? 75 : 60, modifiers.volume),
          kmOverride: _km(highReadiness ? 12 : 9, modifiers.volume),
          loadOverride: _load(
            highReadiness ? 85 : 70,
            modifiers.intensity * modifiers.speed,
          ),
          fallback: DailyTrainingBlock(
            type: TrainingBlockType.skating,
            moment: TrainingBlockMoment.afternoon,
            title: highReadiness
                ? 'Patines: salidas + velocidad máxima'
                : 'Patines: salidas técnicas + vueltas lanzadas',
            description:
                'Calentamiento técnico. 6-8 salidas cortas, 4-6 aceleraciones, 3-5 vueltas lanzadas o tramos rápidos. Recuperación completa. Técnica limpia antes que volumen.',
            durationMinutes: _minutes(
              highReadiness ? 75 : 60,
              modifiers.volume,
            ),
            km: _km(highReadiness ? 12 : 9, modifiers.volume),
            targetLoad: _load(
              highReadiness ? 85 : 70,
              modifiers.intensity * modifiers.speed,
            ),
            targetHeartRateZone: highReadiness ? 5 : 4,
            recoveryFocused: false,
            taperFocused: false,
            aiReason:
                'La velocidad se ajusta por speedResponse y por el estado fisiológico del día.',
            stimulus: TrainingStimulus.speed,
            energySystem: TrainingEnergySystem.anaerobicAlactic,
            neuromuscularLoad: highReadiness
                ? NeuromuscularLoad.maximal
                : NeuromuscularLoad.high,
          ),
        ),
      ),
      if (needsBase || modifiers.endurance > 0.95)
        _PrioritizedBlock(
          priority: _BlockPriority.optional,
          block: DailyTrainingBlock(
            type: TrainingBlockType.aerobic,
            moment: TrainingBlockMoment.evening,
            title: 'Base aeróbica regenerativa',
            description:
                'Bici o rodaje muy suave Z1-Z2. Mantener capacidad de recuperación entre esfuerzos rápidos y tolerancia de carga.',
            durationMinutes: _minutes(
              (18 * modifiers.endurance).round(),
              modifiers.volume,
            ),
            km: 0,
            targetLoad: _load(12, modifiers.recovery),
            targetHeartRateZone: 1,
            recoveryFocused: true,
            taperFocused: false,
            aiReason:
                'Incluso el velocista necesita base aeróbica para soportar rondas, bloques y recuperación.',
            stimulus: TrainingStimulus.aerobic,
            energySystem: TrainingEnergySystem.aerobic,
            neuromuscularLoad: NeuromuscularLoad.low,
          ),
        ),
      if (_shouldInclude(modifiers.plyometric, threshold: 0.95))
        _PrioritizedBlock(
          priority: _BlockPriority.optional,
          block: DailyTrainingBlock(
            type: TrainingBlockType.activation,
            moment: TrainingBlockMoment.evening,
            title: 'Pliometría complementaria de transferencia',
            description:
                'Saltos laterales reactivos, bounds cortos y contactos rápidos de baja dosis. Cortar si cae reactividad.',
            durationMinutes: _minutes((16 * modifiers.plyometric).round(), 1.0),
            km: 0,
            targetLoad: _load(22, modifiers.plyometric),
            targetHeartRateZone: 2,
            recoveryFocused: false,
            taperFocused: false,
            aiReason:
                'La pliometría mejora transferencia neural, rigidez útil y aceleración.',
            stimulus: TrainingStimulus.plyometric,
            energySystem: TrainingEnergySystem.anaerobicAlactic,
            neuromuscularLoad: NeuromuscularLoad.moderate,
          ),
        ),
    ];

    return IntegratedTrainingDay(
      date: date,
      expectedReadiness: readiness,
      expectedFatigue: fatigue,
      taperMode: false,
      recoveryDay: false,
      aiSummary: highReadiness
          ? '${_weekPrefix(week)}Día de calidad para velocista: fuerza explosiva, pliometría y velocidad específica.'
          : '${_weekPrefix(week)}Día integrado para velocista: potencia técnica sin exceder carga neuromuscular.',
      aiRecommendation:
          'La calidad manda. Si cae la técnica, se corta volumen. Mantener base mínima para tolerar rondas y recuperación.',
      blocks: _resolvePriorities(
        blocks: plannedBlocks,
        readiness: readiness,
        injuryRisk: context.currentInjuryRisk,
        acwr: context.fatigueTrend,
      ),
    );
  }

  static IntegratedTrainingDay _enduranceDay({
    required AthletePerformanceContext context,
    required DateTime date,
    required int readiness,
    required String fatigue,
    required bool highReadiness,
    required AthleteTrainingWeek? week,
    required _AdaptiveModifiers modifiers,
  }) {
    final profile = context.physiologyProfile;
    final needsFinish = profile.sprintFinishCapability < 70;
    final needsStrength = profile.strengthDevelopmentLevel < 70;

    final plannedBlocks = <_PrioritizedBlock>[
      _PrioritizedBlock(
        priority: _BlockPriority.critical,
        block: _libraryBlockOrFallback(
          context: context,
          category: TrainingLibraryCategory.endurance,
          needsNeural: false,
          needsMetabolic: false,
          taperMode: false,
          moment: TrainingBlockMoment.morning,
          durationOverride: _minutes(
            highReadiness ? 85 : 65,
            modifiers.volume * modifiers.endurance,
          ),
          kmOverride: _km(highReadiness ? 22 : 16, modifiers.volume),
          loadOverride: _load(
            highReadiness ? 75 : 60,
            modifiers.intensity * modifiers.endurance,
          ),
          fallback: DailyTrainingBlock(
            type: TrainingBlockType.skating,
            moment: TrainingBlockMoment.morning,
            title: highReadiness
                ? 'Patines: fondo aeróbico + cambios de ritmo'
                : 'Patines: rodaje aeróbico controlado',
            description:
                'Trabajo continuo Z2-Z3. Cada 8-10 min incluir cambio de ritmo corto de 15-20 s si la técnica está estable.',
            durationMinutes: _minutes(
              highReadiness ? 85 : 65,
              modifiers.volume * modifiers.endurance,
            ),
            km: _km(highReadiness ? 22 : 16, modifiers.volume),
            targetLoad: _load(
              highReadiness ? 75 : 60,
              modifiers.intensity * modifiers.endurance,
            ),
            targetHeartRateZone: 3,
            recoveryFocused: false,
            taperFocused: false,
            aiReason:
                'Desarrolla resistencia específica sin perder capacidad de cambio de ritmo.',
            stimulus: needsFinish
                ? TrainingStimulus.speed
                : TrainingStimulus.aerobic,
            energySystem: TrainingEnergySystem.aerobic,
            neuromuscularLoad: needsFinish
                ? NeuromuscularLoad.moderate
                : NeuromuscularLoad.low,
          ),
        ),
      ),
      _PrioritizedBlock(
        priority: _BlockPriority.important,
        block: DailyTrainingBlock(
          type: TrainingBlockType.strength,
          moment: TrainingBlockMoment.afternoon,
          title: needsStrength
              ? 'Gimnasio: fuerza funcional prioritaria'
              : 'Gimnasio: fuerza funcional + estabilidad',
          description:
              'Unilateral, core, estabilidad de cadera, isométricos y fuerza resistente.',
          durationMinutes: _minutes(45, modifiers.volume * modifiers.strength),
          km: 0,
          targetLoad: _load(50, modifiers.intensity * modifiers.strength),
          targetHeartRateZone: 2,
          recoveryFocused: false,
          taperFocused: false,
          aiReason:
              'La fuerza es fundamental para sostener postura y remate final.',
          stimulus: TrainingStimulus.strengthEndurance,
          energySystem: TrainingEnergySystem.mixed,
          neuromuscularLoad: NeuromuscularLoad.moderate,
        ),
      ),
      _PrioritizedBlock(
        priority: _BlockPriority.important,
        block: DailyTrainingBlock(
          type: TrainingBlockType.skating,
          moment: TrainingBlockMoment.evening,
          title: 'Remate final controlado',
          description:
              '4-6 aceleraciones de 10-12 s con recuperación completa.',
          durationMinutes: 25,
          km: _km(4, modifiers.volume),
          targetLoad: _load(32, modifiers.intensity * modifiers.speed),
          targetHeartRateZone: 4,
          recoveryFocused: false,
          taperFocused: false,
          aiReason: 'El fondista necesita sprint final para puntos y ataques.',
          stimulus: TrainingStimulus.speed,
          energySystem: TrainingEnergySystem.anaerobicAlactic,
          neuromuscularLoad: NeuromuscularLoad.moderate,
        ),
      ),
      if (_shouldInclude(modifiers.recovery, threshold: 1.0))
        _PrioritizedBlock(
          priority: _BlockPriority.optional,
          block: DailyTrainingBlock(
            type: TrainingBlockType.cycling,
            moment: TrainingBlockMoment.evening,
            title: 'Bicicleta regenerativa',
            description: 'Rodaje muy suave Z1 para facilitar recuperación.',
            durationMinutes: _minutes(20, modifiers.recovery),
            km: 0,
            targetLoad: 12,
            targetHeartRateZone: 1,
            recoveryFocused: true,
            taperFocused: false,
            aiReason: 'Facilita recuperación sin impacto adicional.',
            stimulus: TrainingStimulus.recovery,
            energySystem: TrainingEnergySystem.aerobic,
            neuromuscularLoad: NeuromuscularLoad.low,
          ),
        ),
    ];

    return IntegratedTrainingDay(
      date: date,
      expectedReadiness: readiness,
      expectedFatigue: fatigue,
      taperMode: false,
      recoveryDay: false,
      aiSummary: highReadiness
          ? '${_weekPrefix(week)}Día fondista completo: base, fuerza funcional y velocidad final.'
          : '${_weekPrefix(week)}Día de resistencia controlada con fuerza y remate final moderado.',
      aiRecommendation:
          'El fondista no solo acumula volumen: debe poder acelerar y cerrar fuerte.',
      blocks: _resolvePriorities(
        blocks: plannedBlocks,
        readiness: readiness,
        injuryRisk: context.currentInjuryRisk,
        acwr: context.fatigueTrend,
      ),
    );
  }

  static IntegratedTrainingDay _enduranceSpecificDay({
    required AthletePerformanceContext context,
    required DateTime date,
    required int readiness,
    required String fatigue,
    required bool highReadiness,
    required AthleteTrainingWeek? week,
    required _AdaptiveModifiers modifiers,
  }) {
    final profile = context.physiologyProfile;
    final needsSprintFinish = profile.sprintFinishCapability < 75;

    return IntegratedTrainingDay(
      date: date,
      expectedReadiness: readiness,
      expectedFatigue: fatigue,
      taperMode: false,
      recoveryDay: false,
      aiSummary:
          '${_weekPrefix(week)}Preparación específica fondista: ritmo competitivo, tolerancia, fuerza y remate final.',
      aiRecommendation:
          'Trabajar ritmo específico sin perder capacidad de aceleración. El remate final es obligatorio en patinaje de velocidad.',
      blocks: [
        _libraryBlockOrFallback(
          context: context,
          category: TrainingLibraryCategory.lactate,
          needsNeural: false,
          needsMetabolic: true,
          taperMode: false,
          moment: TrainingBlockMoment.morning,
          durationOverride: _minutes(
            highReadiness ? 80 : 60,
            modifiers.volume * modifiers.endurance,
          ),
          kmOverride: _km(highReadiness ? 20 : 14, modifiers.volume),
          loadOverride: _load(
            highReadiness ? 82 : 68,
            modifiers.intensity * modifiers.endurance,
          ),
          fallback: DailyTrainingBlock(
            type: TrainingBlockType.skating,
            moment: TrainingBlockMoment.morning,
            title: highReadiness
                ? 'Patines: ritmo competitivo + ataques'
                : 'Patines: tempo específico controlado',
            description:
                'Bloques de ritmo de carrera. Incluir cambios de ritmo tipo ataque: 4-6 repeticiones de 20-30 s. Recuperación incompleta controlada.',
            durationMinutes: _minutes(
              highReadiness ? 80 : 60,
              modifiers.volume * modifiers.endurance,
            ),
            km: _km(highReadiness ? 20 : 14, modifiers.volume),
            targetLoad: _load(
              highReadiness ? 82 : 68,
              modifiers.intensity * modifiers.endurance,
            ),
            targetHeartRateZone: highReadiness ? 4 : 3,
            recoveryFocused: false,
            taperFocused: false,
            aiReason:
                'Mejora ritmo competitivo y respuesta a ataques sin perder economía.',
            stimulus: TrainingStimulus.lactateTolerance,
            energySystem: TrainingEnergySystem.anaerobicLactic,
            neuromuscularLoad: NeuromuscularLoad.moderate,
          ),
        ),
        DailyTrainingBlock(
          type: TrainingBlockType.strength,
          moment: TrainingBlockMoment.afternoon,
          title: 'Trabajo físico: fuerza resistente + potencia baja',
          description:
              'Circuito funcional: step-ups, sentadilla unilateral, puente de glúteo, core antirotación, estabilidad de tobillo. Finalizar con saltos laterales bajos 3x5 si hay frescura.',
          durationMinutes: _minutes(40, modifiers.volume * modifiers.strength),
          km: 0,
          targetLoad: _load(45, modifiers.intensity * modifiers.strength),
          targetHeartRateZone: 2,
          recoveryFocused: false,
          taperFocused: false,
          aiReason:
              'La fuerza resistente sostiene postura y potencia en finales de carrera.',
          stimulus: TrainingStimulus.strengthEndurance,
          energySystem: TrainingEnergySystem.mixed,
          neuromuscularLoad: NeuromuscularLoad.moderate,
        ),
        DailyTrainingBlock(
          type: TrainingBlockType.skating,
          moment: TrainingBlockMoment.evening,
          title: needsSprintFinish
              ? 'Remate final prioritario'
              : 'Remate final mantenimiento',
          description:
              '3-5 aceleraciones finales de 12-15 s con recuperación completa. Debe sentirse rápido, no agotador.',
          durationMinutes: 22,
          km: _km(3.5, modifiers.volume),
          targetLoad: _load(35, modifiers.intensity * modifiers.speed),
          targetHeartRateZone: 4,
          recoveryFocused: false,
          taperFocused: false,
          aiReason:
              'El atleta de resistencia necesita ganar puntos, responder ataques y cerrar últimas vueltas.',
          stimulus: TrainingStimulus.speed,
          energySystem: TrainingEnergySystem.anaerobicAlactic,
          neuromuscularLoad: NeuromuscularLoad.moderate,
        ),
      ],
    );
  }

  static IntegratedTrainingDay _mixedDay({
    required AthletePerformanceContext context,
    required DateTime date,
    required int readiness,
    required String fatigue,
    required bool highReadiness,
    required AthleteTrainingWeek? week,
    required _AdaptiveModifiers modifiers,
  }) {
    final plannedBlocks = <_PrioritizedBlock>[
      _PrioritizedBlock(
        priority: _BlockPriority.important,
        block: DailyTrainingBlock(
          type: TrainingBlockType.technical,
          moment: TrainingBlockMoment.morning,
          title: 'Patines: técnica específica',
          description: 'Curvas, postura baja, empuje lateral y eficiencia.',
          durationMinutes: _minutes(45, modifiers.volume),
          km: _km(8, modifiers.volume),
          targetLoad: _load(45, modifiers.intensity),
          targetHeartRateZone: 2,
          recoveryFocused: false,
          taperFocused: false,
          aiReason:
              'El perfil mixto necesita eficiencia técnica antes de intensidad.',
          stimulus: TrainingStimulus.technical,
          energySystem: TrainingEnergySystem.aerobic,
          neuromuscularLoad: NeuromuscularLoad.low,
        ),
      ),
      _PrioritizedBlock(
        priority: _BlockPriority.critical,
        block: _libraryBlockOrFallback(
          context: context,
          category: TrainingLibraryCategory.speed,
          needsNeural: true,
          needsMetabolic: highReadiness,
          taperMode: false,
          moment: TrainingBlockMoment.afternoon,
          durationOverride: _minutes(highReadiness ? 70 : 55, modifiers.volume),
          kmOverride: _km(highReadiness ? 16 : 12, modifiers.volume),
          loadOverride: _load(
            highReadiness ? 78 : 65,
            modifiers.intensity * modifiers.speed,
          ),
          fallback: DailyTrainingBlock(
            type: TrainingBlockType.skating,
            moment: TrainingBlockMoment.afternoon,
            title: highReadiness
                ? 'Patines: intervalos + cambios de ritmo'
                : 'Patines: intervalos controlados',
            description: 'Series moderadas con recuperación suficiente.',
            durationMinutes: _minutes(
              highReadiness ? 70 : 55,
              modifiers.volume,
            ),
            km: _km(highReadiness ? 16 : 12, modifiers.volume),
            targetLoad: _load(
              highReadiness ? 78 : 65,
              modifiers.intensity * modifiers.speed,
            ),
            targetHeartRateZone: highReadiness ? 4 : 3,
            recoveryFocused: false,
            taperFocused: false,
            aiReason: 'Desarrolla potencia específica y tolerancia.',
            stimulus: TrainingStimulus.anaerobic,
            energySystem: TrainingEnergySystem.mixed,
            neuromuscularLoad: NeuromuscularLoad.moderate,
          ),
        ),
      ),
      _PrioritizedBlock(
        priority: _BlockPriority.important,
        block: DailyTrainingBlock(
          type: TrainingBlockType.strength,
          moment: TrainingBlockMoment.evening,
          title: 'Trabajo físico complementario',
          description: 'Core, estabilidad, unilateral y movilidad final.',
          durationMinutes: _minutes(35, modifiers.volume * modifiers.strength),
          km: 0,
          targetLoad: _load(35, modifiers.intensity * modifiers.strength),
          targetHeartRateZone: 2,
          recoveryFocused: false,
          taperFocused: false,
          aiReason: 'La fuerza complementaria protege técnica y aceleración.',
          stimulus: TrainingStimulus.strengthEndurance,
          energySystem: TrainingEnergySystem.mixed,
          neuromuscularLoad: NeuromuscularLoad.moderate,
        ),
      ),
      if (_shouldInclude(modifiers.core, threshold: 1.0))
        _PrioritizedBlock(
          priority: _BlockPriority.optional,
          block: DailyTrainingBlock(
            type: TrainingBlockType.mobility,
            moment: TrainingBlockMoment.evening,
            title: 'Core + movilidad preventiva',
            description: 'Core antirotación, movilidad y estabilidad.',
            durationMinutes: 20,
            km: 0,
            targetLoad: 15,
            targetHeartRateZone: 1,
            recoveryFocused: true,
            taperFocused: false,
            aiReason: 'Mejora estabilidad y control técnico.',
            stimulus: TrainingStimulus.mobility,
            energySystem: TrainingEnergySystem.none,
            neuromuscularLoad: NeuromuscularLoad.low,
          ),
        ),
    ];

    return IntegratedTrainingDay(
      date: date,
      expectedReadiness: readiness,
      expectedFatigue: fatigue,
      taperMode: false,
      recoveryDay: false,
      aiSummary: highReadiness
          ? '${_weekPrefix(week)}Día mixto de calidad.'
          : '${_weekPrefix(week)}Día mixto equilibrado.',
      aiRecommendation: 'Equilibrar intensidad, técnica y recuperación.',
      blocks: _resolvePriorities(
        blocks: plannedBlocks,
        readiness: readiness,
        injuryRisk: context.currentInjuryRisk,
        acwr: context.fatigueTrend,
      ),
    );
  }

  static IntegratedTrainingDay _controlledTechnicalDay({
    required DateTime date,
    required int readiness,
    required String fatigue,
    required String reason,
    required AthleteTrainingWeek? week,
  }) {
    return IntegratedTrainingDay(
      date: date,
      expectedReadiness: readiness,
      expectedFatigue: fatigue,
      taperMode: false,
      recoveryDay: false,
      aiSummary: '${_weekPrefix(week)}Día técnico controlado. $reason',
      aiRecommendation:
          'No hacer intensidad máxima. No hacer fuerza pesada ni pliometría fuerte. Mantener técnica, zona baja-media y recuperación.',
      blocks: const [
        DailyTrainingBlock(
          type: TrainingBlockType.mobility,
          moment: TrainingBlockMoment.morning,
          title: 'Trabajo físico suave: movilidad + activación',
          description:
              'Movilidad de cadera, tobillo y espalda. Activación de glúteo, core suave y estabilidad. Sin saltos fuertes.',
          durationMinutes: 25,
          km: 0,
          targetLoad: 15,
          targetHeartRateZone: 1,
          recoveryFocused: true,
          taperFocused: false,
          aiReason:
              'Se prepara el cuerpo sin aumentar carga fisiológica importante.',
          stimulus: TrainingStimulus.mobility,
          energySystem: TrainingEnergySystem.none,
          neuromuscularLoad: NeuromuscularLoad.low,
        ),
        DailyTrainingBlock(
          type: TrainingBlockType.technical,
          moment: TrainingBlockMoment.afternoon,
          title: 'Patines: técnica sin intensidad',
          description:
              'Postura, empuje lateral, curvas y eficiencia. Rodaje suave. Sin sprints máximos ni series duras.',
          durationMinutes: 45,
          km: 7,
          targetLoad: 35,
          targetHeartRateZone: 2,
          recoveryFocused: false,
          taperFocused: false,
          aiReason:
              'Se mantiene estímulo técnico reduciendo estrés fisiológico.',
          stimulus: TrainingStimulus.technical,
          energySystem: TrainingEnergySystem.aerobic,
          neuromuscularLoad: NeuromuscularLoad.low,
        ),
        DailyTrainingBlock(
          type: TrainingBlockType.cycling,
          moment: TrainingBlockMoment.evening,
          title: 'Bicicleta o descarga suave',
          description:
              'Bici Z1, respiración, movilidad suave y rutina para mejorar descanso.',
          durationMinutes: 20,
          km: 0,
          targetLoad: 10,
          targetHeartRateZone: 1,
          recoveryFocused: true,
          taperFocused: false,
          aiReason:
              'El objetivo es mejorar recuperación para permitir mejor adaptación mañana.',
          stimulus: TrainingStimulus.recovery,
          energySystem: TrainingEnergySystem.aerobic,
          neuromuscularLoad: NeuromuscularLoad.low,
        ),
      ],
    );
  }

  static IntegratedTrainingDay _deloadDay({
    required DateTime date,
    required int readiness,
    required String fatigue,
    required double acwr,
    required String reason,
    required AthleteTrainingWeek? week,
  }) {
    return IntegratedTrainingDay(
      date: date,
      expectedReadiness: readiness,
      expectedFatigue: fatigue,
      taperMode: true,
      recoveryDay: false,
      aiSummary:
          '${_weekPrefix(week)}Descarga automática. $reason ACWR: ${acwr.toStringAsFixed(2)}.',
      aiRecommendation:
          'Reducir volumen. Mantener sensación de movimiento, técnica y recuperación. No meter gimnasio pesado.',
      blocks: const [
        DailyTrainingBlock(
          type: TrainingBlockType.cycling,
          moment: TrainingBlockMoment.morning,
          title: 'Bicicleta regenerativa',
          description:
              'Rodaje muy suave Z1 para circulación. Sin acumular fatiga. Cadencia cómoda.',
          durationMinutes: 30,
          km: 0,
          targetLoad: 20,
          targetHeartRateZone: 1,
          recoveryFocused: true,
          taperFocused: true,
          aiReason:
              'La descarga reduce carga mecánica manteniendo recuperación activa.',
          stimulus: TrainingStimulus.recovery,
          energySystem: TrainingEnergySystem.aerobic,
          neuromuscularLoad: NeuromuscularLoad.low,
        ),
        DailyTrainingBlock(
          type: TrainingBlockType.technical,
          moment: TrainingBlockMoment.afternoon,
          title: 'Patines: técnica ligera',
          description:
              'Patinaje suave, postura, curvas y coordinación sin intensidad. Mantener sensación de pista.',
          durationMinutes: 35,
          km: 5,
          targetLoad: 25,
          targetHeartRateZone: 2,
          recoveryFocused: false,
          taperFocused: true,
          aiReason:
              'Se conserva patrón técnico sin agregar carga significativa.',
          stimulus: TrainingStimulus.technical,
          energySystem: TrainingEnergySystem.aerobic,
          neuromuscularLoad: NeuromuscularLoad.low,
        ),
        DailyTrainingBlock(
          type: TrainingBlockType.mobility,
          moment: TrainingBlockMoment.evening,
          title: 'Movilidad + recuperación',
          description:
              'Cadera, espalda, tobillo, respiración y relajación antes de dormir.',
          durationMinutes: 20,
          km: 0,
          targetLoad: 10,
          targetHeartRateZone: 1,
          recoveryFocused: true,
          taperFocused: true,
          aiReason:
              'Se prioriza bajar fatiga acumulada y mejorar recuperación.',
          stimulus: TrainingStimulus.mobility,
          energySystem: TrainingEnergySystem.none,
          neuromuscularLoad: NeuromuscularLoad.low,
        ),
      ],
    );
  }

  static IntegratedTrainingDay _preCompetitionDay({
    required AthletePerformanceContext context,
    required DateTime date,
    required int readiness,
    required String fatigue,
    required int daysToCompetition,
    required AthleteTrainingWeek? week,
  }) {
    return IntegratedTrainingDay(
      date: date,
      expectedReadiness: readiness,
      expectedFatigue: fatigue,
      taperMode: true,
      recoveryDay: false,
      aiSummary:
          '${_weekPrefix(week)}Acercamiento competitivo. Faltan $daysToCompetition días. Se reduce volumen y se conserva velocidad.',
      aiRecommendation:
          'No agregar carga nueva. Mantener frescura, confianza técnica, aceleración y sueño.',
      blocks: [
        const DailyTrainingBlock(
          type: TrainingBlockType.activation,
          moment: TrainingBlockMoment.morning,
          title: 'Activación + pliometría mínima',
          description:
              'Movilidad, coordinación, saltos suaves de baja dosis y progresivos cortos. Pocos contactos, mucha calidad.',
          durationMinutes: 25,
          km: 1.5,
          targetLoad: 25,
          targetHeartRateZone: 2,
          recoveryFocused: false,
          taperFocused: true,
          aiReason:
              'En acercamiento competitivo se mantiene chispa sin generar fatiga nueva.',
          stimulus: TrainingStimulus.neuromuscular,
          energySystem: TrainingEnergySystem.anaerobicAlactic,
          neuromuscularLoad: NeuromuscularLoad.moderate,
        ),
        _libraryBlockOrFallback(
          context: context,
          category: TrainingLibraryCategory.acceleration,
          needsNeural: true,
          needsMetabolic: false,
          taperMode: true,
          moment: TrainingBlockMoment.afternoon,
          durationOverride: 35,
          kmOverride: 5,
          loadOverride: 35,
          fallback: const DailyTrainingBlock(
            type: TrainingBlockType.skating,
            moment: TrainingBlockMoment.afternoon,
            title: 'Patines: velocidad corta con recuperación completa',
            description:
                'Pocas repeticiones rápidas, técnica limpia y descansos largos. Terminar con sensación de frescura.',
            durationMinutes: 35,
            km: 5,
            targetLoad: 35,
            targetHeartRateZone: 4,
            recoveryFocused: false,
            taperFocused: true,
            aiReason:
                'Se mantiene velocidad específica reduciendo volumen total.',
            stimulus: TrainingStimulus.speed,
            energySystem: TrainingEnergySystem.anaerobicAlactic,
            neuromuscularLoad: NeuromuscularLoad.moderate,
          ),
        ),
        const DailyTrainingBlock(
          type: TrainingBlockType.recovery,
          moment: TrainingBlockMoment.evening,
          title: 'Recuperación y sueño',
          description:
              'Movilidad suave, respiración, hidratación y preparación para dormir.',
          durationMinutes: 20,
          km: 0,
          targetLoad: 10,
          targetHeartRateZone: 1,
          recoveryFocused: true,
          taperFocused: true,
          aiReason: 'El objetivo principal es llegar fresco a la competencia.',
          stimulus: TrainingStimulus.recovery,
          energySystem: TrainingEnergySystem.none,
          neuromuscularLoad: NeuromuscularLoad.low,
        ),
      ],
    );
  }

  static IntegratedTrainingDay _taperDay({
    required AthletePerformanceContext context,
    required DateTime date,
    required int readiness,
    required String fatigue,
    required int daysToCompetition,
    required AthleteTrainingWeek? week,
  }) {
    return IntegratedTrainingDay(
      date: date,
      expectedReadiness: readiness,
      expectedFatigue: fatigue,
      taperMode: true,
      recoveryDay: false,
      aiSummary:
          '${_weekPrefix(week)}Día de taper. Faltan $daysToCompetition días para competir. Se reduce volumen y se mantiene velocidad.',
      aiRecommendation:
          'No agregar carga nueva. Mantener frescura, técnica, activación, aceleración y confianza.',
      blocks: [
        const DailyTrainingBlock(
          type: TrainingBlockType.activation,
          moment: TrainingBlockMoment.morning,
          title: 'Activación neuromuscular',
          description:
              'Movilidad, coordinación, técnica en seco y progresivos cortos. Sin fatigar.',
          durationMinutes: 25,
          km: 2,
          targetLoad: 25,
          targetHeartRateZone: 2,
          recoveryFocused: false,
          taperFocused: true,
          aiReason:
              'Durante taper se busca mantener chispa sin generar fatiga.',
          stimulus: TrainingStimulus.neuromuscular,
          energySystem: TrainingEnergySystem.anaerobicAlactic,
          neuromuscularLoad: NeuromuscularLoad.low,
        ),
        _libraryBlockOrFallback(
          context: context,
          category: TrainingLibraryCategory.acceleration,
          needsNeural: true,
          needsMetabolic: false,
          taperMode: true,
          moment: TrainingBlockMoment.afternoon,
          durationOverride: 35,
          kmOverride: 5,
          loadOverride: 35,
          fallback: const DailyTrainingBlock(
            type: TrainingBlockType.skating,
            moment: TrainingBlockMoment.afternoon,
            title: 'Patines: velocidad baja en volumen',
            description:
                'Pocas repeticiones rápidas con recuperación completa. Técnica y confianza.',
            durationMinutes: 35,
            km: 5,
            targetLoad: 35,
            targetHeartRateZone: 4,
            recoveryFocused: false,
            taperFocused: true,
            aiReason:
                'Se mantiene velocidad específica reduciendo volumen total.',
            stimulus: TrainingStimulus.speed,
            energySystem: TrainingEnergySystem.anaerobicAlactic,
            neuromuscularLoad: NeuromuscularLoad.moderate,
          ),
        ),
        const DailyTrainingBlock(
          type: TrainingBlockType.recovery,
          moment: TrainingBlockMoment.evening,
          title: 'Recuperación y sueño',
          description:
              'Movilidad suave, respiración, hidratación y preparación para dormir.',
          durationMinutes: 20,
          km: 0,
          targetLoad: 10,
          targetHeartRateZone: 1,
          recoveryFocused: true,
          taperFocused: true,
          aiReason: 'El objetivo principal es llegar fresco a la competencia.',
          stimulus: TrainingStimulus.recovery,
          energySystem: TrainingEnergySystem.none,
          neuromuscularLoad: NeuromuscularLoad.low,
        ),
      ],
    );
  }

  static IntegratedTrainingDay _recoveryDay({
    required DateTime date,
    required int readiness,
    required String fatigue,
    required String reason,
    required AthleteTrainingWeek? week,
  }) {
    return IntegratedTrainingDay(
      date: date,
      expectedReadiness: readiness,
      expectedFatigue: fatigue,
      taperMode: false,
      recoveryDay: true,
      aiSummary: '${_weekPrefix(week)}Día regenerativo. $reason',
      aiRecommendation:
          'No recuperar carga perdida. Priorizar sueño, movilidad, hidratación y baja intensidad.',
      blocks: const [
        DailyTrainingBlock(
          type: TrainingBlockType.cycling,
          moment: TrainingBlockMoment.morning,
          title: 'Bicicleta o caminata suave',
          description:
              'Actividad muy ligera Z1 para facilitar recuperación. Sin impacto, sin intensidad.',
          durationMinutes: 25,
          km: 0,
          targetLoad: 15,
          targetHeartRateZone: 1,
          recoveryFocused: true,
          taperFocused: false,
          aiReason: 'Se evita impacto y se favorece recuperación circulatoria.',
          stimulus: TrainingStimulus.recovery,
          energySystem: TrainingEnergySystem.aerobic,
          neuromuscularLoad: NeuromuscularLoad.low,
        ),
        DailyTrainingBlock(
          type: TrainingBlockType.technical,
          moment: TrainingBlockMoment.afternoon,
          title: 'Patines: técnica muy suave',
          description:
              'Rodaje técnico muy suave, postura, equilibrio y coordinación. Sin intensidad.',
          durationMinutes: 30,
          km: 4,
          targetLoad: 20,
          targetHeartRateZone: 1,
          recoveryFocused: true,
          taperFocused: false,
          aiReason:
              'Se mantienen patrones técnicos sin añadir carga significativa.',
          stimulus: TrainingStimulus.technical,
          energySystem: TrainingEnergySystem.aerobic,
          neuromuscularLoad: NeuromuscularLoad.low,
        ),
        DailyTrainingBlock(
          type: TrainingBlockType.mobility,
          moment: TrainingBlockMoment.evening,
          title: 'Movilidad y respiración',
          description:
              'Movilidad de cadera, espalda, tobillo y respiración diafragmática.',
          durationMinutes: 20,
          km: 0,
          targetLoad: 10,
          targetHeartRateZone: 1,
          recoveryFocused: true,
          taperFocused: false,
          aiReason: 'Se prioriza regulación autonómica y recuperación general.',
          stimulus: TrainingStimulus.mobility,
          energySystem: TrainingEnergySystem.none,
          neuromuscularLoad: NeuromuscularLoad.low,
        ),
      ],
    );
  }

  static DailyTrainingBlock _libraryBlockOrFallback({
    required AthletePerformanceContext context,
    required TrainingLibraryCategory category,
    required bool needsNeural,
    required bool needsMetabolic,
    required bool taperMode,
    required TrainingBlockMoment moment,
    required DailyTrainingBlock fallback,
    int? durationOverride,
    double? kmOverride,
    int? loadOverride,
  }) {
    final selected = SessionSelectionEngine.selectSession(
      context: context,
      category: category,
      needsNeural: needsNeural,
      needsMetabolic: needsMetabolic,
      taperMode: taperMode,
    );

    if (selected == null) {
      return fallback;
    }

    return _blockFromTemplate(
      template: selected.session,
      moment: moment,
      fallback: fallback,
      selectionScore: selected.score,
      selectionReasons: selected.reasons,
      durationOverride: durationOverride,
      kmOverride: kmOverride,
      loadOverride: loadOverride,
    );
  }

  static DailyTrainingBlock _blockFromTemplate({
    required TrainingSessionTemplate template,
    required TrainingBlockMoment moment,
    required DailyTrainingBlock fallback,
    required double selectionScore,
    required List<String> selectionReasons,
    int? durationOverride,
    double? kmOverride,
    int? loadOverride,
  }) {
    return DailyTrainingBlock(
      type: _blockTypeFromTemplate(template, fallback.type),
      moment: moment,
      title: template.title,
      description: _templateDescription(template),
      durationMinutes:
          durationOverride ?? _durationFromIntensity(template.intensity),
      km: kmOverride ?? _kmFromTemplate(template),
      targetLoad: loadOverride ?? _loadFromTemplate(template),
      targetHeartRateZone: _zoneFromTemplate(template),
      recoveryFocused: template.recoverySession,
      taperFocused: template.taperCompatible,
      aiReason: _selectionReasonText(
        template: template,
        score: selectionScore,
        reasons: selectionReasons,
      ),
      stimulus: _stimulusFromTemplate(template, fallback.stimulus),
      energySystem: _energySystemFromTemplate(template, fallback.energySystem),
      neuromuscularLoad: _neuromuscularLoadFromTemplate(
        template,
        fallback.neuromuscularLoad,
      ),
      warmup: template.warmup,
      mainSet: template.mainSet,
      exercises: template.complementary,
      technicalCues: template.technicalCues,
      coachingNotes: [template.coachNotes],
      stopCriteria: template.cutCriteria,
    );
  }

  static String _templateDescription(TrainingSessionTemplate template) {
    final buffer = StringBuffer();

    buffer.write(template.objective);

    if (template.type.trim().isNotEmpty) {
      buffer.write(' Tipo: ${template.type}');
    }

    if (template.mainSet.isNotEmpty) {
      buffer.write(' Parte principal: ${template.mainSet.join(' ')}');
    }

    return buffer.toString();
  }

  static String _selectionReasonText({
    required TrainingSessionTemplate template,
    required double score,
    required List<String> reasons,
  }) {
    final base =
        'Sesión real seleccionada desde la biblioteca del entrenador. ID: ${template.id}. Score: ${score.toStringAsFixed(1)}.';

    if (reasons.isEmpty) {
      return '$base Compatible con el objetivo del día.';
    }

    return '$base Razones: ${reasons.join(' ')}';
  }

  static TrainingBlockType _blockTypeFromTemplate(
    TrainingSessionTemplate template,
    TrainingBlockType fallback,
  ) {
    if (template.gymSession) return TrainingBlockType.strength;
    if (template.cyclingSession) return TrainingBlockType.cycling;
    if (template.recoverySession) return TrainingBlockType.recovery;

    if (template.category == TrainingLibraryCategory.technical) {
      return TrainingBlockType.technical;
    }

    if (template.category == TrainingLibraryCategory.mobility ||
        template.category == TrainingLibraryCategory.prehab ||
        template.category == TrainingLibraryCategory.core) {
      return TrainingBlockType.mobility;
    }

    if (template.category == TrainingLibraryCategory.plyometric) {
      return TrainingBlockType.activation;
    }

    if (template.skatingSession) return TrainingBlockType.skating;

    return fallback;
  }

  static TrainingStimulus _stimulusFromTemplate(
    TrainingSessionTemplate template,
    TrainingStimulus fallback,
  ) {
    if (template.recoverySession) return TrainingStimulus.recovery;
    if (template.technicalFocused) return TrainingStimulus.technical;
    if (template.reactiveFocused) return TrainingStimulus.plyometric;
    if (template.metabolicFocused) return TrainingStimulus.lactateTolerance;
    if (template.neuralFocused) return TrainingStimulus.speed;

    if (template.category == TrainingLibraryCategory.strength) {
      return TrainingStimulus.maxStrength;
    }

    if (template.category == TrainingLibraryCategory.power) {
      return TrainingStimulus.power;
    }

    if (template.category == TrainingLibraryCategory.endurance ||
        template.category == TrainingLibraryCategory.tempo) {
      return TrainingStimulus.aerobic;
    }

    return fallback;
  }

  static TrainingEnergySystem _energySystemFromTemplate(
    TrainingSessionTemplate template,
    TrainingEnergySystem fallback,
  ) {
    if (template.recoverySession) return TrainingEnergySystem.aerobic;
    if (template.metabolicFocused) return TrainingEnergySystem.anaerobicLactic;
    if (template.neuralFocused) return TrainingEnergySystem.anaerobicAlactic;
    if (template.category == TrainingLibraryCategory.endurance ||
        template.category == TrainingLibraryCategory.tempo ||
        template.category == TrainingLibraryCategory.cycling) {
      return TrainingEnergySystem.aerobic;
    }

    if (template.category == TrainingLibraryCategory.strength ||
        template.category == TrainingLibraryCategory.power ||
        template.category == TrainingLibraryCategory.core) {
      return TrainingEnergySystem.none;
    }

    return fallback;
  }

  static NeuromuscularLoad _neuromuscularLoadFromTemplate(
    TrainingSessionTemplate template,
    NeuromuscularLoad fallback,
  ) {
    if (template.recoverySession) return NeuromuscularLoad.low;

    if (template.intensity == TrainingSessionIntensity.maximal) {
      return NeuromuscularLoad.maximal;
    }

    if (template.neuralFocused || template.reactiveFocused) {
      return template.intensity == TrainingSessionIntensity.high
          ? NeuromuscularLoad.high
          : NeuromuscularLoad.moderate;
    }

    if (template.metabolicFocused) return NeuromuscularLoad.moderate;

    return fallback;
  }

  static int _durationFromIntensity(TrainingSessionIntensity intensity) {
    switch (intensity) {
      case TrainingSessionIntensity.recovery:
        return 30;
      case TrainingSessionIntensity.low:
        return 40;
      case TrainingSessionIntensity.moderate:
        return 55;
      case TrainingSessionIntensity.high:
        return 70;
      case TrainingSessionIntensity.maximal:
        return 60;
    }
  }

  static double _kmFromTemplate(TrainingSessionTemplate template) {
    if (!template.skatingSession) return 0;

    switch (template.intensity) {
      case TrainingSessionIntensity.recovery:
        return 4;
      case TrainingSessionIntensity.low:
        return 7;
      case TrainingSessionIntensity.moderate:
        return 12;
      case TrainingSessionIntensity.high:
        return 14;
      case TrainingSessionIntensity.maximal:
        return 10;
    }
  }

  static int _loadFromTemplate(TrainingSessionTemplate template) {
    switch (template.intensity) {
      case TrainingSessionIntensity.recovery:
        return 12;
      case TrainingSessionIntensity.low:
        return 28;
      case TrainingSessionIntensity.moderate:
        return 50;
      case TrainingSessionIntensity.high:
        return 75;
      case TrainingSessionIntensity.maximal:
        return 85;
    }
  }

  static int _zoneFromTemplate(TrainingSessionTemplate template) {
    if (template.recoverySession) return 1;
    if (template.metabolicFocused) return 4;
    if (template.neuralFocused) return 4;

    switch (template.intensity) {
      case TrainingSessionIntensity.recovery:
        return 1;
      case TrainingSessionIntensity.low:
        return 2;
      case TrainingSessionIntensity.moderate:
        return 3;
      case TrainingSessionIntensity.high:
        return 4;
      case TrainingSessionIntensity.maximal:
        return 5;
    }
  }

  static IntegratedTrainingDay _professionalizeDay(IntegratedTrainingDay day) {
    return day.copyWith(blocks: day.blocks.map(_professionalizeBlock).toList());
  }

  static DailyTrainingBlock _professionalizeBlock(DailyTrainingBlock block) {
    if (block.hasProfessionalDetails) return block;

    switch (block.type) {
      case TrainingBlockType.strength:
        return _professionalStrengthBlock(block);
      case TrainingBlockType.skating:
      case TrainingBlockType.technical:
        return _professionalSkatingBlock(block);
      case TrainingBlockType.activation:
        return _professionalActivationBlock(block);
      case TrainingBlockType.mobility:
        return _professionalMobilityBlock(block);
      case TrainingBlockType.recovery:
      case TrainingBlockType.cycling:
      case TrainingBlockType.aerobic:
        return _professionalRecoveryBlock(block);
    }
  }

  static DailyTrainingBlock _professionalStrengthBlock(
    DailyTrainingBlock block,
  ) {
    final isPower = block.stimulus == TrainingStimulus.power;
    final isMaxStrength = block.stimulus == TrainingStimulus.maxStrength;
    final isStrengthEndurance =
        block.stimulus == TrainingStimulus.strengthEndurance;

    return block.copyWith(
      warmup: const [
        '8-10 min movilidad dinámica: cadera, tobillo, espalda torácica.',
        'Activación glúteo medio: miniband walk 2x12 por lado.',
        'Core previo: dead bug 2x8 por lado + plancha lateral 2x25 s.',
        '2-3 series progresivas del primer ejercicio antes de la carga real.',
      ],
      strengthExercises: isPower
          ? const [
              'Trap bar jump o sentadilla con salto: 4x3, descanso 2-3 min.',
              'Sentadilla frontal o prensa: 4x4-5, RPE 7-8.',
              'Peso muerto rumano: 3x5-6, control excéntrico.',
              'Step-up alto: 3x5 por pierna.',
              'Core antirotación Pallof press: 3x10 por lado.',
            ]
          : isMaxStrength
          ? const [
              'Sentadilla o prensa principal: 4x4-6, RPE 7-8.',
              'Peso muerto rumano: 3x6-8.',
              'Zancada o split squat: 3x6-8 por pierna.',
              'Hip thrust o puente de glúteo: 3x8.',
              'Core antirotación: 3x30 s por lado.',
            ]
          : isStrengthEndurance
          ? const [
              'Step-up o zancada caminando: 3x10 por pierna.',
              'Sentadilla goblet o prensa moderada: 3x10-12.',
              'Peso muerto rumano ligero: 3x10.',
              'Isométrico posición baja de patinaje: 4x30 s.',
              'Core: plancha frontal 3x35 s + lateral 3x25 s.',
            ]
          : const [
              'Sentadilla técnica: 3x8.',
              'Bisagra de cadera: 3x8.',
              'Trabajo unilateral: 3x8 por pierna.',
              'Core y estabilidad: 3 bloques controlados.',
            ],
      plyometricExercises: isPower
          ? const [
              'Saltos laterales bajos: 3x5 por lado.',
              'Bounds laterales controlados: 3x4 por lado.',
              'Parar si la caída es ruidosa o la rodilla colapsa.',
            ]
          : const [],
      technicalCues: const [
        'Rodilla alineada con punta del pie.',
        'Empuje desde cadera, no solo desde rodilla.',
        'Mantener tronco estable como en posición de patinaje.',
        'No buscar fallo muscular: calidad antes que fatiga.',
      ],
      coachingNotes: const [
        'Transferencia directa a empuje lateral, curvas, salidas y remate final.',
        'El entrenador puede bajar una serie si la velocidad de ejecución cae.',
      ],
      stopCriteria: const [
        'Dolor articular.',
        'Pérdida clara de técnica.',
        'RPE mayor a 8 cuando el día no era máximo.',
        'Asimetría fuerte entre piernas.',
      ],
      cooldown: const [
        'Movilidad cadera 2 min por lado.',
        'Respiración nasal lenta 3 min.',
        'Estiramiento suave de glúteo, flexores e isquios.',
      ],
    );
  }

  static DailyTrainingBlock _professionalSkatingBlock(
    DailyTrainingBlock block,
  ) {
    final isSpeed =
        block.stimulus == TrainingStimulus.speed ||
        block.energySystem == TrainingEnergySystem.anaerobicAlactic;

    final isLactate =
        block.stimulus == TrainingStimulus.lactateTolerance ||
        block.energySystem == TrainingEnergySystem.anaerobicLactic;

    final isAerobic =
        block.stimulus == TrainingStimulus.aerobic ||
        block.energySystem == TrainingEnergySystem.aerobic;

    return block.copyWith(
      warmup: const [
        '10-15 min rodaje progresivo Z1-Z2.',
        'Movilidad dinámica sobre patines: cadera, tobillo, espalda.',
        '3-4 progresivos de 60-80 m sin llegar al máximo.',
        '2 vueltas técnicas enfocadas en postura baja y empuje lateral.',
      ],
      mainSet: isSpeed
          ? const [
              '6-8 salidas cortas de 8-12 s con recuperación completa.',
              '4-6 aceleraciones de 80-120 m, calidad máxima.',
              '3-5 vueltas lanzadas o tramos rápidos según pista.',
              'Descanso amplio: 2-4 min entre repeticiones.',
            ]
          : isLactate
          ? const [
              '3-5 bloques de ritmo competitivo de 2-4 min.',
              '4-6 cambios de ritmo tipo ataque de 20-30 s.',
              'Recuperación incompleta controlada: 2-3 min.',
              'Mantener técnica bajo fatiga, no perseguir solo pulsaciones.',
            ]
          : isAerobic
          ? const [
              'Rodaje principal Z2-Z3 con postura estable.',
              'Cada 8-10 min incluir 15-20 s de cambio de ritmo controlado.',
              'Mantener frecuencia eficiente y empuje lateral.',
              'Terminar con 4-6 progresivos cortos si hay frescura.',
            ]
          : const [
              'Bloque técnico: curvas, postura baja y empuje lateral.',
              '6 repeticiones técnicas de 2-3 min.',
              'Pausa suave entre bloques.',
              'Priorizar eficiencia antes que intensidad.',
            ],
      technicalCues: const [
        'Postura baja sin colapsar la espalda.',
        'Empuje lateral completo, no empujar hacia atrás.',
        'Mirada al frente y hombros relajados.',
        'En curva: presión progresiva y salida limpia.',
        'Mantener técnica cuando aparece fatiga.',
      ],
      tacticalCues: isSpeed
          ? const [
              'Simular salida y primera aceleración.',
              'Buscar explosividad sin tensión excesiva.',
              'Terminar cada repetición con control técnico.',
            ]
          : isLactate
          ? const [
              'Practicar respuesta a ataques.',
              'Controlar el ritmo después del cambio.',
              'Cerrar fuerte sin romper postura.',
            ]
          : const [
              'Aprender a cambiar ritmo sin gastar de más.',
              'Mantener economía para remate final.',
            ],
      coachingNotes: const [
        'El entrenador debe mirar técnica, no solo carga.',
        'Si la técnica cae, se corta el bloque aunque falten repeticiones.',
      ],
      stopCriteria: const [
        'Pérdida de postura baja.',
        'Empuje corto o desordenado.',
        'Dolor lumbar, rodilla o tobillo.',
        'Incapacidad de recuperar técnica tras la pausa.',
      ],
      cooldown: const [
        '8-12 min rodaje suave Z1.',
        'Respiración controlada.',
        'Movilidad final de cadera, glúteo, espalda y tobillo.',
      ],
    );
  }

  static DailyTrainingBlock _professionalActivationBlock(
    DailyTrainingBlock block,
  ) {
    return block.copyWith(
      warmup: const [
        '5 min movilidad dinámica general.',
        'Activación de pies y tobillos.',
        'Activación glúteo medio y core.',
      ],
      plyometricExercises: block.stimulus == TrainingStimulus.plyometric
          ? const [
              'Pogos suaves: 3x12.',
              'Saltos laterales bajos: 3x5 por lado.',
              'Bounds laterales técnicos: 3x4 por lado.',
              'Aceleraciones cortas: 4-6 x 10 s con descanso completo.',
            ]
          : const [
              'Skipping bajo: 3x20 m.',
              'Progresivos suaves: 4x60 m.',
              'Técnica en seco de posición baja: 3x25 s.',
            ],
      technicalCues: const [
        'Contactos rápidos y silenciosos.',
        'Rodilla alineada.',
        'Tronco estable.',
        'No convertir activación en fatiga.',
      ],
      coachingNotes: const [
        'Debe dejar sensación de frescura y velocidad.',
        'Pocos contactos, máxima calidad.',
      ],
      stopCriteria: const [
        'Caídas pesadas.',
        'Dolor en tendón o rodilla.',
        'Pérdida de coordinación.',
      ],
      cooldown: const ['Movilidad suave 5 min.', 'Respiración lenta 2 min.'],
    );
  }

  static DailyTrainingBlock _professionalMobilityBlock(
    DailyTrainingBlock block,
  ) {
    return block.copyWith(
      warmup: const [
        'Respiración nasal 2 min.',
        'Movilidad suave de columna y cadera.',
      ],
      exercises: const [
        'Flexores de cadera: 2x45 s por lado.',
        'Glúteo/piriforme: 2x45 s por lado.',
        'Tobillo contra pared: 2x10 por lado.',
        'Rotación torácica: 2x8 por lado.',
        'Core suave: dead bug 2x8 por lado.',
      ],
      technicalCues: const [
        'Movimiento lento y controlado.',
        'Sin dolor.',
        'Respirar profundo durante cada posición.',
      ],
      coachingNotes: const [
        'Objetivo: recuperar rango útil para posición baja y curvas.',
      ],
      stopCriteria: const ['Dolor punzante.', 'Mareo o malestar.'],
      cooldown: const ['Respiración diafragmática 3 min.'],
    );
  }

  static DailyTrainingBlock _professionalRecoveryBlock(
    DailyTrainingBlock block,
  ) {
    return block.copyWith(
      warmup: const ['Inicio muy suave 5 min.', 'Mantener conversación fácil.'],
      mainSet: const [
        'Trabajo continuo Z1-Z2 sin buscar rendimiento.',
        'Cadencia cómoda y respiración controlada.',
        'Evitar cualquier aceleración fuerte.',
      ],
      technicalCues: const [
        'Soltar piernas.',
        'No competir con el ritmo.',
        'Mantener sensación fácil.',
      ],
      coachingNotes: const [
        'El objetivo es recuperar, no compensar carga perdida.',
      ],
      stopCriteria: const [
        'Fatiga creciente.',
        'Dolor muscular fuerte.',
        'Pulso anormalmente alto para Z1.',
      ],
      cooldown: const [
        '5-8 min muy suave.',
        'Movilidad ligera.',
        'Hidratación y sueño.',
      ],
    );
  }

  static List<DailyTrainingBlock> _resolvePriorities({
    required List<_PrioritizedBlock> blocks,
    required int readiness,
    required double injuryRisk,
    required double acwr,
  }) {
    final resolved = <_PrioritizedBlock>[...blocks];

    if (readiness < 70) {
      resolved.removeWhere((b) => b.priority == _BlockPriority.optional);
    }

    if (injuryRisk > 60) {
      resolved.removeWhere(
        (b) =>
            b.block.neuromuscularLoad == NeuromuscularLoad.maximal &&
            b.priority != _BlockPriority.critical,
      );
    }

    if (acwr > 1.4) {
      resolved.removeWhere(
        (b) =>
            b.block.stimulus == TrainingStimulus.plyometric &&
            b.priority == _BlockPriority.optional,
      );
    }

    return resolved.map((e) => e.block).toList();
  }

  static bool _shouldInclude(double value, {double threshold = 0.08}) {
    return value >= threshold;
  }

  static int _minutes(int base, double modifier) {
    return (base * modifier).round().clamp(15, 180).toInt();
  }

  static int _load(int base, double modifier) {
    return (base * modifier).round().clamp(5, 100).toInt();
  }

  static double _km(double base, double modifier) {
    return (base * modifier).clamp(0, 40).toDouble();
  }

  static AthleteTrainingWeek? _findWeekForDate(
    AthleteProgramProfile athlete,
    DateTime date,
  ) {
    final cleanDate = DateTime(date.year, date.month, date.day);

    for (final week in athlete.seasonPlan) {
      final start = DateTime(
        week.startDate.year,
        week.startDate.month,
        week.startDate.day,
      );

      final end = DateTime(
        week.endDate.year,
        week.endDate.month,
        week.endDate.day,
      );

      if (!cleanDate.isBefore(start) && !cleanDate.isAfter(end)) {
        return week;
      }
    }

    return null;
  }

  static int _daysToNextCompetition(
    AthleteProgramProfile athlete,
    DateTime date,
  ) {
    final future =
        athlete.competitions
            .where((competition) => !competition.date.isBefore(date))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    if (future.isEmpty) {
      return 999;
    }

    return future.first.date.difference(date).inDays;
  }

  static _SeasonDayMode _seasonModeFromWeek(
    AthleteTrainingWeek? week,
    int daysToCompetition,
  ) {
    if (week == null) {
      if (daysToCompetition <= 3) return _SeasonDayMode.taper;
      if (daysToCompetition <= 7) return _SeasonDayMode.competition;
      if (daysToCompetition <= 28) return _SeasonDayMode.specificPreparation;
      return _SeasonDayMode.normal;
    }

    if (week.postCompetitionDeload) {
      return _SeasonDayMode.postCompetitionDeload;
    }

    if (week.taperWeek) {
      return _SeasonDayMode.taper;
    }

    final phase = week.phaseEs.toLowerCase();

    if (phase.contains('general')) {
      return _SeasonDayMode.generalPreparation;
    }

    if (phase.contains('espec')) {
      return _SeasonDayMode.specificPreparation;
    }

    if (phase.contains('precompetencia') || phase.contains('taper')) {
      return _SeasonDayMode.taper;
    }

    if (phase.contains('competencia')) {
      return _SeasonDayMode.competition;
    }

    if (phase.contains('transición') || phase.contains('descarga')) {
      return _SeasonDayMode.transition;
    }

    return _SeasonDayMode.normal;
  }

  static String _weekPrefix(AthleteTrainingWeek? week) {
    if (week == null) return '';

    return 'Semana ${week.weekNumber} · ${week.phaseEs}. ';
  }
}



