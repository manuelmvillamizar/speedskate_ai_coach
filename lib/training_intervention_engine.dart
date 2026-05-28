import 'athlete_adaptation_layer.dart';
import 'athlete_performance_context.dart';
import 'athlete_program_service.dart';
import 'daily_training_block.dart';
import 'integrated_training_day.dart';
import 'physiology/models/strength_load_state.dart';

enum InterventionLevel { none, caution, moderate, severe, critical }

class TrainingInterventionResult {
  final InterventionLevel level;
  final bool blockHighIntensity;
  final bool reduceVolume;
  final bool forceRecovery;
  final bool blockDoubleSession;
  final bool blockHeavyStrength;
  final bool protectCompetition;

  final bool protectTendon;
  final bool protectNeuralSystem;
  final bool reduceReactiveContacts;

  final String summary;
  final List<String> warnings;

  const TrainingInterventionResult({
    required this.level,
    required this.blockHighIntensity,
    required this.reduceVolume,
    required this.forceRecovery,
    required this.blockDoubleSession,
    required this.blockHeavyStrength,
    required this.protectCompetition,
    this.protectTendon = false,
    this.protectNeuralSystem = false,
    this.reduceReactiveContacts = false,
    required this.summary,
    required this.warnings,
  });

  Map<String, dynamic> toMap() {
    return {
      'level': level.name,
      'blockHighIntensity': blockHighIntensity,
      'reduceVolume': reduceVolume,
      'forceRecovery': forceRecovery,
      'blockDoubleSession': blockDoubleSession,
      'blockHeavyStrength': blockHeavyStrength,
      'protectCompetition': protectCompetition,
      'protectTendon': protectTendon,
      'protectNeuralSystem': protectNeuralSystem,
      'reduceReactiveContacts': reduceReactiveContacts,
      'summary': summary,
      'warnings': warnings,
    };
  }

  factory TrainingInterventionResult.fromMap(Map<String, dynamic> map) {
    return TrainingInterventionResult(
      level: InterventionLevel.values.firstWhere(
        (item) => item.name == map['level']?.toString(),
        orElse: () => InterventionLevel.none,
      ),
      blockHighIntensity: map['blockHighIntensity'] == true,
      reduceVolume: map['reduceVolume'] == true,
      forceRecovery: map['forceRecovery'] == true,
      blockDoubleSession: map['blockDoubleSession'] == true,
      blockHeavyStrength: map['blockHeavyStrength'] == true,
      protectCompetition: map['protectCompetition'] == true,
      protectTendon: map['protectTendon'] == true,
      protectNeuralSystem: map['protectNeuralSystem'] == true,
      reduceReactiveContacts: map['reduceReactiveContacts'] == true,
      summary: map['summary']?.toString() ?? '',
      warnings: List<String>.from(
        (map['warnings'] as List<dynamic>? ?? []).map(
          (item) => item.toString(),
        ),
      ),
    );
  }
}

class _SkatingInterventionThresholds {
  final int highIntensityMinutesTodayModerate;
  final int highIntensityMinutesTodaySevere;
  final int highIntensityMinutes7DaysModerate;
  final int highIntensityMinutes7DaysSevere;
  final int highIntensityMinutes7DaysCritical;

  final int zone5Minutes7DaysModerate;
  final int zone5Minutes7DaysSevere;
  final int zone5Minutes7DaysCritical;

  final int neuralDays7DaysModerate;
  final int neuralDays7DaysSevere;
  final int neuralDays7DaysCritical;

  final int reactiveBlocksTodayLimit;
  final int neuralBlocksTodayLimit;
  final int lactateBlocksTodayLimit;

  final double highIntensityRatioTodayModerate;
  final double highIntensityRatioTodaySevere;

  const _SkatingInterventionThresholds({
    required this.highIntensityMinutesTodayModerate,
    required this.highIntensityMinutesTodaySevere,
    required this.highIntensityMinutes7DaysModerate,
    required this.highIntensityMinutes7DaysSevere,
    required this.highIntensityMinutes7DaysCritical,
    required this.zone5Minutes7DaysModerate,
    required this.zone5Minutes7DaysSevere,
    required this.zone5Minutes7DaysCritical,
    required this.neuralDays7DaysModerate,
    required this.neuralDays7DaysSevere,
    required this.neuralDays7DaysCritical,
    required this.reactiveBlocksTodayLimit,
    required this.neuralBlocksTodayLimit,
    required this.lactateBlocksTodayLimit,
    required this.highIntensityRatioTodayModerate,
    required this.highIntensityRatioTodaySevere,
  });
}

