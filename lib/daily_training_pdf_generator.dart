import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'athlete_program_service.dart';
import 'integrated_training_day.dart';
import 'daily_training_block.dart';
import 'athlete_daily_state.dart';
import 'athlete_physiology_profile.dart';
import 'daily_athlete_log.dart';
import 'training_intervention_engine.dart';

class DailyTrainingPdfGenerator {
  static Future<Uint8List> generate({
    required AthleteProgramProfile athlete,
    required IntegratedTrainingDay day,
    required AthleteDailyState state,
    required AthletePhysiologyProfile profile,
    required List<DailyAthleteLog> logs,
    required TrainingInterventionResult intervention,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return [
            _header(athlete, day),
            pw.SizedBox(height: 14),
            _executiveDashboard(day, state, intervention),
            pw.SizedBox(height: 14),
            _coachSummary(day, intervention),
            pw.SizedBox(height: 14),

            _intervention(intervention),
            pw.SizedBox(height: 14),
            _sectionTitle('Plan diario integrado'),
            pw.SizedBox(height: 8),
            _trainingOverview(day),
            pw.SizedBox(height: 12),
            ...day.blocks.map(_trainingBlock),
            pw.SizedBox(height: 14),
            _recommendations(day, state, logs),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _header(
    AthleteProgramProfile athlete,
    IntegratedTrainingDay day,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey900,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SpeedSkate Coach',
            style: pw.TextStyle(
              fontSize: 25,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Plan de entrenamiento de alto rendimiento',
            style: pw.TextStyle(fontSize: 13, color: PdfColors.blueGrey100),
          ),
          pw.SizedBox(height: 14),
          _headerRow('Atleta', _cleanText(athlete.name)),
          _headerRow('Categoría', _cleanText(athlete.category)),
          _headerRow('Fecha', _formatDate(day.date)),
          _headerRow('Tipo de día', _dayType(day)),
        ],
      ),
    );
  }

  static pw.Widget _executiveDashboard(
    IntegratedTrainingDay day,
    AthleteDailyState state,
    TrainingInterventionResult intervention,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle('Resumen ejecutivo'),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              _dashboardCard(
                title: 'Disponibilidad',
                value: '${state.readiness}',
                subtitle: '/100',
                color: _readinessColor(state.readiness),
              ),
              pw.SizedBox(width: 8),
              _dashboardCard(
                title: 'Fatiga',
                value: state.fatigueStatus.toUpperCase(),
                subtitle: '',
                color: _fatigueColor(state.fatigueStatus),
              ),
              pw.SizedBox(width: 8),
              _dashboardCard(
                title: 'Carga',
                value: '${day.totalLoad}',
                subtitle: 'total',
                color: _loadColor(day.totalLoad),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _dashboardCard(
                title: 'Duración',
                value: '${day.totalMinutes}',
                subtitle: 'min',
                color: PdfColors.blue50,
              ),
              pw.SizedBox(width: 8),
              _dashboardCard(
                title: 'Riesgo',
                value: state.injuryRisk.toStringAsFixed(0),
                subtitle: '/100',
                color: _riskColor(state.injuryRisk),
              ),
              pw.SizedBox(width: 8),
              _dashboardCard(
                title: 'Ajuste',
                value: _interventionLevelText(intervention.level),
                subtitle: '',
                color: _interventionPdfColor(intervention.level),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Objetivo principal del día',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey800,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(_dayMainFocus(day)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _dashboardCard({
    required String title,
    required String value,
    required String subtitle,
    required PdfColor color,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(10),
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              _cleanText(value),
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
              maxLines: 1,
            ),
            if (subtitle.isNotEmpty) ...[
              pw.SizedBox(height: 2),
              pw.Text(
                subtitle,
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static pw.Widget _coachSummary(
    IntegratedTrainingDay day,
    TrainingInterventionResult intervention,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle('Resumen de planificación'),
          pw.SizedBox(height: 8),
          pw.Text(_cleanText(day.aiSummary)),
          pw.SizedBox(height: 8),
          pw.Text(
            _cleanText(day.aiRecommendation),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          _row('Nivel de ajuste', _interventionLevelText(intervention.level)),
          _row('Carga total', '${day.totalLoad}'),
          _row('Minutos totales', '${day.totalMinutes} min'),
          _row('Kilómetros patines estimados', day.totalKm.toStringAsFixed(1)),
        ],
      ),
    );
  }

  static pw.Widget _physiology(
    IntegratedTrainingDay day,
    AthleteDailyState state,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle('Estado fisiológico del día'),
          pw.SizedBox(height: 8),
          _row('Disponibilidad', '${state.readiness} / 100'),
          _row('Fatiga', _cleanText(state.fatigueStatus.toUpperCase())),
          _row(
            'Riesgo de lesión',
            '${state.injuryRisk.toStringAsFixed(0)} / 100',
          ),
          _row('Carga aguda', state.acuteLoad.toStringAsFixed(1)),
          _row('Carga crónica', state.chronicLoad.toStringAsFixed(1)),
          _row('ACWR', state.acwr.toStringAsFixed(2)),
          pw.SizedBox(height: 8),
          pw.Text(
            _cleanText(state.aiSummary),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(_cleanText(state.aiRecommendation)),
        ],
      ),
    );
  }

