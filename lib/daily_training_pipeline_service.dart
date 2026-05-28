import 'athlete_context_service.dart';
import 'athlete_adaptation_layer.dart';
import 'adaptive_response_memory.dart';
import 'adaptive_response_memory_engine.dart';
import 'adaptive_response_memory_storage_service.dart';
import 'physiology/models/strength_load_state.dart';
import 'athlete_daily_state.dart';
import 'athlete_daily_state_engine.dart';
import 'athlete_performance_context.dart';
import 'athlete_physiology_profile.dart';
import 'athlete_program_service.dart';
import 'daily_athlete_log.dart';
import 'daily_log_storage_service.dart';
import 'daily_pipeline_cache_service.dart';
import 'daily_training_block.dart';
import 'integrated_day_generator_engine.dart';
import 'integrated_training_day.dart';
import 'physiology_learning_engine.dart';
import 'physiology_profile_storage_service.dart';
import 'training_adjustment_engine.dart';
import 'training_intervention_engine.dart';
import 'training_progression_engine.dart';
import 'training_progression_block_builder.dart';
import 'training_library/training_library_models.dart';
import 'wearable_daily_log_mapper.dart';
import 'physiology/strength_load_calculator.dart';
import 'training_library/gym/gym_exercise_parser.dart';

class DailyTrainingPipelineResult {
  final AthletePhysiologyProfile learnedProfile;
  final List<DailyAthleteLog> logs;
  final AthleteDailyState dailyState;
  final AthletePerformanceContext performanceContext;
  final IntegratedTrainingDay generatedDay;
  final TrainingInterventionResult intervention;
  final IntegratedTrainingDay adjustedDay;
  final AdaptiveResponseMemory adaptiveMemory;

  const DailyTrainingPipelineResult({
    required this.learnedProfile,
    required this.logs,
    required this.dailyState,
    required this.performanceContext,
    required this.generatedDay,
    required this.intervention,
    required this.adjustedDay,
    required this.adaptiveMemory,
  });
}

class DailyTrainingPipelineService {
  static Future<DailyTrainingPipelineResult> run({
    required AthleteProgramProfile athlete,
    required AthleteContextService athleteContext,
    required AthletePhysiologyProfile profile,
    required List<DailyAthleteLog> initialLogs,
    DateTime? date,
    bool useCache = true,
  }) async {
    final targetDate = date ?? DateTime.now();

    final hasWeeklyPlanForToday = _hasWeeklyIntelligentPlanForDate(
      athlete: athlete,
      date: targetDate,
    );

    if (useCache && !hasWeeklyPlanForToday) {
      final cachedSnapshot = await DailyPipelineCacheService.loadSnapshot(
        athleteId: athlete.id,
        date: targetDate,
      );

      if (cachedSnapshot != null) {
        final cachedState = cachedSnapshot.dailyState;
        final cachedMemory =
            await AdaptiveResponseMemoryStorageService.loadMemory(athlete.id);

        final cachedPerformanceContext = AthletePerformanceContext(
          athlete: athlete,
          physiologyProfile: profile,
          dailyLogs: initialLogs,
          latestWearableData: cachedState.wearable,
          currentReadiness: cachedState.readiness,
          currentFatigueStatus: cachedState.fatigueStatus,
          currentInjuryRisk: cachedState.injuryRisk,
          readinessTrend: cachedState.readiness.toDouble(),
          fatigueTrend: cachedState.acwr,
          adaptationTrend: profile.adaptationScore,
          seasonWeeks: athlete.seasonPlan,

          dynamicBaseline: athleteContext.activeDynamicBaseline,
          dataQuality: athleteContext.activeDataQuality,
          fatigueSystems: athleteContext.activeFatigueSystems,
          hybridReadiness: athleteContext.activeHybridReadiness,
        );

        return DailyTrainingPipelineResult(
          learnedProfile: profile,
          logs: initialLogs,
          dailyState: cachedState,
          performanceContext: cachedPerformanceContext,
          generatedDay: cachedSnapshot.trainingDay,
          intervention: cachedSnapshot.intervention,
          adjustedDay: cachedSnapshot.trainingDay,
          adaptiveMemory: cachedMemory,
        );
      }
    }

    final logs = List<DailyAthleteLog>.from(initialLogs);
    var learnedProfile = profile;

    var adaptiveMemory = await AdaptiveResponseMemoryStorageService.loadMemory(
      athlete.id,
    );

    if (athleteContext.activeWearable != null) {
      final wearableLog = WearableDailyLogMapper.fromWearable(
        athleteId: athlete.id,
        wearable: athleteContext.activeWearable!,
      );

      await DailyLogStorageService.saveLog(wearableLog);

      logs.removeWhere((item) {
        return item.date.year == wearableLog.date.year &&
            item.date.month == wearableLog.date.month &&
            item.date.day == wearableLog.date.day;
      });

      logs.add(wearableLog);
      logs.sort((a, b) => a.date.compareTo(b.date));

      learnedProfile = PhysiologyLearningEngine.processDailyMetrics(
        profile: learnedProfile,
        wearableData: athleteContext.activeWearable!,
        sessionType: wearableLog.performedSessionType,
        sessionLoad: wearableLog.performedLoad,
        soreness: athleteContext.activeWearable!.soreness,
        readiness: wearableLog.readiness,
        dataQuality: athleteContext.activeDataQuality,
      );

      await PhysiologyProfileStorageService.saveProfile(learnedProfile);

      adaptiveMemory = AdaptiveResponseMemoryEngine.update(
        memory: adaptiveMemory,
        wearableData: athleteContext.activeWearable!,
        previousLog: logs.length >= 2 ? logs[logs.length - 2] : null,
        readiness: wearableLog.readiness,
        soreness: athleteContext.activeWearable!.soreness,
        strengthLoadState: const StrengthLoadState(
          externalStrengthLoadKg: 0,
          reactiveJumpLoadKg: 0,
          totalMechanicalLoadKg: 0,
          neuralStress: 0,
          muscleStress: 0,
          tendonStress: 0,
          adaptationSignal: 'none',
        ),
      );

      await AdaptiveResponseMemoryStorageService.saveMemory(adaptiveMemory);
    }

    final dailyState = AthleteDailyStateEngine.build(
      athleteId: athlete.id,
      profile: learnedProfile,
      logs: logs,
      wearable: athleteContext.activeWearable,
    );

    final performanceContext = AthletePerformanceContext(
      athlete: athlete,
      physiologyProfile: dailyState.physiologyProfile,
      dailyLogs: logs,
      latestWearableData: dailyState.wearable,
      currentReadiness: dailyState.readiness,
      currentFatigueStatus: dailyState.fatigueStatus,
      currentInjuryRisk: dailyState.injuryRisk,
      readinessTrend: dailyState.readiness.toDouble(),
      fatigueTrend: dailyState.acwr,
      adaptationTrend: dailyState.physiologyProfile.adaptationScore,
      seasonWeeks: athlete.seasonPlan,

      dynamicBaseline: athleteContext.activeDynamicBaseline,
      dataQuality: athleteContext.activeDataQuality,
      fatigueSystems: athleteContext.activeFatigueSystems,
      hybridReadiness: athleteContext.activeHybridReadiness,
    );

    final baseGeneratedDay = _generateDayFromWeeklyPlanOrFallback(
      athlete: athlete,
      context: performanceContext,
      date: targetDate,
      dailyState: dailyState,
    );

    final adaptationProfile = AthleteAdaptationLayer.build(
      performanceContext,
      adaptiveMemory: adaptiveMemory,
    );

    final adaptiveGeneratedDay = _applyAdaptiveMemoryToGeneratedDay(
      day: baseGeneratedDay,
      adaptation: adaptationProfile,
      memory: adaptiveMemory,
      dailyState: dailyState,
    );

    final progressionDecision = TrainingProgressionEngine.decide(
      dailyState: dailyState,
      adaptation: adaptationProfile,
      memory: adaptiveMemory,
    );

    final generatedDay = _applyDailyProgression(
      day: adaptiveGeneratedDay,
      decision: progressionDecision,
      dailyState: dailyState,
    );

    final strengthLoadState = _calculateStrengthLoad(
      generatedDay,
      athlete.weightKg,
    );

    final intervention = TrainingInterventionEngine.analyze(
      context: performanceContext,
      day: generatedDay,
      strengthLoadState: strengthLoadState,
    );

    final adjustedDay = TrainingAdjustmentEngine.apply(
      day: generatedDay,
      intervention: intervention,
    );

    await DailyPipelineCacheService.saveSnapshot(
      athleteId: athlete.id,
      date: targetDate,
      trainingDay: adjustedDay,
      dailyState: dailyState,
      intervention: intervention,
    );

    return DailyTrainingPipelineResult(
      learnedProfile: learnedProfile,
      logs: logs,
      dailyState: dailyState,
      performanceContext: performanceContext,
      generatedDay: generatedDay,
      intervention: intervention,
      adjustedDay: adjustedDay,
      adaptiveMemory: adaptiveMemory,
    );
  }

