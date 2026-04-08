// ════════════════════════════════════════════════════════════════
// ÉCRAN DE FIN
// ════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FinishScreen extends StatelessWidget {
  final int score, total;
  final Color color;
  final String gameTitle;
  final bool submitting;
  final VoidCallback onBack;
  const FinishScreen(
      {super.key,
      required this.score,
      required this.total,
      required this.color,
      required this.gameTitle,
      required this.submitting,
      required this.onBack});

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? score / (total * 10) : 0;
    final emoji = ratio >= 0.8
        ? '🏆'
        : ratio >= 0.5
            ? '🎉'
            : '👍';

    return Scaffold(
      backgroundColor: color.withOpacity(0.04),
      body: SafeArea(
          child: Center(
              child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(emoji, style: const TextStyle(fontSize: 72))
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 20),
          const Text('Jeu terminé !',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(gameTitle,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.2))),
            child: Column(children: [
              Text('$score',
                  style: TextStyle(
                      fontSize: 52, fontWeight: FontWeight.bold, color: color)),
              Text('points gagnés',
                  style:
                      TextStyle(color: color.withOpacity(0.7), fontSize: 14)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                    value: ratio.clamp(0, 1).toDouble(),
                    minHeight: 8,
                    backgroundColor: color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation(color)),
              ),
            ]),
          ).animate().fadeIn(delay: 300.ms),
          // const SizedBox(height: 16),
          // Text('⏰ Disponible à nouveau dans 16h',
          //     style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 32),
          if (submitting)
            const CircularProgressIndicator()
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.home_outlined),
                label: const Text('Retour aux jeux',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
              ).animate().fadeIn(delay: 500.ms),
            ),
        ]),
      ))),
    );
  }
}
