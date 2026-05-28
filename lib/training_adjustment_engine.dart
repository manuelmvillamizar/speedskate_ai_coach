import 'daily_training_block.dart';
import 'integrated_training_day.dart';
import 'training_intervention_engine.dart';

class TrainingAdjustmentEngine {
  static IntegratedTrainingDay apply({
    required IntegratedTrainingDay day,
    required TrainingInterventionResult intervention,
  }) {
    if (intervention.forceRecovery) {
      return _forceRecovery(day, intervention);
    }

    var adjustedBlocks = day.blocks
        .map((block) => _adjustBlock(block, intervention))
        .toList();

    adjustedBlocks = _applyDoubleSessionProtection(
      adjustedBlocks,
      intervention,
    );

    adjustedBlocks = _removeRedundantRecoveryBlocks(adjustedBlocks);

    adjustedBlocks = _preservePrimaryStimulus(
      adjustedBlocks,
      day,
      intervention,
    );

    adjustedBlocks = _sortBlocksByMoment(adjustedBlocks);

    return day.copyWith(
      blocks: adjustedBlocks,
      aiSummary:
          '${day.aiSummary}\n\nControl de carga aplicado para proteger adaptación, frescura y recuperación.',
      aiRecommendation:
          '${day.aiRecommendation}\n\nAjuste aplicado: ${intervention.summary}',
    );
  }

  static DailyTrainingBlock _adjustBlock(
    DailyTrainingBlock block,
    TrainingInterventionResult intervention,
  ) {
    var adjusted = block;

    adjusted = _applyHeavyStrengthProtection(adjusted, intervention);
    adjusted = _applyReactiveProtection(adjusted, intervention);
    adjusted = _applyHighIntensityProtection(adjusted, intervention);
    adjusted = _applyVolumeReduction(adjusted, intervention);
    adjusted = _applyCompetitionProtection(adjusted, intervention);
    adjusted = _protectRecoveryBlocks(adjusted);

    return adjusted;
  }

  static IntegratedTrainingDay _forceRecovery(
    IntegratedTrainingDay day,
    TrainingInterventionResult intervention,
  ) {
    return day.copyWith(
      expectedFatigue: 'red',
      taperMode: false,
      recoveryDay: true,
      aiSummary:
          'Recuperación forzada por fatiga crítica, riesgo elevado o posible sobreentrenamiento.',
      aiRecommendation:
          'Priorizar sueño, hidratación, movilidad, respiración y baja carga. No compensar entrenamiento perdido.',
      blocks: const [
        DailyTrainingBlock(
          type: TrainingBlockType.cycling,
          moment: TrainingBlockMoment.morning,
          title: 'Recuperación aeróbica muy suave',
          description:
              'Bicicleta, caminata o rodaje muy suave Z1. Debe sentirse fácil, sin presión de ritmo ni carga.',
          durationMinutes: 20,
          km: 0,
          targetLoad: 12,
          targetHeartRateZone: 1,
          recoveryFocused: true,
          taperFocused: false,
          aiReason:
              'Se elimina carga neuromuscular y metabólica para permitir recuperación fisiológica.',
          stimulus: TrainingStimulus.recovery,
          energySystem: TrainingEnergySystem.aerobic,
          neuromuscularLoad: NeuromuscularLoad.low,
          warmup: [
            '5 min muy suave en Z1.',
            'Respiración nasal o diafragmática si es posible.',
          ],
          mainSet: [
            '15-20 min continuo muy fácil en Z1.',
            'Mantener sensación de recuperación, sin buscar ritmo.',
          ],
          coachingNotes: [
            'No convertir esta sesión en entrenamiento compensatorio.',
            'Debe terminar con mejor sensación que al inicio.',
          ],
          stopCriteria: [
            'Dolor articular o tendinoso.',
            'Pulso anormalmente alto para Z1.',
            'Sensación de fatiga creciente.',
          ],
        ),
        DailyTrainingBlock(
          type: TrainingBlockType.mobility,
          moment: TrainingBlockMoment.afternoon,
          title: 'Movilidad + respiración',
          description:
              'Movilidad de cadera, tobillo, espalda, glúteo y respiración diafragmática. Sin dolor, sin fatiga.',
          durationMinutes: 25,
          km: 0,
          targetLoad: 10,
          targetHeartRateZone: 1,
          recoveryFocused: true,
          taperFocused: false,
          aiReason:
              'La movilidad restaura rango útil para posición baja sin aumentar estrés.',
          stimulus: TrainingStimulus.mobility,
          energySystem: TrainingEnergySystem.none,
          neuromuscularLoad: NeuromuscularLoad.low,
          mainSet: [
            'Movilidad suave de cadera, tobillo y columna.',
            'Activación ligera de glúteo y core sin fatiga.',
            'Respiración diafragmática 4-6 minutos.',
          ],
          coachingNotes: [
            'Priorizar rango cómodo y controlado.',
            'Evitar estiramientos agresivos o dolorosos.',
          ],
          stopCriteria: [
            'Dolor.',
            'Mareo.',
            'Aumento claro de fatiga.',
          ],
        ),
      ],
    );
  }

