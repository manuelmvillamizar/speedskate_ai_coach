import 'dart:math';

import 'auto_adjust_screen.dart';
import 'exercise_model.dart';
import 'periodization_engine.dart';

class GymAISelectionResult {
  final List<Exercise> selected;
  final List<Exercise> blocked;

  final String explanationEs;
  final String explanationEn;
  final String explanationDe;

  const GymAISelectionResult({
    required this.selected,
    required this.blocked,
    required this.explanationEs,
    required this.explanationEn,
    required this.explanationDe,
  });
}

class GymAISelector {
  static GymAISelectionResult selectExercises({
    required List<Exercise> library,
    required PeriodizationDay periodizationDay,
    required AutoPhysiologyStatus fatigue,
    required String athleteType,
    required String level,
  }) {
    final selected = <Exercise>[];
    final blocked = <Exercise>[];

    for (final exercise in library) {
      final score = _scoreExercise(
        exercise: exercise,
        day: periodizationDay,
        fatigue: fatigue,
        athleteType: athleteType,
        level: level,
      );

      if (score >= 55) {
        selected.add(exercise);
      } else {
        blocked.add(exercise);
      }
    }

    selected.sort(
      (a, b) =>
          _scoreExercise(
            exercise: b,
            day: periodizationDay,
            fatigue: fatigue,
            athleteType: athleteType,
            level: level,
          ).compareTo(
            _scoreExercise(
              exercise: a,
              day: periodizationDay,
              fatigue: fatigue,
              athleteType: athleteType,
              level: level,
            ),
          ),
    );

    return GymAISelectionResult(
      selected: _limitBySessionType(selected, periodizationDay.type),
      blocked: blocked,
      explanationEs: _explanationEs(fatigue, periodizationDay),
      explanationEn: _explanationEn(fatigue, periodizationDay),
      explanationDe: _explanationDe(fatigue, periodizationDay),
    );
  }

  static int _scoreExercise({
    required Exercise exercise,
    required PeriodizationDay day,
    required AutoPhysiologyStatus fatigue,
    required String athleteType,
    required String level,
  }) {
    int score = 50;

    final name = exercise.name.toLowerCase();
    final category = exercise.category;

    if (fatigue == AutoPhysiologyStatus.red) {
      if (_isHeavy(name)) score -= 80;
      if (_isOlympic(name, category)) score -= 70;
      if (_isMobility(name, category)) score += 60;
      if (_isCore(name, category)) score += 25;
    }

    if (fatigue == AutoPhysiologyStatus.orange) {
      if (_isHeavy(name)) score -= 50;
      if (_isPlyometric(name, category)) score -= 35;
      if (_isMobility(name, category)) score += 40;
      if (_isCore(name, category)) score += 20;
    }

    if (fatigue == AutoPhysiologyStatus.yellow) {
      if (_isHeavy(name)) score -= 20;
      if (_isExplosive(name, category)) score += 8;
      if (_isCore(name, category)) score += 10;
    }

    if (fatigue == AutoPhysiologyStatus.green) {
      if (_isOlympic(name, category)) score += 18;
      if (_isExplosive(name, category)) score += 12;
      if (_isHeavy(name)) score += 10;
    }

    switch (day.type) {
      case PeriodizationDayType.gymStrength:
        if (_isHeavy(name)) score += 35;
        if (_isOlympic(name, category)) score += 15;
        if (_isCore(name, category)) score += 10;
        break;

      case PeriodizationDayType.gymPower:
        if (_isOlympic(name, category)) score += 40;
        if (_isExplosive(name, category)) score += 30;
        if (_isHeavy(name)) score -= 10;
        break;

      case PeriodizationDayType.speed:
        if (_isExplosive(name, category)) score += 25;
        if (_isOlympic(name, category)) score += 15;
        if (_isHeavy(name)) score -= 10;
        break;

      case PeriodizationDayType.endurance:
        if (_isUnilateral(name)) score += 20;
        if (_isMachine(name, category)) score += 15;
        if (_isCore(name, category)) score += 15;
        break;

      case PeriodizationDayType.technique:
        if (_isCore(name, category)) score += 20;
        if (_isMobility(name, category)) score += 20;
        if (_isHeavy(name)) score -= 20;
        break;

      case PeriodizationDayType.mobility:
        if (_isMobility(name, category)) score += 70;
        if (_isCore(name, category)) score += 20;
        if (_isHeavy(name)) score -= 60;
        break;

      case PeriodizationDayType.recovery:
        if (_isMobility(name, category)) score += 60;
        if (_isCore(name, category)) score += 15;
        if (_isHeavy(name)) score -= 100;
        if (_isOlympic(name, category)) score -= 90;
        break;

      case PeriodizationDayType.competitionSimulation:
        if (_isExplosive(name, category)) score += 25;
        if (_isOlympic(name, category)) score += 15;
        if (_isHeavy(name)) score -= 35;
        break;
    }

    if (athleteType == 'Velocista') {
      if (_isOlympic(name, category)) score += 20;
      if (_isExplosive(name, category)) score += 20;
    }

    if (athleteType == 'Fondista') {
      if (_isUnilateral(name)) score += 20;
      if (_isCore(name, category)) score += 15;
      if (_isMachine(name, category)) score += 10;
    }

    if (athleteType == 'Mixto') {
      score += 5;
    }

    if (level == 'Elite') {
      if (_isOlympic(name, category)) score += 15;
      if (_isExplosive(name, category)) score += 10;
    }

    if (level == 'Novato') {
      if (_isOlympic(name, category)) score -= 25;
      if (_isMachine(name, category)) score += 20;
      if (_isMobility(name, category)) score += 15;
    }

    return max(0, min(100, score));
  }