  static IntegratedTrainingDay _applyAdaptiveMemoryToGeneratedDay({
    required IntegratedTrainingDay day,
    required AthleteAdaptationProfile adaptation,
    required AdaptiveResponseMemory memory,
    required AthleteDailyState dailyState,
  }) {
    if (day.recoveryDay) return day;

    final protectReactive =
        adaptation.needsReactiveProtection ||
        adaptation.reactiveTolerance < 0.90 ||
        memory.jumpTolerance < 0.92 ||
        memory.strugglesWithJumps;

    final protectLactate =
        adaptation.strugglesWithLactate ||
        adaptation.lactateTolerance < 0.90 ||
        memory.lactateTolerance < 0.92 ||
        memory.strugglesWithLactate;

    final protectNeural =
        adaptation.neuralTolerance < 0.90 ||
        memory.sprintTolerance < 0.92 ||
        memory.z5Tolerance < 0.92 ||
        memory.strugglesWithZ5;

    final protectGym =
        memory.gymTolerance < 0.92 ||
        dailyState.strengthLoadState.tendonStress >= 70 ||
        dailyState.strengthLoadState.muscleStress >= 80;

    final protectDensity =
        adaptation.densityTolerance < 0.92 ||
        memory.doubleSessionTolerance < 0.92 ||
        dailyState.shouldBlockIntensity ||
        dailyState.fatigueStatus == 'orange' ||
        dailyState.fatigueStatus == 'red';

    final needsLongerTaper =
        adaptation.needsLongerTaper ||
        adaptation.taperNeed >= 1.12 ||
        memory.taperResponse < 0.92 ||
        memory.needsLongerTaper;

    var blocks = day.blocks.map((block) {
      var adjusted = block;

      final isReactive =
          adjusted.stimulus == TrainingStimulus.plyometric ||
          adjusted.type == TrainingBlockType.activation ||
          adjusted.neuromuscularLoad == NeuromuscularLoad.high ||
          adjusted.neuromuscularLoad == NeuromuscularLoad.maximal;

      final isLactate =
          adjusted.stimulus == TrainingStimulus.lactateTolerance ||
          adjusted.stimulus == TrainingStimulus.anaerobic ||
          adjusted.energySystem == TrainingEnergySystem.anaerobicLactic;

      final isNeuralSpeed =
          adjusted.stimulus == TrainingStimulus.speed ||
          adjusted.stimulus == TrainingStimulus.neuromuscular ||
          adjusted.energySystem == TrainingEnergySystem.anaerobicAlactic;

      final isGym = adjusted.type == TrainingBlockType.strength;

      if (protectReactive && isReactive) {
        adjusted = adjusted.copyWith(
          title: '${adjusted.title} (reactividad protegida)',
          durationMinutes: (adjusted.durationMinutes * 0.65).round().clamp(
            10,
            60,
          ),
          km: adjusted.km * 0.60,
          targetLoad: (adjusted.targetLoad * 0.60).round().clamp(5, 55),
          targetHeartRateZone: adjusted.targetHeartRateZone.clamp(1, 3),
          neuromuscularLoad: NeuromuscularLoad.low,
          aiReason:
              '${adjusted.aiReason}\n\nMemoria adaptativa: se reduce pliometría/reactividad porque este atleta necesita protección tendinosa o neuromuscular.',
        );
      }

      if (protectLactate && isLactate) {
        adjusted = adjusted.copyWith(
          title: '${adjusted.title} (lactato controlado)',
          durationMinutes: (adjusted.durationMinutes * 0.70).round().clamp(
            12,
            65,
          ),
          km: adjusted.km * 0.70,
          targetLoad: (adjusted.targetLoad * 0.65).round().clamp(5, 60),
          targetHeartRateZone: adjusted.targetHeartRateZone.clamp(1, 3),
          stimulus: TrainingStimulus.technical,
          energySystem: TrainingEnergySystem.aerobic,
          neuromuscularLoad: NeuromuscularLoad.low,
          aiReason:
              '${adjusted.aiReason}\n\nMemoria adaptativa: se controla carga lactácida porque el atleta ha mostrado sensibilidad metabólica.',
        );
      }

      if (protectNeural && isNeuralSpeed) {
        adjusted = adjusted.copyWith(
          title: '${adjusted.title} (velocidad protegida)',
          durationMinutes: (adjusted.durationMinutes * 0.70).round().clamp(
            10,
            55,
          ),
          km: adjusted.km * 0.65,
          targetLoad: (adjusted.targetLoad * 0.70).round().clamp(5, 65),
          targetHeartRateZone: adjusted.targetHeartRateZone.clamp(1, 3),
          neuromuscularLoad: NeuromuscularLoad.moderate,
          aiReason:
              '${adjusted.aiReason}\n\nMemoria adaptativa: se conserva velocidad, pero con menor dosis porque la tolerancia neural/Z5 no está alta.',
        );
      }

      if (protectGym && isGym) {
        adjusted = adjusted.copyWith(
          title: '${adjusted.title} (fuerza protegida)',
          durationMinutes: (adjusted.durationMinutes * 0.70).round().clamp(
            15,
            55,
          ),
          targetLoad: (adjusted.targetLoad * 0.65).round().clamp(5, 60),
          stimulus: TrainingStimulus.strengthEndurance,
          neuromuscularLoad: NeuromuscularLoad.low,
          aiReason:
              '${adjusted.aiReason}\n\nMemoria adaptativa: se reduce fuerza pesada por tolerancia de gimnasio/tendón/músculo.',
        );
      }

      if (needsLongerTaper && !adjusted.recoveryFocused) {
        adjusted = adjusted.copyWith(
          durationMinutes: (adjusted.durationMinutes * 0.85).round().clamp(
            10,
            90,
          ),
          km: adjusted.km * 0.85,
          targetLoad: (adjusted.targetLoad * 0.82).round().clamp(5, 75),
          taperFocused: true,
          aiReason:
              '${adjusted.aiReason}\n\nMemoria adaptativa: este atleta necesita una descarga/taper más conservador.',
        );
      }

      return adjusted;
    }).toList();

    if (protectDensity && blocks.length > 2) {
      final primary = blocks.firstWhere(
        (block) =>
            block.type == TrainingBlockType.skating ||
            block.stimulus == TrainingStimulus.speed ||
            block.stimulus == TrainingStimulus.aerobic,
        orElse: () => blocks.first,
      );

      blocks = [
        primary,
        const DailyTrainingBlock(
          type: TrainingBlockType.recovery,
          moment: TrainingBlockMoment.evening,
          title: 'Recuperación adaptativa',
          description:
              'Sesión añadida para proteger recuperación porque la memoria del atleta no recomienda alta densidad.',
          durationMinutes: 20,
          km: 0,
          targetLoad: 10,
          targetHeartRateZone: 1,
          recoveryFocused: true,
          taperFocused: false,
          aiReason:
              'Memoria adaptativa: se reduce densidad diaria y se prioriza recuperación.',
          stimulus: TrainingStimulus.recovery,
          energySystem: TrainingEnergySystem.none,
          neuromuscularLoad: NeuromuscularLoad.low,
          mainSet: [
            'Movilidad suave.',
            'Respiración diafragmática.',
            'Descarga ligera de piernas.',
          ],
          coachingNotes: [
            'No convertir en entrenamiento extra.',
            'Debe terminar con mejor sensación que al inicio.',
          ],
          stopCriteria: ['Dolor.', 'Fatiga creciente.'],
        ),
      ];
    }

    return day.copyWith(
      blocks: blocks,
      aiSummary:
          '${day.aiSummary}\n\nMemoria adaptativa aplicada internamente al plan.',
      aiRecommendation:
          '${day.aiRecommendation}\n\nLa planificación fue ajustada según tolerancia individual a velocidad, lactato, gimnasio, pliometría, densidad y taper.',
    );
  }

