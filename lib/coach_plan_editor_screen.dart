import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'coach_plan_modification.dart';
import 'daily_training_assignment_service.dart';
import 'daily_training_block.dart';
import 'integrated_training_day.dart';
import 'training_library/day_detail/training_block_detail_screen.dart';
import 'universal_block_editor_screen.dart';

class CoachPlanEditorScreen extends StatefulWidget {
  final String athleteId;
  final IntegratedTrainingDay initialDay;

  const CoachPlanEditorScreen({
    super.key,
    required this.athleteId,
    required this.initialDay,
  });

  @override
  State<CoachPlanEditorScreen> createState() => _CoachPlanEditorScreenState();
}

class _CoachPlanEditorScreenState extends State<CoachPlanEditorScreen> {
  late IntegratedTrainingDay editedDay;
  late List<CoachPlanModification> modifications;

  @override
  void initState() {
    super.initState();
    editedDay = widget.initialDay;
    modifications = [...widget.initialDay.coachModifications];
  }

  void _addModification(CoachPlanModification modification) {
    modifications = [...modifications, modification];
  }

  void _replaceBlocks(List<DailyTrainingBlock> blocks) {
    editedDay = editedDay.copyWith(
      blocks: blocks,
      coachModifications: modifications,
      aiRecommendation: _buildCoachRecommendationText(
        base: widget.initialDay.aiRecommendation,
      ),
      aiSummary: _buildCoachSummaryText(base: widget.initialDay.aiSummary),
    );
  }

  String _buildCoachSummaryText({required String base}) {
    if (modifications.isEmpty) return base;
    return '$base\n\nEl entrenador modificó el plan antes de enviarlo.';
  }

  String _buildCoachRecommendationText({required String base}) {
    if (modifications.isEmpty) return base;

    final notes = modifications
        .map((item) {
          if (item.coachNote.trim().isEmpty) {
            return '• ${item.description}';
          }

          return '• ${item.description} Nota: ${item.coachNote}';
        })
        .join('\n');

    return '$base\n\nCambios estructurados del entrenador:\n$notes';
  }

  CoachPlanModification _modificationFromBlock({
    required CoachPlanEditType type,
    required DailyTrainingBlock block,
    required String description,
    DailyTrainingBlock? updatedBlock,
    bool addedBlock = false,
    bool removedBlock = false,
  }) {
    return CoachPlanModification(
      id: CoachPlanModification.newId(),
      type: type,
      description: description,
      createdAt: DateTime.now(),
      targetBlockTitle: block.title,
      blockType: block.type,
      stimulus: block.stimulus,
      energySystem: block.energySystem,
      neuromuscularLoad: block.neuromuscularLoad,
      previousLoad: addedBlock ? null : block.targetLoad,
      newLoad: removedBlock
          ? null
          : updatedBlock?.targetLoad ?? block.targetLoad,
      previousDurationMinutes: addedBlock ? null : block.durationMinutes,
      newDurationMinutes: removedBlock
          ? null
          : updatedBlock?.durationMinutes ?? block.durationMinutes,
      previousKm: addedBlock ? null : block.km,
      newKm: removedBlock ? null : updatedBlock?.km ?? block.km,
      previousBlockType: addedBlock ? null : block.type,
      newBlockType: removedBlock ? null : updatedBlock?.type ?? block.type,
      previousMoment: addedBlock ? null : block.moment,
      newMoment: removedBlock ? null : updatedBlock?.moment ?? block.moment,
      previousStimulus: addedBlock ? null : block.stimulus,
      newStimulus: removedBlock
          ? null
          : updatedBlock?.stimulus ?? block.stimulus,
      previousEnergySystem: addedBlock ? null : block.energySystem,
      newEnergySystem: removedBlock
          ? null
          : updatedBlock?.energySystem ?? block.energySystem,
      previousNeuromuscularLoad: addedBlock ? null : block.neuromuscularLoad,
      newNeuromuscularLoad: removedBlock
          ? null
          : updatedBlock?.neuromuscularLoad ?? block.neuromuscularLoad,
      previousHeartRateZone: addedBlock ? null : block.targetHeartRateZone,
      newHeartRateZone: removedBlock
          ? null
          : updatedBlock?.targetHeartRateZone ?? block.targetHeartRateZone,
      previousTitle: addedBlock ? null : block.title,
      newTitle: removedBlock ? null : updatedBlock?.title ?? block.title,
      previousDescription: addedBlock ? null : block.description,
      newDescription: removedBlock
          ? null
          : updatedBlock?.description ?? block.description,
      addedBlock: addedBlock,
      removedBlock: removedBlock,
    );
  }

