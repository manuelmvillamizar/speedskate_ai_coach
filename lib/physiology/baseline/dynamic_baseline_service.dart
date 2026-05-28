import 'dart:math' as math;

import 'baseline_models.dart';

class DynamicBaselineService {
  static const String currentVersion = '1.0.0';

  static DynamicBaseline calculate({
    required List<BaselineDataPoint> history,
    required BaselineWindow window,
    BaselineValidationRules rules = BaselineValidationRules.defaultRules,
  }) {
    final now = DateTime.now();
    final windowDays = _windowDays(window);
    final cutoff = now.subtract(Duration(days: windowDays));

    final windowData =
        history.where((item) => !item.date.isBefore(cutoff)).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    final validData = windowData.where((item) {
      if (!item.isValidForBaseline) return false;
      if (item.hasSleepHours && item.sleepHours! < rules.minSleepHours) {
        return false;
      }
      if (item.hasStress && item.stress! > rules.maxStress) {
        return false;
      }
      return true;
    }).toList();

    final excludedData = windowData.where((item) {
      return !validData.contains(item);
    }).toList();

    final weights = _weights(validData, rules.recencyDecayRate);
    final coverage = _coverage(validData);

    final hrv = _metric(validData, weights, (item) => item.hrv);
    final restingHeartRate = _metric(
      validData,
      weights,
      (item) => item.restingHeartRate?.toDouble(),
    );
    final sleepHours = _metric(validData, weights, (item) => item.sleepHours);
    final stress = _metric(
      validData,
      weights,
      (item) => item.stress?.toDouble(),
    );
    final bodyBattery = _metric(
      validData,
      weights,
      (item) => item.bodyBattery?.toDouble(),
    );

    final globalStats = _globalStats(validData, weights);

    final completeness = windowDays == 0 ? 0.0 : validData.length / windowDays;

    final stability = (1.0 - (globalStats.coefficientOfVariation / 0.3)).clamp(
      0.0,
      1.0,
    );

    final confidence = _confidence(
      validDays: validData.length,
      expectedDays: windowDays,
      coefficientOfVariation: globalStats.coefficientOfVariation,
      dataCoverage: coverage,
    );

    return DynamicBaseline(
      window: window,
      calculatedAt: now,
      baselineVersion: currentVersion,
      globalMean: globalStats.mean,
      globalStdDev: globalStats.stdDev,
      globalCoefficientOfVariation: globalStats.coefficientOfVariation,
      globalTrendNormalized: globalStats.trendNormalized,
      confidence: confidence,
      validDays: validData.length,
      excludedDays: excludedData.length,
      missingDays: math.max(
        0,
        windowDays - validData.length - excludedData.length,
      ),
      completeness: completeness.clamp(0.0, 1.0),
      stability: stability.toDouble(),
      dataCoverage: coverage,
      hrv: hrv,
      restingHeartRate: restingHeartRate,
      sleepHours: sleepHours,
      stress: stress,
      bodyBattery: bodyBattery,
      totalDaysConsidered: windowData.length,
      daysWithWearableData: windowData
          .where((item) => item.hasValidWearableData)
          .length,
      topExclusionReasons: _topExclusionReasons(excludedData),
    );
  }

  static int _windowDays(BaselineWindow window) {
    switch (window) {
      case BaselineWindow.shortTerm:
        return 7;
      case BaselineWindow.mediumTerm:
        return 28;
      case BaselineWindow.longTerm:
        return 90;
    }
  }

  static List<double> _weights(List<BaselineDataPoint> data, double decayRate) {
    if (data.isEmpty) return [];

    final now = DateTime.now();
    final raw = data.map((point) {
      final daysAgo = now.difference(point.date).inDays;
      return math.pow(1 - decayRate, daysAgo).toDouble();
    }).toList();

    final sum = raw.fold<double>(0, (a, b) => a + b);
    if (sum <= 0) return List.filled(data.length, 1.0 / data.length);

    return raw.map((value) => value / sum).toList();
  }

