import 'athlete_program_service.dart';
import 'athlete_context_service.dart';
import 'gym_engine.dart';
import 'session_generator_engine.dart';
import 'skating_session_builder.dart';
import 'skating_workout_engine.dart';

class DailyTrainingPlan {
  final AthleteProgramProfile athlete;
  final DateTime date;
  final AthleteTrainingWeek? week;
  final GeneratedTrainingDay generatedDay;
  final SkatingWorkoutSession? skatingSession;
  final GymSession? gymSession;

  final int daysToCompetition;
  final String fatigueStatus;
  final int readinessScore;
  final String summary;

  const DailyTrainingPlan({
    required this.athlete,
    required this.date,
    required this.week,
    required this.generatedDay,
    required this.skatingSession,
    required this.gymSession,
    required this.daysToCompetition,
    required this.fatigueStatus,
    required this.readinessScore,
    required this.summary,
  });
}

class DailyTrainingOrchestrator {
  static DailyTrainingPlan generateToday({
    required AthleteProgramProfile athlete,
    required AthleteContextService context,
  }) {
    return generateForDate(
      athlete: athlete,
      context: context,
      date: DateTime.now(),
    );
  }

  static DailyTrainingPlan generateForDate({
    required AthleteProgramProfile athlete,
    required AthleteContextService context,
    required DateTime date,
  }) {
    final week = _findWeekForDate(athlete, date);
    final daysToCompetition = _daysToNextCompetition(athlete, date);
    final phase = _phaseFromWeek(week, daysToCompetition);

    final generatedDay = SessionGeneratorEngine.generate(
      athlete: athlete,
      context: context,
      phase: phase,
      daysToCompetition: daysToCompetition,
    );

    final skatingSession = generatedDay.skatingEnabled
        ? SkatingSessionBuilder.build(
            athlete: athlete,
            context: context,
            generatedDay: generatedDay,
          )
        : null;

    final gymSession = generatedDay.gymEnabled
        ? GymEngine.generate(
            athleteType: _athleteTypeText(athlete.type),
            level: _athleteLevelText(athlete.level),
          )
        : null;

    return DailyTrainingPlan(
      athlete: athlete,
      date: date,
      week: week,
      generatedDay: generatedDay,
      skatingSession: skatingSession,
      gymSession: gymSession,
      daysToCompetition: daysToCompetition,
      fatigueStatus: context.activeFatigueStatus,
      readinessScore: context.activeReadinessScore,
      summary: _summary(
        athlete: athlete,
        generatedDay: generatedDay,
        daysToCompetition: daysToCompetition,
        fatigueStatus: context.activeFatigueStatus,
        readinessScore: context.activeReadinessScore,
      ),
    );
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
    final futureCompetitions =
        athlete.competitions
            .where((competition) => !competition.date.isBefore(date))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    if (futureCompetitions.isEmpty) {
      return 999;
    }

    return futureCompetitions.first.date.difference(date).inDays;
  }

  static AthleteTrainingPhase _phaseFromWeek(
    AthleteTrainingWeek? week,
    int daysToCompetition,
  ) {
    if (week == null) {
      if (daysToCompetition <= 7) {
        return AthleteTrainingPhase.competition;
      }

      if (daysToCompetition <= 28) {
        return AthleteTrainingPhase.specific;
      }

      return AthleteTrainingPhase.base;
    }

    if (week.postCompetitionDeload) {
      return AthleteTrainingPhase.recovery;
    }

    if (week.taperWeek) {
      return AthleteTrainingPhase.competition;
    }

    final phaseText = week.phaseEs.toLowerCase();

    if (phaseText.contains('general')) {
      return AthleteTrainingPhase.base;
    }

    if (phaseText.contains('espec')) {
      return AthleteTrainingPhase.specific;
    }

    if (phaseText.contains('compet')) {
      return AthleteTrainingPhase.competition;
    }

    if (phaseText.contains('transición') || phaseText.contains('descarga')) {
      return AthleteTrainingPhase.recovery;
    }

    return AthleteTrainingPhase.base;
  }

  static String _athleteTypeText(AthleteProgramType type) {
    switch (type) {
      case AthleteProgramType.sprinter:
        return 'Velocista';
      case AthleteProgramType.endurance:
        return 'Fondista';
      case AthleteProgramType.mixed:
        return 'Mixto';
    }
  }

  static String _athleteLevelText(AthleteProgramLevel level) {
    switch (level) {
      case AthleteProgramLevel.novice:
        return 'Novato';
      case AthleteProgramLevel.competitive:
        return 'Competitivo';
      case AthleteProgramLevel.elite:
        return 'Elite';
    }
  }

  static String _summary({
    required AthleteProgramProfile athlete,
    required GeneratedTrainingDay generatedDay,
    required int daysToCompetition,
    required String fatigueStatus,
    required int readinessScore,
  }) {
    if (fatigueStatus == 'red') {
      return 'Recuperación obligatoria para ${athlete.name}. Fatiga roja y readiness $readinessScore.';
    }

    if (generatedDay.taperMode) {
      return '${athlete.name} está en taper. Faltan $daysToCompetition días para competir.';
    }

    if (generatedDay.recoveryRequired) {
      return 'Sesión regenerativa para ${athlete.name}. Readiness $readinessScore.';
    }

    return 'Sesión automática para ${athlete.name}: ${generatedDay.notes}';
  }
}


