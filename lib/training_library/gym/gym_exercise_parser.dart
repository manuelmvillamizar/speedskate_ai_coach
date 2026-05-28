import 'gym_exercise_image_mapper.dart';

class GymExerciseParsed {
  final String name;
  final String rawText;

  final String? prescription;
  final String? load;
  final String? rest;
  final String? tempo;
  final String? imagePath;

  final String? rpe;
  final String? rir;
  final String? percentage;
  final String? contrastExercise;
  final String? physiologicalGoal;

  final String? videoUrl;
  final String? videoAssetPath;

  final bool hasVideo;
  final bool explosive;
  final bool unilateral;

  const GymExerciseParsed({
    required this.name,
    required this.rawText,
    this.prescription,
    this.load,
    this.rest,
    this.tempo,
    this.imagePath,
    this.rpe,
    this.rir,
    this.percentage,
    this.contrastExercise,
    this.physiologicalGoal,
    this.videoUrl,
    this.videoAssetPath,
    this.hasVideo = false,
    this.explosive = false,
    this.unilateral = false,
  });
}

class GymExerciseParser {
  static List<GymExerciseParsed> parse(List<String> rawItems) {
    final parsed = <GymExerciseParsed>[];

    for (final raw in rawItems) {
      final text = raw.trim();

      if (text.isEmpty) continue;

      final name = _detectExerciseName(text);

      if (name == null) continue;

      final videoUrl = GymExerciseImageMapper.videoUrlFor(name);
      final videoAssetPath = GymExerciseImageMapper.videoAssetFor(name);

      parsed.add(
        GymExerciseParsed(
          name: name,
          rawText: text,
          prescription: _extractPrescription(text),
          load: _extractLoad(text),
          rest: _extractRest(text),
          tempo: _extractTempo(text),
          imagePath: GymExerciseImageMapper.imageFor(name),
          rpe: _extractRpe(text),
          rir: _extractRir(text),
          percentage: _extractPercentage(text),
          contrastExercise: _detectContrast(text),
          physiologicalGoal: _goalFor(name),
          videoUrl: videoUrl,
          videoAssetPath: videoAssetPath,
          hasVideo: videoUrl != null || videoAssetPath != null,
          explosive: _isExplosive(text),
          unilateral: _isUnilateral(name),
        ),
      );
    }

    return _deduplicate(parsed);
  }

  static String? _detectExerciseName(String raw) {
    final text = GymExerciseImageMapper.normalize(raw);

    if (text.contains('front squat') || text.contains('sentadilla frontal')) {
      return 'Front Squat';
    }

    if (text.contains('back squat') ||
        text.contains('sentadilla trasera') ||
        text.contains('sentadilla')) {
      return 'Back Squat';
    }

    if (text.contains('trap bar') || text.contains('trapbar')) {
      return 'Trap Bar Deadlift';
    }

    if (text.contains('peso muerto sumo') || text.contains('sumo deadlift')) {
      return 'Sumo Deadlift';
    }

    if (text.contains('peso muerto') ||
        text.contains('deadlift') ||
        text.contains('rumano')) {
      return 'Deadlift';
    }

    if (text.contains('hip thrust') || text.contains('empuje de cadera')) {
      return 'Hip Thrust';
    }

    if (text.contains('step up') || text.contains('subida al banco')) {
      return 'Step Up';
    }

    if (text.contains('reverse lunge') || text.contains('zancada atras')) {
      return 'Reverse Lunge';
    }

    if (text.contains('zancada') || text.contains('lunge')) {
      return 'Dumbbell Lunge';
    }

    if (text.contains('farmer') || text.contains('granjero')) {
      return 'Farmer Carry';
    }

    if (text.contains('pistol')) {
      return 'Pistol Squat';
    }

    return null;
  }

  static String? _extractPrescription(String text) {
    final patterns = [
      RegExp(r'\b\d+\s*[x�-]\s*\d+\b', caseSensitive: false),
      RegExp(r'\b\d+\s*series?\b', caseSensitive: false),
      RegExp(r'\b\d+\s*reps?\b', caseSensitive: false),
      RegExp(r'\b\d+\s*repeticiones\b', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);

      if (match != null) {
        return match.group(0);
      }
    }

    return null;
  }

