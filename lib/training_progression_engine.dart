import 'athlete_adaptation_layer.dart';
import 'athlete_daily_state.dart';
import 'adaptive_response_memory.dart';

enum TrainingProgressionMode {
  recovery,
  maintain,
  smallProgression,
  addSecondSession,
  addThirdSession,
}

enum TrainingProgressionTarget {
  none,
  skatingVolume,
  skatingIntensity,
  cyclingVolume,
  gymStrength,
  gymPower,
  plyometrics,
  recovery,
}

class TrainingProgressionDecision {
  final TrainingProgressionMode mode;
  final List<TrainingProgressionTarget> targets;
  final int recommendedSessions;
  final double volumeMultiplier;
  final double intensityMultiplier;
  final double gymMultiplier;
  final double plyometricMultiplier;
  final String reason;

  const TrainingProgressionDecision({
    required this.mode,
    required this.targets,
    required this.recommendedSessions,
    required this.volumeMultiplier,
    required this.intensityMultiplier,
    required this.gymMultiplier,
    required this.plyometricMultiplier,
    required this.reason,
  });

  bool get canAddSession {
    return mode == TrainingProgressionMode.addSecondSession ||
        mode == TrainingProgressionMode.addThirdSession;
  }

  bool get shouldReduce {
    return mode == TrainingProgressionMode.recovery;
  }
}

