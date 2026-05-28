import 'training_library_models.dart';

import 'speed/speed_sessions_block_1.dart';
import 'lactate/lactate_sessions_block_1.dart';
import 'technique/technique_sessions_block_1.dart';
import 'plyometric/plyometric_sessions_block_1.dart';
import 'core/core_sessions_block_1.dart';
import 'recovery/recovery_sessions_block_1.dart';
import 'cycling/cycling_sessions_block_1.dart';
import 'gym/gym_strength_sessions_block_1.dart';
import 'gym/gym_power_sessions_block_1.dart';
import 'endurance/endurance_sessions_block_1.dart';
import 'race_simulation/race_simulation_sessions_block_1.dart';
import 'warmup/warmup_sessions_block_1.dart';
import 'cooldown/cooldown_sessions_block_1.dart';

class MasterTrainingLibrary {
  static final List<TrainingSessionTemplate> sessions = [
    ...speedSessionsBlock1,
    ...lactateSessionsBlock1,
    ...techniqueSessionsBlock1,
    ...plyometricSessionsBlock1,
    ...coreSessionsBlock1,
    ...recoverySessionsBlock1,
    ...cyclingSessionsBlock1,
    ...gymStrengthSessionsBlock1,
    ...gymPowerSessionsBlock1,
    ...enduranceSessionsBlock1,
    ...raceSimulationSessionsBlock1,
    ...warmupSessionsBlock1,
    ...cooldownSessionsBlock1,
  ];

  static List<TrainingSessionTemplate> get allSessions => sessions;

  static List<TrainingSessionTemplate> getSessions({
    TrainingLibraryCategory? category,
    TrainingLibraryModality? modality,
    TrainingSessionIntensity? intensity,
    bool? neural,
    bool? metabolic,
    bool? technical,
    bool? reactive,
    bool? taper,
    bool? recovery,
  }) {
    return sessions.where((session) {
      if (category != null && session.category != category) return false;

      if (modality != null && !_matchesModality(session, modality)) {
        return false;
      }

      if (intensity != null && session.intensity != intensity) return false;

      if (neural != null && session.neuralFocused != neural) return false;
      if (metabolic != null && session.metabolicFocused != metabolic) {
        return false;
      }
      if (technical != null && session.technicalFocused != technical) {
        return false;
      }
      if (reactive != null && session.reactiveFocused != reactive) {
        return false;
      }
      if (taper != null && session.taperCompatible != taper) return false;
      if (recovery != null && session.recoverySession != recovery) {
        return false;
      }

      return true;
    }).toList();
  }

  static List<TrainingSessionTemplate> lowStressSessions() {
    return sessions.where((session) {
      return session.intensity == TrainingSessionIntensity.recovery ||
          session.intensity == TrainingSessionIntensity.low ||
          session.recoverySession ||
          session.category == TrainingLibraryCategory.recovery ||
          session.category == TrainingLibraryCategory.mobility ||
          session.category == TrainingLibraryCategory.cycling ||
          session.category == TrainingLibraryCategory.prehab;
    }).toList();
  }

  static List<TrainingSessionTemplate> highIntensitySessions() {
    return sessions.where((session) {
      return session.intensity == TrainingSessionIntensity.high ||
          session.intensity == TrainingSessionIntensity.maximal;
    }).toList();
  }

  static List<TrainingSessionTemplate> byCategory(
    TrainingLibraryCategory category,
  ) {
    return sessions.where((session) => session.category == category).toList();
  }

  static List<TrainingSessionTemplate> byModality(
    TrainingLibraryModality modality,
  ) {
    return sessions
        .where((session) => _matchesModality(session, modality))
        .toList();
  }

  static List<TrainingSessionTemplate> searchByTag(String tag) {
    final target = tag.toLowerCase().trim();

    return sessions.where((session) {
      return session.tags.any((item) => item.toLowerCase().trim() == target);
    }).toList();
  }

  static bool _matchesModality(
    TrainingSessionTemplate session,
    TrainingLibraryModality modality,
  ) {
    return session.modality == TrainingLibraryModality.universal ||
        modality == TrainingLibraryModality.universal ||
        session.modality == modality;
  }
}


