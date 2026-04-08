import 'package:app/core/supabase_client.dart';
import 'package:app/features/votes/vote_provider.dart';
import 'package:app/shared/l10n/app_localizations.dart';
import 'package:app/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/models.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/widgets.dart';
import '../home/home_provider.dart';

class VotePage extends ConsumerStatefulWidget {
  const VotePage({super.key});
  @override
  ConsumerState<VotePage> createState() => _VotePageState();
}

class _VotePageState extends ConsumerState<VotePage>
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

  void _refresh() {
    ref.invalidate(votablePlayersProvider);
    ref.invalidate(randomSecretsProvider);
    ref.invalidate(indicesProvider);
    ref.read(votesRemainingProvider.notifier).reload();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final settingsAsync = ref.watch(gameSettingsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.voteGameTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l.refresh,
            onPressed: _refresh,
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(icon: const Icon(Icons.how_to_vote_outlined), text: l.votes),
            Tab(
                icon: const Icon(Icons.lightbulb_outline),
                text: l.indicesTitle),
          ],
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: l.errorC,
          onRetry: _refresh,
        ),
        data: (settings) {
          if (!settings.gameStarted) return _Locked(l.gameNotStartedLock);
          if (!settings.isVotePhase) {
            return TabBarView(
              controller: _tab,
              children: [
                _Locked(l.voteNotOpen),
                _IndicesTab(),
              ],
            );
          }

          return TabBarView(
            controller: _tab,
            children: [
              _VoteTab(),
              _IndicesTab(),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ONGLET 1 — Vote
// ═══════════════════════════════════════════════════════════════
class _VoteTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_VoteTab> createState() => _VoteTabState();
}

class _VoteTabState extends ConsumerState<_VoteTab> {
  String? _selectedSecret;
  UserModel? _selectedPlayer;
  String _searchQuery = '';
  bool _resultShown = false;

  void _reset() {
    setState(() {
      _selectedSecret = null;
      _selectedPlayer = null;
      _searchQuery = '';
      _resultShown = false;
    });
    ref.read(voteNotifierProvider.notifier).reset();
    ref.invalidate(randomSecretsProvider);
    ref.invalidate(votablePlayersProvider);
  }

  Future<void> _submit() async {
    if (_selectedSecret == null || _selectedPlayer == null) return;
    final l = AppLocalizations.of(context);

    // Confirmation
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(l.voteConfirmTitle),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l.voteConfirmText),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.danger.withOpacity(0.2)),
            ),
            child: Text(l.votePenaltyWarning,
                style: const TextStyle(fontSize: 12, color: AppColors.danger)),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.cancel)),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              child: Text(l.confirm)),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await ref.read(voteNotifierProvider.notifier).castVote(
            targetPlayerId: _selectedPlayer!.id,
            secretProposed: _selectedSecret!,
            votesNotifier: ref.read(votesRemainingProvider.notifier),
          );

      setState(() => _resultShown = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur: $e'), backgroundColor: AppColors.danger));
      }
    }
  }

  void _refresh() {
    ref.invalidate(votablePlayersProvider);
    ref.invalidate(randomSecretsProvider);

    ref.read(votesRemainingProvider.notifier).reload();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final remaining = ref.watch(votesRemainingProvider);
    final voteState = ref.watch(voteNotifierProvider);
    final secretsAsync = ref.watch(randomSecretsProvider);
    final playersAsync = ref.watch(votablePlayersProvider);

    // ── Résultat affiché après vote ───────────────────────────────────────────
    if (_resultShown && voteState.correct != null) {
      return _ResultScreen(
        correct: voteState.correct!,
        reveal: voteState.indiceGiven!,
        remaining: remaining,
        onVoteAgain: remaining > 0 ? _reset : null,
      );
    }

    // ── Plus de votes disponibles ─────────────────────────────────────────────
    if (remaining == 0) {
      return _NoVotesLeft();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // ── Compteur votes ────────────────────────────────────────────────────
        _AttemptsBar(remaining: remaining).animate().fadeIn(duration: 300.ms),
        const SizedBox(height: 16),

        // ── Avertissement pénalité ────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning.withOpacity(0.25)),
          ),
          child: Row(children: [
            const Text('⚠️', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
                child: Text(l.votePenaltyWarning,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.warning))),
          ]),
        ).animate().fadeIn(delay: 50.ms),
        const SizedBox(height: 20),

        // ── Section 1 : Secrets (aléatoires) ─────────────────────────────────
        _SectionLabel(label: l.voteSectionSecret, sub: l.voteRandomSecrets),
        const SizedBox(height: 8),
        secretsAsync.when(
          loading: () => const _ShimmerCard(),
          error: (e, _) => ErrorView(
            message: 'Erreur de chargement"',
            onRetry: _refresh,
          ),
          data: (secrets) => _SecretDropdown(
            secrets: secrets,
            selected: _selectedSecret,
            onChanged: (v) => setState(() => _selectedSecret = v),
          ),
        ),
        const SizedBox(height: 20),

        // ── Section 2 : Joueurs (alphabétique + recherche) ────────────────────
        _SectionLabel(label: l.voteSectionPlayer),
        const SizedBox(height: 8),
        playersAsync.when(
          loading: () => const _ShimmerCard(),
          error: (e, _) => ErrorView(
            message: 'Erreur de chargement"',
            onRetry: _refresh,
          ),
          data: (players) => _PlayerDropdown(
            players: players,
            selected: _selectedPlayer,
            searchQuery: _searchQuery,
            onSearchChanged: (v) => setState(() => _searchQuery = v),
            onChanged: (p) => setState(() => _selectedPlayer = p),
          ),
        ),
        const SizedBox(height: 28),

        // ── Bouton voter ──────────────────────────────────────────────────────
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: (_selectedSecret != null &&
                    _selectedPlayer != null &&
                    !voteState.isLoading)
                ? _submit
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  (_selectedSecret != null && _selectedPlayer != null)
                      ? AppColors.danger
                      : Colors.grey.shade400,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: voteState.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.how_to_vote_outlined, size: 20),
            label: Text(
              (_selectedSecret != null && _selectedPlayer != null)
                  ? l.voteSubmitGuess
                  : l.voteCompleteSelectBoth,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 32),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ONGLET 2 — Indices révélés
