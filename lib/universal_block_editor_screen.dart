import 'package:flutter/material.dart';

import 'daily_training_block.dart';

class UniversalBlockEditorResult {
  final DailyTrainingBlock block;
  final String coachNote;

  const UniversalBlockEditorResult({
    required this.block,
    required this.coachNote,
  });
}

class UniversalBlockEditorScreen extends StatefulWidget {
  final DailyTrainingBlock? initialBlock;

  const UniversalBlockEditorScreen({super.key, this.initialBlock});

  @override
  State<UniversalBlockEditorScreen> createState() =>
      _UniversalBlockEditorScreenState();
}

class _UniversalBlockEditorScreenState
    extends State<UniversalBlockEditorScreen> {
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late final TextEditingController durationController;
  late final TextEditingController kmController;
  late final TextEditingController loadController;
  late final TextEditingController zoneController;
  late final TextEditingController aiReasonController;
  late final TextEditingController coachNoteController;

  late final TextEditingController warmupController;
  late final TextEditingController mainSetController;
  late final TextEditingController exercisesController;
  late final TextEditingController strengthExercisesController;
  late final TextEditingController plyometricExercisesController;
  late final TextEditingController technicalCuesController;
  late final TextEditingController tacticalCuesController;
  late final TextEditingController cooldownController;
  late final TextEditingController coachingNotesController;
  late final TextEditingController stopCriteriaController;

  late TrainingBlockType type;
  late TrainingBlockMoment moment;
  late TrainingStimulus stimulus;
  late TrainingEnergySystem energySystem;
  late NeuromuscularLoad neuromuscularLoad;
  late bool recoveryFocused;
  late bool taperFocused;

  bool get isCreating => widget.initialBlock == null;

  DailyTrainingBlock get initialBlock {
    return widget.initialBlock ??
        const DailyTrainingBlock(
          type: TrainingBlockType.skating,
          moment: TrainingBlockMoment.afternoon,
          title: 'Nuevo trabajo del entrenador',
          description: 'Trabajo añadido manualmente por el entrenador.',
          durationMinutes: 30,
          km: 0,
          targetLoad: 40,
          targetHeartRateZone: 2,
          recoveryFocused: false,
          taperFocused: false,
          aiReason: 'Añadido por decisión del entrenador.',
          stimulus: TrainingStimulus.technical,
          energySystem: TrainingEnergySystem.mixed,
          neuromuscularLoad: NeuromuscularLoad.low,
        );
  }

  @override
  void initState() {
    super.initState();

    final block = initialBlock;

    titleController = TextEditingController(text: block.title);
    descriptionController = TextEditingController(text: block.description);
    durationController = TextEditingController(
      text: block.durationMinutes.toString(),
    );
    kmController = TextEditingController(text: block.km.toStringAsFixed(1));
    loadController = TextEditingController(text: block.targetLoad.toString());
    zoneController = TextEditingController(
      text: block.targetHeartRateZone.toString(),
    );
    aiReasonController = TextEditingController(text: block.aiReason);
    coachNoteController = TextEditingController();

    warmupController = TextEditingController(text: _join(block.warmup));
    mainSetController = TextEditingController(text: _join(block.mainSet));
    exercisesController = TextEditingController(text: _join(block.exercises));
    strengthExercisesController = TextEditingController(
      text: _join(block.strengthExercises),
    );
    plyometricExercisesController = TextEditingController(
      text: _join(block.plyometricExercises),
    );
    technicalCuesController = TextEditingController(
      text: _join(block.technicalCues),
    );
    tacticalCuesController = TextEditingController(
      text: _join(block.tacticalCues),
    );
    cooldownController = TextEditingController(text: _join(block.cooldown));
    coachingNotesController = TextEditingController(
      text: _join(block.coachingNotes),
    );
    stopCriteriaController = TextEditingController(
      text: _join(block.stopCriteria),
    );

    type = block.type;
    moment = block.moment;
    stimulus = block.stimulus;
    energySystem = block.energySystem;
    neuromuscularLoad = block.neuromuscularLoad;
    recoveryFocused = block.recoveryFocused;
    taperFocused = block.taperFocused;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    durationController.dispose();
    kmController.dispose();
    loadController.dispose();
    zoneController.dispose();
    aiReasonController.dispose();
    coachNoteController.dispose();

    warmupController.dispose();
    mainSetController.dispose();
    exercisesController.dispose();
    strengthExercisesController.dispose();
    plyometricExercisesController.dispose();
    technicalCuesController.dispose();
    tacticalCuesController.dispose();
    cooldownController.dispose();
    coachingNotesController.dispose();
    stopCriteriaController.dispose();

    super.dispose();
  }

  String _join(List<String> items) => items.join('\n');

  List<String> _lines(String value) {
    return value
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  int _intFrom(TextEditingController controller, int fallback) {
    return int.tryParse(controller.text.trim()) ?? fallback;
  }

  double _doubleFrom(TextEditingController controller, double fallback) {
    return double.tryParse(controller.text.trim().replaceAll(',', '.')) ??
        fallback;
  }

  void _applyPreset(_TrainingPreset preset) {
    setState(() {
      type = preset.type;
      stimulus = preset.stimulus;
      energySystem = preset.energySystem;
      neuromuscularLoad = preset.neuromuscularLoad;
      recoveryFocused = preset.recoveryFocused;

      titleController.text = preset.title;
      descriptionController.text = preset.description;
      durationController.text = preset.durationMinutes.toString();
      kmController.text = preset.km.toStringAsFixed(1);
      loadController.text = preset.targetLoad.toString();
      zoneController.text = preset.zone.toString();
      mainSetController.text = preset.mainSet.join('\n');
      coachingNotesController.text = preset.coachingNotes.join('\n');
      stopCriteriaController.text = preset.stopCriteria.join('\n');

      if (aiReasonController.text.trim().isEmpty ||
          aiReasonController.text.contains('Añadido por decisión')) {
        aiReasonController.text = preset.reason;
      }
    });
  }

  void _save() {
    final block = initialBlock.copyWith(
      type: type,
      moment: moment,
      title: titleController.text.trim().isEmpty
          ? 'Bloque del entrenador'
          : titleController.text.trim(),
      description: descriptionController.text.trim(),
      durationMinutes: _intFrom(
        durationController,
        initialBlock.durationMinutes,
      ).clamp(1, 240),
      km: _doubleFrom(kmController, initialBlock.km).clamp(0, 80).toDouble(),
      targetLoad: _intFrom(
        loadController,
        initialBlock.targetLoad,
      ).clamp(1, 100),
      targetHeartRateZone: _intFrom(
        zoneController,
        initialBlock.targetHeartRateZone,
      ).clamp(1, 5),
      recoveryFocused: recoveryFocused,
      taperFocused: taperFocused,
      aiReason: aiReasonController.text.trim().isEmpty
          ? 'Editado por criterio del entrenador.'
          : aiReasonController.text.trim(),
      stimulus: stimulus,
      energySystem: energySystem,
      neuromuscularLoad: neuromuscularLoad,
      warmup: _lines(warmupController.text),
      mainSet: _lines(mainSetController.text),
      exercises: _lines(exercisesController.text),
      strengthExercises: _lines(strengthExercisesController.text),
      plyometricExercises: _lines(plyometricExercisesController.text),
      technicalCues: _lines(technicalCuesController.text),
      tacticalCues: _lines(tacticalCuesController.text),
      cooldown: _lines(cooldownController.text),
      coachingNotes: _lines(coachingNotesController.text),
      stopCriteria: _lines(stopCriteriaController.text),
    );

    Navigator.pop(
      context,
      UniversalBlockEditorResult(
        block: block,
        coachNote: coachNoteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isCreating ? 'Añadir trabajo' : 'Editar trabajo'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('Guardar'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeroCard(isCreating: isCreating),
          const SizedBox(height: 16),
          _PresetCard(onPreset: _applyPreset),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Información principal',
            children: [
              _TextField(
                controller: titleController,
                label: 'Nombre del trabajo',
              ),
              _TextField(
                controller: descriptionController,
                label: 'Descripción',
                maxLines: 3,
              ),
              Row(
                children: [
                  Expanded(
                    child: _TextField(
                      controller: durationController,
                      label: 'Minutos',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TextField(
                      controller: kmController,
                      label: 'Km',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _TextField(
                      controller: loadController,
                      label: 'Exigencia 1-100',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TextField(
                      controller: zoneController,
                      label: 'Zona 1-5',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Tipo de entrenamiento',
            children: [
              _Dropdown<TrainingBlockType>(
                label: 'Tipo',
                value: type,
                values: TrainingBlockType.values,
                text: _typeText,
                onChanged: (value) => setState(() => type = value),
              ),
              _Dropdown<TrainingBlockMoment>(
                label: 'Momento',
                value: moment,
                values: TrainingBlockMoment.values,
                text: _momentText,
                onChanged: (value) => setState(() => moment = value),
              ),
              _Dropdown<TrainingStimulus>(
                label: 'Estímulo',
                value: stimulus,
                values: TrainingStimulus.values,
                text: _stimulusText,
                onChanged: (value) => setState(() => stimulus = value),
              ),
              _Dropdown<TrainingEnergySystem>(
                label: 'Sistema energético',
                value: energySystem,
                values: TrainingEnergySystem.values,
                text: _energyText,
                onChanged: (value) => setState(() => energySystem = value),
              ),
              _Dropdown<NeuromuscularLoad>(
                label: 'Carga neuromuscular',
                value: neuromuscularLoad,
                values: NeuromuscularLoad.values,
                text: _neuralText,
                onChanged: (value) => setState(() => neuromuscularLoad = value),
              ),
              SwitchListTile(
                value: recoveryFocused,
                onChanged: (value) => setState(() => recoveryFocused = value),
                title: const Text('Enfocado en recuperación'),
              ),
              SwitchListTile(
                value: taperFocused,
                onChanged: (value) => setState(() => taperFocused = value),
                title: const Text('Compatible con taper/competencia'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Trabajo detallado',
            subtitle:
                'Escribe una línea por ejercicio, serie o indicación. Esto sirve para patines, bici, gimnasio o trabajo físico.',
            children: [
              _TextField(
                controller: warmupController,
                label: 'Calentamiento',
                maxLines: 4,
              ),
              _TextField(
                controller: mainSetController,
                label: 'Trabajo principal / series',
                maxLines: 6,
              ),
              _TextField(
                controller: exercisesController,
                label: 'Ejercicios generales',
                maxLines: 5,
              ),
              _TextField(
                controller: strengthExercisesController,
                label: 'Ejercicios de fuerza / gimnasio',
                maxLines: 5,
              ),
              _TextField(
                controller: plyometricExercisesController,
                label: 'Pliometría / transferencia',
                maxLines: 5,
              ),
              _TextField(
                controller: technicalCuesController,
                label: 'Indicaciones técnicas',
                maxLines: 5,
              ),
              _TextField(
                controller: tacticalCuesController,
                label: 'Indicaciones tácticas',
                maxLines: 5,
              ),
              _TextField(
                controller: cooldownController,
                label: 'Vuelta a la calma',
                maxLines: 4,
              ),
              _TextField(
                controller: coachingNotesController,
                label: 'Notas del entrenador',
                maxLines: 5,
              ),
              _TextField(
                controller: stopCriteriaController,
                label: 'Criterios para cortar',
                maxLines: 5,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Razón del cambio',
            children: [
              _TextField(
                controller: coachNoteController,
                label: 'Nota privada del entrenador',
                maxLines: 3,
              ),
              _TextField(
                controller: aiReasonController,
                label: 'Motivo visible del bloque',
                maxLines: 3,
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: Text(isCreating ? 'Añadir trabajo' : 'Guardar cambios'),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final bool isCreating;

  const _HeroCard({required this.isCreating});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF07111F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white12,
              child: Icon(Icons.tune, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isCreating
                    ? 'Crea cualquier trabajo: patines, bici, gimnasio, físico, técnica o recuperación.'
                    : 'Edita libremente el bloque. La app registrará el cambio para aprender.',
                style: const TextStyle(color: Colors.white70, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  final ValueChanged<_TrainingPreset> onPreset;

  const _PresetCard({required this.onPreset});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cambios rápidos inteligentes',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Convierte el bloque en otro tipo de trabajo sin empezar desde cero.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _TrainingPreset.defaults.map((preset) {
                return ActionChip(
                  avatar: Icon(preset.icon, size: 18),
                  label: Text(preset.label),
                  onPressed: () => onPreset(preset),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 5),
              Text(subtitle!, style: const TextStyle(color: Colors.white70)),
            ],
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;

  const _TextField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> values;
  final String Function(T) text;
  final ValueChanged<T> onChanged;

  const _Dropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.text,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: values
            .map(
              (item) =>
                  DropdownMenuItem<T>(value: item, child: Text(text(item))),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class _TrainingPreset {
  final String label;
  final IconData icon;
  final String title;
  final String description;
  final TrainingBlockType type;
  final TrainingStimulus stimulus;
  final TrainingEnergySystem energySystem;
  final NeuromuscularLoad neuromuscularLoad;
  final bool recoveryFocused;
  final int durationMinutes;
  final double km;
  final int targetLoad;
  final int zone;
  final List<String> mainSet;
  final List<String> coachingNotes;
  final List<String> stopCriteria;
  final String reason;

  const _TrainingPreset({
    required this.label,
    required this.icon,
    required this.title,
    required this.description,
    required this.type,
    required this.stimulus,
    required this.energySystem,
    required this.neuromuscularLoad,
    required this.recoveryFocused,
    required this.durationMinutes,
    required this.km,
    required this.targetLoad,
    required this.zone,
    required this.mainSet,
    required this.coachingNotes,
    required this.stopCriteria,
    required this.reason,
  });

  static const defaults = [
    _TrainingPreset(
      label: 'Bici +10 min',
      icon: Icons.directions_bike,
      title: 'Bicicleta complementaria',
      description: 'Bicicleta añadida o extendida por criterio del entrenador.',
      type: TrainingBlockType.cycling,
      stimulus: TrainingStimulus.aerobic,
      energySystem: TrainingEnergySystem.aerobic,
      neuromuscularLoad: NeuromuscularLoad.low,
      recoveryFocused: false,
      durationMinutes: 40,
      km: 0,
      targetLoad: 35,
      zone: 2,
      mainSet: [
        'Rodaje Z2 controlado.',
        'Mantener cadencia cómoda y técnica limpia.',
        'Últimos 5-10 min suaves.',
      ],
      coachingNotes: [
        'No convertir en fatiga extra.',
        'Usar como complemento al trabajo principal.',
      ],
      stopCriteria: ['Piernas pesadas.', 'Fatiga creciente.'],
      reason: 'El entrenador añadió bicicleta complementaria.',
    ),
    _TrainingPreset(
      label: 'Bici intervalos',
      icon: Icons.bolt,
      title: 'Bicicleta: intervalos de potencia',
      description:
          'Trabajo de cadencia, potencia y cambios de ritmo en bicicleta.',
      type: TrainingBlockType.cycling,
      stimulus: TrainingStimulus.speed,
      energySystem: TrainingEnergySystem.mixed,
      neuromuscularLoad: NeuromuscularLoad.moderate,
      recoveryFocused: false,
      durationMinutes: 45,
      km: 0,
      targetLoad: 58,
      zone: 3,
      mainSet: [
        '10 min progresivos.',
        '6x30s alta cadencia / 2 min suave.',
        '4x15s potencia controlada / 2-3 min suave.',
        '8 min soltando piernas.',
      ],
      coachingNotes: [
        'Buscar chispa, no agotamiento.',
        'Buena opción para transferir fuerza sin impacto.',
      ],
      stopCriteria: [
        'Pulso descontrolado.',
        'Piernas bloqueadas.',
        'Pérdida de coordinación.',
      ],
      reason: 'El entrenador convirtió la bicicleta en trabajo de intervalos.',
    ),
    _TrainingPreset(
      label: 'Velocidad patines',
      icon: Icons.speed,
      title: 'Patines: velocidad específica',
      description:
          'Aceleraciones y velocidad con recuperación completa, priorizando técnica.',
      type: TrainingBlockType.skating,
      stimulus: TrainingStimulus.speed,
      energySystem: TrainingEnergySystem.anaerobicAlactic,
      neuromuscularLoad: NeuromuscularLoad.high,
      recoveryFocused: false,
      durationMinutes: 45,
      km: 6,
      targetLoad: 68,
      zone: 4,
      mainSet: [
        '12 min entrada progresiva.',
        '6x30m salidas controladas.',
        '4x80m lanzados al 90-95%.',
        'Recuperación completa entre repeticiones.',
      ],
      coachingNotes: [
        'Debe sentirse rápido, no agotador.',
        'Cortar si cae la técnica.',
      ],
      stopCriteria: [
        'Pérdida de técnica.',
        'Dolor de aductor, rodilla o tobillo.',
        'Fatiga neural evidente.',
      ],
      reason: 'El entrenador cambió el bloque hacia velocidad específica.',
    ),
    _TrainingPreset(
      label: 'Intervalos patines',
      icon: Icons.timer,
      title: 'Patines: intervalos controlados',
      description:
          'Trabajo de intervalos para cambios de ritmo y tolerancia específica.',
      type: TrainingBlockType.skating,
      stimulus: TrainingStimulus.lactateTolerance,
      energySystem: TrainingEnergySystem.anaerobicLactic,
      neuromuscularLoad: NeuromuscularLoad.moderate,
      recoveryFocused: false,
      durationMinutes: 60,
      km: 12,
      targetLoad: 72,
      zone: 4,
      mainSet: [
        '15 min calentamiento técnico.',
        '5x3 min ritmo fuerte controlado / 3 min suave.',
        '4 aceleraciones finales de 12s si la técnica sigue limpia.',
        '10 min vuelta a la calma.',
      ],
      coachingNotes: [
        'Controlar técnica bajo fatiga.',
        'No convertir en máximo si el día no lo permite.',
      ],
      stopCriteria: [
        'Técnica rota.',
        'RPE demasiado alto antes de terminar.',
        'Dolor o rigidez anormal.',
      ],
      reason: 'El entrenador convirtió el bloque en intervalos específicos.',
    ),
    _TrainingPreset(
      label: 'Gimnasio fuerza',
      icon: Icons.fitness_center,
      title: 'Gimnasio: fuerza útil para patinaje',
      description:
          'Fuerza estructural con transferencia hacia empuje y velocidad.',
      type: TrainingBlockType.strength,
      stimulus: TrainingStimulus.maxStrength,
      energySystem: TrainingEnergySystem.none,
      neuromuscularLoad: NeuromuscularLoad.high,
      recoveryFocused: false,
      durationMinutes: 60,
      km: 0,
      targetLoad: 70,
      zone: 2,
      mainSet: [
        'Sentadilla o prensa 4x5-6.',
        'Peso muerto rumano 3x6-8.',
        'Zancada o split squat 3x6 por pierna.',
        'Core antirotación 3x10 por lado.',
        'Transferencia: 3x5 saltos laterales controlados.',
      ],
      coachingNotes: [
        'No buscar fallo muscular.',
        'La prioridad es fuerza útil y transferencia.',
      ],
      stopCriteria: [
        'Dolor lumbar, rodilla o Aquiles.',
        'Pérdida de velocidad de ejecución.',
        'Técnica inestable.',
      ],
      reason: 'El entrenador ajustó el trabajo hacia fuerza específica.',
    ),
    _TrainingPreset(
      label: 'Recuperación',
      icon: Icons.spa,
      title: 'Recuperación activa',
      description:
          'Movilidad, respiración y descarga para facilitar adaptación.',
      type: TrainingBlockType.recovery,
      stimulus: TrainingStimulus.recovery,
      energySystem: TrainingEnergySystem.none,
      neuromuscularLoad: NeuromuscularLoad.low,
      recoveryFocused: true,
      durationMinutes: 25,
      km: 0,
      targetLoad: 12,
      zone: 1,
      mainSet: [
        'Movilidad suave de cadera, tobillo y espalda.',
        'Respiración diafragmática 5 min.',
        'Liberación suave de piernas.',
      ],
      coachingNotes: [
        'Debe sentirse regenerativo.',
        'No convertir en entrenamiento extra.',
      ],
      stopCriteria: ['Dolor.', 'Fatiga creciente.'],
      reason: 'El entrenador priorizó recuperación.',
    ),
  ];
}

String _typeText(TrainingBlockType value) {
  switch (value) {
    case TrainingBlockType.skating:
      return 'Patines';
    case TrainingBlockType.strength:
      return 'Gimnasio / fuerza';
    case TrainingBlockType.cycling:
      return 'Bicicleta';
    case TrainingBlockType.recovery:
      return 'Recuperación';
    case TrainingBlockType.mobility:
      return 'Movilidad / físico suave';
    case TrainingBlockType.activation:
      return 'Activación / potencia';
    case TrainingBlockType.technical:
      return 'Técnica';
    case TrainingBlockType.aerobic:
      return 'Aeróbico';
  }
}

String _momentText(TrainingBlockMoment value) {
  switch (value) {
    case TrainingBlockMoment.morning:
      return 'Mañana';
    case TrainingBlockMoment.afternoon:
      return 'Tarde';
    case TrainingBlockMoment.evening:
      return 'Noche';
  }
}

String _stimulusText(TrainingStimulus value) {
  switch (value) {
    case TrainingStimulus.recovery:
      return 'Recuperación';
    case TrainingStimulus.mobility:
      return 'Movilidad';
    case TrainingStimulus.technical:
      return 'Técnica';
    case TrainingStimulus.aerobic:
      return 'Aeróbico';
    case TrainingStimulus.anaerobic:
      return 'Anaeróbico';
    case TrainingStimulus.lactateTolerance:
      return 'Lactato / tolerancia';
    case TrainingStimulus.neuromuscular:
      return 'Neuromuscular';
    case TrainingStimulus.maxStrength:
      return 'Fuerza máxima';
    case TrainingStimulus.power:
      return 'Potencia';
    case TrainingStimulus.strengthEndurance:
      return 'Fuerza resistencia';
    case TrainingStimulus.plyometric:
      return 'Pliometría';
    case TrainingStimulus.speed:
      return 'Velocidad';
    case TrainingStimulus.tactical:
      return 'Táctico';
  }
}

String _energyText(TrainingEnergySystem value) {
  switch (value) {
    case TrainingEnergySystem.none:
      return 'No aplica';
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

String _neuralText(NeuromuscularLoad value) {
  switch (value) {
    case NeuromuscularLoad.none:
      return 'Ninguna';
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
