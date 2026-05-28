import 'package:flutter/material.dart';

class StrengthExerciseDefinition {
  final String id;
  final String name;
  final String category;
  final String primaryMuscles;
  final String sportTransfer;
  final String description;
  final List<String> coachingCues;
  final List<String> commonMistakes;
  final IconData icon;
  final Color color;

  const StrengthExerciseDefinition({
    required this.id,
    required this.name,
    required this.category,
    required this.primaryMuscles,
    required this.sportTransfer,
    required this.description,
    required this.coachingCues,
    required this.commonMistakes,
    required this.icon,
    required this.color,
  });
}

class StrengthExerciseVisual {
  final StrengthExerciseDefinition definition;
  final String originalText;
  final String prescription;

  const StrengthExerciseVisual({
    required this.definition,
    required this.originalText,
    required this.prescription,
  });
}

class StrengthExerciseLibrary {
  static const StrengthExerciseDefinition unknown = StrengthExerciseDefinition(
    id: 'generic_strength',
    name: 'Ejercicio de fuerza',
    category: 'Fuerza',
    primaryMuscles: 'Según ejercicio',
    sportTransfer: 'Preparación física general para patinaje.',
    description:
        'Ejercicio de fuerza programado por el entrenador. Ejecutar con técnica limpia y control total.',
    coachingCues: [
      'Mantener postura estable.',
      'Controlar la fase de bajada.',
      'No buscar fallo muscular si no está indicado.',
      'Priorizar calidad antes que peso.',
    ],
    commonMistakes: [
      'Perder alineación.',
      'Compensar con la espalda.',
      'Acelerar sin control.',
    ],
    icon: Icons.fitness_center,
    color: Colors.blueGrey,
  );

  static const List<StrengthExerciseDefinition> exercises = [
    StrengthExerciseDefinition(
      id: 'trap_bar_jump',
      name: 'Trap bar jump',
      category: 'Potencia',
      primaryMuscles: 'Glúteos, cuádriceps, cadena posterior',
      sportTransfer: 'Salida, aceleración y potencia de empuje.',
      description:
          'Salto explosivo con trap bar para transferir fuerza al gesto de aceleración.',
      coachingCues: [
        'Empujar el piso fuerte y rápido.',
        'Aterrizar suave y estable.',
        'Mantener tronco firme.',
        'Descansar completo entre series.',
      ],
      commonMistakes: [
        'Aterrizar pesado.',
        'Flexionar espalda.',
        'Buscar fatiga en vez de velocidad.',
      ],
      icon: Icons.bolt,
      color: Colors.deepOrange,
    ),
    StrengthExerciseDefinition(
      id: 'jump_squat',
      name: 'Sentadilla con salto',
      category: 'Potencia',
      primaryMuscles: 'Cuádriceps, glúteos, gemelos',
      sportTransfer: 'Explosividad para salidas y cambios de ritmo.',
      description:
          'Ejercicio balístico para convertir fuerza en velocidad de aplicación.',
      coachingCues: [
        'Bajar controlado.',
        'Saltar vertical y rápido.',
        'Caer silencioso.',
        'Cortar si baja la velocidad.',
      ],
      commonMistakes: [
        'Caer con rodillas hacia adentro.',
        'Hacer demasiadas repeticiones.',
        'Perder rigidez del tronco.',
      ],
      icon: Icons.bolt,
      color: Colors.orange,
    ),
    StrengthExerciseDefinition(
      id: 'front_squat',
      name: 'Sentadilla frontal',
      category: 'Fuerza máxima',
      primaryMuscles: 'Cuádriceps, glúteos, core',
      sportTransfer: 'Base de fuerza para empuje lateral y posición baja.',
      description:
          'Patrón dominante de rodilla con alta exigencia de core y control postural.',
      coachingCues: [
        'Codos altos.',
        'Rodillas alineadas con los pies.',
        'Tronco estable.',
        'Subir fuerte sin perder postura.',
      ],
      commonMistakes: [
        'Colapsar el tronco.',
        'Levantar talones.',
        'Rodillas hacia adentro.',
      ],
      icon: Icons.fitness_center,
      color: Colors.red,
    ),
    StrengthExerciseDefinition(
      id: 'leg_press',
      name: 'Prensa',
      category: 'Fuerza',
      primaryMuscles: 'Cuádriceps, glúteos',
      sportTransfer: 'Fuerza extensora útil para empuje y aceleración.',
      description:
          'Ejercicio guiado para desarrollar fuerza de piernas con control.',
      coachingCues: [
        'Apoyar bien todo el pie.',
        'Controlar el rango.',
        'No bloquear rodillas al final.',
        'Mantener ritmo constante.',
      ],
      commonMistakes: [
        'Bajar demasiado sin control.',
        'Separar cadera del respaldo.',
        'Empujar solo con punta del pie.',
      ],
      icon: Icons.fitness_center,
      color: Colors.red,
    ),
    StrengthExerciseDefinition(
      id: 'romanian_deadlift',
      name: 'Peso muerto rumano',
      category: 'Fuerza posterior',
      primaryMuscles: 'Isquios, glúteos, espalda baja',
      sportTransfer: 'Estabilidad de cadera y potencia de empuje.',
      description:
          'Bisagra de cadera para fortalecer cadena posterior y control excéntrico.',
      coachingCues: [
        'Cadera atrás.',
        'Espalda neutra.',
        'Barra cerca del cuerpo.',
        'Sentir tensión en isquios.',
      ],
      commonMistakes: [
        'Redondear espalda.',
        'Convertirlo en sentadilla.',
        'Perder control excéntrico.',
      ],
      icon: Icons.fitness_center,
      color: Colors.brown,
    ),
    StrengthExerciseDefinition(
      id: 'step_up',
      name: 'Step-up alto',
      category: 'Fuerza unilateral',
      primaryMuscles: 'Glúteos, cuádriceps, estabilizadores de cadera',
      sportTransfer: 'Empuje unilateral, estabilidad y transferencia al patín.',
      description:
          'Trabajo unilateral para mejorar fuerza por pierna y control de cadera.',
      coachingCues: [
        'Subir empujando con la pierna de apoyo.',
        'Controlar la bajada.',
        'Rodilla alineada.',
        'Evitar impulso excesivo.',
      ],
      commonMistakes: [
        'Impulsarse con la pierna de abajo.',
        'Colapsar rodilla.',
        'Perder equilibrio.',
      ],
      icon: Icons.stairs,
      color: Colors.indigo,
    ),
    StrengthExerciseDefinition(
      id: 'pallof_press',
      name: 'Pallof press',
      category: 'Core antirotación',
      primaryMuscles: 'Core, oblicuos, estabilizadores',
      sportTransfer: 'Estabilidad del tronco en curvas, salidas y empuje.',
      description:
          'Ejercicio antirotacional para mantener control del tronco bajo fuerza lateral.',
      coachingCues: [
        'Costillas abajo.',
        'Cadera estable.',
        'Empujar al frente sin rotar.',
        'Respirar con control.',
      ],
      commonMistakes: [
        'Girar el tronco.',
        'Arquear espalda.',
        'Usar demasiada carga.',
      ],
      icon: Icons.accessibility_new,
      color: Colors.teal,
    ),
    StrengthExerciseDefinition(
      id: 'lateral_bounds',
      name: 'Bounds laterales',
      category: 'Pliometría lateral',
      primaryMuscles: 'Glúteos, aductores, gemelos, estabilizadores',
      sportTransfer: 'Empuje lateral, curva y transición fuerza-velocidad.',
      description:
          'Saltos laterales técnicos para mejorar potencia específica de patinaje.',
      coachingCues: [
        'Saltar lateral, no vertical.',
        'Caer estable.',
        'Rodilla alineada.',
        'Pocos contactos, máxima calidad.',
      ],
      commonMistakes: [
        'Caer pesado.',
        'Buscar distancia sin control.',
        'Colapsar rodilla.',
      ],
      icon: Icons.compare_arrows,
      color: Colors.deepPurple,
    ),
    StrengthExerciseDefinition(
      id: 'lateral_jump',
      name: 'Saltos laterales bajos',
      category: 'Pliometría',
      primaryMuscles: 'Tobillo, glúteos, estabilizadores laterales',
      sportTransfer: 'Reactividad lateral y control de apoyo.',
      description:
          'Saltos laterales de baja altura para activar reactividad sin fatigar.',
      coachingCues: [
        'Contacto corto.',
        'Caída silenciosa.',
        'Tronco estable.',
        'Mantener ritmo técnico.',
      ],
      commonMistakes: [
        'Saltar demasiado alto.',
        'Caer rígido.',
        'Perder alineación.',
      ],
      icon: Icons.bolt,
      color: Colors.amber,
    ),
    StrengthExerciseDefinition(
      id: 'pogos',
      name: 'Pogos',
      category: 'Reactividad',
      primaryMuscles: 'Tobillo, gemelos, pie',
      sportTransfer: 'Rigidez elástica y contacto rápido.',
      description:
          'Saltos cortos reactivos para preparar pies y tobillos antes de velocidad.',
      coachingCues: [
        'Contacto rápido.',
        'Rodillas suaves.',
        'Tronco alto.',
        'No buscar fatiga.',
      ],
      commonMistakes: [
        'Caer pesado.',
        'Flexionar demasiado.',
        'Hacer volumen excesivo.',
      ],
      icon: Icons.bolt,
      color: Colors.amber,
    ),
  ];

