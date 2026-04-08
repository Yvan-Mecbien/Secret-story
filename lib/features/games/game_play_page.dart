import 'dart:async';
import 'package:app/core/supabase_client.dart';
import 'package:app/features/games/TypesGames/QuizzGame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/l10n/app_localizations.dart';
import '../../shared/models/models.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/error_view.dart';
import '../auth/auth_provider.dart';
import 'FinishScreen.dart';
import 'TypesGames/AssociationGame.dart';
import 'TypesGames/CalculGame.dart';
import 'TypesGames/EnqueteGame.dart';
import 'TypesGames/IntrusGame.dart';
import 'TypesGames/MemoireGame.dart';
import 'TypesGames/Puzzel.dart';
import 'TypesGames/TapChallengeGame.dart';
import 'TypesGames/VraiFauxGame.dart';
import 'games_provider.dart';

// ════════════════════════════════════════════════════════════════
// PAGE DE CHARGEMENT — charge les questions AVANT de lancer le jeu
// ════════════════════════════════════════════════════════════════
class GameLoadPage extends ConsumerWidget {
  final GameModel game;
  const GameLoadPage({super.key, required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(questionsProvider(game.id));
    final typeColor = _typeColor(game.gameType);

    final userIdAsync = ref.watch(currentUserProvider);
    String userId = '';
    final l = AppLocalizations.of(context);

    userIdAsync.when(
      data: (user) async {
        if (user == null) return;
        userId = user.id;
      },
      error: (Object error, StackTrace stackTrace) {},
      loading: () {},
    );

    void refresh() {
      ref.invalidate(currentUserProvider);
      ref.invalidate(questionsProvider);
    }

    return Scaffold(
      backgroundColor: typeColor.withOpacity(0.04),
      appBar: AppBar(
        title: Text(game.title),
        backgroundColor: typeColor,
        elevation: 0,
      ),
      body: questionsAsync.when(
        loading: () => _LoadingScreen(game: game, color: typeColor),
        error: (e, _) => ErrorView(
          message: l.errorC,
          onRetry: refresh,
        ),
        data: (questions) {
          if (questions.isEmpty) {
            return const Center(child: Text('Aucune question disponible.'));
          }
          // Charger la progression locale
          return FutureBuilder<(dynamic, dynamic, dynamic)>(
            future: loadLocalProgress(game.id, userId),
            builder: (ctx, snap) {
              if (!snap.hasData) {
                return _LoadingScreen(game: game, color: typeColor);
              }
              final (savedScore, savedQ, finishis) = snap.data!;
              final startQ = savedQ.clamp(0, questions.length - 1);

              return _ReadyScreen(
                game: game,
                questions: questions,
                savedScore: savedScore,
                startQuestion: startQ,
                color: typeColor,
                userId: userId,
              );
            },
          );
        },
      ),
    );
  }

  Color _typeColor(String? type) => switch (type) {
        'quiz' => AppColors.primary,
        'intrus' => AppColors.bleu,
        'tap_challenge' => AppColors.danger,
        'vrai_faux' => AppColors.vert,
        'enquete' => const Color(0xFF6B3FA0),
        'puzzle' => AppColors.warning,
        'association' => AppColors.success,
        'memoire' => AppColors.rouge,
        'calcul' => AppColors.bleu,
        _ => AppColors.primary,
      };
}

class _LoadingScreen extends StatelessWidget {
  final GameModel game;
  final Color color;
  const _LoadingScreen({required this.game, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      SizedBox(
          width: 64,
          height: 64,
          child: CircularProgressIndicator(color: color, strokeWidth: 3)),
      const SizedBox(height: 28),
      Text('Chargement des questions…',
          style: TextStyle(
              fontSize: 16, color: color, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text(game.title,
          style: TextStyle(color: color.withOpacity(0.6), fontSize: 13)),
    ]));
  }
}

class _ReadyScreen extends StatelessWidget {
  final GameModel game;
  final List<QuestionModel> questions;
  final int savedScore, startQuestion;
  final Color color;
  final String? userId;
  const _ReadyScreen({
    required this.game,
    required this.questions,
    required this.savedScore,
    required this.startQuestion,
    required this.color,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final resuming = startQuestion > 0 || savedScore > 0;
    return Center(
        child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(_typeEmoji(game.gameType), style: const TextStyle(fontSize: 64))
            .animate()
            .scale(duration: 400.ms, curve: Curves.elasticOut),
        const SizedBox(height: 20),
        Text(game.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('${questions.length} questions · max ${game.pointsReward} pts',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 8),
        Text(' Durée ${game.time} S',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 20),
        if (resuming)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.2))),
            child: Column(children: [
              Text('⏩ Reprendre la partie',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                  'Question ${startQuestion + 1}/${questions.length} · Score: $savedScore pts',
                  style:
                      TextStyle(color: color.withOpacity(0.7), fontSize: 12)),
            ]),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                  builder: (_) => GamePlayPage(
                        game: game,
                        questions: questions,
                        initialScore: savedScore,
                        initialQuestion: startQuestion,
                        userId: userId,
                      )),
            ),
            icon: Icon(
                resuming ? Icons.play_arrow : Icons.sports_esports_outlined),
            label: Text(resuming ? 'Reprendre' : 'Commencer !',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ]),
    ));
  }

  String _typeEmoji(String? type) => switch (type) {
        'quiz' => '🧠',
        'intrus' => '🔍',
        'tap_challenge' => '⚡',
        'vrai_faux' => '❓',
        'enquete' => '🕵️',
        'puzzle' => '🧩',
        'association' => '🔗',
        'memoire' => '🧲',
        'calcul' => '🔢',
        _ => '🎮',
      };
}