  int _indexOfBlock(DailyTrainingBlock block) {
    return editedDay.blocks.indexWhere((item) => identical(item, block));
  }

  void _replaceBlockAt({
    required int index,
    required DailyTrainingBlock newBlock,
  }) {
    if (index < 0 || index >= editedDay.blocks.length) return;

    final blocks = [...editedDay.blocks];
    blocks[index] = newBlock;

    setState(() => _replaceBlocks(blocks));
  }

  void _increaseLoad(DailyTrainingBlock block) {
    final updated = block.copyWith(
      title: '${block.title} + carga entrenador',
      durationMinutes: (block.durationMinutes * 1.12).round().clamp(10, 180),
      km: block.km * 1.10,
      targetLoad: (block.targetLoad * 1.12).round().clamp(5, 100),
      aiReason:
          '${block.aiReason}\n\nDecisión del entrenador: aumentó carga para probar tolerancia adaptativa.',
    );

    final index = _indexOfBlock(block);
    if (index == -1) return;

    _addModification(
      _modificationFromBlock(
        type: CoachPlanEditType.increaseLoad,
        block: block,
        updatedBlock: updated,
        description: 'Aumentó carga en "${block.title}".',
      ),
    );

    _replaceBlockAt(index: index, newBlock: updated);
  }

  void _reduceLoad(DailyTrainingBlock block) {
    final updated = block.copyWith(
      title: '${block.title} - carga entrenador',
      durationMinutes: (block.durationMinutes * 0.82).round().clamp(8, 180),
      km: block.km * 0.82,
      targetLoad: (block.targetLoad * 0.82).round().clamp(5, 100),
      aiReason:
          '${block.aiReason}\n\nDecisión del entrenador: redujo carga por criterio técnico/fisiológico.',
    );

    final index = _indexOfBlock(block);
    if (index == -1) return;

    _addModification(
      _modificationFromBlock(
        type: CoachPlanEditType.reduceLoad,
        block: block,
        updatedBlock: updated,
        description: 'Redujo carga en "${block.title}".',
      ),
    );

    _replaceBlockAt(index: index, newBlock: updated);
  }

  void _addTenMinutes(DailyTrainingBlock block) {
    final updated = block.copyWith(
      durationMinutes: (block.durationMinutes + 10).clamp(1, 240),
      targetLoad: (block.targetLoad + 5).clamp(1, 100),
      aiReason:
          '${block.aiReason}\n\nDecisión del entrenador: añadió 10 minutos al bloque.',
    );

    final index = _indexOfBlock(block);
    if (index == -1) return;

    _addModification(
      CoachPlanModification.fromBlockEdit(
        previousBlock: block,
        newBlock: updated,
        coachNote: 'Añadió 10 minutos.',
      ),
    );

    _replaceBlockAt(index: index, newBlock: updated);
  }

  void _removeTenMinutes(DailyTrainingBlock block) {
    final updated = block.copyWith(
      durationMinutes: (block.durationMinutes - 10).clamp(1, 240),
      targetLoad: (block.targetLoad - 5).clamp(1, 100),
      aiReason:
          '${block.aiReason}\n\nDecisión del entrenador: redujo 10 minutos del bloque.',
    );

    final index = _indexOfBlock(block);
    if (index == -1) return;

    _addModification(
      CoachPlanModification.fromBlockEdit(
        previousBlock: block,
        newBlock: updated,
        coachNote: 'Redujo 10 minutos.',
      ),
    );

    _replaceBlockAt(index: index, newBlock: updated);
  }

