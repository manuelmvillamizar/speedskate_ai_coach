import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'athlete_context_service.dart';
import 'daily_athlete_log.dart';
import 'daily_log_storage_service.dart';
import 'daily_training_assignment.dart';
import 'daily_training_assignment_service.dart';
import 'training_log_learning_adapter.dart';

enum ComplianceLevel { full, partial, none }

enum SubjectiveFeel { excellent, good, normal, fatigued, veryFatigued }

enum TechnicalQuality { excellent, good, regular, poor }

enum RecoveryStatus { recovered, partial, loaded }

enum SleepPerception { good, regular, poor }

enum MotivationLevel { high, normal, low }

enum IncidentType {
  none,
  travel,
  sickness,
  highStress,
  weather,
  pain,
  competition,
  modifiedSession,
}

enum CoachDecision {
  maintain,
  reduceLoad,
  increaseLoad,
  recovery,
  easyTechnique,
  blockIntensity,
}

class TrainingLogScreen extends StatefulWidget {
  const TrainingLogScreen({super.key});

  @override
  State<TrainingLogScreen> createState() => _TrainingLogScreenState();
}

class _TrainingLogScreenState extends State<TrainingLogScreen> {
  static const Color _cardColor = Color(0xFF111827);
  static const Color _softCardColor = Color(0xFF1E293B);

  ComplianceLevel _compliance = ComplianceLevel.full;
  double _rpe = 5;
  SubjectiveFeel _subjectiveFeel = SubjectiveFeel.good;
  double _neuralFatigue = 5;

  final Map<String, int> _painAreas = {
    'Cuádriceps': 0,
    'Isquios': 0,
    'Glúteos': 0,
    'Aductores': 0,
    'Lumbar': 0,
    'Tobillo': 0,
    'Rodilla': 0,
  };

  TechnicalQuality _technicalQuality = TechnicalQuality.good;
  RecoveryStatus _recoveryStatus = RecoveryStatus.partial;
  SleepPerception _sleepPerception = SleepPerception.good;
  MotivationLevel _motivation = MotivationLevel.normal;
  IncidentType _incident = IncidentType.none;
  CoachDecision _coachDecision = CoachDecision.maintain;

