// ════════════════════════════════════════════════════════════════
// 4. VRAI / FAUX (avec chronomètre)
// ════════════════════════════════════════════════════════════════
import 'dart:async';
import 'package:app/features/games/game_engine.dart';
import 'package:app/shared/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../shared/theme/app_theme.dart';
import '../game_play_page.dart';

class VraiFauxWidget extends StatefulWidget {
  final QuestionModel q;
  final Color color;
  final int time;
  final void Function(int) onDone;
  const VraiFauxWidget({
    super.key,
    required this.q,
    required this.time,
    required this.color,
    required this.onDone,
  });

  @override
  State<VraiFauxWidget> createState() => _VraiFauxWidgetState();
}

class _VraiFauxWidgetState extends State<VraiFauxWidget> {
  int _selected = -1;
  bool _answered = false;
  int _timeLeft = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.time;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        }
      });
      if (_timeLeft <= 0 && !_answered) {
        timer.cancel();
        _onTimeout();
      }
    });
  }

  Future<void> _onTimeout() async {
    if (_answered) return;
    setState(() {
      _answered = false;
      _selected = -1; // aucun choix sélectionné
    });
    // Attendre un peu pour que l'utilisateur voie le timeout
    await Future.delayed(1500.ms);
    if (mounted) widget.onDone(0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Chronomètre affiché (optionnel mais recommandé)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_outlined, color: widget.color, size: 28),
            const SizedBox(width: 8),
            Text(
              '$_timeLeft s',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _timeLeft <= 5 ? AppColors.danger : widget.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('❓',
            style: TextStyle(fontSize: 40), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        QuestionCard(
          question: widget.q.question,
          color: widget.color,
          subtitle: 'Cette affirmation est-elle vraie ou fausse ?',
        ),
        const Spacer(),
        Row(children: [
          Expanded(
            child: _VFBtn(
              label: 'VRAI ✅',
              index: 0,
              color: AppColors.success,
              answered: _answered,
              selected: _selected,
              correctIndex: widget.q.answerIndex,
              onTap: _answered ? null : () => _onAnswer(0),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _VFBtn(
              label: 'FAUX ❌',
              index: 1,
              color: AppColors.danger,
              answered: _answered,
              selected: _selected,
              correctIndex: widget.q.answerIndex,
              onTap: _answered ? null : () => _onAnswer(1),
            ),
          ),
        ]),
        const SizedBox(height: 20),
        if (_answered)
          NextBtn(
            color: widget.color,
            label: 'Suivant →',
            onPressed: () => widget.onDone(
              _selected == widget.q.answerIndex
                  ? GameEngine.calcScore(gameType: 'vrai_faux', correct: true)
                  : 0,
            ),
          ),
        const SizedBox(height: 16),
      ]),
    );
  }

  void _onAnswer(int index) {
    if (_answered) return;
    _timer?.cancel();
    setState(() {
      _selected = index;
      _answered = true;
    });
  }
}

class _VFBtn extends StatelessWidget {
  final String label;
  final int index, correctIndex, selected;
  final Color color;
  final bool answered;
  final VoidCallback? onTap;
  const _VFBtn({
    required this.label,
    required this.index,
    required this.correctIndex,
    required this.selected,
    required this.color,
    required this.answered,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool? correct;
    if (answered) {
      if (index == correctIndex) {
        correct = true;
      } else if (selected == index) {
        correct = false;
      } else {
        correct = null;
      }
    }
    final bg = correct == true
        ? color.withOpacity(0.15)
        : correct == false
            ? AppColors.danger.withOpacity(0.1)
            : selected == index
                ? color.withOpacity(0.1)
                : Colors.transparent;
    final border = correct == true
        ? color
        : correct == false
            ? AppColors.danger
            : selected == index
                ? color
                : Colors.grey.withOpacity(0.3);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        height: 90,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: 2),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: correct == true
                  ? color
                  : correct == false
                      ? AppColors.danger
                      : null,
            ),
          ),
        ),
      ),
    );
  }
}
