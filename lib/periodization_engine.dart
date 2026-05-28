import 'auto_adjust_screen.dart';

enum PeriodizationAthleteType { sprinter, endurance, mixed }

enum PeriodizationLevel { beginner, competitive, elite }

enum PeriodizationFocus { base, specific, competition, recovery }

enum PeriodizationDayType {
  speed,
  endurance,
  gymStrength,
  gymPower,
  technique,
  mobility,
  recovery,
  competitionSimulation,
}

class PeriodizationDay {
  final int dayNumber;
  final String dayEs;
  final String dayEn;
  final String dayDe;

  final PeriodizationDayType type;

  final String focusEs;
  final String focusEn;
  final String focusDe;

  final String sessionEs;
  final String sessionEn;
  final String sessionDe;

  final double intensity;
  final double volume;
  final int minutes;
  final double skateKm;
  final double gymLoadKg;

  final bool allowProgression;
  final bool isRecovery;

  final String coachNoteEs;
  final String coachNoteEn;
  final String coachNoteDe;

  const PeriodizationDay({
    required this.dayNumber,
    required this.dayEs,
    required this.dayEn,
    required this.dayDe,
    required this.type,
    required this.focusEs,
    required this.focusEn,
    required this.focusDe,
    required this.sessionEs,
    required this.sessionEn,
    required this.sessionDe,
    required this.intensity,
    required this.volume,
    required this.minutes,
    required this.skateKm,
    required this.gymLoadKg,
    required this.allowProgression,
    required this.isRecovery,
    required this.coachNoteEs,
    required this.coachNoteEn,
    required this.coachNoteDe,
  });
}

class PeriodizationMicrocycle {
  final List<PeriodizationDay> days;
  final String summaryEs;
  final String summaryEn;
  final String summaryDe;
  final double weeklyLoadScore;
  final bool progressionBlocked;
  final String blockReasonEs;
  final String blockReasonEn;
  final String blockReasonDe;

  const PeriodizationMicrocycle({
    required this.days,
    required this.summaryEs,
    required this.summaryEn,
    required this.summaryDe,
    required this.weeklyLoadScore,
    required this.progressionBlocked,
    required this.blockReasonEs,
    required this.blockReasonEn,
    required this.blockReasonDe,
  });
}

