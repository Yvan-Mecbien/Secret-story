import 'dart:async';

import 'package:app/shared/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../shared/theme/app_theme.dart';
import '../game_engine.dart';
import '../game_play_page.dart';

class QuizWidget extends StatefulWidget {
  final QuestionModel q;
  final Color color;
  final int time;
  final void Function(int) onDone;

  const QuizWidget({
    super.key,
    required this.q,
    required this.time,
    required this.color,
    required this.onDone,
  });

  @override
  State<QuizWidget> createState() => QuizWidgetState();
}

class QuizWidgetState extends State<QuizWidget> {
  int _selected = -1;
  bool _answered = false;
  int _timeLeft = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.time;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _timeLeft--;
      });
      if (_timeLeft <= 0) {
        t.cancel();
        if (!_answered) {
          setState(() {
            _answered = false;
            _selected = -1;
          });
          Future.delayed(1500.ms, () {
            if (mounted) widget.onDone(0);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxSec = widget.time; // ✅ correction ici
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
            subtitle: 'Quiz — choisissez la bonne réponse',
          ),
          const SizedBox(height: 20),
          ...widget.q.options.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OptionBtn(
                    label: e.value,
                    index: e.key,
                    activeColor: widget.color,
                    selected: _selected == e.key,
                    isCorrect: _answered
                        ? e.key == widget.q.answerIndex
                            ? true
                            : _selected == e.key
                                ? false
                                : null
                        : null,
                    onTap: _answered
                        ? null
                        : () => setState(() {
                              _selected = e.key;
                              _answered = true;
                            }),
                  ).animate().fadeIn(
                      delay: Duration(milliseconds: 50 * e.key),
                      duration: 200.ms),
                ),
              ),
          const Spacer(),
          if (_answered)
            NextBtn(
              color: widget.color,
              label: 'Question suivante →',
              onPressed: () => widget.onDone(
                _selected == widget.q.answerIndex
                    ? GameEngine.calcScore(gameType: 'quiz', correct: true)
                    : 0,
              ),
            ),
        ],
      ),
    );
  }
}
