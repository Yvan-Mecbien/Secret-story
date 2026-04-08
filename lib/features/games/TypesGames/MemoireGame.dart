// ════════════════════════════════════════════════════════════════
// 1. QUIZ + 8. MÉMOIRE INVERSÉE (avec double timer)
// ════════════════════════════════════════════════════════════════
import 'dart:async';

import 'package:app/shared/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../shared/theme/app_theme.dart';
import '../game_engine.dart';
import '../game_play_page.dart';

class MemoireWidget extends StatefulWidget {
  final QuestionModel q;
  final Color color;
  final int time; // temps pour répondre (après la mémorisation)
  final void Function(int) onDone;

  const MemoireWidget({
    super.key,
    required this.q,
    required this.time,
    required this.color,
    required this.onDone,
  });

  @override
  State<MemoireWidget> createState() => _MemoireWidgetState();
}

class _MemoireWidgetState extends State<MemoireWidget> {
  bool _memorizing = true;
  int _selected = -1;
  bool _answered = false;
  bool _isCorrect = false;

  // Timer pour la phase de mémorisation
  Timer? _memorizeTimer;

  // Timer pour la phase de réponse
  int _timeLeft = 0;
  Timer? _answerTimer;

  @override
  void initState() {
    super.initState();
    // Phase de mémorisation : 3 secondes fixes
    _memorizeTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _memorizing = false;
        });
        // Démarrer le chrono de réponse
        _startAnswerTimer();
      }
    });
  }

  void _startAnswerTimer() {
    _timeLeft = widget.time;
    _answerTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_timeLeft > 0) _timeLeft--;
      });
      if (_timeLeft <= 0 && !_answered) {
        t.cancel();
        // Timeout → réponse fausse, sans révéler la bonne réponse
        setState(() {
          _answered = true;
          _isCorrect = false;
          _selected = -1;
        });
      }
    });
  }

  void _onTapOption(int index) {
    if (_answered || _memorizing) return;
    setState(() {
      _selected = index;
      _answered = true;
      _isCorrect = (index == widget.q.answerIndex);
    });
    _answerTimer?.cancel();
  }

  @override
  void dispose() {
    _memorizeTimer?.cancel();
    _answerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wordsToShow =
        (widget.q.extra?['show_without'] as List?)?.cast<String>() ?? [];
    final allWords = widget.q.options;

    // Valeurs pour le chrono (barre linéaire)
    final maxSec = widget.time;
    final progress = (maxSec > 0) ? (_timeLeft / maxSec).clamp(0.0, 1.0) : 1.0;
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
          // Affichage du chronomètre (uniquement en phase réponse)
          if (!_memorizing) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('🧲', style: TextStyle(fontSize: 28)),
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
          ] else
            const SizedBox(height: 10),

          AnimatedSwitcher(
            duration: 500.ms,
            child: _memorizing
                ? Column(
                    key: const ValueKey('mem'),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Mémorisez ces mots ! (3s)',
                          style: TextStyle(
                            color: widget.color,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: widget.q.options.map((w) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              color: widget.color,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              w,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  )
                : Column(
                    key: const ValueKey('ans'),
                    children: [
                      Text(
                        '❓ Quel mot a disparu ?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: wordsToShow.map((w) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: widget.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: widget.color.withOpacity(0.3)),
                            ),
                            child: Text(
                              w,
                              style: TextStyle(
                                color: widget.color,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      ...allWords.asMap().entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: OptionBtn(
                                label: e.value,
                                index: e.key,
                                activeColor: widget.color,
                                selected: _selected == e.key,
                                isCorrect: _answered
                                    ? (_isCorrect &&
                                            e.key == widget.q.answerIndex)
                                        ? true
                                        : (_selected == e.key && !_isCorrect)
                                            ? false
                                            : null
                                    : null,
                                onTap: _answered || _memorizing
                                    ? null
                                    : () => _onTapOption(e.key),
                              ),
                            ),
                          ),
                    ],
                  ),
          ),
          const Spacer(),
          if (!_memorizing && _answered)
            NextBtn(
              color: widget.color,
              label: 'Suivant →',
              onPressed: () => widget.onDone(
                _isCorrect
                    ? GameEngine.calcScore(gameType: 'memoire', correct: true)
                    : 0,
              ),
            ),
        ],
      ),
    );
  }
}