  static Map<BaselineMetricType, double> _coverage(
    List<BaselineDataPoint> data,
  ) {
    if (data.isEmpty) {
      return {
        BaselineMetricType.hrv: 0,
        BaselineMetricType.restingHeartRate: 0,
        BaselineMetricType.sleepHours: 0,
        BaselineMetricType.stress: 0,
        BaselineMetricType.bodyBattery: 0,
      };
    }

    final total = data.length;

    double ratio(bool Function(BaselineDataPoint item) test) {
      return data.where(test).length / total;
    }

    return {
      BaselineMetricType.hrv: ratio((item) => item.hasHrv),
      BaselineMetricType.restingHeartRate: ratio(
        (item) => item.hasRestingHeartRate,
      ),
      BaselineMetricType.sleepHours: ratio((item) => item.hasSleepHours),
      BaselineMetricType.stress: ratio((item) => item.hasStress),
      BaselineMetricType.bodyBattery: ratio((item) => item.hasBodyBattery),
    };
  }

  static BaselineMetric _metric(
    List<BaselineDataPoint> data,
    List<double> weights,
    double? Function(BaselineDataPoint item) extractor,
  ) {
    final values = <double>[];
    final metricWeights = <double>[];

    for (var i = 0; i < data.length; i++) {
      final value = extractor(data[i]);
      if (value != null && value > 0) {
        values.add(value);
        metricWeights.add(weights[i]);
      }
    }

    if (values.isEmpty) return BaselineMetric.insufficient();

    final weightSum = metricWeights.fold<double>(0, (a, b) => a + b);
    final normalizedWeights = weightSum <= 0
        ? List.filled(values.length, 1.0 / values.length)
        : metricWeights.map((value) => value / weightSum).toList();

    double weightedMean = 0;
    for (var i = 0; i < values.length; i++) {
      weightedMean += values[i] * normalizedWeights[i];
    }

    final mean = values.fold<double>(0, (a, b) => a + b) / values.length;
    final variance =
        values
            .map((value) => math.pow(value - mean, 2).toDouble())
            .fold<double>(0, (a, b) => a + b) /
        values.length;

    final stdDev = math.sqrt(variance);
    final volatility = mean > 0 ? stdDev / mean : 0.0;
    final trend = _trendNormalized(values);
    final sampleSize = values.length;
    final hasEnoughData = sampleSize >= 5;

    double confidence = 0.25;
    if (sampleSize >= 14) {
      confidence += 0.4;
    } else if (sampleSize >= 7) {
      confidence += 0.25;
    } else if (sampleSize >= 5) {
      confidence += 0.15;
    }

    if (volatility < 0.15) confidence += 0.25;
    if (volatility > 0.30) confidence -= 0.15;
    if (volatility > 0.45) confidence -= 0.20;

    return BaselineMetric(
      value: weightedMean,
      confidence: confidence.clamp(0.0, 1.0),
      hasEnoughData: hasEnoughData,
      trendNormalized: trend,
      volatility: volatility,
      sampleSize: sampleSize,
    );
  }

  static double _trendNormalized(List<double> values) {
    if (values.length < 2) return 0;

    final n = values.length;
    final xs = List.generate(n, (index) => index.toDouble());

    final sumX = xs.fold<double>(0, (a, b) => a + b);
    final sumY = values.fold<double>(0, (a, b) => a + b);
    final sumXY = List.generate(
      n,
      (i) => xs[i] * values[i],
    ).fold<double>(0, (a, b) => a + b);
    final sumX2 = xs.map((x) => x * x).fold<double>(0, (a, b) => a + b);

    final denominator = n * sumX2 - sumX * sumX;
    if (denominator == 0) return 0;

    final slope = (n * sumXY - sumX * sumY) / denominator;
    final meanY = sumY / n;

    return meanY == 0 ? 0 : slope / meanY;
  }