  static List<Exercise> _limitBySessionType(
    List<Exercise> list,
    PeriodizationDayType type,
  ) {
    int limit = 6;

    switch (type) {
      case PeriodizationDayType.gymStrength:
        limit = 7;
        break;
      case PeriodizationDayType.gymPower:
        limit = 5;
        break;
      case PeriodizationDayType.recovery:
      case PeriodizationDayType.mobility:
        limit = 4;
        break;
      default:
        limit = 6;
    }

    return list.take(limit).toList();
  }

  static bool _isOlympic(String name, ExerciseCategory category) {
    return category == ExerciseCategory.olympic ||
        name.contains('clean') ||
        name.contains('snatch') ||
        name.contains('jerk');
  }

  static bool _isHeavy(String name) {
    return name.contains('squat') ||
        name.contains('deadlift') ||
        name.contains('hip thrust') ||
        name.contains('press');
  }

  static bool _isExplosive(String name, ExerciseCategory category) {
    return category == ExerciseCategory.plyometric ||
        category == ExerciseCategory.olympic ||
        name.contains('jump') ||
        name.contains('bound') ||
        name.contains('plyo') ||
        name.contains('clean');
  }

  static bool _isPlyometric(String name, ExerciseCategory category) {
    return category == ExerciseCategory.plyometric ||
        name.contains('jump') ||
        name.contains('plyo');
  }

  static bool _isMobility(String name, ExerciseCategory category) {
    return category == ExerciseCategory.mobility ||
        name.contains('mobility') ||
        name.contains('movilidad') ||
        name.contains('stretch') ||
        name.contains('recovery');
  }

  static bool _isMachine(String name, ExerciseCategory category) {
    return category == ExerciseCategory.machine ||
        name.contains('machine') ||
        name.contains('máquina') ||
        name.contains('press');
  }

  static bool _isUnilateral(String name) {
    return name.contains('split') ||
        name.contains('single') ||
        name.contains('step');
  }

  static bool _isCore(String name, ExerciseCategory category) {
    return category == ExerciseCategory.core ||
        name.contains('core') ||
        name.contains('plank') ||
        name.contains('anti-rot');
  }

  static String _explanationEs(
    AutoPhysiologyStatus fatigue,
    PeriodizationDay day,
  ) {
    if (fatigue == AutoPhysiologyStatus.red) {
      return 'La IA priorizó movilidad, core suave y recuperación por fatiga alta.';
    }

    if (fatigue == AutoPhysiologyStatus.orange) {
      return 'La IA redujo fuerza pesada, pliometría agresiva y volumen por fatiga acumulada.';
    }

    if (day.type == PeriodizationDayType.gymPower) {
      return 'La IA priorizó ejercicios explosivos, olímpicos y transferencia directa al patinaje.';
    }

    if (day.type == PeriodizationDayType.gymStrength) {
      return 'La IA priorizó fuerza máxima útil y estabilidad para transferir mejor al patinaje.';
    }

    return 'La IA seleccionó ejercicios según fatiga, objetivo del microciclo y transferencia al patinaje.';
  }

  static String _explanationEn(
    AutoPhysiologyStatus fatigue,
    PeriodizationDay day,
  ) {
    if (fatigue == AutoPhysiologyStatus.red) {
      return 'AI prioritized mobility, easy core and recovery due to high fatigue.';
    }

    if (fatigue == AutoPhysiologyStatus.orange) {
      return 'AI reduced heavy strength, aggressive plyometrics and volume due to accumulated fatigue.';
    }

    if (day.type == PeriodizationDayType.gymPower) {
      return 'AI prioritized explosive, Olympic and skating-transfer exercises.';
    }

    if (day.type == PeriodizationDayType.gymStrength) {
      return 'AI prioritized useful maximal strength and stability for skating transfer.';
    }

    return 'AI selected exercises based on fatigue, microcycle goal and skating transfer.';
  }

  static String _explanationDe(
    AutoPhysiologyStatus fatigue,
    PeriodizationDay day,
  ) {
    if (fatigue == AutoPhysiologyStatus.red) {
      return 'Die KI priorisierte Mobilität, leichten Core und Regeneration wegen hoher Ermüdung.';
    }

    if (fatigue == AutoPhysiologyStatus.orange) {
      return 'Die KI reduzierte schwere Kraft, aggressive Plyometrie und Volumen wegen kumulierter Ermüdung.';
    }

    if (day.type == PeriodizationDayType.gymPower) {
      return 'Die KI priorisierte explosive, olympische und skating-spezifische �obungen.';
    }

    if (day.type == PeriodizationDayType.gymStrength) {
      return 'Die KI priorisierte nützliche Maximalkraft und Stabilität für Skating-Transfer.';
    }

    return 'Die KI wählte �obungen nach Ermüdung, Mikrozyklus-Ziel und Skating-Transfer aus.';
  }
}


