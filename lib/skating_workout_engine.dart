enum SkatingWorkoutType {
  warmup,
  technique,
  intervals,
  flyingLap,
  starts,
  tempo,
  endurance,
  raceSimulation,
  cooldown,
  stretching,
}

enum SkatingIntensity { recovery, easy, moderate, hard, max }

class SkatingWorkoutBlock {
  final SkatingWorkoutType type;

  final String titleEs;
  final String titleEn;
  final String titleDe;

  final String descriptionEs;
  final String descriptionEn;
  final String descriptionDe;

  final int minutes;
  final double km;
  final SkatingIntensity intensity;

  final List<String> instructionsEs;
  final List<String> instructionsEn;
  final List<String> instructionsDe;

  const SkatingWorkoutBlock({
    required this.type,
    required this.titleEs,
    required this.titleEn,
    required this.titleDe,
    required this.descriptionEs,
    required this.descriptionEn,
    required this.descriptionDe,
    required this.minutes,
    required this.km,
    required this.intensity,
    required this.instructionsEs,
    required this.instructionsEn,
    required this.instructionsDe,
  });
}

class SkatingWorkoutSession {
  final String nameEs;
  final String nameEn;
  final String nameDe;

  final List<SkatingWorkoutBlock> blocks;

  const SkatingWorkoutSession({
    required this.nameEs,
    required this.nameEn,
    required this.nameDe,
    required this.blocks,
  });

  int get totalMinutes {
    return blocks.fold(0, (sum, block) => sum + block.minutes);
  }

  double get totalKm {
    return blocks.fold(0, (sum, block) => sum + block.km);
  }
}

class SkatingWorkoutEngine {
  static SkatingWorkoutSession generateSpeedSession({required bool isNovice}) {
    return SkatingWorkoutSession(
      nameEs: 'Velocidad: salidas + vueltas lanzadas',
      nameEn: 'Speed: starts + flying laps',
      nameDe: 'Speed: Starts + fliegende Runden',
      blocks: [
        _warmup(isNovice),
        _techniqueCurve(),
        _starts(isNovice),
        _flyingLaps(isNovice),
        _cooldown(),
        _stretching(),
      ],
    );
  }

  static SkatingWorkoutSession generateEnduranceSession({
    required bool isNovice,
  }) {
    return SkatingWorkoutSession(
      nameEs: 'Fondo: zona 2 + cambios de ritmo',
      nameEn: 'Endurance: zone 2 + pace changes',
      nameDe: 'Ausdauer: Zone 2 + Tempowechsel',
      blocks: [
        _warmup(isNovice),
        _techniqueEfficiency(),
        _enduranceZone2(isNovice),
        _tempoChanges(isNovice),
        _cooldown(),
        _stretching(),
      ],
    );
  }

  static SkatingWorkoutSession generateMixedSession({required bool isNovice}) {
    return SkatingWorkoutSession(
      nameEs: 'Mixto: técnica + intervalos',
      nameEn: 'Mixed: technique + intervals',
      nameDe: 'Gemischt: Technik + Intervalle',
      blocks: [
        _warmup(isNovice),
        _techniqueCurve(),
        _intervals(isNovice),
        _tempoChanges(isNovice),
        _cooldown(),
        _stretching(),
      ],
    );
  }

  static SkatingWorkoutSession generateCompetitionSession({
    required bool isNovice,
  }) {
    return SkatingWorkoutSession(
      nameEs: 'Simulación competitiva',
      nameEn: 'Competition simulation',
      nameDe: 'Wettkampfsimulation',
      blocks: [
        _warmup(isNovice),
        _starts(isNovice),
        _raceSimulation(isNovice),
        _cooldown(),
        _stretching(),
      ],
    );
  }

  static SkatingWorkoutSession generateRecoverySession() {
    return SkatingWorkoutSession(
      nameEs: 'Recuperación técnica suave',
      nameEn: 'Easy technical recovery',
      nameDe: 'Lockere technische Regeneration',
      blocks: [_easyWarmup(), _easyTechnique(), _cooldown(), _stretching()],
    );
  }

