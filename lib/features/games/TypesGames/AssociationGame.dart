// ════════════════════════════════════════════════════════════════
// 7. ASSOCIATION RAPIDE (avec chrono circulaire)
// ════════════════════════════════════════════════════════════════
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../shared/models/models.dart';
import '../../../shared/theme/app_theme.dart';
import '../game_engine.dart';
import '../game_play_page.dart';

class AssociationWidget extends StatefulWidget {
  final QuestionModel q;
  final Color color;
  final int time; // ← temps en secondes
  final void Function(int) onDone;

  const AssociationWidget({
    super.key,
    required this.q,
    required this.color,
    required this.time,
    required this.onDone,
  });

  @override
  State<AssociationWidget> createState() => _AssociationWidgetState();
}

class _AssociationWidgetState extends State<AssociationWidget> {
  int _selected = -1;
  bool _answered = false;
  bool _isCorrect = false; // ← pour savoir si la réponse est juste
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
          _selected = -1; // aucun surlignement rouge
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
    _timer?.cancel(); // on arrête le chrono dès qu'une réponse est donnée
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Valeurs pour le chronomètre circulaire
    final double progress = (_timeLeft / widget.time).clamp(0.0, 1.0);
    final Color timerColor = _timeLeft > widget.time * 0.5
        ? AppColors.success
        : _timeLeft > widget.time * 0.25
            ? AppColors.warning
            : AppColors.danger;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('🔗',
              style: TextStyle(fontSize: 40), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: widget.color, borderRadius: BorderRadius.circular(20)),
            child: Text(widget.q.question,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ).animate().scale(
              duration: 350.ms,
              curve: Curves.elasticOut,
              begin: const Offset(0.8, 0.8),
              end: const Offset(1, 1)),
          const SizedBox(height: 8),
          Center(
              child: Icon(Icons.arrow_downward, color: widget.color, size: 28)
                  .animate(onPlay: (c) => c.repeat())
                  .moveY(
                      begin: 0,
                      end: 5,
                      duration: 800.ms,
                      curve: Curves.easeInOut)
                  .then()
                  .moveY(begin: 5, end: 0, duration: 800.ms)),
          const SizedBox(height: 8),
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
          const Spacer(),

          // ─── Chronomètre circulaire (en bas) ─────────────────
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
                    ? GameEngine.calcScore(
                        gameType: 'association', correct: true)
                    : 0,
              ),
            ),
        ],
      ),
    );
  }
}
