import '../baseline/baseline_models.dart';

class DataQualityReport {
  final bool hasEnoughData;
  final bool canLearn;
  final bool canAdaptTraining;
  final double confidence;
  final double completeness;
  final int validDays;
  final List<String> missingMetrics;
  final String recommendation;

  const DataQualityReport({
    required this.hasEnoughData,
    required this.canLearn,
    required this.canAdaptTraining,
    required this.confidence,
    required this.completeness,
    required this.validDays,
    required this.missingMetrics,
    required this.recommendation,
  });
}

class DataQualityLayer {
  static DataQualityReport evaluateBaseline(DynamicBaseline baseline) {
    final missing = <String>[];

    void check(BaselineMetric metric, String label) {
      if (!metric.hasEnoughData || metric.confidence < 0.45) {
        missing.add(label);
      }
    }

    check(baseline.hrv, 'HRV');
    check(baseline.sleepHours, 'sueño');
    check(baseline.restingHeartRate, 'FC reposo');
    check(baseline.stress, 'estrés');

    final hasEnoughData =
        baseline.validDays >= 5 &&
        baseline.confidence >= 0.45 &&
        baseline.completeness >= 0.35;

    final canLearn =
        baseline.validDays >= 7 &&
        baseline.confidence >= 0.55 &&
        baseline.hrv.confidence >= 0.45 &&
        baseline.sleepHours.confidence >= 0.45;

    final canAdaptTraining =
        baseline.confidence >= 0.40 &&
        baseline.validDays >= 5 &&
        baseline.completeness >= 0.30;

    String recommendation;

    if (canLearn) {
      recommendation =
          'Datos suficientes para aprendizaje fisiológico longitudinal.';
    } else if (canAdaptTraining) {
      recommendation =
          'Datos suficientes para ajustar entrenamiento con precaución, pero no para aprendizaje fuerte.';
    } else {
      recommendation =
          'Datos insuficientes: no aprender patrones fisiológicos todavía.';
    }

    return DataQualityReport(
      hasEnoughData: hasEnoughData,
      canLearn: canLearn,
      canAdaptTraining: canAdaptTraining,
      confidence: baseline.confidence,
      completeness: baseline.completeness,
      validDays: baseline.validDays,
      missingMetrics: missing,
      recommendation: recommendation,
    );
  }
}
