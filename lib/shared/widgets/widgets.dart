import 'package:flutter/material.dart';
import '../../shared/l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

// ─── PlayerAvatar ─────────────────────────────────────────────────────────────
class PlayerAvatar extends StatelessWidget {
  final UserModel user;
  final double size;
  final bool showBorder;

  const PlayerAvatar({
    super.key,
    required this.user,
    this.size = 40,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = user.groupColor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: showBorder ? color : color.withOpacity(0.3),
          width: showBorder ? 2.5 : 1,
        ),
      ),
      child: Center(
        child: Text(
          user.initials,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.36,
          ),
        ),
      ),
    );
  }
}

// ─── GroupBadge ───────────────────────────────────────────────────────────────
class GroupBadge extends StatelessWidget {
  final GroupModel group;
  final bool compact;

  const GroupBadge({super.key, required this.group, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = group.flutterColor;
    final l = AppLocalizations.of(context);

    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [],
    );
  }
}

// ─── PhaseBanner ──────────────────────────────────────────────────────────────
class PhaseBanner extends StatelessWidget {
  final GameSettings settings;

  const PhaseBanner({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    final (emoji, label, color) = switch (settings.currentPhase) {
      'game' => ('🎮', l.phaseGame, AppColors.primary),
      'vote' => ('🗳️', l.phaseVote, AppColors.warning),
      'elimination' => ('❌', l.phaseElimination, AppColors.danger),
      'finished' => ('🎉', l.phaseFinished, AppColors.success),
      _ => ('⏳', l.phaseWaiting, cs.onSurface.withOpacity(0.4)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

// ─── LoadingButton ────────────────────────────────────────────────────────────
class LoadingButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  const LoadingButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.child,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : child,
    );
  }
}

// ─── EmptyState ───────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;

  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: cs.onSurface.withOpacity(0.5), height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}