class TrainingInterventionEngine {
  static TrainingInterventionResult analyze({
    required AthletePerformanceContext context,
    required IntegratedTrainingDay day,
    StrengthLoadState strengthLoadState = const StrengthLoadState(
      externalStrengthLoadKg: 0,
      reactiveJumpLoadKg: 0,
      totalMechanicalLoadKg: 0,
      neuralStress: 0,
      muscleStress: 0,
      tendonStress: 0,
      adaptationSignal: 'none',
    ),
  }) {
    final athlete = context.athlete;
    final readiness = context.currentReadiness;
    final fatigue = context.currentFatigueStatus;
    final injuryRisk = context.currentInjuryRisk;
    final acwr = context.acwr;
    final profile = context.physiologyProfile;
    final adaptation = AthleteAdaptationLayer.build(context);

    final thresholds = _adaptThresholds(
      _thresholdsForAthlete(athlete.type),
      adaptation,
    );

    final warnings = <String>[];

    bool blockHighIntensity = false;
    bool reduceVolume = false;
    bool forceRecovery = false;
    bool blockDoubleSession = false;
    bool blockHeavyStrength = false;
    bool protectCompetition = false;

    bool protectTendon = false;
    bool protectNeuralSystem = false;
    bool reduceReactiveContacts = false;

    InterventionLevel level = InterventionLevel.none;

    void raiseLevel(InterventionLevel newLevel) {
      if (level.index < newLevel.index) {
        level = newLevel;
      }
    }

    final highIntensityBlocks = day.blocks.where(_isHighIntensityBlock).length;
    final heavyStrengthBlocks = day.blocks.where(_isHeavyStrengthBlock).length;
    final plyometricBlocks = day.blocks.where(_isReactiveBlock).length;
    final highNeuromuscularBlocks = day.blocks.where(_isNeuralBlock).length;
    final lactateBlocks = day.blocks.where(_isMetabolicBlock).length;
    final speedBlocks = day.blocks.where((block) => block.isSpeedStimulus).length;

    final neuralLoadToday = _estimatedNeuralLoad(day.blocks);
    final metabolicLoadToday = _estimatedMetabolicLoad(day.blocks);
    final reactiveLoadToday = _estimatedReactiveLoad(day.blocks);

    final strengthNeuralStress = strengthLoadState.neuralStress;
    final strengthTendonStress = strengthLoadState.tendonStress;
    final strengthMuscleStress = strengthLoadState.muscleStress;

    final highIntensityMinutesToday = _todayHighIntensityMinutes(context);
    final highIntensityRatioToday = _todayHighIntensityRatio(context);
    final highIntensityMinutes7Days = _highIntensityMinutesLastDays(context, 7);
    final highIntensityMinutes28Days = _highIntensityMinutesLastDays(
      context,
      28,
    );
    final zone5Minutes7Days = _zone5MinutesLastDays(context, 7);
    final neuralDays7Days = _estimatedNeuralDaysLast7(context);
    final metabolicDays7Days = _estimatedMetabolicDaysLast7(context);

    final isSprinter = athlete.type == AthleteProgramType.sprinter;
    final isEndurance = athlete.type == AthleteProgramType.endurance;
    final isMixed = athlete.type == AthleteProgramType.mixed;

    final taperOrCompetition = day.taperMode || day.expectedFatigue == 'yellow';

    if (adaptation.toleratesNeuralLoad) {
      warnings.add(
        'Adaptación individual: el atleta tolera mejor carga neural.',
      );
    }

    if (adaptation.strugglesWithLactate) {
      warnings.add(
        'Adaptación individual: sensibilidad alta a lactato detectada.',
      );
    }

    if (adaptation.needsLongerTaper) {
      warnings.add(
        'Adaptación individual: se recomienda taper más conservador.',
      );
    }

    if (adaptation.needsReactiveProtection) {
      warnings.add(
        'Adaptación individual: se requiere protección extra de pliometría/reactividad.',
      );
    }

    if (adaptation.toleratesDoubleIntensity) {
      warnings.add(
        'Adaptación individual: buena tolerancia a densidad de intensidad.',
      );
    }

    if (strengthNeuralStress >= 70) {
      warnings.add(
        'Estrés neural elevado detectado desde fuerza/saltos. Proteger sistema nervioso.',
      );

      protectNeuralSystem = true;
      blockHeavyStrength = true;
      reduceVolume = true;

      raiseLevel(InterventionLevel.severe);
    }

    if (strengthNeuralStress >= 85) {
      warnings.add(
        'Estrés neural crítico. Bloquear velocidad máxima, fuerza pesada y pliometría.',
      );

      protectNeuralSystem = true;
      blockHighIntensity = true;
      blockHeavyStrength = true;
      blockDoubleSession = true;
      reduceVolume = true;

      raiseLevel(InterventionLevel.critical);
    }

    if (strengthTendonStress >= 65) {
      warnings.add(
        'Estrés tendinoso elevado. Reducir contactos reactivos y pliometría.',
      );

      protectTendon = true;
      reduceReactiveContacts = true;
      reduceVolume = true;

      raiseLevel(InterventionLevel.severe);
    }

    if (strengthTendonStress >= 85) {
      warnings.add(
        'Estrés tendinoso crítico. Bloquear saltos reactivos y fuerza explosiva.',
      );

      protectTendon = true;
      reduceReactiveContacts = true;
      blockHeavyStrength = true;
      reduceVolume = true;

      raiseLevel(InterventionLevel.critical);
    }

    if (strengthMuscleStress >= 80 && readiness < 65) {
      warnings.add(
        'Fatiga muscular alta con baja recuperación. Reducir fuerza y volumen.',
      );

      blockHeavyStrength = true;
      reduceVolume = true;

      raiseLevel(InterventionLevel.severe);
    }

    if (strengthLoadState.requiresRecovery) {
      warnings.add(
        'Carga de fuerza/saltos requiere recuperación adicional según respuesta mecánica.',
      );

      reduceVolume = true;

      if (strengthNeuralStress >= 75 || strengthTendonStress >= 75) {
        blockHeavyStrength = true;
      }

      raiseLevel(InterventionLevel.severe);
    }

    if (readiness < 60) {
      warnings.add('Readiness bajo. Reducir volumen y controlar intensidad.');
      reduceVolume = true;
      raiseLevel(InterventionLevel.moderate);
    }

    if (readiness < 50) {
      warnings.add(
        'Readiness muy bajo. Bloquear Z4/Z5, fuerza pesada y trabajo máximo.',
      );
      blockHighIntensity = true;
      reduceVolume = true;
      blockHeavyStrength = true;
      raiseLevel(InterventionLevel.severe);
    }

    if (readiness < 40) {
      warnings.add('Readiness crítico. Se fuerza recuperación.');
      blockHighIntensity = true;
      reduceVolume = true;
      forceRecovery = true;
      blockDoubleSession = true;
      blockHeavyStrength = true;
      raiseLevel(InterventionLevel.critical);
    }

    if (fatigue == 'orange') {
      warnings.add(
        'Fatiga naranja. Evitar intensidad máxima, lactato pesado y doble sesión.',
      );
      blockHighIntensity = true;
      reduceVolume = true;
      blockDoubleSession = true;
      raiseLevel(InterventionLevel.severe);
    }

    if (fatigue == 'red') {
      warnings.add('Fatiga roja. Recuperación obligatoria.');
      blockHighIntensity = true;
      reduceVolume = true;
      forceRecovery = true;
      blockDoubleSession = true;
      blockHeavyStrength = true;
      raiseLevel(InterventionLevel.critical);
    }

    if (injuryRisk > 50) {
      warnings.add('Riesgo de lesión elevado. Reducir carga total.');
      reduceVolume = true;
      raiseLevel(InterventionLevel.moderate);
    }

    if (injuryRisk > 70) {
      warnings.add(
        'Riesgo de lesión alto. Bloquear intensidad alta y fuerza pesada.',
      );
      blockHighIntensity = true;
      blockHeavyStrength = true;
      reduceVolume = true;
      raiseLevel(InterventionLevel.severe);
    }

    if (injuryRisk > 82) {
      warnings.add('Riesgo de lesión crítico. Se fuerza recuperación.');
      blockHighIntensity = true;
      blockHeavyStrength = true;
      blockDoubleSession = true;
      reduceVolume = true;
      forceRecovery = true;
      raiseLevel(InterventionLevel.critical);
    }

    if (acwr > 1.35) {
      warnings.add('ACWR elevado. Limitar progresión de carga.');
      reduceVolume = true;
      raiseLevel(InterventionLevel.moderate);
    }

    if (acwr > 1.55) {
      warnings.add(
        'ACWR muy alto. Bloquear intensidad y proteger recuperación.',
      );
      blockHighIntensity = true;
      reduceVolume = true;
      blockDoubleSession = true;
      raiseLevel(InterventionLevel.severe);
    }

    if (context.possibleOvertraining) {
      warnings.add('Posible sobreentrenamiento detectado.');
      blockHighIntensity = true;
      reduceVolume = true;
      forceRecovery = true;
      blockDoubleSession = true;
      blockHeavyStrength = true;
      raiseLevel(InterventionLevel.critical);
    }

    if (context.needsRecoveryBlock) {
      warnings.add(
        'Varios días con baja recuperación. Se recomienda bloque regenerativo.',
      );
      blockHighIntensity = true;
      reduceVolume = true;
      blockDoubleSession = true;
      raiseLevel(InterventionLevel.severe);
    }

    if (adaptation.strugglesWithLactate && lactateBlocks > 0) {
      warnings.add(
        'El atleta muestra sensibilidad a lactato: se bloquea estímulo lactácido.',
      );
      blockHighIntensity = true;
      reduceVolume = true;
      raiseLevel(InterventionLevel.severe);
    }

    if (adaptation.needsReactiveProtection && plyometricBlocks > 0) {
      warnings.add(
        'El atleta necesita protección reactiva: se limita pliometría.',
      );
      blockHeavyStrength = true;
      reduceReactiveContacts = true;
      protectTendon = true;
      reduceVolume = true;
      raiseLevel(InterventionLevel.severe);
    }

    if (adaptation.needsLongerTaper && day.taperMode) {
      warnings.add(
        'Taper individual ampliado: se reduce carga residual adicional.',
      );
      protectCompetition = true;
      reduceVolume = true;
      raiseLevel(InterventionLevel.moderate);
    }

    if (!adaptation.toleratesDoubleIntensity && day.hasDoubleSession) {
      warnings.add(
        'El atleta no tolera alta densidad: se bloquea doble sesión.',
      );
      blockDoubleSession = true;
      reduceVolume = true;
      raiseLevel(InterventionLevel.severe);
    }

    if (adaptation.toleratesNeuralLoad &&
        speedBlocks > 0 &&
        readiness >= 70 &&
        injuryRisk < 60 &&
        !forceRecovery &&
        strengthNeuralStress < 70) {
      warnings.add(
        'Carga neural permitida por buena respuesta individual del atleta.',
      );

      if (level == InterventionLevel.none) {
        raiseLevel(InterventionLevel.caution);
      }
    }

    if (profile.shouldReduceLoad()) {
      warnings.add('Perfil fisiológico sensible. Reducir carga total.');
      reduceVolume = true;
      raiseLevel(InterventionLevel.moderate);
    }

    if (profile.shouldBlockIntensity()) {
      warnings.add('Perfil fisiológico indica bloquear intensidad.');
      blockHighIntensity = true;
      raiseLevel(InterventionLevel.severe);
    }

    if (profile.needsRecoveryMicrocycle()) {
      warnings.add('Perfil fisiológico sugiere microciclo de recuperación.');
      blockHighIntensity = true;
      reduceVolume = true;
      blockDoubleSession = true;
      raiseLevel(InterventionLevel.severe);
    }

    if (neuralLoadToday >= 2 && readiness < 70) {
      warnings.add(
        'Carga neural alta con readiness insuficiente. Proteger velocidad máxima, salidas y pliometría.',
      );
      protectNeuralSystem = true;
      blockHeavyStrength = true;
      reduceVolume = true;
      raiseLevel(InterventionLevel.severe);
    }

    if (metabolicLoadToday >= 2 && readiness < 75) {
      warnings.add(
        'Carga metabólica/lactácida alta para el estado actual. Reducir lactato y Z4/Z5.',
      );
      blockHighIntensity = true;
      reduceVolume = true;
      raiseLevel(InterventionLevel.severe);
    }

    if (reactiveLoadToday > thresholds.reactiveBlocksTodayLimit) {
      warnings.add(
        'Pliometría/reactividad excesiva para el día. Proteger tendón rotuliano, Aquiles y tibiales.',
      );
      protectTendon = true;
      reduceReactiveContacts = true;
      blockHeavyStrength = true;
      reduceVolume = true;
      raiseLevel(InterventionLevel.severe);
    }

    if (highNeuromuscularBlocks > thresholds.neuralBlocksTodayLimit) {
      warnings.add('Demasiados bloques neurales en el día.');
      protectNeuralSystem = true;
      blockHeavyStrength = true;
      reduceVolume = true;
      raiseLevel(InterventionLevel.severe);
    }

    if (lactateBlocks > thresholds.lactateBlocksTodayLimit) {
      warnings.add('Demasiados bloques lactácidos/metabólicos en el día.');
      blockHighIntensity = true;
      reduceVolume = true;
      raiseLevel(InterventionLevel.severe);
    }

    if (neuralDays7Days >= thresholds.neuralDays7DaysModerate) {
      warnings.add(
        'Acumulación de días neurales en la semana. Controlar salidas, velocidad máxima, fuerza pesada y pliometría.',
      );
      reduceVolume = true;
      raiseLevel(InterventionLevel.moderate);
    }

    if (neuralDays7Days >= thresholds.neuralDays7DaysSevere) {
      warnings.add(
        'Demasiados días neurales recientes. Bloquear carga neuromuscular alta.',
      );
      protectNeuralSystem = true;
      blockHeavyStrength = true;
      reduceVolume = true;
      raiseLevel(InterventionLevel.severe);
    }

    if (neuralDays7Days >= thresholds.neuralDays7DaysCritical) {
      warnings.add('Secuencia neural crítica. Forzar descarga relativa.');
      protectNeuralSystem = true;
      blockHighIntensity = true;
      blockHeavyStrength = true;
      blockDoubleSession = true;
      reduceVolume = true;
      raiseLevel(InterventionLevel.critical);
    }

    if (metabolicDays7Days >= 3 && lactateBlocks > 0) {
      warnings.add(
        'Exceso de días metabólicos recientes. Bloquear nuevo estímulo lactácido.',
      );
      blockHighIntensity = true;
      reduceVolume = true;
      raiseLevel(InterventionLevel.severe);
    }

    if (highIntensityRatioToday >= thresholds.highIntensityRatioTodayModerate) {
      warnings.add(
        'Ratio alto de Z4/Z5 hoy: ${(highIntensityRatioToday * 100).round()}%. Reducir intensidad.',
      );
      blockHighIntensity = true;
      reduceVolume = true;
      raiseLevel(InterventionLevel.moderate);
    }

    if (highIntensityRatioToday >= thresholds.highIntensityRatioTodaySevere) {
      warnings.add('Exceso severo de intensidad Z4/Z5 en el día.');
      blockHighIntensity = true;
      reduceVolume = true;
      blockDoubleSession = true;
      raiseLevel(InterventionLevel.severe);
    }

    if (highIntensityMinutesToday >= thresholds.highIntensityMinutesTodayModerate) {
      warnings.add('Muchos minutos Z4/Z5 hoy. Evitar más trabajo intenso.');
      blockHighIntensity = true;
      reduceVolume = true;
      raiseLevel(InterventionLevel.moderate);
    }

    if (highIntensityMinutesToday >= thresholds.highIntensityMinutesTodaySevere) {
      warnings.add(
        'Exceso de minutos intensos hoy. Bloquear intensidad adicional.',
      );
      blockHighIntensity = true;
      reduceVolume = true;
      blockDoubleSession = true;
      raiseLevel(InterventionLevel.severe);
    }

    if (highIntensityMinutes7Days >=
        thresholds.highIntensityMinutes7DaysModerate) {
      warnings.add(
        'Alta intensidad acumulada 7 días: $highIntensityMinutes7Days min Z4/Z5.',
      );
      blockHighIntensity = true;
      reduceVolume = true;
      raiseLevel(InterventionLevel.moderate);
    }

    if (highIntensityMinutes7Days >=
        thresholds.highIntensityMinutes7DaysSevere) {
      warnings.add('Alta intensidad semanal severa. Bloquear intensidad alta.');
      blockHighIntensity = true;
      reduceVolume = true;
      blockDoubleSession = true;
      raiseLevel(InterventionLevel.severe);
    }

    if (highIntensityMinutes7Days >=
        thresholds.highIntensityMinutes7DaysCritical) {
      warnings.add(
        'Exceso crítico de intensidad en 7 días. Bloquear intensidad y fuerza pesada.',
      );
      blockHighIntensity = true;
      reduceVolume = true;
      blockDoubleSession = true;
      blockHeavyStrength = true;
      protectNeuralSystem = true;
      raiseLevel(InterventionLevel.critical);
    }

    if (zone5Minutes7Days >= thresholds.zone5Minutes7DaysModerate) {
      warnings.add('Z5 acumulada elevada. Proteger sistema neuromuscular.');
      blockHighIntensity = true;
      protectNeuralSystem = true;
      raiseLevel(InterventionLevel.moderate);
    }

    if (zone5Minutes7Days >= thresholds.zone5Minutes7DaysSevere) {
      warnings.add(
        'Z5 acumulada severa. Bloquear nuevo trabajo máximo/lactácido.',
      );
      blockHighIntensity = true;
      blockHeavyStrength = true;
      protectNeuralSystem = true;
      reduceVolume = true;
      raiseLevel(InterventionLevel.severe);
    }

    if (zone5Minutes7Days >= thresholds.zone5Minutes7DaysCritical) {
      warnings.add('Z5 acumulada crítica. Forzar recuperación relativa.');
      blockHighIntensity = true;
      reduceVolume = true;
      blockDoubleSession = true;
      blockHeavyStrength = true;
      protectNeuralSystem = true;
      raiseLevel(InterventionLevel.critical);
    }

    if (highIntensityMinutes28Days >= 280) {
      warnings.add(
        'Carga intensa acumulada 28 días alta: $highIntensityMinutes28Days min Z4/Z5.',
      );
      reduceVolume = true;
      blockHighIntensity = true;
      raiseLevel(InterventionLevel.severe);
    }

    if (highIntensityBlocks >= 2 && readiness < 75) {
      warnings.add('Demasiados bloques intensos para el readiness actual.');
      blockHighIntensity = true;
      reduceVolume = true;
      raiseLevel(InterventionLevel.severe);
    }

    if (lactateBlocks > 0 &&
        highIntensityMinutes7Days >= thresholds.highIntensityMinutes7DaysModerate) {
      warnings.add(
        'Bloque lactácido no recomendado con alta intensidad acumulada.',
      );
      blockHighIntensity = true;
      reduceVolume = true;
      raiseLevel(InterventionLevel.severe);
    }

    if (heavyStrengthBlocks > 0 && readiness < 65) {
      warnings.add('Fuerza pesada bloqueada por readiness bajo.');
      blockHeavyStrength = true;
      reduceVolume = true;
      raiseLevel(InterventionLevel.severe);
    }

    if (heavyStrengthBlocks > 0 &&
        zone5Minutes7Days >= thresholds.zone5Minutes7DaysModerate) {
      warnings.add('Fuerza pesada bloqueada por exceso de Z5 acumulada.');
      blockHeavyStrength = true;
      protectNeuralSystem = true;
      raiseLevel(InterventionLevel.severe);
    }

    if (plyometricBlocks > 0 && readiness < 70) {
      warnings.add('Pliometría limitada por recuperación insuficiente.');
      blockHeavyStrength = true;
      reduceReactiveContacts = true;
      protectTendon = true;
      reduceVolume = true;
      raiseLevel(InterventionLevel.moderate);
    }

    if (day.hasDoubleSession && readiness < 70) {
      warnings.add('Doble sesión bloqueada por readiness insuficiente.');
      blockDoubleSession = true;
      reduceVolume = true;
      raiseLevel(InterventionLevel.severe);
    }

    if (day.hasDoubleSession &&
        highIntensityMinutes7Days >= thresholds.highIntensityMinutes7DaysModerate) {
      warnings.add(
        'Doble sesión bloqueada por alta intensidad semanal acumulada.',
      );
      blockDoubleSession = true;
      reduceVolume = true;
      raiseLevel(InterventionLevel.severe);
    }

    if (isSprinter) {
      if (lactateBlocks > 0 && readiness < 78) {
        warnings.add(
          'Velocista: lactato continuo bloqueado si no hay alta frescura.',
        );
        blockHighIntensity = true;
        reduceVolume = true;
        raiseLevel(InterventionLevel.severe);
      }

      if (speedBlocks > 0 &&
          readiness >= 72 &&
          injuryRisk < 55 &&
          neuralDays7Days < thresholds.neuralDays7DaysSevere &&
          strengthNeuralStress < 70 &&
          !forceRecovery) {
        warnings.add(
          'Velocista: se permite velocidad neural controlada si la calidad técnica se mantiene.',
        );
        if (level == InterventionLevel.none) {
          raiseLevel(InterventionLevel.caution);
        }
      }
    }

    if (isEndurance) {
      if (metabolicLoadToday >= 2 &&
          highIntensityMinutes7Days >= thresholds.highIntensityMinutes7DaysModerate) {
        warnings.add(
          'Fondista: exceso de carga metabólica acumulada. Reducir lactato y mantener técnica/aeróbico.',
        );
        blockHighIntensity = true;
        reduceVolume = true;
        raiseLevel(InterventionLevel.severe);
      }

      if (neuralLoadToday >= 2 &&
          neuralDays7Days >= thresholds.neuralDays7DaysModerate) {
        warnings.add(
          'Fondista: demasiada carga neural para la semana. Mantener velocidad corta o técnica, no máxima.',
        );
        blockHeavyStrength = true;
        protectNeuralSystem = true;
        reduceVolume = true;
        raiseLevel(InterventionLevel.severe);
      }
    }

    if (isMixed) {
      if (neuralLoadToday >= 2 && metabolicLoadToday >= 2) {
        warnings.add(
          'Mixto: demasiada combinación neural + metabólica en la misma jornada.',
        );
        blockHighIntensity = true;
        blockHeavyStrength = true;
        protectNeuralSystem = true;
        reduceVolume = true;
        raiseLevel(InterventionLevel.severe);
      }
    }

    if (taperOrCompetition) {
      if (lactateBlocks > 0 || heavyStrengthBlocks > 0) {
        warnings.add(
          'Taper protegido: eliminar lactato pesado y fuerza pesada.',
        );
        protectCompetition = true;
        blockHighIntensity = true;
        blockHeavyStrength = true;
        reduceVolume = true;
        raiseLevel(InterventionLevel.severe);
      }

      if (isSprinter && speedBlocks > 0 && readiness >= 65 && injuryRisk < 65) {
        warnings.add(
          'Taper sprint: conservar velocidad corta, reducir volumen y evitar fatiga residual.',
        );
        protectCompetition = true;
        reduceVolume = true;

        if (!forceRecovery && readiness >= 70 && strengthNeuralStress < 70) {
          blockHighIntensity = false;
        }

        raiseLevel(InterventionLevel.moderate);
      }

      if (isEndurance && speedBlocks > 0) {
        warnings.add(
          'Taper fondo: conservar remate corto, sin convertirlo en sesión intensa.',
        );
        protectCompetition = true;
        reduceVolume = true;
        raiseLevel(InterventionLevel.moderate);
      }

      if (highIntensityMinutes7Days >=
              thresholds.highIntensityMinutes7DaysModerate ||
          highIntensityRatioToday >= thresholds.highIntensityRatioTodayModerate) {
        warnings.add('Taper protegido por exceso de intensidad reciente.');
        protectCompetition = true;
        reduceVolume = true;

        if (!isSprinter) {
          blockHighIntensity = true;
        }

        raiseLevel(InterventionLevel.severe);
      }

      if (strengthTendonStress >= 65 || strengthNeuralStress >= 70) {
        warnings.add(
          'Taper protegido por estrés de fuerza/saltos: reducir carga residual.',
        );
        protectCompetition = true;
        protectTendon = strengthTendonStress >= 65;
        protectNeuralSystem = strengthNeuralStress >= 70;
        reduceReactiveContacts = strengthTendonStress >= 65;
        reduceVolume = true;
        blockHeavyStrength = true;
        raiseLevel(InterventionLevel.severe);
      }
    }

    if (warnings.isEmpty) {
      warnings.add('Sin restricciones críticas detectadas.');
    }

    return TrainingInterventionResult(
      level: level,
      blockHighIntensity: blockHighIntensity,
      reduceVolume: reduceVolume,
      forceRecovery: forceRecovery,
      blockDoubleSession: blockDoubleSession,
      blockHeavyStrength: blockHeavyStrength,
      protectCompetition: protectCompetition,
      protectTendon: protectTendon,
      protectNeuralSystem: protectNeuralSystem,
      reduceReactiveContacts: reduceReactiveContacts,
      summary: _summary(
        level: level,
        blockHighIntensity: blockHighIntensity,
        reduceVolume: reduceVolume,
        forceRecovery: forceRecovery,
        blockDoubleSession: blockDoubleSession,
        blockHeavyStrength: blockHeavyStrength,
        protectCompetition: protectCompetition,
        protectTendon: protectTendon,
        protectNeuralSystem: protectNeuralSystem,
        reduceReactiveContacts: reduceReactiveContacts,
      ),
      warnings: warnings,
    );
  }

