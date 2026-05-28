import 'adaptive_response_memory.dart';
import 'adaptive_response_memory_storage_service.dart';
import 'coach_plan_modification.dart';
import 'daily_athlete_log.dart';
import 'training_log_screen.dart';

class TrainingLogLearningAdapter {
  /// Procesa el registro del entrenador y actualiza la memoria adaptativa
  static Future<void> process({
    required String athleteId,
    required DailyAthleteLog log,
    required ComplianceLevel compliance,
    required SubjectiveFeel subjectiveFeel,
    required TechnicalQuality technicalQuality,
    required RecoveryStatus recoveryStatus,
    required SleepPerception sleepPerception,
    required MotivationLevel motivation,
    required IncidentType incident,
    required CoachDecision coachDecision,
    required List<CoachPlanModification> coachModifications,
    required Map<String, int> painAreas,
    required int rpe,
    required int neuralFatigue,
  }) async {
    // Cargar memoria actual
    var memory = await AdaptiveResponseMemoryStorageService.loadMemory(
      athleteId,
    );

    // Clasificar la respuesta general del día
    final response = _classifyResponse(
      compliance: compliance,
      subjectiveFeel: subjectiveFeel,
      painAreas: painAreas,
      neuralFatigue: neuralFatigue,
      rpe: rpe,
    );

    // Aprender de la sesión según el tipo de entrenamiento
    memory = _learnFromSession(memory: memory, log: log, response: response);
    memory = _learnFromHiddenStress(
      memory: memory,
      log: log,
      response: response,
    );

    // Aprender del dolor específico por zonas
    memory = _learnFromPainAreas(memory: memory, painAreas: painAreas);

    // Aprender de la calidad técnica
    memory = _learnFromTechnicalQuality(
      memory: memory,
      technicalQuality: technicalQuality,
    );

    // Aprender de la recuperación y sueño
    memory = _learnFromRecovery(
      memory: memory,
      recoveryStatus: recoveryStatus,
      sleepPerception: sleepPerception,
    );

    // Aprender de la decisión del entrenador (¡esto es CLAVE!)
    memory = _learnFromCoachDecision(
      memory: memory,
      coachDecision: coachDecision,
      response: response,
    );
    memory = _learnFromCoachModifications(
      memory: memory,
      modifications: coachModifications,
      response: response,
    );

    // Actualizar contadores de respuestas
    memory = memory.copyWith(
      positiveResponses:
          memory.positiveResponses +
          (response == _TrainingResponse.good ? 1 : 0),
      negativeResponses:
          memory.negativeResponses +
          (response == _TrainingResponse.poor ? 1 : 0),
      lastUpdated: DateTime.now(),
    );

    // Guardar memoria actualizada
    await AdaptiveResponseMemoryStorageService.saveMemory(memory);
  }

  /// Clasifica la respuesta general del día
  static _TrainingResponse _classifyResponse({
    required ComplianceLevel compliance,
    required SubjectiveFeel subjectiveFeel,
    required Map<String, int> painAreas,
    required int neuralFatigue,
    required int rpe,
  }) {
    // Si no completó la sesión → respuesta pobre
    if (compliance != ComplianceLevel.full) {
      return _TrainingResponse.poor;
    }

    // Si hay dolor significativo (≥5 en alguna área) → respuesta pobre
    if (painAreas.values.any((severity) => severity >= 5)) {
      return _TrainingResponse.poor;
    }

    // Si fatiga neuromuscular alta (≥8) → respuesta pobre
    if (neuralFatigue >= 8) {
      return _TrainingResponse.poor;
    }

    // Si RPE muy alto (≥9) → respuesta pobre
    if (rpe >= 9) {
      return _TrainingResponse.poor;
    }

    // Si todo excelente → respuesta buena
    if (subjectiveFeel == SubjectiveFeel.excellent &&
        neuralFatigue <= 3 &&
        rpe <= 6 &&
        !painAreas.values.any((severity) => severity >= 2)) {
      return _TrainingResponse.good;
    }

    return _TrainingResponse.neutral;
  }

