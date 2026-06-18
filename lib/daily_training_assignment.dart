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
      'trainingDay': trainingDay.toMap(),
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
      trainingDay: IntegratedTrainingDay.fromMap(
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
}
