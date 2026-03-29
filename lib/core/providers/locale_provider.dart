import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// LocaleProvider
///
/// Manages the app's selected language.
/// Persists the choice to SharedPreferences so it survives app restarts.
/// Driver picks language on the HoldingScreen — saved once, applied everywhere.
class LocaleProvider extends ChangeNotifier {
  static const String _prefKey = 'selected_locale';

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  /// Supported locales — order matches the flag picker on HoldingScreen
  static const List<Locale> supportedLocales = [
    Locale('en'),  // English
    Locale('ar'),  // Arabic (RTL)
    Locale('fr'),  // French
    Locale('es'),  // Spanish
    Locale('pt'),  // Portuguese
    Locale('pl'),  // Polish
    Locale('hi'),  // Hindi
    Locale('de'),  // German
  ];

  /// Load saved locale on app start
  Future<void> loadSavedLocale() async {
    final prefs      = await SharedPreferences.getInstance();
    final savedCode  = prefs.getString(_prefKey);
    if (savedCode != null) {
      _locale = Locale(savedCode);
      notifyListeners();
    }
  }

  /// Set and persist a new locale
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, locale.languageCode);
  }

  /// Language metadata for the flag picker UI
  static const List<Map<String, String>> languages = [
    {'code': 'en', 'flag': '🇬🇧', 'name': 'English'},
    {'code': 'ar', 'flag': '🇸🇦', 'name': 'العربية'},
    {'code': 'fr', 'flag': '🇫🇷', 'name': 'Français'},
    {'code': 'es', 'flag': '🇪🇸', 'name': 'Español'},
    {'code': 'pt', 'flag': '🇧🇷', 'name': 'Português'},
    {'code': 'pl', 'flag': '🇵🇱', 'name': 'Polski'},
    {'code': 'hi', 'flag': '🇮🇳', 'name': 'हिन्दी'},
    {'code': 'de', 'flag': '🇩🇪', 'name': 'Deutsch'},
  ];
}
