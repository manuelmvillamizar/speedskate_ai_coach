import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';

import 'app_language.dart';
import 'app_text.dart';

import 'athlete_program_service.dart';
import 'athlete_context_service.dart';
import 'athlete_physiology_profile.dart';
import 'athlete_daily_state.dart';

import 'integrated_training_day.dart';
import 'daily_training_block.dart';
import 'daily_athlete_log.dart';

import 'daily_training_assignment_service.dart';
import 'daily_training_assignment.dart';
import 'daily_training_pdf_generator.dart';

import 'physiology_profile_storage_service.dart';
import 'daily_log_storage_service.dart';
import 'training_intervention_engine.dart';
import 'daily_training_pipeline_service.dart';
import 'training_library/day_detail/training_block_detail_screen.dart';
import 'coach_plan_editor_screen.dart';

class DailyAITrainingScreen extends StatelessWidget {
  const DailyAITrainingScreen({super.key});

  Future<DailyTrainingPipelineResult> _loadPipeline({
    required AthleteProgramProfile athlete,
    required AthleteContextService athleteContext,
  }) async {
    final physiologyProfile =
        await PhysiologyProfileStorageService.loadProfile(athlete.id) ??
        AthletePhysiologyProfile(athleteId: athlete.id);

    final logs = await DailyLogStorageService.loadLogs(athlete.id);

    return DailyTrainingPipelineService.run(
      athlete: athlete,
      athleteContext: athleteContext,
      profile: physiologyProfile,
      initialLogs: logs,
      date: DateTime.now(),
      useCache: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageNotifier>().current;
    final athleteContext = context.watch<AthleteContextService>();
    final athlete = athleteContext.activeAthlete;

    if (athlete == null) {
      return Center(
        child: Text(
          AppText.t(
            lang,
            'Selecciona un atleta para generar el plan del día.',
            'Select an athlete to generate the daily plan.',
            'Wähle einen Athleten aus, um den Tagesplan zu generieren.',
          ),
        ),
      );
    }

    return FutureBuilder<DailyTrainingPipelineResult>(
      future: _loadPipeline(athlete: athlete, athleteContext: athleteContext),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error generando el plan diario:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final result = snapshot.data;

        if (result == null) {
          return const Center(
            child: Text('No se pudo generar el entrenamiento diario.'),
          );
        }

        final learnedProfile = result.learnedProfile;
        final logs = result.logs;
        final dailyState = result.dailyState;
        final intervention = result.intervention;
        final day = result.adjustedDay;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _TacticalDayHeader(day: day, state: dailyState),
            const SizedBox(height: 12),

            _CoachActionStrip(
              athlete: athlete,
              athleteId: athlete.id,
              day: day,
              state: dailyState,
              profile: learnedProfile,
              logs: logs,
              intervention: intervention,
            ),

            const SizedBox(height: 18),

            _DayStatusCard(
              day: day,
              state: dailyState,
              intervention: intervention,
            ),

            const SizedBox(height: 20),

            if (day.morningBlocks.isNotEmpty)
              _MomentSection(title: 'Mañana', blocks: day.morningBlocks),

            if (day.afternoonBlocks.isNotEmpty)
              _MomentSection(title: 'Tarde', blocks: day.afternoonBlocks),

            if (day.eveningBlocks.isNotEmpty)
              _MomentSection(title: 'Noche', blocks: day.eveningBlocks),

            const SizedBox(height: 12),

            _SimpleDaySummary(day: day),
          ],
        );
      },
    );
  }
}

class _TacticalDayHeader extends StatelessWidget {
  final IntegratedTrainingDay day;
  final AthleteDailyState state;

  const _TacticalDayHeader({required this.day, required this.state});