  static _GlobalStats _globalStats(
    List<BaselineDataPoint> data,
    List<double> weights,
  ) {
    if (data.isEmpty || weights.isEmpty) {
      return const _GlobalStats(
        mean: 0,
        stdDev: 0,
        coefficientOfVariation: 0,
        trendNormalized: 0,
      );
    }

    final scores = <double>[];
    final scoreWeights = <double>[];

    for (var i = 0; i < data.length; i++) {
      final item = data[i];

      double score = 0;
      int count = 0;

      if (item.hasHrv) {
        score += (item.hrv! / 100).clamp(0.0, 1.2);
        count++;
      }

      if (item.hasSleepHours) {
        score += (item.sleepHours! / 10).clamp(0.0, 1.2);
        count++;
      }

      if (item.hasStress) {
        score += ((100 - item.stress!) / 100).clamp(0.0, 1.0);
        count++;
      }

      if (item.hasRestingHeartRate) {
        score += ((100 - item.restingHeartRate!) / 100).clamp(0.0, 1.0);
        count++;
      }

      if (item.hasBodyBattery) {
        score += (item.bodyBattery! / 100).clamp(0.0, 1.0);
        count++;
      }

      if (count > 0) {
        scores.add(score / count);
        scoreWeights.add(weights[i]);
      }
    }

    if (scores.isEmpty) {
      return const _GlobalStats(
        mean: 0,
        stdDev: 0,
        coefficientOfVariation: 0,
        trendNormalized: 0,
      );
    }

    final weightSum = scoreWeights.fold<double>(0, (a, b) => a + b);

    double mean = 0;
    for (var i = 0; i < scores.length; i++) {
      mean += scores[i] * scoreWeights[i];
    }

    mean = weightSum > 0
        ? mean / weightSum
        : scores.fold<double>(0, (a, b) => a + b) / scores.length;

    double variance = 0;
    for (var i = 0; i < scores.length; i++) {
      final diff = scores[i] - mean;
      variance += scoreWeights[i] * diff * diff;
    }

    variance = weightSum > 0 ? variance / weightSum : variance / scores.length;

    final stdDev = math.sqrt(variance);
    final cv = mean > 0 ? stdDev / mean : 0.0;

    return _GlobalStats(
      mean: mean,
      stdDev: stdDev,
      coefficientOfVariation: cv,
      trendNormalized: _trendNormalized(scores),
    );
  }

  static double _confidence({
    required int validDays,
    required int expectedDays,
    required double coefficientOfVariation,
    required Map<BaselineMetricType, double> dataCoverage,
  }) {
    if (expectedDays <= 0) return 0;

    double confidence = 0.25;

    final completeness = validDays / expectedDays;
    confidence += completeness * 0.30;

    final stability = (1.0 - (coefficientOfVariation / 0.35)).clamp(0.0, 1.0);
    confidence += stability * 0.25;

    final keyCoverage =
        ((dataCoverage[BaselineMetricType.hrv] ?? 0) +
            (dataCoverage[BaselineMetricType.sleepHours] ?? 0) +
            (dataCoverage[BaselineMetricType.restingHeartRate] ?? 0)) /
        3;

    confidence += keyCoverage * 0.20;

    if (validDays < 5) confidence *= 0.45;
    if (coefficientOfVariation > 0.45) confidence *= 0.65;

    return confidence.clamp(0.0, 1.0);
  }

  static List<BaselineExclusionReason> _topExclusionReasons(
    List<BaselineDataPoint> excluded,
  ) {
    final counts = <BaselineExclusionReason, int>{};

    for (final item in excluded) {
      final reason = item.exclusionReason;
      if (reason == null) continue;
      counts[reason] = (counts[reason] ?? 0) + 1;
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.take(3).map((entry) => entry.key).toList();
  }
}

class _GlobalStats {
  final double mean;
  final double stdDev;
  final double coefficientOfVariation;
  final double trendNormalized;

  const _GlobalStats({
    required this.mean,
    required this.stdDev,
    required this.coefficientOfVariation,
    required this.trendNormalized,
  });
}
