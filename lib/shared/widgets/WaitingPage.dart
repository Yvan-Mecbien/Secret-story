// ─── Waiting ──────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/home/home_page.dart';
import '../../features/home/home_provider.dart';
import '../../features/theme/settings_page.dart';
import '../../features/votes/vote_provider.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';

class WaitingPage extends ConsumerWidget {
  final AsyncValue<UserModel?> userAsync;
  const WaitingPage({super.key, required this.userAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: [
          // Bouton rafraîchir
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l.refresh,
            onPressed: () {
              ref.invalidate(hiddenIndicesProvider);
              ref.invalidate(currentUserProvider);
              ref.invalidate(gameSettingsStreamProvider);
            },
          ),

          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône animée
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('🔮', style: TextStyle(fontSize: 36)),
                    ),
                  ),
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.06, 1.06),
                    duration: 1600.ms,
                    curve: Curves.easeInOut,
                  )
                  .then()
                  .scale(
                    begin: const Offset(1.06, 1.06),
                    end: const Offset(1, 1),
                    duration: 1600.ms,
                    curve: Curves.easeInOut,
                  ),

              const SizedBox(height: 36),

              Text(
                l.waitingTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                  height: 1.3,
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 14),

              Text(
                l.waitingSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: cs.onSurface.withOpacity(0.5), height: 1.6),
              ).animate().fadeIn(delay: 350.ms),

              const SizedBox(height: 36),

              // Card joueur
              userAsync.when(
                data: (user) => user != null
                    ? PlayerChip(user: user).animate().fadeIn(delay: 500.ms)
                    : const SizedBox(),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
