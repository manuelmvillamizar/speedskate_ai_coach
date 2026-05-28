import 'daily_training_block.dart';

enum CoachPlanEditType {
  increaseLoad,
  reduceLoad,
  addCore,
  addRecovery,
  addCyclingSpeedTransfer,
  addSkatingSpeed,
  addPlyometricTransfer,
  removeBlock,

  // Universal coach editor
  addCustomBlock,
  editBlock,
  changeTitle,
  changeDescription,
  changeBlockType,
  changeMoment,
  changeDuration,
  changeDistance,
  changeLoad,
  changeHeartRateZone,
  changeStimulus,
  changeEnergySystem,
  changeNeuromuscularLoad,
  changeWarmup,
  changeMainSet,
  changeExercises,
  changeStrengthExercises,
  changePlyometricExercises,
  changeTechnicalCues,
  changeTacticalCues,
  changeCooldown,
  changeCoachingNotes,
  changeStopCriteria,
}

class CoachPlanModification {
  final String id;
  final CoachPlanEditType type;
  final String description;
  final DateTime createdAt;

  final String? targetBlockTitle;
  final TrainingBlockType? blockType;
  final TrainingStimulus? stimulus;
  final TrainingEnergySystem? energySystem;
  final NeuromuscularLoad? neuromuscularLoad;

  final int? previousLoad;
  final int? newLoad;
  final int? previousDurationMinutes;
  final int? newDurationMinutes;
  final double? previousKm;
  final double? newKm;

  final TrainingBlockType? previousBlockType;
  final TrainingBlockType? newBlockType;
  final TrainingBlockMoment? previousMoment;
  final TrainingBlockMoment? newMoment;
  final TrainingStimulus? previousStimulus;
  final TrainingStimulus? newStimulus;
  final TrainingEnergySystem? previousEnergySystem;
  final TrainingEnergySystem? newEnergySystem;
  final NeuromuscularLoad? previousNeuromuscularLoad;
  final NeuromuscularLoad? newNeuromuscularLoad;

  final int? previousHeartRateZone;
  final int? newHeartRateZone;

  final String? previousTitle;
  final String? newTitle;
  final String? previousDescription;
  final String? newDescription;

  final List<String> changedFields;
  final String coachNote;

  final bool addedBlock;
  final bool removedBlock;

  const CoachPlanModification({
    required this.id,
    required this.type,
    required this.description,
    required this.createdAt,
    this.targetBlockTitle,
    this.blockType,
    this.stimulus,
    this.energySystem,
    this.neuromuscularLoad,
    this.previousLoad,
    this.newLoad,
    this.previousDurationMinutes,
    this.newDurationMinutes,
    this.previousKm,
    this.newKm,
    this.previousBlockType,
    this.newBlockType,
    this.previousMoment,
    this.newMoment,
    this.previousStimulus,
    this.newStimulus,
    this.previousEnergySystem,
    this.newEnergySystem,
    this.previousNeuromuscularLoad,
    this.newNeuromuscularLoad,
    this.previousHeartRateZone,
    this.newHeartRateZone,
    this.previousTitle,
    this.newTitle,
    this.previousDescription,
    this.newDescription,
    this.changedFields = const [],
    this.coachNote = '',
    this.addedBlock = false,
    this.removedBlock = false,
  });

  double get loadDeltaPercent {
    if (previousLoad == null || newLoad == null || previousLoad == 0) return 0;
    return ((newLoad! - previousLoad!) / previousLoad!) * 100;
  }

  double get durationDeltaPercent {
    if (previousDurationMinutes == null ||
        newDurationMinutes == null ||
        previousDurationMinutes == 0) {
      return 0;
    }

    return ((newDurationMinutes! - previousDurationMinutes!) /
            previousDurationMinutes!) *
        100;
  }

  double get kmDeltaPercent {
    if (previousKm == null || newKm == null || previousKm == 0) return 0;
    return ((newKm! - previousKm!) / previousKm!) * 100;
  }

