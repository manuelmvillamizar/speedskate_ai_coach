import '../../training_library/master_training_library.dart';
import '../../training_library/training_library_models.dart';
import '../constraints/session_constraints_engine.dart';
import '../priority/session_priority_engine.dart';

class WeeklyMicrocycleDay {
  final int dayIndex;
  final String label;
  final List<TrainingSessionTemplate> sessions;
  final List<String> notes;

  const WeeklyMicrocycleDay({
    required this.dayIndex,
    required this.label,
    required this.sessions,
    required this.notes,
  });
}

class WeeklyMicrocyclePlan {
  final List<WeeklyMicrocycleDay> days;
  final List<String> globalNotes;

  const WeeklyMicrocyclePlan({required this.days, required this.globalNotes});
}

class WeeklyMicrocycleBuilder {
  static WeeklyMicrocyclePlan build({
    required TrainingLibraryModality modality,
    required double readiness,
    required double acwr,
    required bool taperPhase,
    int trainingDays = 6,
    List<String> recentSessionIds = const [],
  }) {
    final days = <WeeklyMicrocycleDay>[];
    final globalNotes = <String>[];
    final usedThisWeekIds = <String>{};

    final weeklyPattern = _patternFor(
      modality: modality,
      readiness: readiness,
      acwr: acwr,
      taperPhase: taperPhase,
      trainingDays: trainingDays.clamp(3, 7),
    );

    for (int i = 0; i < 7; i++) {
      final target = weeklyPattern[i];

      final previousDaySessions = i == 0
          ? <TrainingSessionTemplate>[]
          : days[i - 1].sessions;

      final selected = <TrainingSessionTemplate>[];
      final notes = <String>[];

      if (target.recoveryOnly) {
        selected.addAll(
          _bestRecoveryStack(
            modality: modality,
            readiness: readiness,
            acwr: acwr,
            taperPhase: taperPhase,
            recentSessionIds: recentSessionIds,
            usedThisWeekIds: usedThisWeekIds,
          ),
        );

        days.add(
          WeeklyMicrocycleDay(
            dayIndex: i,
            label: target.label,
            sessions: selected,
            notes: const [],
          ),
        );

        continue;
      }

      for (final slot in target.slots) {
        final candidates = _candidatesForSlot(slot: slot, modality: modality);

        final allowedCandidates = candidates.where((session) {
          final result = SessionConstraintsEngine.canPlaceSession(
            candidate: session,
            sameDaySessions: selected,
            previousDaySessions: previousDaySessions,
            readiness: readiness,
            acwr: acwr,
            taperPhase: taperPhase,
          );

          return result.allowed;
        }).toList();

        if (allowedCandidates.isEmpty) continue;

        final rotatedCandidates = _rotateCandidates(
          candidates: allowedCandidates,
          recentSessionIds: recentSessionIds,
          usedThisWeekIds: usedThisWeekIds,
        );

        final best = SessionPriorityEngine.bestSession(
          candidates: rotatedCandidates,
          targetModality: modality,
          readiness: readiness,
          acwr: acwr,
          taperPhase: taperPhase,
          needsNeuralStimulus: slot.neural,
          needsMetabolicStimulus: slot.metabolic,
          protectReactiveLoad: slot.protectReactive,
        );

        if (best != null && !_alreadySelected(selected, best.session)) {
          selected.add(best.session);
          usedThisWeekIds.add(best.session.id);
          notes.addAll(best.reasons);
        }
      }

      if (selected.isEmpty) {
        selected.addAll(
          _bestRecoveryStack(
            modality: modality,
            readiness: readiness,
            acwr: acwr,
            taperPhase: taperPhase,
            recentSessionIds: recentSessionIds,
            usedThisWeekIds: usedThisWeekIds,
          ),
        );
      }

      days.add(
        WeeklyMicrocycleDay(
          dayIndex: i,
          label: target.label,
          sessions: selected,
          notes: notes,
        ),
      );
    }

    if (readiness < 0.45) {
      globalNotes.add('Readiness bajo: semana protegida con más recuperación.');
    }

    if (acwr > 1.45) {
      globalNotes.add('ACWR alto: se limita la acumulación de intensidad.');
    }

    if (taperPhase) {
      globalNotes.add(
        'Taper activo: baja fatiga residual, alta calidad técnica.',
      );
    }

    return WeeklyMicrocyclePlan(days: days, globalNotes: globalNotes);
  }