  static String? _extractLoad(String text) {
    final patterns = [
      RegExp(r'\b\d+\s*%\s*1rm\b', caseSensitive: false),
      RegExp(r'\b\d+\s*%\b', caseSensitive: false),
      RegExp(r'\brpe\s*\d+(\.\d+)?\b', caseSensitive: false),
      RegExp(r'\brir\s*\d+\b', caseSensitive: false),
      RegExp(r'\bpesado\b', caseSensitive: false),
      RegExp(r'\bmoderado\b', caseSensitive: false),
      RegExp(r'\bligero\b', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);

      if (match != null) {
        return match.group(0);
      }
    }

    return null;
  }

  static String? _extractRest(String text) {
    final patterns = [
      RegExp(
        r'\bdescanso\s*\d+\s*(s|min|segundos|minutos)\b',
        caseSensitive: false,
      ),
      RegExp(r'\brest\s*\d+\s*(s|min)\b', caseSensitive: false),
      RegExp(r'\b\d+\s*(s|min)\s*descanso\b', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);

      if (match != null) {
        return match.group(0);
      }
    }

    return null;
  }

  static String? _extractTempo(String text) {
    final match = RegExp(
      r'\btempo\s*\d+\s*[-:]\s*\d+\s*[-:]\s*\d+\b',
      caseSensitive: false,
    ).firstMatch(text);

    return match?.group(0);
  }

  static String? _extractRpe(String text) {
    final match = RegExp(
      r'\brpe\s*\d+(\.\d+)?\b',
      caseSensitive: false,
    ).firstMatch(text);

    return match?.group(0)?.toUpperCase();
  }

  static String? _extractRir(String text) {
    final match = RegExp(
      r'\brir\s*\d+\b',
      caseSensitive: false,
    ).firstMatch(text);

    return match?.group(0)?.toUpperCase();
  }

  static String? _extractPercentage(String text) {
    final match = RegExp(
      r'\b\d+\s*%',
      caseSensitive: false,
    ).firstMatch(text);

    return match?.group(0);
  }

  static String? _detectContrast(String text) {
    final normalized = GymExerciseImageMapper.normalize(text);

    if (normalized.contains('squat jump')) {
      return 'Squat Jumps';
    }

    if (normalized.contains('jump')) {
      return 'Squat Jumps';
    }

    if (normalized.contains('bound')) {
      return 'Bounds';
    }

    if (normalized.contains('aceleracion')) {
      return 'Acceleration Sprint';
    }

    if (normalized.contains('salto')) {
      return 'Reactive Jumps';
    }

    return null;
  }

  static bool _isExplosive(String text) {
    final normalized = GymExerciseImageMapper.normalize(text);

    return normalized.contains('explosivo') ||
        normalized.contains('power') ||
        normalized.contains('jump') ||
        normalized.contains('salto') ||
        normalized.contains('reactivo') ||
        normalized.contains('velocidad') ||
        normalized.contains('transferencia');
  }

  static bool _isUnilateral(String exercise) {
    return exercise == 'Step Up' ||
        exercise == 'Reverse Lunge' ||
        exercise == 'Dumbbell Lunge' ||
        exercise == 'Pistol Squat';
  }

  static String _goalFor(String exercise) {
    switch (exercise) {
      case 'Back Squat':
        return 'Desarrollar fuerza máxima y transferencia a aceleración.';
      case 'Front Squat':
        return 'Mejorar postura específica y stiffness de patinaje.';
      case 'Deadlift':
      case 'Trap Bar Deadlift':
        return 'Potenciar producción de fuerza horizontal y cadera.';
      case 'Sumo Deadlift':
        return 'Desarrollar fuerza de cadera y estabilidad en base amplia.';
      case 'Hip Thrust':
        return 'Transferir potencia hacia extensión explosiva de cadera.';
      case 'Step Up':
        return 'Desarrollar fuerza unilateral específica.';
      case 'Reverse Lunge':
      case 'Dumbbell Lunge':
        return 'Estabilidad, fuerza unilateral y control mecánico.';
      case 'Farmer Carry':
        return 'Rigidez de core y estabilidad global bajo carga.';
      case 'Pistol Squat':
        return 'Control unilateral, estabilidad y fuerza específica.';
      default:
        return 'Desarrollo de fuerza específica para speed skating.';
    }
  }

  static List<GymExerciseParsed> _deduplicate(
    List<GymExerciseParsed> items,
  ) {
    final seen = <String>{};
    final result = <GymExerciseParsed>[];

    for (final item in items) {
      final key = GymExerciseImageMapper.normalize(item.name);

      if (seen.contains(key)) continue;

      seen.add(key);
      result.add(item);
    }

    return result;
  }
}