  static SkatingWorkoutBlock _warmup(bool isNovice) {
    return SkatingWorkoutBlock(
      type: SkatingWorkoutType.warmup,
      titleEs: 'Calentamiento progresivo',
      titleEn: 'Progressive warm-up',
      titleDe: 'Progressives Aufwärmen',
      descriptionEs:
          'Activación general en patines antes del trabajo principal.',
      descriptionEn: 'General skating activation before the main work.',
      descriptionDe: 'Allgemeine Aktivierung auf Skates vor dem Hauptteil.',
      minutes: isNovice ? 12 : 18,
      km: isNovice ? 2.0 : 4.0,
      intensity: SkatingIntensity.easy,
      instructionsEs: [
        '5 min rodaje suave.',
        'Movilidad dinámica de tobillo, cadera y columna.',
        '3 progresivos de 60 m al 70%.',
        'Mantener técnica limpia y respiración controlada.',
      ],
      instructionsEn: [
        '5 min easy skating.',
        'Dynamic ankle, hip and spine mobility.',
        '3 progressive 60 m accelerations at 70%.',
        'Keep clean technique and controlled breathing.',
      ],
      instructionsDe: [
        '5 min locker skaten.',
        'Dynamische Mobilität für Sprunggelenk, Hüfte und Wirbelsäule.',
        '3 progressive 60-m-Beschleunigungen bei 70%.',
        'Saubere Technik und kontrollierte Atmung halten.',
      ],
    );
  }

  static SkatingWorkoutBlock _easyWarmup() {
    return SkatingWorkoutBlock(
      type: SkatingWorkoutType.warmup,
      titleEs: 'Calentamiento suave',
      titleEn: 'Easy warm-up',
      titleDe: 'Lockeres Aufwärmen',
      descriptionEs: 'Rodaje suave para activar sin acumular fatiga.',
      descriptionEn: 'Easy skating to activate without adding fatigue.',
      descriptionDe:
          'Lockeres Skaten zur Aktivierung ohne zusätzliche Ermüdung.',
      minutes: 10,
      km: 1.5,
      intensity: SkatingIntensity.recovery,
      instructionsEs: [
        'Rodar suave.',
        'Evitar aceleraciones fuertes.',
        'Priorizar sensación corporal.',
      ],
      instructionsEn: [
        'Skate easy.',
        'Avoid hard accelerations.',
        'Prioritize body feeling.',
      ],
      instructionsDe: [
        'Locker skaten.',
        'Harte Beschleunigungen vermeiden.',
        'Körpergefühl priorisieren.',
      ],
    );
  }

  static SkatingWorkoutBlock _techniqueCurve() {
    return SkatingWorkoutBlock(
      type: SkatingWorkoutType.technique,
      titleEs: 'Técnica de curva',
      titleEn: 'Curve technique',
      titleDe: 'Kurventechnik',
      descriptionEs:
          'Trabajo técnico para mejorar entrada, apoyo y salida de curva.',
      descriptionEn: 'Technical work to improve curve entry, support and exit.',
      descriptionDe:
          'Technikarbeit zur Verbesserung von Kurveneingang, Abdruck und Ausgang.',
      minutes: 15,
      km: 2.0,
      intensity: SkatingIntensity.moderate,
      instructionsEs: [
        'Entrar bajo y estable.',
        'Mirar hacia la salida de la curva.',
        'Mantener presión lateral constante.',
        'Evitar cruzar con el tronco alto.',
      ],
      instructionsEn: [
        'Enter low and stable.',
        'Look toward curve exit.',
        'Keep constant lateral pressure.',
        'Avoid crossing with high torso.',
      ],
      instructionsDe: [
        'Tief und stabil einfahren.',
        'Zum Kurvenausgang schauen.',
        'Konstanten lateralen Druck halten.',
        'Nicht mit hohem Oberkörper kreuzen.',
      ],
    );
  }

