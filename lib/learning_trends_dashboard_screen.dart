import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'adaptive_response_memory.dart';
import 'adaptive_response_memory_storage_service.dart';
import 'athlete_context_service.dart';
import 'athlete_physiology_profile.dart';
import 'app_language.dart';
import 'app_text.dart';
import 'daily_athlete_log.dart';
import 'daily_log_storage_service.dart';
import 'physiology_profile_storage_service.dart';
import 'physiology_sports_translator.dart';
import 'training_log_alerts_screen.dart';

class LearningTrendsDashboardScreen extends StatefulWidget {
  const LearningTrendsDashboardScreen({super.key});

  @override
  State<LearningTrendsDashboardScreen> createState() =>
      _LearningTrendsDashboardScreenState();
}

class _LearningTrendsDashboardScreenState
    extends State<LearningTrendsDashboardScreen> {
  static const Color bg = Color(0xFF0B0B0F);
  static const Color cardBg = Color(0xFF17171C);

  AdaptiveResponseMemory? _memory;
  AthletePhysiologyProfile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final athleteContext = context.read<AthleteContextService>();
    final athleteId = athleteContext.activeAthleteId;

    if (athleteId == null) {
      setState(() {
        _error = 'No hay atleta activo';
        _loading = false;
      });
      return;
    }

    try {
      final memory = await AdaptiveResponseMemoryStorageService.loadMemory(
        athleteId,
      );

      final profile = await PhysiologyProfileStorageService.loadProfile(
        athleteId,
      );

      setState(() {
        _memory = memory;
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error cargando datos: $e';
        _loading = false;
      });
    }
  }

  Future<List<DailyAthleteLog>> _loadAthleteLogs() async {
    final athleteId = context.read<AthleteContextService>().activeAthleteId;

    if (athleteId == null) return [];

    final logs = await DailyLogStorageService.loadLogs(athleteId);

    final sorted = List<DailyAthleteLog>.from(logs)
      ..sort((a, b) => a.date.compareTo(b.date));

    return sorted;
  }

  Future<Map<String, dynamic>> _loadSportsTranslations() async {
    final athleteContext = context.read<AthleteContextService>();
    final athleteId = athleteContext.activeAthleteId;
    final dailyState = athleteContext.currentDailyState;
    final wearable = athleteContext.activeWearable;

    final interpretations = <SportsMetricInterpretation>[];

    if (dailyState != null) {
      interpretations.add(
        PhysiologySportsTranslator.translateReadiness(dailyState.readiness),
      );
    } else if (wearable != null) {
      int estimatedAvailability = 75;

      if (wearable.hasRealHrv && wearable.hrv < 45) {
        estimatedAvailability -= 15;
      }

      if (wearable.hasRealSleep && wearable.sleepHours < 6.5) {
        estimatedAvailability -= 15;
      }

      if (wearable.hasRealStress && wearable.stress > 65) {
        estimatedAvailability -= 10;
      }

      interpretations.add(
        PhysiologySportsTranslator.translateReadiness(
          estimatedAvailability.clamp(0, 100),
        ),
      );
    }

    if (wearable != null && wearable.hasRealHrv) {
      final baselineHrv = _profile?.baselineHrv ?? wearable.hrv.toDouble();

      interpretations.add(
        PhysiologySportsTranslator.translateHrv(
          wearable.hrv.toDouble(),
          baselineHrv,
        ),
      );
    }

    if (wearable != null && wearable.hasRealSleep) {
      interpretations.add(
        PhysiologySportsTranslator.translateSleep(wearable.sleepHours),
      );
    }

    if (athleteId != null) {
      final logs = await DailyLogStorageService.loadLogs(athleteId);

      if (logs.isNotEmpty) {
        final sortedLogs = List<DailyAthleteLog>.from(logs)
          ..sort((a, b) => b.date.compareTo(a.date));

        final lastLog = sortedLogs.first;

        interpretations.add(
          PhysiologySportsTranslator.translateRpe(lastLog.rpe),
        );

        interpretations.add(
          PhysiologySportsTranslator.translateSoreness(lastLog.soreness),
        );
      }
    }

    if (wearable != null && wearable.hasRealTrainingLoad) {
      final maxDailyLoad = _profile?.maxDailyLoad ?? 120.0;

      interpretations.add(
        PhysiologySportsTranslator.translateTrainingLoad(
          wearable.trainingLoad,
          maxDailyLoad,
        ),
      );
    }

    return {'interpretations': interpretations};
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageNotifier>().current;

    if (_loading) {
      return const ColoredBox(
        color: bg,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return ColoredBox(
        color: bg,
        child: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.white70)),
        ),
      );
    }

    return Container(
      color: bg,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _DashboardHeader(),
          const SizedBox(height: 18),

          _buildAthleteEvolutionDashboard(lang),

          const SizedBox(height: 18),

          _buildRecoveryFatigueSection(lang, _profile, _memory),

          const SizedBox(height: 18),

          _buildCapacityEvolutionSection(lang, _profile),

          const SizedBox(height: 18),

          _buildCompetitiveProjectionSection(lang, _profile),

          const SizedBox(height: 18),

          const Text(
            'Lectura deportiva actual',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'La app traduce los datos del atleta a señales simples para el entrenador.',
            style: TextStyle(fontSize: 13, color: Colors.white60),
          ),
          const SizedBox(height: 14),

          FutureBuilder<Map<String, dynamic>>(
            future: _loadSportsTranslations(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _DarkCard(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return const _InfoCard(
                  text:
                      'Conecta un wearable y registra entrenamientos para ver la lectura deportiva.',
                );
              }

              final data = snapshot.data!;
              final interpretations =
                  data['interpretations'] as List<SportsMetricInterpretation>;

              if (interpretations.isEmpty) {
                return const _InfoCard(
                  text:
                      'Aún no hay datos suficientes. Registra días de entrenamiento para construir tendencia.',
                );
              }

              return Column(
                children: interpretations
                    .map((interp) => _SportsMetricCard(interpretation: interp))
                    .toList(),
              );
            },
          ),

          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _buildAthleteEvolutionDashboard(AppLanguage lang) {
    return FutureBuilder<List<DailyAthleteLog>>(
      future: _loadAthleteLogs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _DarkCard(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final logs = snapshot.data ?? [];

        if (logs.isEmpty) {
          return const _DarkCard(
            child: Text(
              'Aún no hay suficientes registros para construir la evolución del atleta.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        final now = DateTime.now();
        final last7 = logs
            .where(
              (log) => log.date.isAfter(now.subtract(const Duration(days: 7))),
            )
            .toList();

        final last28 = logs
            .where(
              (log) => log.date.isAfter(now.subtract(const Duration(days: 28))),
            )
            .toList();

        final minutes7 = _sumInt(last7, (log) => log.performedMinutes);
        final minutes28 = _sumInt(last28, (log) => log.performedMinutes);
        final load7 = _sumInt(last7, (log) => log.performedLoad);
        final load28 = _sumInt(last28, (log) => log.performedLoad);
        final km7 = _sumDouble(last7, (log) => log.performedKm);
        final km28 = _sumDouble(last28, (log) => log.performedKm);
        final avgAvailability7 = _avgInt(last7, (log) => log.readiness);
        final avgRpe7 = _avgInt(last7, (log) => log.rpe);
        final avgSoreness7 = _avgInt(last7, (log) => log.soreness);
        final completed28 = last28
            .where((log) => log.completedAsPlanned)
            .length;
        final compliance28 = last28.isEmpty ? 0.0 : completed28 / last28.length;
        final activeDays28 = last28
            .map(
              (log) => DateTime(
                log.date.year,
                log.date.month,
                log.date.day,
              ).toIso8601String(),
            )
            .toSet()
            .length;
        final consistency28 = activeDays28 / 28;

        final weeklyMinutes = _buildWeeklySeries(
          logs: logs,
          weeks: 6,
          pick: (log) => log.performedMinutes.toDouble(),
        );

        final weeklyLoad = _buildWeeklySeries(
          logs: logs,
          weeks: 6,
          pick: (log) => log.performedLoad.toDouble(),
        );

        final weeklyAvailability = _buildWeeklyAverageSeries(
          logs: logs,
          weeks: 6,
          pick: (log) => log.readiness.toDouble(),
        );

        final radarValues = [
          _normalize(minutes28.toDouble(), 900),
          _normalize(load28.toDouble(), 900),
          _normalize(km28, 120),
          consistency28.clamp(0.0, 1.0),
          _normalize(avgAvailability7.toDouble(), 100),
          (1.0 - _normalize(avgSoreness7.toDouble(), 10)).clamp(0.0, 1.0),
        ];

        return _DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cabina de evolución',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _buildCoachStatusLine(
                  avgAvailability7: avgAvailability7,
                  avgSoreness7: avgSoreness7,
                  consistency28: consistency28,
                  load7: load7,
                ),
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: _EvolutionStatCard(
                      title: 'Trabajo 7 días',
                      value: '$minutes7',
                      unit: 'min',
                      icon: Icons.timer,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _EvolutionStatCard(
                      title: 'Exigencia semanal',
                      value: '$load7',
                      unit: 'pts',
                      icon: Icons.bolt,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _EvolutionStatCard(
                      title: 'Km 7 días',
                      value: km7.toStringAsFixed(1),
                      unit: 'km',
                      icon: Icons.route,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _EvolutionStatCard(
                      title: 'Registros 28 días',
                      value: '${last28.length}',
                      unit: 'días',
                      icon: Icons.event_available,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              _EvolutionRadarCard(
                values: radarValues,
                labels: const [
                  'Trabajo',
                  'Carga',
                  'Km',
                  'Constancia',
                  'Disponibilidad',
                  'Recuperación',
                ],
              ),

              const SizedBox(height: 18),

              _EvolutionBar(
                title: 'Constancia últimos 28 días',
                value: consistency28,
                label: '${(consistency28 * 100).round()}%',
                color: Colors.green,
              ),
              _EvolutionBar(
                title: 'Plan cumplido últimos 28 días',
                value: compliance28,
                label: '${(compliance28 * 100).round()}%',
                color: Colors.blue,
              ),
              _EvolutionBar(
                title: 'Disponibilidad últimos 7 días',
                value: _normalize(avgAvailability7.toDouble(), 100),
                label: _availabilityLabel(avgAvailability7),
                color: Colors.teal,
              ),
              _EvolutionBar(
                title: 'Control de fatiga/dolor',
                value: (1.0 - _normalize(avgSoreness7.toDouble(), 10)).clamp(
                  0.0,
                  1.0,
                ),
                label: _fatigueLabel(avgSoreness7),
                color: Colors.amber,
              ),

              const SizedBox(height: 22),

              _WeeklyLineChart(
                title: 'Trabajo semanal',
                values: weeklyMinutes,
                color: Colors.blue,
                unit: 'min',
              ),

              _WeeklyLineChart(
                title: 'Exigencia semanal',
                values: weeklyLoad,
                color: Colors.orange,
                unit: 'pts',
              ),

              _WeeklyLineChart(
                title: 'Disponibilidad semanal',
                values: weeklyAvailability,
                color: Colors.green,
                unit: '%',
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (consistency28 >= 0.5)
                    const _StatusBadge(
                      label: 'Constancia alta',
                      color: Colors.green,
                    ),
                  if (load7 > 350)
                    const _StatusBadge(
                      label: 'Semana exigente',
                      color: Colors.blue,
                    ),
                  if (avgSoreness7 <= 4)
                    const _StatusBadge(
                      label: 'Fatiga controlada',
                      color: Colors.orange,
                    ),
                  if (avgAvailability7 < 65)
                    const _StatusBadge(
                      label: 'Recuperación en observación',
                      color: Colors.amber,
                    ),
                ],
              ),

              const SizedBox(height: 18),

              _EvolutionSummaryBox(
                minutes28: minutes28,
                load28: load28,
                km28: km28,
                avgRpe7: avgRpe7,
                avgAvailability7: avgAvailability7,
                avgSoreness7: avgSoreness7,
                consistency28: consistency28,
              ),
            ],
          ),
        );
      },
    );
  }

  int _sumInt(
    List<DailyAthleteLog> logs,
    int Function(DailyAthleteLog log) pick,
  ) {
    return logs.fold<int>(0, (sum, log) => sum + pick(log));
  }

  double _sumDouble(
    List<DailyAthleteLog> logs,
    double Function(DailyAthleteLog log) pick,
  ) {
    return logs.fold<double>(0, (sum, log) => sum + pick(log));
  }

  double _avgInt(
    List<DailyAthleteLog> logs,
    int Function(DailyAthleteLog log) pick,
  ) {
    if (logs.isEmpty) return 0;
    return logs.fold<double>(0, (sum, log) => sum + pick(log)) / logs.length;
  }

  double _normalize(double value, double max) {
    if (max <= 0) return 0;
    return (value / max).clamp(0.0, 1.0);
  }

  DateTime _startOfWeek(DateTime date) {
    final clean = DateTime(date.year, date.month, date.day);
    return clean.subtract(Duration(days: clean.weekday - 1));
  }

  List<double> _buildWeeklySeries({
    required List<DailyAthleteLog> logs,
    required int weeks,
    required double Function(DailyAthleteLog log) pick,
  }) {
    final now = DateTime.now();
    final currentWeekStart = _startOfWeek(now);

    return List<double>.generate(weeks, (index) {
      final weekStart = currentWeekStart.subtract(
        Duration(days: 7 * (weeks - index - 1)),
      );
      final weekEnd = weekStart.add(const Duration(days: 7));

      return logs
          .where(
            (log) =>
                !log.date.isBefore(weekStart) && log.date.isBefore(weekEnd),
          )
          .fold<double>(0, (sum, log) => sum + pick(log));
    });
  }

  List<double> _buildWeeklyAverageSeries({
    required List<DailyAthleteLog> logs,
    required int weeks,
    required double Function(DailyAthleteLog log) pick,
  }) {
    final now = DateTime.now();
    final currentWeekStart = _startOfWeek(now);

    return List<double>.generate(weeks, (index) {
      final weekStart = currentWeekStart.subtract(
        Duration(days: 7 * (weeks - index - 1)),
      );
      final weekEnd = weekStart.add(const Duration(days: 7));

      final weekLogs = logs
          .where(
            (log) =>
                !log.date.isBefore(weekStart) && log.date.isBefore(weekEnd),
          )
          .toList();

      if (weekLogs.isEmpty) return 0;

      return weekLogs.fold<double>(0, (sum, log) => sum + pick(log)) /
          weekLogs.length;
    });
  }

  String _availabilityLabel(double value) {
    if (value >= 80) return 'Alta';
    if (value >= 65) return 'Buena';
    if (value >= 50) return 'Moderada';
    return 'Baja';
  }

  String _fatigueLabel(double soreness) {
    if (soreness <= 3) return 'Controlada';
    if (soreness <= 6) return 'Moderada';
    return 'Alta';
  }

  String _buildCoachStatusLine({
    required double avgAvailability7,
    required double avgSoreness7,
    required double consistency28,
    required int load7,
  }) {
    if (avgAvailability7 >= 75 && avgSoreness7 <= 4 && consistency28 >= 0.45) {
      return 'Atleta estable: buena base para sostener calidad.';
    }

    if (avgAvailability7 < 60 || avgSoreness7 >= 7) {
      return 'Atleta en observación: conviene controlar recuperación.';
    }

    if (load7 > 450) {
      return 'Semana exigente: vigilar respuesta antes de volver a cargar.';
    }

    return 'Evolución en construcción: más registros harán la lectura más precisa.';
  }

  Widget _buildRecoveryFatigueSection(
    AppLanguage lang,
    AthletePhysiologyProfile? profile,
    AdaptiveResponseMemory? memory,
  ) {
    final recoveryText = _recoveryProfileText(profile);
    final fatigueText = _fatigueSensitivityText(profile);

    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppText.t(
              lang,
              'Recuperación y fatiga',
              'Recovery & Fatigue',
              'Regeneration & Ermüdung',
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Lectura simple para decidir si conviene cargar, mantener o proteger.',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 16),
          _CoachReadingCard(
            title: 'Recuperación',
            value: recoveryText,
            icon: Icons.battery_charging_full,
            color: Colors.green,
            description: _recoveryDescription(profile),
          ),
          _CoachReadingCard(
            title: 'Fatiga acumulada',
            value: fatigueText,
            icon: Icons.monitor_heart,
            color: Colors.orange,
            description: _fatigueDescription(profile),
          ),
          _CoachReadingCard(
            title: 'Disponibilidad general',
            value: _availabilityLabel(profile?.readinessTrend ?? 75),
            icon: Icons.speed,
            color: Colors.blue,
            description: _availabilityDescription(
              profile?.readinessTrend ?? 75,
            ),
          ),
        ],
      ),
    );
  }

  String _recoveryProfileText(AthletePhysiologyProfile? profile) {
    if (profile == null) return 'Sin tendencia';

    switch (profile.recoveryProfile) {
      case RecoveryProfile.fast:
        return 'Rápida';
      case RecoveryProfile.normal:
        return 'Normal';
      case RecoveryProfile.slow:
        return 'Lenta';
    }
  }

  String _fatigueSensitivityText(AthletePhysiologyProfile? profile) {
    if (profile == null) return 'Sin tendencia';

    switch (profile.fatigueSensitivity) {
      case FatigueSensitivity.low:
        return 'Tolera bien';
      case FatigueSensitivity.moderate:
        return 'Moderada';
      case FatigueSensitivity.high:
        return 'Sensible';
    }
  }

  String _recoveryDescription(AthletePhysiologyProfile? profile) {
    if (profile == null) {
      return 'Registra más entrenamientos para construir esta lectura.';
    }

    switch (profile.recoveryProfile) {
      case RecoveryProfile.fast:
        return 'Suele estar listo más rápido después de cargas fuertes.';
      case RecoveryProfile.normal:
        return 'Responde de forma estable a la carga habitual.';
      case RecoveryProfile.slow:
        return 'Necesita más cuidado entre sesiones exigentes.';
    }
  }

  String _fatigueDescription(AthletePhysiologyProfile? profile) {
    if (profile == null) {
      return 'La app necesita más registros para detectar patrones.';
    }

    switch (profile.fatigueSensitivity) {
      case FatigueSensitivity.low:
        return 'Puede sostener semanas densas con buena respuesta.';
      case FatigueSensitivity.moderate:
        return 'Conviene alternar carga y recuperación con equilibrio.';
      case FatigueSensitivity.high:
        return 'Vigilar días consecutivos fuertes y doble sesión.';
    }
  }

  String _availabilityDescription(double value) {
    if (value >= 80) {
      return 'Buen momento para trabajo de calidad si el plan lo permite.';
    }

    if (value >= 65) {
      return 'Puede entrenar bien, cuidando la acumulación de fatiga.';
    }

    if (value >= 50) {
      return 'Mejor controlar la intensidad o ajustar volumen.';
    }

    return 'Señal de cautela: priorizar recuperación y técnica limpia.';
  }

  Widget _buildCapacityEvolutionSection(
    AppLanguage lang,
    AthletePhysiologyProfile? profile,
  ) {
    if (profile == null) return const SizedBox.shrink();

    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppText.t(
              lang,
              'Capacidad de trabajo',
              'Work capacity',
              'Arbeitskapazität',
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Resumen deportivo sin mostrar límites internos del motor.',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 16),
          _CoachReadingCard(
            title: 'Carga semanal',
            value: _workCapacityLabel(profile.maxWeeklyLoad, 1200, 900),
            icon: Icons.calendar_view_week,
            color: Colors.blue,
            description: _workCapacityDescription(profile.maxWeeklyLoad),
          ),
          _CoachReadingCard(
            title: 'Trabajo en patines',
            value: _skatingCapacityLabel(profile.maxSkatingKm),
            icon: Icons.route,
            color: Colors.green,
            description: _skatingCapacityDescription(profile.maxSkatingKm),
          ),
          _CoachReadingCard(
            title: 'Fuerza',
            value: _strengthCapacityLabel(profile.maxGymLoad),
            icon: Icons.fitness_center,
            color: Colors.red,
            description: _strengthCapacityDescription(profile.maxGymLoad),
          ),
        ],
      ),
    );
  }

  String _workCapacityLabel(double value, double high, double medium) {
    if (value >= high) return 'Alta';
    if (value >= medium) return 'Media';
    return 'En construcción';
  }

  String _workCapacityDescription(double value) {
    if (value >= 1200) {
      return 'Puede sostener semanas fuertes si la recuperación acompaña.';
    }

    if (value >= 900) {
      return 'Buena base para progresar con carga controlada.';
    }

    return 'Conviene construir base antes de semanas muy densas.';
  }

  String _skatingCapacityLabel(double km) {
    if (km >= 50) return 'Alta';
    if (km >= 35) return 'Media';
    return 'En construcción';
  }

  String _skatingCapacityDescription(double km) {
    if (km >= 50) {
      return 'Buena capacidad para volumen específico en patines.';
    }

    if (km >= 35) {
      return 'Base útil, con margen para aumentar progresivamente.';
    }

    return 'Priorizar regularidad antes de subir mucho el volumen.';
  }

  String _strengthCapacityLabel(double gymLoad) {
    if (gymLoad >= 20000) return 'Fuerte';
    if (gymLoad >= 14000) return 'Media';
    return 'En desarrollo';
  }

  String _strengthCapacityDescription(double gymLoad) {
    if (gymLoad >= 20000) {
      return 'Buen soporte de fuerza para transferir a velocidad.';
    }

    if (gymLoad >= 14000) {
      return 'Base de fuerza útil, todavía con margen de desarrollo.';
    }

    return 'Conviene construir fuerza general y específica progresivamente.';
  }

  Widget _buildCompetitiveProjectionSection(
    AppLanguage lang,
    AthletePhysiologyProfile? profile,
  ) {
    if (profile == null) return const SizedBox.shrink();

    final recommendationText = _competitiveRecommendation(profile);

    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, size: 32, color: Colors.amber),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppText.t(
                    lang,
                    'Perfil competitivo',
                    'Competitive profile',
                    'Wettkampfprofil',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Fortalezas actuales del atleta y dirección de desarrollo.',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 16),
          _DevelopmentBar(
            title: AppText.t(lang, 'Velocidad', 'Speed', 'Geschwindigkeit'),
            value: profile.speedDevelopmentLevel,
            color: Colors.blue,
          ),
          _DevelopmentBar(
            title: AppText.t(lang, 'Fuerza', 'Strength', 'Kraft'),
            value: profile.strengthDevelopmentLevel,
            color: Colors.red,
          ),
          _DevelopmentBar(
            title: AppText.t(lang, 'Técnica', 'Technique', 'Technik'),
            value: profile.technicalDevelopmentLevel,
            color: Colors.green,
          ),
          _DevelopmentBar(
            title: AppText.t(
              lang,
              'Resistencia específica',
              'Specific endurance',
              'Spezifische Ausdauer',
            ),
            value: profile.enduranceDevelopmentLevel,
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.25)),
            ),
            child: Text(
              recommendationText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _competitiveRecommendation(AthletePhysiologyProfile profile) {
    final recommendations = <String>[];

    if (profile.strengthDevelopmentLevel < 60) {
      recommendations.add('priorizar fuerza');
    }

    if (profile.speedDevelopmentLevel < 60) {
      recommendations.add('mejorar velocidad');
    }

    if (profile.enduranceDevelopmentLevel < 60) {
      recommendations.add('construir resistencia específica');
    }

    if (profile.technicalDevelopmentLevel < 70) {
      recommendations.add('pulir técnica');
    }

    if (recommendations.isEmpty) {
      return 'Perfil equilibrado. Mantener calidad y progresar con control.';
    }

    return 'Enfoque sugerido: ${recommendations.take(2).join(', ')}.';
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Evolución del atleta',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Una lectura simple para decidir mejor: carga, recuperación, constancia y progreso.',
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}

class _DarkCard extends StatelessWidget {
  final Widget child;

  const _DarkCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _LearningTrendsDashboardScreenState.cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String text;

  const _InfoCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white54),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white60)),
          ),
        ],
      ),
    );
  }
}