  TrainingBlockType? get effectiveBlockType => newBlockType ?? blockType;
  TrainingStimulus? get effectiveStimulus => newStimulus ?? stimulus;
  TrainingEnergySystem? get effectiveEnergySystem =>
      newEnergySystem ?? energySystem;
  NeuromuscularLoad? get effectiveNeuromuscularLoad =>
      newNeuromuscularLoad ?? neuromuscularLoad;

  bool get targetsStrength {
    return effectiveBlockType == TrainingBlockType.strength ||
        effectiveStimulus == TrainingStimulus.maxStrength ||
        effectiveStimulus == TrainingStimulus.power ||
        effectiveStimulus == TrainingStimulus.strengthEndurance;
  }

  bool get targetsSpeed {
    return effectiveBlockType == TrainingBlockType.skating ||
        effectiveStimulus == TrainingStimulus.speed ||
        effectiveStimulus == TrainingStimulus.neuromuscular;
  }

  bool get targetsPlyometric {
    return effectiveStimulus == TrainingStimulus.plyometric ||
        effectiveNeuromuscularLoad == NeuromuscularLoad.high ||
        effectiveNeuromuscularLoad == NeuromuscularLoad.maximal;
  }

  bool get targetsLactate {
    return effectiveEnergySystem == TrainingEnergySystem.anaerobicLactic ||
        effectiveStimulus == TrainingStimulus.lactateTolerance ||
        effectiveStimulus == TrainingStimulus.anaerobic;
  }

  bool get targetsRecovery {
    return effectiveBlockType == TrainingBlockType.recovery ||
        effectiveStimulus == TrainingStimulus.recovery ||
        effectiveStimulus == TrainingStimulus.mobility;
  }

  bool get targetsCycling {
    return effectiveBlockType == TrainingBlockType.cycling;
  }

  bool get changedTrainingNature {
    return previousBlockType != null && newBlockType != null ||
        previousStimulus != null && newStimulus != null ||
        previousEnergySystem != null && newEnergySystem != null;
  }

  bool get increasedMeaningfulLoad {
    return type == CoachPlanEditType.increaseLoad ||
        loadDeltaPercent >= 8 ||
        durationDeltaPercent >= 8 ||
        kmDeltaPercent >= 8;
  }

