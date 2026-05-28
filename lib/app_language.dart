import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { es, en, de }

class AppLanguageNotifier extends ChangeNotifier {
  static const String _storageKey = 'speedskate_app_language_v1';

  AppLanguage _current = AppLanguage.es;
  bool _loaded = false;

  AppLanguageNotifier() {
    _loadSavedLanguage();
  }

  AppLanguage get current => _current;

  bool get loaded => _loaded;

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);

      if (saved != null && saved.isNotEmpty) {
        _current = AppLanguage.values.firstWhere(
          (language) => language.name == saved,
          orElse: () => AppLanguage.es,
        );
      }
    } catch (_) {
      _current = AppLanguage.es;
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> changeLanguage(AppLanguage language) async {
    _current = language;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, language.name);
    } catch (_) {
      // La app no debe fallar si no se puede guardar el idioma.
    }
  }
}


