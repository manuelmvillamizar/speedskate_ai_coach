// lib/training_log_alerts_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:speedskate_ai_coach/athlete_context_service.dart';
import 'package:speedskate_ai_coach/training_log_history_service.dart';
import 'package:speedskate_ai_coach/daily_athlete_log.dart';

class TrainingLogAlertsScreen extends StatefulWidget {
  const TrainingLogAlertsScreen({super.key});

  @override
  State<TrainingLogAlertsScreen> createState() =>
      _TrainingLogAlertsScreenState();
}

class _TrainingLogAlertsScreenState extends State<TrainingLogAlertsScreen> {
  List<TrainingAlert> _alerts = [];
  bool _loading = true;

  static const Color _cardColor = Color(0xFF111827);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final athleteId = context.read<AthleteContextService>().activeAthleteId;

    if (athleteId == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);

    final alerts = await TrainingLogHistoryService.generateAlerts(athleteId);

    if (!mounted) return;

    setState(() {
      _alerts = alerts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final athlete = context.watch<AthleteContextService>().activeAthlete;

    if (athlete == null) {
      return const Center(
        child: Text(
          'No hay atleta activo.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Avisos - ${athlete.name}'),
        actions: [
          IconButton(
            tooltip: 'Actualizar avisos',
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const _HeaderCard(),

                  const SizedBox(height: 16),

                  if (_alerts.isNotEmpty) ...[
                    const _SectionTitle(
                      title: 'Avisos que requieren atención',
                      subtitle:
                          'Señales detectadas desde los registros reales del atleta.',
                    ),
                    const SizedBox(height: 8),
                    ..._alerts.map((alert) => _AlertCard(alert: alert)),
                  ] else ...[
                    const _NoAlertsCard(),
                  ],

                  const SizedBox(height: 16),

                  _SuggestionCard(suggestion: _getSuggestion()),

                  const SizedBox(height: 24),

                  const _SectionTitle(
                    title: 'Últimos registros',
                    subtitle:
                        'Lectura rápida de cómo respondió el atleta en los entrenamientos recientes.',
                  ),

                  const SizedBox(height: 12),

                  FutureBuilder<List<DailyAthleteLog>>(
                    future: TrainingLogHistoryService.loadLogs(athlete.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data!.isEmpty) {
                        return const _EmptyLogsCard();
                      }

                      final logs = List<DailyAthleteLog>.from(snapshot.data!)
                        ..sort((a, b) => b.date.compareTo(a.date));

                      final recentLogs = logs.length > 10
                          ? logs.sublist(0, 10)
                          : logs;

                      return Column(
                        children: recentLogs
                            .map((log) => _RecentLogCard(log: log))
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  String _getSuggestion() {
    if (_alerts.any((a) => a.severity == 'critical')) {
      return 'Proteger al atleta hoy. Prioriza recuperación, baja la exigencia y revisa dolor o fatiga antes de trabajos intensos.';
    }

    if (_alerts.any((a) => a.title.toLowerCase().contains('dolor'))) {
      return 'Revisar dolor reportado, técnica y volumen reciente. Evita añadir impacto o pliometría si la molestia continúa.';
    }

    if (_alerts.any((a) => a.severity == 'warning')) {
      return 'Mantener el plan con control. Observa calentamiento, sensación de piernas y respuesta al primer bloque.';
    }

    return 'No hay señales críticas. Mantén el plan actual y sigue observando la respuesta real del atleta.';
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      color: _TrainingLogAlertsScreenState._cardColor,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.amber),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Avisos importantes\nAquí aparecen señales que el entrenador debe revisar. La evolución general vive en la pestaña Evolución.',
                style: TextStyle(color: Colors.white70, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(child: Icon(Icons.flag)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoAlertsCard extends StatelessWidget {
  const _NoAlertsCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      color: Color(0xFF064E3B),
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.greenAccent),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No hay avisos importantes. El atleta está respondiendo bien según los registros disponibles.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final String suggestion;

  const _SuggestionCard({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _TrainingLogAlertsScreenState._cardColor,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.lightbulb, color: Colors.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lectura para el entrenador',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    suggestion,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.3,
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

class _AlertCard extends StatelessWidget {
  final TrainingAlert alert;

  const _AlertCard({required this.alert});

  Color _getColor() {
    switch (alert.severity) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  String _severityText() {
    switch (alert.severity) {
      case 'critical':
        return 'Revisar ahora';
      case 'warning':
        return 'Atención';
      default:
        return 'Observación';
    }
  }

  String _cleanTitle(String title) {
    return title
        .replaceAll('Readiness', 'Disponibilidad')
        .replaceAll('readiness', 'disponibilidad')
        .replaceAll('RPE', 'esfuerzo')
        .replaceAll('HRV', 'recuperación');
  }

  String _cleanDescription(String description) {
    return description
        .replaceAll('readiness', 'disponibilidad')
        .replaceAll('Readiness', 'Disponibilidad')
        .replaceAll('RPE', 'esfuerzo')
        .replaceAll('HRV', 'recuperación')
        .replaceAll('carga', 'exigencia');
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Card(
      color: _TrainingLogAlertsScreenState._cardColor,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getIcon(), color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _cleanTitle(alert.title),
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                ),
                Text(
                  _severityText(),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _cleanDescription(alert.description),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Detectado: ${_formatDate(alert.detectedAt)}',
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.75)),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (alert.severity) {
      case 'critical':
        return Icons.warning_amber;
      case 'warning':
        return Icons.info_outline;
      default:
        return Icons.lightbulb_outline;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _EmptyLogsCard extends StatelessWidget {
  const _EmptyLogsCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      color: _TrainingLogAlertsScreenState._cardColor,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.history, color: Colors.white70),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No hay registros guardados. Ve a la pestaña “¿Cómo fue?” para crear uno.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentLogCard extends StatelessWidget {
  final DailyAthleteLog log;

  const _RecentLogCard({required this.log});

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _getPainSummary() {
    final match = RegExp(r'Dolor: (.*?)(?= ·|$)').firstMatch(log.aiNotes);

    if (match != null) {
      final pain = match.group(1) ?? '';
      return pain.length > 40 ? '${pain.substring(0, 40)}...' : pain;
    }

    return 'Sin dolor reportado';
  }

  @override
  Widget build(BuildContext context) {
    final hasPain = _getPainSummary() != 'Sin dolor reportado';

    return Card(
      color: _TrainingLogAlertsScreenState._cardColor,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.white70,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDate(log.date),
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getReadinessColor(log.readiness),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Disponibilidad: ${log.readiness}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChip(
                  icon: Icons.fitness_center,
                  label: 'Exigencia: ${log.rpe}/10',
                  color: _getRpeColor(log.rpe),
                ),
                _buildChip(
                  icon: log.completedAsPlanned
                      ? Icons.check_circle
                      : Icons.warning,
                  label: log.completedAsPlanned
                      ? 'Hecho según plan'
                      : 'Modificado',
                  color: log.completedAsPlanned ? Colors.green : Colors.orange,
                ),
              ],
            ),
            if (hasPain) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.medical_information,
                    size: 14,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _getPainSummary(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.redAccent,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (log.aiDecision.isNotEmpty && log.aiDecision != 'No registrada')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note, size: 14, color: Colors.blue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Decisión: ${log.aiDecision}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.lightBlueAccent,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getReadinessColor(int readiness) {
    if (readiness >= 80) return Colors.green;
    if (readiness >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getRpeColor(int rpe) {
    if (rpe <= 5) return Colors.green;
    if (rpe <= 7) return Colors.orange;
    return Colors.red;
  }
}