  static SkatingWorkoutBlock _techniqueEfficiency() {
    return SkatingWorkoutBlock(
      type: SkatingWorkoutType.technique,
      titleEs: 'Técnica de eficiencia',
      titleEn: 'Efficiency technique',
      titleDe: 'Effizienztechnik',
      descriptionEs:
          'Trabajo de postura baja, empuje lateral y economía de movimiento.',
      descriptionEn: 'Low-position, lateral push and movement economy work.',
      descriptionDe: 'Tiefe Position, lateraler Abdruck und Bewegungsökonomie.',
      minutes: 15,
      km: 3.0,
      intensity: SkatingIntensity.easy,
      instructionsEs: [
        'Mantener cadera baja.',
        'Empujar lateral, no hacia atrás.',
        'Recuperar el patín cerca del centro.',
        'Respirar estable.',
      ],
      instructionsEn: [
        'Keep hips low.',
        'Push laterally, not backward.',
        'Recover skate close to center.',
        'Keep steady breathing.',
      ],
      instructionsDe: [
        'Hüfte tief halten.',
        'Seitlich drücken, nicht nach hinten.',
        'Skate nahe zur Mitte zurückführen.',
        'Ruhig atmen.',
      ],
    );
  }

  static SkatingWorkoutBlock _easyTechnique() {
    return SkatingWorkoutBlock(
      type: SkatingWorkoutType.technique,
      titleEs: 'Técnica suave',
      titleEn: 'Easy technique',
      titleDe: 'Lockere Technik',
      descriptionEs: 'Trabajo técnico sin fatiga para recuperar patrones.',
      descriptionEn: 'Low-fatigue technical work to restore movement patterns.',
      descriptionDe:
          'Technikarbeit ohne Ermüdung zur Wiederherstellung von Bewegungsmustern.',
      minutes: 20,
      km: 3.0,
      intensity: SkatingIntensity.recovery,
      instructionsEs: [
        'Rodar al 50-60%.',
        'Cuidar postura baja.',
        'No perseguir velocidad.',
      ],
      instructionsEn: [
        'Skate at 50-60%.',
        'Maintain low position.',
        'Do not chase speed.',
      ],
      instructionsDe: [
        'Bei 50-60% skaten.',
        'Tiefe Position halten.',
        'Keine Geschwindigkeit erzwingen.',
      ],
    );
  }

  static SkatingWorkoutBlock _starts(bool isNovice) {
    return SkatingWorkoutBlock(
      type: SkatingWorkoutType.starts,
      titleEs: 'Salidas',
      titleEn: 'Starts',
      titleDe: 'Starts',
      descriptionEs: 'Trabajo de aceleración desde parado o baja velocidad.',
      descriptionEn: 'Acceleration work from standing or low speed.',
      descriptionDe:
          'Beschleunigungsarbeit aus dem Stand oder niedriger Geschwindigkeit.',
      minutes: isNovice ? 12 : 18,
      km: isNovice ? 1.0 : 2.0,
      intensity: SkatingIntensity.max,
      instructionsEs: [
        isNovice ? '6 x 40 m' : '8 x 60 m',
        'Recuperación completa 2-3 min.',
        'Buscar potencia, no fatiga.',
        'Cortar la serie si la técnica cae.',
      ],
      instructionsEn: [
        isNovice ? '6 x 40 m' : '8 x 60 m',
        'Full recovery 2-3 min.',
        'Seek power, not fatigue.',
        'Stop the set if technique drops.',
      ],
      instructionsDe: [
        isNovice ? '6 x 40 m' : '8 x 60 m',
        'Vollständige Pause 2-3 min.',
        'Leistung suchen, nicht Ermüdung.',
        'Serie stoppen, wenn Technik abfällt.',
      ],
    );
  }

  static SkatingWorkoutBlock _flyingLaps(bool isNovice) {
    return SkatingWorkoutBlock(
      type: SkatingWorkoutType.flyingLap,
      titleEs: 'Vueltas lanzadas',
      titleEn: 'Flying laps',
      titleDe: 'Fliegende Runden',
      descriptionEs:
          'Entrada progresiva y vuelta rápida con velocidad controlada.',
      descriptionEn: 'Progressive entry and fast lap with controlled speed.',
      descriptionDe:
          'Progressiver Einstieg und schnelle Runde mit kontrollierter Geschwindigkeit.',
      minutes: isNovice ? 15 : 25,
      km: isNovice ? 3.0 : 6.0,
      intensity: SkatingIntensity.hard,
      instructionsEs: [
        isNovice ? '3 x 200 m lanzados' : '5 x 300 m lanzados',
        'Entrada progresiva.',
        'Mantener postura baja.',
        'Descanso amplio entre repeticiones.',
      ],
      instructionsEn: [
        isNovice ? '3 x 200 m flying' : '5 x 300 m flying',
        'Progressive entry.',
        'Maintain low position.',
        'Long rest between reps.',
      ],
      instructionsDe: [
        isNovice ? '3 x 200 m fliegend' : '5 x 300 m fliegend',
        'Progressiver Einstieg.',
        'Tiefe Position halten.',
        'Lange Pause zwischen Wiederholungen.',
      ],
    );
  }

