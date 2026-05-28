class GymExerciseImageMapper {
  static const String _basePath = 'assets/images/strength/cuts/';
  static const String _videoBasePath = 'assets/videos/exercises/';

  static String? imageFor(String rawName) {
    final name = _normalize(rawName);

    if (_has(name, ['back squat', 'sentadilla trasera'])) {
      return '${_basePath}back_squat.png';
    }

    if (_has(name, ['front squat', 'sentadilla frontal'])) {
      return '${_basePath}front_squat.png';
    }

    if (_has(name, ['trap bar', 'trapbar'])) {
      return '${_basePath}trap_bar_deadlift.png';
    }

    if (_has(name, ['sumo deadlift', 'peso muerto sumo'])) {
      return '${_basePath}sumo_deadlift.png';
    }

    if (_has(name, ['deadlift', 'peso muerto'])) {
      return '${_basePath}deadlift.png';
    }

    if (_has(name, ['dumbbell lunge', 'zancada', 'lunge'])) {
      return '${_basePath}dumbbell_lunge.png';
    }

    if (_has(name, ['farmer carry', 'farmer walk', 'paseo granjero'])) {
      return '${_basePath}farmer_carry.png';
    }

    if (_has(name, ['step up', 'step-up', 'subida al banco'])) {
      return '${_basePath}step_up.png';
    }

    if (_has(name, ['hip thrust', 'empuje de cadera'])) {
      return '${_basePath}hip_thrust.png';
    }

    if (_has(name, ['reverse lunge', 'zancada atras'])) {
      return '${_basePath}reverse_lunge.png';
    }

    if (_has(name, ['pistol squat', 'sentadilla pistol'])) {
      return '${_basePath}pistol_squat.png';
    }

    return null;
  }

  static String? videoAssetFor(String rawName) {
    final name = _normalize(rawName);

    if (_has(name, ['back squat', 'sentadilla trasera'])) {
      return '${_videoBasePath}back_squat.mp4';
    }

    if (_has(name, ['front squat', 'sentadilla frontal'])) {
      return '${_videoBasePath}front_squat.mp4';
    }

    if (_has(name, ['trap bar', 'trapbar'])) {
      return '${_videoBasePath}trap_bar_deadlift.mp4';
    }

    if (_has(name, ['sumo deadlift'])) {
      return '${_videoBasePath}sumo_deadlift.mp4';
    }

    if (_has(name, ['deadlift'])) {
      return '${_videoBasePath}deadlift.mp4';
    }

    if (_has(name, ['hip thrust'])) {
      return '${_videoBasePath}hip_thrust.mp4';
    }

    if (_has(name, ['step up'])) {
      return '${_videoBasePath}step_up.mp4';
    }

    if (_has(name, ['reverse lunge'])) {
      return '${_videoBasePath}reverse_lunge.mp4';
    }

    if (_has(name, ['dumbbell lunge'])) {
      return '${_videoBasePath}dumbbell_lunge.mp4';
    }

    if (_has(name, ['farmer carry'])) {
      return '${_videoBasePath}farmer_carry.mp4';
    }

    if (_has(name, ['pistol squat'])) {
      return '${_videoBasePath}pistol_squat.mp4';
    }

    return null;
  }

  static String? videoUrlFor(String rawName) {
    final name = _normalize(rawName);

    if (_has(name, ['back squat'])) {
      return 'https://www.youtube.com/results?search_query=back+squat';
    }

    if (_has(name, ['front squat'])) {
      return 'https://www.youtube.com/results?search_query=front+squat';
    }

    if (_has(name, ['trap bar'])) {
      return 'https://www.youtube.com/results?search_query=trap+bar+deadlift';
    }

    if (_has(name, ['deadlift'])) {
      return 'https://www.youtube.com/results?search_query=deadlift';
    }

    if (_has(name, ['hip thrust'])) {
      return 'https://www.youtube.com/results?search_query=hip+thrust';
    }

    if (_has(name, ['step up'])) {
      return 'https://www.youtube.com/results?search_query=step+up+exercise';
    }

    if (_has(name, ['lunge'])) {
      return 'https://www.youtube.com/results?search_query=dumbbell+lunge';
    }

    if (_has(name, ['farmer carry'])) {
      return 'https://www.youtube.com/results?search_query=farmer+carry';
    }

    if (_has(name, ['pistol squat'])) {
      return 'https://www.youtube.com/results?search_query=pistol+squat';
    }

    return null;
  }

  static bool _has(String text, List<String> keys) {
    return keys.any((key) => text.contains(_normalize(key)));
  }

  static String normalize(String value) => _normalize(value);

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

