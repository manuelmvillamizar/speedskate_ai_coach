import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'athlete_context_service.dart';
import 'athlete_program_service.dart';
import 'coach_planning_preferences.dart';

class CoachPlanningPreferencesScreen extends StatefulWidget {
  final String athleteId;

  const CoachPlanningPreferencesScreen({super.key, required this.athleteId});

  @override
  State<CoachPlanningPreferencesScreen> createState() =>
      _CoachPlanningPreferencesScreenState();
}

class _CoachPlanningPreferencesScreenState
    extends State<CoachPlanningPreferencesScreen> {
  late CoachPlanningPreferences preferences;

  @override
  void initState() {
    super.initState();

    final service = AthleteProgramService.instance;
    final athlete = service.athletes.firstWhere(
      (item) => item.id == widget.athleteId,
    );

    preferences = athlete.planningPreferences;
  }

  Future<void> save() async {
    await context.read<AthleteProgramService>().updatePlanningPreferences(
      athleteId: widget.athleteId,
      preferences: preferences,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filosofía de entrenamiento guardada.')),
    );

    Navigator.pop(context);
  }

  void update(CoachPlanningPreferences value) {
    setState(() {
      preferences = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AthleteProgramService>();
    final athleteContext = context.watch<AthleteContextService>();

    final athlete = service.athletes.firstWhere(
      (item) => item.id == widget.athleteId,
    );

    final feasibility = _CoachPlanFeasibility.evaluate(
      preferences: preferences,
      readiness: athleteContext.activeReadinessScore,
      fatigueStatus: athleteContext.activeFatigueStatus,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planificación del entrenador'),
        actions: [
          TextButton.icon(
            onPressed: save,
            icon: const Icon(Icons.save),
            label: const Text('Guardar'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeroCard(
            athleteName: athlete.name,
            totalSessions: preferences.totalWeeklySessions,
            feasibility: feasibility,
          ),
          const SizedBox(height: 16),
          _CoachLogicCard(feasibility: feasibility),
          const SizedBox(height: 16),
          _WeeklySummaryCard(preferences: preferences),
          const SizedBox(height: 16),
          _SwitchCard(
            icon: Icons.calendar_month,
            title: 'Usar temporada',
            subtitle:
                'Organiza fases, taper, descargas y competencias. Si está apagado, la app genera semanas libres.',
            value: preferences.useSeasonPlanning,
            onChanged: (value) {
              update(preferences.copyWith(useSeasonPlanning: value));
            },
          ),
          _SwitchCard(
            icon: Icons.view_day,
            title: 'Permitir doble sesión',
            subtitle:
                'Permite mañana/tarde/noche cuando el entrenador pide mucho volumen semanal.',
            value: preferences.allowDoubleSessions,
            onChanged: (value) {
              update(preferences.copyWith(allowDoubleSessions: value));
            },
          ),
          _SwitchCard(
            icon: Icons.directions_bike,
            title: 'Permitir bicicleta',
            subtitle:
                'Si se apaga, la app no propone bicicleta y reorganiza la carga con otros medios.',
            value: preferences.allowCycling,
            onChanged: (value) {
              update(
                preferences.copyWith(
                  allowCycling: value,
                  cyclingSessionsPerWeek: value
                      ? preferences.cyclingSessionsPerWeek
                      : 0,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const _SectionTitle(
            title: 'Distribución semanal',
            subtitle:
                'El entrenador propone. La fisiología evalúa. La app ajusta o advierte.',
          ),
          const SizedBox(height: 12),
          _SessionSlider(
            icon: Icons.speed,
            color: Colors.blue,
            title: 'Patines',
            value: preferences.skatingSessionsPerWeek,
            max: 14,
            subtitle: 'Sesiones sobre patines por semana.',
            onChanged: (value) {
              update(preferences.copyWith(skatingSessionsPerWeek: value));
            },
          ),
          _SessionSlider(
            icon: Icons.fitness_center,
            color: Colors.deepPurple,
            title: 'Gimnasio',
            value: preferences.strengthSessionsPerWeek,
            max: 7,
            subtitle: 'Fuerza, potencia, transferencia y trabajo físico.',
            onChanged: (value) {
              update(preferences.copyWith(strengthSessionsPerWeek: value));
            },
          ),
          _SessionSlider(
            icon: Icons.directions_bike,
            color: Colors.teal,
            title: 'Bicicleta',
            value: preferences.allowCycling
                ? preferences.cyclingSessionsPerWeek
                : 0,
            max: 7,
            enabled: preferences.allowCycling,
            subtitle: preferences.allowCycling
                ? 'Aeróbico o recuperación con bajo impacto.'
                : 'Bicicleta desactivada por preferencia del entrenador.',
            onChanged: (value) {
              update(preferences.copyWith(cyclingSessionsPerWeek: value));
            },
          ),
          _SessionSlider(
            icon: Icons.bolt,
            color: Colors.orange,
            title: 'Pliometría',
            value: preferences.plyometricSessionsPerWeek,
            max: 6,
            subtitle: 'Saltos, reactividad y transferencia fuerza → velocidad.',
            onChanged: (value) {
              update(preferences.copyWith(plyometricSessionsPerWeek: value));
            },
          ),
          _SessionSlider(
            icon: Icons.self_improvement,
            color: Colors.green,
            title: 'Movilidad',
            value: preferences.mobilitySessionsPerWeek,
            max: 7,
            subtitle: 'Movilidad, recuperación, rango útil y prevención.',
            onChanged: (value) {
              update(preferences.copyWith(mobilitySessionsPerWeek: value));
            },
          ),
          _SessionSlider(
            icon: Icons.accessibility_new,
            color: Colors.indigo,
            title: 'Core',
            value: preferences.coreSessionsPerWeek,
            max: 7,
            subtitle: 'Core, estabilidad lumbo-pélvica y control postural.',
            onChanged: (value) {
              update(preferences.copyWith(coreSessionsPerWeek: value));
            },
          ),
          const SizedBox(height: 16),
          const _SectionTitle(
            title: 'Prioridades del entrenador',
            subtitle:
                'Esto ayuda a la app a entender la filosofía del entrenador.',
          ),
          const SizedBox(height: 12),
          _PriorityGrid(preferences: preferences, onChanged: update),
          const SizedBox(height: 16),
          _StyleSelector(
            value: preferences.planningStyle,
            onChanged: (value) {
              update(preferences.copyWith(planningStyle: value));
            },
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: save,
            icon: const Icon(Icons.check),
            label: const Text('Guardar y aplicar al plan'),
          ),
        ],
      ),
    );
  }
}

class _CoachPlanFeasibility {
  final String status;
  final String title;
  final String message;
  final Color color;
  final IconData icon;
  final List<String> warnings;

  const _CoachPlanFeasibility({
    required this.status,
    required this.title,
    required this.message,
    required this.color,
    required this.icon,
    required this.warnings,
  });

  static _CoachPlanFeasibility evaluate({
    required CoachPlanningPreferences preferences,
    required int readiness,
    required String fatigueStatus,
  }) {
    final warnings = <String>[];

    final total = preferences.totalWeeklySessions;
    final neuralDemand =
        preferences.skatingSessionsPerWeek +
        preferences.strengthSessionsPerWeek +
        preferences.plyometricSessionsPerWeek;

    if (total >= 22) {
      warnings.add(
        'Volumen semanal muy alto. Conviene distribuirlo en doble sesión o reducir bloques accesorios.',
      );
    }

    if (!preferences.allowDoubleSessions && total > 10) {
      warnings.add(
        'El entrenador pide muchas sesiones, pero doble sesión está apagada.',
      );
    }

    if (preferences.plyometricSessionsPerWeek >= 4) {
      warnings.add(
        'Pliometría alta. Revisar tendón rotuliano, Aquiles, tibiales y fatiga neural.',
      );
    }

    if (preferences.strengthSessionsPerWeek >= 5) {
      warnings.add(
        'Gimnasio alto. La app debe proteger fuerza pesada si HRV/sueño/fatiga no acompañan.',
      );
    }

    if (neuralDemand >= 18) {
      warnings.add(
        'Demanda neural semanal alta: patines + gimnasio + pliometría cargan sistema nervioso.',
      );
    }

    if (readiness < 55) {
      warnings.add(
        'Readiness bajo. La app puede mantener la estructura, pero bajará intensidad o volumen.',
      );
    }

    if (fatigueStatus.toLowerCase() == 'red' ||
        fatigueStatus.toLowerCase() == 'orange') {
      warnings.add(
        'Fatiga elevada. La fisiología puede bloquear alta intensidad aunque el entrenador la programe.',
      );
    }

    if (warnings.isEmpty) {
      return const _CoachPlanFeasibility(
        status: 'compatible',
        title: 'Plan compatible',
        message:
            'La estructura semanal parece viable. La fisiología seguirá ajustando día a día.',
        color: Colors.green,
        icon: Icons.check_circle,
        warnings: [],
      );
    }

    if (warnings.length <= 2) {
      return _CoachPlanFeasibility(
        status: 'caution',
        title: 'Plan viable con cuidado',
        message:
            'La intención del entrenador se puede respetar, pero la app debe vigilar carga y recuperación.',
        color: Colors.orange,
        icon: Icons.warning_amber,
        warnings: warnings,
      );
    }

    return _CoachPlanFeasibility(
      status: 'risk',
      title: 'Plan exigente',
      message:
          'La intención del entrenador es fuerte. La app debe negociar con la fisiología y aplicar ajustes si hay riesgo.',
      color: Colors.red,
      icon: Icons.health_and_safety,
      warnings: warnings,
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String athleteName;
  final int totalSessions;
  final _CoachPlanFeasibility feasibility;

  const _HeroCard({
    required this.athleteName,
    required this.totalSessions,
    required this.feasibility,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF07111F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: feasibility.color.withOpacity(0.20),
              child: Icon(feasibility.icon, color: feasibility.color, size: 34),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    athleteName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'El entrenador propone. La fisiología negocia. La app aprende.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  '$totalSessions',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'sesiones/sem',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachLogicCard extends StatelessWidget {
  final _CoachPlanFeasibility feasibility;

  const _CoachLogicCard({required this.feasibility});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: feasibility.color.withOpacity(0.10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(feasibility.icon, color: feasibility.color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    feasibility.title,
                    style: TextStyle(
                      color: feasibility.color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(feasibility.message),
            if (feasibility.warnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...feasibility.warnings.map(
                (warning) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, size: 8, color: feasibility.color),
                      const SizedBox(width: 10),
                      Expanded(child: Text(warning)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WeeklySummaryCard extends StatelessWidget {
  final CoachPlanningPreferences preferences;

  const _WeeklySummaryCard({required this.preferences});

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryItem('Patines', preferences.skatingSessionsPerWeek, Icons.speed),
      _SummaryItem(
        'Gimnasio',
        preferences.strengthSessionsPerWeek,
        Icons.fitness_center,
      ),
      _SummaryItem(
        'Bici',
        preferences.allowCycling ? preferences.cyclingSessionsPerWeek : 0,
        Icons.directions_bike,
      ),
      _SummaryItem(
        'Pliometría',
        preferences.plyometricSessionsPerWeek,
        Icons.bolt,
      ),
      _SummaryItem(
        'Movilidad',
        preferences.mobilitySessionsPerWeek,
        Icons.self_improvement,
      ),
      _SummaryItem(
        'Core',
        preferences.coreSessionsPerWeek,
        Icons.accessibility_new,
      ),
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen semanal visual',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Así entiende la app la intención del entrenador.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: items.map((item) => _SummaryPill(item: item)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem {
  final String title;
  final int value;
  final IconData icon;

  const _SummaryItem(this.title, this.value, this.icon);
}

class _SummaryPill extends StatelessWidget {
  final _SummaryItem item;

  const _SummaryPill({required this.item});

  @override
  Widget build(BuildContext context) {
    final active = item.value > 0;
    final color = active ? Colors.blue : Colors.grey;

    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(active ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(active ? 0.20 : 0.10)),
      ),
      child: Row(
        children: [
          Icon(item.icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active ? Colors.black : Colors.black45,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            '${item.value}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: SwitchListTile(
        secondary: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class _SessionSlider extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final int value;
  final int max;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _SessionSlider({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.max,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: effectiveColor.withOpacity(0.12),
                  child: Icon(icon, color: effectiveColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: enabled ? Colors.black : Colors.black45,
                    ),
                  ),
                ),
                Text(
                  '$value',
                  style: TextStyle(
                    color: effectiveColor,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                subtitle,
                style: const TextStyle(color: Colors.black54),
              ),
            ),
            Slider(
              value: value.toDouble(),
              min: 0,
              max: max.toDouble(),
              divisions: max,
              label: '$value',
              onChanged: enabled ? (raw) => onChanged(raw.round()) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityGrid extends StatelessWidget {
  final CoachPlanningPreferences preferences;
  final ValueChanged<CoachPlanningPreferences> onChanged;

  const _PriorityGrid({required this.preferences, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.55,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _PriorityCard(
          icon: Icons.bolt,
          title: 'Velocidad',
          selected: preferences.prioritizeSpeed,
          onTap: () {
            onChanged(
              preferences.copyWith(
                prioritizeSpeed: !preferences.prioritizeSpeed,
              ),
            );
          },
        ),
        _PriorityCard(
          icon: Icons.route,
          title: 'Resistencia',
          selected: preferences.prioritizeEndurance,
          onTap: () {
            onChanged(
              preferences.copyWith(
                prioritizeEndurance: !preferences.prioritizeEndurance,
              ),
            );
          },
        ),
        _PriorityCard(
          icon: Icons.fitness_center,
          title: 'Fuerza',
          selected: preferences.prioritizeStrength,
          onTap: () {
            onChanged(
              preferences.copyWith(
                prioritizeStrength: !preferences.prioritizeStrength,
              ),
            );
          },
        ),
        _PriorityCard(
          icon: Icons.sports,
          title: 'Técnica',
          selected: preferences.prioritizeTechnique,
          onTap: () {
            onChanged(
              preferences.copyWith(
                prioritizeTechnique: !preferences.prioritizeTechnique,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PriorityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _PriorityCard({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.blue : Colors.grey;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(selected ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(selected ? 0.35 : 0.12)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.14),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.black : Colors.black54,
                ),
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

class _StyleSelector extends StatelessWidget {
  final CoachPlanningStyle value;
  final ValueChanged<CoachPlanningStyle> onChanged;

  const _StyleSelector({required this.value, required this.onChanged});

  String _label(CoachPlanningStyle style) {
    switch (style) {
      case CoachPlanningStyle.balanced:
        return 'Balanceado';
      case CoachPlanningStyle.speedFocused:
        return 'Prioridad velocidad';
      case CoachPlanningStyle.enduranceFocused:
        return 'Prioridad fondo';
      case CoachPlanningStyle.strengthFocused:
        return 'Prioridad fuerza';
      case CoachPlanningStyle.technicalFocused:
        return 'Prioridad técnica';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<CoachPlanningStyle>(
          value: value,
          decoration: const InputDecoration(
            labelText: 'Estilo de planificación',
            border: OutlineInputBorder(),
          ),
          items: CoachPlanningStyle.values.map((style) {
            return DropdownMenuItem(value: style, child: Text(_label(style)));
          }).toList(),
          onChanged: (style) {
            if (style == null) return;
            onChanged(style);
          },
        ),
      ),
    );
  }
}