  static IntegratedTrainingDay _applyDailyProgression({
    required IntegratedTrainingDay day,
    required TrainingProgressionDecision decision,
    required AthleteDailyState dailyState,
  }) {
    if (day.recoveryDay || day.taperMode) {
      return day;
    }

    if (!decision.canAddSession) {
      return day;
    }

    if (dailyState.shouldForceRecovery ||
        dailyState.shouldBlockIntensity ||
        dailyState.fatigueStatus == 'red' ||
        dailyState.fatigueStatus == 'orange') {
      return day;
    }

    final currentBlocks = day.blocks;

    final hasMorning = currentBlocks.any(
      (block) => block.moment == TrainingBlockMoment.morning,
    );

    final hasAfternoon = currentBlocks.any(
      (block) => block.moment == TrainingBlockMoment.afternoon,
    );

    final hasEvening = currentBlocks.any(
      (block) => block.moment == TrainingBlockMoment.evening,
    );

    final hasHighNeural = currentBlocks.any(
      (block) =>
          block.neuromuscularLoad == NeuromuscularLoad.high ||
          block.neuromuscularLoad == NeuromuscularLoad.maximal,
    );

    final hasPlyometric = currentBlocks.any(
      (block) => block.stimulus == TrainingStimulus.plyometric,
    );

    final hasStrength = currentBlocks.any(
      (block) => block.type == TrainingBlockType.strength,
    );

    final hasCycling = currentBlocks.any(
      (block) => block.type == TrainingBlockType.cycling,
    );

    final extraBlocks = TrainingProgressionBlockBuilder.buildExtraBlocks(
      decision: decision,
    );

    final acceptedExtras = <DailyTrainingBlock>[];

    for (final block in extraBlocks) {
      if (block.moment == TrainingBlockMoment.morning && hasMorning) {
        continue;
      }

      if (block.moment == TrainingBlockMoment.afternoon && hasAfternoon) {
        continue;
      }

      if (block.moment == TrainingBlockMoment.evening && hasEvening) {
        continue;
      }

      if (block.type == TrainingBlockType.cycling && hasCycling) {
        continue;
      }

      if (block.type == TrainingBlockType.strength && hasStrength) {
        continue;
      }

      if (block.stimulus == TrainingStimulus.plyometric &&
          (hasPlyometric || hasHighNeural)) {
        continue;
      }

      if (block.neuromuscularLoad == NeuromuscularLoad.high && hasHighNeural) {
        continue;
      }

      acceptedExtras.add(block);
    }

    if (acceptedExtras.isEmpty) {
      return day;
    }

    final maxBlocks = decision.mode == TrainingProgressionMode.addThirdSession
        ? 4
        : 3;

    final remainingSlots = (maxBlocks - currentBlocks.length)
        .clamp(0, 4)
        .toInt();

    if (remainingSlots <= 0) {
      return day;
    }

    final finalBlocks = [
      ...currentBlocks,
      ...acceptedExtras.take(remainingSlots),
    ];

    return day.copyWith(
      blocks: finalBlocks,
      aiSummary:
          '${day.aiSummary} Progresi�n diaria aplicada: ${decision.reason}',
      aiRecommendation:
          '${day.aiRecommendation} La carga extra fue a�adida solo porque la fisiolog�a actual lo permite.',
    );
  }

