import 'dart:async';
import 'dart:math';

import 'package:app/features/games/game_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ════════════════════════════════════════════════════════════════
// 3. TAP CHALLENGE
// ════════════════════════════════════════════════════════════════
class TapChallengeWidget extends StatefulWidget {
  final Color color;
  final void Function(int) onDone;
  const TapChallengeWidget(
      {super.key, required this.color, required this.onDone});
  @override
  State<TapChallengeWidget> createState() => _TapChallengeState();
}

class _TapChallengeState extends State<TapChallengeWidget> {
  double? _x, _y;
  DateTime? _appeared;
  bool _done = false;
  Timer? _timer;
  int? _reactionMs;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _spawnButton();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _spawnButton() {
    final delay = Duration(milliseconds: 600 + _rng.nextInt(2000));
    _timer = Timer(delay, () {
      if (!mounted) return;
      setState(() {
        _x = 0.1 + _rng.nextDouble() * 0.7;
        _y = 0.15 + _rng.nextDouble() * 0.55;
        _appeared = DateTime.now();
      });
    });
  }

  void _onTap() {
    if (_appeared == null || _done) return;
    final ms = DateTime.now().difference(_appeared!).inMilliseconds;
    setState(() {
      _done = true;
      _reactionMs = ms;
    });
    Future.delayed(1500.ms, () {
      if (mounted) {
        widget.onDone(GameEngine.calcScore(
            gameType: 'tap_challenge', correct: true, reactionMs: ms));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(children: [
      // Instructions
      Positioned(
        top: 20,
        left: 0,
        right: 0,
        child: Column(children: [
          const Text('⚡', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 10),
          const Text('Tapez le bouton dès qu\'il apparaît !',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
          if (_done && _reactionMs != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Text('⚡ ${_reactionMs}ms !',
                  style: TextStyle(
                      color: widget.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
          ] else if (_x == null) ...[
            const SizedBox(height: 12),
            Text('Préparez-vous…',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          ],
        ]),
      ),
      // Bouton qui apparaît
      if (_x != null && _y != null && !_done)
        Positioned(
          left: _x! * (size.width - 80),
          top: _y! * (size.height - 200),
          child: GestureDetector(
            onTap: _onTap,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: widget.color.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 4)
                  ]),
              child: const Center(
                  child: Text('👆', style: TextStyle(fontSize: 30))),
            ).animate().scale(
                duration: 300.ms,
                curve: Curves.elasticOut,
                begin: const Offset(0, 0),
                end: const Offset(1, 1)),
          ),
        ),
    ]);
  }
}
