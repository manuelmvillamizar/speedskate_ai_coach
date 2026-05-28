import 'exercise_model.dart';

class ExerciseLibrary {
  static final List<Exercise> exercises = [
    Exercise(
      name: 'Hang Clean',
      category: ExerciseCategory.olympic,

      descriptionEs:
          'Ejercicio olímpico enfocado en potencia explosiva, triple extensión y transferencia al sprint.',
      descriptionEn:
          'Olympic lift focused on explosive power, triple extension and sprint transfer.',
      descriptionDe:
          'Olympische �obung für Explosivkraft, Dreifachstreckung und Sprinttransfer.',

      muscles: 'Glúteos, cuádriceps, femorales, espalda, trapecio, core',

      level: 'Elite',

      equipment: 'Barra olímpica',

      imagePath: 'assets/images/exercises/hang_clean.jpg',

      gifPath: 'assets/gifs/exercises/hang_clean.gif',

      videoPath: 'assets/videos/exercises/hang_clean.mp4',

      techniqueStepsEs: [
        'Mantener espalda neutra.',
        'Iniciar desde posición hang.',
        'Extender cadera violentamente.',
        'Elevar codos rápido.',
        'Recibir en posición atlética.',
      ],

      techniqueStepsEn: [
        'Keep neutral spine.',
        'Start from hang position.',
        'Explosively extend hips.',
        'Drive elbows fast.',
        'Catch in athletic stance.',
      ],

      techniqueStepsDe: [
        'Neutrale Wirbelsäule halten.',
        'Aus Hang-Position starten.',
        'Hüfte explosiv strecken.',
        'Ellenbogen schnell anheben.',
        'In athletischer Position fangen.',
      ],

      commonMistakesEs: [
        'Redondear espalda.',
        'Tirar solo con brazos.',
        'No extender cadera.',
        'Recibir con codos bajos.',
      ],

      commonMistakesEn: [
        'Rounded back.',
        'Pulling only with arms.',
        'Poor hip extension.',
        'Low elbows on catch.',
      ],

      commonMistakesDe: [
        'Runder Rücken.',
        'Nur mit Armen ziehen.',
        'Schlechte Hüftstreckung.',
        'Tiefe Ellenbogen beim Fangen.',
      ],

      skatingTransferEs:
          'Mejora aceleración, potencia de salida y frecuencia explosiva.',
      skatingTransferEn:
          'Improves acceleration, start power and explosive frequency.',
      skatingTransferDe:
          'Verbessert Beschleunigung, Startkraft und Explosivität.',
    ),

    Exercise(
      name: 'Back Squat',
      category: ExerciseCategory.strength,

      descriptionEs: 'Ejercicio base de fuerza máxima para patinadores.',
      descriptionEn: 'Fundamental maximal strength exercise for skaters.',
      descriptionDe: 'Grundübung für Maximalkraft im Skating.',

      muscles: 'Cuádriceps, glúteos, femorales, core',

      level: 'Competitivo',

      equipment: 'Rack + barra',

      imagePath: 'assets/images/exercises/back_squat.jpg',

      gifPath: 'assets/gifs/exercises/back_squat.gif',

      videoPath: 'assets/videos/exercises/back_squat.mp4',

      techniqueStepsEs: [
        'Pies al ancho de hombros.',
        'Mantener pecho arriba.',
        'Bajar bajo control.',
        'Rodillas alineadas.',
        'Subir empujando el suelo.',
      ],

      techniqueStepsEn: [
        'Feet shoulder width apart.',
        'Keep chest up.',
        'Descend under control.',
        'Align knees properly.',
        'Drive through the floor.',
      ],

      techniqueStepsDe: [
        'Fü�Ye schulterbreit.',
        'Brust oben halten.',
        'Kontrolliert absenken.',
        'Knie korrekt ausrichten.',
        'Kraftvoll hochdrücken.',
      ],

      commonMistakesEs: [
        'Valgo de rodilla.',
        'Talones elevados.',
        'Perder postura lumbar.',
      ],

      commonMistakesEn: ['Knee valgus.', 'Heels lifting.', 'Lumbar collapse.'],

      commonMistakesDe: [
        'Knievalgus.',
        'Fersen heben ab.',
        'Lendenwirbelsäule kollabiert.',
      ],

      skatingTransferEs:
          'Incrementa fuerza específica y estabilidad en empuje lateral.',
      skatingTransferEn:
          'Improves skating-specific force and lateral push stability.',
      skatingTransferDe:
          'Verbessert spezifische Kraft und laterale Stabilität.',
    ),

    Exercise(
      name: 'Box Jump',
      category: ExerciseCategory.plyometric,

      descriptionEs: 'Pliometría para desarrollar potencia reactiva.',
      descriptionEn: 'Plyometric drill to develop reactive power.',
      descriptionDe: 'Plyometrische �obung zur Entwicklung reaktiver Kraft.',

      muscles: 'Glúteos, pantorrillas, cuádriceps',

      level: 'Competitivo',

      equipment: 'Caja pliométrica',

      imagePath: 'assets/images/exercises/box_jump.jpg',

      gifPath: 'assets/gifs/exercises/box_jump.gif',

      videoPath: 'assets/videos/exercises/box_jump.mp4',

      techniqueStepsEs: [
        'Preparar brazos atrás.',
        'Impulsar con triple extensión.',
        'Caer suave.',
        'Absorber impacto.',
      ],

      techniqueStepsEn: [
        'Load arms back.',
        'Explode with triple extension.',
        'Land softly.',
        'Absorb impact.',
      ],

      techniqueStepsDe: [
        'Arme nach hinten vorbereiten.',
        'Explosiv strecken.',
        'Sanft landen.',
        'Aufprall absorbieren.',
      ],

      commonMistakesEs: [
        'Caer rígido.',
        'No usar brazos.',
        'Colapsar rodillas.',
      ],

      commonMistakesEn: [
        'Rigid landing.',
        'No arm swing.',
        'Knees collapsing.',
      ],

      commonMistakesDe: [
        'Starre Landung.',
        'Keine Armbewegung.',
        'Knie kollabieren.',
      ],

      skatingTransferEs:
          'Mejora capacidad explosiva y frecuencia neuromuscular.',
      skatingTransferEn:
          'Improves explosive ability and neuromuscular frequency.',
      skatingTransferDe: 'Verbessert Explosivität und neuromuskuläre Frequenz.',
    ),

    Exercise(
      name: 'Plank',
      category: ExerciseCategory.core,

      descriptionEs: 'Ejercicio fundamental de estabilidad del core.',
      descriptionEn: 'Fundamental core stability exercise.',
      descriptionDe: 'Grundlegende Core-Stabilitätsübung.',

      muscles: 'Core, abdomen, lumbar',

      level: 'Novato',

      equipment: 'Peso corporal',

      imagePath: 'assets/images/exercises/plank.jpg',

      gifPath: 'assets/gifs/exercises/plank.gif',

      videoPath: 'assets/videos/exercises/plank.mp4',

      techniqueStepsEs: [
        'Mantener línea recta.',
        'Activar abdomen.',
        'No elevar cadera.',
      ],

      techniqueStepsEn: [
        'Keep straight line.',
        'Brace core.',
        'Avoid hip elevation.',
      ],

      techniqueStepsDe: [
        'Gerade Linie halten.',
        'Core aktivieren.',
        'Hüfte nicht anheben.',
      ],

      commonMistakesEs: ['Cadera caída.', 'Cuello hiperextendido.'],

      commonMistakesEn: ['Hip sagging.', 'Hyperextended neck.'],

      commonMistakesDe: ['Hüfte hängt durch.', '�oberstreckter Nacken.'],

      skatingTransferEs: 'Mejora estabilidad y transmisión de fuerza.',
      skatingTransferEn: 'Improves stability and force transfer.',
      skatingTransferDe: 'Verbessert Stabilität und Kraftübertragung.',
    ),
  ];
}