  static bool _alreadySelected(
    List<TrainingSessionTemplate> selected,
    TrainingSessionTemplate session,
  ) {
    return selected.any((item) => item.id == session.id);
  }

  static List<TrainingSessionTemplate> _rotateCandidates({
    required List<TrainingSessionTemplate> candidates,
    required List<String> recentSessionIds,
    required Set<String> usedThisWeekIds,
  }) {
    final fresh = candidates.where((session) {
      return !usedThisWeekIds.contains(session.id) &&
          !recentSessionIds.contains(session.id);
    }).toList();

    if (fresh.isNotEmpty) return fresh;

    final notUsedThisWeek = candidates.where((session) {
      return !usedThisWeekIds.contains(session.id);
    }).toList();

    if (notUsedThisWeek.isNotEmpty) return notUsedThisWeek;

    return candidates;
  }

  static List<TrainingSessionTemplate> _candidatesForSlot({
    required _SessionSlot slot,
    required TrainingLibraryModality modality,
  }) {
    final byCategoryAndModality = MasterTrainingLibrary.allSessions.where((
      session,
    ) {
      if (!slot.categories.contains(session.category)) return false;
      if (!session.matchesModality(modality)) return false;
      return true;
    }).toList();

    if (byCategoryAndModality.isNotEmpty) {
      return _sortByWorkDensity(byCategoryAndModality);
    }

    final byCategory = MasterTrainingLibrary.allSessions.where((session) {
      return slot.categories.contains(session.category);
    }).toList();

    return _sortByWorkDensity(byCategory);
  }

  static List<TrainingSessionTemplate> _sortByWorkDensity(
    List<TrainingSessionTemplate> sessions,
  ) {
    final sorted = List<TrainingSessionTemplate>.from(sessions);

    sorted.sort((a, b) {
      final scoreA = _workDensityScore(a);
      final scoreB = _workDensityScore(b);
      return scoreB.compareTo(scoreA);
    });

    return sorted;
  }

  static int _workDensityScore(TrainingSessionTemplate session) {
    var score = 0;

    score += session.mainSet.length * 12;
    score += session.warmup.length * 2;
    score += session.complementary.length * 5;

    if (session.skatingSession) score += 20;
    if (session.cyclingSession) score += 18;
    if (session.gymSession) score += 14;
    if (session.recoverySession) score += 2;

    switch (session.category) {
      case TrainingLibraryCategory.endurance:
        score += 30;
        break;
      case TrainingLibraryCategory.tempo:
        score += 30;
        break;
      case TrainingLibraryCategory.lactate:
        score += 28;
        break;
      case TrainingLibraryCategory.maxVelocity:
        score += 28;
        break;
      case TrainingLibraryCategory.speed:
        score += 26;
        break;
      case TrainingLibraryCategory.acceleration:
        score += 24;
        break;
      case TrainingLibraryCategory.tactical:
        score += 24;
        break;
      case TrainingLibraryCategory.plyometric:
        score += 24;
        break;
      case TrainingLibraryCategory.power:
        score += 24;
        break;
      case TrainingLibraryCategory.cycling:
        score += 22;
        break;
      case TrainingLibraryCategory.strength:
        score += 18;
        break;
      case TrainingLibraryCategory.core:
        score += 8;
        break;
      case TrainingLibraryCategory.technical:
        score += 2;
        break;
      case TrainingLibraryCategory.mobility:
        score -= 4;
        break;
      case TrainingLibraryCategory.recovery:
        score -= 6;
        break;
      case TrainingLibraryCategory.test:
        score += 14;
        break;
      case TrainingLibraryCategory.prehab:
        score += 4;
        break;
    }

    switch (session.intensity) {
      case TrainingSessionIntensity.recovery:
        score -= 8;
        break;
      case TrainingSessionIntensity.low:
        score += 2;
        break;
      case TrainingSessionIntensity.moderate:
        score += 10;
        break;
      case TrainingSessionIntensity.high:
        score += 18;
        break;
      case TrainingSessionIntensity.maximal:
        score += 22;
        break;
    }

    return score;
  }

