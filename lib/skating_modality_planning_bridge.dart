import 'athlete_program_service.dart';

enum SkatingSpecialization { sprint, endurance, mixed }

enum SkatingSeasonPhase { general, specific, competition, taper, transition }

class ModalityTrainingDistribution {
  final double aerobic;
  final double speed;
  final double strength;
  final double power;
  final double technical;
  final double tactical;
  final double recovery;
  final double plyometric;
  final double core;
  final double upperBody;
  final double bike;

  const ModalityTrainingDistribution({
    required this.aerobic,
    required this.speed,
    required this.strength,
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

class SkatingModalityPlanningBridge {
  static SkatingSpecialization specializationForAthlete(
    AthleteProgramProfile athlete,
  ) {
    switch (athlete.type) {
      case AthleteProgramType.sprinter:
        return SkatingSpecialization.sprint;

      case AthleteProgramType.endurance:
        return SkatingSpecialization.endurance;

      case AthleteProgramType.mixed:
        return SkatingSpecialization.mixed;
    }
  }

  static SkatingSeasonPhase phaseFromWeek(AthleteTrainingWeek? week) {
    if (week == null) {
      return SkatingSeasonPhase.general;
    }

    if (week.postCompetitionDeload) {
      return SkatingSeasonPhase.transition;
    }

    if (week.taperWeek) {
      return SkatingSeasonPhase.taper;
    }

    final phase = week.phaseEs.toLowerCase();

    if (phase.contains('general')) {
      return SkatingSeasonPhase.general;
    }

    if (phase.contains('espec')) {
      return SkatingSeasonPhase.specific;
    }

    if (phase.contains('competencia')) {
      return SkatingSeasonPhase.competition;
    }

    if (phase.contains('taper')) {
      return SkatingSeasonPhase.taper;
    }

    if (phase.contains('trans')) {
      return SkatingSeasonPhase.transition;
    }

    return SkatingSeasonPhase.general;
  }

  static ModalityTrainingDistribution distribution({
    required SkatingSpecialization specialization,
    required SkatingSeasonPhase phase,
  }) {
    switch (specialization) {
      case SkatingSpecialization.sprint:
        return _sprinterDistribution(phase);

      case SkatingSpecialization.endurance:
        return _enduranceDistribution(phase);

      case SkatingSpecialization.mixed:
        return _mixedDistribution(phase);
    }
  }

  static ModalityTrainingDistribution _sprinterDistribution(
    SkatingSeasonPhase phase,
  ) {
    switch (phase) {
      case SkatingSeasonPhase.general:
        return const ModalityTrainingDistribution(
          aerobic: 0.22,
          speed: 0.18,
          strength: 0.22,
          power: 0.14,
          technical: 0.08,
          tactical: 0.02,
          recovery: 0.05,
          plyometric: 0.04,
          core: 0.03,
          upperBody: 0.01,
          bike: 0.01,
        );

      case SkatingSeasonPhase.specific:
        return const ModalityTrainingDistribution(
          aerobic: 0.15,
          speed: 0.28,
          strength: 0.20,
          power: 0.16,
          technical: 0.08,
          tactical: 0.03,
          recovery: 0.04,
          plyometric: 0.04,
          core: 0.01,
          upperBody: 0.00,
          bike: 0.01,
        );

      case SkatingSeasonPhase.competition:
        return const ModalityTrainingDistribution(
          aerobic: 0.12,
          speed: 0.32,
          strength: 0.16,
          power: 0.14,
          technical: 0.10,
          tactical: 0.05,
          recovery: 0.07,
          plyometric: 0.02,
          core: 0.01,
          upperBody: 0.00,
          bike: 0.01,
        );

      case SkatingSeasonPhase.taper:
        return const ModalityTrainingDistribution(
          aerobic: 0.10,
          speed: 0.34,
          strength: 0.10,
          power: 0.10,
          technical: 0.12,
          tactical: 0.06,
          recovery: 0.14,
          plyometric: 0.02,
          core: 0.01,
          upperBody: 0.00,
          bike: 0.01,
        );

      case SkatingSeasonPhase.transition:
        return const ModalityTrainingDistribution(
          aerobic: 0.30,
          speed: 0.08,
          strength: 0.08,
          power: 0.02,
          technical: 0.05,
          tactical: 0.00,
          recovery: 0.20,
          plyometric: 0.00,
          core: 0.10,
          upperBody: 0.07,
          bike: 0.10,
        );
    }
  }

  static ModalityTrainingDistribution _enduranceDistribution(
    SkatingSeasonPhase phase,
  ) {
    switch (phase) {
      case SkatingSeasonPhase.general:
        return const ModalityTrainingDistribution(
          aerobic: 0.38,
          speed: 0.08,
          strength: 0.14,
          power: 0.04,
          technical: 0.08,
          tactical: 0.04,
          recovery: 0.06,
          plyometric: 0.02,
          core: 0.06,
          upperBody: 0.04,
          bike: 0.06,
        );

      case SkatingSeasonPhase.specific:
        return const ModalityTrainingDistribution(
          aerobic: 0.28,
          speed: 0.14,
          strength: 0.14,
          power: 0.05,
          technical: 0.08,
          tactical: 0.07,
          recovery: 0.06,
          plyometric: 0.02,
          core: 0.05,
          upperBody: 0.04,
          bike: 0.07,
        );

      case SkatingSeasonPhase.competition:
        return const ModalityTrainingDistribution(
          aerobic: 0.22,
          speed: 0.18,
          strength: 0.10,
          power: 0.05,
          technical: 0.10,
          tactical: 0.10,
          recovery: 0.10,
          plyometric: 0.01,
          core: 0.04,
          upperBody: 0.03,
          bike: 0.07,
        );

      case SkatingSeasonPhase.taper:
        return const ModalityTrainingDistribution(
          aerobic: 0.18,
          speed: 0.20,
          strength: 0.06,
          power: 0.04,
          technical: 0.12,
          tactical: 0.10,
          recovery: 0.18,
          plyometric: 0.00,
          core: 0.03,
          upperBody: 0.02,
          bike: 0.07,
        );

      case SkatingSeasonPhase.transition:
        return const ModalityTrainingDistribution(
          aerobic: 0.32,
          speed: 0.05,
          strength: 0.06,
          power: 0.01,
          technical: 0.03,
          tactical: 0.00,
          recovery: 0.22,
          plyometric: 0.00,
          core: 0.10,
          upperBody: 0.08,
          bike: 0.13,
        );
    }
  }

  static ModalityTrainingDistribution _mixedDistribution(
    SkatingSeasonPhase phase,
  ) {
    switch (phase) {
      case SkatingSeasonPhase.general:
        return const ModalityTrainingDistribution(
          aerobic: 0.30,
          speed: 0.14,
          strength: 0.18,
          power: 0.08,
          technical: 0.08,
          tactical: 0.04,
          recovery: 0.06,
          plyometric: 0.03,
          core: 0.04,
          upperBody: 0.02,
          bike: 0.03,
        );

      case SkatingSeasonPhase.specific:
        return const ModalityTrainingDistribution(
          aerobic: 0.24,
          speed: 0.18,
          strength: 0.18,
          power: 0.10,
          technical: 0.08,
          tactical: 0.06,
          recovery: 0.05,
          plyometric: 0.04,
          core: 0.03,
          upperBody: 0.01,
          bike: 0.03,
        );

      case SkatingSeasonPhase.competition:
        return const ModalityTrainingDistribution(
          aerobic: 0.18,
          speed: 0.22,
          strength: 0.14,
          power: 0.10,
          technical: 0.10,
          tactical: 0.08,
          recovery: 0.10,
          plyometric: 0.03,
          core: 0.02,
          upperBody: 0.01,
          bike: 0.02,
        );

      case SkatingSeasonPhase.taper:
        return const ModalityTrainingDistribution(
          aerobic: 0.14,
          speed: 0.24,
          strength: 0.08,
          power: 0.08,
          technical: 0.12,
          tactical: 0.08,
          recovery: 0.18,
          plyometric: 0.02,
          core: 0.02,
          upperBody: 0.01,
          bike: 0.03,
        );

      case SkatingSeasonPhase.transition:
        return const ModalityTrainingDistribution(
          aerobic: 0.32,
          speed: 0.06,
          strength: 0.08,
          power: 0.02,
          technical: 0.04,
          tactical: 0.00,
          recovery: 0.20,
          plyometric: 0.00,
          core: 0.10,
          upperBody: 0.08,
          bike: 0.10,
        );
    }
  }
}


