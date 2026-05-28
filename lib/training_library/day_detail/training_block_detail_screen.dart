import 'package:flutter/material.dart';

import '../../daily_training_block.dart';
import '../gym/gym_plan_detail_screen.dart';
import 'cycling_block_detail_screen.dart';
import 'physical_work_detail_screen.dart';
import 'skating_block_detail_screen.dart';

class TrainingBlockDetailScreen extends StatelessWidget {
  final DailyTrainingBlock block;

  const TrainingBlockDetailScreen({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    if (block.type == TrainingBlockType.strength) {
      return GymPlanDetailScreen(block: block);
    }

    if (block.type == TrainingBlockType.skating) {
      return SkatingBlockDetailScreen(block: block);
    }

    if (block.type == TrainingBlockType.cycling) {
      return CyclingBlockDetailScreen(block: block);
    }

    if (block.type == TrainingBlockType.mobility ||
        block.type == TrainingBlockType.recovery ||
        block.type == TrainingBlockType.activation ||
        block.type == TrainingBlockType.aerobic ||
        block.type == TrainingBlockType.technical) {
      return PhysicalWorkDetailScreen(block: block);
    }

    return Scaffold(
      appBar: AppBar(title: Text(_title())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderCard(block: block),
          const SizedBox(height: 16),

          if (block.description.trim().isNotEmpty)
            _InfoCard(
              title: 'Descripción',
              icon: Icons.description,
              content: block.description,
            ),

          if (block.mainSet.isNotEmpty)
            _ListCard(
              title: _mainSetTitle(),
              icon: _mainSetIcon(),
              items: block.mainSet,
            ),

          if (block.exercises.isNotEmpty)
            _ListCard(
              title: _exerciseTitle(),
              icon: Icons.checklist,
              items: block.exercises,
            ),

          if (block.technicalCues.isNotEmpty)
            _ListCard(
              title: 'Cues técnicos',
              icon: Icons.psychology,
              items: block.technicalCues,
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
        ],
      ),
    );
  }

  String _title() {
    switch (block.type) {
      case TrainingBlockType.cycling:
        return 'Trabajo de bicicleta';
      case TrainingBlockType.skating:
        return 'Sesión en pista';
      case TrainingBlockType.mobility:
        return 'Movilidad';
      case TrainingBlockType.recovery:
        return 'Recuperación';
      case TrainingBlockType.activation:
        return 'Activación';
      case TrainingBlockType.technical:
        return 'Trabajo técnico';
      case TrainingBlockType.aerobic:
        return 'Trabajo aeróbico';
      case TrainingBlockType.strength:
        return 'Plan de gimnasio';
    }
  }

  String _mainSetTitle() {
    switch (block.type) {
      case TrainingBlockType.cycling:
        return 'Bloque principal de bicicleta';
      case TrainingBlockType.skating:
        return 'Bloque principal en pista';
      case TrainingBlockType.mobility:
        return 'Secuencia de movilidad';
      case TrainingBlockType.recovery:
        return 'Protocolo de recuperación';
      case TrainingBlockType.activation:
        return 'Secuencia de activación';
      case TrainingBlockType.technical:
        return 'Trabajo técnico principal';
      case TrainingBlockType.aerobic:
        return 'Bloque aeróbico';
      case TrainingBlockType.strength:
        return 'Main Set';
    }
  }

  String _exerciseTitle() {
    switch (block.type) {
      case TrainingBlockType.cycling:
        return 'Trabajo complementario';
      case TrainingBlockType.skating:
        return 'Ejercicios en pista';
      case TrainingBlockType.mobility:
        return 'Ejercicios de movilidad';
      case TrainingBlockType.recovery:
        return 'Tareas de recuperación';
      case TrainingBlockType.activation:
        return 'Ejercicios de activación';
      case TrainingBlockType.technical:
        return 'Ejercicios técnicos';
      case TrainingBlockType.aerobic:
        return 'Trabajo complementario';
      case TrainingBlockType.strength:
        return 'Ejercicios complementarios';
    }
  }

  IconData _mainSetIcon() {
    switch (block.type) {
      case TrainingBlockType.cycling:
        return Icons.directions_bike;
      case TrainingBlockType.skating:
        return Icons.speed;
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
      case TrainingBlockType.strength:
        return Icons.fitness_center;
    }
  }
}

class _HeaderCard extends StatelessWidget {
  final DailyTrainingBlock block;

  const _HeaderCard({required this.block});

  Color _color() {
    if (block.targetLoad >= 75) return Colors.red;
    if (block.targetLoad >= 50) return Colors.orange;
    return Colors.green;
  }

  IconData _icon() {
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

  String _typeText() {
    switch (block.type) {
      case TrainingBlockType.skating:
        return 'Patines';
      case TrainingBlockType.strength:
        return 'Gimnasio';
      case TrainingBlockType.cycling:
        return 'Bicicleta';
      case TrainingBlockType.mobility:
        return 'Movilidad';
      case TrainingBlockType.recovery:
        return 'Recuperación';
      case TrainingBlockType.activation:
        return 'Activación';
      case TrainingBlockType.technical:
        return 'Técnica';
      case TrainingBlockType.aerobic:
        return 'Aeróbico';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();

    return Card(
      color: color.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.18),
                  child: Icon(_icon(), color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _typeText(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              block.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (block.aiReason.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(block.aiReason),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _Metric(
                  label: 'Carga',
                  value: '${block.targetLoad}',
                  color: color,
                ),
                _Metric(
                  label: 'Min',
                  value: '${block.durationMinutes}',
                  color: Colors.blue,
                ),
                _Metric(
                  label: 'Zona',
                  value: 'Z${block.targetHeartRateZone}',
                  color: Colors.purple,
                ),
                if (block.km > 0)
                  _Metric(
                    label: 'Km',
                    value: block.km.toStringAsFixed(1),
                    color: Colors.teal,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Metric({
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
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(content),
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
    if (items.isEmpty) return const SizedBox.shrink();

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
                    Expanded(child: Text(item)),
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


