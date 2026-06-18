import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_language.dart';
import 'app_text.dart';
import 'athlete_program_service.dart';
import 'athlete_context_service.dart';
import 'daily_ai_training_screen.dart';
import 'auto_adjust_screen.dart';
import 'training_library/training_library_models.dart';
import 'physiology_status_screen.dart';
import 'training_system/microcycle/weekly_microcycle_builder.dart';
import 'training_log_screen.dart';
import 'learning_trends_dashboard_screen.dart';
import 'training_log_alerts_screen.dart';
import 'wearable_integration_service.dart';
import 'athlete_weight_history_service.dart';

class AthleteDetailHubScreen extends StatefulWidget {
  final AthleteProgramProfile athlete;

  const AthleteDetailHubScreen({super.key, required this.athlete});

  @override
  State<AthleteDetailHubScreen> createState() => _AthleteDetailHubScreenState();
}

class _AthleteDetailHubScreenState extends State<AthleteDetailHubScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final athleteProgramService = context.read<AthleteProgramService>();
      final athleteContextService = context.read<AthleteContextService>();
      final wearableService = context.read<WearableIntegrationService>();

      athleteProgramService.selectAthlete(widget.athlete.id);
      athleteContextService.setActiveAthlete(widget.athlete);
      wearableService.setActiveAthlete(widget.athlete.id);
    });
  }

  String typeText(AppLanguage lang, AthleteProgramType type) {
    switch (type) {
      case AthleteProgramType.sprinter:
        return AppText.t(lang, 'Velocista', 'Sprinter', 'Sprinter');
      case AthleteProgramType.endurance:
        return AppText.t(lang, 'Fondista', 'Endurance', 'Ausdauer');
      case AthleteProgramType.mixed:
        return AppText.t(lang, 'Mixto', 'Mixed', 'Gemischt');
    }
  }

  String levelText(AppLanguage lang, AthleteProgramLevel level) {
    switch (level) {
      case AthleteProgramLevel.novice:
        return AppText.t(lang, 'Novato', 'Beginner', 'Anfänger');
      case AthleteProgramLevel.competitive:
        return AppText.t(lang, 'Competitivo', 'Competitive', 'Wettkampf');
      case AthleteProgramLevel.elite:
        return AppText.t(lang, 'Elite', 'Elite', 'Elite');
    }
  }

  void openAddCompetition() {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider<AthleteProgramService>.value(
        value: AthleteProgramService.instance,
        child: _CreateCompetitionDialog(athlete: widget.athlete),
      ),
    );
  }

  void generateSeason() {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider<AthleteProgramService>.value(
        value: AthleteProgramService.instance,
        child: _GenerateSeasonDialog(athlete: widget.athlete),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageNotifier>().current;

    return DefaultTabController(
      length: 8,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.athlete.name),
          actions: [
            IconButton(
              tooltip: AppText.t(
                lang,
                'Agregar competencia',
                'Add competition',
                'Wettkampf hinzufügen',
              ),
              onPressed: openAddCompetition,
              icon: const Icon(Icons.emoji_events),
            ),
            IconButton(
              tooltip: AppText.t(
                lang,
                'Generar temporada',
                'Generate season',
                'Saison erstellen',
              ),
              onPressed: generateSeason,
              icon: const Icon(Icons.auto_awesome),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: AppText.t(lang, 'Resumen', 'Summary', 'Übersicht')),
              Tab(
                text: AppText.t(
                  lang,
                  'Plan de hoy',
                  "Today's plan",
                  'Heutiger Plan',
                ),
              ),
              Tab(
                text: AppText.t(
                  lang,
                  'Estado corporal',
                  'Body status',
                  'Körperstatus',
                ),
              ),
              Tab(
                text: AppText.t(lang, 'Evolución', 'Evolution', 'Entwicklung'),
              ),
              Tab(
                icon: const Icon(Icons.fact_check),
                text: AppText.t(
                  lang,
                  '¿Cómo fue?',
                  'How was it?',
                  'Wie war es?',
                ),
              ),
              Tab(text: AppText.t(lang, 'Avisos', 'Warnings', 'Hinweise')),
              Tab(
                text: AppText.t(
                  lang,
                  'Entrenamientos',
                  'Training history',
                  'Trainingsverlauf',
                ),
              ),
              Tab(text: AppText.t(lang, 'Perfil', 'Profile', 'Profil')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _SummaryTab(
              athlete: widget.athlete,
              type: typeText(lang, widget.athlete.type),
              level: levelText(lang, widget.athlete.level),
            ),
            const DailyAITrainingScreen(),
            const PhysiologyStatusScreen(),
            const LearningTrendsDashboardScreen(),
            const TrainingLogScreen(),
            const TrainingLogAlertsScreen(),
            _HistoryTab(athlete: widget.athlete),
            _ProfileTab(
              athlete: widget.athlete,
              type: typeText(lang, widget.athlete.type),
              level: levelText(lang, widget.athlete.level),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

String _formatDateRange(DateTime start, DateTime end) {
  if (start.year == end.year &&
      start.month == end.month &&
      start.day == end.day) {
    return _formatDate(start);
  }

  return '${_formatDate(start)} - ${_formatDate(end)}';
}

String _priorityText(CompetitionPriority priority) {
  switch (priority) {
    case CompetitionPriority.preparation:
      return 'Preparación';
    case CompetitionPriority.important:
      return 'Importante';
    case CompetitionPriority.main:
      return 'Principal';
  }
}

class _SummaryTab extends StatelessWidget {
  final AthleteProgramProfile athlete;
  final String type;
  final String level;

  const _SummaryTab({
    required this.athlete,
    required this.type,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final athleteContext = context.watch<AthleteContextService>();
    final dailyState = athleteContext.currentDailyState;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: const Color(0xFF111827),
          surfaceTintColor: Colors.transparent,
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.speed)),
            title: Text(
              athlete.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            subtitle: Text(
              '${athlete.category} · ${athlete.age} años · $type · $level',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ),
        _MetricCard(
          title: 'Disponibilidad',
          value: dailyState != null
              ? '${dailyState.readiness}'
              : athleteContext.activeReadinessScore <= 0
              ? 'Sin datos'
              : '${athleteContext.activeReadinessScore}',
          icon: Icons.favorite,
        ),
        _MetricCard(
          title: 'Fatiga',
          value: dailyState != null
              ? dailyState.fatigueStatus.toUpperCase()
              : athleteContext.activeFatigueStatus.toUpperCase(),
          icon: Icons.monitor_heart,
        ),
        _MetricCard(
          title: 'Competencias',
          value: '${athlete.competitions.length}',
          icon: Icons.calendar_month,
        ),
        _MetricCard(
          title: 'Semanas planificadas',
          value: '${athlete.seasonPlan.length}',
          icon: Icons.view_week,
        ),
        const SizedBox(height: 12),
        _InfoBox(
          color: Colors.blue,
          icon: Icons.info_outline,
          text:
              'Resumen = vista rápida del atleta. El estado corporal vive en Estado corporal, '
              'la evolución vive en Evolución y el entrenamiento de hoy vive en Plan de hoy.',
        ),
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final AthleteProgramProfile athlete;

  const _HistoryTab({required this.athlete});

  @override
  Widget build(BuildContext context) {
    final athleteContext = context.watch<AthleteContextService>();
    final history = athleteContext.activeHistory;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle(
          icon: Icons.history,
          title: 'Entrenamientos pasados',
          subtitle:
              'Aquí viven los entrenamientos registrados y la temporada planificada.',
        ),
        const SizedBox(height: 12),
        if (history.isEmpty)
          const Card(
            color: Color(0xFF111827),
            surfaceTintColor: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No hay entrenamientos registrados todavía.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          )
        else
          ...history.map((entry) {
            return Card(
              color: const Color(0xFF111827),
              surfaceTintColor: Colors.transparent,
              child: ListTile(
                leading: const Icon(Icons.history, color: Colors.white70),
                title: Text(
                  _formatDate(entry.date),
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${entry.skateKm} km · ${entry.minutes} min',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            );
          }),
        const SizedBox(height: 18),
        const _SectionTitle(
          icon: Icons.view_week,
          title: 'Temporada planificada',
          subtitle:
              'Vista de semanas, sesiones y competencias objetivo del atleta.',
        ),
        const SizedBox(height: 12),
        if (athlete.seasonPlan.isEmpty)
          const Card(
            color: Color(0xFF111827),
            surfaceTintColor: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Aún no hay temporada generada.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          )
        else
          ...athlete.seasonPlan.map((week) => _WeekCard(week: week)),
      ],
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final AthleteProgramProfile athlete;
  final String type;
  final String level;

  const _ProfileTab({
    required this.athlete,
    required this.type,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AthleteProgramService>();

    final updatedAthlete = service.athletes.firstWhere(
      (item) => item.id == athlete.id,
      orElse: () => athlete,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle(
          icon: Icons.person,
          title: 'Datos del atleta',
          subtitle:
              'Información estructural del deportista y calendario competitivo.',
        ),
        const SizedBox(height: 12),
        Card(
          color: const Color(0xFF111827),
          surfaceTintColor: Colors.transparent,
          child: Column(
            children: [
              _ProfileTile(
                icon: Icons.badge,
                title: 'Nombre',
                value: updatedAthlete.name,
              ),
              const Divider(height: 1),
              _ProfileTile(
                icon: Icons.category,
                title: 'Categoría',
                value: updatedAthlete.category,
              ),
              const Divider(height: 1),
              _ProfileTile(
                icon: Icons.cake,
                title: 'Edad',
                value: '${updatedAthlete.age} años',
              ),
              const Divider(height: 1),
              _ProfileTile(
                icon: Icons.speed,
                title: 'Tipo de atleta',
                value: type,
              ),
              const Divider(height: 1),
              _ProfileTile(
                icon: Icons.workspace_premium,
                title: 'Nivel',
                value: level,
              ),
              const Divider(height: 1),
              _ProfileTile(
                icon: Icons.monitor_weight,
                title: 'Peso',
                value: '${updatedAthlete.weightKg.toStringAsFixed(1)} kg',
              ),
              const Divider(height: 1),
              _WeightHistoryCard(athlete: updatedAthlete),
              const Divider(height: 1),
              _ProfileTile(
                icon: Icons.height,
                title: 'Estatura',
                value: updatedAthlete.heightCm > 0
                    ? '${updatedAthlete.heightCm.toStringAsFixed(1)} cm'
                    : 'No registrada',
              ),
              const Divider(height: 1),
              _ProfileTile(
                icon: Icons.email,
                title: 'Correo',
                value: updatedAthlete.email.isEmpty
                    ? 'No registrado'
                    : updatedAthlete.email,
              ),
              const Divider(height: 1),
              _ProfileTile(
                icon: Icons.phone,
                title: 'WhatsApp',
                value: updatedAthlete.whatsapp.isEmpty
                    ? 'No registrado'
                    : updatedAthlete.whatsapp,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _SectionTitle(
          icon: Icons.emoji_events,
          title: 'Calendario de competencias',
          subtitle:
              'Competencias usadas para orientar temporada, descarga y semanas clave.',
        ),
        const SizedBox(height: 12),
        if (updatedAthlete.competitions.isEmpty)
          const Card(
            color: Color(0xFF111827),
            surfaceTintColor: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No hay competencias registradas.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          )
        else
          ...updatedAthlete.competitions.map((competition) {
            return Card(
              color: const Color(0xFF111827),
              surfaceTintColor: Colors.transparent,
              child: ListTile(
                leading: const Icon(Icons.emoji_events, color: Colors.white70),
                title: Text(
                  competition.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  '${competition.location} · ${_formatDateRange(competition.date, competition.endDate)}\n'
                  '${_priorityText(competition.priority)} · ${competition.events.join(', ')}',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    service.deleteCompetition(
                      athleteId: updatedAthlete.id,
                      competitionId: competition.id,
                    );
                  },
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _WeightHistoryCard extends StatefulWidget {
  final AthleteProgramProfile athlete;

  const _WeightHistoryCard({required this.athlete});

  @override
  State<_WeightHistoryCard> createState() => _WeightHistoryCardState();
}

class _WeightHistoryCardState extends State<_WeightHistoryCard> {
  List<WeightHistoryEntry> entries = [];
  AthleteWeightSummary? summary;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadWeightHistory();
  }

  Future<void> loadWeightHistory() async {
    final loadedEntries =
        await AthleteWeightHistoryService.getEntriesForAthlete(
          widget.athlete.id,
        );

    final loadedSummary = await AthleteWeightHistoryService.getSummary(
      widget.athlete.id,
    );

    if (!mounted) return;

    setState(() {
      entries = loadedEntries;
      summary = loadedSummary;
      loading = false;
    });
  }

  Future<void> registerWeight() async {
    final controller = TextEditingController(
      text: widget.athlete.weightKg > 0
          ? widget.athlete.weightKg.toStringAsFixed(1)
          : '',
    );

    final newWeight = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Registrar peso'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Peso',
              suffixText: 'kg',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(
                  controller.text.trim().replaceAll(',', '.'),
                );

                if (value == null || value <= 0) return;

                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (newWeight == null) return;

    await AthleteWeightHistoryService.addEntry(
      athleteId: widget.athlete.id,
      date: DateTime.now(),
      weightKg: newWeight,
    );

    await AthleteProgramService.instance.updateAthleteWeight(
      athleteId: widget.athlete.id,
      weightKg: newWeight,
    );

    if (!mounted) return;

    await loadWeightHistory();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Peso registrado: ${newWeight.toStringAsFixed(1)} kg'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final latest = summary?.latestEntry;
    final change = summary?.changeLast4WeeksKg;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Historial de peso',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: registerWeight,
                icon: const Icon(Icons.add),
                label: const Text('Registrar peso'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            const Text(
              'Cargando historial...',
              style: TextStyle(color: Colors.white70),
            )
          else if (entries.isEmpty)
            const Text(
              'Sin registros todavía. Registra el primer peso semanal.',
              style: TextStyle(color: Colors.white70),
            )
          else ...[
            Text(
              latest == null
                  ? 'Última medición: no disponible'
                  : 'Última medición: ${latest.weightKg.toStringAsFixed(1)} kg · ${_formatDate(latest.date)}',
              style: const TextStyle(color: Colors.white70),
            ),
            if (change != null) ...[
              const SizedBox(height: 6),
              Text(
                'Cambio últimas 4 semanas: '
                '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} kg',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
            if (summary?.hasRapidChange == true &&
                summary?.rapidChangeMessage != null) ...[
              const SizedBox(height: 10),
              _InfoBox(
                color: Colors.orange,
                icon: Icons.warning_amber,
                text: summary!.rapidChangeMessage!,
              ),
            ],
            const SizedBox(height: 12),
            ...entries
                .take(6)
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.monitor_weight_outlined,
                          color: Colors.white54,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatDate(entry.date),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                        Text(
                          '${entry.weightKg.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white70)),
      trailing: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  final AthleteTrainingWeek week;

  const _WeekCard({required this.week});

  bool _isToday(WeeklyMicrocycleDay day, DateTime weekStart) {
    final today = DateTime.now();
    final dayDate = weekStart.add(Duration(days: day.dayIndex));

    return dayDate.year == today.year &&
        dayDate.month == today.month &&
        dayDate.day == today.day;
  }

  @override
  Widget build(BuildContext context) {
    final intelligentPlan = week.intelligentPlan;

    return Card(
      color: const Color(0xFF111827),
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WeekHeader(week: week),
            const SizedBox(height: 12),
            Row(
              children: [
                _SmallMetric(
                  icon: Icons.speed,
                  text: '${week.skateDays} patines',
                ),
                const SizedBox(width: 8),
                _SmallMetric(
                  icon: Icons.fitness_center,
                  text: '${week.gymDays} gym',
                ),
                const SizedBox(width: 8),
                _SmallMetric(
                  icon: Icons.spa,
                  text: '${week.recoveryDays} recuperación',
                ),
              ],
            ),
            if (week.taperWeek) ...[
              const SizedBox(height: 12),
              _InfoBox(
                color: Colors.orange,
                icon: Icons.emoji_events,
                text:
                    'Semana de descarga competitiva: reducir fatiga y conservar calidad.',
              ),
            ],
            if (week.postCompetitionDeload) ...[
              const SizedBox(height: 12),
              _InfoBox(
                color: Colors.blue,
                icon: Icons.hotel,
                text: 'Semana de recuperación después de competencia.',
              ),
            ],
            if (week.targetCompetition != null) ...[
              const SizedBox(height: 12),
              _CompetitionBox(competition: week.targetCompetition!),
            ],
            if (intelligentPlan != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Plan de trabajo semanal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              ...intelligentPlan.days.map((day) {
                final isToday = _isToday(day, week.startDate);

                return Card(
                  color: isToday
                      ? const Color(0xFF064E3B)
                      : const Color(0xFF1E293B),
                  surfaceTintColor: Colors.transparent,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ExpansionTile(
                    initiallyExpanded: isToday,
                    iconColor: Colors.white70,
                    collapsedIconColor: Colors.white70,
                    leading: CircleAvatar(
                      backgroundColor: isToday
                          ? Colors.green.withOpacity(0.20)
                          : Colors.blue.withOpacity(0.20),
                      child: Text(
                        '${day.dayIndex + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            day.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (isToday)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'HOY',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      '${day.sessions.length} sesión(es) programada(s)',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    children: [
                      ...day.sessions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final session = entry.value;

                        return _SessionWorkCard(
                          sessionNumber: index + 1,
                          session: session,
                        );
                      }),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _WeekHeader extends StatelessWidget {
  final AthleteTrainingWeek week;

  const _WeekHeader({required this.week});

  @override
  Widget build(BuildContext context) {
    final Color markerColor = week.taperWeek
        ? Colors.orange
        : week.postCompetitionDeload
        ? Colors.blue
        : Colors.green;

    return Row(
      children: [
        CircleAvatar(
          backgroundColor: markerColor.withOpacity(0.18),
          child: Text(
            '${week.weekNumber}',
            style: TextStyle(fontWeight: FontWeight.bold, color: markerColor),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                week.phaseEs,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(week.goalEs, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 4),
              Text(
                '${_formatDate(week.startDate)} - ${_formatDate(week.endDate)}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SessionWorkCard extends StatelessWidget {
  final int sessionNumber;
  final TrainingSessionTemplate session;

  const _SessionWorkCard({required this.sessionNumber, required this.session});

  @override
  Widget build(BuildContext context) {
    final color = _sessionColor(session);
    final highAlert =
        session.intensity == TrainingSessionIntensity.high ||
        session.intensity == TrainingSessionIntensity.maximal;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: color.withOpacity(0.16),
                child: Icon(_sessionIcon(session), color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sesión $sessionNumber · ${_sessionTypeText(session)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (highAlert)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ALTA',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            session.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            session.objective,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70),
          ),
          if (session.mainSet.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Trabajo principal',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            ...session.mainSet
                .take(3)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      '• $item',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 8),
          Text(
            'Intensidad: ${_intensityText(session.intensity)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Color _sessionColor(TrainingSessionTemplate session) {
    if (session.recoverySession) return Colors.green;
    if (session.gymSession) return Colors.purple;
    if (session.cyclingSession) return Colors.teal;

    switch (session.category) {
      case TrainingLibraryCategory.speed:
      case TrainingLibraryCategory.acceleration:
      case TrainingLibraryCategory.maxVelocity:
        return Colors.blue;
      case TrainingLibraryCategory.lactate:
        return Colors.deepOrange;
      case TrainingLibraryCategory.endurance:
      case TrainingLibraryCategory.tempo:
        return Colors.teal;
      case TrainingLibraryCategory.tactical:
        return Colors.indigo;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _sessionIcon(TrainingSessionTemplate session) {
    if (session.gymSession) return Icons.fitness_center;
    if (session.cyclingSession) return Icons.directions_bike;
    if (session.recoverySession) return Icons.spa;

    switch (session.category) {
      case TrainingLibraryCategory.speed:
      case TrainingLibraryCategory.acceleration:
      case TrainingLibraryCategory.maxVelocity:
        return Icons.bolt;
      case TrainingLibraryCategory.lactate:
        return Icons.local_fire_department;
      case TrainingLibraryCategory.endurance:
      case TrainingLibraryCategory.tempo:
        return Icons.route;
      case TrainingLibraryCategory.tactical:
        return Icons.groups;
      default:
        return Icons.speed;
    }
  }

  String _sessionTypeText(TrainingSessionTemplate session) {
    if (session.gymSession) return 'Gimnasio';
    if (session.cyclingSession) return 'Bicicleta';
    if (session.recoverySession) return 'Recuperación';

    switch (session.category) {
      case TrainingLibraryCategory.speed:
      case TrainingLibraryCategory.acceleration:
      case TrainingLibraryCategory.maxVelocity:
        return 'Patines velocidad';
      case TrainingLibraryCategory.lactate:
        return 'Lactato';
      case TrainingLibraryCategory.endurance:
        return 'Fondo';
      case TrainingLibraryCategory.tempo:
        return 'Tempo';
      case TrainingLibraryCategory.tactical:
        return 'Táctico';
      case TrainingLibraryCategory.technical:
        return 'Técnica';
      case TrainingLibraryCategory.core:
        return 'Core';
      case TrainingLibraryCategory.mobility:
        return 'Movilidad';
      default:
        return 'Patines';
    }
  }

  String _intensityText(TrainingSessionIntensity intensity) {
    switch (intensity) {
      case TrainingSessionIntensity.recovery:
        return 'Recuperación';
      case TrainingSessionIntensity.low:
        return 'Baja';
      case TrainingSessionIntensity.moderate:
        return 'Moderada';
      case TrainingSessionIntensity.high:
        return 'Alta';
      case TrainingSessionIntensity.maximal:
        return 'Máxima';
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(child: Icon(icon)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF111827),
      surfaceTintColor: Colors.transparent,
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(color: Colors.white70)),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _SmallMetric extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SmallMetric({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: Colors.white70),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _InfoBox({required this.color, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}

class _CompetitionBox extends StatelessWidget {
  final AthleteCompetition competition;

  const _CompetitionBox({required this.competition});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3F1111),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  competition.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${competition.location} · ${_formatDateRange(competition.date, competition.endDate)}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateCompetitionDialog extends StatefulWidget {
  final AthleteProgramProfile athlete;

  const _CreateCompetitionDialog({required this.athlete});

  @override
  State<_CreateCompetitionDialog> createState() =>
      _CreateCompetitionDialogState();
}

class _CreateCompetitionDialogState extends State<_CreateCompetitionDialog> {
  final nameController = TextEditingController();
  final locationController = TextEditingController();
  final eventsController = TextEditingController(text: '500m, 1000m');

  DateTime startDate = DateTime.now().add(const Duration(days: 60));
  DateTime endDate = DateTime.now().add(const Duration(days: 60));
  CompetitionPriority priority = CompetitionPriority.main;

  bool saving = false;

  @override
  void dispose() {
    nameController.dispose();
    locationController.dispose();
    eventsController.dispose();
    super.dispose();
  }

  Future<void> pickStartDate() async {
    final result = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 1200)),
      initialDate: startDate,
      helpText: 'Fecha de inicio',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (result == null) return;

    setState(() {
      startDate = result;
      if (endDate.isBefore(startDate)) {
        endDate = startDate;
      }
    });
  }

  Future<void> pickEndDate() async {
    final result = await showDatePicker(
      context: context,
      firstDate: startDate,
      lastDate: DateTime.now().add(const Duration(days: 1200)),
      initialDate: endDate.isBefore(startDate) ? startDate : endDate,
      helpText: 'Fecha de finalización',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (result == null) return;

    setState(() {
      endDate = result;
    });
  }

  Future<void> saveCompetition() async {
    if (saving) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final name = nameController.text.trim();
    final location = locationController.text.trim();

    if (name.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Escribe el nombre de la competencia.')),
      );
      return;
    }

    if (location.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Escribe el lugar de la competencia.')),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      final events = eventsController.text
          .split(',')
          .map((event) => event.trim())
          .where((event) => event.isNotEmpty)
          .toList();

      await context.read<AthleteProgramService>().addCompetition(
        athleteId: widget.athlete.id,
        competition: AthleteCompetition(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          date: startDate,
          endDate: endDate,
          location: location,
          priority: priority,
          events: events,
        ),
      );

      if (!mounted) return;

      navigator.pop();

      messenger.showSnackBar(
        SnackBar(content: Text('Competencia $name guardada.')),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        saving = false;
      });

      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo guardar la competencia: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar competencia'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                enabled: !saving,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                enabled: !saving,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Lugar'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: eventsController,
                enabled: !saving,
                decoration: const InputDecoration(
                  labelText: 'Pruebas',
                  hintText: '500m, 1000m, eliminación',
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _DateFieldButton(
                      label: 'Desde',
                      value: _formatDate(startDate),
                      onTap: saving ? null : pickStartDate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DateFieldButton(
                      label: 'Hasta',
                      value: _formatDate(endDate),
                      onTap: saving ? null : pickEndDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CompetitionPriority>(
                value: priority,
                decoration: const InputDecoration(
                  labelText: 'Prioridad',
                  border: OutlineInputBorder(),
                ),
                items: CompetitionPriority.values.map((value) {
                  return DropdownMenuItem(
                    value: value,
                    child: Text(_priorityText(value)),
                  );
                }).toList(),
                onChanged: saving
                    ? null
                    : (value) {
                        if (value == null) return;

                        setState(() {
                          priority = value;
                        });
                      },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: saving ? null : saveCompetition,
          icon: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(saving ? 'Guardando' : 'Guardar'),
        ),
      ],
    );
  }
}

class _DateFieldButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _DateFieldButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_month),
        ).copyWith(labelText: label),
        child: Text(value, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _GenerateSeasonDialog extends StatefulWidget {
  final AthleteProgramProfile athlete;

  const _GenerateSeasonDialog({required this.athlete});

  @override
  State<_GenerateSeasonDialog> createState() => _GenerateSeasonDialogState();
}

class _GenerateSeasonDialogState extends State<_GenerateSeasonDialog> {
  DateTime startDate = DateTime.now();
  int weeks = 16;
  AutoPhysiologyStatus fatigue = AutoPhysiologyStatus.green;

  Future<void> pickStartDate() async {
    final result = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 900)),
      initialDate: startDate,
      helpText: 'Inicio de temporada',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (result == null) return;

    setState(() {
      startDate = result;
    });
  }

  String _fatigueText(AutoPhysiologyStatus value) {
    switch (value) {
      case AutoPhysiologyStatus.green:
        return 'Verde';
      case AutoPhysiologyStatus.yellow:
        return 'Amarillo';
      case AutoPhysiologyStatus.orange:
        return 'Naranja';
      case AutoPhysiologyStatus.red:
        return 'Rojo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<AthleteProgramService>();

    return AlertDialog(
      title: const Text('Generar temporada'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DateFieldButton(
                label: 'Inicio',
                value: _formatDate(startDate),
                onTap: pickStartDate,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: weeks,
                decoration: const InputDecoration(
                  labelText: 'Duración',
                  border: OutlineInputBorder(),
                ),
                items: const [8, 12, 16, 20, 24, 32, 40, 52]
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text('$value semanas'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    weeks = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AutoPhysiologyStatus>(
                value: fatigue,
                decoration: const InputDecoration(
                  labelText: 'Fatiga inicial',
                  border: OutlineInputBorder(),
                ),
                items: AutoPhysiologyStatus.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_fatigueText(value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    fatigue = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            service.generateSeasonForAthlete(
              athleteId: widget.athlete.id,
              startDate: startDate,
              totalWeeks: weeks,
              fatigueStatus: fatigue,
            );

            Navigator.pop(context);
          },
          child: const Text('Generar'),
        ),
      ],
    );
  }
}