  void _convertToRecovery(DailyTrainingBlock block) {
    final updated = block.copyWith(
      type: TrainingBlockType.recovery,
      title: 'Recuperación activa',
      description:
          'Trabajo regenerativo ajustado por el entrenador para controlar fatiga y favorecer adaptación.',
      durationMinutes: block.durationMinutes.clamp(15, 45),
      km: 0,
      targetLoad: 12,
      targetHeartRateZone: 1,
      recoveryFocused: true,
      stimulus: TrainingStimulus.recovery,
      energySystem: TrainingEnergySystem.none,
      neuromuscularLoad: NeuromuscularLoad.low,
      mainSet: const [
        'Movilidad suave de cadera, tobillo y espalda.',
        'Respiración diafragmática 5 min.',
        'Liberación suave de piernas.',
      ],
      coachingNotes: const [
        'Debe sentirse regenerativo.',
        'No convertir en entrenamiento extra.',
      ],
      stopCriteria: const ['Dolor.', 'Fatiga creciente.'],
      aiReason:
          '${block.aiReason}\n\nDecisión del entrenador: convirtió el bloque en recuperación.',
    );

    final index = _indexOfBlock(block);
    if (index == -1) return;

    _addModification(
      CoachPlanModification.fromBlockEdit(
        previousBlock: block,
        newBlock: updated,
        coachNote: 'Convirtió el bloque en recuperación.',
      ),
    );

    _replaceBlockAt(index: index, newBlock: updated);
  }

  void _convertToSpeed(DailyTrainingBlock block) {
    final updated = block.copyWith(
      type: TrainingBlockType.skating,
      title: 'Patines: velocidad específica',
      description:
          'Aceleraciones y velocidad con recuperación completa, priorizando técnica y frescura.',
      durationMinutes: block.durationMinutes.clamp(30, 70),
      km: block.km > 0 ? block.km.clamp(3, 10).toDouble() : 5,
      targetLoad: 68,
      targetHeartRateZone: 4,
      recoveryFocused: false,
      stimulus: TrainingStimulus.speed,
      energySystem: TrainingEnergySystem.anaerobicAlactic,
      neuromuscularLoad: NeuromuscularLoad.high,
      warmup: const [
        '12 min entrada progresiva.',
        'Movilidad dinámica y activación de tobillo/cadera.',
      ],
      mainSet: const [
        '6x30m salidas controladas.',
        '4x80m lanzados al 90-95%.',
        'Recuperación completa entre repeticiones.',
      ],
      technicalCues: const [
        'Empuje largo y limpio.',
        'Cadera estable.',
        'Cortar si cae la técnica.',
      ],
      stopCriteria: const [
        'Pérdida de técnica.',
        'Dolor de aductor, rodilla o tobillo.',
        'Fatiga neural evidente.',
      ],
      aiReason:
          '${block.aiReason}\n\nDecisión del entrenador: cambió el bloque hacia velocidad específica.',
    );

    final index = _indexOfBlock(block);
    if (index == -1) return;

    _addModification(
      CoachPlanModification.fromBlockEdit(
        previousBlock: block,
        newBlock: updated,
        coachNote: 'Convirtió el bloque en velocidad específica.',
      ),
    );

    _replaceBlockAt(index: index, newBlock: updated);
  }

