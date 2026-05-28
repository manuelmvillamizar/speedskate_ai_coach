import 'daily_athlete_log.dart';
import 'daily_log_storage_service.dart';

class TrainingLogAnalysis {
  final DateTime date;
  final int readiness;
  final int soreness;
  final int rpe;
  final int neuralFatigue;
  final String technicalQuality;
  final String coachDecision;
  final String painSummary;
  final String observations;

  TrainingLogAnalysis({
    required this.date,
    required this.readiness,
    required this.soreness,
    required this.rpe,
    required this.neuralFatigue,
    required this.technicalQuality,
    required this.coachDecision,
    required this.painSummary,
    required this.observations,
  });
}

class TrainingAlert {
  final String title;
  final String description;
  final String severity;
  final DateTime detectedAt;

  TrainingAlert({
    required this.title,
    required this.description,
    required this.severity,
    required this.detectedAt,
  });
}

class TrainingLogHistoryService {
  static Future<List<DailyAthleteLog>> loadLogs(String athleteId) async {
    return DailyLogStorageService.loadLogs(athleteId);
  }

  static TrainingLogAnalysis parseLog(DailyAthleteLog log) {
    final painSummary =
        RegExp(r'Dolor: (.*?)(?= ·|$)').firstMatch(log.aiNotes)?.group(1) ?? '';

    final technicalQuality =
        RegExp(
          r'Calidad técnica: (.*?)(?= ·|$)',
        ).firstMatch(log.aiNotes)?.group(1) ??
        'Normal';

    return TrainingLogAnalysis(
      date: log.date,
      readiness: log.readiness,
      soreness: log.soreness,
      rpe: log.rpe,
      neuralFatigue: log.rpe,
      technicalQuality: technicalQuality,
      coachDecision: log.aiDecision.isNotEmpty
          ? log.aiDecision
          : 'No registrada',
      painSummary: painSummary,
      observations: log.aiNotes,
    );
  }

  static Future<List<TrainingAlert>> generateAlerts(String athleteId) async {
    final logs = await loadLogs(athleteId);
    final alerts = <TrainingAlert>[];

    if (logs.isEmpty) return alerts;

    final sorted = List<DailyAthleteLog>.from(logs)
      ..sort((a, b) => b.date.compareTo(a.date));

    final today = sorted.first;
    final recent3 = sorted.length > 3 ? sorted.sublist(0, 3) : sorted;
    final recent7 = sorted.length > 7 ? sorted.sublist(0, 7) : sorted;
    final recent14 = sorted.length > 14 ? sorted.sublist(0, 14) : sorted;

    _addTodayAlerts(alerts, today);
    _addShortTrendAlerts(alerts, recent3);
    _addWeeklyTrendAlerts(alerts, recent7);
    _addLongerPatternAlerts(alerts, recent14);

    return alerts;
  }

