enum TrainingLibraryCategory {
  speed,
  acceleration,
  maxVelocity,
  lactate,
  aerobic,
  tempo,
  endurance,
  technical,
  tactical,
  strength,
  power,
  plyometric,
  activation,
  mobility,
  recovery,
  cycling,
  core,
  competition,
  taper,
}

enum TrainingLibraryModality { sprinter, endurance, mixed, universal }

enum TrainingLibraryPhase {
  generalPreparation,
  specificPreparation,
  preCompetition,
  competition,
  taper,
  transition,
  universal,
}

enum TrainingSessionIntensity { recovery, low, moderate, high, maximal }

class TrainingSessionTemplate {
  final String id;

  final String title;

  final String description;

  final String objective;

  final TrainingLibraryCategory category;

  final TrainingLibraryModality modality;

  final TrainingLibraryPhase phase;

  final TrainingSessionIntensity intensity;

  final int recommendedDurationMinutes;

  final double recommendedKm;

  final bool neuralFocused;

  final bool metabolicFocused;

  final bool technicalFocused;

  final bool gymSession;

  final bool skatingSession;

  final bool cyclingSession;

  final bool recoverySession;

  final bool taperCompatible;

  final List<String> tags;

  final List<String> warmup;

  final List<String> mainSet;

  final List<String> accessories;

  final List<String> coachNotes;

  final List<String> technicalCues;

  final List<String> cutCriteria;

  final List<String> commonErrors;

  final List<String> adaptations;

  final List<String> progressionOptions;

  final List<String> regressionOptions;

  const TrainingSessionTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.objective,
    required this.category,
    required this.modality,
    required this.phase,
    required this.intensity,
    required this.recommendedDurationMinutes,
    required this.recommendedKm,
    required this.neuralFocused,
    required this.metabolicFocused,
    required this.technicalFocused,
    required this.gymSession,
    required this.skatingSession,
    required this.cyclingSession,
    required this.recoverySession,
    required this.taperCompatible,
    required this.tags,
    required this.warmup,
    required this.mainSet,
    required this.accessories,
    required this.coachNotes,
    required this.technicalCues,
    required this.cutCriteria,
    required this.commonErrors,
    required this.adaptations,
    required this.progressionOptions,
    required this.regressionOptions,
  });
}

