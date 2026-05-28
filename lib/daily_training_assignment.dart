import 'daily_training_block.dart';
import 'integrated_training_day.dart';

enum DailyTrainingAssignmentStatus { draft, sent, completed }

class DailyTrainingAssignment {
  final String id;
  final String athleteId;
  final DateTime date;
  final IntegratedTrainingDay trainingDay;
  final DateTime createdAt;
  final DateTime? sentAt;
  final DailyTrainingAssignmentStatus status;

  const DailyTrainingAssignment({
    required this.id,
    required this.athleteId,
    required this.date,
    required this.trainingDay,
    required this.createdAt,
    this.sentAt,
    this.status = DailyTrainingAssignmentStatus.draft,
  });

  DailyTrainingAssignment copyWith({
    DateTime? sentAt,
    DailyTrainingAssignmentStatus? status,
  }) {
    return DailyTrainingAssignment(
      id: id,
      athleteId: athleteId,
      date: date,
      trainingDay: trainingDay,
      createdAt: createdAt,
      sentAt: sentAt ?? this.sentAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'athleteId': athleteId,
      'date': date.toIso8601String(),
      'trainingDay': _trainingDayToMap(trainingDay),
      'createdAt': createdAt.toIso8601String(),
      'sentAt': sentAt?.toIso8601String(),
      'status': status.name,
    };
  }

  factory DailyTrainingAssignment.fromMap(Map<String, dynamic> map) {
    return DailyTrainingAssignment(
      id: map['id']?.toString() ?? '',
      athleteId: map['athleteId']?.toString() ?? '',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      trainingDay: _trainingDayFromMap(
        Map<String, dynamic>.from(map['trainingDay'] ?? {}),
      ),
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      sentAt: map['sentAt'] == null
          ? null
          : DateTime.tryParse(map['sentAt'].toString()),
      status: DailyTrainingAssignmentStatus.values.firstWhere(
        (value) => value.name == map['status'],
        orElse: () => DailyTrainingAssignmentStatus.draft,
      ),
    );
  }

  static Map<String, dynamic> _trainingDayToMap(IntegratedTrainingDay day) {
    return {
      'date': day.date.toIso8601String(),
      'blocks': day.blocks.map(_blockToMap).toList(),
      'aiSummary': day.aiSummary,
      'aiRecommendation': day.aiRecommendation,
      'expectedReadiness': day.expectedReadiness,
      'expectedFatigue': day.expectedFatigue,
      'taperMode': day.taperMode,
      'recoveryDay': day.recoveryDay,
    };
  }

  static IntegratedTrainingDay _trainingDayFromMap(Map<String, dynamic> map) {
    final rawBlocks = List<dynamic>.from(map['blocks'] ?? []);

    return IntegratedTrainingDay(
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      blocks: rawBlocks
          .map((item) => _blockFromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
      aiSummary: map['aiSummary']?.toString() ?? '',
      aiRecommendation: map['aiRecommendation']?.toString() ?? '',
      expectedReadiness: (map['expectedReadiness'] as num?)?.round() ?? 75,
      expectedFatigue: map['expectedFatigue']?.toString() ?? 'green',
      taperMode: map['taperMode'] == true,
      recoveryDay: map['recoveryDay'] == true,
    );
  }

  static Map<String, dynamic> _blockToMap(DailyTrainingBlock block) {
    return {
      'type': block.type.name,
      'moment': block.moment.name,
      'title': block.title,
      'description': block.description,
      'durationMinutes': block.durationMinutes,
      'km': block.km,
      'targetLoad': block.targetLoad,
      'targetHeartRateZone': block.targetHeartRateZone,
      'recoveryFocused': block.recoveryFocused,
      'taperFocused': block.taperFocused,
      'aiReason': block.aiReason,
      'stimulus': block.stimulus.name,
      'energySystem': block.energySystem.name,
      'neuromuscularLoad': block.neuromuscularLoad.name,
    };
  }

  static DailyTrainingBlock _blockFromMap(Map<String, dynamic> map) {
    return DailyTrainingBlock(
      type: TrainingBlockType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => TrainingBlockType.technical,
      ),
      moment: TrainingBlockMoment.values.firstWhere(
        (value) => value.name == map['moment'],
        orElse: () => TrainingBlockMoment.morning,
      ),
      title: map['title']?.toString() ?? 'Bloque de entrenamiento',
      description: map['description']?.toString() ?? '',
      durationMinutes: (map['durationMinutes'] as num?)?.round() ?? 0,
      km: (map['km'] as num?)?.toDouble() ?? 0,
      targetLoad: (map['targetLoad'] as num?)?.round() ?? 0,
      targetHeartRateZone: (map['targetHeartRateZone'] as num?)?.round() ?? 1,
      recoveryFocused: map['recoveryFocused'] == true,
      taperFocused: map['taperFocused'] == true,
      aiReason: map['aiReason']?.toString() ?? '',
      stimulus: TrainingStimulus.values.firstWhere(
        (value) => value.name == map['stimulus'],
        orElse: () => TrainingStimulus.technical,
      ),
      energySystem: TrainingEnergySystem.values.firstWhere(
        (value) => value.name == map['energySystem'],
        orElse: () => TrainingEnergySystem.mixed,
      ),
      neuromuscularLoad: NeuromuscularLoad.values.firstWhere(
        (value) => value.name == map['neuromuscularLoad'],
        orElse: () => NeuromuscularLoad.low,
      ),
    );
  }
}


