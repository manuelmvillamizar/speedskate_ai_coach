class SpeedSkateSessionInterpretation {
  final double speed;
  final double skatingStrength;
  final double technique;
  final double balance;
  final double curves;
  final double starts;
  final double endurance;
  final double plyometric;
  final double gymStrength;
  final double recovery;

  final double neuralStress;
  final double muscleStress;
  final double tendonStress;
  final double metabolicStress;
  final double technicalStress;
  final double coordinationStress;
  final double mechanicalStress;
  final double recoveryCost;

  final List<String> detectedTags;
  final String summary;

  const SpeedSkateSessionInterpretation({
    required this.speed,
    required this.skatingStrength,
    required this.technique,
    required this.balance,
    required this.curves,
    required this.starts,
    required this.endurance,
    required this.plyometric,
    required this.gymStrength,
    required this.recovery,
    required this.neuralStress,
    required this.muscleStress,
    required this.tendonStress,
    required this.metabolicStress,
    required this.technicalStress,
    required this.coordinationStress,
    required this.mechanicalStress,
    required this.recoveryCost,
    required this.detectedTags,
    required this.summary,
  });
}

class SpeedSkateSignalInterpreter {
  static SpeedSkateSessionInterpretation interpret(String rawText) {
    final text = rawText.toLowerCase();

    double speed = 0;
    double skatingStrength = 0;
    double technique = 0;
    double balance = 0;
    double curves = 0;
    double starts = 0;
    double endurance = 0;
    double plyometric = 0;
    double gymStrength = 0;
    double recovery = 0;

    final tags = <String>[];

    bool hasAny(List<String> words) {
      return words.any((word) => text.contains(word));
    }

    void addTag(String tag) {
      if (!tags.contains(tag)) tags.add(tag);
    }

    if (hasAny([
      'velocidad',
      'sprint',
      'sprints',
      'rápido',
      'rapido',
      'máxima velocidad',
      'maxima velocidad',
      'remate',
    ])) {
      speed = 85;
      addTag('velocidad');
    }

    if (hasAny([
      'salida',
      'salidas',
      'aceleracion',
      'aceleración',
      'arranque',
      '30m',
      '30 m',
      '50m',
      '50 m',
    ])) {
      starts = 90;
      speed = speed < 75 ? 75 : speed;
      addTag('salidas');
    }

    if (hasAny([
      'curva',
      'curvas',
      'peralte',
      'entrada curva',
      'salida curva',
    ])) {
      curves = 85;
      technique = technique < 70 ? 70 : technique;
      addTag('curvas');
    }

    if (hasAny([
      'técnica',
      'tecnica',
      'empuje',
      'empujes',
      'doble empuje',
      'posición',
      'posicion',
      'postura',
      'braceo',
      'apoyo',
    ])) {
      technique = technique < 80 ? 80 : technique;
      addTag('técnica');
    }

    if (hasAny([
      'equilibrio',
      'balance',
      'estabilidad',
      'control',
      'unipodal',
      'una pierna',
      '1 pierna',
    ])) {
      balance = 85;

      addTag('equilibrio');
    }

    if (hasAny([
      'fuerza sobre patines',
      'fuerza en patines',
      'sentadilla sobre patines',
      'sentadillas sobre patines',
      'sentadilla unipodal',
      'sentadillas unipodales',
      'empuje con fuerza',
      'posición baja',
      'posicion baja',
    ])) {
      skatingStrength = 90;
      technique = technique < 65 ? 65 : technique;
      balance = balance < 55 ? 55 : balance;
      addTag('fuerza sobre patines');
    }

    if (hasAny([
      'gimnasio',
      'pesas',
      'fuerza máxima',
      'fuerza maxima',
      'sentadilla',
      'peso muerto',
      'hip thrust',
      'zancada',
      'squat',
      'deadlift',
    ])) {
      gymStrength = 85;
      addTag('fuerza gimnasio');
    }

    if (hasAny([
      'pliometría',
      'pliometria',
      'saltos',
      'saltabilidad',
      'bounds',
      'reactivo',
      'reactividad',
    ])) {
      plyometric = 85;
      addTag('pliometría');
    }

    if (hasAny([
      'fondo',
      'resistencia',
      'aeróbico',
      'aerobico',
      'rodaje',
      'continuo',
      'tempo',
      'series largas',
    ])) {
      endurance = 80;
      addTag('resistencia');
    }

    if (hasAny([
      'recuperación',
      'recuperacion',
      'regenerativo',
      'suave',
      'movilidad',
      'descarga',
    ])) {
      recovery = 85;
      addTag('recuperación');
    }

    final neuralStress = [
      speed,
      starts,
      plyometric,
      skatingStrength * 0.65,
    ].reduce((a, b) => a > b ? a : b).clamp(0, 100).toDouble();

    final muscleStress = [
      skatingStrength,
      gymStrength,
      plyometric * 0.75,
      endurance * 0.45,
    ].reduce((a, b) => a > b ? a : b).clamp(0, 100).toDouble();

    final tendonStress = [
      plyometric,
      starts * 0.75,
      curves * 0.55,
      skatingStrength * 0.60,
    ].reduce((a, b) => a > b ? a : b).clamp(0, 100).toDouble();

    final metabolicStress = [
      endurance,
      speed * 0.45,
      starts * 0.35,
    ].reduce((a, b) => a > b ? a : b).clamp(0, 100).toDouble();

    final technicalStress = [
      technique,
      curves,
      balance,
      skatingStrength * 0.55,
    ].reduce((a, b) => a > b ? a : b).clamp(0, 100).toDouble();

    final coordinationStress = [
      balance,
      curves * 0.65,
      technique * 0.55,
    ].reduce((a, b) => a > b ? a : b).clamp(0, 100).toDouble();

    final mechanicalStress = [
      skatingStrength,
      curves * 0.70,
      plyometric,
      gymStrength * 0.80,
    ].reduce((a, b) => a > b ? a : b).clamp(0, 100).toDouble();

    final recoveryCost = [
      neuralStress,
      muscleStress,
      tendonStress,
      metabolicStress,
    ].reduce((a, b) => a > b ? a : b).clamp(0, 100).toDouble();

    final summary = tags.isEmpty
        ? 'No se detectó un estímulo específico.'
        : 'Estímulos detectados: ${tags.join(', ')}.';

    return SpeedSkateSessionInterpretation(
      speed: speed,
      skatingStrength: skatingStrength,
      technique: technique,
      balance: balance,
      curves: curves,
      starts: starts,
      endurance: endurance,
      plyometric: plyometric,
      gymStrength: gymStrength,
      recovery: recovery,
      neuralStress: neuralStress,
      muscleStress: muscleStress,
      tendonStress: tendonStress,
      metabolicStress: metabolicStress,
      technicalStress: technicalStress,
      coordinationStress: coordinationStress,
      mechanicalStress: mechanicalStress,
      recoveryCost: recoveryCost,
      detectedTags: tags,
      summary: summary,
    );
  }
}
