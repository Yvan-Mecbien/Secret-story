import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Theme ───────────────────────────────────────────────────────────────────
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier(super.initial);

  static const _key = 'theme_mode';

  /// Charge la préférence sauvegardée (appelé avant runApp)
  static Future<ThemeMode> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    return switch (saved) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  Future<void> toggle() async {
    await setMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (_) => ThemeNotifier(ThemeMode.system),
);

// ─── Locale ──────────────────────────────────────────────────────────────────
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(super.initial);

  static const _key = 'locale';

  static Future<Locale> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key) ?? 'fr';
    return Locale(saved);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (_) => LocaleNotifier(const Locale('fr')),
);