  void _convertToIntervals(DailyTrainingBlock block) {
    final updated = block.copyWith(
      type: block.type == TrainingBlockType.cycling
          ? TrainingBlockType.cycling
          : TrainingBlockType.skating,
      title: block.type == TrainingBlockType.cycling
          ? 'Bicicleta: intervalos de potencia'
          : 'Patines: intervalos controlados',
      description:
          'Trabajo de intervalos ajustado por el entrenador para cambios de ritmo, tolerancia y control técnico.',
      durationMinutes: block.durationMinutes.clamp(40, 75),
      km: block.type == TrainingBlockType.cycling
          ? 0
          : (block.km > 0 ? block.km.clamp(6, 16).toDouble() : 10),
      targetLoad: 72,
      targetHeartRateZone: 4,
      recoveryFocused: false,
      stimulus: TrainingStimulus.lactateTolerance,
      energySystem: TrainingEnergySystem.anaerobicLactic,
      neuromuscularLoad: NeuromuscularLoad.moderate,
      warmup: const ['15 min calentamiento progresivo y técnico.'],
      mainSet: block.type == TrainingBlockType.cycling
          ? const [
              '10 min progresivos.',
              '6x30s alta cadencia / 2 min suave.',
              '4x15s potencia controlada / 2-3 min suave.',
              '8 min soltando piernas.',
            ]
          : const [
              '5x3 min ritmo fuerte controlado / 3 min suave.',
              '4 aceleraciones finales de 12s si la técnica sigue limpia.',
              '10 min vuelta a la calma.',
            ],
      coachingNotes: const [
        'Controlar técnica bajo fatiga.',
        'No convertir en máximo si el día no lo permite.',
      ],
      stopCriteria: const [
        'Técnica rota.',
        'RPE demasiado alto antes de terminar.',
        'Dolor o rigidez anormal.',
      ],
      aiReason:
          '${block.aiReason}\n\nDecisión del entrenador: convirtió el bloque en intervalos.',
    );

    final index = _indexOfBlock(block);
    if (index == -1) return;

    _addModification(
      CoachPlanModification.fromBlockEdit(
        previousBlock: block,
        newBlock: updated,
        coachNote: 'Convirtió el bloque en intervalos.',
      ),
    );

    _replaceBlockAt(index: index, newBlock: updated);
  }

  void _removeBlock(DailyTrainingBlock block) {
    final blocks = editedDay.blocks
        .where((item) => !identical(item, block))
        .toList();

    _addModification(CoachPlanModification.fromRemovedBlock(block: block));

    setState(() => _replaceBlocks(blocks));
  }

  void _addBlock(
    DailyTrainingBlock block,
    CoachPlanEditType type,
    String label,
  ) {
    final blocks = [...editedDay.blocks, block];

    _addModification(
      _modificationFromBlock(
        type: type,
        block: block,
        addedBlock: true,
        description: label,
      ),
    );

    setState(() => _replaceBlocks(blocks));
  }

  Future<void> _addCustomBlock() async {
    final result = await Navigator.push<UniversalBlockEditorResult>(
      context,
      MaterialPageRoute(builder: (_) => const UniversalBlockEditorScreen()),
    );

    if (result == null) return;

    final blocks = [...editedDay.blocks, result.block];

    _addModification(
      CoachPlanModification.fromAddedBlock(
        block: result.block,
        coachNote: result.coachNote,
      ),
    );

    setState(() => _replaceBlocks(blocks));
  }

  Future<void> _editBlockFreely(DailyTrainingBlock block) async {
    final index = _indexOfBlock(block);
    if (index == -1) return;

    final result = await Navigator.push<UniversalBlockEditorResult>(
      context,
      MaterialPageRoute(
        builder: (_) => UniversalBlockEditorScreen(initialBlock: block),
      ),
    );

    if (result == null) return;

    _addModification(
      CoachPlanModification.fromBlockEdit(
        previousBlock: block,
        newBlock: result.block,
        coachNote: result.coachNote,
      ),
    );

    _replaceBlockAt(index: index, newBlock: result.block);
  }

