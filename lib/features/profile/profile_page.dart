import 'package:app/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../shared/models/models.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/widgets.dart';
import '../auth/auth_provider.dart';
import '../auth/login_page.dart';
import '../theme/settings_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final userAsync = ref.watch(currentUserProvider);
    final historyAsync = ref.watch(historyProvider);
    final cs = Theme.of(context).colorScheme;

    void refresh() {
      ref.invalidate(currentUserProvider);
      ref.invalidate(historyProvider);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.myProfile),
        actions: [
          // Bouton rafraîchir
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l.refresh,
            onPressed: () {
              ref.invalidate(currentUserProvider);
              ref.invalidate(historyProvider);
            },
          ),
          // Raccourci paramètres
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l.settings,
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const SettingsPage())),
          ),
          // Déconnexion
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: l.logout,
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(l.logoutConfirmTitle),
                  content: Text(l.logoutConfirmText),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l.cancel)),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(l.logout)),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                await ref.read(authNotifierProvider.notifier).logout();
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (_) => false);
              }
            },
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: l.errorC,
          onRetry: refresh,
        ),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Joueur introuvable'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeroCard(user: user)
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.05, end: 0),
              const SizedBox(height: 14),
              _StatsRow(user: user).animate().fadeIn(delay: 80.ms),
              const SizedBox(height: 18),
              _SecretCard(secret: user.secret).animate().fadeIn(delay: 160.ms),
              const SizedBox(height: 20),
              Text(l.pointHistory,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16))
                  .animate()
                  .fadeIn(delay: 220.ms),
              const SizedBox(height: 8),
              historyAsync.when(
                loading: () => const Center(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator())),
                error: (e, _) => ErrorView(
                  message: l.errorC,
                  onRetry: refresh,
                ),
                data: (history) => history.isEmpty
                    ? EmptyState(emoji: '📊', title: l.noHistory)
                    : Column(
                        children: history
                            .asMap()
                            .entries
                            .map(
                                (e) => _HistoryRow(item: e.value, index: e.key))
                            .toList()),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

// ─── Hero card ────────────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final UserModel user;
  const _HeroCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.primaryLight.withOpacity(0.25),
                  AppColors.primary.withOpacity(0.15)
                ]
              : [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 6)),
              ],
      ),
      child: Row(children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withOpacity(0.35), width: 2)),
          child: Center(
              child: Text(user.initials,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user.pseudo,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          if (user.group != null) ...[
            const SizedBox(height: 3),
            Row(children: [
              Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                      color: user.groupColor,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.white.withOpacity(0.4)))),
              const SizedBox(width: 5),
              Text('Groupe ${user.group!.name}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ],
          if (user.isEliminated)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4)),
              child: const Text('ÉLIMINÉ',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${user.points}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold)),
          const Text('pts',
              style: TextStyle(color: Colors.white60, fontSize: 12)),
        ]),
      ]),
    );
  }
}

// ─── Stats row ────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final UserModel user;
  const _StatsRow({required this.user});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(children: [
      _StatChip(
          emoji: '⭐',
          value: '${user.points}',
          label: l.points,
          color: AppColors.warning),
      const SizedBox(width: 10),
      _StatChip(
        emoji: user.isEliminated ? '❌' : '✅',
        value: user.isEliminated ? l.eliminated : l.active,
        label: l.status,
        color: user.isEliminated ? AppColors.danger : AppColors.success,
      ),
      const SizedBox(width: 10),
      _StatChip(
          emoji: '🏠',
          value: user.group?.name ?? '—',
          label: l.group,
          color: user.groupColor),
    ]);
  }
}

class _StatChip extends StatelessWidget {
  final String emoji, value, label;
  final Color color;
  const _StatChip(
      {required this.emoji,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2))),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
      ),
    );
  }
}

// ─── Secret card ──────────────────────────────────────────────────────────────
class _SecretCard extends StatefulWidget {
  final String secret;
  const _SecretCard({required this.secret});
  @override
  State<_SecretCard> createState() => _SecretCardState();
}

class _SecretCardState extends State<_SecretCard> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: isDark
              ? AppColors.jaune.withOpacity(0.08)
              : const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.jaune.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(l.mySecret,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.jaune : AppColors.warning)),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _revealed = !_revealed),
            child: Text(_revealed ? l.hide : l.reveal,
                style: TextStyle(
                    color: isDark ? AppColors.jaune : AppColors.warning,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
        ]),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: 280.ms,
          child: _revealed
              ? Text(widget.secret,
                  key: const ValueKey('r'),
                  style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: isDark
                          ? AppColors.jaune.withOpacity(0.85)
                          : const Color(0xFF7A6000)))
              : Container(
                  key: const ValueKey('h'),
                  height: 36,
                  decoration: BoxDecoration(
                      color: AppColors.jaune.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Center(
                      child: Text('••••••••••••••••••••',
                          style: TextStyle(
                              color: AppColors.warning,
                              letterSpacing: 2,
                              fontSize: 18))),
                ),
        ),
      ]),
    );
  }
}

// ─── History row ──────────────────────────────────────────────────────────────
class _HistoryRow extends StatelessWidget {
  final PointHistory item;
  final int index;
  const _HistoryRow({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final isPos = item.points > 0;
    final date = DateFormat('dd/MM à HH:mm').format(item.createdAt.toLocal());
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: (isPos ? AppColors.success : AppColors.danger)
                    .withOpacity(0.1),
                shape: BoxShape.circle),
            child: Center(
                child: Text(isPos ? '⭐' : '📉',
                    style: const TextStyle(fontSize: 17))),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(item.reason,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                Text(date,
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurface.withOpacity(0.4))),
              ])),
          Text(isPos ? '+${item.points}' : '${item.points}',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isPos ? AppColors.success : AppColors.danger)),
        ]),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 40 * index), duration: 260.ms)
        .slideX(begin: 0.04, end: 0);
  }
}
