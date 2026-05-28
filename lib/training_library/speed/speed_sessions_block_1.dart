import '../training_library_models.dart';

final List<TrainingSessionTemplate> speedSessionsBlock1 = [
  TrainingSessionTemplate(
    id: 'speed_001',
    number: 1,
    title: 'Pure Acceleration Development',

    category: TrainingLibraryCategory.acceleration,
    modality: TrainingLibraryModality.sprinter,
    intensity: TrainingSessionIntensity.maximal,

    objective:
        'Develop explosive acceleration mechanics, first push efficiency, and maximal force application during initial skating strides.',

    type: 'On Skates - Neural Speed Session',

    warmup: [
      '10 min easy skating',
      'Dynamic mobility routine',
      'Ankling drills',
      'Fast feet drills',
      '2 x 30m progressive accelerations',
      '2 x flying 40m progressive',
    ],

    mainSet: [
      '6 x 30m maximal starts',
      'Rest 3-4 min between reps',
      '4 x 60m acceleration build',
      'Rest 4-5 min between reps',
      '2 x 100m progressive speed extension',
    ],

    complementary: [
      '3 x 8 low hurdle jumps',
      '3 x 10 resisted band pushes',
      'Core stabilization circuit',
    ],

    technicalCues: [
      'Project hips forward aggressively',
      'Maintain low shin angles',
      'Push backward not upward',
      'Explosive first 3 pushes',
      'Keep head neutral',
    ],

    commonErrors: [
      'Standing too early',
      'Overstriding',
      'Losing push direction',
      'Excessive upper body rotation',
    ],

    cutCriteria: [
      'Drop in acceleration quality',
      'Loss of technical posture',
      'Power output visibly reduced',
    ],

    coachNotes:
        'Full neural freshness required. Avoid pairing with heavy lactate or maximal gym fatigue.',

    skatingSession: true,
    gymSession: false,
    cyclingSession: false,
    recoverySession: false,

    neuralFocused: true,
    metabolicFocused: false,
    reactiveFocused: true,
    technicalFocused: true,
    taperCompatible: true,

    tags: ['acceleration', 'speed', 'neural', 'starts', 'power'],
  ),

  TrainingSessionTemplate(
    id: 'speed_002',
    number: 2,
    title: 'Maximum Velocity Exposure',

    category: TrainingLibraryCategory.maxVelocity,
    modality: TrainingLibraryModality.sprinter,
    intensity: TrainingSessionIntensity.maximal,

    objective:
        'Improve top speed mechanics, skating frequency, relaxation at high velocity, and maximal velocity exposure.',

    type: 'On Skates - Max Velocity',

    warmup: [
      '12 min easy skating',
      'Dynamic mobility',
      'Sprint mobility drills',
      '2 x 100m progressive',
      '2 x flying 60m',
    ],

    mainSet: [
      '5 x flying 100m',
      '20m build zone',
      '100m maximal speed zone',
      'Rest 5-6 min',
      '3 x flying 200m relaxed fast skating',
    ],

    complementary: [
      'Reactive jumps',
      'Sprint arm mechanics drills',
      'Elastic ankle work',
    ],

    technicalCues: [
      'Relax shoulders at speed',
      'Fast recovery under hips',
      'Maintain lateral push direction',
      'Avoid tension accumulation',
    ],

    commonErrors: [
      'Tight upper body',
      'Overpushing',
      'Frequency collapse',
      'Late recovery mechanics',
    ],

    cutCriteria: [
      'Visible drop in speed',
      'Loss of relaxation',
      'Mechanical breakdown',
    ],

    coachNotes:
        'Session requires very high CNS freshness. Best placed after recovery or low-load days.',

    skatingSession: true,
    gymSession: false,
    cyclingSession: false,
    recoverySession: false,

    neuralFocused: true,
    metabolicFocused: false,
    reactiveFocused: true,
    technicalFocused: true,
    taperCompatible: true,

    tags: ['max velocity', 'flying', 'speed', 'elite speed', 'neural'],
  ),

  TrainingSessionTemplate(
    id: 'speed_003',
    number: 3,
    title: 'Speed Endurance Intro',

    category: TrainingLibraryCategory.speed,
    modality: TrainingLibraryModality.mixed,
    intensity: TrainingSessionIntensity.high,

    objective:
        'Develop the ability to sustain high skating speed with controlled fatigue accumulation.',

    type: 'On Skates - Speed Endurance',

    warmup: [
      '10 min skating',
      'Dynamic mobility',
      '2 progressive 100m',
      'Sprint drills',
    ],

    mainSet: [
      '4 x 300m at 90-95%',
      'Rest 5 min',
      '2 x 500m controlled fast pace',
      'Rest 6 min',
    ],

    complementary: [
      'Low intensity mobility',
      'Breathing reset work',
      'Core endurance circuit',
    ],

    technicalCues: [
      'Maintain technique under fatigue',
      'Control upper body tension',
      'Efficient corner mechanics',
      'Stable knee position',
    ],

    commonErrors: [
      'Technique collapse late',
      'Overpacing first reps',
      'Loss of push efficiency',
    ],

    cutCriteria: [
      'Excessive lactate breakdown',
      'Technical posture lost',
      'Unsafe movement quality',
    ],

    coachNotes:
        'Can be used for both sprinters and endurance skaters depending on phase and volume.',

    skatingSession: true,
    gymSession: false,
    cyclingSession: false,
    recoverySession: false,

    neuralFocused: false,
    metabolicFocused: true,
    reactiveFocused: false,
    technicalFocused: true,
    taperCompatible: false,

    tags: ['speed endurance', 'lactate', 'mixed', 'competition support'],
  ),

  TrainingSessionTemplate(
    id: 'speed_004',
    number: 4,
    title: 'Overspeed Neural Session',

    category: TrainingLibraryCategory.maxVelocity,
    modality: TrainingLibraryModality.sprinter,
    intensity: TrainingSessionIntensity.maximal,

    objective:
        'Stimulate supramaximal turnover and neural adaptation through assisted overspeed skating.',

    type: 'Overspeed Assisted Session',

    warmup: [
      '15 min progressive skating',
      'Dynamic sprint mobility',
      '2 x 60m fast relaxed skating',
    ],

    mainSet: [
      '6 x assisted flying 80m',
      'Rest 5 min',
      '3 x free flying 100m',
      'Contrast with normal skating speed',
    ],

    complementary: ['Reactive bounding', 'Fast feet ladder drills'],

    technicalCues: [
      'Relax at supramaximal speed',
      'Quick recovery mechanics',
      'Avoid overpushing',
    ],

    commonErrors: [
      'Panic mechanics',
      'Excessive tension',
      'Poor body alignment',
    ],

    cutCriteria: [
      'Loss of technical control',
      'Unsafe overspeed posture',
      'CNS fatigue signs',
    ],

    coachNotes:
        'Use carefully. High neural demand. Never combine with heavy lower body gym.',

    skatingSession: true,
    gymSession: false,
    cyclingSession: false,
    recoverySession: false,

    neuralFocused: true,
    metabolicFocused: false,
    reactiveFocused: true,
    technicalFocused: true,
    taperCompatible: true,

    tags: ['overspeed', 'neural', 'elite', 'flying', 'speed mechanics'],
  ),
];


