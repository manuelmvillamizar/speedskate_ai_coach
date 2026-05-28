import 'package:flutter/material.dart';

import '../../daily_training_block.dart';

class PhysicalWorkDetailScreen extends StatelessWidget {
  final DailyTrainingBlock block;

  const PhysicalWorkDetailScreen({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderCard(block: block),
          const SizedBox(height: 18),

          if (block.description.trim().isNotEmpty)
            _InfoCard(
              title: 'Objetivo del trabajo',
              icon: Icons.flag,
              content: block.description,
            ),

          if (block.warmup.isNotEmpty)
            _InfoListCard(
              title: 'Preparación',
              icon: Icons.local_fire_department_outlined,
              items: block.warmup,
            ),

          if (block.mainSet.isNotEmpty)
            _SequenceCard(
              title: _mainSetTitle(),
              icon: _mainSetIcon(),
              items: block.mainSet,
            ),

          if (block.exercises.isNotEmpty)
            _InfoListCard(
              title: 'Ejercicios',
              icon: Icons.checklist,
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

          _ProtectionCard(block: block),
        ],
      ),
    );
  }

  String _title() {
    switch (block.type) {
      case TrainingBlockType.mobility:
        return 'Trabajo de movilidad';
      case TrainingBlockType.recovery:
        return 'Recuperación';
      case TrainingBlockType.activation:
        return 'Activación';
      case TrainingBlockType.aerobic:
        return 'Trabajo aeróbico';
      case TrainingBlockType.technical:
        return 'Trabajo técnico';
      case TrainingBlockType.skating:
        return 'Sesión en pista';
      case TrainingBlockType.cycling:
        return 'Bicicleta';
      case TrainingBlockType.strength:
        return 'Gimnasio';
    }
  }

  String _mainSetTitle() {
    switch (block.type) {
      case TrainingBlockType.mobility:
        return 'Secuencia de movilidad';
      case TrainingBlockType.recovery:
        return 'Protocolo de recuperación';
      case TrainingBlockType.activation:
        return 'Secuencia de activación';
      case TrainingBlockType.aerobic:
        return 'Bloque aeróbico';
      case TrainingBlockType.technical:
        return 'Trabajo técnico principal';
      case TrainingBlockType.skating:
        return 'Bloque en pista';
      case TrainingBlockType.cycling:
        return 'Bloque de bicicleta';
      case TrainingBlockType.strength:
        return 'Bloque de fuerza';
    }
  }

  IconData _mainSetIcon() {
    switch (block.type) {
      case TrainingBlockType.mobility:
        return Icons.self_improvement;
      case TrainingBlockType.recovery:
        return Icons.spa;
      case TrainingBlockType.activation:
        return Icons.bolt;
      case TrainingBlockType.aerobic:
        return Icons.favorite;
      case TrainingBlockType.technical:
        return Icons.sports;
      case TrainingBlockType.skating:
        return Icons.speed;
      case TrainingBlockType.cycling:
        return Icons.directions_bike;
      case TrainingBlockType.strength:
        return Icons.fitness_center;
    }
  }
}

class _HeaderCard extends StatelessWidget {
  final DailyTrainingBlock block;

  const _HeaderCard({required this.block});

  Color _color() {
    switch (block.type) {
      case TrainingBlockType.recovery:
        return Colors.green;
      case TrainingBlockType.mobility:
        return Colors.teal;
      case TrainingBlockType.activation:
        return Colors.orange;
      case TrainingBlockType.aerobic:
        return Colors.blue;
      case TrainingBlockType.technical:
        return Colors.indigo;
      default:
        if (block.targetLoad >= 75) return Colors.red;
        if (block.targetLoad >= 50) return Colors.orange;
        return Colors.green;
    }
  }