  static IntegratedTrainingDay _generateDayFromWeeklyPlanOrFallback({
    required AthleteProgramProfile athlete,
    required AthletePerformanceContext context,
    required DateTime date,
    required AthleteDailyState dailyState,
  }) {
    final week = _findWeekForDate(athlete: athlete, date: date);

    if (week == null || week.intelligentPlan == null) {
      return IntegratedDayGeneratorEngine.generate(
        context: context,
        date: date,
      );
    }

    final dayIndex = _dayIndexInWeek(week: week, date: date);
    final weeklyDay = week.intelligentPlan!.days.firstWhere(
      (day) => day.dayIndex == dayIndex,
      orElse: () => week.intelligentPlan!.days.first,
    );

    if (weeklyDay.sessions.isEmpty) {
      return IntegratedDayGeneratorEngine.generate(
        context: context,
        date: date,
      );
    }

    final blocks = <DailyTrainingBlock>[];

    for (int i = 0; i < weeklyDay.sessions.length; i++) {
      blocks.add(
        _blockFromTemplate(
          template: weeklyDay.sessions[i],
          moment: _momentForIndex(i),
          dailyState: dailyState,
          taperMode: week.taperWeek,
        ),
      );
    }

    return IntegratedTrainingDay(
      date: date,
      blocks: blocks,
      aiSummary:
          'Semana ${week.weekNumber} · ${week.phaseEs}. Plan diario tomado del microciclo semanal inteligente.',
      aiRecommendation:
          'Ejecutar el plan del día, sujeto al control de carga por readiness, ACWR, fatiga, HRV, sueño y riesgo.',
      expectedReadiness: dailyState.readiness,
      expectedFatigue: dailyState.fatigueStatus,
      taperMode: week.taperWeek,
      recoveryDay: blocks.every((block) => block.recoveryFocused),
    );
  }

  static bool _hasWeeklyIntelligentPlanForDate({
    required AthleteProgramProfile athlete,
    required DateTime date,
  }) {
    final week = _findWeekForDate(athlete: athlete, date: date);

    if (week == null) return false;
    if (week.intelligentPlan == null) return false;

    final dayIndex = _dayIndexInWeek(week: week, date: date);

    return week.intelligentPlan!.days.any((day) {
      return day.dayIndex == dayIndex && day.sessions.isNotEmpty;
    });
  }

  static AthleteTrainingWeek? _findWeekForDate({
    required AthleteProgramProfile athlete,
    required DateTime date,
  }) {
    final cleanDate = _cleanDate(date);

    for (final week in athlete.seasonPlan) {
      final start = _cleanDate(week.startDate);
      final end = _cleanDate(week.endDate);

      final isInside = !cleanDate.isBefore(start) && !cleanDate.isAfter(end);

      if (isInside) return week;
    }

    return null;
  }

  static int _dayIndexInWeek({
    required AthleteTrainingWeek week,
    required DateTime date,
  }) {
    final start = _cleanDate(week.startDate);
    final cleanDate = _cleanDate(date);

    final difference = cleanDate.difference(start).inDays;

    if (difference < 0) return 0;
    if (difference > 6) return 6;

    return difference;
  }

  static DateTime _cleanDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static TrainingBlockMoment _momentForIndex(int index) {
    if (index == 0) return TrainingBlockMoment.morning;
    if (index == 1) return TrainingBlockMoment.afternoon;
    return TrainingBlockMoment.evening;
  }