// ════════════════════════════════════════════════════════════════
// PAGE DE JEU PRINCIPAL — dispatche vers le bon widget de jeu
// ════════════════════════════════════════════════════════════════
class GamePlayPage extends ConsumerStatefulWidget {
  final GameModel game;
  final List<QuestionModel> questions;
  final int initialScore;
  final int initialQuestion;
  final String? userId;

  const GamePlayPage({
    super.key,
    required this.game,
    required this.questions,
    required this.initialScore,
    required this.initialQuestion,
    required this.userId,
  });

  @override
  ConsumerState<GamePlayPage> createState() => _GamePlayPageState();
}

class _GamePlayPageState extends ConsumerState<GamePlayPage> {
  late int _qIndex;
  late int _score;
  bool _finished = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _qIndex = widget.initialQuestion;
    _score = widget.initialScore;
  }

  void _onQuestionDone(int pointsEarned) {
    setState(() {
      _score += pointsEarned;
      if (_qIndex + 1 >= widget.questions.length) {
        _finished = true;
        _submitFinal();
      } else {
        _qIndex++;
      }
    });

    final newIndex = _qIndex + 1;
    // Sauvegarde locale à chaque question
    saveLocalProgress(widget.game.id, widget.userId!, _score, newIndex);
  }

  Future<void> _submitFinal() async {
    setState(() => _submitting = true);
    try {
      await supabase.rpc('save_game_progress', params: {
        'p_user_id': widget.userId,
        'p_game_id': widget.game.id,
        'p_score': _score,
        'p_current_q': widget.questions.length,
        'p_completed': true,
      });
      await setGameCooldown(widget.game.id);
      await clearLocalProgress(widget.game.id, widget.userId!);
      ref.invalidate(currentUserProvider);
      ref.invalidate(gameCooldownProvider(widget.game.id));
    } catch (_) {}
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(widget.game.gameType);

    if (_finished) {
      return FinishScreen(
        score: _score,
        total: widget.questions.length,
        color: color,
        gameTitle: widget.game.title,
        submitting: _submitting,
        onBack: () => Navigator.of(context).pop(),
      );
    }

    final q = widget.questions[_qIndex];
    final progress = (_qIndex + 1) / widget.questions.length;

    return Scaffold(
      backgroundColor: color.withOpacity(0.03),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.game.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            )),
        leading: IconButton(
            icon: Icon(
              Icons.close,
              color: color,
            ),
            onPressed: () {
              saveLocalProgress(
                  widget.game.id, widget.userId!, _score, _qIndex + 1);

              Navigator.of(context).pop();
            }),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Q${_qIndex + 1}/${widget.questions.length}',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text('$_score pts',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: color.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ]),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: 300.ms,
        transitionBuilder: (child, anim) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
        child: KeyedSubtree(
          key: ValueKey(_qIndex),
          child: _buildGameWidget(q, color),
        ),
      ),
    );
  }

  Widget _buildGameWidget(QuestionModel q, Color color) {
    switch (widget.game.gameType) {
      case 'quiz':
        return QuizWidget(
            q: q,
            time: widget.game.time,
            color: color,
            onDone: _onQuestionDone);
      case 'intrus':
        return IntrusWidget(
            q: q,
            time: widget.game.time,
            color: color,
            onDone: _onQuestionDone);
      case 'tap_challenge':
        return TapChallengeWidget(color: color, onDone: _onQuestionDone);
      case 'vrai_faux':
        return VraiFauxWidget(
            q: q,
            time: widget.game.time,
            color: color,
            onDone: _onQuestionDone);
      case 'enquete':
        return EnqueteWidget(
            q: q,
            time: widget.game.time,
            color: color,
            onDone: _onQuestionDone);
      case 'puzzle':
        return PuzzleWidget(
            q: q,
            time: widget.game.time,
            color: color,
            onDone: _onQuestionDone);
      case 'association':
        return AssociationWidget(
            q: q,
            time: widget.game.time,
            color: color,
            onDone: _onQuestionDone);
      case 'memoire':
        return MemoireWidget(
            q: q,
            time: widget.game.time,
            color: color,
            onDone: _onQuestionDone);
      case 'calcul':
        return CalculWidget(
            q: q,
            time: widget.game.time,
            color: color,
            onDone: _onQuestionDone);
      default:
        return QuizWidget(
            q: q,
            time: widget.game.time,
            color: color,
            onDone: _onQuestionDone);
    }
  }

  Color _typeColor(String? type) => switch (type) {
        'quiz' => AppColors.primary,
        'intrus' => AppColors.bleu,
        'tap_challenge' => AppColors.danger,
        'vrai_faux' => AppColors.vert,
        'enquete' => const Color(0xFF6B3FA0),
        'puzzle' => AppColors.warning,
        'association' => AppColors.success,
        'memoire' => AppColors.rouge,
        'calcul' => AppColors.bleu,
        _ => AppColors.primary,
      };
}

