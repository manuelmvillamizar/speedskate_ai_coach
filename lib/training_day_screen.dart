import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_language.dart';
import 'app_text.dart';
import 'auto_adjust_screen.dart';
import 'global_state.dart';
import 'training_history_service.dart';
import 'gym_engine.dart';
import 'progression_engine.dart';
import 'fatigue_engine.dart';
import 'periodization_engine.dart';
import 'gym_ai_selector.dart';
import 'exercise_library.dart';
import 'exercise_model.dart';
import 'exercise_detail_screen.dart';
import 'skating_workout_engine.dart';

enum DaySessionType { skates, gym, bike, mobility, recovery }

class DaySession {
  String momentEs;
  String momentEn;
  String momentDe;
  DaySessionType type;
  String titleEs;
  String titleEn;
  String titleDe;
  double km;
  int sets;
  int reps;
  double weightKg;
  int minutes;
  List<GymExercise> gymExercises;
  SkatingWorkoutSession? skatingSession;

  DaySession({
    required this.momentEs,
    required this.momentEn,
    required this.momentDe,
    required this.type,
    required this.titleEs,
    required this.titleEn,
    required this.titleDe,
    this.km = 0,
    this.sets = 0,
    this.reps = 0,
    this.weightKg = 0,
    this.minutes = 0,
    this.gymExercises = const [],
    this.skatingSession,
  });

  String moment(AppLanguage lang) =>
      AppText.t(lang, momentEs, momentEn, momentDe);

  String title(AppLanguage lang) => AppText.t(lang, titleEs, titleEn, titleDe);

  double get gymKg {
    if (type != DaySessionType.gym) return 0;

    if (gymExercises.isNotEmpty) {
      return gymExercises.fold(0, (sum, e) => sum + (e.sets * e.reps * 50));
    }

    return sets * reps * weightKg;
  }
}

class TrainingDayScreen extends StatefulWidget {
  const TrainingDayScreen({super.key});

  @override
  State<TrainingDayScreen> createState() => _TrainingDayScreenState();
}

class _TrainingDayScreenState extends State<TrainingDayScreen> {
  String athleteType = 'Velocista';
  String level = 'Competitivo';

  List<DaySession> sessions = [];
  String appliedAdjustment = '';

  double get totalSkateKm {
    return sessions
        .where((s) => s.type == DaySessionType.skates)
        .fold(0, (sum, s) => sum + s.km);
  }

  double get totalBikeKm {
    return sessions
        .where((s) => s.type == DaySessionType.bike)
        .fold(0, (sum, s) => sum + s.km);
  }

  double get totalGymKg {
    return sessions.fold(0, (sum, s) => sum + s.gymKg);
  }

  int get totalMinutes {
    return sessions.fold(0, (sum, s) => sum + s.minutes);
  }

  GymSession generateGymPro() {
    return GymEngine.generate(athleteType: athleteType, level: level);
  }

  Exercise? findExerciseData(String name) {
    final normalized = name.toLowerCase().trim();

    for (final exercise in ExerciseLibrary.exercises) {
      if (exercise.name.toLowerCase().trim() == normalized) {
        return exercise;
      }
    }

    for (final exercise in ExerciseLibrary.exercises) {
      if (normalized.contains(exercise.name.toLowerCase().trim()) ||
          exercise.name.toLowerCase().trim().contains(normalized)) {
        return exercise;
      }
    }

    return null;
  }