  void _addCoreBlock() {
    _addBlock(
      const DailyTrainingBlock(
        type: TrainingBlockType.mobility,
        moment: TrainingBlockMoment.evening,
        title: 'Core complementario del entrenador',
        description:
            'Core anti-rotación, estabilidad lumbo-pélvica y control postural para transferir mejor al patinaje.',
        durationMinutes: 25,
        km: 0,
        targetLoad: 28,
        targetHeartRateZone: 1,
        recoveryFocused: false,
        taperFocused: false,
        aiReason:
            'Añadido por el entrenador para reforzar estabilidad y transferencia técnica.',
        stimulus: TrainingStimulus.mobility,
        energySystem: TrainingEnergySystem.none,
        neuromuscularLoad: NeuromuscularLoad.low,
        mainSet: [
          'Plancha frontal 3x35-45s.',
          'Pallof press 3x10 por lado.',
          'Dead bug 3x10 por lado.',
          'Side plank 3x30s por lado.',
        ],
        coachingNotes: [
          'Calidad antes que fatiga.',
          'Mantener pelvis estable y respiración controlada.',
        ],
        stopCriteria: ['Dolor lumbar.', 'Pérdida de control postural.'],
      ),
      CoachPlanEditType.addCore,
      'Añadió bloque de core complementario.',
    );
  }

  void _addRecoveryBlock() {
    _addBlock(
      const DailyTrainingBlock(
        type: TrainingBlockType.recovery,
        moment: TrainingBlockMoment.evening,
        title: 'Recuperación añadida por el entrenador',
        description:
            'Movilidad suave, respiración y descarga para favorecer adaptación después de la carga principal.',
        durationMinutes: 25,
        km: 0,
        targetLoad: 12,
        targetHeartRateZone: 1,
        recoveryFocused: true,
        taperFocused: false,
        aiReason:
            'Añadido por el entrenador para mejorar recuperación y controlar fatiga residual.',
        stimulus: TrainingStimulus.recovery,
        energySystem: TrainingEnergySystem.none,
        neuromuscularLoad: NeuromuscularLoad.low,
        mainSet: [
          'Movilidad de cadera y tobillo 8-10 min.',
          'Respiración diafragmática 5 min.',
          'Liberación suave de glúteos, cuádriceps y gemelos.',
        ],
        coachingNotes: [
          'Debe sentirse regenerativo.',
          'No convertir en entrenamiento extra.',
        ],
        stopCriteria: ['Dolor.', 'Fatiga creciente.'],
      ),
      CoachPlanEditType.addRecovery,
      'Añadió recuperación complementaria.',
    );
  }

  void _addCyclingSpeedTransfer() {
    _addBlock(
      const DailyTrainingBlock(
        type: TrainingBlockType.cycling,
        moment: TrainingBlockMoment.afternoon,
        title: 'Bicicleta transferencia velocidad',
        description:
            'Trabajo corto de cadencia y potencia controlada para transferir fuerza a velocidad sin impacto.',
        durationMinutes: 35,
        km: 12,
        targetLoad: 48,
        targetHeartRateZone: 3,
        recoveryFocused: false,
        taperFocused: false,
        aiReason:
            'Añadido por el entrenador como transferencia fuerza → velocidad con bajo impacto articular.',
        stimulus: TrainingStimulus.speed,
        energySystem: TrainingEnergySystem.anaerobicAlactic,
        neuromuscularLoad: NeuromuscularLoad.moderate,
        warmup: ['10 min Z1-Z2 con cadencia progresiva.'],
        mainSet: [
          '6x12s alta cadencia / potencia controlada.',
          'Recuperar 2 min muy suave entre repeticiones.',
          'Terminar con 8-10 min fácil.',
        ],
        coachingNotes: [
          'Buscar chispa, no fatiga.',
          'No convertir en lactato.',
        ],
        stopCriteria: [
          'Piernas pesadas.',
          'Pulso sube demasiado.',
          'Pérdida de coordinación.',
        ],
      ),
      CoachPlanEditType.addCyclingSpeedTransfer,
      'Añadió transferencia de velocidad en bicicleta.',
    );
  }

