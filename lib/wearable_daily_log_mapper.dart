import 'daily_athlete_log.dart';
import 'wearable_integration_service.dart';

class WearableDailyLogMapper {
  static DailyAthleteLog fromWearable({
    required String athleteId,
    required WearableDailyData wearable,
  }) {
    final bodyStress = _bodyStress(wearable);
    final readiness = _readiness(wearable, bodyStress);

    final internalLoad = wearable.trainingLoad + bodyStress.recoveryCost * 0.35;

    final externalLoad =
        wearable.trainingLoad +
        (wearable.activeCalories * 0.05) +
        bodyStress.mechanicalStress * 0.20 +
        bodyStress.intermittentStress * 0.15;

    return DailyAthleteLog(
      athleteId: athleteId,
      date: wearable.date,
      plannedSessionType: 'AI Adaptive Session',
      plannedLoad: internalLoad.round(),
      plannedMinutes: wearable.totalTrainingMinutes,
      plannedKm: wearable.totalDistanceKm,
      performedSessionType: _performedSessionType(wearable, bodyStress),
      performedLoad: internalLoad.round(),
      performedMinutes: wearable.totalTrainingMinutes,
      performedKm: wearable.totalDistanceKm,
      completedAsPlanned: true,
      hrv: wearable.hrv.toDouble(),
      restingHeartRate: wearable.restingHeartRate,
      sleepHours: wearable.sleepHours,
      stressLevel: wearable.stress.toDouble(),
      averageHeartRate: wearable.averageHeartRate,
      maxHeartRate: wearable.maxHeartRate,
      rpe: wearable.rpe,
      soreness: wearable.soreness,
      motivation: 5,
      readiness: readiness,
      overloadDetected: readiness < 45 || bodyStress.requiresProtection,
      recoveryRecommended: readiness < 60 || bodyStress.recoveryCost >= 65,
      injuryRisk: _injuryRisk(wearable, readiness, bodyStress),
      aiDecision: readiness < 60 || bodyStress.requiresProtection
          ? 'Reduce load'
          : 'Normal progression',
      aiNotes: _notes(wearable, readiness, bodyStress),
      internalLoad: internalLoad,
      externalLoad: externalLoad,
      zone1Minutes: wearable.zone1Minutes,
      zone2Minutes: wearable.zone2Minutes,
      zone3Minutes: wearable.zone3Minutes,
      zone4Minutes: wearable.zone4Minutes,
      zone5Minutes: wearable.zone5Minutes,
      neuralStress: bodyStress.neuralStress,
      muscleStress: bodyStress.muscleStress,
      tendonStress: bodyStress.tendonStress,
      metabolicStress: bodyStress.metabolicStress,
      cardiovascularStress: bodyStress.cardiovascularStress,
      mechanicalStress: bodyStress.mechanicalStress,
      technicalStress: bodyStress.technicalStress,
      coordinationStress: bodyStress.coordinationStress,
      terrainStress: bodyStress.terrainStress,
      intermittentStress: bodyStress.intermittentStress,
      recoveryCost: bodyStress.recoveryCost,
    );
  }