  static List<TrainingSessionTemplate> _bestRecoveryStack({
    required TrainingLibraryModality modality,
    required double readiness,
    required double acwr,
    required bool taperPhase,
    required List<String> recentSessionIds,
    required Set<String> usedThisWeekIds,
  }) {
    final cyclingCandidates = _rotateCandidates(
      candidates: _sortByWorkDensity(
        MasterTrainingLibrary.allSessions
            .where((session) => session.cyclingSession)
            .toList(),
      ),
      recentSessionIds: recentSessionIds,
      usedThisWeekIds: usedThisWeekIds,
    );

    final recoveryCandidates = _rotateCandidates(
      candidates: _sortByWorkDensity(
        MasterTrainingLibrary.allSessions
            .where((session) => session.recoverySession)
            .toList(),
      ),
      recentSessionIds: recentSessionIds,
      usedThisWeekIds: usedThisWeekIds,
    );

    final selected = <TrainingSessionTemplate>[];

    final cycling = SessionPriorityEngine.bestSession(
      candidates: cyclingCandidates,
      targetModality: modality,
      readiness: readiness,
      acwr: acwr,
      taperPhase: taperPhase,
      needsNeuralStimulus: false,
      needsMetabolicStimulus: false,
      protectReactiveLoad: true,
    );

    if (cycling != null) {
      selected.add(cycling.session);
      usedThisWeekIds.add(cycling.session.id);
    }

    final recovery = SessionPriorityEngine.bestSession(
      candidates: recoveryCandidates,
      targetModality: modality,
      readiness: readiness,
      acwr: acwr,
      taperPhase: taperPhase,
      needsNeuralStimulus: false,
      needsMetabolicStimulus: false,
      protectReactiveLoad: true,
    );

    if (recovery != null && !_alreadySelected(selected, recovery.session)) {
      selected.add(recovery.session);
      usedThisWeekIds.add(recovery.session.id);
    }

    return selected;
  }

  static List<_DayTarget> _patternFor({
    required TrainingLibraryModality modality,
    required double readiness,
    required double acwr,
    required bool taperPhase,
    required int trainingDays,
  }) {
    if (readiness < 0.45 || acwr > 1.55) {
      return const [
        _DayTarget.recovery('Día 1 - Bici recovery + descarga'),
        _DayTarget.lowTechnical('Día 2 - Técnica suave + core + movilidad'),
        _DayTarget.recovery('Día 3 - Bici recovery + movilidad'),
        _DayTarget.aerobicSupport('Día 4 - Aeróbico suave + bici'),
        _DayTarget.recovery('Día 5 - Recovery profundo'),
        _DayTarget.lowTechnical('Día 6 - Técnica controlada + movilidad'),
        _DayTarget.recovery('Día 7 - Descarga total'),
      ];
    }

    if (taperPhase) {
      return const [
        _DayTarget.taperSpeed('Día 1 - Velocidad corta + técnica'),
        _DayTarget.taperStrength('Día 2 - Fuerza ligera + bici'),
        _DayTarget.recovery('Día 3 - Recovery + bici'),
        _DayTarget.taperRacePrep('Día 4 - Ritmo carrera + activación'),
        _DayTarget.recovery('Día 5 - Descarga + movilidad'),
        _DayTarget.taperActivation('Día 6 - Activación precompetencia'),
        _DayTarget.recovery('Día 7 - Recovery / competencia'),
      ];
    }

    switch (modality) {
      case TrainingLibraryModality.sprinter:
        return const [
          _DayTarget.sprinterMaxSpeedPlyo(
            'Día 1 - Máxima velocidad + pliometría',
          ),
          _DayTarget.sprinterStrengthSpeed('Día 2 - Fuerza pesada + salidas'),
          _DayTarget.aerobicRecovery(
            'Día 3 - Bici recovery + movilidad + core',
          ),
          _DayTarget.sprinterLactatePower('Día 4 - Lactato + potencia'),
          _DayTarget.sprinterFlyingSprintPlyo(
            'Día 5 - Sprints lanzados + pliometría',
          ),
          _DayTarget.sprinterRaceSimulation(
            'Día 6 - Simulación competitiva + velocidad',
          ),
          _DayTarget.recovery('Día 7 - Bici suave + recovery profundo'),
        ];

      case TrainingLibraryModality.endurance:
        return const [
          _DayTarget.enduranceLongTempoStrength('Día 1 - Tempo largo + fuerza'),
          _DayTarget.enduranceVolumeCycling(
            'Día 2 - Fondo real + bici aeróbica',
          ),
          _DayTarget.aerobicRecovery(
            'Día 3 - Bici recovery + movilidad + core',
          ),
          _DayTarget.enduranceTacticalTempo('Día 4 - Táctico grupo + tempo'),
          _DayTarget.enduranceLongSupport(
            'Día 5 - Fondo largo + soporte aeróbico',
          ),
          _DayTarget.enduranceSprintFinish('Día 6 - Sprints lanzados + remate'),
          _DayTarget.recovery('Día 7 - Bici suave + recovery profundo'),
        ];

      case TrainingLibraryModality.mixed:
        return const [
          _DayTarget.mixedSpeedStrength('Día 1 - Velocidad + fuerza'),
          _DayTarget.mixedTempoTechnical('Día 2 - Tempo + técnica'),
          _DayTarget.aerobicRecovery('Día 3 - Bici recovery + movilidad'),
          _DayTarget.mixedPowerSkate('Día 4 - Potencia + patines'),
          _DayTarget.mixedTactical('Día 5 - Táctico / simulación'),
          _DayTarget.aerobicSupport('Día 6 - Aeróbico + bici + movilidad'),
          _DayTarget.recovery('Día 7 - Recovery profundo'),
        ];

      case TrainingLibraryModality.universal:
        return const [
          _DayTarget.mixedSpeedStrength('Día 1 - Velocidad + fuerza'),
          _DayTarget.mixedTempoTechnical('Día 2 - Tempo + técnica'),
          _DayTarget.aerobicRecovery('Día 3 - Bici recovery + movilidad'),
          _DayTarget.mixedPowerSkate('Día 4 - Potencia + patines'),
          _DayTarget.aerobicSupport('Día 5 - Aeróbico + bici + movilidad'),
          _DayTarget.lowTechnical('Día 6 - Técnica + core'),
          _DayTarget.recovery('Día 7 - Recovery profundo'),
        ];
    }
  }
}