  void _addSkatingSpeedBlock() {
    _addBlock(
      const DailyTrainingBlock(
        type: TrainingBlockType.skating,
        moment: TrainingBlockMoment.afternoon,
        title: 'Velocidad añadida por el entrenador',
        description:
            'Bloque corto de aceleraciones y velocidad neural, priorizando frescura, técnica y recuperación completa.',
        durationMinutes: 35,
        km: 4,
        targetLoad: 55,
        targetHeartRateZone: 3,
        recoveryFocused: false,
        taperFocused: false,
        aiReason:
            'Añadido por el entrenador para probar respuesta a estímulo neural adicional.',
        stimulus: TrainingStimulus.speed,
        energySystem: TrainingEnergySystem.anaerobicAlactic,
        neuromuscularLoad: NeuromuscularLoad.moderate,
        warmup: [
          '12 min progresivos.',
          'Movilidad dinámica y activación de tobillo/cadera.',
        ],
        mainSet: [
          '6x30m salidas controladas.',
          '4x80m lanzados al 90-95%.',
          'Recuperación completa entre repeticiones.',
        ],
        technicalCues: [
          'Empuje largo y limpio.',
          'Cadera estable.',
          'No forzar si cae la técnica.',
        ],
        coachingNotes: ['Debe sentirse rápido, no agotador.'],
        stopCriteria: [
          'Pérdida de técnica.',
          'Dolor de aductor, rodilla o tobillo.',
          'Fatiga neural evidente.',
        ],
      ),
      CoachPlanEditType.addSkatingSpeed,
      'Añadió trabajo de velocidad en patines.',
    );
  }

  void _addPlyometricTransfer() {
    _addBlock(
      const DailyTrainingBlock(
        type: TrainingBlockType.activation,
        moment: TrainingBlockMoment.morning,
        title: 'Pliometría transferencia fuerza → velocidad',
        description:
            'Saltos controlados de baja a media dosis para convertir fuerza en velocidad específica.',
        durationMinutes: 22,
        km: 0,
        targetLoad: 42,
        targetHeartRateZone: 2,
        recoveryFocused: false,
        taperFocused: false,
        aiReason:
            'Añadido por el entrenador como transferencia fuerza → velocidad.',
        stimulus: TrainingStimulus.plyometric,
        energySystem: TrainingEnergySystem.anaerobicAlactic,
        neuromuscularLoad: NeuromuscularLoad.moderate,
        mainSet: [
          'Pogos suaves 3x20 contactos.',
          'Saltos laterales controlados 3x8 por lado.',
          'Skater bounds 3x6 por lado.',
        ],
        coachingNotes: [
          'Pocos contactos y mucha calidad.',
          'Evitar fatiga tendinosa.',
        ],
        stopCriteria: [
          'Dolor de rodilla, tobillo o Aquiles.',
          'Aterrizajes pesados.',
          'Pérdida de coordinación.',
        ],
      ),
      CoachPlanEditType.addPlyometricTransfer,
      'Añadió pliometría de transferencia.',
    );
  }

  Future<void> _saveDraft() async {
    final finalDay = editedDay.copyWith(coachModifications: modifications);

    context.read<DailyTrainingAssignmentService>().saveDraft(
      athleteId: widget.athleteId,
      day: finalDay,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Plan editado guardado como borrador del entrenador.'),
      ),
    );