  static _SkatingInterventionThresholds _thresholdsForAthlete(
    AthleteProgramType type,
  ) {
    switch (type) {
      case AthleteProgramType.sprinter:
        return const _SkatingInterventionThresholds(
          highIntensityMinutesTodayModerate: 24,
          highIntensityMinutesTodaySevere: 34,
          highIntensityMinutes7DaysModerate: 75,
          highIntensityMinutes7DaysSevere: 105,
          highIntensityMinutes7DaysCritical: 135,
          zone5Minutes7DaysModerate: 20,
          zone5Minutes7DaysSevere: 30,
          zone5Minutes7DaysCritical: 40,
          neuralDays7DaysModerate: 3,
          neuralDays7DaysSevere: 4,
          neuralDays7DaysCritical: 5,
          reactiveBlocksTodayLimit: 2,
          neuralBlocksTodayLimit: 3,
          lactateBlocksTodayLimit: 1,
          highIntensityRatioTodayModerate: 0.28,
          highIntensityRatioTodaySevere: 0.40,
        );

      case AthleteProgramType.endurance:
        return const _SkatingInterventionThresholds(
          highIntensityMinutesTodayModerate: 32,
          highIntensityMinutesTodaySevere: 45,
          highIntensityMinutes7DaysModerate: 95,
          highIntensityMinutes7DaysSevere: 125,
          highIntensityMinutes7DaysCritical: 155,
          zone5Minutes7DaysModerate: 16,
          zone5Minutes7DaysSevere: 24,
          zone5Minutes7DaysCritical: 32,
          neuralDays7DaysModerate: 2,
          neuralDays7DaysSevere: 3,
          neuralDays7DaysCritical: 4,
          reactiveBlocksTodayLimit: 1,
          neuralBlocksTodayLimit: 2,
          lactateBlocksTodayLimit: 2,
          highIntensityRatioTodayModerate: 0.30,
          highIntensityRatioTodaySevere: 0.42,
        );

      case AthleteProgramType.mixed:
        return const _SkatingInterventionThresholds(
          highIntensityMinutesTodayModerate: 28,
          highIntensityMinutesTodaySevere: 40,
          highIntensityMinutes7DaysModerate: 85,
          highIntensityMinutes7DaysSevere: 115,
          highIntensityMinutes7DaysCritical: 145,
          zone5Minutes7DaysModerate: 18,
          zone5Minutes7DaysSevere: 27,
          zone5Minutes7DaysCritical: 36,
          neuralDays7DaysModerate: 3,
          neuralDays7DaysSevere: 4,
          neuralDays7DaysCritical: 5,
          reactiveBlocksTodayLimit: 2,
          neuralBlocksTodayLimit: 3,
          lactateBlocksTodayLimit: 1,
          highIntensityRatioTodayModerate: 0.28,
          highIntensityRatioTodaySevere: 0.40,
        );
    }
  }

