import 'dart:async';

import 'package:app/features/games/game_engine.dart';
import 'package:app/shared/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../shared/theme/app_theme.dart';
import '../game_play_page.dart';

// ════════════════════════════════════════════════════════════════
// 2. INTRUS (avec chrono à barre)
// ════════════════════════════════════════════════════════════════
class IntrusWidget extends StatefulWidget {
  final QuestionModel q;
  final Color color;
  final int time;
  final void Function(int) onDone;

  const IntrusWidget({
    super.key,
    required this.q,
    required this.color,
    required this.time,
    required this.onDone,
  });

  @override
  State<IntrusWidget> createState() => _IntrusWidgetState();
}

class _IntrusWidgetState extends State<IntrusWidget> {
  int _selected = -1;
  bool _answered = false;
  bool _isCorrect = false;
  int _timeLeft = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
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
        if (_timeLeft > 0) _timeLeft--;
      });
      if (_timeLeft <= 0 && !_answered) {
        t.cancel();
        // Timeout → réponse fausse, sans afficher l'intrus
        setState(() {
          _answered = true;
          _isCorrect = false;
          _selected = -1;
        });
      }
    });
  }

  void _onTapOption(int index) {
    if (_answered) return;
    setState(() {
      _selected = index;
      _answered = true;
      _isCorrect = (index == widget.q.answerIndex);
    });
    _timer?.cancel();
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
    final progress = (_timeLeft / maxSec).clamp(0.0, 1.0);
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
          // --- Barre de chronomètre ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🔍', style: TextStyle(fontSize: 28)),
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

          QuestionCard(
            question: widget.q.question,
            color: widget.color,
            subtitle: '🔍 Trouvez l\'intrus parmi ces mots',
          ),
          const SizedBox(height: 24),

          // Grille 2×2
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: widget.q.options.asMap().entries.map((e) {
              final int index = e.key;
              final String label = e.value;
              final bool isIntrus = (index == widget.q.answerIndex);

              // Déterminer la couleur de fond, bordure et texte
              Color bg = cs.surface;
              Color border = cs.outline.withOpacity(0.3);
              Color text = cs.onSurface;
              IconData icon = Icons.circle_outlined;

              if (_answered) {
                if (_isCorrect) {
                  // Bonne réponse : on montre l'intrus (vert) et les autres restent neutres
                  if (isIntrus) {
                    bg = AppColors.success.withOpacity(0.1);
                    border = AppColors.success;
                    text = AppColors.success;
                    icon = Icons.check_circle_outline;
                  } else {
                    // Les autres options n'ont pas de couleur spéciale
                  }
                } else {
                  // Mauvaise réponse : on ne montre PAS l'intrus
                  // Seule l'option choisie par l'utilisateur devient rouge
                  if (index == _selected) {
                    bg = AppColors.danger.withOpacity(0.1);
                    border = AppColors.danger;
                    text = AppColors.danger;
                    icon = Icons.warning_amber_rounded;
                  }
                  // L'intrus reste totalement neutre (non révélé)
                }
              } else if (index == _selected) {
                // Sélection en cours (avant validation)
                bg = widget.color.withOpacity(0.1);
                border = widget.color;
                text = widget.color;
                icon = Icons.circle_outlined;
              }

              return GestureDetector(
                onTap: _answered ? null : () => _onTapOption(index),
                child: AnimatedContainer(
                  duration: 200.ms,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: border,
                      width: (index == _selected ||
                              (_answered &&
                                  ((_isCorrect && isIntrus) ||
                                      (!_isCorrect && index == _selected))))
                          ? 2
                          : 0.8,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: text, size: 20),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          color: text,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ).animate().scale(
                    delay: Duration(milliseconds: 60 * index),
                    duration: 250.ms,
                    curve: Curves.easeOut,
                    begin: const Offset(0.85, 0.85),
                    end: const Offset(1, 1),
                  );
            }).toList(),
          ),

          const Spacer(),

          if (_answered)
            NextBtn(
              color: widget.color,
              label: 'Suivant →',
              onPressed: () => widget.onDone(
                _isCorrect
                    ? GameEngine.calcScore(gameType: 'intrus', correct: true)
                    : 0,
              ),
            ),
        ],
      ),
    );
  }
}