  bool get reducedMeaningfulLoad {
    return type == CoachPlanEditType.reduceLoad ||
        loadDeltaPercent <= -8 ||
        durationDeltaPercent <= -8 ||
        kmDeltaPercent <= -8;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'targetBlockTitle': targetBlockTitle,
      'blockType': blockType?.name,
      'stimulus': stimulus?.name,
      'energySystem': energySystem?.name,
      'neuromuscularLoad': neuromuscularLoad?.name,
      'previousLoad': previousLoad,
      'newLoad': newLoad,
      'previousDurationMinutes': previousDurationMinutes,
      'newDurationMinutes': newDurationMinutes,
      'previousKm': previousKm,
      'newKm': newKm,
      'previousBlockType': previousBlockType?.name,
      'newBlockType': newBlockType?.name,
      'previousMoment': previousMoment?.name,
      'newMoment': newMoment?.name,
      'previousStimulus': previousStimulus?.name,
      'newStimulus': newStimulus?.name,
      'previousEnergySystem': previousEnergySystem?.name,
      'newEnergySystem': newEnergySystem?.name,
      'previousNeuromuscularLoad': previousNeuromuscularLoad?.name,
      'newNeuromuscularLoad': newNeuromuscularLoad?.name,
      'previousHeartRateZone': previousHeartRateZone,
      'newHeartRateZone': newHeartRateZone,
      'previousTitle': previousTitle,
      'newTitle': newTitle,
      'previousDescription': previousDescription,
      'newDescription': newDescription,
      'changedFields': changedFields,
      'coachNote': coachNote,
      'addedBlock': addedBlock,
      'removedBlock': removedBlock,
    };
  }

  factory CoachPlanModification.fromMap(Map<String, dynamic> map) {
    return CoachPlanModification(
      id:
          map['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      type: CoachPlanEditType.values.firstWhere(
        (item) => item.name == map['type']?.toString(),
        orElse: () => CoachPlanEditType.editBlock,
      ),
      description: map['description']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      targetBlockTitle: map['targetBlockTitle']?.toString(),
      blockType: _blockTypeOrNull(map['blockType']),
      stimulus: _stimulusOrNull(map['stimulus']),
      energySystem: _energySystemOrNull(map['energySystem']),
      neuromuscularLoad: _neuromuscularLoadOrNull(map['neuromuscularLoad']),
      previousLoad: (map['previousLoad'] as num?)?.round(),
      newLoad: (map['newLoad'] as num?)?.round(),
      previousDurationMinutes: (map['previousDurationMinutes'] as num?)
          ?.round(),
      newDurationMinutes: (map['newDurationMinutes'] as num?)?.round(),
      previousKm: (map['previousKm'] as num?)?.toDouble(),
      newKm: (map['newKm'] as num?)?.toDouble(),
      previousBlockType: _blockTypeOrNull(map['previousBlockType']),
      newBlockType: _blockTypeOrNull(map['newBlockType']),
      previousMoment: _momentOrNull(map['previousMoment']),
      newMoment: _momentOrNull(map['newMoment']),
      previousStimulus: _stimulusOrNull(map['previousStimulus']),
      newStimulus: _stimulusOrNull(map['newStimulus']),
      previousEnergySystem: _energySystemOrNull(map['previousEnergySystem']),
      newEnergySystem: _energySystemOrNull(map['newEnergySystem']),
      previousNeuromuscularLoad: _neuromuscularLoadOrNull(
        map['previousNeuromuscularLoad'],
      ),
      newNeuromuscularLoad: _neuromuscularLoadOrNull(
        map['newNeuromuscularLoad'],
      ),
      previousHeartRateZone: (map['previousHeartRateZone'] as num?)?.round(),
      newHeartRateZone: (map['newHeartRateZone'] as num?)?.round(),
      previousTitle: map['previousTitle']?.toString(),
      newTitle: map['newTitle']?.toString(),
      previousDescription: map['previousDescription']?.toString(),
      newDescription: map['newDescription']?.toString(),
      changedFields: _stringList(map['changedFields']),
      coachNote: map['coachNote']?.toString() ?? '',
      addedBlock: map['addedBlock'] == true,
      removedBlock: map['removedBlock'] == true,
    );
  }

  static CoachPlanModification fromBlockEdit({
    required DailyTrainingBlock previousBlock,
    required DailyTrainingBlock newBlock,
    String coachNote = '',
  }) {
    final changedFields = <String>[];

    if (previousBlock.title != newBlock.title) changedFields.add('title');
    if (previousBlock.description != newBlock.description) {
      changedFields.add('description');
    }
    if (previousBlock.type != newBlock.type) changedFields.add('type');
    if (previousBlock.moment != newBlock.moment) changedFields.add('moment');
    if (previousBlock.durationMinutes != newBlock.durationMinutes) {
      changedFields.add('duration');
    }
    if (previousBlock.km != newBlock.km) changedFields.add('distance');
    if (previousBlock.targetLoad != newBlock.targetLoad) {
      changedFields.add('load');
    }
    if (previousBlock.targetHeartRateZone != newBlock.targetHeartRateZone) {
      changedFields.add('heartRateZone');
    }
    if (previousBlock.stimulus != newBlock.stimulus) {
      changedFields.add('stimulus');
    }
    if (previousBlock.energySystem != newBlock.energySystem) {
      changedFields.add('energySystem');
    }
    if (previousBlock.neuromuscularLoad != newBlock.neuromuscularLoad) {
      changedFields.add('neuromuscularLoad');
    }
    if (!_sameList(previousBlock.warmup, newBlock.warmup)) {
      changedFields.add('warmup');
    }
    if (!_sameList(previousBlock.mainSet, newBlock.mainSet)) {
      changedFields.add('mainSet');
    }
    if (!_sameList(previousBlock.exercises, newBlock.exercises)) {
      changedFields.add('exercises');
    }
    if (!_sameList(
      previousBlock.strengthExercises,
      newBlock.strengthExercises,
    )) {
      changedFields.add('strengthExercises');
    }
    if (!_sameList(
      previousBlock.plyometricExercises,
      newBlock.plyometricExercises,
    )) {
      changedFields.add('plyometricExercises');
    }
    if (!_sameList(previousBlock.technicalCues, newBlock.technicalCues)) {
      changedFields.add('technicalCues');
    }
    if (!_sameList(previousBlock.tacticalCues, newBlock.tacticalCues)) {
      changedFields.add('tacticalCues');
    }
    if (!_sameList(previousBlock.cooldown, newBlock.cooldown)) {
      changedFields.add('cooldown');
    }
    if (!_sameList(previousBlock.coachingNotes, newBlock.coachingNotes)) {
      changedFields.add('coachingNotes');
    }
    if (!_sameList(previousBlock.stopCriteria, newBlock.stopCriteria)) {
      changedFields.add('stopCriteria');
    }

    return CoachPlanModification(
      id: newId(),
      type: CoachPlanEditType.editBlock,
      description: _buildEditDescription(
        previousBlock,
        newBlock,
        changedFields,
      ),
      createdAt: DateTime.now(),
      targetBlockTitle: previousBlock.title,
      blockType: previousBlock.type,
      stimulus: previousBlock.stimulus,
      energySystem: previousBlock.energySystem,
      neuromuscularLoad: previousBlock.neuromuscularLoad,
      previousLoad: previousBlock.targetLoad,
      newLoad: newBlock.targetLoad,
      previousDurationMinutes: previousBlock.durationMinutes,
      newDurationMinutes: newBlock.durationMinutes,
      previousKm: previousBlock.km,
      newKm: newBlock.km,
      previousBlockType: previousBlock.type,
      newBlockType: newBlock.type,
      previousMoment: previousBlock.moment,
      newMoment: newBlock.moment,
      previousStimulus: previousBlock.stimulus,
      newStimulus: newBlock.stimulus,
      previousEnergySystem: previousBlock.energySystem,
      newEnergySystem: newBlock.energySystem,
      previousNeuromuscularLoad: previousBlock.neuromuscularLoad,
      newNeuromuscularLoad: newBlock.neuromuscularLoad,
      previousHeartRateZone: previousBlock.targetHeartRateZone,
      newHeartRateZone: newBlock.targetHeartRateZone,
      previousTitle: previousBlock.title,
      newTitle: newBlock.title,
      previousDescription: previousBlock.description,
      newDescription: newBlock.description,
      changedFields: changedFields,
      coachNote: coachNote,
    );
  }

  static CoachPlanModification fromAddedBlock({
    required DailyTrainingBlock block,
    String coachNote = '',
  }) {
    return CoachPlanModification(
      id: newId(),
      type: CoachPlanEditType.addCustomBlock,
      description: 'Añadió "${block.title}" al plan.',
      createdAt: DateTime.now(),
      targetBlockTitle: block.title,
      blockType: block.type,
      stimulus: block.stimulus,
      energySystem: block.energySystem,
      neuromuscularLoad: block.neuromuscularLoad,
      newLoad: block.targetLoad,
      newDurationMinutes: block.durationMinutes,
      newKm: block.km,
      newBlockType: block.type,
      newMoment: block.moment,
      newStimulus: block.stimulus,
      newEnergySystem: block.energySystem,
      newNeuromuscularLoad: block.neuromuscularLoad,
      newHeartRateZone: block.targetHeartRateZone,
      newTitle: block.title,
      newDescription: block.description,
      changedFields: const ['addedBlock'],
      coachNote: coachNote,
      addedBlock: true,
    );
  }

  static CoachPlanModification fromRemovedBlock({
    required DailyTrainingBlock block,
    String coachNote = '',
  }) {
    return CoachPlanModification(
      id: newId(),
      type: CoachPlanEditType.removeBlock,
      description: 'Eliminó "${block.title}" del plan.',
      createdAt: DateTime.now(),
      targetBlockTitle: block.title,
      blockType: block.type,
      stimulus: block.stimulus,
      energySystem: block.energySystem,
      neuromuscularLoad: block.neuromuscularLoad,
      previousLoad: block.targetLoad,
      previousDurationMinutes: block.durationMinutes,
      previousKm: block.km,
      previousBlockType: block.type,
      previousMoment: block.moment,
      previousStimulus: block.stimulus,
      previousEnergySystem: block.energySystem,
      previousNeuromuscularLoad: block.neuromuscularLoad,
      previousHeartRateZone: block.targetHeartRateZone,
      previousTitle: block.title,
      previousDescription: block.description,
      changedFields: const ['removedBlock'],
      coachNote: coachNote,
      removedBlock: true,
    );
  }

  static String _buildEditDescription(
    DailyTrainingBlock previousBlock,
    DailyTrainingBlock newBlock,
    List<String> changedFields,
  ) {
    if (changedFields.isEmpty) {
      return 'Revisó "${previousBlock.title}" sin cambios estructurales.';
    }

    final parts = <String>[];

    if (previousBlock.type != newBlock.type) {
      parts.add(
        'cambió tipo de ${previousBlock.type.name} a ${newBlock.type.name}',
      );
    }

    if (previousBlock.stimulus != newBlock.stimulus) {
      parts.add(
        'cambió estímulo de ${previousBlock.stimulus.name} a ${newBlock.stimulus.name}',
      );
    }

    if (previousBlock.durationMinutes != newBlock.durationMinutes) {
      parts.add(
        'duración ${previousBlock.durationMinutes}→${newBlock.durationMinutes} min',
      );
    }

    if (previousBlock.km != newBlock.km) {
      parts.add(
        'distancia ${previousBlock.km.toStringAsFixed(1)}→${newBlock.km.toStringAsFixed(1)} km',
      );
    }

    if (previousBlock.targetLoad != newBlock.targetLoad) {
      parts.add('exigencia ${previousBlock.targetLoad}→${newBlock.targetLoad}');
    }

    if (parts.isEmpty) {
      parts.add('editó contenido técnico del bloque');
    }

    return 'Editó "${previousBlock.title}": ${parts.join(', ')}.';
  }

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;

    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }

    return true;
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return [];
    return value.map((item) => item.toString()).toList();
  }

  static TrainingBlockType? _blockTypeOrNull(dynamic value) {
    if (value == null) return null;

    return TrainingBlockType.values.cast<TrainingBlockType?>().firstWhere(
      (item) => item?.name == value.toString(),
      orElse: () => null,
    );
  }

  static TrainingBlockMoment? _momentOrNull(dynamic value) {
    if (value == null) return null;

    return TrainingBlockMoment.values.cast<TrainingBlockMoment?>().firstWhere(
      (item) => item?.name == value.toString(),
      orElse: () => null,
    );
  }

  static TrainingStimulus? _stimulusOrNull(dynamic value) {
    if (value == null) return null;

    return TrainingStimulus.values.cast<TrainingStimulus?>().firstWhere(
      (item) => item?.name == value.toString(),
      orElse: () => null,
    );
  }

  static TrainingEnergySystem? _energySystemOrNull(dynamic value) {
    if (value == null) return null;

    return TrainingEnergySystem.values.cast<TrainingEnergySystem?>().firstWhere(
      (item) => item?.name == value.toString(),
      orElse: () => null,
    );
  }

  static NeuromuscularLoad? _neuromuscularLoadOrNull(dynamic value) {
    if (value == null) return null;

    return NeuromuscularLoad.values.cast<NeuromuscularLoad?>().firstWhere(
      (item) => item?.name == value.toString(),
      orElse: () => null,
    );
  }

  static String newId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}
