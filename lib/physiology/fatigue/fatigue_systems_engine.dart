import '../baseline/baseline_models.dart';
import '../data_quality/data_quality_layer.dart';

enum FatigueType { neural, muscular, tissueStress, cardiovascular, metabolic }

class FatigueChannel {
  final FatigueType type;
  final double score;
  final double confidence;
  final List<String> contributors;
  final Duration estimatedRecovery;
  final String recommendation;

  const FatigueChannel({
    required this.type,
    required this.score,
    required this.confidence,
    required this.contributors,
    required this.estimatedRecovery,
    required this.recommendation,
  });
}

class FatigueSystemsProfile {
  final FatigueChannel neural;
  final FatigueChannel muscular;
  final FatigueChannel tissueStress;
  final FatigueChannel cardiovascular;
  final FatigueChannel metabolic;
  final double overallScore;
  final double overallConfidence;
  final DateTime calculatedAt;

  const FatigueSystemsProfile({
    required this.neural,
    required this.muscular,
    required this.tissueStress,
    required this.cardiovascular,
    required this.metabolic,
    required this.overallScore,
    required this.overallConfidence,
    required this.calculatedAt,
  });
}

class FatigueSystemsEngine {
  static FatigueSystemsProfile calculate({
    required BaselineDataPoint today,
    required DynamicBaseline baseline,
    required DataQualityReport dataQuality,
    double gymLoad = 0,
    double skateKm = 0,
    int minutes = 0,
    int zone5Minutes = 0,
    int highIntensityMinutes = 0,
    int soreness = 0,
  }) {
    final neural = _neural(
      today: today,
      baseline: baseline,
      dataQuality: dataQuality,
      zone5Minutes: zone5Minutes,
      highIntensityMinutes: highIntensityMinutes,
    );

    final muscular = _muscular(
      gymLoad: gymLoad,
      minutes: minutes,
      soreness: soreness,
    );

    final tissueStress = _tissueStress(
      gymLoad: gymLoad,
      soreness: soreness,
      highIntensityMinutes: highIntensityMinutes,
    );

    final cardiovascular = _cardiovascular(
      today: today,
      baseline: baseline,
      dataQuality: dataQuality,
      minutes: minutes,
      skateKm: skateKm,
    );

    final metabolic = _metabolic(
      highIntensityMinutes: highIntensityMinutes,
      zone5Minutes: zone5Minutes,
      minutes: minutes,
      today: today,
    );

    final scores = [
      neural.score,
      muscular.score,
      tissueStress.score,
      cardiovascular.score,
      metabolic.score,
    ];

    final confidences = [
      neural.confidence,
      muscular.confidence,
      tissueStress.confidence,
      cardiovascular.confidence,
      metabolic.confidence,
    ];

    return FatigueSystemsProfile(
      neural: neural,
      muscular: muscular,
      tissueStress: tissueStress,
      cardiovascular: cardiovascular,
      metabolic: metabolic,
      overallScore: scores.reduce((a, b) => a + b) / scores.length,
      overallConfidence:
          confidences.reduce((a, b) => a + b) / confidences.length,
      calculatedAt: DateTime.now(),
    );
  }

  static FatigueChannel _neural({
    required BaselineDataPoint today,
    required DynamicBaseline baseline,
    required DataQualityReport dataQuality,
    required int zone5Minutes,
    required int highIntensityMinutes,
  }) {
    double score = 0;
    final contributors = <String>[];

    final hrvBaseline = baseline.hrv.value;

    if (today.hrv != null && hrvBaseline != null && hrvBaseline > 0) {
      final drop = (hrvBaseline - today.hrv!) / hrvBaseline;

      if (drop > 0.08) {
        score += 22;
        contributors.add('HRV por debajo del baseline');
      }

      if (drop > 0.18) {
        score += 18;
        contributors.add('Caída fuerte de HRV');
      }
    }

    if (zone5Minutes >= 10) {
      score += 20;
      contributors.add('Exposición Z5 elevada');
    }

    if (highIntensityMinutes >= 30) {
      score += 18;
      contributors.add('Alta intensidad acumulada');
    }

    if (today.sleepHours != null && today.sleepHours! < 6) {
      score += 15;
      contributors.add('Sueño bajo');
    }

    return FatigueChannel(
      type: FatigueType.neural,
      score: score.clamp(0, 100).toDouble(),
      confidence: dataQuality.confidence,
      contributors: contributors,
      estimatedRecovery: const Duration(hours: 24),
      recommendation: score >= 65
          ? 'Proteger sistema neural: evitar velocidad máxima, fuerza pesada y pliometría.'
          : 'Sistema neural dentro de rango manejable.',
    );
  }