  static DailyTrainingBlock _applyHeavyStrengthProtection(
    DailyTrainingBlock block,
    TrainingInterventionResult intervention,
  ) {
    if (!intervention.blockHeavyStrength) return block;

    final isHeavyStrength =
        block.type == TrainingBlockType.strength &&
        (block.stimulus == TrainingStimulus.maxStrength ||
            block.stimulus == TrainingStimulus.power ||
            block.targetLoad >= 60 ||
            block.neuromuscularLoad == NeuromuscularLoad.high ||
            block.neuromuscularLoad == NeuromuscularLoad.maximal);

    if (!isHeavyStrength) return block;

    return DailyTrainingBlock(
      type: TrainingBlockType.mobility,
      moment: block.moment,
      title: 'Activación + estabilidad protegida',
      description:
          'Se reemplaza fuerza pesada por movilidad, core, estabilidad de cadera/tobillo y activación ligera.',
      durationMinutes: 25,
      km: 0,
      targetLoad: 18,
      targetHeartRateZone: 1,
      recoveryFocused: true,
      taperFocused: block.taperFocused,
      aiReason:
          '${block.aiReason}\n\nAjuste: fuerza pesada bloqueada para proteger sistema nervioso, tendones y recuperación.',
      stimulus: TrainingStimulus.mobility,
      energySystem: TrainingEnergySystem.none,
      neuromuscularLoad: NeuromuscularLoad.low,
      mainSet: const [
        'Movilidad controlada de cadera y tobillo.',
        'Core anti-rotación y estabilidad lumbo-pélvica.',
        'Activación ligera de glúteo medio, sóleo y tibial anterior.',
        'Trabajo técnico de postura baja sin carga externa pesada.',
      ],
      coachingNotes: const [
        'Mantener sensación de activación, no de fatiga.',
        'Evitar cargas axiales pesadas y saltos intensos.',
        'Priorizar control articular y calidad de movimiento.',
      ],
      stopCriteria: const [
        'Dolor tendinoso o articular.',
        'Pérdida de control postural.',
        'Fatiga neuromuscular evidente.',
      ],
    );
  }

  static DailyTrainingBlock _applyReactiveProtection(
    DailyTrainingBlock block,
    TrainingInterventionResult intervention,
  ) {
    if (!intervention.blockHeavyStrength) return block;

    final isReactive =
        block.stimulus == TrainingStimulus.plyometric ||
        (block.type == TrainingBlockType.activation &&
            block.neuromuscularLoad.index >= NeuromuscularLoad.moderate.index);

    if (!isReactive) return block;

    return block.copyWith(
      title: '${block.title} (reactividad protegida)',
      description:
          'Se reduce carga reactiva para proteger tendón rotuliano, Aquiles, tibiales y sistema neuromuscular.',
      durationMinutes: (block.durationMinutes * 0.55).round().clamp(10, 25),
      km: block.km * 0.50,
      targetLoad: (block.targetLoad * 0.50).round().clamp(5, 35),
      targetHeartRateZone: 2,
      recoveryFocused: false,
      aiReason:
          '${block.aiReason}\n\nAjuste: reducción reactiva/pliométrica para controlar stiffness y fatiga neural.',
      stimulus: TrainingStimulus.plyometric,
      energySystem: TrainingEnergySystem.anaerobicAlactic,
      neuromuscularLoad: NeuromuscularLoad.low,
    );
  }

