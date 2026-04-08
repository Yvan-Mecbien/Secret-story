import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/l10n/app_localizations.dart';
import '../../shared/theme/theme_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        children: [
          // ── Apparence ──────────────────────────────────────────────────
          _SectionHeader(title: l.appearance),

          // Thème
          _SettingsTile(
            icon: Icons.palette_outlined,
            label: 'Thème',
            subtitle: _themeLabel(themeMode, l),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<ThemeMode>(
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: cs.primaryContainer,
                selectedForegroundColor: cs.onPrimaryContainer,
              ),
              segments: [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(l.themeLight),
                  icon: const Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(l.themeSystem),
                  icon: const Icon(Icons.settings_suggest_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(l.themeDark),
                  icon: const Icon(Icons.dark_mode_outlined),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) =>
                  ref.read(themeProvider.notifier).setMode(s.first),
            ),
          ),

          const Divider(height: 24, indent: 16, endIndent: 16),

          // ── Langue ─────────────────────────────────────────────────────
          _SectionHeader(title: l.language),

          _LangOption(
            emoji: '🇫🇷',
            label: l.french,
            isSelected: locale.languageCode == 'fr',
            onTap: () =>
                ref.read(localeProvider.notifier).setLocale(const Locale('fr')),
          ),
          _LangOption(
            emoji: '🇬🇧',
            label: l.english,
            isSelected: locale.languageCode == 'en',
            onTap: () =>
                ref.read(localeProvider.notifier).setLocale(const Locale('en')),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode, AppLocalizations l) {
    return switch (mode) {
      ThemeMode.light => l.themeLight,
      ThemeMode.dark => l.themeDark,
      ThemeMode.system => l.themeSystem,
    };
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: cs.primary),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style:
              TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.55))),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangOption({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Text(emoji, style: const TextStyle(fontSize: 24)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: cs.primary)
          : Icon(Icons.radio_button_unchecked,
              color: cs.onSurface.withOpacity(0.3)),
      onTap: onTap,
      tileColor: isSelected ? cs.primaryContainer.withOpacity(0.5) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