  static _SkatingInterventionThresholds _adaptThresholds(
    _SkatingInterventionThresholds base,
    AthleteAdaptationProfile adaptation,
  ) {
    int scaleInt(int value, double factor) {
      return (value * factor).round().clamp(1, 999);
    }

    double scaleDouble(double value, double factor) {
      return (value * factor).clamp(0.05, 0.95);
    }

    final neuralFactor = adaptation.neuralTolerance;
    final metabolicFactor = adaptation.metabolicTolerance;
    final lactateFactor = adaptation.lactateTolerance;
    final reactiveFactor = adaptation.reactiveTolerance;
    final densityFactor = adaptation.densityTolerance;
    final taperFactor = adaptation.taperNeed;
    final recoveryFactor = adaptation.recoveryNeed;

    final globalSafetyFactor = ((densityFactor + recoveryFactor) / 2).clamp(
      0.75,
      1.20,
    );

    final intensityFactor = ((metabolicFactor + densityFactor) / 2).clamp(
      0.70,
      1.25,
    );

    final zone5Factor = ((neuralFactor + reactiveFactor) / 2).clamp(0.70, 1.25);

    final lactateSafetyFactor = lactateFactor.clamp(0.65, 1.25);

    final taperProtectionFactor = (2.0 - taperFactor).clamp(0.70, 1.15);

    return _SkatingInterventionThresholds(
      highIntensityMinutesTodayModerate: scaleInt(
        base.highIntensityMinutesTodayModerate,
        intensityFactor * taperProtectionFactor,
      ),
      highIntensityMinutesTodaySevere: scaleInt(
        base.highIntensityMinutesTodaySevere,
        intensityFactor * taperProtectionFactor,
      ),
      highIntensityMinutes7DaysModerate: scaleInt(
        base.highIntensityMinutes7DaysModerate,
        intensityFactor * globalSafetyFactor,
      ),
      highIntensityMinutes7DaysSevere: scaleInt(
        base.highIntensityMinutes7DaysSevere,
        intensityFactor * globalSafetyFactor,
      ),
      highIntensityMinutes7DaysCritical: scaleInt(
        base.highIntensityMinutes7DaysCritical,
        intensityFactor * globalSafetyFactor,
      ),
      zone5Minutes7DaysModerate: scaleInt(
        base.zone5Minutes7DaysModerate,
        zone5Factor,
      ),
      zone5Minutes7DaysSevere: scaleInt(
        base.zone5Minutes7DaysSevere,
        zone5Factor,
      ),
      zone5Minutes7DaysCritical: scaleInt(
        base.zone5Minutes7DaysCritical,
        zone5Factor,
      ),
      neuralDays7DaysModerate: scaleInt(
        base.neuralDays7DaysModerate,
        neuralFactor,
      ),
      neuralDays7DaysSevere: scaleInt(base.neuralDays7DaysSevere, neuralFactor),
      neuralDays7DaysCritical: scaleInt(
        base.neuralDays7DaysCritical,
        neuralFactor,
      ),
      reactiveBlocksTodayLimit: scaleInt(
        base.reactiveBlocksTodayLimit,
        reactiveFactor,
      ),
      neuralBlocksTodayLimit: scaleInt(
        base.neuralBlocksTodayLimit,
        neuralFactor,
      ),
      lactateBlocksTodayLimit: scaleInt(
        base.lactateBlocksTodayLimit,
        lactateSafetyFactor,
      ),
      highIntensityRatioTodayModerate: scaleDouble(
        base.highIntensityRatioTodayModerate,
        intensityFactor * taperProtectionFactor,
      ),
      highIntensityRatioTodaySevere: scaleDouble(
        base.highIntensityRatioTodaySevere,
        intensityFactor * taperProtectionFactor,
      ),
    );
  }