// ═══════════════════════════════════════════════════════════════
class _IndicesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final indicesAsync = ref.watch(indicesProvider);
    final cs = Theme.of(context).colorScheme;

    void refresh() {
      ref.invalidate(indicesProvider);
    }

    return indicesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        message: l.errorC,
        onRetry: refresh,
      ),
      data: (indices) {
        if (indices.isEmpty) {
          return EmptyState(emoji: '🔍', title: l.noIndices);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: indices.length,
          itemBuilder: (context, i) {
            final ind = indices[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                        child: Text('💡', style: TextStyle(fontSize: 18))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ind.userPseudo!,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      Text(ind.indice,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                      Text(
                        '${ind.createdAt.day.toString().padLeft(2, '0')}/'
                        '${ind.createdAt.month.toString().padLeft(2, '0')} '
                        '${ind.createdAt.hour.toString().padLeft(2, '0')}:'
                        '${ind.createdAt.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurface.withOpacity(0.4)),
                      ),
                    ],
                  )),
                ]),
              ),
            ).animate().fadeIn(
                delay: Duration(milliseconds: 50 * i), duration: 280.ms);
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// WIDGETS INTERNES
// ═══════════════════════════════════════════════════════════════

class _AttemptsBar extends StatelessWidget {
  final int remaining;
  const _AttemptsBar({required this.remaining});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = remaining > 1
        ? AppColors.success
        : remaining == 1
            ? AppColors.warning
            : AppColors.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        ...List.generate(
            3,
            (i) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < remaining ? color : color.withOpacity(0.2),
                    ),
                  ),
                )),
        const SizedBox(width: 8),
        Text(l.voteAttemptsLeft(remaining),
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final String? sub;
  const _SectionLabel({required this.label, this.sub});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      if (sub != null)
        Text(sub!,
            style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withOpacity(0.45),
                fontStyle: FontStyle.italic)),
    ]);
  }
}

// ─── Dropdown secrets (liste déroulante) ─────────────────────────────────────
class _SecretDropdown extends StatelessWidget {
  final List<String> secrets;
  final String? selected;
  final void Function(String?) onChanged;

  const _SecretDropdown({
    required this.secrets,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E32) : const Color(0xFFF8F8FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected != null
              ? AppColors.primary
              : cs.outline.withOpacity(0.4),
          width: selected != null ? 1.5 : 0.8,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          hint: Row(children: [
            const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(l.voteSecretDropdownHint,
                style: TextStyle(
                    color: cs.onSurface.withOpacity(0.45), fontSize: 14)),
          ]),
          icon: Icon(Icons.keyboard_arrow_down,
              color: selected != null ? AppColors.primary : Colors.grey),
          dropdownColor: isDark ? const Color(0xFF1E1E32) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: secrets
              .map((s) => DropdownMenuItem<String>(
                    value: s,
                    child: Row(children: [
                      const Text('🔒', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(s,
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1)),
                    ]),
                  ))
              .toList(),
          onChanged: onChanged,
          selectedItemBuilder: (ctx) => secrets
              .map((s) => Row(children: [
                    const Text('🔒', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(s,
                            style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis)),
                  ]))
              .toList(),
        ),
      ),
    );
  }
}