  /// Aprende del tipo de sesión realizada
  static AdaptiveResponseMemory _learnFromSession({
    required AdaptiveResponseMemory memory,
    required DailyAthleteLog log,
    required _TrainingResponse response,
  }) {
    var sprintTol = memory.sprintTolerance;
    var lactateTol = memory.lactateTolerance;
    var doubleSessionTol = memory.doubleSessionTolerance;
    var z5Tol = memory.z5Tolerance;

    final sessionType = log.performedSessionType.toLowerCase();

    final isSprint =
        sessionType.contains('speed') ||
        sessionType.contains('sprint') ||
        sessionType.contains('velocidad') ||
        sessionType.contains('aceleracion');

    final isLactate =
        sessionType.contains('lactate') ||
        sessionType.contains('lactato') ||
        sessionType.contains('anaerobic') ||
        log.highIntensityMinutes >= 25;

    final isDoubleSession =
        log.performedMinutes >= 100 || log.performedLoad >= 85;

    final hasZ5 = log.zone5Minutes >= 8;

    if (isSprint) {
      sprintTol = _adjustTolerance(sprintTol, response);
    }

    if (isLactate) {
      lactateTol = _adjustTolerance(lactateTol, response);
    }

    if (isDoubleSession) {
      doubleSessionTol = _adjustTolerance(doubleSessionTol, response);
    }

    if (hasZ5) {
      z5Tol = _adjustTolerance(z5Tol, response);
    }

    return memory.copyWith(
      sprintTolerance: sprintTol,
      lactateTolerance: lactateTol,
      doubleSessionTolerance: doubleSessionTol,
      z5Tolerance: z5Tol,
    );
  }

  /// Aprende del estrés corporal oculto
  static AdaptiveResponseMemory _learnFromHiddenStress({
    required AdaptiveResponseMemory memory,
    required DailyAthleteLog log,
    required _TrainingResponse response,
  }) {
    var updated = memory;

    // ===================================================
    // ESTRÉS NEURAL OCULTO
    // ===================================================

    if (log.neuralStress >= 75) {
      updated = updated.copyWith(
        sprintTolerance: (updated.sprintTolerance - 0.02).clamp(0.70, 1.30),
        z5Tolerance: (updated.z5Tolerance - 0.02).clamp(0.70, 1.30),
      );
    } else if (log.neuralStress <= 45 && response == _TrainingResponse.good) {
      updated = updated.copyWith(
        sprintTolerance: (updated.sprintTolerance + 0.008).clamp(0.70, 1.30),
      );
    }

    // ===================================================
    // ESTRÉS MECÁNICO / TERRENO
    // ===================================================

    if (log.mechanicalStress >= 75 || log.terrainStress >= 75) {
      updated = updated.copyWith(
        jumpTolerance: (updated.jumpTolerance - 0.018).clamp(0.70, 1.30),
        gymTolerance: (updated.gymTolerance - 0.01).clamp(0.70, 1.30),
      );
    }

    // ===================================================
    // INTERMITENCIAS Y CAMBIOS DE RITMO
    // ===================================================

    if (log.intermittentStress >= 75) {
      updated = updated.copyWith(
        sprintTolerance: (updated.sprintTolerance - 0.015).clamp(0.70, 1.30),
        doubleSessionTolerance: (updated.doubleSessionTolerance - 0.012).clamp(
          0.70,
          1.30,
        ),
      );
    } else if (log.intermittentStress <= 45 &&
        response == _TrainingResponse.good) {
      updated = updated.copyWith(
        sprintTolerance: (updated.sprintTolerance + 0.006).clamp(0.70, 1.30),
      );
    }

    // ===================================================
    // COSTE DE RECUPERACIÓN
    // ===================================================

    if (log.recoveryCost >= 80) {
      updated = updated.copyWith(
        taperResponse: (updated.taperResponse - 0.02).clamp(0.70, 1.30),
        doubleSessionTolerance: (updated.doubleSessionTolerance - 0.02).clamp(
          0.70,
          1.30,
        ),
      );
    } else if (log.recoveryCost <= 45 && response == _TrainingResponse.good) {
      updated = updated.copyWith(
        taperResponse: (updated.taperResponse + 0.008).clamp(0.70, 1.30),
      );
    }

    // ===================================================
    // ESTRÉS OCULTO TOTAL
    // ===================================================

    if (log.hiddenBodyStress >= 85) {
      updated = updated.copyWith(
        sprintTolerance: (updated.sprintTolerance - 0.015).clamp(0.70, 1.30),
        lactateTolerance: (updated.lactateTolerance - 0.015).clamp(0.70, 1.30),
        jumpTolerance: (updated.jumpTolerance - 0.015).clamp(0.70, 1.30),
        doubleSessionTolerance: (updated.doubleSessionTolerance - 0.015).clamp(
          0.70,
          1.30,
        ),
      );
    }

    // ===================================================
    // RESPUESTA POSITIVA A CARGA COMPLEJA
    // ===================================================

    if (response == _TrainingResponse.good &&
        log.hiddenBodyStress >= 60 &&
        log.recoveryCost < 65) {
      updated = updated.copyWith(
        sprintTolerance: (updated.sprintTolerance + 0.006).clamp(0.70, 1.30),
        doubleSessionTolerance: (updated.doubleSessionTolerance + 0.006).clamp(
          0.70,
          1.30,
        ),
      );
    }

    return updated;
  }

