enum GymBlockType {
  activation,
  olympic,
  strength,
  accessory,
  plyometric,
  core,
  machine,
}

class GymExercise {
  final String name;
  final GymBlockType type;
  final int sets;
  final int reps;

  GymExercise({
    required this.name,
    required this.type,
    required this.sets,
    required this.reps,
  });
}

class GymSession {
  final List<GymExercise> exercises;

  GymSession(this.exercises);
}

class GymEngine {
  static GymSession generate({
    required String athleteType,
    required String level,
  }) {
    List<GymExercise> session = [];

    // �Y"� ACTIVACI�"N
    session.add(
      GymExercise(
        name: 'Movilidad cadera + activación glúteo',
        type: GymBlockType.activation,
        sets: 2,
        reps: 12,
      ),
    );

    // �Y"� VELOCISTA
    if (athleteType == 'Velocista') {
      session.add(
        GymExercise(
          name: 'Power Clean',
          type: GymBlockType.olympic,
          sets: 5,
          reps: 3,
        ),
      );

      session.add(
        GymExercise(
          name: 'Back Squat',
          type: GymBlockType.strength,
          sets: 5,
          reps: 4,
        ),
      );

      session.add(
        GymExercise(
          name: 'Hip Thrust',
          type: GymBlockType.strength,
          sets: 4,
          reps: 6,
        ),
      );

      session.add(
        GymExercise(
          name: 'Romanian Deadlift',
          type: GymBlockType.accessory,
          sets: 3,
          reps: 6,
        ),
      );

      session.add(
        GymExercise(
          name: 'Skater Jumps',
          type: GymBlockType.plyometric,
          sets: 4,
          reps: 8,
        ),
      );

      session.add(
        GymExercise(
          name: 'Core anti-rotación',
          type: GymBlockType.core,
          sets: 3,
          reps: 12,
        ),
      );
    }

    // �Y"� FONDISTA
    if (athleteType == 'Fondista') {
      session.add(
        GymExercise(
          name: 'Split Squat',
          type: GymBlockType.strength,
          sets: 4,
          reps: 10,
        ),
      );

      session.add(
        GymExercise(
          name: 'Leg Press',
          type: GymBlockType.machine,
          sets: 3,
          reps: 12,
        ),
      );

      session.add(
        GymExercise(
          name: 'Curl femoral',
          type: GymBlockType.accessory,
          sets: 3,
          reps: 12,
        ),
      );

      session.add(
        GymExercise(
          name: 'Step Ups',
          type: GymBlockType.accessory,
          sets: 3,
          reps: 12,
        ),
      );

      session.add(
        GymExercise(
          name: 'Core estabilidad',
          type: GymBlockType.core,
          sets: 4,
          reps: 12,
        ),
      );
    }

    // �Y"� MIXTO
    if (athleteType == 'Mixto') {
      session.add(
        GymExercise(
          name: 'Hang Clean',
          type: GymBlockType.olympic,
          sets: 4,
          reps: 4,
        ),
      );

      session.add(
        GymExercise(
          name: 'Back Squat',
          type: GymBlockType.strength,
          sets: 4,
          reps: 6,
        ),
      );

      session.add(
        GymExercise(
          name: 'Step Ups',
          type: GymBlockType.accessory,
          sets: 3,
          reps: 10,
        ),
      );

      session.add(
        GymExercise(
          name: 'Skater Jumps',
          type: GymBlockType.plyometric,
          sets: 3,
          reps: 8,
        ),
      );

      session.add(
        GymExercise(name: 'Core', type: GymBlockType.core, sets: 3, reps: 12),
      );
    }

    return GymSession(session);
  }
}