  static DailyTrainingBlock _applyHighIntensityProtection(
    DailyTrainingBlock block,
    TrainingInterventionResult intervention,
  ) {
    if (!intervention.blockHighIntensity) return block;

    final isLactate =
        block.energySystem == TrainingEnergySystem.anaerobicLactic ||
        block.stimulus == TrainingStimulus.lactateTolerance;

    final isNeuralSpeed =
        block.isSpeedStimulus ||
        block.energySystem == TrainingEnergySystem.anaerobicAlactic;

    final isHighIntensity =
        block.targetHeartRateZone >= 4 ||
        block.targetLoad >= 75 ||
        isLactate ||
        block.neuromuscularLoad == NeuromuscularLoad.maximal;

    if (!isHighIntensity) return block;

    if (isNeuralSpeed) {
      return block.copyWith(
        title: '${block.title} (velocidad preservada)',
        description:
            'Se mantiene estímulo neural corto y fresco sin generar fatiga metabólica residual.',
        durationMinutes: (block.durationMinutes * 0.45).round().clamp(10, 30),
        km: block.km * 0.45,
        targetLoad: (block.targetLoad * 0.50).round().clamp(5, 55),
        targetHeartRateZone: block.targetHeartRateZone > 3
            ? 3
            : block.targetHeartRateZone,
        recoveryFocused: false,
        aiReason:
            '${block.aiReason}\n\nAjuste: velocidad neural protegida sin carga lactácida excesiva.',
        stimulus: TrainingStimulus.speed,
        energySystem: TrainingEnergySystem.anaerobicAlactic,
        neuromuscularLoad: NeuromuscularLoad.moderate,
      );
    }

    if (isLactate) {
      return DailyTrainingBlock(
        type: TrainingBlockType.technical,
        moment: block.moment,
        title: 'Técnica + ritmo controlado',
        description:
            'Se elimina carga lactácida y se mantiene eficiencia técnica y control de ritmo.',
        durationMinutes: (block.durationMinutes * 0.60).round().clamp(12, 45),
        km: block.km * 0.60,
        targetLoad: (block.targetLoad * 0.50).round().clamp(5, 50),
        targetHeartRateZone: 2,
        recoveryFocused: false,
        taperFocused: block.taperFocused,
        aiReason:
            '${block.aiReason}\n\nAjuste: lactato eliminado para proteger frescura y recuperación.',
        stimulus: TrainingStimulus.technical,
        energySystem: TrainingEnergySystem.aerobic,
        neuromuscularLoad: NeuromuscularLoad.low,
        warmup: const [
          '10 min progresivos Z1-Z2.',
          'Movilidad dinámica de cadera, tobillo y columna.',
        ],
        mainSet: const [
          'Bloques técnicos en Z2 con postura estable.',
          'Ritmo controlado sin entrar en acumulación lactácida.',
          'Priorizar eficiencia de empuje y recuperación entre esfuerzos.',
        ],
        technicalCues: const [
          'Empuje completo sin tensión excesiva.',
          'Postura baja estable.',
          'Respiración controlada y ritmo fluido.',
        ],
        coachingNotes: const [
          'No perseguir velocidad máxima.',
          'Mantener control técnico durante todo el bloque.',
        ],
        stopCriteria: const [
          'Piernas pesadas o pérdida de técnica.',
          'Sensación de lactato creciente.',
          'Pulso fuera de la zona indicada.',
        ],
      );
    }

    return block.copyWith(
      title: '${block.title} (carga protegida)',
      description: 'Carga reducida para limitar estrés fisiológico acumulado.',
      durationMinutes: (block.durationMinutes * 0.70).round().clamp(10, 50),
      km: block.km * 0.70,
      targetLoad: (block.targetLoad * 0.60).round().clamp(5, 60),
      targetHeartRateZone: block.targetHeartRateZone > 3
          ? 3
          : block.targetHeartRateZone,
      aiReason:
          '${block.aiReason}\n\nAjuste: reducción de intensidad para controlar fatiga.',
    );
  }

  static DailyTrainingBlock _applyVolumeReduction(
    DailyTrainingBlock block,
    TrainingInterventionResult intervention,
  ) {
    if (!intervention.reduceVolume) return block;
    if (block.recoveryFocused) return block;

    final reduction = block.neuromuscularLoad == NeuromuscularLoad.maximal
        ? 0.65
        : block.energySystem == TrainingEnergySystem.anaerobicLactic
            ? 0.68
            : 0.80;

    return block.copyWith(
      durationMinutes: (block.durationMinutes * reduction).round().clamp(
            10,
            120,
          ),
      km: block.km * reduction,
      targetLoad: (block.targetLoad * reduction).round().clamp(5, 90),
      aiReason:
          '${block.aiReason}\n\nAjuste: volumen reducido para controlar fatiga acumulada.',
    );
  }

