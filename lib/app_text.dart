import 'app_language.dart';

class AppText {
  static String t(AppLanguage l, String es, String en, String de) {
    switch (l) {
      case AppLanguage.es:
        return es;
      case AppLanguage.en:
        return en;
      case AppLanguage.de:
        return de;
    }
  }
}