  static bool _isHighIntensityBlock(DailyTrainingBlock block) {
    return block.targetHeartRateZone >= 4 ||
        block.targetLoad >= 75 ||
        block.energySystem == TrainingEnergySystem.anaerobicLactic ||
        block.energySystem == TrainingEnergySystem.anaerobicAlactic;
  }

  static bool _isHeavyStrengthBlock(DailyTrainingBlock block) {
    return block.type == TrainingBlockType.strength &&
        (block.targetLoad >= 60 ||
            block.stimulus == TrainingStimulus.maxStrength ||
            block.stimulus == TrainingStimulus.power ||
            block.neuromuscularLoad == NeuromuscularLoad.high ||
            block.neuromuscularLoad == NeuromuscularLoad.maximal);
  }

  static bool _isReactiveBlock(DailyTrainingBlock block) {
    return block.stimulus == TrainingStimulus.plyometric ||
        (block.type == TrainingBlockType.activation &&
            block.neuromuscularLoad.index >= NeuromuscularLoad.moderate.index);
  }

  static bool _isNeuralBlock(DailyTrainingBlock block) {
    return block.isSpeedStimulus ||
        block.stimulus == TrainingStimulus.plyometric ||
        block.energySystem == TrainingEnergySystem.anaerobicAlactic ||
        block.neuromuscularLoad == NeuromuscularLoad.high ||
        block.neuromuscularLoad == NeuromuscularLoad.maximal;
  }