  static DailyTrainingBlock _blockFromTemplate({
    required TrainingSessionTemplate template,
    required TrainingBlockMoment moment,
    required AthleteDailyState dailyState,
    required bool taperMode,
  }) {
    final blockType = _blockTypeFromTemplate(template);
    final stimulus = _stimulusFromTemplate(template);
    final energySystem = _energySystemFromTemplate(template);
    final neuromuscularLoad = _neuromuscularLoadFromTemplate(template);

    final isStrength = blockType == TrainingBlockType.strength;
    final isCycling = blockType == TrainingBlockType.cycling;
    final isSkating = blockType == TrainingBlockType.skating;

    final mainSet = _mainSetFromTemplate(template);
    final complementary = _complementaryFromTemplate(template);
    final warmup = _warmupFromTemplate(template, blockType);
    final cooldown = _cooldownFromTemplate(template, blockType);

    return DailyTrainingBlock(
      type: blockType,
      moment: moment,
      title: template.title,
      description: _descriptionFromTemplate(template),
      durationMinutes: _durationFromTemplate(template),
      km: _kmFromTemplate(template),
      targetLoad: _loadFromTemplate(template),
      targetHeartRateZone: _zoneFromTemplate(template),
      recoveryFocused: template.recoverySession,
      taperFocused: taperMode || template.taperCompatible,
      aiReason:
          'Sesión tomada del plan semanal. Control diario disponible por readiness ${dailyState.readiness}, ACWR ${dailyState.acwr.toStringAsFixed(2)} y fatiga ${dailyState.fatigueStatus}.',
      stimulus: stimulus,
      energySystem: energySystem,
      neuromuscularLoad: neuromuscularLoad,
      warmup: warmup,
      mainSet: mainSet,
      exercises: complementary,
      strengthExercises: isStrength
          ? _strengthExercisesFromTemplate(template)
          : const [],
      plyometricExercises: isStrength
          ? _strengthTransferExercises(template)
          : template.category == TrainingLibraryCategory.plyometric
          ? template.complementary
          : const [],
      technicalCues: _technicalCuesFromTemplate(template, blockType),
      tacticalCues: template.category == TrainingLibraryCategory.tactical
          ? template.technicalCues
          : const [],
      cooldown: cooldown,
      coachingNotes: _coachingNotesFromTemplate(
        template: template,
        isStrength: isStrength,
        isCycling: isCycling,
        isSkating: isSkating,
      ),
      stopCriteria: _stopCriteriaFromTemplate(template, blockType),
    );
  }

  static List<String> _mainSetFromTemplate(TrainingSessionTemplate template) {
    if (!template.gymSession) return template.mainSet;

    final result = <String>[];

    if (template.mainSet.isEmpty) {
      result.add('Bloque de fuerza principal según la sesión programada.');
    } else {
      result.addAll(template.mainSet);
    }

    final transfer = _strengthTransferExercises(template);

    if (transfer.isNotEmpty) {
      result.add('Transferencia fuerza → velocidad:');
      result.addAll(transfer);
    }

    return result;
  }

  static List<String> _strengthExercisesFromTemplate(
    TrainingSessionTemplate template,
  ) {
    if (template.mainSet.isNotEmpty) return template.mainSet;
    if (template.complementary.isNotEmpty) return template.complementary;

    return const ['Ejercicio principal de fuerza según objetivo de la sesión.'];
  }

  static List<String> _strengthTransferExercises(
    TrainingSessionTemplate template,
  ) {
    if (!template.gymSession &&
        template.category != TrainingLibraryCategory.strength &&
        template.category != TrainingLibraryCategory.power) {
      return const [];
    }

    final text = [
      template.title,
      template.objective,
      template.type,
      ...template.mainSet,
      ...template.complementary,
    ].join(' ').toLowerCase();

    if (text.contains('sentadilla') ||
        text.contains('squat') ||
        text.contains('front squat') ||
        text.contains('back squat')) {
      return const [
        'Después de cada serie principal: 3-5 saltos verticales o squat jumps con máxima intención.',
        'Transferencia específica: 2-3 series de bounds laterales o saltos horizontales controlados.',
        'Objetivo: convertir fuerza de extensión de cadera-rodilla-tobillo en empuje potente de patinaje.',
      ];
    }

    if (text.contains('peso muerto') ||
        text.contains('deadlift') ||
        text.contains('trap bar') ||
        text.contains('hip thrust')) {
      return const [
        'Después de cada serie principal: 4-6 saltos horizontales o broad jumps con descanso completo.',
        'Transferencia específica: aceleraciones cortas o empujes explosivos en seco si el espacio lo permite.',
        'Objetivo: transformar fuerza de cadena posterior en aceleración y salida potente.',
      ];
    }

    if (text.contains('zancada') ||
        text.contains('lunge') ||
        text.contains('step up') ||
        text.contains('unilateral')) {
      return const [
        'Después de cada serie principal: 4-6 saltos laterales por lado con aterrizaje estable.',
        'Transferencia específica: bounds laterales imitando dirección de empuje del patinaje.',
        'Objetivo: mejorar fuerza unilateral, estabilidad de apoyo y transferencia lateral.',
      ];
    }

    if (template.category == TrainingLibraryCategory.power ||
        template.reactiveFocused ||
        template.neuralFocused) {
      return const [
        'Combinar cada ejercicio de potencia con 3-5 repeticiones explosivas de baja fatiga.',
        'Mantener descansos amplios para preservar velocidad de ejecución.',
        'Objetivo: producir potencia útil sin acumular fatiga neuromuscular innecesaria.',
      ];
    }

    return const [
      'Después del ejercicio principal: 3-5 saltos de potencia o bounds específicos con máxima calidad.',
      'Mantener descansos suficientes para que cada repetición sea rápida, limpia y explosiva.',
      'Objetivo: transferir fuerza del gimnasio a velocidad, aceleración y empuje específico.',
    ];
  }