  static void _addTodayAlerts(
    List<TrainingAlert> alerts,
    DailyAthleteLog today,
  ) {
    if (today.readiness < 45) {
      alerts.add(
        TrainingAlert(
          title: '🔴 Readiness muy bajo hoy',
          description:
              'El readiness de hoy es ${today.readiness}. Revisar carga de mañana, priorizar recuperación y evitar intensidad alta si hay dolor o fatiga.',
          severity: 'critical',
          detectedAt: DateTime.now(),
        ),
      );
    } else if (today.readiness < 60) {
      alerts.add(
        TrainingAlert(
          title: '⚠️ Readiness bajo hoy',
          description:
              'El readiness de hoy está por debajo de 60. Conviene controlar la carga y observar respuesta antes de aumentar intensidad.',
          severity: 'warning',
          detectedAt: DateTime.now(),
        ),
      );
    }

    if (today.rpe >= 9) {
      alerts.add(
        TrainingAlert(
          title: '🔴 RPE muy alto hoy',
          description:
              'El atleta reportó RPE ${today.rpe}/10. La sesión fue percibida como muy exigente; revisar recuperación y carga del siguiente día.',
          severity: 'critical',
          detectedAt: DateTime.now(),
        ),
      );
    } else if (today.rpe >= 8) {
      alerts.add(
        TrainingAlert(
          title: '⚠️ RPE alto hoy',
          description:
              'El atleta reportó RPE ${today.rpe}/10. Monitorear fatiga neuromuscular y evitar acumular otra sesión intensa inmediatamente.',
          severity: 'warning',
          detectedAt: DateTime.now(),
        ),
      );
    }

    final kneePain = _extractPain(today.aiNotes, 'Rodilla');
    final lumbarPain = _extractPain(today.aiNotes, 'Lumbar');
    final anklePain = _extractPain(today.aiNotes, 'Tobillo');
    final adductorPain = _extractPain(today.aiNotes, 'Aductores');

    if (kneePain >= 6) {
      alerts.add(
        TrainingAlert(
          title: '⚠️ Dolor de rodilla alto hoy',
          description:
              'Rodilla reportada en $kneePain/10. Revisar pliometría, curvas, volumen de patines y ejercicios de fuerza con alta carga articular.',
          severity: 'warning',
          detectedAt: DateTime.now(),
        ),
      );
    }

    if (lumbarPain >= 6) {
      alerts.add(
        TrainingAlert(
          title: '⚠️ Dolor lumbar alto hoy',
          description:
              'Lumbar reportada en $lumbarPain/10. Cuidado con fuerza pesada, bisagras de cadera y trabajo prolongado en posición baja.',
          severity: 'warning',
          detectedAt: DateTime.now(),
        ),
      );
    }

    if (anklePain >= 6) {
      alerts.add(
        TrainingAlert(
          title: '⚠️ Dolor de tobillo alto hoy',
          description:
              'Tobillo reportado en $anklePain/10. Revisar saltos, aceleraciones, estabilidad y tolerancia tendinosa.',
          severity: 'warning',
          detectedAt: DateTime.now(),
        ),
      );
    }

    if (adductorPain >= 6) {
      alerts.add(
        TrainingAlert(
          title: '⚠️ Dolor de aductores alto hoy',
          description:
              'Aductores reportados en $adductorPain/10. Revisar empuje lateral, curvas, cambios de ritmo y cargas de velocidad.',
          severity: 'warning',
          detectedAt: DateTime.now(),
        ),
      );
    }

    if (today.aiNotes.contains('Calidad técnica: Mala')) {
      alerts.add(
        TrainingAlert(
          title: '⚠️ Técnica mala hoy',
          description:
              'El entrenador reportó calidad técnica mala. Puede indicar fatiga, rigidez o exceso de intensidad para el estado actual.',
          severity: 'warning',
          detectedAt: DateTime.now(),
        ),
      );
    }

    if (today.aiNotes.contains('Incidencia: Enfermedad')) {
      alerts.add(
        TrainingAlert(
          title: '🔴 Enfermedad reportada',
          description:
              'Hay una incidencia de enfermedad. Priorizar recuperación y evitar cargas intensas hasta confirmar buena respuesta.',
          severity: 'critical',
          detectedAt: DateTime.now(),
        ),
      );
    }
  }

  static void _addShortTrendAlerts(
    List<TrainingAlert> alerts,
    List<DailyAthleteLog> recent3,
  ) {
    if (recent3.length < 2) return;

    final lowReadiness = recent3.where((log) => log.readiness < 60).length;
    if (lowReadiness >= 2) {
      alerts.add(
        TrainingAlert(
          title: '⚠️ Readiness bajo repetido',
          description:
              'El readiness estuvo bajo en $lowReadiness de los últimos ${recent3.length} registros. Posible fatiga acumulada temprana.',
          severity: 'warning',
          detectedAt: DateTime.now(),
        ),
      );
    }

    final highRpe = recent3.where((log) => log.rpe >= 8).length;
    if (highRpe >= 2) {
      alerts.add(
        TrainingAlert(
          title: '⚠️ Alta exigencia repetida',
          description:
              'RPE ≥8 en $highRpe de los últimos ${recent3.length} registros. Evitar encadenar sesiones intensas sin recuperación suficiente.',
          severity: 'warning',
          detectedAt: DateTime.now(),
        ),
      );
    }

    final kneePainDays = recent3
        .where((log) => _extractPain(log.aiNotes, 'Rodilla') >= 4)
        .length;
    if (kneePainDays >= 2) {
      alerts.add(
        TrainingAlert(
          title: '⚠️ Rodilla sensible en registros recientes',
          description:
              'Dolor de rodilla ≥4/10 en $kneePainDays de los últimos ${recent3.length} registros. Reducir saltos agresivos y vigilar curvas.',
          severity: 'warning',
          detectedAt: DateTime.now(),
        ),
      );
    }
  }