  /// Aprende del dolor en áreas específicas
  static AdaptiveResponseMemory _learnFromPainAreas({
    required AdaptiveResponseMemory memory,
    required Map<String, int> painAreas,
  }) {
    var updated = memory;

    // Dolor de rodilla → reducir tolerancia a saltos/pliometría
    final kneePain = painAreas['Rodilla'] ?? 0;
    if (kneePain >= 4) {
      updated = updated.copyWith(
        jumpTolerance: (updated.jumpTolerance - 0.03).clamp(0.70, 1.30),
      );
    }

    // Dolor lumbar → reducir tolerancia a gimnasio/fuerza pesada
    final lumbarPain = painAreas['Lumbar'] ?? 0;
    if (lumbarPain >= 4) {
      updated = updated.copyWith(
        gymTolerance: (updated.gymTolerance - 0.03).clamp(0.70, 1.30),
      );
    }

    // Dolor aductores → reducir tolerancia a velocidad/sprint
    final adductorPain = painAreas['Aductores'] ?? 0;
    if (adductorPain >= 4) {
      updated = updated.copyWith(
        sprintTolerance: (updated.sprintTolerance - 0.025).clamp(0.70, 1.30),
      );
    }

    // Dolor tobillo/Aquiles → reducir tolerancia a Z5 y saltos
    final anklePain = painAreas['Tobillo'] ?? 0;
    if (anklePain >= 4) {
      updated = updated.copyWith(
        z5Tolerance: (updated.z5Tolerance - 0.03).clamp(0.70, 1.30),
        jumpTolerance: (updated.jumpTolerance - 0.02).clamp(0.70, 1.30),
      );
    }

    return updated;
  }

  /// Aprende de la calidad técnica
  static AdaptiveResponseMemory _learnFromTechnicalQuality({
    required AdaptiveResponseMemory memory,
    required TechnicalQuality technicalQuality,
  }) {
    var updated = memory;

    if (technicalQuality == TechnicalQuality.poor) {
      updated = updated.copyWith(
        sprintTolerance: (updated.sprintTolerance - 0.02).clamp(0.70, 1.30),
        z5Tolerance: (updated.z5Tolerance - 0.02).clamp(0.70, 1.30),
      );
    }

    if (technicalQuality == TechnicalQuality.excellent) {
      updated = updated.copyWith(
        sprintTolerance: (updated.sprintTolerance + 0.01).clamp(0.70, 1.30),
      );
    }

    return updated;
  }

