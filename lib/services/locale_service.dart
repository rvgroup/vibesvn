import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'storage_service.dart';

class LocaleService extends ChangeNotifier {
  static final LocaleService _instance = LocaleService._internal();
  factory LocaleService() => _instance;
  LocaleService._internal();

  static const String _localeKey = 'app_locale';
  static const String _defaultLocale = 'en';
  
  Locale _currentLocale = const Locale(_defaultLocale);
  Map<String, String> _translations = {};
  
  Locale get currentLocale => _currentLocale;
  
  static List<Locale> get supportedLocales => const [
    Locale('en', 'US'), // English
    Locale('ru', 'RU'), // Russian
  ];
  
  static Map<String, String> get localeNames => {
    'en': 'English',
    'ru': 'Русский',
  };

  Future<void> initialize() async {
    final savedLocale = await StorageService.getLocale();
    await setLocale(savedLocale ?? _defaultLocale);
  }

  Future<void> setLocale(String localeCode) async {
    try {
      // Load translations for the new locale
      final translations = await _loadTranslations(localeCode);
      
      _currentLocale = Locale(localeCode);
      _translations = translations;
      
      // Save preference
      await StorageService.saveLocale(localeCode);
      
      notifyListeners();
    } catch (e) {
      print('Error loading locale $localeCode: $e');
      // Fallback to default locale
      if (localeCode != _defaultLocale) {
        await setLocale(_defaultLocale);
      }
    }
  }

  Future<Map<String, String>> _loadTranslations(String localeCode) async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/translations/$localeCode.json'
      );
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      
      return jsonMap.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      print('Error loading translations for $localeCode: $e');
      return {};
    }
  }

  String translate(String key) {
    return _translations[key] ?? key;
  }

  // Convenience method for shorter syntax
  String t(String key) => translate(key);

  String getCurrentLocaleCode() => _currentLocale.languageCode;
  
  bool isCurrentLocale(String localeCode) => _currentLocale.languageCode == localeCode;
}

// Extension for easy access to translations
extension Translations on String {
  String tr(BuildContext context) {
    return LocaleService().t(this);
  }
}