  static SkatingWorkoutBlock _intervals(bool isNovice) {
    return SkatingWorkoutBlock(
      type: SkatingWorkoutType.intervals,
      titleEs: 'Intervalos específicos',
      titleEn: 'Specific intervals',
      titleDe: 'Spezifische Intervalle',
      descriptionEs: 'Series con intensidad alta y recuperación controlada.',
      descriptionEn: 'High-intensity repetitions with controlled recovery.',
      descriptionDe: 'Hochintensive Wiederholungen mit kontrollierter Pause.',
      minutes: isNovice ? 18 : 30,
      km: isNovice ? 4.0 : 8.0,
      intensity: SkatingIntensity.hard,
      instructionsEs: [
        isNovice ? '6 x 200 m' : '8 x 400 m',
        'Recuperar 1:1 o 1:2 según nivel.',
        'Mantener ritmo constante.',
        'No salir demasiado fuerte.',
      ],
      instructionsEn: [
        isNovice ? '6 x 200 m' : '8 x 400 m',
        'Recover 1:1 or 1:2 depending on level.',
        'Keep steady pace.',
        'Do not start too hard.',
      ],
      instructionsDe: [
        isNovice ? '6 x 200 m' : '8 x 400 m',
        'Pause 1:1 oder 1:2 je nach Niveau.',
        'Konstantes Tempo halten.',
        'Nicht zu schnell starten.',
      ],
    );
  }

  static SkatingWorkoutBlock _enduranceZone2(bool isNovice) {
    return SkatingWorkoutBlock(
      type: SkatingWorkoutType.endurance,
      titleEs: 'Rodaje zona 2',
      titleEn: 'Zone 2 skating',
      titleDe: 'Zone-2-Skaten',
      descriptionEs:
          'Base aeróbica sostenible para patinadores de fondo y mixtos.',
      descriptionEn:
          'Sustainable aerobic base for endurance and mixed skaters.',
      descriptionDe: 'Nachhaltige aerobe Basis für Ausdauer- und Mischskater.',
      minutes: isNovice ? 35 : 60,
      km: isNovice ? 10.0 : 22.0,
      intensity: SkatingIntensity.moderate,
      instructionsEs: [
        'Mantener respiración controlada.',
        'Ritmo conversacional.',
        'Postura estable.',
        'No convertirlo en carrera.',
      ],
      instructionsEn: [
        'Keep controlled breathing.',
        'Conversational pace.',
        'Stable posture.',
        'Do not turn it into a race.',
      ],
      instructionsDe: [
        'Kontrollierte Atmung halten.',
        'Gesprächstempo.',
        'Stabile Position.',
        'Nicht zum Rennen machen.',
      ],
    );
  }

  static SkatingWorkoutBlock _tempoChanges(bool isNovice) {
    return SkatingWorkoutBlock(
      type: SkatingWorkoutType.tempo,
      titleEs: 'Cambios de ritmo',
      titleEn: 'Pace changes',
      titleDe: 'Tempowechsel',
      descriptionEs: 'Cambios controlados para mejorar respuesta táctica.',
      descriptionEn: 'Controlled pace changes to improve tactical response.',
      descriptionDe:
          'Kontrollierte Tempowechsel zur Verbesserung taktischer Reaktion.',
      minutes: isNovice ? 12 : 20,
      km: isNovice ? 2.0 : 5.0,
      intensity: SkatingIntensity.hard,
      instructionsEs: [
        isNovice
            ? '6 x 20 s rápido / 60 s suave'
            : '10 x 30 s rápido / 60 s suave',
        'Acelerar progresivamente.',
        'No romper técnica.',
      ],
      instructionsEn: [
        isNovice ? '6 x 20 s fast / 60 s easy' : '10 x 30 s fast / 60 s easy',
        'Accelerate progressively.',
        'Do not break technique.',
      ],
      instructionsDe: [
        isNovice
            ? '6 x 20 s schnell / 60 s locker'
            : '10 x 30 s schnell / 60 s locker',
        'Progressiv beschleunigen.',
        'Technik nicht verlieren.',
      ],
    );
  }

