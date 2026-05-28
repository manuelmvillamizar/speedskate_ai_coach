import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'athlete_program_service.dart';
import 'daily_training_assignment.dart';
import 'daily_training_assignment_service.dart';
import 'daily_training_block.dart';
import 'strength_exercise_library.dart';

class AthleteTodayPlanScreen extends StatelessWidget {
  const AthleteTodayPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final athlete = context.watch<AthleteProgramService>().activeAthlete;

    if (athlete == null) {
      return const Center(child: Text('No hay atleta activo.'));
    }

    final assignment = context
        .watch<DailyTrainingAssignmentService>()
        .todayAssignmentForAthlete(athlete.id);

    if (assignment == null ||
        assignment.status != DailyTrainingAssignmentStatus.sent) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Tu entrenador aún no ha enviado el entrenamiento de hoy.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final day = assignment.trainingDay;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Entrenamiento de hoy',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Plan enviado por tu entrenador. Sigue solo este entrenamiento.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        _AthleteBriefingCard(day: day),
        const SizedBox(height: 16),
        _SimpleWarningCard(day: day),
        const SizedBox(height: 16),
        ...day.blocks.map((block) => _AthleteBlockCard(block: block)),
      ],
    );
  }
}

class _AthleteBriefingCard extends StatelessWidget {
  final dynamic day;

  const _AthleteBriefingCard({required this.day});

  Color get color {
    switch (day.expectedFatigue) {
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.orange;
      case 'orange':
        return Colors.deepOrange;
      case 'red':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String get fatigueText {
    switch (day.expectedFatigue) {
      case 'green':
        return 'Listo para entrenar';
      case 'yellow':
        return 'Controlar intensidad';
      case 'orange':
        return 'Día de carga controlada';
      case 'red':
        return 'Prioridad recuperación';
      default:
        return 'Plan del día';
    }
  }

  String get focusText {
    if (day.hasRecoveryBlock) {
      return 'Recuperación y adaptación';
    }

    if (day.hasDoubleSession) {
      return 'Doble sesión controlada';
    }

    if (day.hasStrengthAndSkating) {
      return 'Fuerza + patinaje';
    }

    if (day.totalLoad >= 75) {
      return 'Calidad e intensidad';
    }

    if (day.totalLoad <= 40) {
      return 'Técnica y recuperación';
    }

    return 'Entrenamiento principal del día';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.10),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.18),
                  child: Icon(Icons.today, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    fatigueText,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              focusText,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(day.aiSummary),
            const SizedBox(height: 12),
            Text(
              day.aiRecommendation,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MiniChip(
                  label: 'Readiness',
                  value: '${day.expectedReadiness}',
                ),
                _MiniChip(
                  label: 'Fatiga',
                  value: day.expectedFatigue.toUpperCase(),
                ),
                _MiniChip(label: 'Duración', value: '${day.totalMinutes} min'),
                _MiniChip(label: 'Km', value: day.totalKm.toStringAsFixed(1)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleWarningCard extends StatelessWidget {
  final dynamic day;

  const _SimpleWarningCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final warnings = <String>[];

    if (day.expectedFatigue == 'orange' || day.expectedFatigue == 'red') {
      warnings.add('No agregues entrenamiento extra.');
    }

    if (day.hasRecoveryBlock) {
      warnings.add('Respeta los bloques de recuperación.');
    }

    if (day.hasDoubleSession) {
      warnings.add('Come e hidrátate bien entre sesiones.');
    }

    if (day.totalLoad >= 75) {
      warnings.add('Prioriza técnica limpia sobre esfuerzo máximo.');
    }

    if (warnings.isEmpty) {
      warnings.add('Sigue el plan tal como fue enviado por tu entrenador.');
    }

    return Card(
      color: Colors.blueGrey.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Indicaciones para el atleta',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...warnings.map(
              (warning) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(warning)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AthleteBlockCard extends StatelessWidget {
  final DailyTrainingBlock block;

  const _AthleteBlockCard({required this.block});

  String get momentText {
    switch (block.moment) {
      case TrainingBlockMoment.morning:
        return 'Parte inicial / Mañana';
      case TrainingBlockMoment.afternoon:
        return 'Parte central / Tarde';
      case TrainingBlockMoment.evening:
        return 'Parte final / Noche';
    }
  }

  IconData get icon {
    switch (block.type) {
      case TrainingBlockType.skating:
        return Icons.speed;
      case TrainingBlockType.strength:
        return Icons.fitness_center;
      case TrainingBlockType.cycling:
        return Icons.directions_bike;
      case TrainingBlockType.mobility:
        return Icons.self_improvement;
      case TrainingBlockType.recovery:
        return Icons.spa;
      case TrainingBlockType.activation:
        return Icons.bolt;
      case TrainingBlockType.technical:
        return Icons.sports;
      case TrainingBlockType.aerobic:
        return Icons.favorite;
    }
  }

  Color get color {
    if (block.recoveryFocused) return Colors.green;
    if (block.taperFocused) return Colors.orange;

    switch (block.type) {
      case TrainingBlockType.skating:
        return Colors.blue;
      case TrainingBlockType.strength:
        return Colors.red;
      case TrainingBlockType.cycling:
        return Colors.cyan;
      case TrainingBlockType.mobility:
        return Colors.blueGrey;
      case TrainingBlockType.recovery:
        return Colors.green;
      case TrainingBlockType.activation:
        return Colors.amber;
      case TrainingBlockType.technical:
        return Colors.indigo;
      case TrainingBlockType.aerobic:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.14),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    momentText,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (block.recoveryFocused)
                  const Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text('Recuperación'),
                  ),
                if (block.taperFocused)
                  const Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text('Taper'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              block.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(block.description),
            const SizedBox(height: 12),
            _BlockRow(label: 'Duración', value: '${block.durationMinutes} min'),
            _BlockRow(
              label: 'Kilómetros',
              value: '${block.km.toStringAsFixed(1)} km',
            ),
            _BlockRow(label: 'Zona FC', value: 'Z${block.targetHeartRateZone}'),
            _BlockRow(label: 'Carga', value: '${block.targetLoad}'),
            const SizedBox(height: 12),
            _AthleteProfessionalPlanSection(block: block),
          ],
        ),
      ),
    );
  }
}

class _AthleteProfessionalPlanSection extends StatelessWidget {
  final DailyTrainingBlock block;

  const _AthleteProfessionalPlanSection({required this.block});

  @override
  Widget build(BuildContext context) {
    if (!block.hasProfessionalDetails) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        const Text(
          'Qué hacer',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _PlanList(
          title: 'Calentamiento',
          icon: Icons.local_fire_department,
          items: block.warmup,
        ),
        _PlanList(
          title: 'Bloque principal',
          icon: Icons.flag,
          items: block.mainSet,
        ),
        _PlanList(
          title: 'Ejercicios',
          icon: Icons.list_alt,
          items: block.exercises,
        ),
        _StrengthExerciseVisualSection(items: block.strengthExercises),
        _PlanList(
          title: 'Pliometría',
          icon: Icons.bolt,
          items: block.plyometricExercises,
        ),
        _PlanList(
          title: 'Técnica',
          icon: Icons.sports,
          items: block.technicalCues,
        ),
        _PlanList(
          title: 'Táctica',
          icon: Icons.route,
          items: block.tacticalCues,
        ),
        _PlanList(
          title: 'Vuelta a la calma',
          icon: Icons.self_improvement,
          items: block.cooldown,
        ),
        _PlanList(
          title: 'Notas importantes',
          icon: Icons.edit_note,
          items: block.coachingNotes,
        ),
        _PlanList(
          title: 'Corta el entrenamiento si aparece',
          icon: Icons.warning_amber,
          items: block.stopCriteria,
          warning: true,
        ),
      ],
    );
  }
}

class _StrengthExerciseVisualSection extends StatelessWidget {
  final List<String> items;

  const _StrengthExerciseVisualSection({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final visuals = items
        .map(StrengthExerciseLibrary.resolveFromText)
        .toList(growable: false);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.fitness_center, size: 20, color: Colors.red),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Fuerza / pesas',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...visuals.asMap().entries.map(
            (entry) => _StrengthExerciseCard(
              index: entry.key + 1,
              visual: entry.value,
            ),
          ),
        ],
      ),
    );
  }
}

