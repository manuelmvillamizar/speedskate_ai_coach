import 'auto_adjust_screen.dart';
import 'periodization_engine.dart';

enum SeasonPhase {
  generalPreparation,
  specificPreparation,
  preCompetition,
  competition,
  transition,
}

enum SeasonTrainingEmphasis {
  aerobicBase,
  maxStrength,
  speedPower,
  raceSpecific,
  taper,
  recovery,
}

class SeasonCompetitionInput {
  final String id;
  final String name;
  final DateTime date;
  final String location;
  final int priority;

  const SeasonCompetitionInput({
    required this.id,
    required this.name,
    required this.date,
    required this.location,
    required this.priority,
  });
}

class AthleteSeasonWeek {
  final int weekNumber;
  final DateTime startDate;
  final DateTime endDate;

  final SeasonPhase phase;
  final SeasonTrainingEmphasis emphasis;

  final PeriodizationMicrocycle microcycle;

  final SeasonCompetitionInput? competition;

  final String goalEs;
  final String goalEn;
  final String goalDe;

  final int gymDays;
  final int skateDays;
  final int recoveryDays;

  final bool taperWeek;
  final bool postCompetitionDeload;

  const AthleteSeasonWeek({
    required this.weekNumber,
    required this.startDate,
    required this.endDate,
    required this.phase,
    required this.emphasis,
    required this.microcycle,
    required this.competition,
    required this.goalEs,
    required this.goalEn,
    required this.goalDe,
    required this.gymDays,
    required this.skateDays,
    required this.recoveryDays,
    required this.taperWeek,
    required this.postCompetitionDeload,
  });
}

class AthleteSeasonPlan {
  final String athleteName;
  final PeriodizationAthleteType athleteType;
  final PeriodizationLevel level;
  final DateTime startDate;
  final DateTime endDate;
  final List<SeasonCompetitionInput> competitions;
  final List<AthleteSeasonWeek> weeks;

  const AthleteSeasonPlan({
    required this.athleteName,
    required this.athleteType,
    required this.level,
    required this.startDate,
    required this.endDate,
    required this.competitions,
    required this.weeks,
  });
}

class AthleteSeasonEngine {
  static AthleteSeasonPlan generateSeason({
    required String athleteName,
    required PeriodizationAthleteType athleteType,
    required PeriodizationLevel level,
    required DateTime startDate,
    required int totalWeeks,
    required List<SeasonCompetitionInput> competitions,
    AutoPhysiologyStatus fatigueStatus = AutoPhysiologyStatus.green,
  }) {
    final sortedCompetitions = [...competitions]
      ..sort((a, b) => a.date.compareTo(b.date));

    final weeks = <AthleteSeasonWeek>[];

    for (int i = 0; i < totalWeeks; i++) {
      final weekStart = startDate.add(Duration(days: i * 7));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final competition = _competitionInWeek(
        sortedCompetitions,
        weekStart,
        weekEnd,
      );

      final nextCompetition = _nextCompetition(sortedCompetitions, weekStart);

      final previousCompetition = _previousCompetition(
        sortedCompetitions,
        weekStart,
      );

      final weeksToCompetition = nextCompetition == null
          ? null
          : (nextCompetition.date.difference(weekStart).inDays / 7).ceil();

      final daysSincePreviousCompetition = previousCompetition == null
          ? null
          : weekStart.difference(previousCompetition.date).inDays;

      final phase = _phaseForWeek(
        weekIndex: i,
        totalWeeks: totalWeeks,
        competition: competition,
        weeksToCompetition: weeksToCompetition,
        daysSincePreviousCompetition: daysSincePreviousCompetition,
      );

      final emphasis = _emphasisForPhase(
        phase: phase,
        athleteType: athleteType,
        competition: competition,
        weeksToCompetition: weeksToCompetition,
      );

      final focus = _periodizationFocusForPhase(phase);

      final adjustedFatigue = _fatigueForWeek(
        phase: phase,
        baseFatigue: fatigueStatus,
      );

      final microcycle = PeriodizationEngine.generateMicrocycle(
        athleteType: athleteType,
        level: level,
        focus: focus,
        fatigueStatus: adjustedFatigue,
      );

      weeks.add(
        AthleteSeasonWeek(
          weekNumber: i + 1,
          startDate: weekStart,
          endDate: weekEnd,
          phase: phase,
          emphasis: emphasis,
          microcycle: microcycle,
          competition: competition,
          goalEs: _goalEs(phase, emphasis, competition),
          goalEn: _goalEn(phase, emphasis, competition),
          goalDe: _goalDe(phase, emphasis, competition),
          gymDays: _gymDays(phase, athleteType),
          skateDays: _skateDays(phase, athleteType),
          recoveryDays: _recoveryDays(phase),
          taperWeek: phase == SeasonPhase.preCompetition,
          postCompetitionDeload:
              phase == SeasonPhase.transition &&
              daysSincePreviousCompetition != null,
        ),
      );
    }

    return AthleteSeasonPlan(
      athleteName: athleteName,
      athleteType: athleteType,
      level: level,
      startDate: startDate,
      endDate: startDate.add(Duration(days: totalWeeks * 7 - 1)),
      competitions: sortedCompetitions,
      weeks: weeks,
    );
  }