class _DayTarget {
  final String label;
  final List<_SessionSlot> slots;
  final bool recoveryOnly;

  const _DayTarget({
    required this.label,
    required this.slots,
    required this.recoveryOnly,
  });

  const _DayTarget.recovery(String label)
    : this(
        label: label,
        recoveryOnly: true,
        slots: const [_SessionSlot.recoveryCycling(), _SessionSlot.recovery()],
      );

  const _DayTarget.lowTechnical(String label)
    : this(
        label: label,
        recoveryOnly: false,
        slots: const [
          _SessionSlot.technicalLow(),
          _SessionSlot.core(),
          _SessionSlot.recoveryCycling(),
          _SessionSlot.recovery(),
        ],
      );

  const _DayTarget.aerobicSupport(String label)
    : this(
        label: label,
        recoveryOnly: false,
        slots: const [
          _SessionSlot.enduranceQuality(),
          _SessionSlot.cycling(),
          _SessionSlot.recovery(),
        ],
      );

  const _DayTarget.aerobicRecovery(String label)
    : this(
        label: label,
        recoveryOnly: false,
        slots: const [
          _SessionSlot.recoveryCycling(),
          _SessionSlot.core(),
          _SessionSlot.recovery(),
        ],
      );

  const _DayTarget.sprinterMaxSpeedPlyo(String label)
    : this(
        label: label,
        recoveryOnly: false,
        slots: const [
          _SessionSlot.maxVelocity(),
          _SessionSlot.speed(),
          _SessionSlot.plyometricAggressive(),
          _SessionSlot.power(),
          _SessionSlot.recovery(),
        ],
      );

  const _DayTarget.sprinterStrengthSpeed(String label)
    : this(
        label: label,
        recoveryOnly: false,
        slots: const [
          _SessionSlot.strengthAggressive(),
          _SessionSlot.acceleration(),
          _SessionSlot.speed(),
          _SessionSlot.recovery(),
        ],
      );

  const _DayTarget.sprinterLactatePower(String label)
    : this(
        label: label,
        recoveryOnly: false,
        slots: const [
          _SessionSlot.lactate(),
          _SessionSlot.power(),
          _SessionSlot.core(),
          _SessionSlot.recoveryCycling(),
          _SessionSlot.recovery(),
        ],
      );