  static StrengthExerciseDefinition? findById(String id) {
    for (final exercise in exercises) {
      if (exercise.id == id) return exercise;
    }

    return null;
  }

  static StrengthExerciseVisual resolveFromText(String text) {
    final definition = _matchDefinition(text) ?? unknown;
    final prescription = _extractPrescription(text);

    return StrengthExerciseVisual(
      definition: definition,
      originalText: text,
      prescription: prescription,
    );
  }

  static StrengthExerciseDefinition? _matchDefinition(String text) {
    final value = _normalize(text);

    if (value.contains('trap bar')) return findById('trap_bar_jump');
    if (value.contains('sentadilla con salto')) return findById('jump_squat');
    if (value.contains('sentadilla frontal')) return findById('front_squat');
    if (value.contains('prensa')) return findById('leg_press');
    if (value.contains('peso muerto rumano')) {
      return findById('romanian_deadlift');
    }
    if (value.contains('step-up') || value.contains('step up')) {
      return findById('step_up');
    }
    if (value.contains('pallof')) return findById('pallof_press');
    if (value.contains('bounds laterales')) return findById('lateral_bounds');
    if (value.contains('saltos laterales')) return findById('lateral_jump');
    if (value.contains('pogos')) return findById('pogos');

    return null;
  }

  static String _extractPrescription(String text) {
    final parts = text.split(':');

    if (parts.length >= 2) {
      return parts.sublist(1).join(':').trim().replaceAll('.', '');
    }

    final match = RegExp(
      r'(\d+\s*x\s*\d+[-�?"]?\d*|\d+\s*series|\d+\s*reps)',
      caseSensitive: false,
    ).firstMatch(text);

    if (match != null) {
      return match.group(0) ?? '';
    }

    return 'Según indicación';
  }

  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');
  }
}


