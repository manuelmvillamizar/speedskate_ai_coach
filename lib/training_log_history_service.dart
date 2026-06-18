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
      neuralFatigue: log.neuralStress.round(),
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

    if (logs.isEmpty) {
      alerts.add(
        TrainingAlert(
          title: 'ℹ️ Sin registros del entrenador',
          description:
              'La IA puede usar datos fisiológicos y wearable, pero los avisos serán más precisos cuando exista registro en “¿Cómo fue?”.',
          severity: 'info',
          detectedAt: DateTime.now(),
        ),
      );

      return alerts;
    }

    final sorted = List<DailyAthleteLog>.from(logs)
      ..sort((a, b) => b.date.compareTo(a.date));

    final today = sorted.first;
    final recent3 = sorted.length > 3 ? sorted.sublist(0, 3) : sorted;
    final recent7 = sorted.length > 7 ? sorted.sublist(0, 7) : sorted;
    final recent14 = sorted.length > 14 ? sorted.sublist(0, 14) : sorted;

    _addTodayAlerts(alerts, today);
    _addHiddenPhysiologyAlerts(alerts, today);
    _addShortTrendAlerts(alerts, recent3);
    _addWeeklyTrendAlerts(alerts, recent7);
    _addHiddenTrendAlerts(alerts, recent7);
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
          title: '🔴 Disponibilidad muy baja hoy',
          description:
              'La disponibilidad de hoy es ${today.readiness}. Priorizar recuperación y evitar intensidad alta si hay dolor o fatiga.',
          severity: 'critical',
          detectedAt: DateTime.now(),
        ),
      );
    } else if (today.readiness < 60) {
      alerts.add(
        TrainingAlert(
          title: '⚠️ Disponibilidad baja hoy',
          description:
              'La disponibilidad está por debajo de 60. Conviene controlar la carga y observar respuesta antes de aumentar intensidad.',
          severity: 'warning',
          detectedAt: DateTime.now(),
        ),
      );
    }

    if (today.rpe >= 9) {
      alerts.add(
        TrainingAlert(
          title: '🔴 Esfuerzo muy alto hoy',
          description:
              'El atleta reportó esfuerzo ${today.rpe}/10. Revisar recuperación y carga del siguiente día.',
          severity: 'critical',
          detectedAt: DateTime.now(),
        ),
      );
    } else if (today.rpe >= 8) {
      alerts.add(
        TrainingAlert(
          title: '⚠️ Esfuerzo alto hoy',
          description:
              'El atleta reportó esfuerzo ${today.rpe}/10. Evitar acumular otra sesión intensa inmediatamente.',
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
              'Rodilla reportada en $kneePain/10. Revisar pliometría, curvas, volumen de patines y fuerza con alta carga articular.',
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
              'Lumbar reportada en $lumbarPain/10. Cuidado con fuerza pesada y trabajo prolongado en posición baja.',
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
              'Aductores reportados en $adductorPain/10. Revisar empuje lateral, curvas, cambios de ritmo y velocidad.',
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
              'El entrenador reportó técnica mala. Puede indicar fatiga, rigidez o exceso de intensidad para el estado actual.',
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

  static void _addHiddenPhysiologyAlerts(
    List<TrainingAlert> alerts,
    DailyAthleteLog today,
  ) {
    if (today.recoveryCost >= 85 || today.hiddenBodyStress >= 85) {
      alerts.add(
        TrainingAlert(
          title: '🔴 Recuperación comprometida',
          description:
              'La sesión dejó un coste interno alto. Conviene priorizar descarga, movilidad o trabajo técnico suave antes de volver a exigir.',
          severity: 'critical',
          detectedAt: DateTime.now(),
        ),
      );
    } else if (today.recoveryCost >= 70 || today.hiddenBodyStress >= 70) {
      alerts.add(
        TrainingAlert(
          title: '⚠️ Carga interna elevada',
          description:
              'La app detectó que el entrenamiento fue más costoso de lo que parece por distancia o duración. Controlar la próxima carga.',
          severity: 'warning',
          detectedAt: DateTime.now(),
        ),
      );
    }

    if (today.neuralStress >= 80 || today.intermittentStress >= 80) {
      alerts.add(
        TrainingAlert(
          title: '⚠️ Fatiga neuromuscular elevada',
          description:
              'Evitar velocidad máxima, salidas explosivas o cambios de ritmo fuertes hasta recuperar frescura.',
          severity: 'warning',
          detectedAt: DateTime.now(),
        ),
      );
    }

    if (today.mechanicalStress >= 80 ||
        today.tendonStress >= 80 ||
        today.terrainStress >= 80) {
      alerts.add(
        TrainingAlert(
          title: '⚠️ Estrés mecánico alto',
          description:
              'Proteger tendones, fuerza pesada, saltos, curvas exigentes y pliometría durante la próxima carga.',
          severity: 'warning',
          detectedAt: DateTime.now(),
        ),
      );
    }

    if (today.technicalStress >= 75 && today.coordinationStress >= 70) {
      alerts.add(
        TrainingAlert(
          title: '⚠️ Técnica bajo fatiga',
          description:
              'La sesión tuvo alta exigencia técnica y coordinativa. Mantener técnica limpia antes de aumentar intensidad.',
          severity: 'warning',
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
          title: '⚠️ Disponibilidad baja repetida',
          description:
              'La disponibilidad estuvo baja en $lowReadiness de los últimos ${recent3.length} registros. Posible fatiga acumulada temprana.',
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
              'Esfuerzo ≥8 en $highRpe de los últimos ${recent3.length} registros. Evitar encadenar sesiones intensas sin recuperación suficiente.',
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
          title: '🔴 Disponibilidad semanal baja',
          description:
              'Promedio reciente de disponibilidad: ${avgReadiness.toStringAsFixed(1)}. Considerar microdescarga o reducir intensidad.',
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
              'Promedio reciente de esfuerzo: ${avgRpe.toStringAsFixed(1)}/10. Revisar acumulación de intensidad y recuperación.',
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
              'Técnica regular o mala en $poorTechnique registros recientes. Puede indicar fatiga o exceso de carga técnica bajo cansancio.',
          severity: 'warning',
          detectedAt: DateTime.now(),
        ),
      );
    }
  }

  static void _addHiddenTrendAlerts(
    List<TrainingAlert> alerts,
    List<DailyAthleteLog> recent7,
  ) {
    if (recent7.length < 3) return;

    final avgRecoveryCost = _avg(recent7, (log) => log.recoveryCost);
    final avgNeuralStress = _avg(recent7, (log) => log.neuralStress);
    final avgMechanicalStress = _avg(recent7, (log) => log.mechanicalStress);
    final avgTendonStress = _avg(recent7, (log) => log.tendonStress);
    final avgHiddenStress = _avg(recent7, (log) => log.hiddenBodyStress);

    if (avgRecoveryCost >= 70 || avgHiddenStress >= 70) {
      alerts.add(
        TrainingAlert(
          title: '⚠️ Recuperación en observación',
          description:
              'Los últimos registros muestran coste interno acumulado. Conviene no subir carga hasta ver mejor respuesta.',
          severity: 'warning',
          detectedAt: DateTime.now(),
        ),
      );
    }

    if (avgNeuralStress >= 70) {
      alerts.add(
        TrainingAlert(
          title: '⚠️ Carga neural acumulada',
          description:
              'La semana reciente acumula estímulos rápidos o intermitentes. Evitar encadenar salidas, velocidad máxima o Z5 sin recuperación.',
          severity: 'warning',
          detectedAt: DateTime.now(),
        ),
      );
    }

    if (avgMechanicalStress >= 70 || avgTendonStress >= 70) {
      alerts.add(
        TrainingAlert(
          title: '⚠️ Carga mecánica acumulada',
          description:
              'Vigilar tendones y articulaciones. Controlar curvas, saltos, fuerza pesada y volumen sobre patines.',
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
              'Rodilla ≥4/10 en $kneePainDays registros recientes. Revisar pliometría, curvas, fuerza de piernas y recuperación tendinosa.',
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

  static double _avg(
    List<DailyAthleteLog> logs,
    double Function(DailyAthleteLog log) pick,
  ) {
    if (logs.isEmpty) return 0;

    return logs.fold<double>(0, (sum, log) => sum + pick(log)) / logs.length;
  }
}