class TrainingProgressionEngine {
  static TrainingProgressionDecision decide({
    required AthleteDailyState dailyState,
    required AthleteAdaptationProfile adaptation,
    AdaptiveResponseMemory? memory,
  }) {
    final strength = dailyState.strengthLoadState;

    final readiness = dailyState.readiness;
    final injuryRisk = dailyState.injuryRisk;
    final acwr = dailyState.acwr;

    final neuralStress = strength.neuralStress;
    final tendonStress = strength.tendonStress;
    final muscleStress = strength.muscleStress;

    final sprintTolerance = memory?.sprintTolerance ?? 1.0;
    final lactateTolerance = memory?.lactateTolerance ?? 1.0;
    final gymTolerance = memory?.gymTolerance ?? 1.0;
    final jumpTolerance = memory?.jumpTolerance ?? 1.0;
    final doubleSessionTolerance = memory?.doubleSessionTolerance ?? 1.0;
    final taperResponse = memory?.taperResponse ?? 1.0;
    final z5Tolerance = memory?.z5Tolerance ?? 1.0;

    final poorNeuralTolerance =
        adaptation.neuralTolerance < 0.90 ||
        sprintTolerance < 0.92 ||
        z5Tolerance < 0.92 ||
        memory?.strugglesWithZ5 == true;

    final goodNeuralTolerance =
        adaptation.toleratesNeuralLoad ||
        adaptation.neuralTolerance >= 1.08 ||
        sprintTolerance >= 1.08 ||
        memory?.toleratesSprint == true;

    final poorLactateTolerance =
        adaptation.strugglesWithLactate ||
        adaptation.lactateTolerance < 0.90 ||
        lactateTolerance < 0.92 ||
        memory?.strugglesWithLactate == true;

    final goodLactateTolerance =
        adaptation.lactateTolerance >= 1.06 &&
        lactateTolerance >= 1.04 &&
        !poorLactateTolerance;

    final poorReactiveTolerance =
        adaptation.needsReactiveProtection ||
        adaptation.reactiveTolerance < 0.90 ||
        jumpTolerance < 0.92 ||
        memory?.strugglesWithJumps == true;

    final goodReactiveTolerance =
        adaptation.reactiveTolerance >= 1.06 &&
        jumpTolerance >= 1.04 &&
        !poorReactiveTolerance;

    final goodGymTolerance =
        gymTolerance >= 1.04 ||
        memory?.toleratesGym == true ||
        adaptation.neuralTolerance >= 1.05;

    final poorGymTolerance =
        gymTolerance < 0.92 ||
        memory?.strugglesWithJumps == true ||
        tendonStress >= 70 ||
        muscleStress >= 80;

    final goodDensityTolerance =
        adaptation.toleratesDoubleIntensity ||
        adaptation.densityTolerance >= 1.08 ||
        doubleSessionTolerance >= 1.08 ||
        memory?.toleratesDoubleSession == true;

    final poorDensityTolerance =
        adaptation.densityTolerance < 0.92 ||
        doubleSessionTolerance < 0.92 ||
        dailyState.shouldBlockIntensity ||
        neuralStress >= 70 ||
        tendonStress >= 70;

    final needsConservativeTaper =
        adaptation.needsLongerTaper ||
        adaptation.taperNeed >= 1.12 ||
        taperResponse < 0.92 ||
        memory?.needsLongerTaper == true;

    if (readiness < 55 ||
        injuryRisk >= 65 ||
        acwr >= 1.45 ||
        dailyState.shouldForceRecovery ||
        dailyState.shouldBlockIntensity ||
        neuralStress >= 80 ||
        tendonStress >= 80 ||
        (needsConservativeTaper && readiness < 68)) {
      return const TrainingProgressionDecision(
        mode: TrainingProgressionMode.recovery,
        targets: [TrainingProgressionTarget.recovery],
        recommendedSessions: 1,
        volumeMultiplier: 0.65,
        intensityMultiplier: 0.55,
        gymMultiplier: 0.50,
        plyometricMultiplier: 0.0,
        reason:
            'Bloqueo de progresión por fatiga, riesgo, estrés neural/tendinoso o necesidad de descarga más conservadora.',
      );
    }

    if (readiness < 70 ||
        injuryRisk >= 45 ||
        acwr >= 1.25 ||
        neuralStress >= 65 ||
        tendonStress >= 65 ||
        muscleStress >= 75 ||
        poorDensityTolerance ||
        poorReactiveTolerance && readiness < 76 ||
        poorLactateTolerance && readiness < 76) {
      final targets = <TrainingProgressionTarget>[
        TrainingProgressionTarget.cyclingVolume,
      ];

      if (poorReactiveTolerance ||
          poorLactateTolerance ||
          poorNeuralTolerance) {
        targets.add(TrainingProgressionTarget.recovery);
      }

      return TrainingProgressionDecision(
        mode: TrainingProgressionMode.maintain,
        targets: targets,
        recommendedSessions: 1,
        volumeMultiplier: poorDensityTolerance ? 0.84 : 0.90,
        intensityMultiplier: poorLactateTolerance || poorNeuralTolerance
            ? 0.72
            : 0.80,
        gymMultiplier: poorGymTolerance ? 0.65 : 0.80,
        plyometricMultiplier: poorReactiveTolerance ? 0.0 : 0.45,
        reason:
            'Mantener carga: la memoria adaptativa recomienda bajo impacto, control de intensidad y protección reactiva/metabólica.',
      );
    }

    if (readiness >= 86 &&
        injuryRisk < 35 &&
        acwr >= 0.80 &&
        acwr <= 1.18 &&
        goodDensityTolerance &&
        !poorDensityTolerance &&
        !poorReactiveTolerance &&
        !poorLactateTolerance &&
        !needsConservativeTaper) {
      final targets = <TrainingProgressionTarget>[
        TrainingProgressionTarget.cyclingVolume,
      ];

      if (goodGymTolerance && !poorGymTolerance) {
        targets.add(TrainingProgressionTarget.gymPower);
      } else {
        targets.add(TrainingProgressionTarget.gymStrength);
      }

      if (goodReactiveTolerance) {
        targets.add(TrainingProgressionTarget.plyometrics);
      }

      if (goodNeuralTolerance) {
        targets.add(TrainingProgressionTarget.skatingIntensity);
      }

      return TrainingProgressionDecision(
        mode: TrainingProgressionMode.addThirdSession,
        targets: targets,
        recommendedSessions: 3,
        volumeMultiplier: 1.08,
        intensityMultiplier: goodNeuralTolerance ? 1.06 : 1.02,
        gymMultiplier: goodGymTolerance ? 1.08 : 1.00,
        plyometricMultiplier: goodReactiveTolerance ? 1.04 : 0.0,
        reason:
            'Alta adaptación confirmada: readiness, memoria adaptativa y tolerancia de densidad permiten expansión controlada.',
      );
    }

    if (readiness >= 78 &&
        injuryRisk < 40 &&
        acwr <= 1.22 &&
        !poorDensityTolerance &&
        !poorReactiveTolerance &&
        !needsConservativeTaper) {
      final targets = <TrainingProgressionTarget>[
        TrainingProgressionTarget.cyclingVolume,
      ];

      if (goodGymTolerance && !poorGymTolerance) {
        targets.add(TrainingProgressionTarget.gymStrength);
      }

      if (goodNeuralTolerance && !poorLactateTolerance) {
        targets.add(TrainingProgressionTarget.skatingIntensity);
      }

      return TrainingProgressionDecision(
        mode: TrainingProgressionMode.addSecondSession,
        targets: targets,
        recommendedSessions: 2,
        volumeMultiplier: goodDensityTolerance ? 1.05 : 1.02,
        intensityMultiplier: goodNeuralTolerance ? 1.02 : 1.00,
        gymMultiplier: goodGymTolerance ? 1.03 : 0.95,
        plyometricMultiplier: goodReactiveTolerance ? 0.65 : 0.0,
        reason:
            'Buena adaptación: se permite segunda sesión solo porque la memoria del atleta no muestra señales de mala tolerancia.',
      );
    }

    if (poorLactateTolerance ||
        poorReactiveTolerance ||
        needsConservativeTaper) {
      return TrainingProgressionDecision(
        mode: TrainingProgressionMode.smallProgression,
        targets: const [
          TrainingProgressionTarget.skatingVolume,
          TrainingProgressionTarget.recovery,
        ],
        recommendedSessions: 1,
        volumeMultiplier: 1.00,
        intensityMultiplier: poorLactateTolerance ? 0.90 : 0.96,
        gymMultiplier: poorGymTolerance ? 0.85 : 0.95,
        plyometricMultiplier: poorReactiveTolerance ? 0.0 : 0.40,
        reason:
            'Progresión conservadora: la memoria adaptativa limita lactato, pliometría o densidad antes de aumentar carga.',
      );
    }

    return TrainingProgressionDecision(
      mode: TrainingProgressionMode.smallProgression,
      targets: [
        TrainingProgressionTarget.skatingVolume,
        if (goodGymTolerance && !poorGymTolerance)
          TrainingProgressionTarget.gymStrength,
        if (goodReactiveTolerance) TrainingProgressionTarget.plyometrics,
      ],
      recommendedSessions: 1,
      volumeMultiplier: 1.03,
      intensityMultiplier: goodNeuralTolerance ? 1.01 : 1.00,
      gymMultiplier: goodGymTolerance ? 1.02 : 1.00,
      plyometricMultiplier: goodReactiveTolerance ? 0.55 : 0.0,
      reason:
          'Progresión pequeña guiada por memoria adaptativa, sin aumentar todo al mismo tiempo.',
    );
  }
}
