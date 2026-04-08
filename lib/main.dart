import 'package:app/features/auth/StorageService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/l10n/app_localizations.dart';

import 'shared/theme/app_theme.dart';
import 'shared/theme/theme_provider.dart';
import 'features/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser StorageService
  await StorageService.init();

  await Supabase.initialize(
    url: 'https://sxswlrcbolmmjkctjmzv.supabase.co', // ← Remplacer
    anonKey: 'sb_publishable_4sO6Q3VCZGyBOd5o6Ns_0Q_b7IxtlJe',
    // ← Remplacer
  );

  // Charger les préférences persisées
  final themeMode = await ThemeNotifier.load();
  final locale = await LocaleNotifier.load();

  runApp(
    ProviderScope(
      overrides: [
        themeProvider.overrideWith((_) => ThemeNotifier(themeMode)),
        localeProvider.overrideWith((_) => LocaleNotifier(locale)),
      ],
      child: const SecretStoryApp(),
    ),
  );
}

class SecretStoryApp extends ConsumerWidget {
  const SecretStoryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Secret Story',
      debugShowCheckedModeBanner: false,
      // ── Thèmes ──────────────────────────────────────────────────────────
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      // ── Localisation ────────────────────────────────────────────────────
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
      ],
      // ── Navigation : pas de GoRouter, Navigator classique ───────────────
      home: const AuthGate(),
    );
  }
}
