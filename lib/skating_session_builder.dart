// �s�️ LEGACY CANDIDATE - Este archivo pertenece al pipeline antiguo.
// El pipeline moderno usa DailyTrainingPipelineService.
// Pendiente de migración o eliminación.
import 'athlete_program_service.dart';
import 'athlete_context_service.dart';
import 'session_generator_engine.dart';
import 'skating_workout_engine.dart';

class SkatingSessionBuilder {
  static SkatingWorkoutSession build({
    required AthleteProgramProfile athlete,
    required AthleteContextService context,
    required GeneratedTrainingDay generatedDay,
  }) {
    final isNovice = athlete.level == AthleteProgramLevel.novice;

    if (context.activeFatigueStatus == 'red') {
      return SkatingWorkoutEngine.generateRecoverySession();
    }

    if (generatedDay.recoveryRequired) {
      return SkatingWorkoutEngine.generateRecoverySession();
    }

    if (generatedDay.focus == SessionFocus.raceSimulation) {
      return SkatingWorkoutEngine.generateCompetitionSession(
        isNovice: isNovice,
      );
    }

    if (generatedDay.focus == SessionFocus.taper) {
      return SkatingWorkoutEngine.generateCompetitionSession(
        isNovice: isNovice,
      );
    }

    switch (athlete.type) {
      case AthleteProgramType.sprinter:
        return SkatingWorkoutEngine.generateSpeedSession(isNovice: isNovice);

      case AthleteProgramType.endurance:
        return SkatingWorkoutEngine.generateEnduranceSession(
          isNovice: isNovice,
        );

      case AthleteProgramType.mixed:
        return SkatingWorkoutEngine.generateMixedSession(isNovice: isNovice);
    }
  }
}