  static DailyTrainingBlock _applyCompetitionProtection(
    DailyTrainingBlock block,
    TrainingInterventionResult intervention,
  ) {
    if (!intervention.protectCompetition) return block;

    final isHeavy =
        block.targetLoad > 60 ||
        block.energySystem == TrainingEnergySystem.anaerobicLactic ||
        block.neuromuscularLoad == NeuromuscularLoad.maximal;

    if (!isHeavy) return block;

    final protectedEnergy =
        block.energySystem == TrainingEnergySystem.anaerobicLactic
            ? TrainingEnergySystem.aerobic
            : block.energySystem;

    final protectedNeural = block.neuromuscularLoad == NeuromuscularLoad.maximal
        ? NeuromuscularLoad.moderate
        : block.neuromuscularLoad;

    if (block.isSpeedStimulus) {
      return block.copyWith(
        title: '${block.title} (priming preservado)',
        description:
            'Se mantiene velocidad corta y fresca para preservar timing neural y aceleración.',
        durationMinutes: (block.durationMinutes * 0.40).round().clamp(8, 20),
        km: block.km * 0.40,
        targetLoad: (block.targetLoad * 0.45).round().clamp(5, 45),
        targetHeartRateZone: 2,
        taperFocused: true,
        aiReason:
            '${block.aiReason}\n\nAjuste: taper sprint preserva velocidad neural sin fatiga residual.',
        energySystem: TrainingEnergySystem.anaerobicAlactic,
        neuromuscularLoad: NeuromuscularLoad.low,
      );
    }

    return block.copyWith(
      title: '${block.title} (frescura protegida)',
      description:
          'Carga reducida para llegar fresco. Mantener sensación rápida y técnica, sin fatiga nueva.',
      durationMinutes: (block.durationMinutes * 0.65).round().clamp(10, 45),
      km: block.km * 0.60,
      targetLoad: (block.targetLoad * 0.55).round().clamp(5, 55),
      targetHeartRateZone: block.targetHeartRateZone > 3
          ? 3
          : block.targetHeartRateZone,
      taperFocused: true,
      aiReason:
          '${block.aiReason}\n\nAjuste: protección precompetitiva/taper aplicada.',
      energySystem: protectedEnergy,
      neuromuscularLoad: protectedNeural,
    );
  }

  static DailyTrainingBlock _protectRecoveryBlocks(DailyTrainingBlock block) {
    if (!block.recoveryFocused) return block;

    return block.copyWith(
      targetLoad: block.targetLoad.clamp(5, 25),
      targetHeartRateZone: block.targetHeartRateZone.clamp(1, 2),
      neuromuscularLoad: NeuromuscularLoad.low,
    );
  }

  static List<DailyTrainingBlock> _applyDoubleSessionProtection(
    List<DailyTrainingBlock> blocks,
    TrainingInterventionResult intervention,
  ) {
    if (!intervention.blockDoubleSession) return blocks;

    if (blocks.length <= 1) return blocks;

    final heavyBlocks = blocks.where((block) {
      return block.targetLoad >= 65 ||
          block.targetHeartRateZone >= 4 ||
          block.neuromuscularLoad.index >= NeuromuscularLoad.moderate.index ||
          block.energySystem == TrainingEnergySystem.anaerobicLactic ||
          block.isSpeedStimulus;
    }).length;

    if (blocks.length == 2 && heavyBlocks < 2) {
      return blocks;
    }

    final protectedMain = _selectMostImportantBlock(blocks);

    final recoveryBlock = const DailyTrainingBlock(
      type: TrainingBlockType.recovery,
      moment: TrainingBlockMoment.evening,
      title: 'Recuperación de protección fisiológica',
      description:
          'Se eliminan sesiones accesorias para proteger recuperación fisiológica.',
      durationMinutes: 20,
      km: 0,
      targetLoad: 10,
      targetHeartRateZone: 1,
      recoveryFocused: true,
      taperFocused: false,
      aiReason:
          'Ajuste aplicado por acumulación de carga y protección del estado fisiológico.',
      stimulus: TrainingStimulus.recovery,
      energySystem: TrainingEnergySystem.none,
      neuromuscularLoad: NeuromuscularLoad.low,
      mainSet: [
        'Movilidad suave y respiración controlada.',
        'Recuperación activa muy ligera si no hay dolor.',
        'No añadir intensidad ni volumen adicional.',
      ],
      coachingNotes: [
        'La prioridad del bloque es recuperar, no compensar carga perdida.',
        'Mantener sensación fácil y controlada.',
      ],
      stopCriteria: [
        'Dolor.',
        'Fatiga creciente.',
        'Pulso elevado para una carga baja.',
      ],
    );

    return [protectedMain, recoveryBlock];
  }