class MasterTrainingLibrary {
  static const List<TrainingSessionTemplate> sessions = [
    // =========================================================
    // SPEED
    // =========================================================
    TrainingSessionTemplate(
      id: 'speed_starts_001',

      title: 'Salidas estaticas o semiestaticas',

      description:
          'Trabajo neural de aceleración y primer empuje. Máxima calidad técnica, descansos completos y cero repeticiones lentas.',

      objective:
          'Desarrollar aceleración específica y transferencia de fuerza al gesto técnico.',

      category: TrainingLibraryCategory.acceleration,

      modality: TrainingLibraryModality.sprinter,

      phase: TrainingLibraryPhase.specificPreparation,

      intensity: TrainingSessionIntensity.high,

      recommendedDurationMinutes: 75,

      recommendedKm: 10,

      neuralFocused: true,

      metabolicFocused: false,

      technicalFocused: true,

      gymSession: false,

      skatingSession: true,

      cyclingSession: false,

      recoverySession: false,

      taperCompatible: true,

      tags: ['speed', 'acceleration', 'starts', 'neural', 'sprint'],

      warmup: [
        'Movilidad dinámica de cadera y tobillo.',
        'Activación de glúteo y core.',
        '3 progresiones suaves.',
        '2 aceleraciones técnicas.',
      ],

      mainSet: [
        '6-8 salidas de 10-15 m.',
        '4 aceleraciones progresivas.',
        '3 lanzadas cortas.',
        'Descanso completo entre repeticiones.',
      ],

      accessories: ['Movilidad final.', 'Liberación de tibiales y sóleo.'],

      coachNotes: [
        'La calidad manda.',
        'No perseguir volumen innecesario.',
        'Cada repetición debe verse rápida.',
      ],

      technicalCues: [
        'Mantener posición baja estable.',
        'Empuje lateral agresivo.',
        'No levantar demasiado el tronco.',
      ],

      cutCriteria: [
        'Caída visible de velocidad.',
        'Fatiga neural.',
        'Técnica inestable.',
        'Dolor tendinoso.',
      ],

      commonErrors: [
        'Salir demasiado rígido.',
        'Perder control del tronco.',
        'Acortar empuje.',
      ],

      adaptations: [
        'Reducir repeticiones si baja la calidad.',
        'Extender descansos si hay fatiga neural.',
      ],

      progressionOptions: [
        'Agregar resistencia ligera.',
        'Aumentar velocidad lanzada.',
      ],

      regressionOptions: ['Reducir distancia.', 'Eliminar lanzadas.'],
    ),

    // =========================================================
    // LACTATE
    // =========================================================
    TrainingSessionTemplate(
      id: 'lactate_tolerance_001',

      title: 'Tolerancia lactácida controlada',

      description:
          'Sesión de tolerancia al lactato específica para mantener velocidad bajo fatiga.',

      objective:
          'Mejorar capacidad de sostener ritmo competitivo y responder aceleraciones.',

      category: TrainingLibraryCategory.lactate,

      modality: TrainingLibraryModality.mixed,

      phase: TrainingLibraryPhase.specificPreparation,

      intensity: TrainingSessionIntensity.high,

      recommendedDurationMinutes: 90,

      recommendedKm: 18,

      neuralFocused: false,

      metabolicFocused: true,

      technicalFocused: true,

      gymSession: false,

      skatingSession: true,

      cyclingSession: false,

      recoverySession: false,

      taperCompatible: false,

      tags: ['lactate', 'specific', 'speed endurance'],

      warmup: ['Rodaje progresivo.', 'Movilidad dinámica.', '2 progresiones.'],

      mainSet: [
        '4 x 600m ritmo competitivo.',
        'Recuperación incompleta.',
        '2 bloques finales de cambio de ritmo.',
      ],

      accessories: ['Rodaje suave.', 'Movilidad posterior.'],

      coachNotes: [
        'No convertir la sesión en supervivencia.',
        'Controlar calidad técnica bajo fatiga.',
      ],

      technicalCues: ['Mantener frecuencia.', 'No perder línea técnica.'],

      cutCriteria: ['Técnica destruida.', 'Caída excesiva de ritmo.'],

      commonErrors: ['Salir demasiado rápido.', 'Perder postura.'],

      adaptations: ['Reducir volumen si hay exceso metabólico.'],

      progressionOptions: ['Más cambios de ritmo.'],

      regressionOptions: ['Reducir distancia.'],
    ),

    // =========================================================
    // STRENGTH
    // =========================================================
    TrainingSessionTemplate(
      id: 'strength_max_001',

      title: 'Fuerza máxima específica',

      description:
          'Sesión orientada a desarrollar fuerza útil transferible al empuje en patinaje.',

      objective: 'Mejorar producción de fuerza y estabilidad bajo carga.',

      category: TrainingLibraryCategory.strength,

      modality: TrainingLibraryModality.universal,

      phase: TrainingLibraryPhase.generalPreparation,

      intensity: TrainingSessionIntensity.high,

      recommendedDurationMinutes: 70,

      recommendedKm: 0,

      neuralFocused: true,

      metabolicFocused: false,

      technicalFocused: false,

      gymSession: true,

      skatingSession: false,

      cyclingSession: false,

      recoverySession: false,

      taperCompatible: false,

      tags: ['strength', 'gym', 'max strength'],

      warmup: [
        'Movilidad dinámica.',
        'Activación glúteo/core.',
        'Series progresivas.',
      ],

      mainSet: [
        'Sentadilla pesada.',
        'Peso muerto.',
        'Split squat.',
        'Trabajo unilateral.',
      ],

      accessories: ['Core antirotacional.', 'Estabilidad cadera.'],

      coachNotes: [
        'No sacrificar técnica por carga.',
        'Buscar transferencia, no ego.',
      ],

      technicalCues: [
        'Controlar fase excéntrica.',
        'Mantener estabilidad lumbo-pélvica.',
      ],

      cutCriteria: ['Pérdida técnica.', 'Fatiga neural excesiva.'],

      commonErrors: ['Compensar con espalda.', 'Perder alineación de rodilla.'],

      adaptations: ['Reducir volumen si hay alta carga neural semanal.'],

      progressionOptions: ['Contrastes.', 'Más velocidad concéntrica.'],

      regressionOptions: ['Reducir carga.', 'Eliminar accesorios.'],
    ),

    // =========================================================
    // RECOVERY
    // =========================================================
    TrainingSessionTemplate(
      id: 'recovery_001',

      title: 'Recuperación neuromuscular',

      description:
          'Trabajo regenerativo para restaurar frescura física y técnica.',

      objective: 'Favorecer recuperación sin añadir fatiga residual.',

      category: TrainingLibraryCategory.recovery,

      modality: TrainingLibraryModality.universal,

      phase: TrainingLibraryPhase.universal,

      intensity: TrainingSessionIntensity.recovery,

      recommendedDurationMinutes: 40,

      recommendedKm: 0,

      neuralFocused: false,

      metabolicFocused: false,

      technicalFocused: false,

      gymSession: false,

      skatingSession: false,

      cyclingSession: true,

      recoverySession: true,

      taperCompatible: true,

      tags: ['recovery', 'mobility', 'regeneration'],

      warmup: ['Respiración.', 'Movilidad suave.'],

      mainSet: ['Bicicleta regenerativa Z1.', 'Movilidad.', 'Respiración.'],

      accessories: ['Foam roller.', 'Liberación muscular.'],

      coachNotes: [
        'La sesión debe sentirse fácil.',
        'Salir más fresco de como se empezó.',
      ],

      technicalCues: ['Respiración controlada.', 'Sin tensión innecesaria.'],

      cutCriteria: ['Fatiga adicional.'],

      commonErrors: ['Hacer demasiado volumen.', 'Subir intensidad.'],

      adaptations: ['Reducir duración si hay mucha fatiga.'],

      progressionOptions: ['Agregar movilidad específica.'],

      regressionOptions: ['Solo respiración y movilidad.'],
    ),
  ];
}