  static List<String> _complementaryFromTemplate(
    TrainingSessionTemplate template,
  ) {
    final result = <String>[...template.complementary];

    if (template.cyclingSession) {
      result.addAll(_cyclingPerformanceNotes(template));
    }

    return result;
  }

  static List<String> _cyclingPerformanceNotes(
    TrainingSessionTemplate template,
  ) {
    if (!template.cyclingSession) return const [];

    switch (template.intensity) {
      case TrainingSessionIntensity.recovery:
        return const [
          'Cadencia fácil y constante para recuperar sin sumar estrés.',
          'Usar la bicicleta como descarga cardiovascular y circulación.',
        ];
      case TrainingSessionIntensity.low:
        return const [
          'Base aeróbica controlada sin volumen excesivo.',
          'Priorizar cadencia eficiente y sensación de piernas sueltas.',
        ];
      case TrainingSessionIntensity.moderate:
        return const [
          'Bloques de ritmo sostenido con cambios cortos de cadencia.',
          'Objetivo: sostener potencia útil sin convertir la sesión en fondo excesivo.',
        ];
      case TrainingSessionIntensity.high:
        return const [
          'Intervalos cortos o medios orientados a cambios de ritmo.',
          'Objetivo: mejorar tolerancia a aceleraciones repetidas y remates.',
        ];
      case TrainingSessionIntensity.maximal:
        return const [
          'Sprints cortos en bicicleta con recuperación amplia.',
          'Objetivo: potencia, velocidad de piernas y capacidad de responder ataques.',
        ];
    }
  }

  static List<String> _warmupFromTemplate(
    TrainingSessionTemplate template,
    TrainingBlockType blockType,
  ) {
    if (template.warmup.isNotEmpty) return template.warmup;

    switch (blockType) {
      case TrainingBlockType.strength:
        return const [
          'Movilidad dinámica de cadera, tobillo y columna.',
          'Activación de glúteo, core y sóleo.',
          'Series progresivas antes del primer ejercicio principal.',
        ];
      case TrainingBlockType.cycling:
        return const [
          '10 min progresivos Z1-Z2.',
          '3 aceleraciones cortas de cadencia sin fatiga.',
        ];
      case TrainingBlockType.skating:
        return const [
          'Entrada progresiva en pista.',
          'Movilidad dinámica y técnica básica antes del bloque principal.',
        ];
      case TrainingBlockType.recovery:
      case TrainingBlockType.mobility:
      case TrainingBlockType.activation:
      case TrainingBlockType.technical:
      case TrainingBlockType.aerobic:
        return const [
          'Preparación suave y progresiva.',
          'Movilidad controlada antes del bloque principal.',
        ];
    }
  }

  static List<String> _cooldownFromTemplate(
    TrainingSessionTemplate template,
    TrainingBlockType blockType,
  ) {
    switch (blockType) {
      case TrainingBlockType.strength:
        return const [
          'Movilidad suave de cadera, tobillo y espalda.',
          'Respiración diafragmática 3-5 min.',
          'Descarga ligera de cuádriceps, glúteo, sóleo y zona lumbar.',
        ];
      case TrainingBlockType.cycling:
        return const [
          '8-12 min muy suave en Z1.',
          'Soltar piernas sin buscar potencia.',
          'Hidratación y recuperación posterior.',
        ];
      case TrainingBlockType.skating:
        return const [
          'Rodaje suave o movilidad fuera de pista.',
          'Bajar progresivamente la activación neural.',
        ];
      case TrainingBlockType.recovery:
        return const ['Respiración lenta y movilidad muy suave.'];
      case TrainingBlockType.mobility:
      case TrainingBlockType.activation:
      case TrainingBlockType.technical:
      case TrainingBlockType.aerobic:
        return const ['Cerrar con movilidad suave y respiración controlada.'];
    }
  }

  static List<String> _technicalCuesFromTemplate(
    TrainingSessionTemplate template,
    TrainingBlockType blockType,
  ) {
    final result = <String>[...template.technicalCues];

    if (blockType == TrainingBlockType.strength) {
      result.addAll(const [
        'Buscar intención explosiva en la fase concéntrica.',
        'Mantener alineación rodilla-pie y estabilidad de cadera.',
        'La transferencia debe sentirse rápida, no fatigante.',
      ]);
    }

    if (blockType == TrainingBlockType.cycling) {
      result.addAll(const [
        'Cadencia estable y técnica limpia.',
        'No convertir la bicicleta en volumen excesivo sin objetivo.',
        'En cambios de ritmo, buscar potencia controlada y recuperación completa.',
      ]);
    }

    return result.toSet().toList();
  }

  static List<String> _coachingNotesFromTemplate({
    required TrainingSessionTemplate template,
    required bool isStrength,
    required bool isCycling,
    required bool isSkating,
  }) {
    final notes = <String>[];

    if (template.coachNotes.trim().isNotEmpty) {
      notes.add(template.coachNotes.trim());
    }

    if (isStrength) {
      notes.add(
        'Cada bloque principal de fuerza debe tener intención de transferencia a velocidad específica de patinaje.',
      );
      notes.add(
        'No perseguir fatiga muscular excesiva: la prioridad es fuerza útil, potencia y calidad neuromuscular.',
      );
    }

    if (isCycling) {
      notes.add(
        'La bicicleta debe apoyar fuerza, velocidad, cambios de ritmo y recuperación; evitar base larga sin objetivo.',
      );
      notes.add(
        'Para patinaje, incluso 5 km y 10 km requieren potencia, remates, aceleraciones y capacidad de responder ataques.',
      );
    }

    if (isSkating) {
      notes.add(
        'Mantener calidad técnica y control de carga durante aceleraciones, cambios de ritmo o trabajo de velocidad.',
      );
    }

    return notes;
  }

