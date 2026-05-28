enum BaselineWindow { shortTerm, mediumTerm, longTerm }

enum BaselineExclusionReason {
  illness,
  injury,
  travel,
  missingData,
  poorSleep,
  extremeStress,
  coachExcluded,
}

enum BaselineMetricType {
  hrv,
  restingHeartRate,
  sleepHours,
  stress,
  bodyBattery,
}

class BaselineDataPoint {
  final DateTime date;
  final double? hrv;
  final int? restingHeartRate;
  final double? sleepHours;
  final int? stress;
  final int? bodyBattery;
  final bool hasValidWearableData;
  final bool isExcluded;
  final BaselineExclusionReason? exclusionReason;

  const BaselineDataPoint({
    required this.date,
    this.hrv,
    this.restingHeartRate,
    this.sleepHours,
    this.stress,
    this.bodyBattery,
    this.hasValidWearableData = true,
    this.isExcluded = false,
    this.exclusionReason,
  });

  bool get isValidForBaseline => hasValidWearableData && !isExcluded;

  bool get hasHrv => hrv != null && hrv! > 0;
  bool get hasRestingHeartRate =>
      restingHeartRate != null && restingHeartRate! > 0;
  bool get hasSleepHours => sleepHours != null && sleepHours! > 0;
  bool get hasStress => stress != null && stress! > 0;
  bool get hasBodyBattery => bodyBattery != null && bodyBattery! > 0;
}

class BaselineMetric {
  final double? value;
  final double confidence;
  final bool hasEnoughData;
  final double trendNormalized;
  final double volatility;
  final int sampleSize;

  const BaselineMetric({
    required this.value,
    required this.confidence,
    required this.hasEnoughData,
    required this.trendNormalized,
    required this.volatility,
    required this.sampleSize,
  });

  factory BaselineMetric.insufficient() {
    return const BaselineMetric(
      value: null,
      confidence: 0,
      hasEnoughData: false,
      trendNormalized: 0,
      volatility: 0,
      sampleSize: 0,
    );
  }
}

class DynamicBaseline {
  final BaselineWindow window;
  final DateTime calculatedAt;
  final String baselineVersion;

  final double globalMean;
  final double globalStdDev;
  final double globalCoefficientOfVariation;
  final double globalTrendNormalized;

  final double confidence;
  final int validDays;
  final int excludedDays;
  final int missingDays;
  final double completeness;
  final double stability;

  final Map<BaselineMetricType, double> dataCoverage;

  final BaselineMetric hrv;
  final BaselineMetric restingHeartRate;
  final BaselineMetric sleepHours;
  final BaselineMetric stress;
  final BaselineMetric bodyBattery;

  final int totalDaysConsidered;
  final int daysWithWearableData;
  final List<BaselineExclusionReason> topExclusionReasons;

  const DynamicBaseline({
    required this.window,
    required this.calculatedAt,
    required this.baselineVersion,
    required this.globalMean,
    required this.globalStdDev,
    required this.globalCoefficientOfVariation,
    required this.globalTrendNormalized,
    required this.confidence,
    required this.validDays,
    required this.excludedDays,
    required this.missingDays,
    required this.completeness,
    required this.stability,
    required this.dataCoverage,
    required this.hrv,
    required this.restingHeartRate,
    required this.sleepHours,
    required this.stress,
    required this.bodyBattery,
    required this.totalDaysConsidered,
    required this.daysWithWearableData,
    required this.topExclusionReasons,
  });
}

class BaselineValidationRules {
  final double minSleepHours;
  final int maxStress;
  final int minValidDays;
  final double maxAllowedCoefficientOfVariation;
  final double recencyDecayRate;

  const BaselineValidationRules({
    this.minSleepHours = 4.0,
    this.maxStress = 90,
    this.minValidDays = 5,
    this.maxAllowedCoefficientOfVariation = 0.4,
    this.recencyDecayRate = 0.08,
  });

  static const defaultRules = BaselineValidationRules();

  static const eliteRules = BaselineValidationRules(
    minSleepHours: 6.0,
    maxStress: 80,
    minValidDays: 7,
    recencyDecayRate: 0.06,
  );

  static const taperRules = BaselineValidationRules(
    minSleepHours: 7.0,
    maxStress: 70,
    minValidDays: 5,
    recencyDecayRate: 0.12,
  );
}