  static SkatingWorkoutBlock _raceSimulation(bool isNovice) {
    return SkatingWorkoutBlock(
      type: SkatingWorkoutType.raceSimulation,
      titleEs: 'Simulación de carrera',
      titleEn: 'Race simulation',
      titleDe: 'Rennsimulation',
      descriptionEs:
          'Trabajo táctico y competitivo con esfuerzos similares a carrera.',
      descriptionEn: 'Tactical and competitive work with race-like efforts.',
      descriptionDe:
          'Taktische und wettkampfnahe Arbeit mit rennähnlichen Belastungen.',
      minutes: isNovice ? 25 : 40,
      km: isNovice ? 5.0 : 10.0,
      intensity: SkatingIntensity.max,
      instructionsEs: [
        isNovice ? '2 bloques simulados' : '3 bloques simulados',
        'Practicar salida, ubicación y remate.',
        'Recuperación completa.',
        'Finalizar si hay pérdida técnica.',
      ],
      instructionsEn: [
        isNovice ? '2 simulated blocks' : '3 simulated blocks',
        'Practice start, positioning and final sprint.',
        'Full recovery.',
        'Stop if technique drops.',
      ],
      instructionsDe: [
        isNovice ? '2 simulierte Blöcke' : '3 simulierte Blöcke',
        'Start, Positionierung und Endspurt üben.',
        'Vollständige Erholung.',
        'Stoppen, wenn Technik abfällt.',
      ],
    );
  }

  static SkatingWorkoutBlock _cooldown() {
    return SkatingWorkoutBlock(
      type: SkatingWorkoutType.cooldown,
      titleEs: 'Vuelta a la calma',
      titleEn: 'Cooldown',
      titleDe: 'Cooldown',
      descriptionEs:
          'Bajar pulsaciones y soltar piernas después del trabajo principal.',
      descriptionEn: 'Lower heart rate and loosen legs after main work.',
      descriptionDe:
          'Herzfrequenz senken und Beine nach dem Hauptteil lockern.',
      minutes: 10,
      km: 2.0,
      intensity: SkatingIntensity.recovery,
      instructionsEs: [
        'Rodar suave.',
        'Respiración nasal si es posible.',
        'No hacer aceleraciones.',
      ],
      instructionsEn: [
        'Skate easy.',
        'Use nasal breathing if possible.',
        'Do not accelerate.',
      ],
      instructionsDe: [
        'Locker skaten.',
        'Wenn möglich durch die Nase atmen.',
        'Nicht beschleunigen.',
      ],
    );
  }

  static SkatingWorkoutBlock _stretching() {
    return SkatingWorkoutBlock(
      type: SkatingWorkoutType.stretching,
      titleEs: 'Estiramiento y movilidad',
      titleEn: 'Stretching and mobility',
      titleDe: 'Dehnen und Mobilität',
      descriptionEs: 'Trabajo final para recuperar cadera, espalda y piernas.',
      descriptionEn: 'Final work to recover hips, back and legs.',
      descriptionDe:
          'Abschlussarbeit zur Regeneration von Hüfte, Rücken und Beinen.',
      minutes: 12,
      km: 0,
      intensity: SkatingIntensity.recovery,
      instructionsEs: [
        'Flexores de cadera 45 s por lado.',
        'Glúteo 45 s por lado.',
        'Isquios 45 s por lado.',
        'Respiración lenta 2 min.',
      ],
      instructionsEn: [
        'Hip flexors 45 s per side.',
        'Glute stretch 45 s per side.',
        'Hamstrings 45 s per side.',
        'Slow breathing 2 min.',
      ],
      instructionsDe: [
        'Hüftbeuger 45 s pro Seite.',
        'Gesä�Y 45 s pro Seite.',
        'Hamstrings 45 s pro Seite.',
        'Langsame Atmung 2 min.',
      ],
    );
  }
}


