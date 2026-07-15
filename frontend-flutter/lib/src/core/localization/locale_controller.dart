import 'package:flutter/material.dart';

import 'locale_storage.dart';

class LocaleController extends ChangeNotifier {
  LocaleController({
    required LocaleStorage storage,
    Locale initialLocale = const Locale('en'),
  }) : _storage = storage,
       _locale = _supportedLocale(initialLocale);

  static const supportedLocales = <Locale>[Locale('en'), Locale('vi')];

  final LocaleStorage _storage;
  Locale _locale;

  Locale get locale => _locale;

  Future<void> load() async {
    try {
      final savedLanguageCode = await _storage.readLanguageCode();
      if (savedLanguageCode == null) {
        return;
      }
      final savedLocale = _matchingSupportedLocale(Locale(savedLanguageCode));
      if (savedLocale != null) {
        _updateLocale(savedLocale);
      }
    } on Object {
      // A storage failure must not prevent the application from starting.
    }
  }

  Future<void> setLocale(Locale locale) async {
    final supportedLocale = _supportedLocale(locale);
    if (supportedLocale == _locale) {
      return;
    }

    _locale = supportedLocale;
    notifyListeners();
    try {
      await _storage.saveLanguageCode(_locale.languageCode);
    } on Object {
      // Keep the selected language active even if persistence is unavailable.
    }
  }

  void _updateLocale(Locale locale) {
    final supportedLocale = _supportedLocale(locale);
    if (supportedLocale == _locale) {
      return;
    }
    _locale = supportedLocale;
    notifyListeners();
  }

  static Locale _supportedLocale(Locale locale) {
    return _matchingSupportedLocale(locale) ?? const Locale('en');
  }

  static Locale? _matchingSupportedLocale(Locale locale) {
    for (final supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return supportedLocale;
      }
    }
    return null;
  }
}