class PeriodizationEngine {
  static PeriodizationMicrocycle generateMicrocycle({
    required PeriodizationAthleteType athleteType,
    required PeriodizationLevel level,
    required PeriodizationFocus focus,
    required AutoPhysiologyStatus fatigueStatus,
  }) {
    final bool forcedRecovery =
        focus == PeriodizationFocus.recovery ||
        fatigueStatus == AutoPhysiologyStatus.orange ||
        fatigueStatus == AutoPhysiologyStatus.red;

    final bool progressionBlocked =
        fatigueStatus == AutoPhysiologyStatus.orange ||
        fatigueStatus == AutoPhysiologyStatus.red;

    final double levelFactor = _levelFactor(level);
    final double focusFactor = _focusFactor(focus);
    final double fatigueFactor = _fatigueFactor(fatigueStatus);

    final List<PeriodizationDayType> structure = forcedRecovery
        ? _recoveryStructure()
        : _structureFor(athleteType, focus);

    final days = <PeriodizationDay>[];

    for (int i = 0; i < structure.length; i++) {
      final type = structure[i];
      final bool isRecovery =
          type == PeriodizationDayType.recovery ||
          type == PeriodizationDayType.mobility;

      final double rawIntensity = _baseIntensity(type) * levelFactor;
      final double rawVolume = _baseVolume(type, athleteType) * focusFactor;

      final double intensity = _clamp01(
        isRecovery ? rawIntensity * 0.65 : rawIntensity * fatigueFactor,
      );

      final double volume = _clamp01(
        isRecovery ? rawVolume * 0.65 : rawVolume * fatigueFactor,
      );

      days.add(
        PeriodizationDay(
          dayNumber: i + 1,
          dayEs: _dayEs(i),
          dayEn: _dayEn(i),
          dayDe: _dayDe(i),
          type: type,
          focusEs: _focusEs(type),
          focusEn: _focusEn(type),
          focusDe: _focusDe(type),
          sessionEs: _sessionEs(type, athleteType, focus, fatigueStatus),
          sessionEn: _sessionEn(type, athleteType, focus, fatigueStatus),
          sessionDe: _sessionDe(type, athleteType, focus, fatigueStatus),
          intensity: intensity,
          volume: volume,
          minutes: _minutes(type, level, fatigueStatus),
          skateKm: _skateKm(type, athleteType, level, fatigueStatus),
          gymLoadKg: _gymLoadKg(type, athleteType, level, fatigueStatus),
          allowProgression:
              !progressionBlocked &&
              !isRecovery &&
              fatigueStatus == AutoPhysiologyStatus.green,
          isRecovery: isRecovery,
          coachNoteEs: _coachNoteEs(type, fatigueStatus, progressionBlocked),
          coachNoteEn: _coachNoteEn(type, fatigueStatus, progressionBlocked),
          coachNoteDe: _coachNoteDe(type, fatigueStatus, progressionBlocked),
        ),
      );
    }

    final weeklyLoadScore = days.fold<double>(
      0,
      (sum, d) =>
          sum +
          (d.intensity * 40) +
          (d.volume * 35) +
          (d.skateKm * 1.2) +
          (d.gymLoadKg / 180),
    );

    return PeriodizationMicrocycle(
      days: days,
      summaryEs: _summaryEs(focus, fatigueStatus, progressionBlocked),
      summaryEn: _summaryEn(focus, fatigueStatus, progressionBlocked),
      summaryDe: _summaryDe(focus, fatigueStatus, progressionBlocked),
      weeklyLoadScore: weeklyLoadScore,
      progressionBlocked: progressionBlocked,
      blockReasonEs: _blockReasonEs(fatigueStatus),
      blockReasonEn: _blockReasonEn(fatigueStatus),
      blockReasonDe: _blockReasonDe(fatigueStatus),
    );
  }

  static List<PeriodizationDayType> _structureFor(
    PeriodizationAthleteType type,
    PeriodizationFocus focus,
  ) {
    if (focus == PeriodizationFocus.competition) {
      return const [
        PeriodizationDayType.speed,
        PeriodizationDayType.gymPower,
        PeriodizationDayType.technique,
        PeriodizationDayType.recovery,
        PeriodizationDayType.speed,
        PeriodizationDayType.competitionSimulation,
        PeriodizationDayType.recovery,
      ];
    }

    if (type == PeriodizationAthleteType.sprinter) {
      return const [
        PeriodizationDayType.gymPower,
        PeriodizationDayType.speed,
        PeriodizationDayType.technique,
        PeriodizationDayType.gymStrength,
        PeriodizationDayType.recovery,
        PeriodizationDayType.speed,
        PeriodizationDayType.mobility,
      ];
    }

    if (type == PeriodizationAthleteType.endurance) {
      return const [
        PeriodizationDayType.endurance,
        PeriodizationDayType.gymStrength,
        PeriodizationDayType.technique,
        PeriodizationDayType.endurance,
        PeriodizationDayType.recovery,
        PeriodizationDayType.competitionSimulation,
        PeriodizationDayType.mobility,
      ];
    }

    return const [
      PeriodizationDayType.speed,
      PeriodizationDayType.gymStrength,
      PeriodizationDayType.endurance,
      PeriodizationDayType.technique,
      PeriodizationDayType.gymPower,
      PeriodizationDayType.recovery,
      PeriodizationDayType.mobility,
    ];
  }

  static List<PeriodizationDayType> _recoveryStructure() {
    return const [
      PeriodizationDayType.technique,
      PeriodizationDayType.mobility,
      PeriodizationDayType.recovery,
      PeriodizationDayType.technique,
      PeriodizationDayType.mobility,
      PeriodizationDayType.recovery,
      PeriodizationDayType.recovery,
    ];
  }

  static double _levelFactor(PeriodizationLevel level) {
    switch (level) {
      case PeriodizationLevel.beginner:
        return 0.72;
      case PeriodizationLevel.competitive:
        return 0.9;
      case PeriodizationLevel.elite:
        return 1.0;
    }
  }