  IconData _icon() {
    switch (block.type) {
      case TrainingBlockType.mobility:
        return Icons.self_improvement;
      case TrainingBlockType.recovery:
        return Icons.spa;
      case TrainingBlockType.activation:
        return Icons.bolt;
      case TrainingBlockType.aerobic:
        return Icons.favorite;
      case TrainingBlockType.technical:
        return Icons.sports;
      case TrainingBlockType.skating:
        return Icons.speed;
      case TrainingBlockType.cycling:
        return Icons.directions_bike;
      case TrainingBlockType.strength:
        return Icons.fitness_center;
    }
  }

  String _typeText() {
    switch (block.type) {
      case TrainingBlockType.mobility:
        return 'Movilidad';
      case TrainingBlockType.recovery:
        return 'Recuperación';
      case TrainingBlockType.activation:
        return 'Activación';
      case TrainingBlockType.aerobic:
        return 'Aeróbico';
      case TrainingBlockType.technical:
        return 'Técnico';
      case TrainingBlockType.skating:
        return 'Patines';
      case TrainingBlockType.cycling:
        return 'Bicicleta';
      case TrainingBlockType.strength:
        return 'Gimnasio';
    }
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
    final color = _color();

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
                  child: Icon(_icon(), color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _typeText(),
                    style: const TextStyle(
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
                  label: 'Minutos',
                  value: '${block.durationMinutes}',
                  color: Colors.blue,
                ),
                _MetricChip(
                  label: 'Zona',
                  value: 'Z${block.targetHeartRateZone}',
                  color: Colors.purple,
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

class _SequenceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;

  const _SequenceCard({
    required this.title,
    required this.icon,
    required this.items,
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
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...items.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final item = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      child: Text(
                        '$index',
                        style: const TextStyle(fontSize: 12),
                      ),
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
              );
            }),
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
    if (items.isEmpty) return const SizedBox.shrink();

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

class _ProtectionCard extends StatelessWidget {
  final DailyTrainingBlock block;

  const _ProtectionCard({required this.block});

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
            const SizedBox(height: 16),
            _ProtectionLine(text: _protectionText()),
            if (block.targetLoad <= 35)
              const _ProtectionLine(
                text:
                    'Carga baja: orientado a recuperación, activación o mantenimiento.',
              ),
            if (block.type == TrainingBlockType.recovery)
              const _ProtectionLine(
                text:
                    'Priorizar respiración, movilidad suave y reducción del estrés interno.',
              ),
            if (block.type == TrainingBlockType.activation)
              const _ProtectionLine(
                text:
                    'Activar sin generar fatiga residual antes de la sesión principal.',
              ),
            if (block.type == TrainingBlockType.mobility)
              const _ProtectionLine(
                text:
                    'Mejorar rango útil sin irritar tejido ni aumentar tensión neuromuscular.',
              ),
            if (block.type == TrainingBlockType.aerobic)
              const _ProtectionLine(
                text:
                    'Mantener estímulo aeróbico controlado sin invadir recuperación.',
              ),
            if (block.type == TrainingBlockType.technical)
              const _ProtectionLine(
                text:
                    'Conservar calidad técnica con baja interferencia fisiológica.',
              ),
            if (block.taperFocused)
              const _ProtectionLine(
                text:
                    'Bloque en taper: preservar frescura y evitar fatiga residual.',
              ),
          ],
        ),
      ),
    );
  }

  String _protectionText() {
    switch (block.type) {
      case TrainingBlockType.recovery:
        return 'Este bloque protege recuperación y disponibilidad para próximas cargas.';
      case TrainingBlockType.mobility:
        return 'Este bloque mejora movilidad funcional y reduce compensaciones.';
      case TrainingBlockType.activation:
        return 'Este bloque prepara al sistema neuromuscular sin sobrecargar.';
      case TrainingBlockType.aerobic:
        return 'Este bloque mantiene base aeróbica con bajo riesgo fisiológico.';
      case TrainingBlockType.technical:
        return 'Este bloque mejora calidad técnica con carga controlada.';
      default:
        return 'Bloque usado para modular carga y proteger rendimiento.';
    }
  }
}

class _ProtectionLine extends StatelessWidget {
  final String text;

  const _ProtectionLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 8, color: Colors.greenAccent),
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