    Navigator.pop(context, finalDay);
  }

  Future<void> _saveAndSend() async {
    final service = context.read<DailyTrainingAssignmentService>();
    final finalDay = editedDay.copyWith(coachModifications: modifications);

    service.saveDraft(athleteId: widget.athleteId, day: finalDay);
    service.sendToday(widget.athleteId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plan editado enviado al atleta.')),
    );

    Navigator.pop(context, finalDay);
  }

  @override
  Widget build(BuildContext context) {
    final totalLoad = editedDay.totalLoad;
    final totalMinutes = editedDay.totalMinutes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar plan del entrenador'),
        actions: [
          TextButton.icon(
            onPressed: _saveDraft,
            icon: const Icon(Icons.save),
            label: const Text('Guardar'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _EditorHeroCard(
            totalLoad: totalLoad,
            totalMinutes: totalMinutes,
            totalBlocks: editedDay.blocks.length,
            modifications: modifications.length,
          ),
          const SizedBox(height: 16),
          _QuickAddCard(
            onAddCustom: _addCustomBlock,
            onAddCore: _addCoreBlock,
            onAddRecovery: _addRecoveryBlock,
            onAddCyclingTransfer: _addCyclingSpeedTransfer,
            onAddSkatingSpeed: _addSkatingSpeedBlock,
            onAddPlyometricTransfer: _addPlyometricTransfer,
          ),
          const SizedBox(height: 16),
          if (modifications.isNotEmpty)
            _ModificationHistoryCard(modifications: modifications),
          const SizedBox(height: 16),
          const Text(
            'Bloques del plan',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...editedDay.blocks.map(
            (block) => _EditableBlockCard(
              block: block,
              onOpen: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TrainingBlockDetailScreen(block: block),
                  ),
                );
              },
              onEditFreely: () => _editBlockFreely(block),
              onIncrease: () => _increaseLoad(block),
              onReduce: () => _reduceLoad(block),
              onAddTenMinutes: () => _addTenMinutes(block),
              onRemoveTenMinutes: () => _removeTenMinutes(block),
              onConvertToRecovery: () => _convertToRecovery(block),
              onConvertToSpeed: () => _convertToSpeed(block),
              onConvertToIntervals: () => _convertToIntervals(block),
              onRemove: () => _removeBlock(block),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saveDraft,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar borrador'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saveAndSend,
                  icon: const Icon(Icons.send),
                  label: const Text('Enviar editado'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditorHeroCard extends StatelessWidget {
  final int totalLoad;
  final int totalMinutes;
  final int totalBlocks;
  final int modifications;

  const _EditorHeroCard({
    required this.totalLoad,
    required this.totalMinutes,
    required this.totalBlocks,
    required this.modifications,
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
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white12,
              child: Icon(Icons.edit_calendar, color: Colors.white),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Editor universal del entrenador',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Edita patines, bici, gimnasio, físico o recuperación. Cada cambio queda registrado para aprendizaje.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  '$modifications',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
                const Text(
                  'cambios',
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

class _QuickAddCard extends StatelessWidget {
  final VoidCallback onAddCustom;
  final VoidCallback onAddCore;
  final VoidCallback onAddRecovery;
  final VoidCallback onAddCyclingTransfer;
  final VoidCallback onAddSkatingSpeed;
  final VoidCallback onAddPlyometricTransfer;

  const _QuickAddCard({
    required this.onAddCustom,
    required this.onAddCore,
    required this.onAddRecovery,
    required this.onAddCyclingTransfer,
    required this.onAddSkatingSpeed,
    required this.onAddPlyometricTransfer,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Añadir al plan',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'El entrenador puede añadir trabajo libre o usar accesos rápidos. Todo queda registrado para que la app aprenda.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ActionChipButton(
                  icon: Icons.add_circle,
                  label: 'Trabajo libre',
                  onTap: onAddCustom,
                ),
                _ActionChipButton(
                  icon: Icons.accessibility_new,
                  label: 'Estabilidad',
                  onTap: onAddCore,
                ),
                _ActionChipButton(
                  icon: Icons.spa,
                  label: 'Recuperación',
                  onTap: onAddRecovery,
                ),
                _ActionChipButton(
                  icon: Icons.directions_bike,
                  label: 'Transferencia velocidad',
                  onTap: onAddCyclingTransfer,
                ),
                _ActionChipButton(
                  icon: Icons.speed,
                  label: 'Velocidad patines',
                  onTap: onAddSkatingSpeed,
                ),
                _ActionChipButton(
                  icon: Icons.bolt,
                  label: 'Potencia reactiva',
                  onTap: onAddPlyometricTransfer,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChipButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _ModificationHistoryCard extends StatelessWidget {
  final List<CoachPlanModification> modifications;

  const _ModificationHistoryCard({required this.modifications});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cambios del entrenador',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...modifications.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 18,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.coachNote.trim().isEmpty
                            ? item.description
                            : '${item.description}\nNota: ${item.coachNote}',
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

class _EditableBlockCard extends StatelessWidget {
  final DailyTrainingBlock block;
  final VoidCallback onOpen;
  final VoidCallback onEditFreely;
  final VoidCallback onIncrease;
  final VoidCallback onReduce;
  final VoidCallback onAddTenMinutes;
  final VoidCallback onRemoveTenMinutes;
  final VoidCallback onConvertToRecovery;
  final VoidCallback onConvertToSpeed;
  final VoidCallback onConvertToIntervals;
  final VoidCallback onRemove;

  const _EditableBlockCard({
    required this.block,
    required this.onOpen,
    required this.onEditFreely,
    required this.onIncrease,
    required this.onReduce,
    required this.onAddTenMinutes,
    required this.onRemoveTenMinutes,
    required this.onConvertToRecovery,
    required this.onConvertToSpeed,
    required this.onConvertToIntervals,
    required this.onRemove,
  });

  Color get color {
    if (block.recoveryFocused) return Colors.green;

    switch (block.type) {
      case TrainingBlockType.skating:
        return Colors.blue;
      case TrainingBlockType.strength:
        return Colors.deepPurple;
      case TrainingBlockType.cycling:
        return Colors.teal;
      case TrainingBlockType.mobility:
        return Colors.green;
      case TrainingBlockType.recovery:
        return Colors.green;
      case TrainingBlockType.activation:
        return Colors.orange;
      case TrainingBlockType.technical:
        return Colors.indigo;
      case TrainingBlockType.aerobic:
        return Colors.cyan;
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

  String get typeText {
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

  String get loadText {
    if (block.targetLoad >= 75) return 'Exigencia alta';
    if (block.targetLoad >= 50) return 'Exigencia media';
    return 'Exigencia controlada';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
                    block.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Ver detalle',
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(typeText)),
                Chip(label: Text(loadText)),
                Chip(label: Text('${block.durationMinutes} min')),
                if (block.km > 0)
                  Chip(label: Text('${block.km.toStringAsFixed(1)} km')),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onEditFreely,
                icon: const Icon(Icons.tune),
                label: const Text('Editar libremente'),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onRemoveTenMinutes,
                  icon: const Icon(Icons.remove),
                  label: const Text('-10 min'),
                ),
                OutlinedButton.icon(
                  onPressed: onAddTenMinutes,
                  icon: const Icon(Icons.add),
                  label: const Text('+10 min'),
                ),
                OutlinedButton.icon(
                  onPressed: onReduce,
                  icon: const Icon(Icons.shield),
                  label: const Text('Proteger'),
                ),
                FilledButton.icon(
                  onPressed: onIncrease,
                  icon: const Icon(Icons.trending_up),
                  label: const Text('Exigir más'),
                ),
                OutlinedButton.icon(
                  onPressed: onConvertToRecovery,
                  icon: const Icon(Icons.spa),
                  label: const Text('Recuperación'),
                ),
                OutlinedButton.icon(
                  onPressed: onConvertToSpeed,
                  icon: const Icon(Icons.speed),
                  label: const Text('Velocidad'),
                ),
                OutlinedButton.icon(
                  onPressed: onConvertToIntervals,
                  icon: const Icon(Icons.timer),
                  label: const Text('Intervalos'),
                ),
                IconButton(
                  tooltip: 'Eliminar bloque',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