  /// Aprende de la recuperación y sueño percibido
  static AdaptiveResponseMemory _learnFromRecovery({
    required AdaptiveResponseMemory memory,
    required RecoveryStatus recoveryStatus,
    required SleepPerception sleepPerception,
  }) {
    var updated = memory;

    if (recoveryStatus == RecoveryStatus.loaded) {
      updated = updated.copyWith(
        taperResponse: (updated.taperResponse - 0.015).clamp(0.70, 1.30),
        doubleSessionTolerance: (updated.doubleSessionTolerance - 0.02).clamp(
          0.70,
          1.30,
        ),
      );
    }

    if (recoveryStatus == RecoveryStatus.recovered) {
      updated = updated.copyWith(
        taperResponse: (updated.taperResponse + 0.01).clamp(0.70, 1.30),
      );
    }

    if (sleepPerception == SleepPerception.poor) {
      updated = updated.copyWith(
        taperResponse: (updated.taperResponse - 0.01).clamp(0.70, 1.30),
        doubleSessionTolerance: (updated.doubleSessionTolerance - 0.015).clamp(
          0.70,
          1.30,
        ),
      );
    }

    return updated;
  }

  /// APRENDIZAJE CLAVE: de la decisión del entrenador
  static AdaptiveResponseMemory _learnFromCoachDecision({
    required AdaptiveResponseMemory memory,
    required CoachDecision coachDecision,
    required _TrainingResponse response,
  }) {
    var updated = memory;

    switch (coachDecision) {
      case CoachDecision.maintain:
        // El entrenador mantiene plan → respuesta neutral o buena
        break;

      case CoachDecision.reduceLoad:
        // El entrenador decidió bajar carga → probablemente el atleta estaba fatigado
        if (response == _TrainingResponse.good) {
          // A pesar de bajar carga, el atleta respondió bien → tal vez es sensible
          updated = updated.copyWith(
            doubleSessionTolerance: (updated.doubleSessionTolerance - 0.01)
                .clamp(0.70, 1.30),
          );
        }
        break;

      case CoachDecision.increaseLoad:
        // El entrenador decidió subir carga → el atleta toleró bien
        if (response == _TrainingResponse.good) {
          updated = updated.copyWith(
            sprintTolerance: (updated.sprintTolerance + 0.015).clamp(
              0.70,
              1.30,
            ),
            lactateTolerance: (updated.lactateTolerance + 0.01).clamp(
              0.70,
              1.30,
            ),
          );
        }
        break;

      case CoachDecision.recovery:
        // El entrenador prioriza recuperación → señal de fatiga
        updated = updated.copyWith(
          taperResponse: (updated.taperResponse - 0.01).clamp(0.70, 1.30),
        );
        break;

      case CoachDecision.easyTechnique:
        // El entrenador prioriza técnica suave → tal vez el atleta estaba rígido
        updated = updated.copyWith(
          sprintTolerance: (updated.sprintTolerance - 0.01).clamp(0.70, 1.30),
        );
        break;

      case CoachDecision.blockIntensity:
        // El entrenador bloquea intensidad → clara señal de fatiga/riesgo
        updated = updated.copyWith(
          z5Tolerance: (updated.z5Tolerance - 0.02).clamp(0.70, 1.30),
          sprintTolerance: (updated.sprintTolerance - 0.015).clamp(0.70, 1.30),
        );
        break;
    }

    return updated;
  }

