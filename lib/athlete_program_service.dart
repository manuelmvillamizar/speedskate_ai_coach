import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'athlete_season_engine.dart';
import 'auto_adjust_screen.dart';
import 'coach_planning_preferences.dart';
import 'periodization_engine.dart';
import 'training_library/training_library_models.dart';
import 'training_system/microcycle/weekly_microcycle_builder.dart';

enum AthleteProgramType { sprinter, endurance, mixed }

enum AthleteProgramLevel { novice, competitive, elite }

enum CompetitionPriority { preparation, important, main }

class AthleteCompetition {
  final String id;
  final String name;
  final DateTime date;
  final DateTime endDate;
  final String location;
  final CompetitionPriority priority;
  final List<String> events;

  AthleteCompetition({
    required this.id,
    required this.name,
    required this.date,
    DateTime? endDate,
    required this.location,
    required this.priority,
    required this.events,
  }) : endDate = endDate ?? date;
}

class AthleteTrainingWeek {
  final int weekNumber;
  final DateTime startDate;
  final DateTime endDate;

  final String phaseEs;
  final String phaseEn;
  final String phaseDe;

  final String goalEs;
  final String goalEn;
  final String goalDe;

  final PeriodizationMicrocycle microcycle;
  final WeeklyMicrocyclePlan? intelligentPlan;

  final AthleteCompetition? targetCompetition;

  final int gymDays;
  final int skateDays;
  final int recoveryDays;

  final bool taperWeek;
  final bool postCompetitionDeload;

  AthleteTrainingWeek({
    required this.weekNumber,
    required this.startDate,
    required this.endDate,
    required this.phaseEs,
    required this.phaseEn,
    required this.phaseDe,
    required this.goalEs,
    required this.goalEn,
    required this.goalDe,
    required this.microcycle,
    this.intelligentPlan,
    this.targetCompetition,
    this.gymDays = 0,
    this.skateDays = 0,
    this.recoveryDays = 0,
    this.taperWeek = false,
    this.postCompetitionDeload = false,
  });
}

class AthleteProgramProfile {
  final String id;
  String name;
  String category;
  AthleteProgramType type;
  AthleteProgramLevel level;
  int age;
  double weightKg;
  double heightCm;
  String email;
  String whatsapp;
  DateTime? birthDate;

  DateTime? savedSeasonStartDate;
  int? savedSeasonWeeks;
  AutoPhysiologyStatus savedSeasonFatigue;

  CoachPlanningPreferences planningPreferences;

  final List<AthleteCompetition> competitions;
  final List<AthleteTrainingWeek> seasonPlan;

  AthleteProgramProfile({
    required this.id,
    required this.name,
    required this.category,
    required this.type,
    required this.level,
    required this.age,
    required this.weightKg,
    this.heightCm = 0,
    this.email = '',
    this.whatsapp = '',
    this.birthDate,
    this.savedSeasonStartDate,
    this.savedSeasonWeeks,
    this.savedSeasonFatigue = AutoPhysiologyStatus.green,
    CoachPlanningPreferences? planningPreferences,
    List<AthleteCompetition>? competitions,
    List<AthleteTrainingWeek>? seasonPlan,
  }) : planningPreferences =
           planningPreferences ?? const CoachPlanningPreferences(),
       competitions = competitions ?? [],
       seasonPlan = seasonPlan ?? [];
}

class AthleteProgramService extends ChangeNotifier {
  static final AthleteProgramService instance = AthleteProgramService._();

  static const String _storageKey = 'speedskate_athletes_v1';
  static const String _activeAthleteKey = 'speedskate_active_athlete_v1';

  AthleteProgramService._() {
    _loadData();
  }

  final List<AthleteProgramProfile> athletes = [];
  String? activeAthleteId;

  bool _loaded = false;
  bool get loaded => _loaded;

  AthleteProgramProfile? get activeAthlete {
    if (athletes.isEmpty) return null;

    if (activeAthleteId == null) return athletes.first;

    for (final athlete in athletes) {
      if (athlete.id == activeAthleteId) return athlete;
    }

    return athletes.first;
  }

