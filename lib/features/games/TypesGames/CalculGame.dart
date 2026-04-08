import 'dart:async';

import 'package:app/shared/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../shared/theme/app_theme.dart';
import '../game_engine.dart';

// ════════════════════════════════════════════════════════════════
// 9. CALCUL RAPIDE
// ════════════════════════════════════════════════════════════════
class CalculWidget extends StatefulWidget {
  final QuestionModel q;
  final Color color;
  final int time;
  final void Function(int) onDone;
  const CalculWidget(
      {super.key,
      required this.q,
      required this.time,
      required this.color,
      required this.onDone});
  @override
  State<CalculWidget> createState() => _CalculWidgetState();
}

class _CalculWidgetState extends State<CalculWidget> {
  int _selected = -1;
  bool _answered = false;
  DateTime? _startTime;
  int _timeLeft = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    // final maxSec = (widget.q.extra?['max_seconds'] as int?) ?? 10;
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
    final maxSec = (widget.q.extra?['max_seconds'] as int?) ?? 20;
    final progress = _timeLeft / maxSec;
    final timerColor = _timeLeft > maxSec * 0.5
        ? AppColors.success
        : _timeLeft > maxSec * 0.25
            ? AppColors.warning
            : AppColors.danger;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Timer
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('🔢', style: TextStyle(fontSize: 28)),
          Row(children: [
            Icon(Icons.timer_outlined, color: timerColor, size: 18),
            const SizedBox(width: 4),
            Text('$_timeLeft s',
                style: TextStyle(
                    color: timerColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ]),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: timerColor.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(timerColor)),
        ),
        const SizedBox(height: 24),

        // Calcul
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
              color: widget.color, borderRadius: BorderRadius.circular(24)),
          child: Text(widget.q.question,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
        ).animate().scale(
            duration: 300.ms,
            curve: Curves.easeOut,
            begin: const Offset(0.9, 0.9),
            end: const Offset(1, 1)),
        const SizedBox(height: 24),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: widget.q.options.asMap().entries.map((e) {
            final isCorrect = _answered
                ? e.key == widget.q.answerIndex
                    ? true
                    : _selected == e.key
                        ? false
                        : null
                : null;
            final isSelected = _selected == e.key;
            Color bg = Theme.of(context).colorScheme.surface;
            Color border =
                Theme.of(context).colorScheme.outline.withOpacity(0.3);
            Color text = Theme.of(context).colorScheme.onSurface;
            if (isCorrect == true) {
              // ignore: deprecated_member_use
              bg = AppColors.success.withOpacity(0.1);
              border = AppColors.success;
              text = AppColors.success;
            } else if (isCorrect == false) {
              bg = AppColors.danger.withOpacity(0.1);
              border = AppColors.danger;
              text = AppColors.danger;
            } else if (isSelected) {
              bg = widget.color.withOpacity(0.1);
              border = widget.color;
              text = widget.color;
            }

            return GestureDetector(
              onTap: _answered
                  ? null
                  : () {
                      _timer?.cancel();
                      final ms =
                          DateTime.now().difference(_startTime!).inMilliseconds;
                      setState(() {
                        _selected = e.key;
                        _answered = true;
                      });
                      Future.delayed(1200.ms, () {
                        if (mounted) {
                          widget.onDone(e.key == widget.q.answerIndex
                              ? GameEngine.calcScore(
                                  gameType: 'calcul',
                                  correct: true,
                                  reactionMs: ms,
                                  maxSeconds: maxSec)
                              : 0);
                        }
                      });
                    },
              child: AnimatedContainer(
                duration: 200.ms,
                decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: border,
                        width: isSelected || isCorrect != null ? 2 : 0.8)),
                child: Center(
                    child: Text(e.value,
                        style: TextStyle(
                            color: text,
                            fontSize: 20,
                            fontWeight: FontWeight.bold))),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }
}