  static bool _isMetabolicBlock(DailyTrainingBlock block) {
    return block.stimulus == TrainingStimulus.lactateTolerance ||
        block.energySystem == TrainingEnergySystem.anaerobicLactic ||
        (block.targetHeartRateZone >= 4 &&
            block.targetLoad >= 70 &&
            !block.isSpeedStimulus);
  }

  static int _estimatedNeuralLoad(List<DailyTrainingBlock> blocks) {
    return blocks.where(_isNeuralBlock).length;
  }

  static int _estimatedMetabolicLoad(List<DailyTrainingBlock> blocks) {
    return blocks.where(_isMetabolicBlock).length;
  }

  static int _estimatedReactiveLoad(List<DailyTrainingBlock> blocks) {
    return blocks.where(_isReactiveBlock).length;
  }

  static int _todayHighIntensityMinutes(AthletePerformanceContext context) {
    final wearable = context.latestWearableData;

    if (wearable != null && wearable.totalZoneMinutes > 0) {
      return wearable.highIntensityMinutes;
    }

    if (context.dailyLogs.isEmpty) return 0;

    return context.dailyLogs.last.highIntensityMinutes;
  }

  static double _todayHighIntensityRatio(AthletePerformanceContext context) {
    final wearable = context.latestWearableData;

    if (wearable != null && wearable.totalZoneMinutes > 0) {
      return wearable.highIntensityRatio;
    }

    if (context.dailyLogs.isEmpty) return 0.0;

    return context.dailyLogs.last.highIntensityRatio;
  }