class _StrengthExerciseCard extends StatelessWidget {
  final int index;
  final StrengthExerciseVisual visual;

  const _StrengthExerciseCard({required this.index, required this.visual});

  @override
  Widget build(BuildContext context) {
    final exercise = visual.definition;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: exercise.color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: exercise.color.withOpacity(0.10),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: exercise.color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    exercise.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: exercise.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    visual.prescription,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _ExerciseVisualPlaceholder(exercise: exercise),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  exercise.description,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                _ExerciseInfoRow(
                  label: 'Músculos',
                  value: exercise.primaryMuscles,
                  icon: Icons.accessibility_new,
                  color: exercise.color,
                ),
                _ExerciseInfoRow(
                  label: 'Transferencia',
                  value: exercise.sportTransfer,
                  icon: Icons.speed,
                  color: exercise.color,
                ),
                const SizedBox(height: 8),
                _ExerciseCueWrap(
                  title: 'Claves técnicas',
                  items: exercise.coachingCues.take(3).toList(),
                  color: exercise.color,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseVisualPlaceholder extends StatelessWidget {
  final StrengthExerciseDefinition exercise;

  const _ExerciseVisualPlaceholder({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            exercise.color.withOpacity(0.16),
            exercise.color.withOpacity(0.04),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 20,
            top: 18,
            child: Icon(
              exercise.icon,
              size: 76,
              color: exercise.color.withOpacity(0.28),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: exercise.color.withOpacity(0.18),
                  child: Icon(exercise.icon, size: 38, color: exercise.color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    exercise.category,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: exercise.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 14,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.90),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle_outline, size: 18),
                  SizedBox(width: 4),
                  Text(
                    'GIF próximamente',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ExerciseInfoRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCueWrap extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;

  const _ExerciseCueWrap({
    required this.title,
    required this.items,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 7),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: items
              .map(
                (item) => Chip(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: color.withOpacity(0.10),
                  label: Text(item),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _PlanList extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;
  final bool warning;

  const _PlanList({
    required this.title,
    required this.icon,
    required this.items,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final color = warning ? Colors.red : Colors.blueGrey;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    warning ? '!' : '�?�',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final String value;

  const _MiniChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}

class _BlockRow extends StatelessWidget {
  final String label;
  final String value;

  const _BlockRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}


