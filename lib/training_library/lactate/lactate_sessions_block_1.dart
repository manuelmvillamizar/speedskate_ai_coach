import '../training_library_models.dart';

final List<TrainingSessionTemplate> lactateSessionsBlock1 = [
  TrainingSessionTemplate(
    id: 'lactate_001',
    number: 1,
    title: 'Lactate Tolerance Builder',

    category: TrainingLibraryCategory.lactate,
    modality: TrainingLibraryModality.sprinter,
    intensity: TrainingSessionIntensity.high,

    objective:
        'Increase lactate tolerance capacity and maintain skating mechanics under severe metabolic stress.',

    type: 'On Skates - Lactate Tolerance',

    warmup: [
      '12 min easy skating',
      'Dynamic mobility',
      'Progressive accelerations',
      '2 x 200m moderate pace',
    ],

    mainSet: [
      '4 x 500m at 95%',
      'Rest 6-8 min',
      '2 x 300m maximal controlled finish',
    ],

    complementary: ['Light mobility', 'Breathing reset', 'Low intensity core'],

    technicalCues: [
      'Maintain knee stability',
      'Control upper body tension',
      'Efficient push under fatigue',
      'Stay compact in corners',
    ],

    commonErrors: [
      'Opening too fast',
      'Technique collapse late',
      'Loss of lateral push mechanics',
    ],

    cutCriteria: [
      'Unsafe technical breakdown',
      'Severe posture collapse',
      'Neuromuscular exhaustion signs',
    ],

    coachNotes:
        'Very high metabolic stress. Avoid pairing with maximal neural sessions next day.',

    skatingSession: true,
    gymSession: false,
    cyclingSession: false,
    recoverySession: false,

    neuralFocused: false,
    metabolicFocused: true,
    reactiveFocused: false,
    technicalFocused: true,
    taperCompatible: false,

    tags: ['lactate', 'metabolic', 'tolerance', 'speed endurance'],
  ),

  TrainingSessionTemplate(
    id: 'lactate_002',
    number: 2,
    title: 'Sprint Lactate Combo',

    category: TrainingLibraryCategory.lactate,
    modality: TrainingLibraryModality.mixed,
    intensity: TrainingSessionIntensity.high,

    objective:
        'Develop repeated sprint ability and lactate buffering under repeated high intensity efforts.',

    type: 'Repeated Sprint Lactate Session',

    warmup: [
      '10 min skating',
      'Sprint drills',
      'Dynamic mobility',
      '2 x progressive 100m',
    ],

    mainSet: [
      '3 sets:',
      '3 x 200m maximal',
      'Rest 90 sec between reps',
      'Rest 8 min between sets',
    ],

    complementary: ['Mobility reset', 'Glute activation', 'Breathing work'],

    technicalCues: [
      'Explosive first half',
      'Maintain pressure in corners',
      'Control technique during acidosis',
    ],

    commonErrors: [
      'Overstriding under fatigue',
      'Upper body collapse',
      'Losing edge pressure',
    ],

    cutCriteria: [
      'Major speed drop',
      'Dangerous coordination loss',
      'Mechanical collapse',
    ],

    coachNotes:
        'Extremely demanding glycolytic session. Monitor recovery carefully.',

    skatingSession: true,
    gymSession: false,
    cyclingSession: false,
    recoverySession: false,

    neuralFocused: true,
    metabolicFocused: true,
    reactiveFocused: false,
    technicalFocused: true,
    taperCompatible: false,

    tags: ['glycolytic', 'repeated sprint', 'competition', 'anaerobic'],
  ),

  TrainingSessionTemplate(
    id: 'lactate_003',
    number: 3,
    title: 'Long Lactate Resistance',

    category: TrainingLibraryCategory.lactate,
    modality: TrainingLibraryModality.endurance,
    intensity: TrainingSessionIntensity.high,

    objective:
        'Improve prolonged lactate resistance and sustain high speed under extended metabolic accumulation.',

    type: 'Endurance Lactate Session',

    warmup: [
      '15 min progressive skating',
      'Dynamic mobility',
      'Technique drills',
    ],

    mainSet: [
      '3 x 1000m at race pace',
      'Rest 8 min',
      '2 x 600m progressive finish',
    ],

    complementary: ['Low intensity mobility', 'Recovery skating'],

    technicalCues: [
      'Maintain efficient rhythm',
      'Stable trunk positioning',
      'Economical cornering',
    ],

    commonErrors: [
      'Opening too aggressively',
      'Late technical collapse',
      'Inefficient recovery phase',
    ],

    cutCriteria: [
      'Loss of posture control',
      'Dangerous fatigue patterns',
      'Excessive deceleration',
    ],

    coachNotes:
        'Useful for endurance skaters needing stronger finishing capability and attacks.',

    skatingSession: true,
    gymSession: false,
    cyclingSession: false,
    recoverySession: false,

    neuralFocused: false,
    metabolicFocused: true,
    reactiveFocused: false,
    technicalFocused: true,
    taperCompatible: false,

    tags: ['endurance lactate', 'resistance', 'metabolic', 'race support'],
  ),

  TrainingSessionTemplate(
    id: 'lactate_004',
    number: 4,
    title: 'Competition Simulation Lactate',

    category: TrainingLibraryCategory.lactate,
    modality: TrainingLibraryModality.mixed,
    intensity: TrainingSessionIntensity.maximal,

    objective:
        'Simulate competition metabolic stress and tactical fatigue accumulation.',

    type: 'Race Simulation',

    warmup: ['15 min skating', 'Progressive speed drills', 'Starts practice'],

    mainSet: [
      '1 x simulated race block',
      'Includes attacks, accelerations, tactical surges',
      '2 x 300m maximal finish sprints',
    ],

    complementary: ['Recovery skating', 'Mobility cooldown'],

    technicalCues: [
      'React efficiently to pace changes',
      'Control fatigue during attacks',
      'Maintain tactical positioning',
    ],

    commonErrors: [
      'Early energy waste',
      'Excessive tension',
      'Pacing collapse',
    ],

    cutCriteria: [
      'Unsafe exhaustion',
      'Loss of tactical awareness',
      'Major technical failure',
    ],

    coachNotes:
        'Excellent pre-competition metabolic session but requires full recovery afterwards.',

    skatingSession: true,
    gymSession: false,
    cyclingSession: false,
    recoverySession: false,

    neuralFocused: true,
    metabolicFocused: true,
    reactiveFocused: false,
    technicalFocused: true,
    taperCompatible: false,

    tags: ['competition', 'simulation', 'race', 'lactate', 'tactical'],
  ),
];