  static int _highIntensityMinutesLastDays(
    AthletePerformanceContext context,
    int days,
  ) {
    final logs = context.sortedLogs;

    if (logs.isEmpty) return 0;

    final selected = logs.length <= days
        ? logs
        : logs.sublist(logs.length - days);

    return selected.fold<int>(0, (sum, log) => sum + log.highIntensityMinutes);
  }

  static int _zone5MinutesLastDays(
    AthletePerformanceContext context,
    int days,
  ) {
    final logs = context.sortedLogs;

    if (logs.isEmpty) return 0;

    final selected = logs.length <= days
        ? logs
        : logs.sublist(logs.length - days);

    return selected.fold<int>(0, (sum, log) => sum + log.zone5Minutes);
  }

  static int _estimatedNeuralDaysLast7(AthletePerformanceContext context) {
    final logs = context.sortedLogs;

    if (logs.isEmpty) return 0;

    final selected = logs.length <= 7 ? logs : logs.sublist(logs.length - 7);

    return selected.where((log) {
      return log.zone5Minutes >= 5 || log.highIntensityMinutes >= 18;
    }).length;
  }

  static int _estimatedMetabolicDaysLast7(AthletePerformanceContext context) {
    final logs = context.sortedLogs;

    if (logs.isEmpty) return 0;

    final selected = logs.length <= 7 ? logs : logs.sublist(logs.length - 7);

    return selected.where((log) {
      return log.highIntensityMinutes >= 25;
    }).length;
  }

