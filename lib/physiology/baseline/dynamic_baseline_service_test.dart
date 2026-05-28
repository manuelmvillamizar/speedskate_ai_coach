import 'package:flutter_test/flutter_test.dart';
import 'package:speedskate_ai_coach/physiology/baseline/baseline_models.dart';
import 'package:speedskate_ai_coach/physiology/baseline/dynamic_baseline_service.dart';

List<BaselineDataPoint> stableAthleteDataset() {
  final now = DateTime.now();
  final data = <BaselineDataPoint>[];

  for (int i = 0; i < 28; i++) {
    data.add(
      BaselineDataPoint(
        date: now.subtract(Duration(days: 27 - i)),
        hrv: 55 + (i % 5 - 2),
        sleepHours: 7.5 + (i % 3 - 1) * 0.2,
        stress: 35 + (i % 4 - 2),
        restingHeartRate: 52 + (i % 3 - 1),
        bodyBattery: 65 + (i % 5 - 2),
      ),
    );
  }

  return data;
}

List<BaselineDataPoint> badLastThreeDaysDataset() {
  final now = DateTime.now();
  final data = <BaselineDataPoint>[];

  for (int i = 0; i < 25; i++) {
    data.add(
      BaselineDataPoint(
        date: now.subtract(Duration(days: 27 - i)),
        hrv: 55,
        sleepHours: 7.5,
        stress: 35,
        restingHeartRate: 52,
        bodyBattery: 65,
      ),
    );
  }

  for (int i = 0; i < 3; i++) {
    data.add(
      BaselineDataPoint(
        date: now.subtract(Duration(days: 2 - i)),
        hrv: 38,
        sleepHours: 5,
        stress: 75,
        restingHeartRate: 62,
        bodyBattery: 35,
      ),
    );
  }

  return data;
}

List<BaselineDataPoint> illnessExcludedDataset() {
  final now = DateTime.now();
  final data = <BaselineDataPoint>[];

  for (int i = 0; i < 28; i++) {
    final sick = i >= 12 && i <= 15;

    data.add(
      BaselineDataPoint(
        date: now.subtract(Duration(days: 27 - i)),
        hrv: sick ? 35 : 55,
        sleepHours: sick ? 4 : 7.5,
        stress: sick ? 88 : 35,
        restingHeartRate: sick ? 66 : 52,
        bodyBattery: sick ? 25 : 65,
        isExcluded: sick,
        exclusionReason: sick ? BaselineExclusionReason.illness : null,
      ),
    );
  }

  return data;
}

List<BaselineDataPoint> extremeGappedDataset() {
  final now = DateTime.now();
  final validIndexes = {3, 10, 17, 24};
  final data = <BaselineDataPoint>[];

  for (int i = 0; i < 28; i++) {
    final valid = validIndexes.contains(i);

    data.add(
      BaselineDataPoint(
        date: now.subtract(Duration(days: 27 - i)),
        hrv: valid ? 55 : null,
        sleepHours: valid ? 7.5 : null,
        stress: valid ? 35 : null,
        restingHeartRate: valid ? 52 : null,
        bodyBattery: valid ? 65 : null,
        hasValidWearableData: valid,
        isExcluded: !valid,
        exclusionReason: valid ? null : BaselineExclusionReason.missingData,
      ),
    );
  }

  return data;
}

List<BaselineDataPoint> volatileHrvDataset() {
  final now = DateTime.now();
  final values = [20, 90, 25, 100, 15, 85, 30, 95];

  return List.generate(28, (i) {
    return BaselineDataPoint(
      date: now.subtract(Duration(days: 27 - i)),
      hrv: values[i % values.length].toDouble(),
      sleepHours: 7.5,
      stress: 35,
      restingHeartRate: 52,
      bodyBattery: 65,
    );
  });
}