  static AdaptiveResponseMemory _learnFromCoachModifications({
    required AdaptiveResponseMemory memory,
    required List<CoachPlanModification> modifications,
    required _TrainingResponse response,
  }) {
    if (modifications.isEmpty) return memory;

    var updated = memory;

    final addedBlocks = modifications.where((item) => item.addedBlock).length;
    final removedBlocks = modifications
        .where((item) => item.removedBlock)
        .length;

    final increasedLoad = modifications.any(
      (item) => item.increasedMeaningfulLoad,
    );

    final reducedLoad = modifications.any((item) => item.reducedMeaningfulLoad);

    final addedSpeed = modifications.any(
      (item) => item.addedBlock && item.targetsSpeed,
    );

    final addedStrength = modifications.any(
      (item) => item.addedBlock && item.targetsStrength,
    );

    final addedPlyometric = modifications.any(
      (item) => item.addedBlock && item.targetsPlyometric,
    );

    final addedRecovery = modifications.any(
      (item) => item.addedBlock && item.targetsRecovery,
    );

    final addedLactate = modifications.any(
      (item) => item.addedBlock && item.targetsLactate,
    );

    final madeDoubleSession = addedBlocks >= 1 && modifications.length >= 1;

    if (response == _TrainingResponse.good) {
      if (increasedLoad) {
        updated = updated.copyWith(
          sprintTolerance: (updated.sprintTolerance + 0.012).clamp(0.70, 1.30),
          lactateTolerance: (updated.lactateTolerance + 0.008).clamp(
            0.70,
            1.30,
          ),
        );
      }

      if (addedStrength) {
        updated = updated.copyWith(
          gymTolerance: (updated.gymTolerance + 0.015).clamp(0.70, 1.30),
        );
      }

      if (addedSpeed) {
        updated = updated.copyWith(
          sprintTolerance: (updated.sprintTolerance + 0.018).clamp(0.70, 1.30),
        );
      }

      if (addedPlyometric) {
        updated = updated.copyWith(
          jumpTolerance: (updated.jumpTolerance + 0.012).clamp(0.70, 1.30),
        );
      }

      if (addedLactate) {
        updated = updated.copyWith(
          lactateTolerance: (updated.lactateTolerance + 0.012).clamp(
            0.70,
            1.30,
          ),
        );
      }

      if (madeDoubleSession) {
        updated = updated.copyWith(
          doubleSessionTolerance: (updated.doubleSessionTolerance + 0.01).clamp(
            0.70,
            1.30,
          ),
        );
      }

      if (addedRecovery) {
        updated = updated.copyWith(
          taperResponse: (updated.taperResponse + 0.006).clamp(0.70, 1.30),
        );
      }
    }

    if (response == _TrainingResponse.poor) {
      if (increasedLoad) {
        updated = updated.copyWith(
          sprintTolerance: (updated.sprintTolerance - 0.018).clamp(0.70, 1.30),
          lactateTolerance: (updated.lactateTolerance - 0.014).clamp(
            0.70,
            1.30,
          ),
          doubleSessionTolerance: (updated.doubleSessionTolerance - 0.012)
              .clamp(0.70, 1.30),
        );
      }

      if (addedStrength) {
        updated = updated.copyWith(
          gymTolerance: (updated.gymTolerance - 0.018).clamp(0.70, 1.30),
        );
      }

      if (addedSpeed) {
        updated = updated.copyWith(
          sprintTolerance: (updated.sprintTolerance - 0.02).clamp(0.70, 1.30),
        );
      }

      if (addedPlyometric) {
        updated = updated.copyWith(
          jumpTolerance: (updated.jumpTolerance - 0.02).clamp(0.70, 1.30),
        );
      }

      if (addedLactate) {
        updated = updated.copyWith(
          lactateTolerance: (updated.lactateTolerance - 0.02).clamp(0.70, 1.30),
        );
      }

      if (madeDoubleSession) {
        updated = updated.copyWith(
          doubleSessionTolerance: (updated.doubleSessionTolerance - 0.018)
              .clamp(0.70, 1.30),
        );
      }
    }

    if (reducedLoad && response == _TrainingResponse.good) {
      updated = updated.copyWith(
        taperResponse: (updated.taperResponse + 0.006).clamp(0.70, 1.30),
      );
    }

    return updated;
  }

  /// Ajusta una tolerancia según la respuesta
  static double _adjustTolerance(double current, _TrainingResponse response) {
    switch (response) {
      case _TrainingResponse.good:
        return (current + 0.015).clamp(0.70, 1.30).toDouble();
      case _TrainingResponse.poor:
        return (current - 0.025).clamp(0.70, 1.30).toDouble();
      case _TrainingResponse.neutral:
        return current;
    }
  }
}

enum _TrainingResponse { good, neutral, poor }