  static void _addWeeklyTrendAlerts(
    List<TrainingAlert> alerts,
    List<DailyAthleteLog> recent7,
  ) {
    if (recent7.length < 3) return;

    final avgReadiness =
        recent7.fold<double>(0.0, (sum, log) => sum + log.readiness) /
        recent7.length;

    final avgRpe =
        recent7.fold<double>(0.0, (sum, log) => sum + log.rpe) / recent7.length;

    if (avgReadiness < 60) {
      alerts.add(
        TrainingAlert(
          title: '🔴 Readiness semanal bajo',
          description:
              'Promedio reciente de readiness: ${avgReadiness.toStringAsFixed(1)}. Considerar microdescarga o reducir intensidad.',
          severity: 'critical',
          detectedAt: DateTime.now(),
        ),
      );
    }

    if (avgRpe >= 7.5) {
      alerts.add(
        TrainingAlert(
          title: '⚠️ Carga interna alta',
          description:
              'Promedio reciente de RPE: ${avgRpe.toStringAsFixed(1)}/10. Revisar acumulación de intensidad y recuperación.',
          severity: 'warning',
          detectedAt: DateTime.now(),
        ),
      );
    }

    final poorTechnique = recent7.where((log) {
      return log.aiNotes.contains('Calidad técnica: Mala') ||
          log.aiNotes.contains('Calidad técnica: Regular');
    }).length;

    if (poorTechnique >= 3) {
      alerts.add(
        TrainingAlert(
          title: '⚠️ Técnica degradada recurrente',
          description:
              'Calidad técnica regular o mala en $poorTechnique registros recientes. Puede indicar fatiga o exceso de carga técnica bajo cansancio.',
          severity: 'warning',
          detectedAt: DateTime.now(),
        ),
      );
    }
  }

  static void _addLongerPatternAlerts(
    List<TrainingAlert> alerts,
    List<DailyAthleteLog> recent14,
  ) {
    if (recent14.length < 5) return;

    final kneePainDays = recent14
        .where((log) => _extractPain(log.aiNotes, 'Rodilla') >= 4)
        .length;

    if (kneePainDays >= 3) {
      alerts.add(
        TrainingAlert(
          title: '🔴 Dolor de rodilla recurrente',
          description:
              'Rodilla ≥4/10 en $kneePainDays registros recientes. Revisar carga de pliometría, curvas, fuerza de piernas y recuperación tendinosa.',
          severity: 'critical',
          detectedAt: DateTime.now(),
        ),
      );
    }

    final incidentDays = recent14.where((log) {
      return log.aiNotes.contains('Incidencia: Viaje') ||
          log.aiNotes.contains('Incidencia: Enfermedad') ||
          log.aiNotes.contains('Incidencia: Estrés alto');
    }).length;

    if (incidentDays >= 3) {
      alerts.add(
        TrainingAlert(
          title: '📋 Contexto externo elevado',
          description:
              'Hay $incidentDays registros con viaje, enfermedad o estrés alto. Ajustar expectativas de rendimiento y carga.',
          severity: 'info',
          detectedAt: DateTime.now(),
        ),
      );
    }
  }

  static Future<Map<String, dynamic>> getTrends(String athleteId) async {
    final logs = await loadLogs(athleteId);

    if (logs.isEmpty) {
      return {
        'readinessTrend': 0.0,
        'rpeTrend': 0.0,
        'avgReadiness': 0,
        'avgRpe': 0.0,
        'totalLogs': 0,
      };
    }

    final sorted = List<DailyAthleteLog>.from(logs)
      ..sort((a, b) => b.date.compareTo(a.date));

    final last7Days = sorted.length > 7 ? sorted.sublist(0, 7) : sorted;
    final previous7Days = sorted.length > 14 ? sorted.sublist(7, 14) : [];

    final avgReadinessLast7 =
        last7Days.fold<double>(0.0, (sum, log) => sum + log.readiness) /
        last7Days.length;

    final avgReadinessPrev7 = previous7Days.isNotEmpty
        ? previous7Days.fold<double>(0.0, (sum, log) => sum + log.readiness) /
              previous7Days.length
        : avgReadinessLast7;

    final avgRpeLast7 =
        last7Days.fold<double>(0.0, (sum, log) => sum + log.rpe) /
        last7Days.length;

    final avgRpePrev7 = previous7Days.isNotEmpty
        ? previous7Days.fold<double>(0.0, (sum, log) => sum + log.rpe) /
              previous7Days.length
        : avgRpeLast7;

    return {
      'readinessTrend': avgReadinessLast7 - avgReadinessPrev7,
      'rpeTrend': avgRpeLast7 - avgRpePrev7,
      'avgReadiness': avgReadinessLast7.round(),
      'avgRpe': avgRpeLast7,
      'totalLogs': logs.length,
    };
  }

  static int _extractPain(String notes, String area) {
    final match = RegExp('$area:\\s*(\\d+)').firstMatch(notes);

    if (match == null) return 0;

    return int.tryParse(match.group(1) ?? '0') ?? 0;
  }
}
