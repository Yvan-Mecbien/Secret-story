// ============================================================
// GAME ENGINE — logique de score par type de jeu
// ============================================================

class GameEngine {
  /// Calcule les points selon le type de jeu
  static int calcScore({
    required String gameType,
    required bool correct,
    int? reactionMs,   // pour tap_challenge / calcul
    int? maxSeconds,   // pour calcul
    int basePoints = 10,
  }) {
    if (!correct) return 0;
    switch (gameType) {
      case 'tap_challenge':
        // Plus rapide = plus de points (max 30, min 5)
        if (reactionMs == null) return basePoints;
        final ms = reactionMs.clamp(100, 2000);
        return (30 - ((ms - 100) / 2000 * 25)).round().clamp(5, 30);

      case 'calcul':
        // Bonus si répondu < 50% du temps imparti
        if (reactionMs == null || maxSeconds == null) return basePoints;
        final ratio = reactionMs / (maxSeconds * 1000);
        if (ratio < 0.3) return (basePoints * 2).round();
        if (ratio < 0.6) return (basePoints * 1.5).round();
        return basePoints;

      case 'memoire':
        return basePoints + 5; // bonus mémoire

      case 'enquete':
        return basePoints * 2; // enquête = double points

      default:
        return basePoints;
    }
  }
}
