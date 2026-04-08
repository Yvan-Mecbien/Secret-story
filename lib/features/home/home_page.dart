import 'package:app/features/votes/vote_provider.dart';
import 'package:app/shared/theme/app_theme.dart';
import 'package:app/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../shared/l10n/app_localizations.dart';
import '../../shared/widgets/WaitingPage.dart';
import '../../shared/widgets/widgets.dart';
import '../../shared/models/models.dart';
import '../auth/auth_provider.dart';
import '../theme/settings_page.dart';
import 'home_provider.dart';
import '../leaderboard/leaderboard_provider.dart';
import '../navigation_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

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
      data: (settings) => settings.gameStarted
          ? _DashboardPage(settings: settings, userAsync: userAsync)
          : WaitingPage(userAsync: userAsync),
    );
  }
}

class PlayerChip extends StatelessWidget {
  final UserModel user;
  const PlayerChip({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlayerAvatar(user: user, size: 44, showBorder: true),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.pseudo,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (user.group != null)
                GroupBadge(group: user.group!, compact: true),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Dashboard ────────────────────────────────────────────────────────────────
class _DashboardPage extends ConsumerWidget {
  final GameSettings settings;
  final AsyncValue<UserModel?> userAsync;

  const _DashboardPage({required this.settings, required this.userAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = GlobalKey<ExpandableFabState>();
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final leaderAsync = ref.watch(fullLeaderboardProvider);
    final hiddenAsync = ref.watch(hiddenIndicesProvider);
    GroupModel? lien;
    void refresh() {
      ref.invalidate(hiddenIndicesProvider);
      ref.invalidate(currentUserProvider);
      ref.invalidate(gameSettingsStreamProvider);
      ref.invalidate(fullLeaderboardProvider);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.home),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l.refresh,
            onPressed: () {
              refresh();
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
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(fullLeaderboardProvider);
          ref.invalidate(currentUserProvider);
          ref.invalidate(gameSettingsStreamProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Phase
            PhaseBanner(settings: settings).animate().fadeIn(duration: 350.ms),

            const SizedBox(height: 14),

            // Ma carte
            userAsync.when(
              data: (user) {
                if (user != null) {
                  lien = user.group; // si group est nullable
                  // Utilisez lien ici (par exemple, le stocker dans un provider, un setState, etc.)
                  // Ensuite retournez le widget
                  return _MyCard(user: user).animate().fadeIn(delay: 80.ms);
                }
                return const SizedBox();
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorView(
                message: l.errorC,
                onRetry: refresh,
              ),
            ),

            const SizedBox(height: 20),

            // Titre classement
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l.rankingTitle,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Consumer(
                  builder: (_, ref2, __) => TextButton(
                    onPressed: () =>
                        ref2.read(activeTabProvider.notifier).state = 1,
                    child: Text(l.seeAll(ref2
                            .watch(fullLeaderboardProvider)
                            .valueOrNull
                            ?.length ??
                        0)),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 160.ms),

            // Classement
            leaderAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: ErrorView(
                  message: l.errorC,
                ),
              ),
              data: (players) => Column(
                children: players
                    .take(4)
                    .toList()
                    .asMap()
                    .entries
                    .map(
                      (e) => _LeaderRow(rank: e.key + 1, player: e.value)
                          .animate()
                          .fadeIn(
                            delay: Duration(milliseconds: 200 + e.key * 60),
                            duration: 300.ms,
                          )
                          .slideX(begin: 0.06, end: 0),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        key: key,

        // margin: const EdgeInsets.all(100),
        // duration: const Duration(milliseconds: 500),
        distance: 100.0,
        // type: ExpandableFabType.up,
        // pos: ExpandableFabPos.left,
        // childrenOffset: const Offset(0, 20),
        // childrenAnimation: ExpandableFabAnimation.none,
        fanAngle: 110,
        // openButtonBuilder: RotateFloatingActionButtonBuilder(
        //   child: const Icon(Icons.abc),
        //   fabSize: ExpandableFabSize.large,
        //   foregroundColor: Colors.amber,
        //   backgroundColor: Colors.green,
        //   shape: const CircleBorder(),
        //   angle: 3.14 * 2,
        //   elevation: 5,
        // ),
        // closeButtonBuilder: FloatingActionButtonBuilder(
        //   size: 56,
        //   builder: (BuildContext context, void Function()? onPressed,
        //       Animation<double> progress) {
        //     return IconButton(
        //       onPressed: onPressed,
        //       icon: const Icon(
        //         Icons.check_circle_outline,
        //         size: 40,
        //       ),
        //     );
        //   },
        // ),
        overlayStyle: ExpandableFabOverlayStyle(
          color: Colors.black.withValues(alpha: 0.5),
          blur: 5,
        ),

        children: [
          Row(
            children: [
              Text(l.send, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 20),
              FloatingActionButton.small(
                // shape: const CircleBorder(),
                heroTag: null,
                child: const Icon(Icons.share),
                onPressed: () {},
              ),
            ],
          ),
          // Row(
          //   children: [
          //     Text(
          //       l.indice,
          //       style: const TextStyle(fontWeight: FontWeight.bold),
          //     ),
          //     const SizedBox(width: 20),
          //     hiddenAsync.when(
          //       loading: () => const FloatingActionButton.small(
          //         heroTag: null,
          //         onPressed: null,
          //         child: Icon(Icons.lightbulb_outline),
          //       ),
          //       error: (_, __) => const FloatingActionButton.small(
          //         heroTag: null,
          //         onPressed: null,
          //         child: Icon(Icons.lightbulb_outline),
          //       ),
          //       data: (indices) => _BadgedButton(
          //         count: indices.length,
          //         indices: indices,
          //       ),
          //     ),
          //   ],
          // ),
          Row(
            children: [
              Text(l.group,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 20),
              FloatingActionButton.small(
                // shape: const CircleBorder(),
                heroTag: null,
                child: const Icon(Icons.groups_sharp),
                onPressed: () {
                  showGroupInfoDialog(context, lien!);
                  //  Navigator.of(context).push(
                  //     MaterialPageRoute(builder: ((context) => const NextPage())));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Fonction pour afficher le modal
Future<void> showGroupInfoDialog(BuildContext context, GroupModel group) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _getColorFromString(group.name),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(group.name),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('👥 Membres : ${group.nbrMembre}'),
            const SizedBox(height: 8),
            Text('🎨 Couleur : ${group.name}'),
            const SizedBox(height: 8),
            Text('🔗 Lien : ${group.lien}'),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              final Uri whatsappUri = Uri.parse(group.lien);
              if (await canLaunchUrl(whatsappUri)) {
                await launchUrl(whatsappUri);
              } else {
                // Gestion d'erreur : afficher un snackbar ou autre
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Impossible d\'ouvrir le lien')),
                );
              }
            },
            icon: const Icon(Icons.chat),
            label: const Text('Ouvrir WhatsApp'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      );
    },
  );
}

// Petit utilitaire pour convertir une chaîne couleur en Color (exemple basique)
Color _getColorFromString(String colorName) {
  switch (colorName.toLowerCase()) {
    case 'rouge':
      return Colors.red;
    case 'vert':
      return Colors.green;
    case 'bleu':
      return Colors.blue;
    case 'jaune':
      return Colors.yellow;
    default:
      return Colors.grey;
  }
}

class _MyCard extends StatelessWidget {
  final UserModel user;
  const _MyCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            PlayerAvatar(user: user, size: 54, showBorder: true),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(user.pseudo,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 17)),
                      if (user.isEliminated) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(l.eliminated,
                              style: TextStyle(color: cs.error, fontSize: 11)),
                        ),
                      ],
                    ],
                  ),
                  if (user.group != null)
                    GroupBadge(group: user.group!, compact: true),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${user.points}',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: cs.primary)),
                Text(l.points,
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurface.withOpacity(0.45))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  final int rank;
  final UserModel player;
  const _LeaderRow({required this.rank, required this.player});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final medals = ['🥇', '🥈', '🥉'];
    final l = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: rank <= 3
                  ? Text(medals[rank - 1], style: const TextStyle(fontSize: 20))
                  : Text('#$rank',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface.withOpacity(0.4),
                          fontSize: 14)),
            ),
            PlayerAvatar(user: player, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(player.pseudo,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (player.group != null)
                    GroupBadge(group: player.group!, compact: true),
                ],
              ),
            ),
            Text('${player.points} ${l.pts}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _BadgedButton extends StatelessWidget {
  final int count;
  final List<IndiceModel> indices;

  const _BadgedButton({required this.count, required this.indices});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        FloatingActionButton.small(
          heroTag: null,
          backgroundColor: count > 0
              ? AppColors.warning
              : Theme.of(context).colorScheme.primary,
          onPressed: () => _showDialog(context),
          child: const Icon(Icons.lightbulb_outline, color: Colors.white),
        ),
        if (count > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _showDialog(BuildContext context) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Text('💡', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Text(l.indicesDialogTitle),
        ]),
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        content: SizedBox(
          width: double.maxFinite,
          child: count == 0
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    l.noIndices,
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5)),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: indices.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final ind = indices[i];
                    // Récupérer le pseudo depuis la jointure users(pseudo)
                    final pseudo = ind.userPseudo ?? '—';
                    final date = DateFormat('dd/MM HH:mm')
                        .format(ind.createdAt.toLocal());
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                            child: Text('💡', style: TextStyle(fontSize: 18))),
                      ),
                      title: Text(
                        pseudo,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        l.indicesSoonAvailable,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.warning),
                      ),
                      trailing: Text(
                        date,
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(ctx)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.4)),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