  const _DayTarget.sprinterFlyingSprintPlyo(String label)
    : this(
        label: label,
        recoveryOnly: false,
        slots: const [
          _SessionSlot.maxVelocity(),
          _SessionSlot.speed(),
          _SessionSlot.plyometricAggressive(),
          _SessionSlot.recovery(),
        ],
      );

  const _DayTarget.sprinterRaceSimulation(String label)
    : this(
        label: label,
        recoveryOnly: false,
        slots: const [
          _SessionSlot.tactical(),
          _SessionSlot.lactate(),
          _SessionSlot.speed(),
          _SessionSlot.recovery(),
        ],
      );

  const _DayTarget.enduranceLongTempoStrength(String label)
    : this(
        label: label,
        recoveryOnly: false,
        slots: const [
          _SessionSlot.tempoAggressive(),
          _SessionSlot.enduranceQuality(),
          _SessionSlot.strength(),
          _SessionSlot.recovery(),
        ],
      );

  const _DayTarget.enduranceVolumeCycling(String label)
    : this(
        label: label,
        recoveryOnly: false,
        slots: const [
          _SessionSlot.enduranceQuality(),
          _SessionSlot.cycling(),
          _SessionSlot.technicalLow(),
          _SessionSlot.recovery(),
        ],
      );

  const _DayTarget.enduranceTacticalTempo(String label)
    : this(
        label: label,
        recoveryOnly: false,
        slots: const [
          _SessionSlot.tactical(),
          _SessionSlot.tempoAggressive(),
          _SessionSlot.core(),
          _SessionSlot.recovery(),
        ],
      );

  const _DayTarget.enduranceLongSupport(String label)
    : this(
        label: label,
        recoveryOnly: false,
        slots: const [
          _SessionSlot.enduranceQuality(),
          _SessionSlot.enduranceQuality(),
          _SessionSlot.cycling(),
          _SessionSlot.recovery(),
        ],
      );

  const _DayTarget.enduranceSprintFinish(String label)
    : this(
        label: label,
        recoveryOnly: false,
        slots: const [
          _SessionSlot.maxVelocity(),
          _SessionSlot.speed(),
          _SessionSlot.tempoAggressive(),
          _SessionSlot.recoveryCycling(),
          _SessionSlot.recovery(),
        ],
      );

  const _DayTarget.mixedSpeedStrength(String label)
    : this(
        label: label,
        recoveryOnly: false,
        slots: const [
          _SessionSlot.speed(),
          _SessionSlot.strength(),
          _SessionSlot.plyometricAggressive(),
          _SessionSlot.recovery(),
        ],
      );

  const _DayTarget.mixedTempoTechnical(String label)
    : this(
        label: label,
        recoveryOnly: false,
        slots: const [
          _SessionSlot.tempoAggressive(),
          _SessionSlot.technicalLow(),
          _SessionSlot.recovery(),
        ],
      );

  const _DayTarget.mixedPowerSkate(String label)
    : this(
        label: label,
        recoveryOnly: false,
        slots: const [
          _SessionSlot.power(),
          _SessionSlot.speed(),
          _SessionSlot.recovery(),
        ],
      );

  const _DayTarget.mixedTactical(String label)
    : this(
        label: label,
        recoveryOnly: false,
        slots: const [
          _SessionSlot.tactical(),
          _SessionSlot.lactate(),
          _SessionSlot.recovery(),
        ],
      );

  const _DayTarget.taperSpeed(String label)
    : this(
        label: label,
        recoveryOnly: false,
        slots: const [
          _SessionSlot.speed(),
          _SessionSlot.maxVelocity(),
          _SessionSlot.technicalLow(),
          _SessionSlot.recovery(),
        ],
      );

  const _DayTarget.taperStrength(String label)
    : this(
        label: label,
        recoveryOnly: false,
        slots: const [
          _SessionSlot.strengthLight(),
          _SessionSlot.recoveryCycling(),
          _SessionSlot.recovery(),
        ],
      );

  const _DayTarget.taperRacePrep(String label)
    : this(
        label: label,
        recoveryOnly: false,
        slots: const [
          _SessionSlot.tactical(),
          _SessionSlot.speed(),
          _SessionSlot.recovery(),
        ],
      );

  const _DayTarget.taperActivation(String label)
    : this(
        label: label,
        recoveryOnly: false,
        slots: const [_SessionSlot.speed(), _SessionSlot.recovery()],
      );
}

