import 'package:flutter/material.dart';

import '../../daily_training_block.dart';

class CyclingBlockDetailScreen extends StatelessWidget {
  final DailyTrainingBlock block;

  const CyclingBlockDetailScreen({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final dominantZone = 'Z${block.targetHeartRateZone}';

    return Scaffold(
      appBar: AppBar(title: const Text('Trabajo de bicicleta')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderCard(block: block, dominantZone: dominantZone),

          const SizedBox(height: 18),

          if (block.description.trim().isNotEmpty)
            _InfoCard(
              title: 'Objetivo fisiológico',
              icon: Icons.flag,
              content: block.description,
            ),

          if (block.warmup.isNotEmpty)
            _InfoListCard(
              title: 'Calentamiento',
              icon: Icons.local_fire_department_outlined,
              items: block.warmup,
            ),

          if (block.mainSet.isNotEmpty)
            _IntervalBlockCard(title: 'Bloque principal', items: block.mainSet),

          if (block.exercises.isNotEmpty)
            _InfoListCard(
              title: 'Trabajo complementario',
              icon: Icons.extension,
              items: block.exercises,
            ),

          if (block.technicalCues.isNotEmpty)
            _InfoListCard(
              title: 'Cues técnicos',
              icon: Icons.psychology,
              items: block.technicalCues,
            ),

          if (block.cooldown.isNotEmpty)
            _InfoListCard(
              title: 'Vuelta a la calma',
              icon: Icons.spa,
              items: block.cooldown,
            ),

          if (block.coachingNotes.isNotEmpty)
            _InfoListCard(
              title: 'Notas del entrenador',
              icon: Icons.record_voice_over,
              items: block.coachingNotes,
            ),

          if (block.stopCriteria.isNotEmpty)
            _InfoListCard(
              title: 'Criterios de corte',
              icon: Icons.warning_amber,
              items: block.stopCriteria,
            ),

          const SizedBox(height: 18),

          _BikeProtectionCard(block: block),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final DailyTrainingBlock block;
  final String dominantZone;

  const _HeaderCard({required this.block, required this.dominantZone});

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
                  radius: 26,
                  backgroundColor: color.withOpacity(0.18),
                  child: Icon(Icons.directions_bike, color: color),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Sesión de bicicleta',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Text(
              block.title,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),

            if (block.aiReason.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(block.aiReason, style: const TextStyle(height: 1.4)),
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
                  label: 'Zona dominante',
                  value: dominantZone,
                  color: Colors.purple,
                ),
                _MetricChip(
                  label: 'Minutos',
                  value: '${block.durationMinutes}',
                  color: Colors.blue,
                ),
                if (block.km > 0)
                  _MetricChip(
                    label: 'Km',
                    value: block.km.toStringAsFixed(1),
                    color: Colors.teal,
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

class _IntervalBlockCard extends StatelessWidget {
  final String title;
  final List<String> items;

  const _IntervalBlockCard({required this.title, required this.items});

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
                const Icon(Icons.timer),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            ...items.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
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
                      child: Icon(Icons.play_circle_fill, color: Colors.blue),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 15, height: 1.4),
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
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 12),
            Text(content, style: const TextStyle(height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _InfoListCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;

  const _InfoListCard({
    required this.title,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
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

            const SizedBox(height: 12),

            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('�?� '),
                    Expanded(
                      child: Text(item, style: const TextStyle(height: 1.4)),
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

class _BikeProtectionCard extends StatelessWidget {
  final DailyTrainingBlock block;

  const _BikeProtectionCard({required this.block});

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
                Icon(Icons.health_and_safety, color: Colors.tealAccent),
                SizedBox(width: 10),
                Text(
                  'Función fisiológica de la bicicleta',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            const _FocusLine(
              text:
                  'Usar la bicicleta para controlar carga cardiovascular sin impacto específico de pista.',
            ),
            const _FocusLine(
              text:
                  'Mantener cadencia estable y sensación controlada según la zona indicada.',
            ),

            if (block.targetHeartRateZone <= 2)
              const _FocusLine(
                text:
                    'Trabajo Z1-Z2: priorizar recuperación, circulación y base aeróbica.',
              ),

            if (block.targetHeartRateZone == 3)
              const _FocusLine(
                text:
                    'Trabajo Z3: sostener ritmo sin convertirlo en sesión lactácida.',
              ),

            if (block.targetHeartRateZone >= 4)
              const _FocusLine(
                text:
                    'Alta intensidad en bicicleta: controlar acumulación de Z4/Z5 y recuperación posterior.',
              ),

            if (block.recoveryFocused)
              const _FocusLine(
                text:
                    'Bloque de recuperación: debe sentirse fácil y mejorar la sensación general.',
              ),

            if (block.taperFocused)
              const _FocusLine(
                text:
                    'Bloque en taper: conservar activación sin generar fatiga residual.',
              ),
          ],
        ),
      ),
    );
  }
}

class _FocusLine extends StatelessWidget {
  final String text;

  const _FocusLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 8, color: Colors.tealAccent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