  static int calculateAge(DateTime birthDate, {DateTime? today}) {
    final now = today ?? DateTime.now();

    var age = now.year - birthDate.year;

    final birthdayThisYear = DateTime(now.year, birthDate.month, birthDate.day);

    if (now.isBefore(birthdayThisYear)) {
      age--;
    }

    return age < 0 ? 0 : age;
  }

  static String calculateSkatingCategory(
    DateTime birthDate, {
    DateTime? today,
  }) {
    final age = calculateAge(birthDate, today: today);

    if (age <= 11) return 'Infantil / menores';
    if (age <= 14) return 'Prejuvenil';
    if (age <= 17) return 'Juvenil';
    if (age <= 19) return 'Junior';
    if (age <= 34) return 'Senior';
    return 'Master';
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();

      final raw = prefs.getString(_storageKey);

      final savedActiveId = prefs.getString(_activeAthleteKey);

      final loadedAthletes = <AthleteProgramProfile>[];

      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;

        for (final item in decoded) {
          try {
            final map = item as Map<String, dynamic>;

            final birthDate = DateTime.tryParse(
              map['birthDate'] as String? ?? '',
            );

            final calculatedAge = birthDate == null
                ? (map['age'] as num?)?.toInt() ?? 0
                : calculateAge(birthDate);

            final calculatedCategory = birthDate == null
                ? map['category'] as String? ?? 'Sin categoría'
                : calculateSkatingCategory(birthDate);

            final athlete = AthleteProgramProfile(
              id: map['id'] as String,
              name: map['name'] as String? ?? 'Atleta',
              category: calculatedCategory,
              type: _typeFromString(map['type'] as String? ?? 'sprinter'),
              level: _levelFromString(map['level'] as String? ?? 'competitive'),
              age: calculatedAge,
              weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0,
              heightCm: (map['heightCm'] as num?)?.toDouble() ?? 0,
              email: map['email'] as String? ?? '',
              whatsapp: map['whatsapp'] as String? ?? '',
              birthDate: birthDate,
              savedSeasonStartDate: map['savedSeasonStartDate'] == null
                  ? null
                  : DateTime.tryParse(map['savedSeasonStartDate'] as String),
              savedSeasonWeeks: (map['savedSeasonWeeks'] as num?)?.toInt(),
              savedSeasonFatigue: _fatigueFromString(
                map['savedSeasonFatigue'] as String? ?? 'green',
              ),
              planningPreferences: CoachPlanningPreferences.fromMap(
                map['planningPreferences'] as Map<String, dynamic>?,
              ),
              competitions: ((map['competitions'] ?? []) as List<dynamic>).map((
                competitionRaw,
              ) {
                final competitionMap = competitionRaw as Map<String, dynamic>;

                final startDate =
                    DateTime.tryParse(
                      competitionMap['date'] as String? ?? '',
                    ) ??
                    DateTime.now();

                final endDate =
                    DateTime.tryParse(
                      competitionMap['endDate'] as String? ?? '',
                    ) ??
                    startDate;

                return AthleteCompetition(
                  id: competitionMap['id'] as String,
                  name: competitionMap['name'] as String? ?? 'Competencia',
                  date: startDate,
                  endDate: endDate,
                  location: competitionMap['location'] as String? ?? '',
                  priority: _priorityFromString(
                    competitionMap['priority'] as String? ?? 'main',
                  ),
                  events: ((competitionMap['events'] ?? []) as List<dynamic>)
                      .map((event) => event.toString())
                      .toList(),
                );
              }).toList(),
            );

            loadedAthletes.add(athlete);
          } catch (_) {
            continue;
          }
        }
      }

      athletes
        ..clear()
        ..addAll(loadedAthletes);

      activeAthleteId = savedActiveId;

      if (activeAthleteId == null && athletes.isNotEmpty) {
        activeAthleteId = athletes.first.id;
      }