  static double _focusFactor(PeriodizationFocus focus) {
    switch (focus) {
      case PeriodizationFocus.base:
        return 0.9;
      case PeriodizationFocus.specific:
        return 1.0;
      case PeriodizationFocus.competition:
        return 0.85;
      case PeriodizationFocus.recovery:
        return 0.55;
    }
  }

  static double _fatigueFactor(AutoPhysiologyStatus status) {
    switch (status) {
      case AutoPhysiologyStatus.green:
        return 1.0;
      case AutoPhysiologyStatus.yellow:
        return 0.84;
      case AutoPhysiologyStatus.orange:
        return 0.58;
      case AutoPhysiologyStatus.red:
        return 0.35;
    }
  }

  static double _baseIntensity(PeriodizationDayType type) {
    switch (type) {
      case PeriodizationDayType.speed:
        return 0.95;
      case PeriodizationDayType.gymPower:
        return 0.88;
      case PeriodizationDayType.gymStrength:
        return 0.84;
      case PeriodizationDayType.competitionSimulation:
        return 0.9;
      case PeriodizationDayType.endurance:
        return 0.72;
      case PeriodizationDayType.technique:
        return 0.55;
      case PeriodizationDayType.mobility:
        return 0.3;
      case PeriodizationDayType.recovery:
        return 0.2;
    }
  }

  static double _baseVolume(
    PeriodizationDayType type,
    PeriodizationAthleteType athleteType,
  ) {
    final enduranceBonus = athleteType == PeriodizationAthleteType.endurance
        ? 1.15
        : 1.0;

    switch (type) {
      case PeriodizationDayType.endurance:
        return 0.82 * enduranceBonus;
      case PeriodizationDayType.gymStrength:
        return 0.78;
      case PeriodizationDayType.gymPower:
        return 0.62;
      case PeriodizationDayType.speed:
        return 0.58;
      case PeriodizationDayType.competitionSimulation:
        return 0.72;
      case PeriodizationDayType.technique:
        return 0.48;
      case PeriodizationDayType.mobility:
        return 0.25;
      case PeriodizationDayType.recovery:
        return 0.18;
    }
  }

  static int _minutes(
    PeriodizationDayType type,
    PeriodizationLevel level,
    AutoPhysiologyStatus status,
  ) {
    int base;

    switch (type) {
      case PeriodizationDayType.speed:
        base = 80;
        break;
      case PeriodizationDayType.endurance:
        base = 105;
        break;
      case PeriodizationDayType.gymStrength:
        base = 70;
        break;
      case PeriodizationDayType.gymPower:
        base = 65;
        break;
      case PeriodizationDayType.technique:
        base = 55;
        break;
      case PeriodizationDayType.competitionSimulation:
        base = 90;
        break;
      case PeriodizationDayType.mobility:
        base = 30;
        break;
      case PeriodizationDayType.recovery:
        base = 25;
        break;
    }

    if (level == PeriodizationLevel.beginner) base = (base * 0.75).round();
    if (level == PeriodizationLevel.elite) base = (base * 1.1).round();

    if (status == AutoPhysiologyStatus.yellow) base = (base * 0.9).round();
    if (status == AutoPhysiologyStatus.orange) base = (base * 0.65).round();
    if (status == AutoPhysiologyStatus.red) base = (base * 0.45).round();

    return base;
  }

  static double _skateKm(
    PeriodizationDayType type,
    PeriodizationAthleteType athleteType,
    PeriodizationLevel level,
    AutoPhysiologyStatus status,
  ) {
    double km;

    switch (type) {
      case PeriodizationDayType.speed:
        km = athleteType == PeriodizationAthleteType.sprinter ? 14 : 18;
        break;
      case PeriodizationDayType.endurance:
        km = athleteType == PeriodizationAthleteType.endurance ? 34 : 24;
        break;
      case PeriodizationDayType.technique:
        km = 8;
        break;
      case PeriodizationDayType.competitionSimulation:
        km = 18;
        break;
      default:
        km = 0;
    }

    if (level == PeriodizationLevel.beginner) km *= 0.65;
    if (level == PeriodizationLevel.elite) km *= 1.15;

    if (status == AutoPhysiologyStatus.yellow) km *= 0.85;
    if (status == AutoPhysiologyStatus.orange) km *= 0.55;
    if (status == AutoPhysiologyStatus.red) km *= 0.25;

    return km;
  }