  static List<String> _stopCriteriaFromTemplate(
    TrainingSessionTemplate template,
    TrainingBlockType blockType,
  ) {
    final criteria = <String>[...template.cutCriteria];

    switch (blockType) {
      case TrainingBlockType.strength:
        criteria.addAll(const [
          'Pérdida clara de velocidad de ejecución.',
          'Dolor lumbar, rodilla, Aquiles o tendón rotuliano.',
          'Pérdida de técnica en la transferencia explosiva.',
        ]);
        break;
      case TrainingBlockType.cycling:
        criteria.addAll(const [
          'Pulso fuera de la zona indicada de forma sostenida.',
          'Piernas pesadas que impiden cadencia limpia.',
          'Fatiga que compromete la sesión principal de patinaje.',
        ]);
        break;
      case TrainingBlockType.skating:
        criteria.addAll(const [
          'Pérdida de técnica o coordinación.',
          'Dolor articular o tendinoso.',
          'Fatiga que impide mantener calidad.',
        ]);
        break;
      case TrainingBlockType.recovery:
      case TrainingBlockType.mobility:
      case TrainingBlockType.activation:
      case TrainingBlockType.technical:
      case TrainingBlockType.aerobic:
        criteria.addAll(const [
          'Dolor.',
          'Aumento claro de fatiga.',
          'Pérdida de control del movimiento.',
        ]);
        break;
    }

    return criteria.toSet().toList();
  }

  static String _descriptionFromTemplate(TrainingSessionTemplate template) {
    final parts = <String>[];

    if (template.objective.trim().isNotEmpty) {
      parts.add(template.objective.trim());
    }

    if (template.type.trim().isNotEmpty) {
      parts.add('Tipo: ${template.type.trim()}.');
    }

    if (template.gymSession) {
      parts.add(
        'Fuerza orientada a transferencia: cada ejercicio principal debe conectar con potencia, velocidad o empuje específico.',
      );
    }

    if (template.cyclingSession) {
      parts.add(
        'Bicicleta orientada a rendimiento en patinaje: potencia, cambios de ritmo, recuperación y velocidad de piernas sin base excesiva.',
      );
    }

    if (template.mainSet.isNotEmpty) {
      parts.add('Trabajo principal: ${template.mainSet.join(' ')}');
    }

    if (parts.isEmpty) return template.title;

    return parts.join(' ');
  }

  static TrainingBlockType _blockTypeFromTemplate(
    TrainingSessionTemplate template,
  ) {
    if (template.gymSession) return TrainingBlockType.strength;
    if (template.cyclingSession) return TrainingBlockType.cycling;
    if (template.recoverySession) return TrainingBlockType.recovery;

    switch (template.category) {
      case TrainingLibraryCategory.speed:
      case TrainingLibraryCategory.acceleration:
      case TrainingLibraryCategory.maxVelocity:
      case TrainingLibraryCategory.lactate:
      case TrainingLibraryCategory.tactical:
        return TrainingBlockType.skating;

      case TrainingLibraryCategory.endurance:
      case TrainingLibraryCategory.tempo:
        return TrainingBlockType.aerobic;

      case TrainingLibraryCategory.strength:
      case TrainingLibraryCategory.power:
      case TrainingLibraryCategory.plyometric:
        return TrainingBlockType.strength;

      case TrainingLibraryCategory.technical:
        return TrainingBlockType.technical;

      case TrainingLibraryCategory.core:
      case TrainingLibraryCategory.mobility:
      case TrainingLibraryCategory.prehab:
        return TrainingBlockType.mobility;

      case TrainingLibraryCategory.recovery:
        return TrainingBlockType.recovery;

      case TrainingLibraryCategory.cycling:
        return TrainingBlockType.cycling;

      case TrainingLibraryCategory.test:
        return TrainingBlockType.skating;
    }
  }

  static TrainingStimulus _stimulusFromTemplate(
    TrainingSessionTemplate template,
  ) {
    if (template.recoverySession) return TrainingStimulus.recovery;

    switch (template.category) {
      case TrainingLibraryCategory.speed:
      case TrainingLibraryCategory.acceleration:
      case TrainingLibraryCategory.maxVelocity:
        return TrainingStimulus.speed;

      case TrainingLibraryCategory.lactate:
        return TrainingStimulus.lactateTolerance;

      case TrainingLibraryCategory.endurance:
      case TrainingLibraryCategory.tempo:
      case TrainingLibraryCategory.cycling:
        return TrainingStimulus.aerobic;

      case TrainingLibraryCategory.tactical:
        return TrainingStimulus.tactical;

      case TrainingLibraryCategory.strength:
        return TrainingStimulus.maxStrength;

      case TrainingLibraryCategory.power:
        return TrainingStimulus.power;

      case TrainingLibraryCategory.plyometric:
        return TrainingStimulus.plyometric;

      case TrainingLibraryCategory.technical:
        return TrainingStimulus.technical;

      case TrainingLibraryCategory.core:
      case TrainingLibraryCategory.mobility:
      case TrainingLibraryCategory.prehab:
        return TrainingStimulus.mobility;

      case TrainingLibraryCategory.recovery:
        return TrainingStimulus.recovery;

      case TrainingLibraryCategory.test:
        return TrainingStimulus.anaerobic;
    }
  }