  static pw.Widget _zoneSummary(
    AthleteDailyState state,
    List<DailyAthleteLog> logs,
  ) {
    final lastLog = logs.isEmpty ? state.log : logs.last;
    final wearable = state.wearable;

    final z1 = wearable != null && wearable.totalZoneMinutes > 0
        ? wearable.zone1Minutes
        : lastLog?.zone1Minutes ?? 0;
    final z2 = wearable != null && wearable.totalZoneMinutes > 0
        ? wearable.zone2Minutes
        : lastLog?.zone2Minutes ?? 0;
    final z3 = wearable != null && wearable.totalZoneMinutes > 0
        ? wearable.zone3Minutes
        : lastLog?.zone3Minutes ?? 0;
    final z4 = wearable != null && wearable.totalZoneMinutes > 0
        ? wearable.zone4Minutes
        : lastLog?.zone4Minutes ?? 0;
    final z5 = wearable != null && wearable.totalZoneMinutes > 0
        ? wearable.zone5Minutes
        : lastLog?.zone5Minutes ?? 0;

    final total = z1 + z2 + z3 + z4 + z5;
    final highToday = z4 + z5;
    final highRatio = total <= 0 ? 0.0 : highToday / total;

    final last7 = logs.length <= 7 ? logs : logs.sublist(logs.length - 7);

    final high7 = last7.fold<int>(
      0,
      (sum, log) => sum + log.highIntensityMinutes,
    );

    final z5SevenDays = last7.fold<int>(
      0,
      (sum, log) => sum + log.zone5Minutes,
    );

    final color = _zonePdfColor(
      highRatio: highRatio,
      high7: high7,
      z5SevenDays: z5SevenDays,
    );

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle('Resumen de zonas Z1-Z5'),
          pw.SizedBox(height: 8),
          _row('Z1 recuperación', '$z1 min'),
          _row('Z2 base aeróbica', '$z2 min'),
          _row('Z3 ritmo moderado', '$z3 min'),
          _row('Z4 alta intensidad', '$z4 min'),
          _row('Z5 máxima intensidad', '$z5 min'),
          pw.SizedBox(height: 8),
          _row('Total zonas hoy', '$total min'),
          _row('Z4/Z5 hoy', '$highToday min'),
          _row('Ratio alta intensidad hoy', '${(highRatio * 100).round()}%'),
          _row('Z4/Z5 últimos 7 días', '$high7 min'),
          _row('Z5 últimos 7 días', '$z5SevenDays min'),
          pw.SizedBox(height: 8),
          pw.Text(
            _zoneInterpretation(
              total: total,
              highRatio: highRatio,
              high7: high7,
              z5SevenDays: z5SevenDays,
            ),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _learning(
    AthletePhysiologyProfile profile,
    List<DailyAthleteLog> logs,
    AthleteDailyState state,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.purple50,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle('Perfil fisiológico'),
          pw.SizedBox(height: 8),
          _row('Registros históricos usados', '${logs.length}'),
          _row('HRV base', profile.baselineHrv.toStringAsFixed(1)),
          _row('FC reposo base', '${profile.baselineRestingHeartRate}'),
          _row(
            'Sueño promedio',
            '${profile.averageSleepHours.toStringAsFixed(1)} h',
          ),
          _row('Estrés promedio', '${profile.averageStress}'),
          _row(
            'Capacidad de recuperación',
            profile.recoveryRate.toStringAsFixed(2),
          ),
          _row(
            'Acumulación de fatiga',
            profile.fatigueAccumulationRate.toStringAsFixed(2),
          ),
          _row(
            'Respuesta a la fuerza',
            profile.strengthResponse.toStringAsFixed(2),
          ),
          _row(
            'Respuesta a la velocidad',
            profile.speedResponse.toStringAsFixed(2),
          ),
          _row(
            'Respuesta a la resistencia',
            profile.enduranceResponse.toStringAsFixed(2),
          ),
          _row('Adaptación', profile.adaptationScore.toStringAsFixed(1)),
        ],
      ),
    );
  }

  static pw.Widget _intervention(TrainingInterventionResult intervention) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _interventionPdfColor(intervention.level),
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle('Control de seguridad y carga'),
          pw.SizedBox(height: 8),
          _row('Nivel', _interventionLevelText(intervention.level)),
          pw.SizedBox(height: 6),
          pw.Text(_cleanText(intervention.summary)),
          pw.SizedBox(height: 10),
          if (intervention.blockHighIntensity)
            pw.Bullet(text: 'Bloquear intensidad alta.'),
          if (intervention.reduceVolume)
            pw.Bullet(text: 'Reducir volumen total.'),
          if (intervention.forceRecovery)
            pw.Bullet(text: 'Priorizar recuperación.'),
          if (intervention.blockDoubleSession)
            pw.Bullet(text: 'Evitar doble sesión de riesgo.'),
          if (intervention.blockHeavyStrength)
            pw.Bullet(text: 'Evitar fuerza pesada.'),
          if (intervention.protectCompetition)
            pw.Bullet(text: 'Proteger taper / competencia.'),
          if (!intervention.blockHighIntensity &&
              !intervention.reduceVolume &&
              !intervention.forceRecovery &&
              !intervention.blockDoubleSession &&
              !intervention.blockHeavyStrength &&
              !intervention.protectCompetition)
            pw.Text('Sin restricciones críticas detectadas.'),
          if (intervention.warnings.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              'Alertas:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            ...intervention.warnings.map(
              (warning) => pw.Bullet(text: _cleanText(warning)),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _trainingOverview(IntegratedTrainingDay day) {
    final skating = day.blocks
        .where((b) => b.type == TrainingBlockType.skating)
        .toList();
    final strength = day.blocks
        .where((b) => b.type == TrainingBlockType.strength)
        .toList();
    final cycling = day.blocks
        .where((b) => b.type == TrainingBlockType.cycling)
        .toList();
    final physical = day.blocks
        .where(
          (b) =>
              b.type == TrainingBlockType.mobility ||
              b.type == TrainingBlockType.activation ||
              b.type == TrainingBlockType.technical ||
              b.type == TrainingBlockType.aerobic,
        )
        .toList();
    final recovery = day.blocks.where((b) => b.recoveryFocused).toList();

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _row('Bloques totales', '${day.blocks.length}'),
          _row('Patines', '${skating.length} bloque(s)'),
          _row('Gimnasio / fuerza', '${strength.length} bloque(s)'),
          _row('Bicicleta', '${cycling.length} bloque(s)'),
          _row('Trabajo físico / técnico', '${physical.length} bloque(s)'),
          _row('Recuperación', '${recovery.length} bloque(s)'),
        ],
      ),
    );
  }

  static pw.Widget _trainingBlock(DailyTrainingBlock block) {
    final color = _blockColor(block);

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 82,
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Center(
                  child: pw.Text(
                    _momentText(block.moment),
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Text(
                  '${_typeText(block.type)} · ${_cleanText(block.title)}',
                  style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(_cleanText(block.description)),
          pw.SizedBox(height: 10),
          pw.Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chip('Duración: ${block.durationMinutes} min'),
              _chip('Km: ${block.km.toStringAsFixed(1)}'),
              _chip('Carga: ${block.targetLoad}'),
              _chip('Zona FC: Z${block.targetHeartRateZone}'),
              _chip('Estímulo: ${_stimulusText(block.stimulus)}'),
              _chip('Sistema: ${_energySystemText(block.energySystem)}'),
              _chip(
                'Neuromuscular: ${_neuromuscularText(block.neuromuscularLoad)}',
              ),
              if (block.recoveryFocused) _chip('Recuperación'),
              if (block.taperFocused) _chip('Taper'),
            ],
          ),
          pw.SizedBox(height: 10),
          if (block.hasProfessionalDetails) ...[
            _professionalListSection('Calentamiento', block.warmup),
            _professionalListSection('Bloque principal', block.mainSet),
            _professionalListSection('Ejercicios', block.exercises),
            _professionalListSection('Fuerza / pesas', block.strengthExercises),
            _professionalListSection(
              'Pliometría / potencia',
              block.plyometricExercises,
            ),

            _professionalListSection('Vuelta a la calma', block.cooldown),

            _professionalListSection(
              'Criterios para cortar',
              block.stopCriteria,
            ),
            pw.SizedBox(height: 2),
          ],
        ],
      ),
    );
  }

  static pw.Widget _professionalListSection(String title, List<String> items) {
    if (items.isEmpty) return pw.SizedBox.shrink();

    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
          pw.SizedBox(height: 5),
          ...items.map((item) => _bullet(_cleanText(item))),
        ],
      ),
    );
  }

  static pw.Widget _bullet(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
         pw.Text('• ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Expanded(
            child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _recommendations(
    IntegratedTrainingDay day,
    AthleteDailyState state,
    List<DailyAthleteLog> logs,
  ) {
    final recommendations = <String>[];

    final last7 = logs.length <= 7 ? logs : logs.sublist(logs.length - 7);

    final high7 = last7.fold<int>(
      0,
      (sum, log) => sum + log.highIntensityMinutes,
    );

    final z5SevenDays = last7.fold<int>(
      0,
      (sum, log) => sum + log.zone5Minutes,
    );

    if (day.recoveryDay || state.shouldForceRecovery) {
      recommendations.add(
        'No recuperar carga perdida. Priorizar sueño y recuperación.',
      );
    }

    if (state.shouldBlockIntensity) {
      recommendations.add('Bloquear intensidad máxima durante el día.');
    }

    if (state.shouldReduceLoad) {
      recommendations.add(
        'Reducir carga si aparece fatiga técnica o muscular.',
      );
    }

    if (high7 >= 90) {
      recommendations.add(
        'Evitar nuevos minutos en Z4/Z5 por alta intensidad acumulada.',
      );
    }

    if (z5SevenDays >= 18) {
      recommendations.add(
        'Evitar Z5 y esfuerzos máximos por carga neuromuscular acumulada.',
      );
    }

    if (day.taperMode || state.taperRecommended) {
      recommendations.add('Mantener frescura. No agregar volumen extra.');
    }

    if (day.hasStrengthAndSkating) {
      recommendations.add(
        'Separar fuerza y patines. Controlar calidad neuromuscular.',
      );
    }

    if (day.hasDoubleSession) {
      recommendations.add('Cuidar hidratación y alimentación entre sesiones.');
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        'Seguir el plan enviado por el entrenador sin agregar trabajo extra.',
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle('Recomendaciones finales'),
          pw.SizedBox(height: 8),
          ...recommendations.map((item) => pw.Bullet(text: item)),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
    );
  }

  static pw.Widget _headerRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Text(
              _cleanText(label),
              style: const pw.TextStyle(color: PdfColors.blueGrey100),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Text(
            _cleanText(value),
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _row(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(child: pw.Text(_cleanText(label))),
          pw.SizedBox(width: 12),
          pw.Text(
            _cleanText(value),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _chip(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Text(_cleanText(text), style: const pw.TextStyle(fontSize: 10)),
    );
  }

  static String _zoneInterpretation({
    required int total,
    required double highRatio,
    required int high7,
    required int z5SevenDays,
  }) {
    if (total <= 0) {
      return 'Sin datos de zonas para hoy. Sincronizar wearable para análisis completo.';
    }

    if (high7 >= 120 || z5SevenDays >= 28) {
      return 'Alerta crítica: exceso de Z4/Z5 acumulada. Bloquear intensidad.';
    }

    if (high7 >= 90 || highRatio >= 0.30) {
      return 'Alta intensidad elevada. Reducir volumen y proteger recuperación.';
    }

    if (highRatio >= 0.20 || high7 >= 65) {
      return 'Intensidad moderadamente alta. Controlar carga restante.';
    }

    return 'Distribución de intensidad controlada.';
  }

  static PdfColor _zonePdfColor({
    required double highRatio,
    required int high7,
    required int z5SevenDays,
  }) {
    if (high7 >= 120 || z5SevenDays >= 28) return PdfColors.red100;
    if (high7 >= 90 || z5SevenDays >= 18 || highRatio >= 0.30) {
      return PdfColors.orange50;
    }
    if (highRatio >= 0.20 || high7 >= 65) return PdfColors.yellow50;
    return PdfColors.green50;
  }

  static String _dayType(IntegratedTrainingDay day) {
    if (day.recoveryDay) return 'Recuperación';
    if (day.taperMode) return 'Taper / competencia';
    if (day.hasStrengthAndSkating) return 'Integrado fuerza + patines';
    if (day.hasDoubleSession) return 'Doble sesión';
    return 'Sesión única';
  }

  static String _dayMainFocus(IntegratedTrainingDay day) {
    if (day.recoveryDay) {
      return 'Recuperar, bajar carga acumulada y proteger la adaptación.';
    }

    if (day.taperMode) {
      return 'Mantener frescura, velocidad técnica y confianza antes de competir.';
    }

    if (day.hasStrengthAndSkating) {
      return 'Convertir fuerza en velocidad específica sin perder calidad técnica.';
    }

    if (day.hasDoubleSession) {
      return 'Distribuir la carga del día cuidando recuperación entre sesiones.';
    }

    if (day.totalLoad >= 80) {
      return 'Día de calidad: intensidad controlada y ejecución técnica precisa.';
    }

    if (day.totalLoad <= 40) {
      return 'Día liviano: técnica, movilidad y recuperación activa.';
    }

    return 'Cumplir el estímulo principal del día sin añadir carga extra.';
  }

  static String _momentText(TrainingBlockMoment moment) {
    switch (moment) {
      case TrainingBlockMoment.morning:
        return 'Mañana';
      case TrainingBlockMoment.afternoon:
        return 'Tarde';
      case TrainingBlockMoment.evening:
        return 'Noche';
    }
  }

  static String _typeText(TrainingBlockType type) {
    switch (type) {
      case TrainingBlockType.skating:
        return 'Patines';
      case TrainingBlockType.strength:
        return 'Gimnasio';
      case TrainingBlockType.cycling:
        return 'Bicicleta';
      case TrainingBlockType.recovery:
        return 'Recuperación';
      case TrainingBlockType.mobility:
        return 'Movilidad';
      case TrainingBlockType.activation:
        return 'Activación / pliometría';
      case TrainingBlockType.technical:
        return 'Técnica';
      case TrainingBlockType.aerobic:
        return 'Aeróbico';
    }
  }

  static String _stimulusText(TrainingStimulus stimulus) {
    switch (stimulus) {
      case TrainingStimulus.recovery:
        return 'Recuperación';
      case TrainingStimulus.mobility:
        return 'Movilidad';
      case TrainingStimulus.technical:
        return 'Técnica';
      case TrainingStimulus.aerobic:
        return 'Aeróbico';
      case TrainingStimulus.anaerobic:
        return 'Anaeróbico';
      case TrainingStimulus.lactateTolerance:
        return 'Tolerancia lactato';
      case TrainingStimulus.neuromuscular:
        return 'Neuromuscular';
      case TrainingStimulus.maxStrength:
        return 'Fuerza máxima';
      case TrainingStimulus.power:
        return 'Potencia';
      case TrainingStimulus.strengthEndurance:
        return 'Fuerza resistencia';
      case TrainingStimulus.plyometric:
        return 'Pliometría';
      case TrainingStimulus.speed:
        return 'Velocidad';
      case TrainingStimulus.tactical:
        return 'Táctica';
    }
  }

  static String _energySystemText(TrainingEnergySystem system) {
    switch (system) {
      case TrainingEnergySystem.none:
        return 'Ninguno';
      case TrainingEnergySystem.aerobic:
        return 'Aeróbico';
      case TrainingEnergySystem.anaerobicAlactic:
        return 'Anaeróbico aláctico';
      case TrainingEnergySystem.anaerobicLactic:
        return 'Anaeróbico láctico';
      case TrainingEnergySystem.mixed:
        return 'Mixto';
    }
  }

  static String _neuromuscularText(NeuromuscularLoad load) {
    switch (load) {
      case NeuromuscularLoad.none:
        return 'Nula';
      case NeuromuscularLoad.low:
        return 'Baja';
      case NeuromuscularLoad.moderate:
        return 'Moderada';
      case NeuromuscularLoad.high:
        return 'Alta';
      case NeuromuscularLoad.maximal:
        return 'Máxima';
    }
  }

  static PdfColor _blockColor(DailyTrainingBlock block) {
    if (block.recoveryFocused) return PdfColors.green50;
    if (block.taperFocused) return PdfColors.orange50;

    switch (block.type) {
      case TrainingBlockType.skating:
        return PdfColors.blue50;
      case TrainingBlockType.strength:
        return PdfColors.red50;
      case TrainingBlockType.cycling:
        return PdfColors.cyan50;
      case TrainingBlockType.recovery:
        return PdfColors.green50;
      case TrainingBlockType.mobility:
        return PdfColors.grey100;
      case TrainingBlockType.activation:
        return PdfColors.amber50;
      case TrainingBlockType.technical:
        return PdfColors.indigo50;
      case TrainingBlockType.aerobic:
        return PdfColors.teal50;
    }
  }

  static PdfColor _readinessColor(int readiness) {
    if (readiness >= 80) return PdfColors.green50;
    if (readiness >= 65) return PdfColors.yellow50;
    if (readiness >= 45) return PdfColors.orange50;
    return PdfColors.red50;
  }

  static PdfColor _fatigueColor(String fatigue) {
    final value = fatigue.toLowerCase();

    if (value == 'green') return PdfColors.green50;
    if (value == 'yellow') return PdfColors.yellow50;
    if (value == 'orange') return PdfColors.orange50;
    if (value == 'red') return PdfColors.red50;

    return PdfColors.grey100;
  }

  static PdfColor _loadColor(int load) {
    if (load >= 220) return PdfColors.red50;
    if (load >= 150) return PdfColors.orange50;
    if (load >= 80) return PdfColors.yellow50;
    return PdfColors.green50;
  }

  static PdfColor _riskColor(double risk) {
    if (risk >= 70) return PdfColors.red50;
    if (risk >= 45) return PdfColors.orange50;
    if (risk >= 25) return PdfColors.yellow50;
    return PdfColors.green50;
  }

  static PdfColor _interventionPdfColor(InterventionLevel level) {
    switch (level) {
      case InterventionLevel.none:
        return PdfColors.green50;
      case InterventionLevel.caution:
        return PdfColors.yellow50;
      case InterventionLevel.moderate:
        return PdfColors.orange50;
      case InterventionLevel.severe:
        return PdfColors.red50;
      case InterventionLevel.critical:
        return PdfColors.red100;
    }
  }

  static String _interventionLevelText(InterventionLevel level) {
    switch (level) {
      case InterventionLevel.none:
        return 'Sin alerta';
      case InterventionLevel.caution:
        return 'Precaución';
      case InterventionLevel.moderate:
        return 'Ajuste recomendado';
      case InterventionLevel.severe:
        return 'Riesgo alto';
      case InterventionLevel.critical:
        return 'Ajuste crítico';
    }
  }

  static String _coachFriendlyReason(DailyTrainingBlock block) {
    final raw = _cleanText(block.aiReason);

    if (raw.contains('speedResponse')) {
      if (block.type == TrainingBlockType.skating) {
        return 'Estimular velocidad específica manteniendo calidad técnica y control de fatiga.';
      }

      if (block.type == TrainingBlockType.activation ||
          block.type == TrainingBlockType.technical) {
        return 'Preparar el sistema neuromuscular para moverse rápido sin generar fatiga extra.';
      }
    }

    if (raw.contains('estado fisiológico')) {
      return 'Ajustar la sesión al estado del día para proteger rendimiento y recuperación.';
    }

    if (raw.contains('adaptación')) {
      return 'Aplicar el estímulo necesario sin comprometer la recuperación.';
    }

    return raw;
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  static String _cleanText(String value) {
    var text = value;

   final replacements = <String, String>{
  'La IA ajustó automáticamente': 'El sistema ajustó',
  'La IA ajusto automaticamente': 'El sistema ajustó',
  'Intervención IA': 'Ajuste aplicado',
  'intervención IA': 'ajuste aplicado',
  'Razón IA': 'Objetivo del bloque',
  'razón IA': 'objetivo del bloque',
  'Aprendizaje fisiológico IA': 'Perfil fisiológico',
  'IA de seguridad': 'control de seguridad',
  ' IA ': ' sistema ',
  ' IA.': ' sistema.',
  ' IA,': ' sistema,',
  'IA:': 'Sistema:',
  'AI ': '',
  ' AI': '',
};

    replacements.forEach((wrong, correct) {
      text = text.replaceAll(wrong, correct);
    });

    return text;
  }
}