      for (final athlete in athletes) {
        _refreshAthleteAgeAndCategory(athlete);
        _rebuildExistingSeasonIfNeeded(athlete);
      }
    } catch (_) {
      athletes.clear();
      activeAthleteId = null;
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    for (final athlete in athletes) {
      _refreshAthleteAgeAndCategory(athlete);
    }

    final data = athletes.map(_athleteToMap).toList();

    await prefs.setString(_storageKey, jsonEncode(data));

    if (activeAthleteId != null) {
      await prefs.setString(_activeAthleteKey, activeAthleteId!);
    } else {
      await prefs.remove(_activeAthleteKey);
    }
  }

  void _refreshAthleteAgeAndCategory(AthleteProgramProfile athlete) {
    final birthDate = athlete.birthDate;

    if (birthDate == null) return;

    athlete.age = calculateAge(birthDate);
    athlete.category = calculateSkatingCategory(birthDate);
  }

  Map<String, dynamic> _athleteToMap(AthleteProgramProfile athlete) {
    return {
      'id': athlete.id,
      'name': athlete.name,
      'category': athlete.category,
      'type': athlete.type.name,
      'level': athlete.level.name,
      'age': athlete.age,
      'weightKg': athlete.weightKg,
      'heightCm': athlete.heightCm,
      'email': athlete.email,
      'whatsapp': athlete.whatsapp,
      'birthDate': athlete.birthDate?.toIso8601String(),
      'savedSeasonStartDate': athlete.savedSeasonStartDate?.toIso8601String(),
      'savedSeasonWeeks': athlete.savedSeasonWeeks,
      'savedSeasonFatigue': athlete.savedSeasonFatigue.name,
      'planningPreferences': athlete.planningPreferences.toMap(),
      'competitions': athlete.competitions.map(_competitionToMap).toList(),
    };
  }

  Map<String, dynamic> _competitionToMap(AthleteCompetition competition) {
    return {
      'id': competition.id,
      'name': competition.name,
      'date': competition.date.toIso8601String(),
      'endDate': competition.endDate.toIso8601String(),
      'location': competition.location,
      'priority': competition.priority.name,
      'events': competition.events,
    };
  }

  Future<void> selectAthlete(String id) async {
    activeAthleteId = id;
    await _saveData();
    notifyListeners();
  }

  Future<void> addAthlete(AthleteProgramProfile athlete) async {
    _refreshAthleteAgeAndCategory(athlete);

    athletes.removeWhere((item) => item.id == athlete.id);
    athletes.add(athlete);
    activeAthleteId = athlete.id;

    await _saveData();
    notifyListeners();
  }

  Future<void> updateAthlete({
    required String athleteId,
    required String name,
    required String category,
    required AthleteProgramType type,
    required AthleteProgramLevel level,
    required int age,
    required double weightKg,
    required double heightCm,
    required String email,
    required String whatsapp,

    DateTime? birthDate,
  }) async {
    final athlete = athletes.firstWhere((a) => a.id == athleteId);

    athlete.name = name;
    athlete.type = type;
    athlete.level = level;
    athlete.weightKg = weightKg;
    athlete.heightCm = heightCm;
    athlete.email = email;
    athlete.whatsapp = whatsapp;
    athlete.birthDate = birthDate ?? athlete.birthDate;

    if (athlete.birthDate != null) {
      _refreshAthleteAgeAndCategory(athlete);
    } else {
      athlete.age = age;
      athlete.category = category;
    }

    await _saveData();
    notifyListeners();
  }

  Future<void> updateAthleteWeight({
    required String athleteId,
    required double weightKg,
  }) async {
    final athlete = athletes.firstWhere((a) => a.id == athleteId);

    athlete.weightKg = weightKg;

    await _saveData();
    notifyListeners();
  }

  Future<void> updatePlanningPreferences({
    required String athleteId,
    required CoachPlanningPreferences preferences,
  }) async {
    final athlete = athletes.firstWhere((a) => a.id == athleteId);

    athlete.planningPreferences = preferences;

    if (athlete.savedSeasonStartDate != null &&
        athlete.savedSeasonWeeks != null &&
        preferences.useSeasonPlanning) {
      _buildSeasonForAthlete(
        athlete: athlete,
        startDate: athlete.savedSeasonStartDate!,
        totalWeeks: athlete.savedSeasonWeeks!,
        fatigueStatus: athlete.savedSeasonFatigue,
      );
    }

    await _saveData();
    notifyListeners();
  }

  Future<void> deleteAthlete(String id) async {
    athletes.removeWhere((athlete) => athlete.id == id);

    if (activeAthleteId == id) {
      activeAthleteId = athletes.isEmpty ? null : athletes.first.id;
    }

    await _saveData();
    notifyListeners();
  }

  Future<void> addCompetition({
    required String athleteId,
    required AthleteCompetition competition,
  }) async {
    final athlete = athletes.firstWhere((a) => a.id == athleteId);

    athlete.competitions.add(competition);
    athlete.competitions.sort((a, b) => a.date.compareTo(b.date));

    _rebuildExistingSeasonIfNeeded(athlete);

    await _saveData();
    notifyListeners();
  }

  Future<void> deleteCompetition({
    required String athleteId,
    required String competitionId,
  }) async {
    final athlete = athletes.firstWhere((a) => a.id == athleteId);

    athlete.competitions.removeWhere((c) => c.id == competitionId);

    _rebuildExistingSeasonIfNeeded(athlete);

    await _saveData();
    notifyListeners();
  }

  void _rebuildExistingSeasonIfNeeded(AthleteProgramProfile athlete) {
    if (athlete.savedSeasonStartDate == null ||
        athlete.savedSeasonWeeks == null ||
        !athlete.planningPreferences.useSeasonPlanning) {
      return;
    }

    _buildSeasonForAthlete(
      athlete: athlete,
      startDate: athlete.savedSeasonStartDate!,
      totalWeeks: athlete.savedSeasonWeeks!,
      fatigueStatus: athlete.savedSeasonFatigue,
    );
  }

  Future<void> generateSeasonForAthlete({
    required String athleteId,
    required DateTime startDate,
    required int totalWeeks,
    AutoPhysiologyStatus fatigueStatus = AutoPhysiologyStatus.green,
  }) async {
    final athlete = athletes.firstWhere((a) => a.id == athleteId);

    athlete.savedSeasonStartDate = startDate;
    athlete.savedSeasonWeeks = totalWeeks;
    athlete.savedSeasonFatigue = fatigueStatus;

    _buildSeasonForAthlete(
      athlete: athlete,
      startDate: startDate,
      totalWeeks: totalWeeks,
      fatigueStatus: fatigueStatus,
    );

    await _saveData();
    notifyListeners();
  }

  void _buildSeasonForAthlete({
    required AthleteProgramProfile athlete,
    required DateTime startDate,
    required int totalWeeks,
    required AutoPhysiologyStatus fatigueStatus,
  }) {
    final generatedSeason = AthleteSeasonEngine.generateSeason(
      athleteName: athlete.name,
      athleteType: _periodizationType(athlete.type),
      level: _periodizationLevel(athlete.level),
      startDate: startDate,
      totalWeeks: totalWeeks,
      competitions: athlete.competitions
          .map(
            (competition) => SeasonCompetitionInput(
              id: competition.id,
              name: competition.name,
              date: competition.date,
              location: competition.location,
              priority: _priorityValue(competition.priority),
            ),
          )
          .toList(),
      fatigueStatus: fatigueStatus,
    );

    athlete.seasonPlan.clear();

    final recentSessionIds = <String>[];

    athlete.seasonPlan.addAll(
      generatedSeason.weeks.map((week) {
        final taperPhase =
            week.taperWeek ||
            week.phase == SeasonPhase.preCompetition ||
            week.phase == SeasonPhase.competition;

        final effectiveFatigue = _effectiveFatigueForWeek(
          baseFatigue: fatigueStatus,
          phase: week.phase,
          taperWeek: week.taperWeek,
          postCompetitionDeload: week.postCompetitionDeload,
        );

        final preferredTrainingDays = _trainingDaysFromPreferences(
          athlete.planningPreferences,
          fallbackGymDays: week.gymDays,
          fallbackSkateDays: week.skateDays,
          fallbackRecoveryDays: week.recoveryDays,
          level: athlete.level,
        );

        final intelligentPlan = WeeklyMicrocycleBuilder.build(
          modality: _trainingLibraryModality(athlete.type),
          readiness: _readinessFromFatigue(effectiveFatigue),
          acwr: _acwrFromFatigue(effectiveFatigue),
          taperPhase: taperPhase,
          trainingDays: preferredTrainingDays,
          recentSessionIds: recentSessionIds,
        );

        for (final day in intelligentPlan.days) {
          for (final session in day.sessions) {
            recentSessionIds.add(session.id);
          }
        }

        while (recentSessionIds.length > 60) {
          recentSessionIds.removeAt(0);
        }

        return AthleteTrainingWeek(
          weekNumber: week.weekNumber,
          startDate: week.startDate,
          endDate: week.endDate,
          phaseEs: _phaseEs(week.phase),
          phaseEn: _phaseEn(week.phase),
          phaseDe: _phaseDe(week.phase),
          goalEs: week.goalEs,
          goalEn: week.goalEn,
          goalDe: week.goalDe,
          microcycle: week.microcycle,
          intelligentPlan: intelligentPlan,
          targetCompetition: _findCompetitionById(
            athlete.competitions,
            week.competition?.id,
          ),
          gymDays: athlete.planningPreferences.strengthSessionsPerWeek,
          skateDays: athlete.planningPreferences.skatingSessionsPerWeek,
          recoveryDays: athlete.planningPreferences.mobilitySessionsPerWeek,
          taperWeek: week.taperWeek,
          postCompetitionDeload: week.postCompetitionDeload,
        );
      }),
    );
  }

  int _trainingDaysFromPreferences(
    CoachPlanningPreferences preferences, {
    required AthleteProgramLevel level,
    required int fallbackGymDays,
    required int fallbackSkateDays,
    required int fallbackRecoveryDays,
  }) {
    final preferredSessions = preferences.totalWeeklySessions;

    if (!preferences.allowDoubleSessions) {
      return preferredSessions.clamp(3, 7).toInt();
    }

    if (preferredSessions >= 10) return 7;
    if (preferredSessions >= 8) return 6;
    if (preferredSessions >= 5) return 5;

    final fallbackTotal =
        fallbackGymDays + fallbackSkateDays + fallbackRecoveryDays;

    if (fallbackTotal >= 3) {
      return fallbackTotal.clamp(3, 7).toInt();
    }

    switch (level) {
      case AthleteProgramLevel.novice:
        return 4;
      case AthleteProgramLevel.competitive:
        return 6;
      case AthleteProgramLevel.elite:
        return 6;
    }
  }

  AutoPhysiologyStatus _effectiveFatigueForWeek({
    required AutoPhysiologyStatus baseFatigue,
    required SeasonPhase phase,
    required bool taperWeek,
    required bool postCompetitionDeload,
  }) {
    if (postCompetitionDeload || phase == SeasonPhase.transition) {
      return AutoPhysiologyStatus.orange;
    }

    if (taperWeek || phase == SeasonPhase.preCompetition) {
      return AutoPhysiologyStatus.yellow;
    }

    if (phase == SeasonPhase.competition) {
      return AutoPhysiologyStatus.yellow;
    }

    return baseFatigue;
  }

  double _readinessFromFatigue(AutoPhysiologyStatus status) {
    switch (status) {
      case AutoPhysiologyStatus.green:
        return 0.85;
      case AutoPhysiologyStatus.yellow:
        return 0.68;
      case AutoPhysiologyStatus.orange:
        return 0.48;
      case AutoPhysiologyStatus.red:
        return 0.30;
    }
  }

  double _acwrFromFatigue(AutoPhysiologyStatus status) {
    switch (status) {
      case AutoPhysiologyStatus.green:
        return 1.00;
      case AutoPhysiologyStatus.yellow:
        return 1.25;
      case AutoPhysiologyStatus.orange:
        return 1.45;
      case AutoPhysiologyStatus.red:
        return 1.65;
    }
  }

  TrainingLibraryModality _trainingLibraryModality(AthleteProgramType type) {
    switch (type) {
      case AthleteProgramType.sprinter:
        return TrainingLibraryModality.sprinter;
      case AthleteProgramType.endurance:
        return TrainingLibraryModality.endurance;
      case AthleteProgramType.mixed:
        return TrainingLibraryModality.mixed;
    }
  }

  AthleteCompetition? _findCompetitionById(
    List<AthleteCompetition> competitions,
    String? id,
  ) {
    if (id == null) return null;

    for (final competition in competitions) {
      if (competition.id == id) return competition;
    }

    return null;
  }

  PeriodizationAthleteType _periodizationType(AthleteProgramType type) {
    switch (type) {
      case AthleteProgramType.sprinter:
        return PeriodizationAthleteType.sprinter;
      case AthleteProgramType.endurance:
        return PeriodizationAthleteType.endurance;
      case AthleteProgramType.mixed:
        return PeriodizationAthleteType.mixed;
    }
  }

  PeriodizationLevel _periodizationLevel(AthleteProgramLevel level) {
    switch (level) {
      case AthleteProgramLevel.novice:
        return PeriodizationLevel.beginner;
      case AthleteProgramLevel.competitive:
        return PeriodizationLevel.competitive;
      case AthleteProgramLevel.elite:
        return PeriodizationLevel.elite;
    }
  }

  int _priorityValue(CompetitionPriority priority) {
    switch (priority) {
      case CompetitionPriority.preparation:
        return 1;
      case CompetitionPriority.important:
        return 2;
      case CompetitionPriority.main:
        return 3;
    }
  }

  AthleteProgramType _typeFromString(String value) {
    return AthleteProgramType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => AthleteProgramType.sprinter,
    );
  }

  AthleteProgramLevel _levelFromString(String value) {
    return AthleteProgramLevel.values.firstWhere(
      (level) => level.name == value,
      orElse: () => AthleteProgramLevel.competitive,
    );
  }

  CompetitionPriority _priorityFromString(String value) {
    return CompetitionPriority.values.firstWhere(
      (priority) => priority.name == value,
      orElse: () => CompetitionPriority.main,
    );
  }

  AutoPhysiologyStatus _fatigueFromString(String value) {
    return AutoPhysiologyStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => AutoPhysiologyStatus.green,
    );
  }

  String _phaseEs(SeasonPhase phase) {
    switch (phase) {
      case SeasonPhase.generalPreparation:
        return 'Preparación general';
      case SeasonPhase.specificPreparation:
        return 'Preparación específica';
      case SeasonPhase.preCompetition:
        return 'Precompetencia / taper';
      case SeasonPhase.competition:
        return 'Competencia';
      case SeasonPhase.transition:
        return 'Transición / descarga';
    }
  }

  String _phaseEn(SeasonPhase phase) {
    switch (phase) {
      case SeasonPhase.generalPreparation:
        return 'General preparation';
      case SeasonPhase.specificPreparation:
        return 'Specific preparation';
      case SeasonPhase.preCompetition:
        return 'Pre-competition / taper';
      case SeasonPhase.competition:
        return 'Competition';
      case SeasonPhase.transition:
        return 'Transition / deload';
    }
  }

  String _phaseDe(SeasonPhase phase) {
    switch (phase) {
      case SeasonPhase.generalPreparation:
        return 'Allgemeine Vorbereitung';
      case SeasonPhase.specificPreparation:
        return 'Spezifische Vorbereitung';
      case SeasonPhase.preCompetition:
        return 'Vorwettkampf / Taper';
      case SeasonPhase.competition:
        return 'Wettkampf';
      case SeasonPhase.transition:
        return 'Übergang / Entlastung';
    }
  }
}
