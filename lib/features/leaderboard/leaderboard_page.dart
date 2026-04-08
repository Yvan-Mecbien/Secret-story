import 'package:app/features/leaderboard/leaderboard_provider.dart';
import 'package:app/shared/l10n/app_localizations.dart';
import 'package:app/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../shared/widgets/widgets.dart';
import '../../shared/models/models.dart';
import '../auth/auth_provider.dart';

class LeaderboardPage extends ConsumerStatefulWidget {
  const LeaderboardPage({super.key});

  @override
  ConsumerState<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends ConsumerState<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final allAsync = ref.watch(fullLeaderboardProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    void refresh() {
      ref.invalidate(currentUserProvider);
      ref.invalidate(fullLeaderboardProvider);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.leaderboard),
        actions: [
          // Bouton rafraîchir
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l.refresh,
            onPressed: () {
              ref.invalidate(currentUserProvider);
              ref.invalidate(fullLeaderboardProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: [Tab(text: l.tabActive), Tab(text: l.tabAll)],
        ),
      ),
      body: allAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: l.errorC,
          onRetry: refresh,
        ),
        data: (all) {
          final active = all.where((p) => !p.isEliminated).toList();
          return TabBarView(
            controller: _tab,
            children: [
              _PlayerList(players: active, currentUserId: currentUser?.id),
              _PlayerList(players: all, currentUserId: currentUser?.id),
            ],
          );
        },
      ),
    );
  }
}

class _PlayerList extends StatelessWidget {
  final List<UserModel> players;
  final String? currentUserId;

  const _PlayerList({required this.players, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    if (players.isEmpty) {
      return EmptyState(emoji: '🏆', title: l.noPlayers);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: players.length + 1, // +1 for podium
      itemBuilder: (context, index) {
        if (index == 0) {
          return _Podium(players: players.take(3).toList())
              .animate()
              .fadeIn(duration: 450.ms);
        }
        final player = players[index - 1];
        return _PlayerTile(
          rank: index,
          player: player,
          isMe: player.id == currentUserId,
        )
            .animate()
            .fadeIn(
                delay: Duration(milliseconds: 60 + (index - 1) * 45),
                duration: 280.ms)
            .slideX(begin: 0.05, end: 0);
      },
    );
  }
}

// ─── Podium ───────────────────────────────────────────────────────────────────
class _Podium extends StatelessWidget {
  final List<UserModel> players;
  const _Podium({required this.players});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(l.podiumTitle,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: cs.primary)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (players.length > 1)
                _Pedestal(rank: 2, player: players[1], h: 78),
              if (players.isNotEmpty)
                _Pedestal(rank: 1, player: players[0], h: 108),
              if (players.length > 2)
                _Pedestal(rank: 3, player: players[2], h: 58),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pedestal extends StatelessWidget {
  final int rank;
  final UserModel player;
  final double h;

  const _Pedestal({required this.rank, required this.player, required this.h});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final medals = ['🥇', '🥈', '🥉'];
    final colors = [
      const Color(0xFFFFD700).withOpacity(0.25),
      const Color(0xFFC0C0C0).withOpacity(0.3),
      const Color(0xFFCD7F32).withOpacity(0.25),
    ];

    return Column(
      children: [
        Text(medals[rank - 1], style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        PlayerAvatar(user: player, size: 46, showBorder: true),
        const SizedBox(height: 5),
        Text(player.pseudo,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            overflow: TextOverflow.ellipsis,
            maxLines: 1),
        Text('${player.points} ${l.pts}',
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          width: 72,
          height: h,
          decoration: BoxDecoration(
            color: colors[rank - 1],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border:
                Border.all(color: Colors.white.withOpacity(0.3), width: 0.5),
          ),
        ),
      ],
    );
  }
}

// ─── PlayerTile ───────────────────────────────────────────────────────────────
class _PlayerTile extends StatelessWidget {
  final int rank;
  final UserModel player;
  final bool isMe;

  const _PlayerTile(
      {required this.rank, required this.player, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isMe ? cs.primaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side:
            isMe ? BorderSide(color: cs.primary, width: 1.5) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            // Rang
            SizedBox(
              width: 36,
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color:
                      rank <= 3 ? cs.primary : cs.onSurface.withOpacity(0.35),
                  fontSize: 14,
                ),
              ),
            ),

            PlayerAvatar(user: player, size: 40),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          player.pseudo,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: player.isEliminated
                                ? cs.onSurface.withOpacity(0.35)
                                : null,
                            decoration: player.isEliminated
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(l.me,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                      if (player.isEliminated) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: cs.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(l.eliminated,
                              style: TextStyle(color: cs.error, fontSize: 10)),
                        ),
                      ],
                    ],
                  ),
                  // if (player.groupId != null)
                  // GroupBadge(group: player.group!, compact: true),
                ],
              ),
            ),

            Text('${player.points}',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: player.isEliminated
                        ? cs.onSurface.withOpacity(0.3)
                        : cs.primary)),
          ],
        ),
      ),
    );
  }
}
