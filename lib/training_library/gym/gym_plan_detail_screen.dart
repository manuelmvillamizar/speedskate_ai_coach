import 'package:flutter/material.dart';

import '../../daily_training_block.dart';
import 'gym_exercise_card.dart';
import 'gym_exercise_parser.dart';

class GymPlanDetailScreen extends StatelessWidget {
  final DailyTrainingBlock block;

  const GymPlanDetailScreen({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final parsedExercises = GymExerciseParser.parse([
      ...block.mainSet,
      ...block.exercises,
      ...block.technicalCues,
      ...block.coachingNotes,
      block.title,
      block.description,
      block.aiReason,
    ]);

    return Scaffold(
      appBar: AppBar(title: const Text('Plan de fuerza')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderCard(block: block),

          const SizedBox(height: 18),

          if (block.description.trim().isNotEmpty)
            _InfoCard(
              title: 'Objetivo fisiológico',
              icon: Icons.flag,
              content: block.description,
            ),

          if (block.warmup.isNotEmpty)
            _ListCard(
              title: 'Preparación',
              icon: Icons.local_fire_department_outlined,
              items: block.warmup,
            ),

          if (block.mainSet.isNotEmpty)
            _StrengthSequenceCard(items: block.mainSet),

          if (block.exercises.isNotEmpty)
            _ListCard(
              title: 'Trabajo complementario',
              icon: Icons.extension,
              items: block.exercises,
            ),

          if (block.technicalCues.isNotEmpty)
            _ListCard(
              title: 'Cues técnicos',
              icon: Icons.psychology,
              items: block.technicalCues,
            ),

          if (block.cooldown.isNotEmpty)
            _ListCard(
              title: 'Vuelta a la calma',
              icon: Icons.spa,
              items: block.cooldown,
            ),

          if (block.coachingNotes.isNotEmpty)
            _ListCard(
              title: 'Notas del entrenador',
              icon: Icons.record_voice_over,
              items: block.coachingNotes,
            ),

          if (block.stopCriteria.isNotEmpty)
            _ListCard(
              title: 'Criterios de corte',
              icon: Icons.warning_amber,
              items: block.stopCriteria,
            ),

          const SizedBox(height: 20),

          if (parsedExercises.isNotEmpty) ...[
            const Text(
              'Ejercicios principales',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            ...parsedExercises.map(
              (exercise) => GymExerciseCard(
                exercise: exercise,
              ),
            ),
          ],

          const SizedBox(height: 20),

          _TransferCard(block: block),

          const SizedBox(height: 20),

          _PerformanceProtectionCard(block: block),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final DailyTrainingBlock block;

  const _HeaderCard({required this.block});

  Color _loadColor() {
    if (block.targetLoad >= 75) return Colors.red;
    if (block.targetLoad >= 50) return Colors.orange;
    return Colors.green;
  }

  String _energySystemText() {
    switch (block.energySystem) {
      case TrainingEnergySystem.none:
        return 'Sin sistema dominante';
      case TrainingEnergySystem.aerobic:
        return 'Aeróbico';
      case TrainingEnergySystem.anaerobicAlactic:
        return 'Anaeróbico aláctico';
      case TrainingEnergySystem.anaerobicLactic:
        return 'Anaeróbico láctico';
      case TrainingEnergySystem.mixed:
        return 'Mixto';
    }
  }

  String _neuromuscularText() {
    switch (block.neuromuscularLoad) {
      case NeuromuscularLoad.none:
        return 'Nula';
      case NeuromuscularLoad.low:
        return 'Baja';
      case NeuromuscularLoad.moderate:
        return 'Moderada';
      case NeuromuscularLoad.high:
        return 'Alta';
      case NeuromuscularLoad.maximal:
        return 'Máxima';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _loadColor();

    return Card(
      color: color.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.18),
                  radius: 26,
                  child: Icon(Icons.fitness_center, color: color),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Trabajo de fuerza',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Text(
              block.title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            if (block.aiReason.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                block.aiReason,
                style: const TextStyle(height: 1.4),
              ),
            ],

            const SizedBox(height: 18),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetricChip(
                  label: 'Carga',
                  value: '${block.targetLoad}',
                  color: color,
                ),
                _MetricChip(
                  label: 'Minutos',
                  value: '${block.durationMinutes}',
                  color: Colors.blue,
                ),
                _MetricChip(
                  label: 'Zona',
                  value: 'Z${block.targetHeartRateZone}',
                  color: Colors.purple,
                ),
                _MetricChip(
                  label: 'Sistema',
                  value: _energySystemText(),
                  color: Colors.indigo,
                ),
                _MetricChip(
                  label: 'Carga neural',
                  value: _neuromuscularText(),
                  color: Colors.deepOrange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: color.withOpacity(0.12),
      label: Text('$label: $value'),
    );
  }
}

class _StrengthSequenceCard extends StatelessWidget {
  final List<String> items;

  const _StrengthSequenceCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.fitness_center),
                SizedBox(width: 8),
                Text(
                  'Bloque principal',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            ...items.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
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

class _TransferCard extends StatelessWidget {
  final DailyTrainingBlock block;

  const _TransferCard({required this.block});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black87,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bolt, color: Colors.orange),
                SizedBox(width: 10),
                Text(
                  'Transferencia fuerza → velocidad',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            const _TransferLine(
              text:
                  'Después de ejercicios principales de fuerza, incluir transferencia explosiva o reactiva.',
            ),

            const _TransferLine(
              text:
                  'Usar saltos específicos, bounds, saltos horizontales o aceleraciones cortas para convertir fuerza en velocidad útil de patinaje.',
            ),

            const _TransferLine(
              text:
                  'Mantener alta calidad técnica y cortar si aparece pérdida de velocidad o coordinación.',
            ),

            if (block.targetLoad >= 75)
              const _TransferLine(
                text:
                    'Carga alta: aumentar descanso entre series para preservar producción de fuerza y potencia.',
              ),

            if (block.neuromuscularLoad == NeuromuscularLoad.high ||
                block.neuromuscularLoad == NeuromuscularLoad.maximal)
              const _TransferLine(
                text:
                    'Alta exigencia neural: priorizar ejecución explosiva sobre volumen excesivo.',
              ),
          ],
        ),
      ),
    );
  }
}

class _TransferLine extends StatelessWidget {
  final String text;

  const _TransferLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 8, color: Colors.orange),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceProtectionCard extends StatelessWidget {
  final DailyTrainingBlock block;

  const _PerformanceProtectionCard({required this.block});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blueGrey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.health_and_safety, color: Colors.greenAccent),
                SizedBox(width: 10),
                Text(
                  'Protección fisiológica',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            const _TransferLine(
              text:
                  'Mantener técnica estable incluso bajo fatiga neuromuscular.',
            ),

            const _TransferLine(
              text:
                  'Evitar pérdida de velocidad de ejecución en las últimas series.',
            ),

            const _TransferLine(
              text:
                  'Controlar tendón rotuliano, Aquiles y zona lumbar en cargas altas.',
            ),

            if (block.recoveryFocused)
              const _TransferLine(
                text:
                    'Bloque orientado a recuperación: priorizar movilidad y activación ligera.',
              ),

            if (block.taperFocused)
              const _TransferLine(
                text:
                    'Bloque en taper: conservar potencia sin generar fatiga residual.',
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String content;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(content, style: const TextStyle(height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;

  const _ListCard({
    required this.title,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('�?� '),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(height: 1.4),
                      ),
                    ),
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