  final TextEditingController _observationsController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _observationsController.dispose();
    super.dispose();
  }

  void _clearForm() {
    setState(() {
      _compliance = ComplianceLevel.full;
      _rpe = 5;
      _subjectiveFeel = SubjectiveFeel.good;
      _neuralFatigue = 5;

      for (final key in _painAreas.keys) {
        _painAreas[key] = 0;
      }

      _technicalQuality = TechnicalQuality.good;
      _recoveryStatus = RecoveryStatus.partial;
      _sleepPerception = SleepPerception.good;
      _motivation = MotivationLevel.normal;
      _incident = IncidentType.none;
      _coachDecision = CoachDecision.maintain;
      _observationsController.clear();
    });
  }

  Future<void> _saveLog() async {
    if (_saving) return;

    setState(() => _saving = true);

    try {
      final athleteContext = context.read<AthleteContextService>();
      final assignmentService = context.read<DailyTrainingAssignmentService>();

      final athlete = athleteContext.activeAthlete;
      final athleteId = athleteContext.activeAthleteId;

      if (athlete == null || athleteId == null) {
        _showSnackbar('No hay atleta activo.');
        return;
      }

      final assignment = assignmentService.todayAssignmentForAthlete(athleteId);
      final plannedDay = assignment?.trainingDay;

      final plannedLoad = plannedDay?.totalLoad ?? 0;
      final plannedMinutes = plannedDay?.totalMinutes ?? 0;
      final plannedKm = plannedDay?.totalKm ?? 0.0;
      final plannedSessionType = plannedDay == null
          ? ''
          : plannedDay.blocks.map((block) => block.title).join(' + ');

      final performedLoad = _performedLoadFromCompliance(plannedLoad);
      final performedMinutes = _performedMinutesFromCompliance(plannedMinutes);
      final performedKm = _performedKmFromCompliance(plannedKm);

      final dailyLog = DailyAthleteLog(
        athleteId: athleteId,
        date: DateTime.now(),
        plannedSessionType: plannedSessionType,
        plannedLoad: plannedLoad,
        plannedMinutes: plannedMinutes,
        plannedKm: plannedKm,
        completedAsPlanned: _compliance == ComplianceLevel.full,
        performedSessionType: _complianceToText(_compliance),
        performedLoad: performedLoad,
        performedMinutes: performedMinutes,
        performedKm: performedKm,
        rpe: _rpe.round(),
        soreness: _maxPain(),
        motivation: _motivationScore(),
        readiness: _calculateReadiness(),
        overloadDetected: _rpe >= 8 || _neuralFatigue >= 8 || _maxPain() >= 6,
        recoveryRecommended:
            _coachDecision == CoachDecision.recovery ||
            _recoveryStatus == RecoveryStatus.loaded ||
            _subjectiveFeel == SubjectiveFeel.veryFatigued,
        injuryRisk: _calculateInjuryRisk(),
        aiNotes: _buildNotes(),
        aiDecision: _coachDecisionToText(_coachDecision),
        internalLoad: performedMinutes * _rpe,
        externalLoad: performedLoad.toDouble(),
      );

      await DailyLogStorageService.saveLog(dailyLog);

      await TrainingLogLearningAdapter.process(
        athleteId: athleteId,
        log: dailyLog,
        compliance: _compliance,
        subjectiveFeel: _subjectiveFeel,
        technicalQuality: _technicalQuality,
        recoveryStatus: _recoveryStatus,
        sleepPerception: _sleepPerception,
        motivation: _motivation,
        incident: _incident,
        coachDecision: _coachDecision,
        coachModifications: plannedDay?.coachModifications ?? [],
        painAreas: _painAreas,
        rpe: _rpe.round(),
        neuralFatigue: _neuralFatigue.round(),
      );

      if (!mounted) return;

      _showSnackbar('Registro guardado. La app aprendió de este día.');
      _clearForm();
    } catch (error) {
      if (!mounted) return;
      _showSnackbar('Error al guardar: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  int _performedLoadFromCompliance(int plannedLoad) {
    switch (_compliance) {
      case ComplianceLevel.full:
        return plannedLoad > 0 ? plannedLoad : 100;
      case ComplianceLevel.partial:
        return plannedLoad > 0 ? (plannedLoad * 0.55).round() : 50;
      case ComplianceLevel.none:
        return 0;
    }
  }

  int _performedMinutesFromCompliance(int plannedMinutes) {
    switch (_compliance) {
      case ComplianceLevel.full:
        return plannedMinutes;
      case ComplianceLevel.partial:
        return (plannedMinutes * 0.55).round();
      case ComplianceLevel.none:
        return 0;
    }
  }

  double _performedKmFromCompliance(double plannedKm) {
    switch (_compliance) {
      case ComplianceLevel.full:
        return plannedKm;
      case ComplianceLevel.partial:
        return plannedKm * 0.55;
      case ComplianceLevel.none:
        return 0.0;
    }
  }

  int _maxPain() {
    if (_painAreas.isEmpty) return 0;
    return _painAreas.values.reduce((a, b) => a > b ? a : b);
  }

  int _motivationScore() {
    switch (_motivation) {
      case MotivationLevel.high:
        return 8;
      case MotivationLevel.normal:
        return 5;
      case MotivationLevel.low:
        return 3;
    }
  }

  double _calculateInjuryRisk() {
    double risk = 10;

    risk += _maxPain() * 6;
    risk += _neuralFatigue >= 7 ? 12 : 0;
    risk += _rpe >= 8 ? 10 : 0;

    if (_technicalQuality == TechnicalQuality.poor) risk += 12;
    if (_recoveryStatus == RecoveryStatus.loaded) risk += 10;
    if (_incident == IncidentType.pain) risk += 15;
    if (_incident == IncidentType.sickness) risk += 10;

    return risk.clamp(0, 100);
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  int _calculateReadiness() {
    int readiness = 75;

    switch (_subjectiveFeel) {
      case SubjectiveFeel.excellent:
        readiness += 15;
        break;
      case SubjectiveFeel.good:
        readiness += 5;
        break;
      case SubjectiveFeel.normal:
        break;
      case SubjectiveFeel.fatigued:
        readiness -= 15;
        break;
      case SubjectiveFeel.veryFatigued:
        readiness -= 25;
        break;
    }

    switch (_recoveryStatus) {
      case RecoveryStatus.recovered:
        readiness += 10;
        break;
      case RecoveryStatus.partial:
        break;
      case RecoveryStatus.loaded:
        readiness -= 15;
        break;
    }

    switch (_sleepPerception) {
      case SleepPerception.good:
        readiness += 5;
        break;
      case SleepPerception.regular:
        break;
      case SleepPerception.poor:
        readiness -= 15;
        break;
    }

    switch (_motivation) {
      case MotivationLevel.high:
        readiness += 10;
        break;
      case MotivationLevel.normal:
        break;
      case MotivationLevel.low:
        readiness -= 15;
        break;
    }

    if (_technicalQuality == TechnicalQuality.poor) readiness -= 10;
    if (_rpe >= 8) readiness -= 10;

    readiness -= _neuralFatigue.round();
    readiness -= _maxPain() * 3;

    return readiness.clamp(0, 100);
  }

  String _buildNotes() {
    final notes = <String>[];

    notes.add('Cumplimiento: ${_complianceToText(_compliance)}');
    notes.add('Exigencia percibida: ${_rpe.round()}/10');
    notes.add('Sensación de piernas: ${_neuralFatigue.round()}/10');
    notes.add('Sensación general: ${_subjectiveFeelToText(_subjectiveFeel)}');
    notes.add('Recuperación: ${_recoveryToText(_recoveryStatus)}');
    notes.add('Sueño percibido: ${_sleepToText(_sleepPerception)}');
    notes.add('Motivación: ${_motivationToText(_motivation)}');
    notes.add('Calidad técnica: ${_technicalQualityToText(_technicalQuality)}');

    if (_incident != IncidentType.none) {
      notes.add('Incidencia: ${_incidentToText(_incident)}');
    }

    final painNotes = _painAreas.entries
        .where((entry) => entry.value > 0)
        .map((entry) => '${entry.key}: ${entry.value}/10')
        .join(', ');

    if (painNotes.isNotEmpty) {
      notes.add('Dolor: $painNotes');
    }

    if (_observationsController.text.trim().isNotEmpty) {
      notes.add('Observación: ${_observationsController.text.trim()}');
    }

    return notes.join(' · ');
  }

  String _complianceToText(ComplianceLevel value) {
    switch (value) {
      case ComplianceLevel.full:
        return 'Completo';
      case ComplianceLevel.partial:
        return 'Modificado';
      case ComplianceLevel.none:
        return 'No realizado';
    }
  }

  String _subjectiveFeelToText(SubjectiveFeel value) {
    switch (value) {
      case SubjectiveFeel.excellent:
        return 'Excelente';
      case SubjectiveFeel.good:
        return 'Buena';
      case SubjectiveFeel.normal:
        return 'Normal';
      case SubjectiveFeel.fatigued:
        return 'Cansado';
      case SubjectiveFeel.veryFatigued:
        return 'Muy cargado';
    }
  }

  String _technicalQualityToText(TechnicalQuality value) {
    switch (value) {
      case TechnicalQuality.excellent:
        return 'Excelente';
      case TechnicalQuality.good:
        return 'Buena';
      case TechnicalQuality.regular:
        return 'Regular';
      case TechnicalQuality.poor:
        return 'Baja';
    }
  }

  String _recoveryToText(RecoveryStatus value) {
    switch (value) {
      case RecoveryStatus.recovered:
        return 'Listo para trabajar';
      case RecoveryStatus.partial:
        return 'Recuperación parcial';
      case RecoveryStatus.loaded:
        return 'Muy cargado';
    }
  }

  String _sleepToText(SleepPerception value) {
    switch (value) {
      case SleepPerception.good:
        return 'Bueno';
      case SleepPerception.regular:
        return 'Regular';
      case SleepPerception.poor:
        return 'Malo';
    }
  }

  String _motivationToText(MotivationLevel value) {
    switch (value) {
      case MotivationLevel.high:
        return 'Alta';
      case MotivationLevel.normal:
        return 'Normal';
      case MotivationLevel.low:
        return 'Baja';
    }
  }

  String _incidentToText(IncidentType value) {
    switch (value) {
      case IncidentType.none:
        return 'Ninguna';
      case IncidentType.travel:
        return 'Viaje';
      case IncidentType.sickness:
        return 'Enfermedad';
      case IncidentType.highStress:
        return 'Estrés alto';
      case IncidentType.weather:
        return 'Clima';
      case IncidentType.pain:
        return 'Dolor';
      case IncidentType.competition:
        return 'Competencia';
      case IncidentType.modifiedSession:
        return 'Sesión modificada';
    }
  }

  String _coachDecisionToText(CoachDecision value) {
    switch (value) {
      case CoachDecision.maintain:
        return 'Mantener plan';
      case CoachDecision.reduceLoad:
        return 'Proteger';
      case CoachDecision.increaseLoad:
        return 'Exigir más';
      case CoachDecision.recovery:
        return 'Recuperación activa';
      case CoachDecision.easyTechnique:
        return 'Técnica suave';
      case CoachDecision.blockIntensity:
        return 'Bloquear intensidad';
    }
  }

  @override
  Widget build(BuildContext context) {
    final athlete = context.watch<AthleteContextService>().activeAthlete;
    final athleteId = context.watch<AthleteContextService>().activeAthleteId;

    if (athlete == null || athleteId == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No hay atleta activo.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final assignment = context
        .watch<DailyTrainingAssignmentService>()
        .todayAssignmentForAthlete(athleteId);

    return Scaffold(
      appBar: AppBar(
        title: Text('¿Cómo fue? - ${athlete.name}'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        children: [
          _TrainingLogHeroCard(
            athleteName: athlete.name,
            availabilityPreview: _calculateReadiness(),
            protectionPreview: _calculateInjuryRisk(),
          ),
          const SizedBox(height: 12),
          _PlannedTrainingCard(assignment: assignment),
          const SizedBox(height: 12),
          _section(
            title: '1. ¿Qué tanto pudo completar?',
            subtitle: 'Marca si el entrenamiento se hizo como estaba previsto.',
            child: _dropdown<ComplianceLevel>(
              value: _compliance,
              items: ComplianceLevel.values,
              labelBuilder: _complianceToText,
              onChanged: (value) => setState(() => _compliance = value),
            ),
          ),
          _section(
            title: '2. ¿Qué tan exigente fue?',
            subtitle: 'Qué tan duro se sintió el entrenamiento para el atleta.',
            child: _slider(
              value: _rpe,
              min: 1,
              max: 10,
              label: '${_rpe.round()} / 10',
              onChanged: (value) => setState(() => _rpe = value),
            ),
          ),
          _section(
            title: '3. Sensación general',
            subtitle: 'Cómo terminó el atleta después del entrenamiento.',
            child: _dropdown<SubjectiveFeel>(
              value: _subjectiveFeel,
              items: SubjectiveFeel.values,
              labelBuilder: _subjectiveFeelToText,
              onChanged: (value) => setState(() => _subjectiveFeel = value),
            ),
          ),
          _section(
            title: '4. Sensación de piernas',
            subtitle: 'Pesadez, lentitud, rigidez o poca reacción.',
            child: _slider(
              value: _neuralFatigue,
              min: 1,
              max: 10,
              label: '${_neuralFatigue.round()} / 10',
              onChanged: (value) => setState(() => _neuralFatigue = value),
            ),
          ),
          _section(
            title: '5. Dolor por zonas',
            subtitle:
                'La app usa esto para proteger tendón, músculo y técnica.',
            child: _painSliders(),
          ),
          _section(
            title: '6. Calidad técnica',
            subtitle: 'Si la técnica cae, la app aprende a ajustar el plan.',
            child: _dropdown<TechnicalQuality>(
              value: _technicalQuality,
              items: TechnicalQuality.values,
              labelBuilder: _technicalQualityToText,
              onChanged: (value) => setState(() => _technicalQuality = value),
            ),
          ),
          _section(
            title: '7. Recuperación',
            subtitle: 'Cómo quedó el atleta después de la sesión.',
            child: _dropdown<RecoveryStatus>(
              value: _recoveryStatus,
              items: RecoveryStatus.values,
              labelBuilder: _recoveryToText,
              onChanged: (value) => setState(() => _recoveryStatus = value),
            ),
          ),
          _section(
            title: '8. Sueño percibido',
            subtitle: 'Se combina con el dispositivo cuando haya datos.',
            child: _dropdown<SleepPerception>(
              value: _sleepPerception,
              items: SleepPerception.values,
              labelBuilder: _sleepToText,
              onChanged: (value) => setState(() => _sleepPerception = value),
            ),
          ),
          _section(
            title: '9. Motivación',
            subtitle: 'Ayuda a entender la respuesta emocional del atleta.',
            child: _dropdown<MotivationLevel>(
              value: _motivation,
              items: MotivationLevel.values,
              labelBuilder: _motivationToText,
              onChanged: (value) => setState(() => _motivation = value),
            ),
          ),
          _section(
            title: '10. Incidencia',
            subtitle: 'Viaje, enfermedad, estrés, dolor o cambio de sesión.',
            child: _dropdown<IncidentType>(
              value: _incident,
              items: IncidentType.values,
              labelBuilder: _incidentToText,
              onChanged: (value) => setState(() => _incident = value),
            ),
          ),
          _section(
            title: '11. Decisión para el próximo día',
            subtitle: 'La app aprende también del criterio del entrenador.',
            child: _dropdown<CoachDecision>(
              value: _coachDecision,
              items: CoachDecision.values,
              labelBuilder: _coachDecisionToText,
              onChanged: (value) => setState(() => _coachDecision = value),
            ),
          ),
          _section(
            title: '12. Observaciones',
            subtitle: 'Comentarios libres del entrenador.',
            child: TextField(
              controller: _observationsController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Ej: rígido en curvas, excelente remate...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _saving ? null : _saveLog,
            icon: const Icon(Icons.save),
            label: const Text('Guardar registro del día'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      color: _cardColor,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T value) labelBuilder,
    required ValueChanged<T> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      dropdownColor: _softCardColor,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(labelBuilder(item), overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;
        onChanged(value);
      },
    );
  }

  Widget _slider({
    required double value,
    required double min,
    required double max,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              min.round().toString(),
              style: const TextStyle(color: Colors.white70),
            ),
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: (max - min).round(),
                label: value.round().toString(),
                onChanged: onChanged,
              ),
            ),
            Text(
              max.round().toString(),
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _painSliders() {
    return Column(
      children: _painAreas.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  entry.key,
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ),
              Expanded(
                child: Slider(
                  value: entry.value.toDouble(),
                  min: 0,
                  max: 10,
                  divisions: 10,
                  label: entry.value.toString(),
                  onChanged: (value) {
                    setState(() {
                      _painAreas[entry.key] = value.round();
                    });
                  },
                ),
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '${entry.value}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TrainingLogHeroCard extends StatelessWidget {
  final String athleteName;
  final int availabilityPreview;
  final double protectionPreview;

  const _TrainingLogHeroCard({
    required this.athleteName,
    required this.availabilityPreview,
    required this.protectionPreview,
  });

  Color get protectionColor {
    if (protectionPreview >= 70) return Colors.red;
    if (protectionPreview >= 45) return Colors.orange;
    return Colors.green;
  }

  String get protectionText {
    if (protectionPreview >= 70) return 'proteger';
    if (protectionPreview >= 45) return 'controlar';
    return 'estable';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF07111F),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white12,
              child: Icon(Icons.fact_check, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    athleteName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Cómo respondió el atleta después del entrenamiento.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  '$availabilityPreview',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'disponibilidad',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  protectionText,
                  style: TextStyle(
                    color: protectionColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlannedTrainingCard extends StatelessWidget {
  final DailyTrainingAssignment? assignment;

  const _PlannedTrainingCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final day = assignment?.trainingDay;

    if (day == null) {
      return Card(
        color: Colors.orange.withOpacity(0.10),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const ListTile(
          leading: Icon(Icons.info_outline, color: Colors.orange),
          title: Text(
            'No hay plan enviado para hoy',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'El registro se guardará como observación libre del entrenador.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Card(
      color: Colors.blue.withOpacity(0.08),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.assignment_turned_in, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Plan enviado para hoy',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              day.aiSummary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SmallChip(label: 'Exigencia', value: '${day.totalLoad}'),
                _SmallChip(label: 'Min', value: '${day.totalMinutes}'),
                _SmallChip(label: 'Km', value: day.totalKm.toStringAsFixed(1)),
                _SmallChip(label: 'Bloques', value: '${day.blocks.length}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label;
  final String value;

  const _SmallChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}
