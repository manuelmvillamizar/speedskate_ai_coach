// lib/physiology_sports_translator.dart

import 'package:flutter/material.dart';

class SportsMetricInterpretation {
  final String title;
  final String technicalName;
  final String status;
  final String explanation;
  final String severity;

  const SportsMetricInterpretation({
    required this.title,
    required this.technicalName,
    required this.status,
    required this.explanation,
    required this.severity,
  });

  Color get severityColor {
    switch (severity) {
      case 'critical':
        return const Color(0xFFDC2626);
      case 'warning':
        return const Color(0xFFF59E0B);
      case 'good':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData get severityIcon {
    switch (severity) {
      case 'critical':
        return Icons.warning_amber;
      case 'warning':
        return Icons.info_outline;
      case 'good':
        return Icons.check_circle;
      default:
        return Icons.circle_outlined;
    }
  }
}

class PhysiologySportsTranslator {
  static SportsMetricInterpretation translateReadiness(int readiness) {
    if (readiness >= 85) {
      return const SportsMetricInterpretation(
        title: 'Disponibilidad para entrenar',
        technicalName: 'internal_availability',
        status: 'Muy alta 🟢',
        explanation:
            'Buen día para trabajos de calidad, velocidad o intensidad si el plan lo permite.',
        severity: 'good',
      );
    }

    if (readiness >= 75) {
      return const SportsMetricInterpretation(
        title: 'Disponibilidad para entrenar',
        technicalName: 'internal_availability',
        status: 'Buena 🟢',
        explanation:
            'El atleta está en condiciones de entrenar bien. Mantener foco en calidad técnica.',
        severity: 'good',
      );
    }

    if (readiness >= 65) {
      return const SportsMetricInterpretation(
        title: 'Disponibilidad para entrenar',
        technicalName: 'internal_availability',
        status: 'Moderada 🟡',
        explanation:
            'Puede entrenar, pero conviene evitar subir demasiado la carga del día.',
        severity: 'warning',
      );
    }

    if (readiness >= 50) {
      return const SportsMetricInterpretation(
        title: 'Disponibilidad para entrenar',
        technicalName: 'internal_availability',
        status: 'Limitada 🟠',
        explanation:
            'Mejor controlar intensidad, cuidar técnica y no forzar trabajos máximos.',
        severity: 'warning',
      );
    }

    return const SportsMetricInterpretation(
      title: 'Disponibilidad para entrenar',
      technicalName: 'internal_availability',
      status: 'Baja 🔴',
      explanation:
          'Señal de cautela. Priorizar recuperación, movilidad o trabajo técnico suave.',
      severity: 'critical',
    );
  }

  static SportsMetricInterpretation translateHrv(
    double hrv,
    double baselineHrv,
  ) {
    if (hrv >= baselineHrv * 1.05) {
      return const SportsMetricInterpretation(
        title: 'Recuperación',
        technicalName: 'internal_recovery_signal',
        status: 'Muy buena 🟢',
        explanation:
            'El atleta muestra buena recuperación. Puede tolerar estímulos exigentes si el plan lo pide.',
        severity: 'good',
      );
    }

    if (hrv >= baselineHrv * 0.95) {
      return const SportsMetricInterpretation(
        title: 'Recuperación',
        technicalName: 'internal_recovery_signal',
        status: 'Estable 🟢',
        explanation:
            'Recuperación adecuada. Puede sostener una sesión normal con buena calidad.',
        severity: 'good',
      );
    }

    if (hrv >= baselineHrv * 0.85) {
      return const SportsMetricInterpretation(
        title: 'Recuperación',
        technicalName: 'internal_recovery_signal',
        status: 'En observación 🟡',
        explanation:
            'Hay señales de fatiga. Conviene cuidar la velocidad, los saltos y la fuerza pesada.',
        severity: 'warning',
      );
    }

    return const SportsMetricInterpretation(
      title: 'Recuperación',
      technicalName: 'internal_recovery_signal',
      status: 'Incompleta 🔴',
      explanation:
          'El atleta no parece recuperar bien. Mejor proteger potencia, velocidad máxima y carga neural.',
      severity: 'critical',
    );
  }

  static SportsMetricInterpretation translateSleep(double hours) {
    if (hours >= 8.5) {
      return const SportsMetricInterpretation(
        title: 'Descanso',
        technicalName: 'internal_sleep_signal',
        status: 'Excelente 🟢',
        explanation:
            'Buen descanso. Puede favorecer sesiones de calidad y buena asimilación.',
        severity: 'good',
      );
    }

    if (hours >= 7.5) {
      return const SportsMetricInterpretation(
        title: 'Descanso',
        technicalName: 'internal_sleep_signal',
        status: 'Bueno 🟢',
        explanation: 'Descanso suficiente para sostener entrenamiento normal.',
        severity: 'good',
      );
    }

    if (hours >= 6.5) {
      return const SportsMetricInterpretation(
        title: 'Descanso',
        technicalName: 'internal_sleep_signal',
        status: 'Justo 🟡',
        explanation:
            'Descanso mínimo. Evitar convertir el día en una sesión demasiado agresiva.',
        severity: 'warning',
      );
    }

    return const SportsMetricInterpretation(
      title: 'Descanso',
      technicalName: 'internal_sleep_signal',
      status: 'Insuficiente 🔴',
      explanation:
          'El atleta descansó poco. Priorizar recuperación, técnica limpia o carga controlada.',
      severity: 'critical',
    );
  }

  static SportsMetricInterpretation translateRpe(int rpe) {
    if (rpe <= 0) {
      return const SportsMetricInterpretation(
        title: 'Sensación del atleta',
        technicalName: 'internal_effort_signal',
        status: 'Sin registro',
        explanation:
            'Cuando el entrenador registre la sensación del atleta, la app podrá interpretar mejor la respuesta.',
        severity: 'normal',
      );
    }

    if (rpe <= 4) {
      return const SportsMetricInterpretation(
        title: 'Sensación del atleta',
        technicalName: 'internal_effort_signal',
        status: 'Ligera 🟢',
        explanation:
            'El atleta percibe poca carga. Buena señal para sostener progresión si la técnica está bien.',
        severity: 'good',
      );
    }

    if (rpe <= 6) {
      return const SportsMetricInterpretation(
        title: 'Sensación del atleta',
        technicalName: 'internal_effort_signal',
        status: 'Normal 🟢',
        explanation:
            'Esfuerzo esperado. Mantener control técnico y observar respuesta posterior.',
        severity: 'good',
      );
    }

    if (rpe <= 8) {
      return const SportsMetricInterpretation(
        title: 'Sensación del atleta',
        technicalName: 'internal_effort_signal',
        status: 'Pesada 🟡',
        explanation:
            'El atleta sintió una sesión exigente. Evitar acumular otro día fuerte sin revisar recuperación.',
        severity: 'warning',
      );
    }

    return const SportsMetricInterpretation(
      title: 'Sensación del atleta',
      technicalName: 'internal_effort_signal',
      status: 'Muy pesada 🔴',
      explanation:
          'Señal de carga alta. Conviene proteger saltos, velocidad máxima y fuerza pesada.',
      severity: 'critical',
    );
  }

  static SportsMetricInterpretation translateSoreness(int soreness) {
    if (soreness <= 2) {
      return const SportsMetricInterpretation(
        title: 'Molestias musculares',
        technicalName: 'internal_soreness_signal',
        status: 'Sin molestias 🟢',
        explanation: 'El atleta muestra buena recuperación muscular.',
        severity: 'good',
      );
    }

    if (soreness <= 4) {
      return const SportsMetricInterpretation(
        title: 'Molestias musculares',
        technicalName: 'internal_soreness_signal',
        status: 'Leves 🟢',
        explanation:
            'Molestias controladas. Puede entrenar, cuidando calidad de movimiento.',
        severity: 'good',
      );
    }

    if (soreness <= 6) {
      return const SportsMetricInterpretation(
        title: 'Molestias musculares',
        technicalName: 'internal_soreness_signal',
        status: 'Moderadas 🟡',
        explanation:
            'Conviene evitar fuerza pesada, saltos agresivos o intensidad máxima si la técnica cae.',
        severity: 'warning',
      );
    }

    return const SportsMetricInterpretation(
      title: 'Molestias musculares',
      technicalName: 'internal_soreness_signal',
      status: 'Altas 🔴',
      explanation:
          'Priorizar recuperación, movilidad y técnica suave antes de volver a cargar fuerte.',
      severity: 'critical',
    );
  }

  static SportsMetricInterpretation translateTrainingLoad(
    double load,
    double maxLoad,
  ) {
    final ratio = maxLoad > 0 ? load / maxLoad : 0.5;

    if (ratio <= 0.5) {
      return const SportsMetricInterpretation(
        title: 'Exigencia del día',
        technicalName: 'internal_load_signal',
        status: 'Ligera 🟢',
        explanation:
            'Día controlado. Puede servir para construir base o recuperar sin perder continuidad.',
        severity: 'good',
      );
    }

    if (ratio <= 0.85) {
      return const SportsMetricInterpretation(
        title: 'Exigencia del día',
        technicalName: 'internal_load_signal',
        status: 'Normal 🟢',
        explanation:
            'Carga adecuada. Mantener calidad y observar cómo responde el atleta.',
        severity: 'good',
      );
    }

    if (ratio <= 1.1) {
      return const SportsMetricInterpretation(
        title: 'Exigencia del día',
        technicalName: 'internal_load_signal',
        status: 'Alta 🟡',
        explanation:
            'Día exigente. Conviene revisar recuperación antes del siguiente estímulo fuerte.',
        severity: 'warning',
      );
    }

    return const SportsMetricInterpretation(
      title: 'Exigencia del día',
      technicalName: 'internal_load_signal',
      status: 'Muy alta 🔴',
      explanation:
          'Carga muy agresiva. Usarla solo si el entrenador busca sobrecarga estratégica y luego controlar recuperación.',
      severity: 'critical',
    );
  }
}
