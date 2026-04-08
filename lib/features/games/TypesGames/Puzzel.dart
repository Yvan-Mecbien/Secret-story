import 'dart:async';

import 'package:app/features/games/game_engine.dart';
import 'package:app/shared/models/models.dart';
import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../game_play_page.dart';

// ════════════════════════════════════════════════════════════════
// 6. PUZZLE avec chrono
// ════════════════════════════════════════════════════════════════
class PuzzleWidget extends StatefulWidget {
  final QuestionModel q;
  final Color color;
  final int time; // ⬅️ typé explicitement
  final void Function(int) onDone;

  const PuzzleWidget({
    super.key,
    required this.q,
    required this.time,
    required this.color,
    required this.onDone,
  });

  @override
  State<PuzzleWidget> createState() => _PuzzleWidgetState();
}

class _PuzzleWidgetState extends State<PuzzleWidget> {
  late List<String> _available;
  final List<String> _built = [];
  bool _checked = false;
  bool? _correct;

  // Timer
  int _timeLeft = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _available = List.from(widget.q.options)..shuffle();
    _timeLeft = widget.time;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _timeLeft--;
      });
      if (_timeLeft <= 0 && !_checked) {
        t.cancel();
        // Temps écoulé → réponse incorrecte
        setState(() {
          _checked = true;
          _correct = false;
        });
      }
    });
  }

  void _addWord(String w) {
    if (_checked) return;
    setState(() {
      _available.remove(w);
      _built.add(w);
    });
  }

  void _removeWord(String w) {
    if (_checked) return;
    setState(() {
      _built.remove(w);
      _available.add(w);
    });
  }

  void _check() {
    if (_checked) return;
    final attempt = _built.join(' ');
    final answer = widget.q.answer;
    setState(() {
      _checked = false;
      _correct = attempt == answer;
    });
    _timer?.cancel(); // Arrêter le chrono une fois la réponse donnée
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxSec = widget.time;
    final progress = _timeLeft / maxSec;
    final timerColor = _timeLeft > maxSec * 0.5
        ? AppColors.success
        : _timeLeft > maxSec * 0.25
            ? AppColors.warning
            : AppColors.danger;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Timer (style identique au QuizWidget) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🧩', style: TextStyle(fontSize: 28)),
              Row(
                children: [
                  Icon(Icons.timer_outlined, color: timerColor, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '$_timeLeft s',
                    style: TextStyle(
                      color: timerColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: timerColor.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(timerColor),
            ),
          ),
          const SizedBox(height: 24),

          // --- Intitulé du jeu ---
          Text(
            'Reconstituez la phrase',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),

          // --- Zone de construction ---
          Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _checked
                  ? (_correct! ? AppColors.success : AppColors.danger)
                      .withOpacity(0.08)
                  : cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _checked
                    ? (_correct! ? AppColors.success : AppColors.danger)
                    : widget.color.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: _built.isEmpty
                ? Text(
                    'Tapez les mots ci-dessous…',
                    style: TextStyle(
                      color: cs.onSurface.withOpacity(0.35),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _built
                        .map(
                          (w) => GestureDetector(
                            onTap: () => _removeWord(w),
                            child: Chip(
                              label: Text(
                                w,
                                style: TextStyle(
                                  color: widget.color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: widget.color.withOpacity(0.1),
                              side: BorderSide(
                                color: widget.color.withOpacity(0.3),
                              ),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () => _removeWord(w),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),

          const SizedBox(height: 16),

          // --- Mots disponibles ---
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _available
                .map(
                  (w) => GestureDetector(
                    onTap: () => _addWord(w),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: cs.outline.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        w,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          const Spacer(),

          // --- Bouton Vérifier (si pas encore vérifié et phrase non vide) ---
          if (!_checked && _built.isNotEmpty)
            NextBtn(
              color: widget.color,
              label: 'Vérifier ✓',
              onPressed: _check,
            ),

          // --- Résultat (si vérifié ou timeout) ---
          if (_checked) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (_correct! ? AppColors.success : AppColors.danger)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _correct!
                    ? '✅ Parfait !'
                    // : '❌ La bonne réponse était : ${widget.q.answer}',
                    : '❌ La bonne réponse était : ',
                style: TextStyle(
                  color: _correct! ? AppColors.success : AppColors.danger,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            NextBtn(
              color: widget.color,
              label: 'Suivant →',
              onPressed: () => widget.onDone(
                _correct!
                    ? GameEngine.calcScore(gameType: 'puzzle', correct: true)
                    : 0,
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