class _CoachReadingCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String description;

  const _CoachReadingCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DevelopmentBar extends StatelessWidget {
  final String title;
  final double value;
  final Color color;

  const _DevelopmentBar({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = (value / 100).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              Text(
                _developmentLabel(value),
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: safeValue,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            color: color,
            backgroundColor: color.withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  String _developmentLabel(double value) {
    if (value >= 80) return 'Alta';
    if (value >= 60) return 'Buena';
    if (value >= 40) return 'Media';
    return 'En desarrollo';
  }
}

class _EvolutionStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _EvolutionStatCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EvolutionBar extends StatelessWidget {
  final String title;
  final double value;
  final String label;
  final Color color;

  const _EvolutionBar({
    required this.title,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: safeValue,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            color: color,
            backgroundColor: color.withOpacity(0.18),
          ),
        ],
      ),
    );
  }
}

class _EvolutionRadarCard extends StatelessWidget {
  final List<double> values;
  final List<String> labels;

  const _EvolutionRadarCard({required this.values, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: CustomPaint(
        painter: _RadarPainter(values: values, labels: labels),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;

  _RadarPainter({required this.values, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || labels.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.32;

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final fillPaint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.28)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final axisPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 1;

    for (var level = 1; level <= 4; level++) {
      final path = Path();
      final levelRadius = radius * level / 4;

      for (var i = 0; i < values.length; i++) {
        final angle = (-90 + i * 360 / values.length) * math.pi / 180;
        final point = Offset(
          center.dx + levelRadius * math.cos(angle),
          center.dy + levelRadius * math.sin(angle),
        );

        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }

      path.close();
      canvas.drawPath(path, gridPaint);
    }

    final valuePath = Path();

    for (var i = 0; i < values.length; i++) {
      final angle = (-90 + i * 360 / values.length) * math.pi / 180;
      final axisEnd = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      canvas.drawLine(center, axisEnd, axisPaint);

      final valueRadius = radius * values[i].clamp(0.0, 1.0);
      final point = Offset(
        center.dx + valueRadius * math.cos(angle),
        center.dy + valueRadius * math.sin(angle),
      );

      if (i == 0) {
        valuePath.moveTo(point.dx, point.dy);
      } else {
        valuePath.lineTo(point.dx, point.dy);
      }

      final labelPoint = Offset(
        center.dx + (radius + 28) * math.cos(angle),
        center.dy + (radius + 28) * math.sin(angle),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 90);

      textPainter.paint(
        canvas,
        Offset(
          labelPoint.dx - textPainter.width / 2,
          labelPoint.dy - textPainter.height / 2,
        ),
      );
    }

    valuePath.close();
    canvas.drawPath(valuePath, fillPaint);
    canvas.drawPath(valuePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.labels != labels;
  }
}

class _EvolutionSummaryBox extends StatelessWidget {
  final int minutes28;
  final int load28;
  final double km28;
  final double avgRpe7;
  final double avgAvailability7;
  final double avgSoreness7;
  final double consistency28;

  const _EvolutionSummaryBox({
    required this.minutes28,
    required this.load28,
    required this.km28,
    required this.avgRpe7,
    required this.avgAvailability7,
    required this.avgSoreness7,
    required this.consistency28,
  });

  @override
  Widget build(BuildContext context) {
    String status;

    if (avgAvailability7 >= 75 && avgSoreness7 <= 4 && consistency28 >= 0.45) {
      status = 'Evolución estable con buena disponibilidad para progresar.';
    } else if (avgAvailability7 < 60 || avgSoreness7 >= 7) {
      status =
          'Hay señales de fatiga. Conviene vigilar recuperación antes de cargar fuerte.';
    } else {
      status =
          'Evolución en construcción. Más registros harán la lectura más precisa.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lectura general',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          Text(status, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          Text(
            'Últimos 28 días: $minutes28 min · $load28 pts · ${km28.toStringAsFixed(1)} km.',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          Text(
            'Últimos 7 días: esfuerzo ${avgRpe7.toStringAsFixed(1)} · disponibilidad ${avgAvailability7.toStringAsFixed(0)} · dolor ${avgSoreness7.toStringAsFixed(1)}.',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SportsMetricCard extends StatelessWidget {
  final SportsMetricInterpretation interpretation;

  const _SportsMetricCard({required this.interpretation});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _LearningTrendsDashboardScreenState.cardBg,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              interpretation.severityIcon,
              color: interpretation.severityColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    interpretation.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    interpretation.status,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: interpretation.severityColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    interpretation.explanation,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyLineChart extends StatelessWidget {
  final String title;
  final List<double> values;
  final Color color;
  final String unit;

  const _WeeklyLineChart({
    required this.title,
    required this.values,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final latestValue = values.isEmpty ? 0.0 : values.last;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                '${latestValue.toStringAsFixed(latestValue % 1 == 0 ? 0 : 1)} $unit',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: CustomPaint(
              painter: _LineChartPainter(values: values, color: color),
              child: Container(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              values.length,
              (index) => Text(
                'S${index + 1}',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _LineChartPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.12)
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1;

    for (int i = 0; i < 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? 0.0
          : (i / (values.length - 1)) * size.width;
      final normalized = values[i] / safeMax;
      final y = size.height - (normalized * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 4, Paint()..color = color);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
