import 'package:app/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/models.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/WaitingPage.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/widgets.dart';
import '../auth/auth_provider.dart';
import '../home/home_provider.dart';
import 'game_play_page.dart';
import 'games_provider.dart';

class GamesPage extends ConsumerWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(gameSettingsStreamProvider);
    final userAsync = ref.watch(currentUserProvider);

    return settingsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => ErrorView(
        message: 'Erreur de chargement',
        onRetry: () {
          ref.invalidate(currentUserProvider);
          ref.invalidate(gameSettingsStreamProvider);
        },
      ),
      data: (settings) => settings.currentPhase == "game"
          ? const GamesPagePret()
          : WaitingPage(userAsync: userAsync),
    );
  }
}

class GamesPagePret extends ConsumerWidget {
  const GamesPagePret({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final gamesAsync = ref.watch(gamesStreamProvider);

    void refresh() {
      ref.invalidate(gamesStreamProvider);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.games),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(gamesStreamProvider),
          ),
        ],
      ),
      body: gamesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: l.errorC,
          onRetry: refresh,
        ),
        data: (games) {
          if (games.isEmpty) {
            return EmptyState(
                emoji: '🎮', title: l.noGames, subtitle: l.noGamesSub);
          }
          final active = games.where((g) => g.isActive).toList();
          // final inactive = games.where((g) => !g.isActive).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(gamesStreamProvider),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              children: [
                if (active.isNotEmpty) ...[
                  _SectionHeader(
                      emoji: '🔥',
                      title: l.gamesAvailable,
                      count: active.length,
                      color: AppColors.success),
                  const SizedBox(height: 8),
                  ...active
                      .asMap()
                      .entries
                      .map((e) => _GameCard(game: e.value, index: e.key)),
                  const SizedBox(height: 16),
                ],
                // if (inactive.isNotEmpty) ...[
                //   _SectionHeader(
                //       emoji: '⏳',
                //       title: l.gamesSoon,
                //       count: inactive.length,
                //       color: Colors.grey),
                //   const SizedBox(height: 8),
                //   ...inactive.asMap().entries.map((e) =>
                //       _GameCard(game: e.value, index: e.key + active.length)),
                // ],
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String emoji, title;
  final int count;
  final Color color;
  const _SectionHeader(
      {required this.emoji,
      required this.title,
      required this.count,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 16)),
      const SizedBox(width: 7),
      Text(title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10)),
        child: Text('$count',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    ]);
  }
}

// ─── Game card ────────────────────────────────────────────────────────────────
class _GameCard extends ConsumerWidget {
  final GameModel game;
  final int index;
  const _GameCard({required this.game, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final cooldownAsync = ref.watch(gameCooldownProvider(game.id));
    final cooldownEnd = cooldownAsync.valueOrNull;
    final isOnCooldown = cooldownEnd != null;

    final typeInfo = _gameTypeInfo(game.gameType);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: game.isActive && !isOnCooldown
            ? () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => GameLoadPage(game: game)))
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              // Icône type de jeu
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                    color: isOnCooldown
                        ? Colors.grey.withOpacity(0.1)
                        : typeInfo.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16)),
                child: Center(
                    child: Text(isOnCooldown ? '⏳' : typeInfo.emoji,
                        style: const TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      Expanded(
                          child: Text(game.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16))),
                      if (game.isActive && !isOnCooldown)
                        _Badge(label: l.gameActive, color: AppColors.success),
                      if (isOnCooldown)
                        _Badge(
                            label: _cooldownLabel(cooldownEnd),
                            color: Colors.grey),
                    ]),
                    const SizedBox(height: 3),
                    Text(typeInfo.label,
                        style: TextStyle(
                            color: typeInfo.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(game.description,
                        style: TextStyle(
                            color: cs.onSurface.withOpacity(0.5),
                            fontSize: 12,
                            height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ])),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              // Points reward
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColors.jaune.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('⭐', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(l.pointsReward(game.pointsReward),
                      style: const TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ]),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColors.bleu.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('⏳', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text('${game.time} S',
                      style: const TextStyle(
                          color: AppColors.bleu,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ]),
              ),

              const Spacer(),
              if (isOnCooldown)
                Row(children: [
                  const Icon(Icons.lock_clock, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Disponible ${_cooldownLabel(cooldownEnd)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ])
              else if (game.isActive)
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => GameLoadPage(game: game))),
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: Text(l.play),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: typeInfo.color,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                )
              else
                Text(l.comingSoon,
                    style: TextStyle(
                        color: cs.onSurface.withOpacity(0.35),
                        fontSize: 12,
                        fontStyle: FontStyle.italic)),
            ]),
          ]),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 70 * index), duration: 300.ms)
        .slideY(begin: 0.04, end: 0);
  }

  String _cooldownLabel(DateTime end) {
    final diff = end.difference(DateTime.now());
    if (diff.inHours > 0) {
      return 'dans ${diff.inHours}h${diff.inMinutes.remainder(60).toString().padLeft(2, '0')}';
    }
    return 'dans ${diff.inMinutes}min';
  }

  _TypeInfo _gameTypeInfo(String? type) {
    return switch (type) {
      'quiz' => const _TypeInfo('🧠', 'Quiz', AppColors.primary),
      'intrus' => const _TypeInfo('🔍', 'Trouve l\'intrus', AppColors.bleu),
      'tap_challenge' =>
        const _TypeInfo('⚡', 'Tap Challenge', AppColors.danger),
      'vrai_faux' => const _TypeInfo('❓', 'Vrai ou Faux', AppColors.vert),
      'enquete' => const _TypeInfo('🕵️', 'Enquête', Color(0xFF6B3FA0)),
      'puzzle' => const _TypeInfo('🧩', 'Puzzle', AppColors.warning),
      'association' => const _TypeInfo('🔗', 'Association', AppColors.success),
      'memoire' => const _TypeInfo('🧲', 'Mémoire inversée', AppColors.rouge),
      'calcul' => const _TypeInfo('🔢', 'Calcul rapide', AppColors.bleu),
      _ => const _TypeInfo('🎮', 'Mini-jeu', AppColors.primary),
    };
  }
}

class _TypeInfo {
  final String emoji, label;
  final Color color;
  const _TypeInfo(this.emoji, this.label, this.color);
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6)),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      );
}