  static SeasonCompetitionInput? _competitionInWeek(
    List<SeasonCompetitionInput> competitions,
    DateTime start,
    DateTime end,
  ) {
    for (final competition in competitions) {
      final date = DateTime(
        competition.date.year,
        competition.date.month,
        competition.date.day,
      );

      final s = DateTime(start.year, start.month, start.day);
      final e = DateTime(end.year, end.month, end.day);

      if (!date.isBefore(s) && !date.isAfter(e)) {
        return competition;
      }
    }

    return null;
  }

  static SeasonCompetitionInput? _nextCompetition(
    List<SeasonCompetitionInput> competitions,
    DateTime date,
  ) {
    final future = competitions.where((c) => !c.date.isBefore(date)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (future.isEmpty) return null;

    return future.first;
  }

  static SeasonCompetitionInput? _previousCompetition(
    List<SeasonCompetitionInput> competitions,
    DateTime date,
  ) {
    final past = competitions.where((c) => c.date.isBefore(date)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (past.isEmpty) return null;

    return past.first;
  }

  static SeasonPhase _phaseForWeek({
    required int weekIndex,
    required int totalWeeks,
    required SeasonCompetitionInput? competition,
    required int? weeksToCompetition,
    required int? daysSincePreviousCompetition,
  }) {
    if (competition != null) {
      return SeasonPhase.competition;
    }

    if (daysSincePreviousCompetition != null &&
        daysSincePreviousCompetition >= 0 &&
        daysSincePreviousCompetition <= 10) {
      return SeasonPhase.transition;
    }

    if (weeksToCompetition != null) {
      if (weeksToCompetition <= 1) {
        return SeasonPhase.preCompetition;
      }

      if (weeksToCompetition <= 4) {
        return SeasonPhase.specificPreparation;
      }
    }

    final progress = weekIndex / totalWeeks;

    if (progress < 0.45) {
      return SeasonPhase.generalPreparation;
    }

    if (progress < 0.80) {
      return SeasonPhase.specificPreparation;
    }

    return SeasonPhase.preCompetition;
  }

  static SeasonTrainingEmphasis _emphasisForPhase({
    required SeasonPhase phase,
    required PeriodizationAthleteType athleteType,
    required SeasonCompetitionInput? competition,
    required int? weeksToCompetition,
  }) {
    switch (phase) {
      case SeasonPhase.generalPreparation:
        if (athleteType == PeriodizationAthleteType.endurance) {
          return SeasonTrainingEmphasis.aerobicBase;
        }
        return SeasonTrainingEmphasis.maxStrength;

      case SeasonPhase.specificPreparation:
        if (athleteType == PeriodizationAthleteType.sprinter) {
          return SeasonTrainingEmphasis.speedPower;
        }
        return SeasonTrainingEmphasis.raceSpecific;

      case SeasonPhase.preCompetition:
        return SeasonTrainingEmphasis.taper;

      case SeasonPhase.competition:
        return SeasonTrainingEmphasis.raceSpecific;

      case SeasonPhase.transition:
        return SeasonTrainingEmphasis.recovery;
    }
  }

  static PeriodizationFocus _periodizationFocusForPhase(SeasonPhase phase) {
    switch (phase) {
      case SeasonPhase.generalPreparation:
        return PeriodizationFocus.base;
      case SeasonPhase.specificPreparation:
        return PeriodizationFocus.specific;
      case SeasonPhase.preCompetition:
        return PeriodizationFocus.recovery;
      case SeasonPhase.competition:
        return PeriodizationFocus.competition;
      case SeasonPhase.transition:
        return PeriodizationFocus.recovery;
    }
  }

  static AutoPhysiologyStatus _fatigueForWeek({
    required SeasonPhase phase,
    required AutoPhysiologyStatus baseFatigue,
  }) {
    if (phase == SeasonPhase.preCompetition ||
        phase == SeasonPhase.transition ||
        phase == SeasonPhase.competition) {
      return AutoPhysiologyStatus.green;
    }

    return baseFatigue;
  }

  static int _gymDays(SeasonPhase phase, PeriodizationAthleteType athleteType) {
    switch (phase) {
      case SeasonPhase.generalPreparation:
        return athleteType == PeriodizationAthleteType.sprinter ? 3 : 2;
      case SeasonPhase.specificPreparation:
        return 2;
      case SeasonPhase.preCompetition:
        return 1;
      case SeasonPhase.competition:
        return 0;
      case SeasonPhase.transition:
        return 0;
    }
  }

  static int _skateDays(
    SeasonPhase phase,
    PeriodizationAthleteType athleteType,
  ) {
    switch (phase) {
      case SeasonPhase.generalPreparation:
        return athleteType == PeriodizationAthleteType.endurance ? 5 : 4;
      case SeasonPhase.specificPreparation:
        return 5;
      case SeasonPhase.preCompetition:
        return 4;
      case SeasonPhase.competition:
        return 3;
      case SeasonPhase.transition:
        return 2;
    }
  }

  static int _recoveryDays(SeasonPhase phase) {
    switch (phase) {
      case SeasonPhase.generalPreparation:
        return 1;
      case SeasonPhase.specificPreparation:
        return 1;
      case SeasonPhase.preCompetition:
        return 2;
      case SeasonPhase.competition:
        return 2;
      case SeasonPhase.transition:
        return 3;
    }
  }

  static String _goalEs(
    SeasonPhase phase,
    SeasonTrainingEmphasis emphasis,
    SeasonCompetitionInput? competition,
  ) {
    if (competition != null) {
      return 'Semana competitiva: ${competition.name}. Llegar fresco, rápido y preciso.';
    }

    switch (phase) {
      case SeasonPhase.generalPreparation:
        return 'Construir base física, fuerza estructural, técnica y tolerancia a la carga.';
      case SeasonPhase.specificPreparation:
        return 'Convertir fuerza y base en velocidad, potencia y ritmo competitivo.';
      case SeasonPhase.preCompetition:
        return 'Reducir fatiga, mantener velocidad y afinar detalles técnicos.';
      case SeasonPhase.competition:
        return 'Competir, controlar carga y priorizar rendimiento.';
      case SeasonPhase.transition:
        return 'Recuperar, descargar y preparar el siguiente bloque.';
    }
  }

  static String _goalEn(
    SeasonPhase phase,
    SeasonTrainingEmphasis emphasis,
    SeasonCompetitionInput? competition,
  ) {
    if (competition != null) {
      return 'Competition week: ${competition.name}. Arrive fresh, fast and precise.';
    }

    switch (phase) {
      case SeasonPhase.generalPreparation:
        return 'Build physical base, structural strength, technique and load tolerance.';
      case SeasonPhase.specificPreparation:
        return 'Convert strength and base into speed, power and race rhythm.';
      case SeasonPhase.preCompetition:
        return 'Reduce fatigue, maintain speed and sharpen technical details.';
      case SeasonPhase.competition:
        return 'Compete, control load and prioritize performance.';
      case SeasonPhase.transition:
        return 'Recover, deload and prepare the next block.';
    }
  }

  static String _goalDe(
    SeasonPhase phase,
    SeasonTrainingEmphasis emphasis,
    SeasonCompetitionInput? competition,
  ) {
    if (competition != null) {
      return 'Wettkampfwoche: ${competition.name}. Frisch, schnell und präzise ankommen.';
    }

    switch (phase) {
      case SeasonPhase.generalPreparation:
        return 'Physische Basis, strukturelle Kraft, Technik und Belastungstoleranz aufbauen.';
      case SeasonPhase.specificPreparation:
        return 'Kraft und Basis in Geschwindigkeit, Leistung und Wettkampfrhythmus umwandeln.';
      case SeasonPhase.preCompetition:
        return 'Ermüdung reduzieren, Geschwindigkeit halten und technische Details schärfen.';
      case SeasonPhase.competition:
        return 'Wettkampf, Belastung kontrollieren und Leistung priorisieren.';
      case SeasonPhase.transition:
        return 'Regeneration, Entlastung und Vorbereitung des nächsten Blocks.';
    }
  }
}