  void openExerciseDetail(BuildContext context, Exercise? exercise) {
    if (exercise == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseDetailScreenPro(exercise: exercise),
      ),
    );
  }

  void generateDay(AppLanguage lang, GlobalTrainingState globalState) {
    final generated =
        globalState.automaticPeriodizationEnabled &&
            globalState.currentPeriodizationDay != null
        ? generateFromPeriodizationDay(
            globalState: globalState,
            day: globalState.currentPeriodizationDay!,
          )
        : generateManualDay();

    final adjusted = applyPhysiologyAdjustment(
      lang: lang,
      globalState: globalState,
      originalSessions: generated,
    );

    setState(() {
      sessions = adjusted.sessions;
      appliedAdjustment = adjusted.message;
    });

    final fatigue = FatigueEngine.calculateStatus(
      gymLoad: totalGymKg,
      skateKm: totalSkateKm,
      minutes: totalMinutes,
    );

    if (fatigue == 'green') {
      globalState.updatePhysiology(AutoPhysiologyStatus.green);
    }
    if (fatigue == 'yellow') {
      globalState.updatePhysiology(AutoPhysiologyStatus.yellow);
    }
    if (fatigue == 'orange') {
      globalState.updatePhysiology(AutoPhysiologyStatus.orange);
    }
    if (fatigue == 'red') {
      globalState.updatePhysiology(AutoPhysiologyStatus.red);
    }

    saveToHistory(globalState);
  }

  List<DaySession> generateManualDay() {
    final isElite = level == 'Elite';
    final isNovato = level == 'Novato';
    final gymPro = generateGymPro();

    final generated = <DaySession>[];

    if (athleteType == 'Velocista') {
      if (!isNovato) {
        generated.add(
          DaySession(
            momentEs: 'Mañana',
            momentEn: 'Morning',
            momentDe: 'Morgen',
            type: DaySessionType.gym,
            titleEs: 'Gimnasio PRO velocista',
            titleEn: 'PRO sprinter gym',
            titleDe: 'PRO Sprinter-Krafttraining',
            minutes: 75,
            gymExercises: gymPro.exercises,
          ),
        );
      }

      final skatingWorkout = SkatingWorkoutEngine.generateSpeedSession(
        isNovice: isNovato,
      );

      generated.add(
        DaySession(
          momentEs: 'Tarde',
          momentEn: 'Afternoon',
          momentDe: 'Nachmittag',
          type: DaySessionType.skates,
          titleEs: skatingWorkout.nameEs,
          titleEn: skatingWorkout.nameEn,
          titleDe: skatingWorkout.nameDe,
          km: skatingWorkout.totalKm,
          minutes: skatingWorkout.totalMinutes,
          skatingSession: skatingWorkout,
        ),
      );
    }

    if (athleteType == 'Fondista') {
      final skatingWorkout = SkatingWorkoutEngine.generateEnduranceSession(
        isNovice: isNovato,
      );

      generated.add(
        DaySession(
          momentEs: 'Mañana',
          momentEn: 'Morning',
          momentDe: 'Morgen',
          type: DaySessionType.skates,
          titleEs: skatingWorkout.nameEs,
          titleEn: skatingWorkout.nameEn,
          titleDe: skatingWorkout.nameDe,
          km: skatingWorkout.totalKm,
          minutes: skatingWorkout.totalMinutes,
          skatingSession: skatingWorkout,
        ),
      );

      if (!isNovato) {
        generated.add(
          DaySession(
            momentEs: 'Tarde',
            momentEn: 'Afternoon',
            momentDe: 'Nachmittag',
            type: DaySessionType.gym,
            titleEs: 'Gimnasio PRO fondista',
            titleEn: 'PRO endurance gym',
            titleDe: 'PRO Ausdauer-Krafttraining',
            minutes: 65,
            gymExercises: gymPro.exercises,
          ),
        );
      }
    }

    if (athleteType == 'Mixto') {
      generated.add(
        DaySession(
          momentEs: 'Mañana',
          momentEn: 'Morning',
          momentDe: 'Morgen',
          type: DaySessionType.gym,
          titleEs: 'Gimnasio PRO mixto',
          titleEn: 'PRO mixed gym',
          titleDe: 'PRO gemischtes Krafttraining',
          minutes: 70,
          gymExercises: gymPro.exercises,
        ),
      );

      final skatingWorkout = SkatingWorkoutEngine.generateMixedSession(
        isNovice: isNovato,
      );

      generated.add(
        DaySession(
          momentEs: 'Tarde',
          momentEn: 'Afternoon',
          momentDe: 'Nachmittag',
          type: DaySessionType.skates,
          titleEs: skatingWorkout.nameEs,
          titleEn: skatingWorkout.nameEn,
          titleDe: skatingWorkout.nameDe,
          km: skatingWorkout.totalKm,
          minutes: skatingWorkout.totalMinutes,
          skatingSession: skatingWorkout,
        ),
      );
    }

    if (isElite) {
      generated.add(
        DaySession(
          momentEs: 'Noche',
          momentEn: 'Night',
          momentDe: 'Abend',
          type: DaySessionType.mobility,
          titleEs: 'Movilidad + recuperación guiada',
          titleEn: 'Mobility + guided recovery',
          titleDe: 'Mobilität + geführte Regeneration',
          minutes: 30,
        ),
      );
    }

    return generated;
  }

  List<DaySession> generateFromPeriodizationDay({
    required GlobalTrainingState globalState,
    required PeriodizationDay day,
  }) {
    final generated = <DaySession>[];
    final gymPro = generateGymPro();

    final aiSelection = GymAISelector.selectExercises(
      library: ExerciseLibrary.exercises,
      periodizationDay: day,
      fatigue: globalState.physiologyStatus,
      athleteType: athleteType,
      level: level,
    );

    final aiGymExercises = gymPro.exercises.where((gymExercise) {
      return aiSelection.selected.any(
        (selectedExercise) =>
            selectedExercise.name.toLowerCase() ==
            gymExercise.name.toLowerCase(),
      );
    }).toList();

    final safeGymExercises = aiGymExercises.isEmpty
        ? gymPro.exercises
        : aiGymExercises;

    if (day.type == PeriodizationDayType.speed) {
      final skatingWorkout = SkatingWorkoutEngine.generateSpeedSession(
        isNovice: level == 'Novato',
      );

      generated.add(
        DaySession(
          momentEs: 'Principal',
          momentEn: 'Main',
          momentDe: 'Hauptteil',
          type: DaySessionType.skates,
          titleEs: skatingWorkout.nameEs,
          titleEn: skatingWorkout.nameEn,
          titleDe: skatingWorkout.nameDe,
          km: skatingWorkout.totalKm,
          minutes: skatingWorkout.totalMinutes,
          skatingSession: skatingWorkout,
        ),
      );
    }

    if (day.type == PeriodizationDayType.endurance) {
      final skatingWorkout = SkatingWorkoutEngine.generateEnduranceSession(
        isNovice: level == 'Novato',
      );

      generated.add(
        DaySession(
          momentEs: 'Principal',
          momentEn: 'Main',
          momentDe: 'Hauptteil',
          type: DaySessionType.skates,
          titleEs: skatingWorkout.nameEs,
          titleEn: skatingWorkout.nameEn,
          titleDe: skatingWorkout.nameDe,
          km: skatingWorkout.totalKm,
          minutes: skatingWorkout.totalMinutes,
          skatingSession: skatingWorkout,
        ),
      );
    }

    if (day.type == PeriodizationDayType.technique) {
      final skatingWorkout = SkatingWorkoutEngine.generateRecoverySession();

      generated.add(
        DaySession(
          momentEs: 'Principal',
          momentEn: 'Main',
          momentDe: 'Hauptteil',
          type: DaySessionType.skates,
          titleEs: skatingWorkout.nameEs,
          titleEn: skatingWorkout.nameEn,
          titleDe: skatingWorkout.nameDe,
          km: skatingWorkout.totalKm,
          minutes: skatingWorkout.totalMinutes,
          skatingSession: skatingWorkout,
        ),
      );
    }

    if (day.type == PeriodizationDayType.competitionSimulation) {
      final skatingWorkout = SkatingWorkoutEngine.generateCompetitionSession(
        isNovice: level == 'Novato',
      );

      generated.add(
        DaySession(
          momentEs: 'Principal',
          momentEn: 'Main',
          momentDe: 'Hauptteil',
          type: DaySessionType.skates,
          titleEs: skatingWorkout.nameEs,
          titleEn: skatingWorkout.nameEn,
          titleDe: skatingWorkout.nameDe,
          km: skatingWorkout.totalKm,
          minutes: skatingWorkout.totalMinutes,
          skatingSession: skatingWorkout,
        ),
      );
    }

    if (day.type == PeriodizationDayType.gymStrength ||
        day.type == PeriodizationDayType.gymPower) {
      generated.add(
        DaySession(
          momentEs: 'Principal',
          momentEn: 'Main',
          momentDe: 'Hauptteil',
          type: DaySessionType.gym,
          titleEs: day.sessionEs,
          titleEn: day.sessionEn,
          titleDe: day.sessionDe,
          minutes: day.minutes,
          gymExercises: safeGymExercises,
        ),
      );
    }

    if (day.type == PeriodizationDayType.mobility) {
      generated.add(
        DaySession(
          momentEs: 'Principal',
          momentEn: 'Main',
          momentDe: 'Hauptteil',
          type: DaySessionType.mobility,
          titleEs: day.sessionEs,
          titleEn: day.sessionEn,
          titleDe: day.sessionDe,
          minutes: day.minutes,
        ),
      );
    }

    if (day.type == PeriodizationDayType.recovery) {
      final skatingWorkout = SkatingWorkoutEngine.generateRecoverySession();

      generated.add(
        DaySession(
          momentEs: 'Principal',
          momentEn: 'Main',
          momentDe: 'Hauptteil',
          type: DaySessionType.skates,
          titleEs: skatingWorkout.nameEs,
          titleEn: skatingWorkout.nameEn,
          titleDe: skatingWorkout.nameDe,
          km: skatingWorkout.totalKm,
          minutes: skatingWorkout.totalMinutes,
          skatingSession: skatingWorkout,
        ),
      );
    }

    if (level == 'Elite' &&
        day.type != PeriodizationDayType.recovery &&
        day.type != PeriodizationDayType.mobility) {
      generated.add(
        DaySession(
          momentEs: 'Noche',
          momentEn: 'Night',
          momentDe: 'Abend',
          type: DaySessionType.mobility,
          titleEs: 'Movilidad + recuperación guiada',
          titleEn: 'Mobility + guided recovery',
          titleDe: 'Mobilität + geführte Regeneration',
          minutes: 25,
        ),
      );
    }

    if (generated.isEmpty) {
      generated.add(
        DaySession(
          momentEs: 'Principal',
          momentEn: 'Main',
          momentDe: 'Hauptteil',
          type: DaySessionType.recovery,
          titleEs: 'Recuperación técnica',
          titleEn: 'Technical recovery',
          titleDe: 'Technische Regeneration',
          minutes: 30,
        ),
      );
    }

    return generated;
  }

  void saveToHistory(GlobalTrainingState globalState) {
    final history = context.read<TrainingHistoryService>();

    history.addEntry(
      TrainingHistoryEntry(
        date: DateTime.now(),
        skateKm: totalSkateKm,
        bikeKm: totalBikeKm,
        gymKg: totalGymKg,
        minutes: totalMinutes,
        physiologyStatus: globalState.physiologyStatus.name,
        adjustment: appliedAdjustment,
      ),
    );
  }

  _AdjustedDay applyPhysiologyAdjustment({
    required AppLanguage lang,
    required GlobalTrainingState globalState,
    required List<DaySession> originalSessions,
  }) {
    final status = globalState.physiologyStatus;

    if (status == AutoPhysiologyStatus.green) {
      return _AdjustedDay(
        sessions: originalSessions,
        message: AppText.t(
          lang,
          'Estado verde: se mantiene la planificación original.',
          'Green status: original plan is maintained.',
          'Grüner Status: ursprünglicher Plan wird beibehalten.',
        ),
      );
    }

    if (status == AutoPhysiologyStatus.yellow) {
      final adjusted = originalSessions.map((s) {
        return DaySession(
          momentEs: s.momentEs,
          momentEn: s.momentEn,
          momentDe: s.momentDe,
          type: s.type,
          titleEs: '${s.titleEs} - ajuste ligero',
          titleEn: '${s.titleEn} - light adjustment',
          titleDe: '${s.titleDe} - leichte Anpassung',
          km: s.km * 0.85,
          sets: s.sets,
          reps: s.reps,
          weightKg: s.weightKg * 0.9,
          minutes: (s.minutes * 0.9).round(),
          gymExercises: s.gymExercises,
          skatingSession: s.skatingSession,
        );
      }).toList();

      return _AdjustedDay(
        sessions: adjusted,
        message: AppText.t(
          lang,
          'Estado amarillo: se reduce aproximadamente 10-15% la carga.',
          'Yellow status: load is reduced by about 10-15%.',
          'Gelber Status: Belastung wird um etwa 10-15% reduziert.',
        ),
      );
    }

    if (status == AutoPhysiologyStatus.orange) {
      final adjusted = originalSessions.map((s) {
        if (s.type == DaySessionType.gym) {
          return DaySession(
            momentEs: s.momentEs,
            momentEn: s.momentEn,
            momentDe: s.momentDe,
            type: DaySessionType.mobility,
            titleEs: 'Movilidad y core suave',
            titleEn: 'Mobility and easy core',
            titleDe: 'Mobilität und leichter Core',
            minutes: 30,
          );
        }

        if (s.type == DaySessionType.skates) {
          final skatingWorkout = SkatingWorkoutEngine.generateRecoverySession();

          return DaySession(
            momentEs: s.momentEs,
            momentEn: s.momentEn,
            momentDe: s.momentDe,
            type: DaySessionType.skates,
            titleEs: skatingWorkout.nameEs,
            titleEn: skatingWorkout.nameEn,
            titleDe: skatingWorkout.nameDe,
            km: skatingWorkout.totalKm,
            minutes: skatingWorkout.totalMinutes,
            skatingSession: skatingWorkout,
          );
        }

        return s;
      }).toList();

      return _AdjustedDay(
        sessions: adjusted,
        message: AppText.t(
          lang,
          'Estado naranja: se baja volumen y se cambia fuerza pesada por recuperación/técnica.',
          'Orange status: volume is reduced and heavy strength is replaced by recovery/technique.',
          'Oranger Status: Volumen wird reduziert und schwere Kraft durch Regeneration/Technik ersetzt.',
        ),
      );
    }

    return _AdjustedDay(
      sessions: [
        DaySession(
          momentEs: 'Mañana',
          momentEn: 'Morning',
          momentDe: 'Morgen',
          type: DaySessionType.recovery,
          titleEs: 'Recuperación prioritaria',
          titleEn: 'Priority recovery',
          titleDe: 'Priorisierte Regeneration',
          minutes: 30,
        ),
        DaySession(
          momentEs: 'Tarde',
          momentEn: 'Afternoon',
          momentDe: 'Nachmittag',
          type: DaySessionType.bike,
          titleEs: 'Bicicleta muy suave opcional',
          titleEn: 'Very easy bike optional',
          titleDe: 'Sehr lockeres Rad optional',
          km: 8,
          minutes: 25,
        ),
      ],
      message: AppText.t(
        lang,
        'Estado rojo: se reemplaza el entrenamiento por recuperación. No recuperar carga perdida.',
        'Red status: training is replaced by recovery. Do not recover missed load.',
        'Roter Status: Training wird durch Regeneration ersetzt. Verpasste Belastung nicht nachholen.',
      ),
    );
  }

  String typeLabel(AppLanguage lang, DaySessionType type) {
    switch (type) {
      case DaySessionType.skates:
        return AppText.t(lang, 'Patines', 'Skating', 'Skaten');
      case DaySessionType.gym:
        return AppText.t(lang, 'Gimnasio', 'Gym', 'Krafttraining');
      case DaySessionType.bike:
        return AppText.t(lang, 'Bicicleta', 'Bike', 'Rad');
      case DaySessionType.mobility:
        return AppText.t(lang, 'Movilidad', 'Mobility', 'Mobilität');
      case DaySessionType.recovery:
        return AppText.t(lang, 'Recuperación', 'Recovery', 'Regeneration');
    }
  }

  String gymBlockLabel(GymBlockType type) {
    switch (type) {
      case GymBlockType.activation:
        return 'Activación';
      case GymBlockType.olympic:
        return 'Olímpico';
      case GymBlockType.strength:
        return 'Fuerza';
      case GymBlockType.machine:
        return 'Máquina';
      case GymBlockType.accessory:
        return 'Complementario';
      case GymBlockType.plyometric:
        return 'Potencia';
      case GymBlockType.core:
        return 'Core';
    }
  }

  IconData typeIcon(DaySessionType type) {
    switch (type) {
      case DaySessionType.skates:
        return Icons.speed;
      case DaySessionType.gym:
        return Icons.fitness_center;
      case DaySessionType.bike:
        return Icons.directions_bike;
      case DaySessionType.mobility:
        return Icons.accessibility_new;
      case DaySessionType.recovery:
        return Icons.spa;
    }
  }

  IconData skatingBlockIcon(SkatingWorkoutType type) {
    switch (type) {
      case SkatingWorkoutType.warmup:
        return Icons.local_fire_department;
      case SkatingWorkoutType.technique:
        return Icons.track_changes;
      case SkatingWorkoutType.intervals:
        return Icons.timer;
      case SkatingWorkoutType.flyingLap:
        return Icons.speed;
      case SkatingWorkoutType.starts:
        return Icons.flash_on;
      case SkatingWorkoutType.tempo:
        return Icons.trending_up;
      case SkatingWorkoutType.endurance:
        return Icons.timeline;
      case SkatingWorkoutType.raceSimulation:
        return Icons.emoji_events;
      case SkatingWorkoutType.cooldown:
        return Icons.air;
      case SkatingWorkoutType.stretching:
        return Icons.accessibility_new;
    }
  }

  Color skatingIntensityColor(SkatingIntensity intensity) {
    switch (intensity) {
      case SkatingIntensity.recovery:
        return Colors.green;
      case SkatingIntensity.easy:
        return Colors.lightGreen;
      case SkatingIntensity.moderate:
        return Colors.amber;
      case SkatingIntensity.hard:
        return Colors.deepOrange;
      case SkatingIntensity.max:
        return Colors.red;
    }
  }

  String physiologyStatusText(AppLanguage lang, AutoPhysiologyStatus status) {
    switch (status) {
      case AutoPhysiologyStatus.green:
        return AppText.t(lang, 'Verde', 'Green', 'Grün');
      case AutoPhysiologyStatus.yellow:
        return AppText.t(lang, 'Amarillo', 'Yellow', 'Gelb');
      case AutoPhysiologyStatus.orange:
        return AppText.t(lang, 'Naranja', 'Orange', 'Orange');
      case AutoPhysiologyStatus.red:
        return AppText.t(lang, 'Rojo', 'Red', 'Rot');
    }
  }

  String periodizationFocusText(AppLanguage lang, PeriodizationDay day) {
    return AppText.t(lang, day.focusEs, day.focusEn, day.focusDe);
  }

  String periodizationDayText(AppLanguage lang, PeriodizationDay day) {
    return AppText.t(lang, day.dayEs, day.dayEn, day.dayDe);
  }

  Color statusColor(AutoPhysiologyStatus status) {
    switch (status) {
      case AutoPhysiologyStatus.green:
        return Colors.green;
      case AutoPhysiologyStatus.yellow:
        return Colors.amber;
      case AutoPhysiologyStatus.orange:
        return Colors.deepOrange;
      case AutoPhysiologyStatus.red:
        return Colors.red;
    }
  }

  List<String> skatingInstructions(
    AppLanguage lang,
    SkatingWorkoutBlock block,
  ) {
    switch (lang) {
      case AppLanguage.es:
        return block.instructionsEs;
      case AppLanguage.en:
        return block.instructionsEn;
      case AppLanguage.de:
        return block.instructionsDe;
    }
  }

  String skatingBlockTitle(AppLanguage lang, SkatingWorkoutBlock block) {
    return AppText.t(lang, block.titleEs, block.titleEn, block.titleDe);
  }

  String skatingBlockDescription(AppLanguage lang, SkatingWorkoutBlock block) {
    return AppText.t(
      lang,
      block.descriptionEs,
      block.descriptionEn,
      block.descriptionDe,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageNotifier>().current;
    final globalState = context.watch<GlobalTrainingState>();
    final periodizationDay = globalState.currentPeriodizationDay;

    GymAISelectionResult? aiSelection;

    if (periodizationDay != null) {
      aiSelection = GymAISelector.selectExercises(
        library: ExerciseLibrary.exercises,
        periodizationDay: periodizationDay,
        fatigue: globalState.physiologyStatus,
        athleteType: athleteType,
        level: level,
      );
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            AppText.t(
              lang,
              'Día de entrenamiento',
              'Training day',
              'Trainingstag',
            ),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            AppText.t(
              lang,
              'Genera un día editable con patines estructurados, gimnasio PRO, periodización e IA.',
              'Generate an editable day with structured skating, PRO gym, periodization and AI.',
              'Erstelle einen bearbeitbaren Tag mit strukturiertem Skating, PRO-Krafttraining, Periodisierung und KI.',
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: statusColor(globalState.physiologyStatus).withOpacity(0.12),
            child: ListTile(
              leading: Icon(
                Icons.favorite,
                color: statusColor(globalState.physiologyStatus),
              ),
              title: Text(
                AppText.t(
                  lang,
                  'Estado fisiológico aplicado',
                  'Applied physiological status',
                  'Angewendeter physiologischer Status',
                ),
              ),
              subtitle: Text(
                physiologyStatusText(lang, globalState.physiologyStatus),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (periodizationDay != null)
            Card(
              color: Colors.indigo.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: globalState.automaticPeriodizationEnabled,
                      title: Text(
                        AppText.t(
                          lang,
                          'Usar periodización automática',
                          'Use automatic periodization',
                          'Automatische Periodisierung nutzen',
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          globalState.automaticPeriodizationEnabled = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${periodizationDay.dayNumber}. ${periodizationDayText(lang, periodizationDay)} · ${periodizationFocusText(lang, periodizationDay)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppText.t(
                        lang,
                        periodizationDay.coachNoteEs,
                        periodizationDay.coachNoteEn,
                        periodizationDay.coachNoteDe,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                globalState.currentMicrocycleDayIndex == 0
                                ? null
                                : globalState.previousMicrocycleDay,
                            icon: const Icon(Icons.arrow_back),
                            label: Text(
                              AppText.t(lang, 'Anterior', 'Previous', 'Zurück'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed:
                                globalState.currentMicrocycle == null ||
                                    globalState.currentMicrocycleDayIndex >=
                                        globalState
                                                .currentMicrocycle!
                                                .days
                                                .length -
                                            1
                                ? null
                                : globalState.nextMicrocycleDay,
                            icon: const Icon(Icons.arrow_forward),
                            label: Text(
                              AppText.t(lang, 'Siguiente', 'Next', 'Weiter'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (aiSelection != null)
            Card(
              color: Colors.purple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.psychology, color: Colors.purple),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppText.t(
                              lang,
                              'Selección IA de ejercicios',
                              'AI exercise selection',
                              'KI-�obungsauswahl',
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppText.t(
                        lang,
                        aiSelection.explanationEs,
                        aiSelection.explanationEn,
                        aiSelection.explanationDe,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 125,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: aiSelection.selected.take(8).length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final exercise = aiSelection!.selected[index];

                          return GestureDetector(
                            onTap: () => openExerciseDetail(context, exercise),
                            child: SizedBox(
                              width: 120,
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.asset(
                                      exercise.imagePath,
                                      height: 78,
                                      width: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        height: 78,
                                        width: 120,
                                        color: Colors.grey.shade200,
                                        child: const Icon(
                                          Icons.image_not_supported,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    exercise.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: athleteType,
                    decoration: InputDecoration(
                      labelText: AppText.t(
                        lang,
                        'Tipo de atleta',
                        'Athlete type',
                        'Athletentyp',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    items: ['Velocista', 'Fondista', 'Mixto']
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e == 'Velocista'
                                  ? AppText.t(
                                      lang,
                                      'Velocista',
                                      'Sprinter',
                                      'Sprinter',
                                    )
                                  : e == 'Fondista'
                                  ? AppText.t(
                                      lang,
                                      'Fondista',
                                      'Endurance skater',
                                      'Ausdauerskater',
                                    )
                                  : AppText.t(
                                      lang,
                                      'Mixto / europeo',
                                      'Mixed / European',
                                      'Gemischt / europäisch',
                                    ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => athleteType = value!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: level,
                    decoration: InputDecoration(
                      labelText: AppText.t(lang, 'Nivel', 'Level', 'Niveau'),
                      border: const OutlineInputBorder(),
                    ),
                    items: ['Novato', 'Competitivo', 'Elite']
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e == 'Novato'
                                  ? AppText.t(
                                      lang,
                                      'Novato',
                                      'Beginner',
                                      'Anfänger',
                                    )
                                  : e == 'Competitivo'
                                  ? AppText.t(
                                      lang,
                                      'Competitivo',
                                      'Competitive',
                                      'Wettkampfniveau',
                                    )
                                  : AppText.t(lang, 'Elite', 'Elite', 'Elite'),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => level = value!),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => generateDay(lang, globalState),
            icon: const Icon(Icons.auto_awesome),
            label: Text(
              globalState.automaticPeriodizationEnabled &&
                      globalState.currentPeriodizationDay != null
                  ? AppText.t(
                      lang,
                      'Generar día desde microciclo',
                      'Generate day from microcycle',
                      'Tag aus Mikrozyklus erstellen',
                    )
                  : AppText.t(
                      lang,
                      'Generar día completo',
                      'Generate full day',
                      'Kompletten Tag erstellen',
                    ),
            ),
          ),
          const SizedBox(height: 16),
          if (appliedAdjustment.isNotEmpty)
            Card(
              color: Colors.green.shade50,
              child: ListTile(
                leading: const Icon(Icons.auto_fix_high),
                title: Text(
                  AppText.t(
                    lang,
                    'Ajuste aplicado',
                    'Applied adjustment',
                    'Angewendete Anpassung',
                  ),
                ),
                subtitle: Text(appliedAdjustment),
              ),
            ),
          if (globalState.shouldBlockProgression)
            Card(
              color: Colors.red.shade50,
              child: ListTile(
                leading: const Icon(Icons.lock, color: Colors.red),
                title: Text(
                  AppText.t(
                    lang,
                    'Progresión bloqueada',
                    'Progression blocked',
                    'Progression blockiert',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  AppText.t(
                    lang,
                    'La fatiga actual no permite aumentar cargas.',
                    'Current fatigue does not allow load increases.',
                    'Die aktuelle Ermüdung erlaubt keine Belastungssteigerung.',
                  ),
                ),
              ),
            ),
          Card(
            child: ExpansionTile(
              initiallyExpanded: true,
              leading: const Icon(Icons.calculate),
              title: Text(
                AppText.t(
                  lang,
                  'Resumen del día',
                  'Daily summary',
                  'Tagesübersicht',
                ),
              ),
              childrenPadding: const EdgeInsets.all(16),
              children: [
                _SummaryRow(
                  label: AppText.t(lang, 'Patines', 'Skating', 'Skaten'),
                  value: '${totalSkateKm.toStringAsFixed(1)} km',
                ),
                _SummaryRow(
                  label: AppText.t(lang, 'Bicicleta', 'Bike', 'Rad'),
                  value: '${totalBikeKm.toStringAsFixed(1)} km',
                ),
                _SummaryRow(
                  label: AppText.t(lang, 'Gimnasio', 'Gym', 'Krafttraining'),
                  value: '${totalGymKg.toStringAsFixed(0)} kg estimados',
                ),
                _SummaryRow(
                  label: AppText.t(lang, 'Minutos', 'Minutes', 'Minuten'),
                  value: '$totalMinutes',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...sessions.map((session) {
            String subtitle =
                '${typeLabel(lang, session.type)} · ${session.minutes} min';

            if (session.type == DaySessionType.skates ||
                session.type == DaySessionType.bike) {
              subtitle += ' · ${session.km.toStringAsFixed(1)} km';
            }

            if (session.type == DaySessionType.gym) {
              subtitle += ' · ${session.gymKg.toStringAsFixed(0)} kg estimados';
            }

            return Card(
              child: ExpansionTile(
                leading: CircleAvatar(child: Icon(typeIcon(session.type))),
                title: Text('${session.moment(lang)} · ${session.title(lang)}'),
                subtitle: Text(subtitle),
                childrenPadding: const EdgeInsets.all(16),
                children: [
                  if (session.skatingSession != null)
                    ...session.skatingSession!.blocks.map((block) {
                      final color = skatingIntensityColor(block.intensity);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: color.withOpacity(0.08),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: color.withOpacity(0.18),
                                    child: Icon(
                                      skatingBlockIcon(block.type),
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      skatingBlockTitle(lang, block),
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(skatingBlockDescription(lang, block)),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Chip(
                                    avatar: const Icon(Icons.timer, size: 18),
                                    label: Text('${block.minutes} min'),
                                  ),
                                  Chip(
                                    avatar: const Icon(Icons.route, size: 18),
                                    label: Text(
                                      '${block.km.toStringAsFixed(1)} km',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ...skatingInstructions(lang, block).map(
                                (instruction) => Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('�?� '),
                                      Expanded(child: Text(instruction)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    })
                  else if (session.gymExercises.isNotEmpty)
                    ...session.gymExercises.map((exercise) {
                      final data = findExerciseData(exercise.name);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          leading: GestureDetector(
                            onTap: () => openExerciseDetail(context, data),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: data == null
                                  ? Container(
                                      width: 54,
                                      height: 54,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.fitness_center),
                                    )
                                  : Image.asset(
                                      data.imagePath,
                                      width: 54,
                                      height: 54,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 54,
                                        height: 54,
                                        color: Colors.grey.shade200,
                                        child: const Icon(
                                          Icons.image_not_supported,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          title: GestureDetector(
                            onTap: () => openExerciseDetail(context, data),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    exercise.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.open_in_new, size: 18),
                              ],
                            ),
                          ),
                          subtitle: Text(
                            '${gymBlockLabel(exercise.type)} · ${exercise.sets} x ${exercise.reps}',
                          ),
                          trailing: globalState.shouldBlockProgression
                              ? const Icon(Icons.lock, color: Colors.red)
                              : Text(
                                  '+${ProgressionEngine.nextWeight(currentWeight: 50, level: level, athleteType: athleteType).toStringAsFixed(1)} kg',
                                ),
                          childrenPadding: const EdgeInsets.all(16),
                          children: [
                            if (data != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.asset(
                                  data.imagePath,
                                  height: 190,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 190,
                                    width: double.infinity,
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      size: 60,
                                    ),
                                  ),
                                ),
                              ),
                            if (data != null) const SizedBox(height: 12),
                            if (data != null)
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton.icon(
                                  onPressed: () =>
                                      openExerciseDetail(context, data),
                                  icon: const Icon(Icons.open_in_new),
                                  label: Text(
                                    AppText.t(
                                      lang,
                                      'Ver detalle técnico',
                                      'View technical detail',
                                      'Technikdetails ansehen',
                                    ),
                                  ),
                                ),
                              ),
                            if (data != null) const SizedBox(height: 12),
                            if (data != null)
                              _SummaryRow(
                                label: AppText.t(
                                  lang,
                                  'Músculos',
                                  'Muscles',
                                  'Muskeln',
                                ),
                                value: data.muscles,
                              ),
                            if (data != null)
                              _SummaryRow(
                                label: AppText.t(
                                  lang,
                                  'Nivel',
                                  'Level',
                                  'Niveau',
                                ),
                                value: data.level,
                              ),
                            if (data != null)
                              _SummaryRow(
                                label: AppText.t(
                                  lang,
                                  'Equipo',
                                  'Equipment',
                                  'Ausrüstung',
                                ),
                                value: data.equipment,
                              ),
                            if (data != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  AppText.t(
                                    lang,
                                    data.descriptionEs,
                                    data.descriptionEn,
                                    data.descriptionDe,
                                  ),
                                ),
                              ),
                            if (data == null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  AppText.t(
                                    lang,
                                    'No hay imagen asociada todavía para este ejercicio.',
                                    'No image associated with this exercise yet.',
                                    'Für diese �obung ist noch kein Bild hinterlegt.',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    })
                  else
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        session.type == DaySessionType.skates ||
                                session.type == DaySessionType.bike
                            ? '${session.km.toStringAsFixed(1)} km · ${session.minutes} min'
                            : '${session.minutes} min',
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AdjustedDay {
  final List<DaySession> sessions;
  final String message;

  _AdjustedDay({required this.sessions, required this.message});
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}


