import 'dart:async';

import 'package:app/features/games/game_engine.dart';
import 'package:app/shared/models/models.dart';
import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart'; // pour AppColors
import '../game_play_page.dart';

// ════════════════════════════════════════════════════════════════
// 5. ENQUÊTE (avec chrono circulaire)
// ════════════════════════════════════════════════════════════════
class EnqueteWidget extends StatefulWidget {
  final QuestionModel q;
  final Color color;
  final int time;
  final void Function(int) onDone;

  const EnqueteWidget({
    super.key,
    required this.q,
    required this.time,
    required this.color,
    required this.onDone,
  });

  @override
  State<EnqueteWidget> createState() => _EnqueteWidgetState();
}

class _EnqueteWidgetState extends State<EnqueteWidget> {
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
        // Timeout → réponse fausse, sans afficher la bonne réponse
        setState(() {
          _answered = true;
          _isCorrect = false;
          _selected = -1; // aucun surlignement
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
    _timer?.cancel(); // arrêt du chrono dès qu'une réponse est donnée
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.q.extra?['story'] as String?;
    final maxSec = widget.time;
    final progress = (_timeLeft / maxSec).clamp(0.0, 1.0);
    final timerColor = _timeLeft > maxSec * 0.5
        ? AppColors.success
        : _timeLeft > maxSec * 0.25
            ? AppColors.warning
            : AppColors.danger;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('🕵️',
              style: TextStyle(fontSize: 40), textAlign: TextAlign.center),
          const SizedBox(height: 14),
          if (story != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: widget.color.withOpacity(0.2)),
              ),
              child: Text(
                story,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 14,
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          Text(
            '🔎 Qui est le coupable ?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ...widget.q.options.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OptionBtn(
                  label: e.value,
                  index: e.key,
                  activeColor: widget.color,
                  selected: _selected == e.key,
                  isCorrect: _answered
                      ? (_isCorrect && e.key == widget.q.answerIndex)
                          ? true // ✅ vert uniquement si bonne réponse
                          : (_selected == e.key && !_isCorrect)
                              ? false // ❌ rouge pour l'option choisie si fausse
                              : null // pas de couleur spéciale
                      : null,
                  onTap: _answered ? null : () => _onTapOption(e.key),
                ),
              )),
          const SizedBox(height: 20),

          // Chronomètre circulaire (en bas, tant que non répondu)
          if (!_answered)
            Center(
              child: SizedBox(
                width: 70,
                height: 70,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: timerColor.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                    ),
                    Text(
                      '$_timeLeft',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: timerColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          if (_answered)
            NextBtn(
              color: widget.color,
              label: 'Suivant →',
              onPressed: () => widget.onDone(
                _isCorrect
                    ? GameEngine.calcScore(gameType: 'enquete', correct: true)
                    : 0,
              ),
            ),
        ],
      ),
    );
  }
}