  static FatigueChannel _muscular({
    required double gymLoad,
    required int minutes,
    required int soreness,
  }) {
    double score = 0;
    final contributors = <String>[];

    if (gymLoad > 6000) {
      score += 25;
      contributors.add('Carga de gimnasio alta');
    }

    if (minutes > 100) {
      score += 15;
      contributors.add('Duración alta');
    }

    if (soreness >= 6) {
      score += 25;
      contributors.add('Soreness elevado');
    }

    return FatigueChannel(
      type: FatigueType.muscular,
      score: score.clamp(0, 100).toDouble(),
      confidence: soreness > 0 || gymLoad > 0 ? 0.75 : 0.35,
      contributors: contributors,
      estimatedRecovery: const Duration(hours: 48),
      recommendation: score >= 65
          ? 'Reducir fuerza, volumen y cargas excéntricas.'
          : 'Fatiga muscular manejable.',
    );
  }

  static FatigueChannel _tissueStress({
    required double gymLoad,
    required int soreness,
    required int highIntensityMinutes,
  }) {
    double score = 0;
    final contributors = <String>[];

    if (gymLoad > 8000) {
      score += 20;
      contributors.add('Carga mecánica alta');
    }

    if (highIntensityMinutes > 35) {
      score += 20;
      contributors.add('Muchos minutos intensos');
    }

    if (soreness >= 7) {
      score += 30;
      contributors.add('Dolor/soreness alto');
    }

    return FatigueChannel(
      type: FatigueType.tissueStress,
      score: score.clamp(0, 100).toDouble(),
      confidence: soreness > 0 || gymLoad > 0 ? 0.70 : 0.30,
      contributors: contributors,
      estimatedRecovery: const Duration(days: 5),
      recommendation: score >= 60
          ? 'Proteger tejido: reducir saltos, curvas fuertes, pliometría y fuerza explosiva.'
          : 'Estrés de tejido controlado.',
    );
  }

  static FatigueChannel _cardiovascular({
    required BaselineDataPoint today,
    required DynamicBaseline baseline,
    required DataQualityReport dataQuality,
    required int minutes,
    required double skateKm,
  }) {
    double score = 0;
    final contributors = <String>[];

    final rhrBaseline = baseline.restingHeartRate.value;

    if (today.restingHeartRate != null &&
        rhrBaseline != null &&
        rhrBaseline > 0) {
      final increase = today.restingHeartRate! - rhrBaseline;

      if (increase >= 6) {
        score += 25;
        contributors.add('FC reposo elevada');
      }

      if (increase >= 10) {
        score += 15;
        contributors.add('FC reposo muy elevada');
      }
    }

    if (today.stress != null && today.stress! > 65) {
      score += 18;
      contributors.add('Estrés alto');
    }

    if (minutes > 100 || skateKm > 18) {
      score += 16;
      contributors.add('Carga cardiovascular alta');
    }

    return FatigueChannel(
      type: FatigueType.cardiovascular,
      score: score.clamp(0, 100).toDouble(),
      confidence: dataQuality.confidence,
      contributors: contributors,
      estimatedRecovery: const Duration(hours: 36),
      recommendation: score >= 65
          ? 'Reducir carga cardiovascular y priorizar recuperación aeróbica suave.'
          : 'Sistema cardiovascular manejable.',
    );
  }

  static FatigueChannel _metabolic({
    required int highIntensityMinutes,
    required int zone5Minutes,
    required int minutes,
    required BaselineDataPoint today,
  }) {
    double score = 0;
    final contributors = <String>[];

    if (highIntensityMinutes >= 25) {
      score += 25;
      contributors.add('Alta carga Z4/Z5');
    }

    if (zone5Minutes >= 8) {
      score += 25;
      contributors.add('Z5 significativa');
    }

    if (minutes > 110) {
      score += 12;
      contributors.add('Duración prolongada');
    }

    if (today.sleepHours != null && today.sleepHours! < 6) {
      score += 12;
      contributors.add('Recuperación energética limitada por sueño bajo');
    }

    return FatigueChannel(
      type: FatigueType.metabolic,
      score: score.clamp(0, 100).toDouble(),
      confidence: 0.65,
      contributors: contributors,
      estimatedRecovery: const Duration(hours: 24),
      recommendation: score >= 65
          ? 'Evitar lactato pesado y nueva carga Z4/Z5.'
          : 'Carga metabólica controlada.',
    );
  }
}