  static String _summary({
    required InterventionLevel level,
    required bool blockHighIntensity,
    required bool reduceVolume,
    required bool forceRecovery,
    required bool blockDoubleSession,
    required bool blockHeavyStrength,
    required bool protectCompetition,
    required bool protectTendon,
    required bool protectNeuralSystem,
    required bool reduceReactiveContacts,
  }) {
    if (forceRecovery) {
      return 'Recuperación forzada por fatiga crítica, riesgo elevado o exceso de carga.';
    }

    if (protectTendon && reduceReactiveContacts) {
      return 'Protección tendinosa: reducir contactos reactivos, saltos y pliometría.';
    }

    if (protectNeuralSystem) {
      return 'Protección neural: limitar fuerza pesada, velocidad máxima y carga explosiva.';
    }

    if (protectCompetition) {
      return 'Protección de taper/competencia: reducir carga residual y preservar frescura.';
    }

    if (blockHighIntensity && blockHeavyStrength) {
      return 'Se bloquea intensidad alta y fuerza pesada para proteger adaptación.';
    }

    if (blockHighIntensity) {
      return 'Se bloquean Z4/Z5, lactato y esfuerzos máximos no seguros.';
    }

    if (blockHeavyStrength) {
      return 'Se bloquea carga neuromuscular pesada: fuerza máxima, potencia o pliometría excesiva.';
    }

    if (blockDoubleSession) {
      return 'Se bloquea doble sesión por riesgo de acumulación.';
    }

    if (reduceVolume) {
      return 'Se reduce volumen para controlar fatiga acumulada.';
    }

    switch (level) {
      case InterventionLevel.none:
        return 'Sin intervención crítica. Mantener plan con monitoreo normal.';
      case InterventionLevel.caution:
        return 'Precaución: mantener calidad sin añadir carga extra.';
      case InterventionLevel.moderate:
        return 'Ajuste moderado recomendado.';
      case InterventionLevel.severe:
        return 'Intervención severa recomendada para controlar riesgo.';
      case InterventionLevel.critical:
        return 'Intervención crítica requerida.';
    }
  }
}