class _SessionSlot {
  final List<TrainingLibraryCategory> categories;
  final bool neural;
  final bool metabolic;
  final bool protectReactive;

  const _SessionSlot({
    required this.categories,
    required this.neural,
    required this.metabolic,
    required this.protectReactive,
  });

  const _SessionSlot.speed()
    : this(
        categories: const [
          TrainingLibraryCategory.speed,
          TrainingLibraryCategory.acceleration,
          TrainingLibraryCategory.maxVelocity,
        ],
        neural: true,
        metabolic: false,
        protectReactive: false,
      );

  const _SessionSlot.acceleration()
    : this(
        categories: const [
          TrainingLibraryCategory.acceleration,
          TrainingLibraryCategory.speed,
        ],
        neural: true,
        metabolic: false,
        protectReactive: false,
      );

  const _SessionSlot.maxVelocity()
    : this(
        categories: const [
          TrainingLibraryCategory.maxVelocity,
          TrainingLibraryCategory.speed,
          TrainingLibraryCategory.acceleration,
        ],
        neural: true,
        metabolic: false,
        protectReactive: false,
      );

  const _SessionSlot.lactate()
    : this(
        categories: const [TrainingLibraryCategory.lactate],
        neural: true,
        metabolic: true,
        protectReactive: false,
      );

  const _SessionSlot.tempoAggressive()
    : this(
        categories: const [
          TrainingLibraryCategory.tempo,
          TrainingLibraryCategory.endurance,
        ],
        neural: false,
        metabolic: true,
        protectReactive: false,
      );

  const _SessionSlot.enduranceQuality()
    : this(
        categories: const [
          TrainingLibraryCategory.endurance,
          TrainingLibraryCategory.tempo,
        ],
        neural: false,
        metabolic: true,
        protectReactive: false,
      );

  const _SessionSlot.tactical()
    : this(
        categories: const [
          TrainingLibraryCategory.tactical,
          TrainingLibraryCategory.endurance,
          TrainingLibraryCategory.tempo,
        ],
        neural: true,
        metabolic: true,
        protectReactive: false,
      );

  const _SessionSlot.strength()
    : this(
        categories: const [
          TrainingLibraryCategory.strength,
          TrainingLibraryCategory.prehab,
        ],
        neural: true,
        metabolic: false,
        protectReactive: true,
      );

  const _SessionSlot.strengthAggressive()
    : this(
        categories: const [
          TrainingLibraryCategory.strength,
          TrainingLibraryCategory.power,
          TrainingLibraryCategory.prehab,
        ],
        neural: true,
        metabolic: false,
        protectReactive: false,
      );

  const _SessionSlot.strengthLight()
    : this(
        categories: const [
          TrainingLibraryCategory.strength,
          TrainingLibraryCategory.prehab,
        ],
        neural: false,
        metabolic: false,
        protectReactive: true,
      );

  const _SessionSlot.power()
    : this(
        categories: const [
          TrainingLibraryCategory.power,
          TrainingLibraryCategory.plyometric,
        ],
        neural: true,
        metabolic: false,
        protectReactive: false,
      );

  const _SessionSlot.plyometricAggressive()
    : this(
        categories: const [
          TrainingLibraryCategory.plyometric,
          TrainingLibraryCategory.power,
        ],
        neural: true,
        metabolic: false,
        protectReactive: false,
      );

  const _SessionSlot.technicalLow()
    : this(
        categories: const [
          TrainingLibraryCategory.technical,
          TrainingLibraryCategory.mobility,
        ],
        neural: false,
        metabolic: false,
        protectReactive: true,
      );

  const _SessionSlot.core()
    : this(
        categories: const [TrainingLibraryCategory.core],
        neural: false,
        metabolic: false,
        protectReactive: true,
      );

  const _SessionSlot.cycling()
    : this(
        categories: const [TrainingLibraryCategory.cycling],
        neural: false,
        metabolic: true,
        protectReactive: true,
      );

  const _SessionSlot.recoveryCycling()
    : this(
        categories: const [TrainingLibraryCategory.cycling],
        neural: false,
        metabolic: false,
        protectReactive: true,
      );

  const _SessionSlot.recovery()
    : this(
        categories: const [
          TrainingLibraryCategory.recovery,
          TrainingLibraryCategory.mobility,
        ],
        neural: false,
        metabolic: false,
        protectReactive: true,
      );
}