  static DailyTrainingBlock _selectMostImportantBlock(
    List<DailyTrainingBlock> blocks,
  ) {
    final speed = blocks.where((b) => b.isSpeedStimulus);

    if (speed.isNotEmpty) {
      return speed.first;
    }

    final skating = blocks.where((b) => b.type == TrainingBlockType.skating);

    if (skating.isNotEmpty) {
      return skating.first;
    }

    final technical = blocks.where(
      (b) => b.type == TrainingBlockType.technical,
    );

    if (technical.isNotEmpty) {
      return technical.first;
    }

    final strength = blocks.where((b) => b.type == TrainingBlockType.strength);

    if (strength.isNotEmpty) {
      return strength.first;
    }

    return blocks.first;
  }

  static List<DailyTrainingBlock> _preservePrimaryStimulus(
    List<DailyTrainingBlock> blocks,
    IntegratedTrainingDay originalDay,
    TrainingInterventionResult intervention,
  ) {
    if (blocks.isEmpty || originalDay.blocks.isEmpty) {
      return blocks;
    }

    final originalPrimary = originalDay.blocks.first;

    final hasEquivalentStimulus = blocks.any((block) {
      if (originalPrimary.isSpeedStimulus && block.isSpeedStimulus) {
        return true;
      }

      return block.stimulus == originalPrimary.stimulus;
    });

    if (hasEquivalentStimulus) {
      return blocks;
    }

    final protectedPrimary = originalPrimary.copyWith(
      title: '${originalPrimary.title} (estímulo preservado)',
      description:
          'Se mantiene intención fisiológica principal con carga reducida.',
      durationMinutes: (originalPrimary.durationMinutes * 0.45).round().clamp(
            8,
            35,
          ),
      km: originalPrimary.km * 0.45,
      targetLoad: (originalPrimary.targetLoad * 0.45).round().clamp(5, 45),
      targetHeartRateZone: originalPrimary.targetHeartRateZone > 3
          ? 3
          : originalPrimary.targetHeartRateZone,
      recoveryFocused: false,
      aiReason:
          '${originalPrimary.aiReason}\n\nAjuste: estímulo fisiológico principal protegido.',
      neuromuscularLoad: originalPrimary.isSpeedStimulus
          ? NeuromuscularLoad.moderate
          : NeuromuscularLoad.low,
    );

    return [protectedPrimary, ...blocks.skip(1)];
  }

  static List<DailyTrainingBlock> _removeRedundantRecoveryBlocks(
    List<DailyTrainingBlock> blocks,
  ) {
    final result = <DailyTrainingBlock>[];
    var recoveryCount = 0;

    for (final block in blocks) {
      final isRecovery =
          block.recoveryFocused ||
          block.type == TrainingBlockType.recovery ||
          block.stimulus == TrainingStimulus.recovery;

      if (isRecovery) {
        recoveryCount++;

        if (recoveryCount > 2) {
          continue;
        }
      }

      result.add(block);
    }

    return result;
  }

  static List<DailyTrainingBlock> _sortBlocksByMoment(
    List<DailyTrainingBlock> blocks,
  ) {
    final sorted = [...blocks];

    sorted.sort((a, b) {
      return _momentOrder(a.moment).compareTo(_momentOrder(b.moment));
    });

    return sorted;
  }

  static int _momentOrder(TrainingBlockMoment moment) {
    switch (moment) {
      case TrainingBlockMoment.morning:
        return 0;
      case TrainingBlockMoment.afternoon:
        return 1;
      case TrainingBlockMoment.evening:
        return 2;
    }
  }
}

