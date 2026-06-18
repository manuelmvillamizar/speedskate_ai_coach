import 'daily_athlete_log.dart';
import 'athlete_physiology_profile.dart';
import 'wearable_integration_service.dart';
import 'physiology/models/strength_load_state.dart';

class AthleteDailyState {
  final String athleteId;

  final DateTime date;

  final WearableDailyData? wearable;

  final DailyAthleteLog? log;

  final AthletePhysiologyProfile physiologyProfile;

  final StrengthLoadState strengthLoadState;

  final int readiness;

  final double injuryRisk;

  final String fatigueStatus;

  final double acuteLoad;

  final double chronicLoad;

  final double acwr;

  final bool shouldReduceLoad;

  final bool shouldBlockIntensity;

  final bool shouldForceRecovery;

  final bool taperRecommended;

  final String aiSummary;

  final String aiRecommendation;

  const AthleteDailyState({
    required this.athleteId,
    required this.date,
    required this.wearable,
    required this.log,
    required this.physiologyProfile,
    this.strengthLoadState = const StrengthLoadState(
      externalStrengthLoadKg: 0,
      reactiveJumpLoadKg: 0,
      totalMechanicalLoadKg: 0,
      neuralStress: 0,
      muscleStress: 0,
      tendonStress: 0,
      adaptationSignal: 'none',
    ),
    required this.readiness,
    required this.injuryRisk,
    required this.fatigueStatus,
    required this.acuteLoad,
    required this.chronicLoad,
    required this.acwr,
    required this.shouldReduceLoad,
    required this.shouldBlockIntensity,
    required this.shouldForceRecovery,
    required this.taperRecommended,
    required this.aiSummary,
    required this.aiRecommendation,
  });
  AthleteDailyState copyWith({
    DateTime? date,
    WearableDailyData? wearable,
    DailyAthleteLog? log,
    AthletePhysiologyProfile? physiologyProfile,
    StrengthLoadState? strengthLoadState,
    int? readiness,
    double? injuryRisk,
    String? fatigueStatus,
    double? acuteLoad,
    double? chronicLoad,
    double? acwr,
    bool? shouldReduceLoad,
    bool? shouldBlockIntensity,
    bool? shouldForceRecovery,
    bool? taperRecommended,
    String? aiSummary,
    String? aiRecommendation,
  }) {
    return AthleteDailyState(
      athleteId: athleteId,
      date: date ?? this.date,
      wearable: wearable ?? this.wearable,
      log: log ?? this.log,
      physiologyProfile: physiologyProfile ?? this.physiologyProfile,
      strengthLoadState: strengthLoadState ?? this.strengthLoadState,
      readiness: readiness ?? this.readiness,
      injuryRisk: injuryRisk ?? this.injuryRisk,
      fatigueStatus: fatigueStatus ?? this.fatigueStatus,
      acuteLoad: acuteLoad ?? this.acuteLoad,
      chronicLoad: chronicLoad ?? this.chronicLoad,
      acwr: acwr ?? this.acwr,
      shouldReduceLoad: shouldReduceLoad ?? this.shouldReduceLoad,
      shouldBlockIntensity: shouldBlockIntensity ?? this.shouldBlockIntensity,
      shouldForceRecovery: shouldForceRecovery ?? this.shouldForceRecovery,
      taperRecommended: taperRecommended ?? this.taperRecommended,
      aiSummary: aiSummary ?? this.aiSummary,
      aiRecommendation: aiRecommendation ?? this.aiRecommendation,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'athleteId': athleteId,
      'date': date.toIso8601String(),
      'wearable': wearable?.toMap(),
      'strengthLoadState': {
        'externalStrengthLoadKg': strengthLoadState.externalStrengthLoadKg,
        'reactiveJumpLoadKg': strengthLoadState.reactiveJumpLoadKg,
        'totalMechanicalLoadKg': strengthLoadState.totalMechanicalLoadKg,
        'neuralStress': strengthLoadState.neuralStress,
        'muscleStress': strengthLoadState.muscleStress,
        'tendonStress': strengthLoadState.tendonStress,
        'adaptationSignal': strengthLoadState.adaptationSignal,
      },
      'readiness': readiness,
      'injuryRisk': injuryRisk,
      'fatigueStatus': fatigueStatus,
      'acuteLoad': acuteLoad,
      'chronicLoad': chronicLoad,
      'acwr': acwr,
      'shouldReduceLoad': shouldReduceLoad,
      'shouldBlockIntensity': shouldBlockIntensity,
      'shouldForceRecovery': shouldForceRecovery,
      'taperRecommended': taperRecommended,
      'aiSummary': aiSummary,
      'aiRecommendation': aiRecommendation,
    };
  }

  factory AthleteDailyState.fromMap(Map<String, dynamic> map) {
    final athleteId = map['athleteId']?.toString() ?? '';

    final wearableRaw = map['wearable'];
    final strengthRaw = map['strengthLoadState'];

    StrengthLoadState strengthLoadState = StrengthLoadState.empty();

    if (strengthRaw is Map) {
      final strengthMap = Map<String, dynamic>.from(strengthRaw);

      strengthLoadState = StrengthLoadState(
        externalStrengthLoadKg:
            (strengthMap['externalStrengthLoadKg'] as num?)?.toDouble() ?? 0,
        reactiveJumpLoadKg:
            (strengthMap['reactiveJumpLoadKg'] as num?)?.toDouble() ?? 0,
        totalMechanicalLoadKg:
            (strengthMap['totalMechanicalLoadKg'] as num?)?.toDouble() ?? 0,
        neuralStress: (strengthMap['neuralStress'] as num?)?.toDouble() ?? 0,
        muscleStress: (strengthMap['muscleStress'] as num?)?.toDouble() ?? 0,
        tendonStress: (strengthMap['tendonStress'] as num?)?.toDouble() ?? 0,
        adaptationSignal: strengthMap['adaptationSignal']?.toString() ?? 'none',
      );
    }

    return AthleteDailyState(
      athleteId: athleteId,
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      wearable: wearableRaw is Map
          ? WearableDailyData.fromMap(Map<String, dynamic>.from(wearableRaw))
          : null,
      log: null,
      physiologyProfile: AthletePhysiologyProfile(athleteId: athleteId),
      strengthLoadState: strengthLoadState,
      readiness: (map['readiness'] as num?)?.round() ?? 75,
      injuryRisk: (map['injuryRisk'] as num?)?.toDouble() ?? 10.0,
      fatigueStatus: map['fatigueStatus']?.toString() ?? 'green',
      acuteLoad: (map['acuteLoad'] as num?)?.toDouble() ?? 0.0,
      chronicLoad: (map['chronicLoad'] as num?)?.toDouble() ?? 0.0,
      acwr: (map['acwr'] as num?)?.toDouble() ?? 1.0,
      shouldReduceLoad: map['shouldReduceLoad'] == true,
      shouldBlockIntensity: map['shouldBlockIntensity'] == true,
      shouldForceRecovery: map['shouldForceRecovery'] == true,
      taperRecommended: map['taperRecommended'] == true,
      aiSummary: map['aiSummary']?.toString() ?? '',
      aiRecommendation: map['aiRecommendation']?.toString() ?? '',
    );
  }
}