List<BaselineDataPoint> taperDataset() {
  final now = DateTime.now();
  final data = <BaselineDataPoint>[];

  for (int i = 0; i < 28; i++) {
    data.add(
      BaselineDataPoint(
        date: now.subtract(Duration(days: 27 - i)),
        hrv: 48 + (i / 27) * 12,
        sleepHours: 6.5 + (i / 27) * 1.5,
        stress: (55 - (i / 27) * 25).round(),
        restingHeartRate: (58 - (i / 27) * 8).round(),
        bodyBattery: (45 + (i / 27) * 25).round(),
      ),
    );
  }

  return data;
}

void main() {
  group('DynamicBaselineService', () {
    test('atleta estable produce baseline confiable', () {
      final baseline = DynamicBaselineService.calculate(
        history: stableAthleteDataset(),
        window: BaselineWindow.mediumTerm,
      );

      expect(baseline.baselineVersion, equals('1.0.0'));
      expect(baseline.confidence, greaterThan(0.70));
      expect(baseline.stability, greaterThan(0.70));
      expect(baseline.hrv.hasEnoughData, isTrue);
      expect(baseline.sleepHours.hasEnoughData, isTrue);
      expect(baseline.hrv.trendNormalized.abs(), lessThan(0.06));
    });

    test('tres días malos no destruyen baseline de 28 días', () {
      final baseline = DynamicBaselineService.calculate(
        history: badLastThreeDaysDataset(),
        window: BaselineWindow.mediumTerm,
      );

      expect(baseline.hrv.value, greaterThan(47));
      expect(baseline.hrv.value, lessThan(58));
      expect(baseline.hrv.trendNormalized, greaterThan(-0.12));
    });

    test('enfermedad excluida no contamina baseline', () {
      final baseline = DynamicBaselineService.calculate(
        history: illnessExcludedDataset(),
        window: BaselineWindow.mediumTerm,
      );

      expect(baseline.excludedDays, equals(4));
      expect(
        baseline.topExclusionReasons,
        contains(BaselineExclusionReason.illness),
      );
      expect(baseline.hrv.value, greaterThan(50));
      expect(baseline.hrv.value, lessThan(58));
    });

    test('gaps extremos bajan confianza', () {
      final baseline = DynamicBaselineService.calculate(
        history: extremeGappedDataset(),
        window: BaselineWindow.mediumTerm,
      );

      expect(baseline.validDays, equals(4));
      expect(baseline.completeness, lessThan(0.20));
      expect(baseline.confidence, lessThan(0.35));
      expect(baseline.hrv.hasEnoughData, isFalse);
    });

    test('HRV muy volátil reduce confianza de HRV', () {
      final stable = DynamicBaselineService.calculate(
        history: stableAthleteDataset(),
        window: BaselineWindow.mediumTerm,
      );

      final volatile = DynamicBaselineService.calculate(
        history: volatileHrvDataset(),
        window: BaselineWindow.mediumTerm,
      );

      expect(volatile.hrv.volatility, greaterThan(stable.hrv.volatility));
      expect(volatile.hrv.confidence, lessThan(stable.hrv.confidence));
    });

    test('taper muestra tendencia positiva suave', () {
      final baseline = DynamicBaselineService.calculate(
        history: taperDataset(),
        window: BaselineWindow.mediumTerm,
      );

      expect(baseline.hrv.trendNormalized, greaterThan(0.0));
      expect(baseline.sleepHours.trendNormalized, greaterThan(0.0));
      expect(baseline.stress.trendNormalized, lessThan(0.0));
    });

    test('HRV faltante no destruye baseline de sueño', () {
      final now = DateTime.now();

      final data = List.generate(28, (i) {
        return BaselineDataPoint(
          date: now.subtract(Duration(days: 27 - i)),
          hrv: null,
          sleepHours: 7.5,
          stress: 35,
          restingHeartRate: 52,
          bodyBattery: 65,
        );
      });

      final baseline = DynamicBaselineService.calculate(
        history: data,
        window: BaselineWindow.mediumTerm,
      );

      expect(baseline.hrv.hasEnoughData, isFalse);
      expect(baseline.sleepHours.hasEnoughData, isTrue);
      expect(baseline.sleepHours.value, greaterThan(7.0));
      expect(baseline.sleepHours.value, lessThan(8.0));
    });
  });
}