// ════════════════════════════════════════════════════════════════
// WIDGETS DE JEU INDIVIDUELS
// ════════════════════════════════════════════════════════════════

// ─── Shared: Question header ──────────────────────────────────────────────────
class QuestionCard extends StatelessWidget {
  final String question;
  final Color color;
  final String? subtitle;
  const QuestionCard(
      {super.key, required this.question, required this.color, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Column(children: [
        if (subtitle != null) ...[
          Text(subtitle!,
              style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontSize: 12,
                  fontStyle: FontStyle.italic)),
          const SizedBox(height: 6),
        ],
        Text(question,
            style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.4),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

// ─── Shared: Option button ────────────────────────────────────────────────────
class OptionBtn extends StatelessWidget {
  final String label;
  final int index;
  final bool? isCorrect; // null=neutre, true=vert, false=rouge
  final bool selected;
  final VoidCallback? onTap;
  final Color activeColor;

  const OptionBtn({
    super.key,
    required this.label,
    required this.index,
    this.isCorrect,
    required this.selected,
    this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color bg = cs.surface, border = cs.outline.withOpacity(0.3);
    Color text = cs.onSurface;
    Widget? trail;

    if (isCorrect == true) {
      bg = AppColors.success.withOpacity(0.1);
      border = AppColors.success;
      text = AppColors.success;
      trail =
          const Icon(Icons.check_circle, color: AppColors.success, size: 20);
    } else if (isCorrect == false) {
      bg = AppColors.danger.withOpacity(0.1);
      border = AppColors.danger;
      text = AppColors.danger;
      trail = const Icon(Icons.cancel, color: AppColors.danger, size: 20);
    } else if (selected) {
      bg = activeColor.withOpacity(0.08);
      border = activeColor;
      text = activeColor;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
                color: border, width: isCorrect != null ? 1.5 : 0.8)),
        child: Row(children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                color: border.withOpacity(0.12), shape: BoxShape.circle),
            child: Center(
                child: Text(String.fromCharCode(65 + index),
                    style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.bold,
                        fontSize: 13))),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: text, fontWeight: FontWeight.w500, fontSize: 15))),
          if (trail != null) trail,
        ]),
      ),
    );
  }
}

// ─── Shared: Next button ──────────────────────────────────────────────────────
class NextBtn extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final Color color;
  const NextBtn(
      {super.key,
      required this.onPressed,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13))),
        child: Text(label,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0);
  }
}