  Color _fatigueColor() {
    switch (day.expectedFatigue) {
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.orange;
      case 'orange':
        return Colors.deepOrange;
      case 'red':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  String _mainFocus() {
    if (day.recoveryDay) return 'Recuperación activa';
    if (day.taperMode) return 'Llegar fresco';
    if (day.hasStrengthAndSkating) return 'Fuerza + patines';
    if (day.blocks.any((b) => b.stimulus == TrainingStimulus.speed)) {
      return 'Velocidad específica';
    }
    if (day.blocks.any((b) => b.stimulus == TrainingStimulus.aerobic)) {
      return 'Base aeróbica';
    }
    if (day.blocks.any((b) => b.stimulus == TrainingStimulus.technical)) {
      return 'Técnica';
    }
    return 'Entrenamiento del día';
  }

  String _availabilityText() {
    if (day.expectedReadiness >= 80) return 'Disponibilidad alta';
    if (day.expectedReadiness >= 65) return 'Disponibilidad buena';
    if (day.expectedReadiness >= 50) return 'Disponibilidad moderada';
    return 'Disponibilidad baja';
  }

  String _fatigueText() {
    switch (day.expectedFatigue) {
      case 'green':
        return 'Fatiga controlada';
      case 'yellow':
        return 'Fatiga moderada';
      case 'orange':
        return 'Fatiga alta';
      case 'red':
        return 'Recuperación prioritaria';
      default:
        return 'Estado en revisión';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _fatigueColor();

    return Card(
      elevation: 0,
      color: const Color(0xFF07111F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Plan táctico del día',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              _mainFocus(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _TacticalBadge(
                  label: _availabilityText(),
                  icon: Icons.speed,
                  color: Colors.blue,
                ),
                _TacticalBadge(
                  label: _fatigueText(),
                  icon: Icons.shield,
                  color: color,
                ),
                _TacticalBadge(
                  label: '${day.totalMinutes} min',
                  icon: Icons.timer,
                  color: Colors.teal,
                ),
                if (day.totalKm > 0)
                  _TacticalBadge(
                    label: '${day.totalKm.toStringAsFixed(1)} km',
                    icon: Icons.route,
                    color: Colors.green,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _cleanCoachText(day.aiRecommendation),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachActionStrip extends StatelessWidget {
  final AthleteProgramProfile athlete;
  final String athleteId;
  final IntegratedTrainingDay day;
  final AthleteDailyState state;
  final AthletePhysiologyProfile profile;
  final List<DailyAthleteLog> logs;
  final TrainingInterventionResult intervention;

  const _CoachActionStrip({
    required this.athlete,
    required this.athleteId,
    required this.day,
    required this.state,
    required this.profile,
    required this.logs,
    required this.intervention,
  });

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DailyTrainingAssignmentService>();
    final assignment = service.todayAssignmentForAthlete(athleteId);
    final alreadySent =
        assignment?.status == DailyTrainingAssignmentStatus.sent;

    return Card(
      elevation: 0,
      color: const Color(0xFF111827),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  alreadySent ? Icons.check_circle : Icons.pending_actions,
                  color: alreadySent ? Colors.green : Colors.blue,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    alreadySent
                        ? 'Entrenamiento enviado'
                        : 'Plan listo para decisión del entrenador',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CoachPlanEditorScreen(
                        athleteId: athleteId,
                        initialDay: day,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_calendar),
                label: const Text('Editar plan'),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      service.saveDraft(athleteId: athleteId, day: day);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Plan diario guardado.')),
                      );
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      service.saveDraft(athleteId: athleteId, day: day);
                      service.sendToday(athleteId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Entrenamiento enviado al atleta.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Enviar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final bytes = await DailyTrainingPdfGenerator.generate(
                    athlete: athlete,
                    day: day,
                    state: state,
                    profile: profile,
                    logs: logs,
                    intervention: intervention,
                  );

                  await Printing.sharePdf(
                    bytes: bytes,
                    filename:
                        'entrenamiento_${athlete.name}_${day.date.day}_${day.date.month}_${day.date.year}.pdf',
                  );
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Generar PDF'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayStatusCard extends StatelessWidget {
  final IntegratedTrainingDay day;
  final AthleteDailyState state;
  final TrainingInterventionResult intervention;

  const _DayStatusCard({
    required this.day,
    required this.state,
    required this.intervention,
  });

  Color _color() {
    switch (state.fatigueStatus) {
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.orange;
      case 'orange':
        return Colors.deepOrange;
      case 'red':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  String _mainMessage() {
    if (state.shouldForceRecovery || day.recoveryDay) {
      return 'Hoy conviene proteger recuperación.';
    }
    if (state.shouldBlockIntensity) {
      return 'Evitar intensidad máxima.';
    }
    if (state.shouldReduceLoad) {
      return 'Controlar carga total.';
    }
    if (day.taperMode) {
      return 'Mantener frescura y confianza.';
    }
    return 'Plan listo para ejecutar con control técnico.';
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();

    return Card(
      elevation: 0,
      color: color.withOpacity(0.10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.18),
              child: Icon(Icons.sports_score, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lectura del día',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(_mainMessage()),
                  if (intervention.level != InterventionLevel.none) ...[
                    const SizedBox(height: 8),
                    Text(
                      _cleanCoachText(intervention.summary),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MomentSection extends StatelessWidget {
  final String title;
  final List<DailyTrainingBlock> blocks;

  const _MomentSection({required this.title, required this.blocks});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...blocks.map((block) => _TrainingBlockCard(block: block)),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _TrainingBlockCard extends StatelessWidget {
  final DailyTrainingBlock block;

  const _TrainingBlockCard({required this.block});

  IconData _icon() {
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

  Color _loadColor() {
    if (block.targetLoad >= 75) return Colors.red;
    if (block.targetLoad >= 50) return Colors.orange;
    return Colors.green;
  }

  String _typeText() {
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

  String _loadText() {
    if (block.targetLoad >= 75) return 'Alta';
    if (block.targetLoad >= 50) return 'Media';
    return 'Controlada';
  }

  String _detailButtonText() {
    switch (block.type) {
      case TrainingBlockType.strength:
        return 'Ver gimnasio';
      case TrainingBlockType.cycling:
        return 'Ver bicicleta';
      case TrainingBlockType.skating:
        return 'Ver pista';
      case TrainingBlockType.mobility:
        return 'Ver movilidad';
      case TrainingBlockType.recovery:
        return 'Ver recuperación';
      case TrainingBlockType.activation:
        return 'Ver activación';
      case TrainingBlockType.technical:
        return 'Ver técnica';
      case TrainingBlockType.aerobic:
        return 'Ver aeróbico';
    }
  }

  IconData _detailButtonIcon() {
    switch (block.type) {
      case TrainingBlockType.strength:
        return Icons.fitness_center;
      case TrainingBlockType.cycling:
        return Icons.directions_bike;
      case TrainingBlockType.skating:
        return Icons.speed;
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

  @override
  Widget build(BuildContext context) {
    final color = _loadColor();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(_icon(), color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        block.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _typeText(),
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetricChip(
                  label: 'Exigencia',
                  value: _loadText(),
                  color: color,
                ),
                _MetricChip(
                  label: 'Duración',
                  value: '${block.durationMinutes} min',
                  color: Colors.blue,
                ),
                if (block.km > 0)
                  _MetricChip(
                    label: 'Distancia',
                    value: '${block.km.toStringAsFixed(1)} km',
                    color: Colors.teal,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _ReasonBox(text: block.aiReason),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrainingBlockDetailScreen(block: block),
                    ),
                  );
                },
                icon: Icon(_detailButtonIcon()),
                label: Text(_detailButtonText()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReasonBox extends StatelessWidget {
  final String text;

  const _ReasonBox({required this.text});

  @override
  Widget build(BuildContext context) {
    final clean = _cleanCoachText(text);

    if (clean.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.flag_outlined, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text('Enfoque del bloque: $clean')),
        ],
      ),
    );
  }
}

class _SimpleDaySummary extends StatelessWidget {
  final IntegratedTrainingDay day;

  const _SimpleDaySummary({required this.day});

  @override
  Widget build(BuildContext context) {
    final items = <String>[
      '${day.blocks.length} bloque${day.blocks.length == 1 ? '' : 's'}',
      '${day.totalMinutes} minutos',
      if (day.totalKm > 0) '${day.totalKm.toStringAsFixed(1)} km',
      if (day.hasDoubleSession) 'Doble sesión',
      if (day.hasStrengthAndSkating) 'Fuerza + patines',
      if (day.hasRecoveryBlock) 'Recuperación incluida',
      if (day.wasModifiedByCoach) 'Ajustado por entrenador',
    ];

    return Card(
      elevation: 0,
      color: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen del día',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: items
                  .map(
                    (item) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        item,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12)),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _TacticalBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _TacticalBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

String _cleanCoachText(String text) {
  var clean = text.trim();

  clean = clean.replaceAll('readiness', 'disponibilidad');
  clean = clean.replaceAll('Readiness', 'Disponibilidad');
  clean = clean.replaceAll('HRV', 'recuperación');
  clean = clean.replaceAll('ACWR', 'carga acumulada');
  clean = clean.replaceAll('Z5', 'intensidad máxima');
  clean = clean.replaceAll('fisiológica', 'del atleta');
  clean = clean.replaceAll('fisiológico', 'del atleta');
  clean = clean.replaceAll('neuromuscular', 'de potencia');
  clean = clean.replaceAll('autonómica', 'de recuperación');

  return clean;
}
