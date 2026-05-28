import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'athlete_program_service.dart';
import 'gym_engine.dart';

class GymScreen extends StatefulWidget {
  const GymScreen({super.key});

  @override
  State<GymScreen> createState() => _GymScreenState();
}

class _GymScreenState extends State<GymScreen> {
  GymSession? session;

  String athleteTypeText(AthleteProgramType type) {
    switch (type) {
      case AthleteProgramType.sprinter:
        return 'Velocista';
      case AthleteProgramType.endurance:
        return 'Fondista';
      case AthleteProgramType.mixed:
        return 'Mixto';
    }
  }

  String athleteLevelText(AthleteProgramLevel level) {
    switch (level) {
      case AthleteProgramLevel.novice:
        return 'Novato';
      case AthleteProgramLevel.competitive:
        return 'Competitivo';
      case AthleteProgramLevel.elite:
        return 'Elite';
    }
  }

  void generateSession(AthleteProgramProfile athlete) {
    setState(() {
      session = GymEngine.generate(
        athleteType: athleteTypeText(athlete.type),
        level: athleteLevelText(athlete.level),
      );
    });
  }

  String blockTitle(GymBlockType type) {
    switch (type) {
      case GymBlockType.activation:
        return 'Activación';
      case GymBlockType.olympic:
        return 'Olímpico';
      case GymBlockType.strength:
        return 'Fuerza';
      case GymBlockType.machine:
        return 'Máquina';
      case GymBlockType.accessory:
        return 'Complementario';
      case GymBlockType.plyometric:
        return 'Potencia';
      case GymBlockType.core:
        return 'Core';
    }
  }

  IconData blockIcon(GymBlockType type) {
    switch (type) {
      case GymBlockType.activation:
        return Icons.accessibility;
      case GymBlockType.olympic:
        return Icons.flash_on;
      case GymBlockType.strength:
        return Icons.fitness_center;
      case GymBlockType.machine:
        return Icons.precision_manufacturing;
      case GymBlockType.accessory:
        return Icons.build;
      case GymBlockType.plyometric:
        return Icons.directions_run;
      case GymBlockType.core:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final athleteService = context.watch<AthleteProgramService>();
    final athlete = athleteService.activeAthlete;

    if (athlete == null) {
      return const Scaffold(
        body: Center(child: Text('Primero crea o selecciona un atleta.')),
      );
    }

    final type = athleteTypeText(athlete.type);
    final level = athleteLevelText(athlete.level);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Sesión de gimnasio PRO',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          Card(
            color: const Color(0xFF111827),
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text(
                athlete.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${athlete.category} · $type · $level'),
            ),
          ),

          const SizedBox(height: 16),

          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'La sesión se genera automáticamente usando el tipo y nivel del atleta seleccionado. No necesitas volver a elegir modalidad.',
              ),
            ),
          ),

          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: () => generateSession(athlete),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generar sesión de gimnasio'),
          ),

          const SizedBox(height: 16),

          if (session != null)
            ...session!.exercises.map(
              (exercise) => Card(
                child: ListTile(
                  leading: Icon(blockIcon(exercise.type)),
                  title: Text(exercise.name),
                  subtitle: Text(
                    '${blockTitle(exercise.type)} · ${exercise.sets} x ${exercise.reps}',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
