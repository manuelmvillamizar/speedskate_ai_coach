import '../../fatigue_engine.dart';
import '../baseline/baseline_models.dart';
import '../data_quality/data_quality_layer.dart';
import '../fatigue/fatigue_systems_engine.dart';

class HybridReadinessResult {
  final int score;
  final int baseScore;
  final int adjustment;
  final double confidence;
  final List<String> factors;

  const HybridReadinessResult({
    required this.score,
    required this.baseScore,
    required this.adjustment,
    required this.confidence,
    required this.factors,
  });
}

class HybridReadinessEngine {
  static HybridReadinessResult calculate({
    required double gymLoad,
    required double skateKm,
    required int minutes,
    required BaselineDataPoint today,
    required DynamicBaseline baseline,
    required DataQualityReport dataQuality,
    FatigueSystemsProfile? fatigueSystems,
    int soreness = 0,
  }) {
    final baseScore = FatigueEngine.readinessScore(
      gymLoad: gymLoad,
      skateKm: skateKm,
      minutes: minutes,
      sleepHours: today.sleepHours?.round() ?? 0,
      stress: today.stress ?? 0,
      hrv: today.hrv?.round() ?? 0,
      normalHrv: baseline.hrv.value?.round() ?? 0,
      restingHeartRate: today.restingHeartRate ?? 0,
      normalRestingHeartRate: baseline.restingHeartRate.value?.round() ?? 0,
      soreness: soreness,
    );

    int adjustment = 0;
    final factors = <String>[];

    if (dataQuality.canAdaptTraining) {
      if (baseline.hrv.trendNormalized > 0.05) {
        adjustment += 4;
        factors.add('HRV con tendencia positiva');
      }

      if (baseline.hrv.trendNormalized < -0.08) {
        adjustment -= 6;
        factors.add('HRV con tendencia negativa');
      }

      if (baseline.sleepHours.trendNormalized > 0.04) {
        adjustment += 3;
        factors.add('Sueño mejorando');
      }

      if (baseline.sleepHours.trendNormalized < -0.06) {
        adjustment -= 5;
        factors.add('Sueño empeorando');
      }

      if (baseline.stress.trendNormalized > 0.08) {
        adjustment -= 5;
        factors.add('Estrés en aumento');
      }
    } else {
      factors.add('Calidad de datos insuficiente: ajuste adaptativo limitado');
    }

    if (fatigueSystems != null && fatigueSystems.overallConfidence >= 0.45) {
      if (fatigueSystems.neural.score >= 70) {
        adjustment -= 8;
        factors.add('Fatiga neural alta');
      }

      if (fatigueSystems.tissueStress.score >= 65) {
        adjustment -= 7;
        factors.add('Estrés de tejido alto');
      }

      if (fatigueSystems.metabolic.score >= 70) {
        adjustment -= 6;
        factors.add('Fatiga metabólica alta');
      }
    }

    final finalScore = (baseScore + adjustment).clamp(0, 100).round();

    return HybridReadinessResult(
      score: finalScore,
      baseScore: baseScore,
      adjustment: adjustment,
      confidence: dataQuality.confidence,
      factors: factors,
    );
  }
}
