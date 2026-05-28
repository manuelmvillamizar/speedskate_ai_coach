import 'coach_plan_modification.dart';
import 'daily_training_block.dart';

class IntegratedTrainingDay {
  final DateTime date;
  final List<DailyTrainingBlock> blocks;

  final String aiSummary;
  final String aiRecommendation;

  final int expectedReadiness;
  final String expectedFatigue;
  final bool taperMode;
  final bool recoveryDay;

  final List<CoachPlanModification> coachModifications;

  const IntegratedTrainingDay({
    required this.date,
    required this.blocks,
    required this.aiSummary,
    required this.aiRecommendation,
    required this.expectedReadiness,
    required this.expectedFatigue,
    required this.taperMode,
    required this.recoveryDay,
    this.coachModifications = const [],
  });

  int get totalMinutes {
    return blocks.fold<int>(0, (sum, block) => sum + block.durationMinutes);
  }

  double get totalKm {
    return blocks.fold<double>(0, (sum, block) => sum + block.km);
  }

  int get totalLoad {
    return blocks.fold<int>(0, (sum, block) => sum + block.targetLoad);
  }

  bool get wasModifiedByCoach => coachModifications.isNotEmpty;

  List<DailyTrainingBlock> get morningBlocks {
    return blocks
        .where((block) => block.moment == TrainingBlockMoment.morning)
        .toList();
  }

  List<DailyTrainingBlock> get afternoonBlocks {
    return blocks
        .where((block) => block.moment == TrainingBlockMoment.afternoon)
        .toList();
  }

  List<DailyTrainingBlock> get eveningBlocks {
    return blocks
        .where((block) => block.moment == TrainingBlockMoment.evening)
        .toList();
  }

  bool get hasDoubleSession {
    return blocks.length >= 2;
  }

  bool get hasHighLoadDay {
    return totalLoad >= 140;
  }

  bool get hasRecoveryBlock {
    return blocks.any((block) => block.recoveryFocused);
  }

  bool get hasStrengthAndSkating {
    final hasStrength = blocks.any(
      (block) => block.type == TrainingBlockType.strength,
    );

    final hasSkating = blocks.any(
      (block) => block.type == TrainingBlockType.skating,
    );

    return hasStrength && hasSkating;
  }

  IntegratedTrainingDay copyWith({
    DateTime? date,
    List<DailyTrainingBlock>? blocks,
    String? aiSummary,
    String? aiRecommendation,
    int? expectedReadiness,
    String? expectedFatigue,
    bool? taperMode,
    bool? recoveryDay,
    List<CoachPlanModification>? coachModifications,
  }) {
    return IntegratedTrainingDay(
      date: date ?? this.date,
      blocks: blocks ?? this.blocks,
      aiSummary: aiSummary ?? this.aiSummary,
      aiRecommendation: aiRecommendation ?? this.aiRecommendation,
      expectedReadiness: expectedReadiness ?? this.expectedReadiness,
      expectedFatigue: expectedFatigue ?? this.expectedFatigue,
      taperMode: taperMode ?? this.taperMode,
      recoveryDay: recoveryDay ?? this.recoveryDay,
      coachModifications: coachModifications ?? this.coachModifications,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'blocks': blocks.map((block) => block.toMap()).toList(),
      'aiSummary': aiSummary,
      'aiRecommendation': aiRecommendation,
      'expectedReadiness': expectedReadiness,
      'expectedFatigue': expectedFatigue,
      'taperMode': taperMode,
      'recoveryDay': recoveryDay,
      'coachModifications': coachModifications
          .map((modification) => modification.toMap())
          .toList(),
    };
  }

  factory IntegratedTrainingDay.fromMap(Map<String, dynamic> map) {
    return IntegratedTrainingDay(
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      blocks: ((map['blocks'] ?? []) as List<dynamic>).map((item) {
        return DailyTrainingBlock.fromMap(Map<String, dynamic>.from(item));
      }).toList(),
      aiSummary: map['aiSummary']?.toString() ?? '',
      aiRecommendation: map['aiRecommendation']?.toString() ?? '',
      expectedReadiness: (map['expectedReadiness'] as num?)?.round() ?? 75,
      expectedFatigue: map['expectedFatigue']?.toString() ?? 'green',
      taperMode: map['taperMode'] == true,
      recoveryDay: map['recoveryDay'] == true,
      coachModifications: ((map['coachModifications'] ?? []) as List<dynamic>)
          .map((item) {
            return CoachPlanModification.fromMap(
              Map<String, dynamic>.from(item),
            );
          })
          .toList(),
    );
  }
}