  static double _gymLoadKg(
    PeriodizationDayType type,
    PeriodizationAthleteType athleteType,
    PeriodizationLevel level,
    AutoPhysiologyStatus status,
  ) {
    double load;

    switch (type) {
      case PeriodizationDayType.gymStrength:
        load = athleteType == PeriodizationAthleteType.sprinter ? 4200 : 3200;
        break;
      case PeriodizationDayType.gymPower:
        load = athleteType == PeriodizationAthleteType.sprinter ? 2800 : 2200;
        break;
      default:
        load = 0;
    }

    if (level == PeriodizationLevel.beginner) load *= 0.6;
    if (level == PeriodizationLevel.elite) load *= 1.15;

    if (status == AutoPhysiologyStatus.yellow) load *= 0.85;
    if (status == AutoPhysiologyStatus.orange) load *= 0.35;
    if (status == AutoPhysiologyStatus.red) load = 0;

    return load;
  }

  static double _clamp01(double value) {
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }

  static String _dayEs(int index) {
    const days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return days[index];
  }

  static String _dayEn(int index) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[index];
  }

  static String _dayDe(int index) {
    const days = [
      'Montag',
      'Dienstag',
      'Mittwoch',
      'Donnerstag',
      'Freitag',
      'Samstag',
      'Sonntag',
    ];
    return days[index];
  }

  static String _focusEs(PeriodizationDayType type) {
    switch (type) {
      case PeriodizationDayType.speed:
        return 'Velocidad';
      case PeriodizationDayType.endurance:
        return 'Resistencia';
      case PeriodizationDayType.gymStrength:
        return 'Fuerza máxima';
      case PeriodizationDayType.gymPower:
        return 'Potencia';
      case PeriodizationDayType.technique:
        return 'Técnica';
      case PeriodizationDayType.mobility:
        return 'Movilidad';
      case PeriodizationDayType.recovery:
        return 'Recuperación';
      case PeriodizationDayType.competitionSimulation:
        return 'Simulación competitiva';
    }
  }

  static String _focusEn(PeriodizationDayType type) {
    switch (type) {
      case PeriodizationDayType.speed:
        return 'Speed';
      case PeriodizationDayType.endurance:
        return 'Endurance';
      case PeriodizationDayType.gymStrength:
        return 'Maximum strength';
      case PeriodizationDayType.gymPower:
        return 'Power';
      case PeriodizationDayType.technique:
        return 'Technique';
      case PeriodizationDayType.mobility:
        return 'Mobility';
      case PeriodizationDayType.recovery:
        return 'Recovery';
      case PeriodizationDayType.competitionSimulation:
        return 'Competition simulation';
    }
  }

  static String _focusDe(PeriodizationDayType type) {
    switch (type) {
      case PeriodizationDayType.speed:
        return 'Geschwindigkeit';
      case PeriodizationDayType.endurance:
        return 'Ausdauer';
      case PeriodizationDayType.gymStrength:
        return 'Maximalkraft';
      case PeriodizationDayType.gymPower:
        return 'Schnellkraft';
      case PeriodizationDayType.technique:
        return 'Technik';
      case PeriodizationDayType.mobility:
        return 'Mobilität';
      case PeriodizationDayType.recovery:
        return 'Regeneration';
      case PeriodizationDayType.competitionSimulation:
        return 'Wettkampfsimulation';
    }
  }

  static String _sessionEs(
    PeriodizationDayType type,
    PeriodizationAthleteType athleteType,
    PeriodizationFocus focus,
    AutoPhysiologyStatus status,
  ) {
    if (status == AutoPhysiologyStatus.red) {
      return 'Recuperación guiada, movilidad, respiración y control de dolor/fatiga.';
    }

    switch (type) {
      case PeriodizationDayType.speed:
        return 'Salidas, aceleraciones cortas, 100m/200m y descansos completos.';
      case PeriodizationDayType.endurance:
        return 'Zona 2, cambios controlados, drafting y final progresivo.';
      case PeriodizationDayType.gymStrength:
        return 'Sentadilla, hip thrust, split squat y core específico.';
      case PeriodizationDayType.gymPower:
        return 'Power clean, saltos laterales, técnica explosiva y baja fatiga.';
      case PeriodizationDayType.technique:
        return 'Curva, postura baja, transferencia lateral y eficiencia.';
      case PeriodizationDayType.mobility:
        return 'Cadera, tobillo, columna, glúteo medio y core suave.';
      case PeriodizationDayType.recovery:
        return 'Descarga activa, movilidad, sueño y recuperación.';
      case PeriodizationDayType.competitionSimulation:
        return 'Simulación de carrera, táctica, remate y toma de decisiones.';
    }
  }

  static String _sessionEn(
    PeriodizationDayType type,
    PeriodizationAthleteType athleteType,
    PeriodizationFocus focus,
    AutoPhysiologyStatus status,
  ) {
    if (status == AutoPhysiologyStatus.red) {
      return 'Guided recovery, mobility, breathing and pain/fatigue control.';
    }

    switch (type) {
      case PeriodizationDayType.speed:
        return 'Starts, short accelerations, 100m/200m and full recovery.';
      case PeriodizationDayType.endurance:
        return 'Zone 2, controlled pace changes, drafting and progressive finish.';
      case PeriodizationDayType.gymStrength:
        return 'Squat, hip thrust, split squat and specific core.';
      case PeriodizationDayType.gymPower:
        return 'Power clean, lateral jumps, explosive technique and low fatigue.';
      case PeriodizationDayType.technique:
        return 'Curve, low position, lateral transfer and efficiency.';
      case PeriodizationDayType.mobility:
        return 'Hip, ankle, spine, glute medius and easy core.';
      case PeriodizationDayType.recovery:
        return 'Active deload, mobility, sleep and recovery.';
      case PeriodizationDayType.competitionSimulation:
        return 'Race simulation, tactics, final sprint and decision-making.';
    }
  }

  static String _sessionDe(
    PeriodizationDayType type,
    PeriodizationAthleteType athleteType,
    PeriodizationFocus focus,
    AutoPhysiologyStatus status,
  ) {
    if (status == AutoPhysiologyStatus.red) {
      return 'Geführte Regeneration, Mobilität, Atmung und Schmerz-/Müdigkeitskontrolle.';
    }

    switch (type) {
      case PeriodizationDayType.speed:
        return 'Starts, kurze Beschleunigungen, 100m/200m und vollständige Erholung.';
      case PeriodizationDayType.endurance:
        return 'Zone 2, kontrollierte Tempowechsel, Drafting und progressiver Abschluss.';
      case PeriodizationDayType.gymStrength:
        return 'Kniebeuge, Hip Thrust, Split Squat und spezifischer Core.';
      case PeriodizationDayType.gymPower:
        return 'Power Clean, Seitensprünge, explosive Technik und geringe Ermüdung.';
      case PeriodizationDayType.technique:
        return 'Kurve, tiefe Position, lateraler Transfer und Effizienz.';
      case PeriodizationDayType.mobility:
        return 'Hüfte, Sprunggelenk, Wirbelsäule, Gluteus medius und leichter Core.';
      case PeriodizationDayType.recovery:
        return 'Aktive Entlastung, Mobilität, Schlaf und Regeneration.';
      case PeriodizationDayType.competitionSimulation:
        return 'Rennsimulation, Taktik, Endspurt und Entscheidungsfindung.';
    }
  }

  static String _coachNoteEs(
    PeriodizationDayType type,
    AutoPhysiologyStatus status,
    bool progressionBlocked,
  ) {
    if (progressionBlocked) {
      return 'Progresión bloqueada por fatiga. No aumentar carga.';
    }

    if (status == AutoPhysiologyStatus.yellow) {
      return 'Mantener estímulo, pero sin buscar récords ni volumen extra.';
    }

    return 'Día apto para calidad. Progresar solo si la técnica se mantiene limpia.';
  }

  static String _coachNoteEn(
    PeriodizationDayType type,
    AutoPhysiologyStatus status,
    bool progressionBlocked,
  ) {
    if (progressionBlocked) {
      return 'Progression blocked by fatigue. Do not increase load.';
    }

    if (status == AutoPhysiologyStatus.yellow) {
      return 'Keep stimulus, but avoid records or extra volume.';
    }

    return 'Quality day. Progress only if technique stays clean.';
  }

  static String _coachNoteDe(
    PeriodizationDayType type,
    AutoPhysiologyStatus status,
    bool progressionBlocked,
  ) {
    if (progressionBlocked) {
      return 'Progression wegen Ermüdung blockiert. Belastung nicht erhöhen.';
    }

    if (status == AutoPhysiologyStatus.yellow) {
      return 'Reiz beibehalten, aber keine Rekorde oder Zusatzbelastung.';
    }

    return 'Qualitätstag. Nur steigern, wenn die Technik sauber bleibt.';
  }

  static String _summaryEs(
    PeriodizationFocus focus,
    AutoPhysiologyStatus status,
    bool progressionBlocked,
  ) {
    if (progressionBlocked) {
      return 'Microciclo de descarga automática por fatiga. Prioridad: asimilar, recuperar y proteger rendimiento.';
    }

    if (focus == PeriodizationFocus.competition) {
      return 'Microciclo competitivo: baja carga innecesaria, mantiene velocidad y precisión.';
    }

    return 'Microciclo de alto rendimiento: combina carga, técnica, gimnasio y recuperación.';
  }

  static String _summaryEn(
    PeriodizationFocus focus,
    AutoPhysiologyStatus status,
    bool progressionBlocked,
  ) {
    if (progressionBlocked) {
      return 'Automatic deload microcycle due to fatigue. Priority: adaptation, recovery and performance protection.';
    }

    if (focus == PeriodizationFocus.competition) {
      return 'Competition microcycle: removes unnecessary load, maintains speed and precision.';
    }

    return 'High-performance microcycle: combines load, technique, gym and recovery.';
  }

  static String _summaryDe(
    PeriodizationFocus focus,
    AutoPhysiologyStatus status,
    bool progressionBlocked,
  ) {
    if (progressionBlocked) {
      return 'Automatischer Entlastungs-Mikrozyklus wegen Ermüdung. Priorität: Anpassung, Regeneration und Leistungsschutz.';
    }

    if (focus == PeriodizationFocus.competition) {
      return 'Wettkampf-Mikrozyklus: reduziert unnötige Belastung, erhält Geschwindigkeit und Präzision.';
    }

    return 'Hochleistungs-Mikrozyklus: kombiniert Belastung, Technik, Krafttraining und Regeneration.';
  }

  static String _blockReasonEs(AutoPhysiologyStatus status) {
    switch (status) {
      case AutoPhysiologyStatus.green:
        return 'Progresión permitida.';
      case AutoPhysiologyStatus.yellow:
        return 'Progresión limitada: vigilar fatiga.';
      case AutoPhysiologyStatus.orange:
        return 'Progresión bloqueada: fatiga acumulada.';
      case AutoPhysiologyStatus.red:
        return 'Progresión bloqueada: riesgo alto de sobrecarga.';
    }
  }

  static String _blockReasonEn(AutoPhysiologyStatus status) {
    switch (status) {
      case AutoPhysiologyStatus.green:
        return 'Progression allowed.';
      case AutoPhysiologyStatus.yellow:
        return 'Progression limited: monitor fatigue.';
      case AutoPhysiologyStatus.orange:
        return 'Progression blocked: accumulated fatigue.';
      case AutoPhysiologyStatus.red:
        return 'Progression blocked: high overload risk.';
    }
  }

  static String _blockReasonDe(AutoPhysiologyStatus status) {
    switch (status) {
      case AutoPhysiologyStatus.green:
        return 'Progression erlaubt.';
      case AutoPhysiologyStatus.yellow:
        return 'Progression begrenzt: Ermüdung beobachten.';
      case AutoPhysiologyStatus.orange:
        return 'Progression blockiert: kumulierte Ermüdung.';
      case AutoPhysiologyStatus.red:
        return 'Progression blockiert: hohes �oberlastungsrisiko.';
    }
  }
}