  static _WearableBodyStress _bodyStress(WearableDailyData wearable) {
    final totalMinutes = wearable.totalTrainingMinutes <= 0
        ? 1
        : wearable.totalTrainingMinutes;

    final highIntensityMinutes = wearable.zone4Minutes + wearable.zone5Minutes;
    final highIntensityRatio = highIntensityMinutes / totalMinutes;

    final z5Ratio = wearable.zone5Minutes / totalMinutes;

    final distanceLoad = (wearable.totalDistanceKm * 1.4).clamp(0, 45);
    final calorieLoad = (wearable.activeCalories * 0.025).clamp(0, 45);
    final trainingLoad = wearable.trainingLoad.clamp(0, 180).toDouble();

    final heartRateSpread = (wearable.maxHeartRate - wearable.averageHeartRate)
        .clamp(0, 90);

    final cardiovascularStress =
        (wearable.zone2Minutes * 0.25 +
                wearable.zone3Minutes * 0.45 +
                wearable.zone4Minutes * 0.75 +
                wearable.zone5Minutes * 1.00 +
                wearable.trainingLoad * 0.20)
            .clamp(0, 100)
            .toDouble();

    final metabolicStress =
        (wearable.zone3Minutes * 0.35 +
                wearable.zone4Minutes * 0.95 +
                wearable.zone5Minutes * 1.15 +
                highIntensityRatio * 35)
            .clamp(0, 100)
            .toDouble();

    final neuralStress =
        (wearable.zone5Minutes * 1.45 +
                wearable.zone4Minutes * 0.45 +
                z5Ratio * 45 +
                heartRateSpread * 0.25 +
                _rpeBonus(wearable) * 0.80)
            .clamp(0, 100)
            .toDouble();

    final intermittentStress =
        (heartRateSpread * 0.50 +
                highIntensityRatio * 55 +
                wearable.zone5Minutes * 0.70 +
                wearable.zone4Minutes * 0.30)
            .clamp(0, 100)
            .toDouble();

    final mechanicalStress =
        (distanceLoad +
                calorieLoad * 0.45 +
                wearable.soreness * 4 +
                intermittentStress * 0.25)
            .clamp(0, 100)
            .toDouble();

    final muscleStress =
        (mechanicalStress * 0.45 +
                metabolicStress * 0.30 +
                wearable.soreness * 5 +
                trainingLoad * 0.10)
            .clamp(0, 100)
            .toDouble();

    final tendonStress =
        (mechanicalStress * 0.35 +
                intermittentStress * 0.30 +
                neuralStress * 0.20 +
                wearable.soreness * 3)
            .clamp(0, 100)
            .toDouble();

    final terrainStress =
        (mechanicalStress * 0.35 +
                intermittentStress * 0.35 +
                distanceLoad * 0.25)
            .clamp(0, 100)
            .toDouble();

    final technicalStress =
        (neuralStress * 0.25 +
                intermittentStress * 0.30 +
                wearable.soreness * 3 +
                highIntensityRatio * 20)
            .clamp(0, 100)
            .toDouble();

    final coordinationStress =
        (technicalStress * 0.60 + neuralStress * 0.25 + heartRateSpread * 0.15)
            .clamp(0, 100)
            .toDouble();

    final recoveryCost =
        (cardiovascularStress * 0.20 +
                metabolicStress * 0.22 +
                neuralStress * 0.20 +
                muscleStress * 0.18 +
                tendonStress * 0.12 +
                intermittentStress * 0.08)
            .clamp(0, 100)
            .toDouble();

    return _WearableBodyStress(
      neuralStress: neuralStress,
      muscleStress: muscleStress,
      tendonStress: tendonStress,
      metabolicStress: metabolicStress,
      cardiovascularStress: cardiovascularStress,
      mechanicalStress: mechanicalStress,
      technicalStress: technicalStress,
      coordinationStress: coordinationStress,
      terrainStress: terrainStress,
      intermittentStress: intermittentStress,
      recoveryCost: recoveryCost,
    );
  }

  static int _readiness(
    WearableDailyData wearable,
    _WearableBodyStress bodyStress,
  ) {
    double score = 100;

    if (wearable.hrv < 45) score -= 18;
    if (wearable.hrv >= 60) score += 5;

    if (wearable.sleepHours < 6) score -= 20;
    if (wearable.sleepHours >= 8) score += 5;

    if (wearable.restingHeartRate > 60) score -= 10;

    score -= wearable.stress * 0.25;
    score -= wearable.soreness * 3;

    if (wearable.trainingLoad > 100) score -= 10;
    if (wearable.trainingLoad > 140) score -= 15;

    final highIntensity = wearable.zone4Minutes + wearable.zone5Minutes;

    if (highIntensity > 35) score -= 10;
    if (highIntensity > 60) score -= 15;

    if (bodyStress.neuralStress >= 70) score -= 10;
    if (bodyStress.muscleStress >= 70) score -= 8;
    if (bodyStress.tendonStress >= 65) score -= 8;
    if (bodyStress.intermittentStress >= 65) score -= 7;
    if (bodyStress.recoveryCost >= 70) score -= 10;

    return score.clamp(0, 100).round();
  }

