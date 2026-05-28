// �s�️ LEGACY CANDIDATE - Este archivo pertenece al pipeline antiguo.
// El pipeline moderno usa IntegratedDayGeneratorEngine.
// Pendiente de migración o eliminación.
import 'athlete_program_service.dart';
import 'athlete_context_service.dart';

enum AthleteTrainingPhase { base, specific, competition, recovery }

enum SessionFocus {
  recovery,
  aerobic,
  technique,
  strength,
  power,
  speed,
  raceSimulation,
  taper,
}

enum SessionIntensity { veryLow, low, medium, high, veryHigh }

class GeneratedTrainingDay {
  final SessionFocus focus;
  final SessionIntensity intensity;

  final bool gymEnabled;
  final bool skatingEnabled;
  final bool recoveryRequired;
  final bool taperMode;

  final int skatingMinutes;
  final int gymMinutes;

  final String notes;

  const GeneratedTrainingDay({
    required this.focus,
    required this.intensity,
    required this.gymEnabled,
    required this.skatingEnabled,
    required this.recoveryRequired,
    required this.taperMode,
    required this.skatingMinutes,
    required this.gymMinutes,
    required this.notes,
  });
}

class SessionGeneratorEngine {
  static GeneratedTrainingDay generate({
    required AthleteProgramProfile athlete,
    required AthleteContextService context,
    required AthleteTrainingPhase phase,
    required int daysToCompetition,
  }) {
    final fatigue = context.activeFatigueStatus;
    final readiness = context.activeReadinessScore;

    /// RECOVERY EMERGENCY

    if (fatigue == 'red') {
      return const GeneratedTrainingDay(
        focus: SessionFocus.recovery,
        intensity: SessionIntensity.veryLow,
        gymEnabled: false,
        skatingEnabled: false,
        recoveryRequired: true,
        taperMode: false,
        skatingMinutes: 0,
        gymMinutes: 0,
        notes: 'Fatiga extrema. Recuperación obligatoria.',
      );
    }

    /// TAPER

    if (daysToCompetition <= 7) {
      return GeneratedTrainingDay(
        focus: SessionFocus.taper,
        intensity: SessionIntensity.low,
        gymEnabled: false,
        skatingEnabled: true,
        recoveryRequired: true,
        taperMode: true,
        skatingMinutes: athlete.type == AthleteProgramType.endurance ? 45 : 35,
        gymMinutes: 0,
        notes: 'Semana precompetitiva. Reducir volumen.',
      );
    }

    /// LOW READINESS

    if (readiness < 45) {
      return const GeneratedTrainingDay(
        focus: SessionFocus.recovery,
        intensity: SessionIntensity.low,
        gymEnabled: false,
        skatingEnabled: true,
        recoveryRequired: true,
        taperMode: false,
        skatingMinutes: 30,
        gymMinutes: 0,
        notes: 'Readiness bajo. Sesión regenerativa.',
      );
    }

    /// PHASE LOGIC

    switch (phase) {
      case AthleteTrainingPhase.base:
        return _basePhase(athlete);

      case AthleteTrainingPhase.specific:
        return _specificPhase(athlete);

      case AthleteTrainingPhase.competition:
        return _competitionPhase(athlete);

      case AthleteTrainingPhase.recovery:
        return _recoveryPhase();
    }
  }

  static GeneratedTrainingDay _basePhase(AthleteProgramProfile athlete) {
    if (athlete.type == AthleteProgramType.endurance) {
      return const GeneratedTrainingDay(
        focus: SessionFocus.aerobic,
        intensity: SessionIntensity.medium,
        gymEnabled: true,
        skatingEnabled: true,
        recoveryRequired: false,
        taperMode: false,
        skatingMinutes: 90,
        gymMinutes: 60,
        notes: 'Desarrollo aeróbico extensivo.',
      );
    }

    return const GeneratedTrainingDay(
      focus: SessionFocus.strength,
      intensity: SessionIntensity.medium,
      gymEnabled: true,
      skatingEnabled: true,
      recoveryRequired: false,
      taperMode: false,
      skatingMinutes: 60,
      gymMinutes: 75,
      notes: 'Construcción de fuerza general.',
    );
  }

  static GeneratedTrainingDay _specificPhase(AthleteProgramProfile athlete) {
    if (athlete.type == AthleteProgramType.sprinter) {
      return const GeneratedTrainingDay(
        focus: SessionFocus.speed,
        intensity: SessionIntensity.high,
        gymEnabled: true,
        skatingEnabled: true,
        recoveryRequired: false,
        taperMode: false,
        skatingMinutes: 75,
        gymMinutes: 60,
        notes: 'Velocidad específica y potencia.',
      );
    }

    return const GeneratedTrainingDay(
      focus: SessionFocus.power,
      intensity: SessionIntensity.high,
      gymEnabled: true,
      skatingEnabled: true,
      recoveryRequired: false,
      taperMode: false,
      skatingMinutes: 90,
      gymMinutes: 50,
      notes: 'Potencia aeróbica específica.',
    );
  }

  static GeneratedTrainingDay _competitionPhase(AthleteProgramProfile athlete) {
    return const GeneratedTrainingDay(
      focus: SessionFocus.raceSimulation,
      intensity: SessionIntensity.high,
      gymEnabled: false,
      skatingEnabled: true,
      recoveryRequired: false,
      taperMode: false,
      skatingMinutes: 60,
      gymMinutes: 0,
      notes: 'Simulación competitiva.',
    );
  }

  static GeneratedTrainingDay _recoveryPhase() {
    return const GeneratedTrainingDay(
      focus: SessionFocus.recovery,
      intensity: SessionIntensity.low,
      gymEnabled: false,
      skatingEnabled: true,
      recoveryRequired: true,
      taperMode: false,
      skatingMinutes: 30,
      gymMinutes: 0,
      notes: 'Microciclo regenerativo.',
    );
  }
}