// ─── Dropdown joueurs (alphabétique + barre de recherche) ────────────────────
class _PlayerDropdown extends StatelessWidget {
  final List<UserModel> players;
  final UserModel? selected;
  final String searchQuery;
  final void Function(String) onSearchChanged;
  final void Function(UserModel?) onChanged;

  const _PlayerDropdown({
    required this.players,
    required this.selected,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filtrer par recherche (déjà triés alphabétiquement par le provider)
    final filtered = searchQuery.isEmpty
        ? players
        : players
            .where((p) =>
                p.pseudo.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();

    return Column(children: [
      // Barre de recherche
      TextField(
        onChanged: onSearchChanged,
        decoration: InputDecoration(
          hintText: l.voteSearchPlayer,
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onSearchChanged(''),
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          isDense: true,
        ),
      ),
      const SizedBox(height: 8),

      // Dropdown
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E32) : const Color(0xFFF8F8FC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected != null
                ? AppColors.primary
                : cs.outline.withOpacity(0.4),
            width: selected != null ? 1.5 : 0.8,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<UserModel>(
            value: filtered.contains(selected) ? selected : null,
            isExpanded: true,
            hint: Row(children: [
              const Icon(Icons.person_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                filtered.isEmpty
                    ? 'Aucun joueur trouvé'
                    : l.votePlayerDropdownHint,
                style: TextStyle(
                    color: cs.onSurface.withOpacity(0.45), fontSize: 14),
              ),
            ]),
            icon: Icon(Icons.keyboard_arrow_down,
                color: selected != null ? AppColors.primary : Colors.grey),
            dropdownColor: isDark ? const Color(0xFF1E1E32) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            items: filtered
                .map((p) => DropdownMenuItem<UserModel>(
                      value: p,
                      child: Row(children: [
                        // Avatar couleur groupe
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: p.groupColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: p.groupColor.withOpacity(0.4), width: 1),
                          ),
                          child: Center(
                              child: Text(p.initials,
                                  style: TextStyle(
                                      color: p.groupColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold))),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(p.pseudo,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis),
                            if (p.group != null)
                              Text(p.group!.name,
                                  style: TextStyle(
                                      fontSize: 10, color: p.groupColor)),
                          ],
                        )),
                        Text('${p.points} pts',
                            style: TextStyle(
                                fontSize: 12,
                                color: cs.primary,
                                fontWeight: FontWeight.bold)),
                      ]),
                    ))
                .toList(),
            onChanged: (p) => onChanged(p),
            selectedItemBuilder: (ctx) => filtered
                .map((p) => Row(children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: p.groupColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                            child: Text(p.initials,
                                style: TextStyle(
                                    color: p.groupColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold))),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(p.pseudo,
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis)),
                    ]))
                .toList(),
          ),
        ),
      ),
    ]);
  }
}

// ─── Écran résultat ───────────────────────────────────────────────────────────
class _ResultScreen extends StatelessWidget {
  final bool correct;
  final int remaining;
  final bool reveal;
  final VoidCallback? onVoteAgain;

  const _ResultScreen({
    required this.correct,
    required this.reveal,
    required this.remaining,
    this.onVoteAgain,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(correct ? '🎉' : '❌', style: const TextStyle(fontSize: 72))
              .animate()
              .scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (correct ? AppColors.success : AppColors.danger)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (correct ? AppColors.success : AppColors.danger)
                    .withOpacity(0.3),
              ),
            ),
            child: Text(
              correct
                  ? l.voteCorrect
                  : reveal
                      ? l.indicesTitle
                      : l.voteWrong,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: correct ? AppColors.success : AppColors.danger,
                height: 1.4,
              ),
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 24),
          _AttemptsBar(remaining: remaining).animate().fadeIn(delay: 450.ms),
          const SizedBox(height: 28),
          if (onVoteAgain != null)
            ElevatedButton.icon(
              onPressed: onVoteAgain,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Voter à nouveau'),
              style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            ).animate().fadeIn(delay: 550.ms),
        ]),
      ),
    );
  }
}

// ─── Shimmer placeholder ──────────────────────────────────────────────────────
class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: cs.onSurface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms);
  }
}

// ─── Plus de votes disponibles ────────────────────────────────────────────────
class _NoVotesLeft extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
        child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🗳️', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        Text(l.voteNoAttemptsLeft,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Revenez demain !',
            style: TextStyle(
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
      ]),
    ));
  }
}

// ─── Écran verrouillé ─────────────────────────────────────────────────────────
class _Locked extends StatelessWidget {
  final String message;
  const _Locked(this.message);
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('🔒', style: TextStyle(fontSize: 56)),
      const SizedBox(height: 16),
      Text(message,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
    ]));
  }
}