  static TrainingEnergySystem _energySystemFromTemplate(
    TrainingSessionTemplate template,
  ) {
    if (template.recoverySession) return TrainingEnergySystem.aerobic;

    switch (template.category) {
      case TrainingLibraryCategory.speed:
      case TrainingLibraryCategory.acceleration:
      case TrainingLibraryCategory.maxVelocity:
      case TrainingLibraryCategory.power:
      case TrainingLibraryCategory.plyometric:
        return TrainingEnergySystem.anaerobicAlactic;

      case TrainingLibraryCategory.lactate:
        return TrainingEnergySystem.anaerobicLactic;

      case TrainingLibraryCategory.endurance:
      case TrainingLibraryCategory.tempo:
      case TrainingLibraryCategory.technical:
        return TrainingEnergySystem.aerobic;

      case TrainingLibraryCategory.cycling:
        return template.intensity == TrainingSessionIntensity.high ||
                template.intensity == TrainingSessionIntensity.maximal
            ? TrainingEnergySystem.mixed
            : TrainingEnergySystem.aerobic;

      case TrainingLibraryCategory.tactical:
      case TrainingLibraryCategory.test:
        return TrainingEnergySystem.mixed;

      case TrainingLibraryCategory.strength:
      case TrainingLibraryCategory.core:
      case TrainingLibraryCategory.mobility:
      case TrainingLibraryCategory.recovery:
      case TrainingLibraryCategory.prehab:
        return TrainingEnergySystem.none;
    }
  }

  static NeuromuscularLoad _neuromuscularLoadFromTemplate(
    TrainingSessionTemplate template,
  ) {
    if (template.recoverySession) return NeuromuscularLoad.low;

    if (template.gymSession ||
        template.category == TrainingLibraryCategory.strength) {
      if (template.intensity == TrainingSessionIntensity.maximal) {
        return NeuromuscularLoad.maximal;
      }
      if (template.intensity == TrainingSessionIntensity.high) {
        return NeuromuscularLoad.high;
      }
      return NeuromuscularLoad.moderate;
    }

    if (template.category == TrainingLibraryCategory.power ||
        template.category == TrainingLibraryCategory.plyometric ||
        template.category == TrainingLibraryCategory.speed ||
        template.category == TrainingLibraryCategory.acceleration ||
        template.category == TrainingLibraryCategory.maxVelocity) {
      return template.intensity == TrainingSessionIntensity.maximal
          ? NeuromuscularLoad.maximal
          : NeuromuscularLoad.high;
    }

    if (template.cyclingSession &&
        (template.intensity == TrainingSessionIntensity.high ||
            template.intensity == TrainingSessionIntensity.maximal)) {
      return NeuromuscularLoad.moderate;
    }

    if (template.neuralFocused || template.reactiveFocused) {
      return NeuromuscularLoad.moderate;
    }

    if (template.metabolicFocused) {
      return NeuromuscularLoad.moderate;
    }

    return NeuromuscularLoad.low;
  }

  static int _durationFromTemplate(TrainingSessionTemplate template) {
    if (template.cyclingSession) {
      switch (template.intensity) {
        case TrainingSessionIntensity.recovery:
          return 30;
        case TrainingSessionIntensity.low:
          return 40;
        case TrainingSessionIntensity.moderate:
          return 50;
        case TrainingSessionIntensity.high:
          return 45;
        case TrainingSessionIntensity.maximal:
          return 35;
      }
    }

    if (template.gymSession) {
      switch (template.intensity) {
        case TrainingSessionIntensity.recovery:
          return 25;
        case TrainingSessionIntensity.low:
          return 40;
        case TrainingSessionIntensity.moderate:
          return 55;
        case TrainingSessionIntensity.high:
          return 70;
        case TrainingSessionIntensity.maximal:
          return 65;
      }
    }

    switch (template.intensity) {
      case TrainingSessionIntensity.recovery:
        return 30;
      case TrainingSessionIntensity.low:
        return 45;
      case TrainingSessionIntensity.moderate:
        return 65;
      case TrainingSessionIntensity.high:
        return 80;
      case TrainingSessionIntensity.maximal:
        return 70;
    }
  }

  static double _kmFromTemplate(TrainingSessionTemplate template) {
    if (template.cyclingSession) {
      switch (template.intensity) {
        case TrainingSessionIntensity.recovery:
          return 12;
        case TrainingSessionIntensity.low:
          return 20;
        case TrainingSessionIntensity.moderate:
          return 28;
        case TrainingSessionIntensity.high:
          return 30;
        case TrainingSessionIntensity.maximal:
          return 22;
      }
    }

    if (!template.skatingSession) return 0;

    switch (template.category) {
      case TrainingLibraryCategory.endurance:
        return template.intensity == TrainingSessionIntensity.high ? 22 : 16;
      case TrainingLibraryCategory.tempo:
        return template.intensity == TrainingSessionIntensity.high ? 18 : 14;
      case TrainingLibraryCategory.lactate:
        return 10;
      case TrainingLibraryCategory.speed:
      case TrainingLibraryCategory.acceleration:
      case TrainingLibraryCategory.maxVelocity:
        return 7;
      case TrainingLibraryCategory.recovery:
        return 5;
      default:
        break;
    }

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
        return 14;
      case TrainingSessionIntensity.low:
        return 30;
      case TrainingSessionIntensity.moderate:
        return 55;
      case TrainingSessionIntensity.high:
        return 80;
      case TrainingSessionIntensity.maximal:
        return 90;
    }
  }

  static int _zoneFromTemplate(TrainingSessionTemplate template) {
    if (template.recoverySession) return 1;
    if (template.cyclingSession &&
        template.intensity == TrainingSessionIntensity.recovery) {
      return 1;
    }
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

  static StrengthLoadState _calculateStrengthLoad(
    IntegratedTrainingDay day,
    double athleteWeightKg,
  ) {
    final rawExercises = <String>[];

    for (final block in day.blocks) {
      rawExercises.addAll(block.strengthExercises);
      rawExercises.addAll(block.plyometricExercises);
      rawExercises.addAll(block.exercises);
    }

    if (rawExercises.isEmpty) {
      return const StrengthLoadState(
        externalStrengthLoadKg: 0,
        reactiveJumpLoadKg: 0,
        totalMechanicalLoadKg: 0,
        neuralStress: 0,
        muscleStress: 0,
        tendonStress: 0,
        adaptationSignal: 'none',
      );
    }

    final parsed = GymExerciseParser.parse(rawExercises);

    return StrengthLoadCalculator.calculate(
      exercises: parsed,
      athleteWeightKg: athleteWeightKg,
    );
  }
}