  static double _injuryRisk(
    WearableDailyData wearable,
    int readiness,
    _WearableBodyStress bodyStress,
  ) {
    double risk = 10;

    if (readiness < 60) risk += 20;
    if (wearable.sleepHours < 6) risk += 15;
    if (wearable.stress > 70) risk += 15;
    if (wearable.soreness >= 7) risk += 20;
    if (wearable.trainingLoad > 140) risk += 15;

    if (wearable.zone5Minutes > 20) risk += 15;
    if (wearable.zone4Minutes > 40) risk += 10;

    if (bodyStress.tendonStress >= 65) risk += 12;
    if (bodyStress.mechanicalStress >= 70) risk += 10;
    if (bodyStress.neuralStress >= 75) risk += 10;
    if (bodyStress.intermittentStress >= 70) risk += 8;
    if (bodyStress.recoveryCost >= 75) risk += 10;

    return risk.clamp(0, 100).toDouble();
  }

  static String _notes(
    WearableDailyData wearable,
    int readiness,
    _WearableBodyStress bodyStress,
  ) {
    final notes = <String>[];
    final highIntensity = wearable.zone4Minutes + wearable.zone5Minutes;

    if (readiness < 40) {
      notes.add('Fatiga crítica detectada desde datos wearable.');
    }

    if (wearable.sleepHours < 6) {
      notes.add('Sueño bajo detectado. Priorizar recuperación.');
    }

    if (wearable.hrv < 45) {
      notes.add('HRV baja detectada. Controlar intensidad.');
    }

    if (wearable.trainingLoad > 140) {
      notes.add('Carga wearable alta. Vigilar acumulación de fatiga.');
    }

    if (highIntensity > 50) {
      notes.add('Alta intensidad acumulada detectada.');
    }

    if (bodyStress.neuralStress >= 65) {
      notes.add('Estrés neural oculto elevado.');
    }

    if (bodyStress.muscleStress >= 65) {
      notes.add('Estrés muscular elevado.');
    }

    if (bodyStress.tendonStress >= 65) {
      notes.add('Estrés tendinoso elevado.');
    }

    if (bodyStress.intermittentStress >= 65) {
      notes.add('Intermitencias/cambios de ritmo con coste fisiológico.');
    }

    if (bodyStress.terrainStress >= 65) {
      notes.add('Estrés mecánico/terreno elevado.');
    }

    if (bodyStress.recoveryCost >= 70) {
      notes.add('Coste de recuperación alto para la próxima sesión.');
    }

    if (notes.isEmpty) {
      return 'Estado fisiológico estable según datos wearable.';
    }

    return notes.join(' ');
  }

  static String _performedSessionType(
    WearableDailyData wearable,
    _WearableBodyStress bodyStress,
  ) {
    final labels = <String>['Wearable Training Load'];

    if (bodyStress.cardiovascularStress >= 60) {
      labels.add('cardiovascular');
    }

    if (bodyStress.metabolicStress >= 60) {
      labels.add('metabolic');
    }

    if (bodyStress.neuralStress >= 60) {
      labels.add('neural');
    }

    if (bodyStress.intermittentStress >= 60) {
      labels.add('intermittent');
    }

    if (bodyStress.mechanicalStress >= 60 || bodyStress.terrainStress >= 60) {
      labels.add('mechanical');
    }

    if (wearable.zone5Minutes >= 8) {
      labels.add('Z5');
    }

    return labels.join(' + ');
  }

  static double _rpeBonus(WearableDailyData wearable) {
    if (wearable.rpe <= 0) return 0;
    if (wearable.rpe <= 6) return 5;
    if (wearable.rpe <= 8) return 12;
    return 20;
  }
}

class _WearableBodyStress {
  final double neuralStress;
  final double muscleStress;
  final double tendonStress;
  final double metabolicStress;
  final double cardiovascularStress;
  final double mechanicalStress;
  final double technicalStress;
  final double coordinationStress;
  final double terrainStress;
  final double intermittentStress;
  final double recoveryCost;

  const _WearableBodyStress({
    required this.neuralStress,
    required this.muscleStress,
    required this.tendonStress,
    required this.metabolicStress,
    required this.cardiovascularStress,
    required this.mechanicalStress,
    required this.technicalStress,
    required this.coordinationStress,
    required this.terrainStress,
    required this.intermittentStress,
    required this.recoveryCost,
  });

  bool get requiresProtection {
    return neuralStress >= 75 ||
        tendonStress >= 75 ||
        muscleStress >= 75 ||
        recoveryCost >= 75 ||
        intermittentStress >= 80;
  }
}
