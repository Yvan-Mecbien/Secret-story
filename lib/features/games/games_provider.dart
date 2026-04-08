import 'dart:async';
import 'package:app/core/supabase_client.dart';
import 'package:app/features/auth/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../shared/models/models.dart';

// ─── Stream des jeux ─────────────────────────────────────────────────────────
final gamesStreamProvider = StreamProvider<List<GameModel>>((ref) {
  return supabase.from('games').stream(primaryKey: ['id']).map(
      (data) => (data as List).map((j) => GameModel.fromJson(j)).toList());
});

// ─── Jeu par ID ───────────────────────────────────────────────────────────────
final gameByIdProvider =
    FutureProvider.family<GameModel?, String>((ref, id) async {
  final data = await supabase.from('games').select().eq('id', id).maybeSingle();
  if (data == null) return null;
  return GameModel.fromJson(data);
});

// ─── Nom des boxes ────────────────────────────────────────────────────────────
const _cooldownBoxName = 'game_cooldown_box'; // contient les timestamps de fin
const _progressBoxName = 'game_progress_box'; // contient score, index, fini

// ─── Clés pour le cooldown ───────────────────────────────────────────────────
String _cooldownKey(String gameId) => 'cooldown_$gameId';

/// Retourne la date de fin du cooldown si actif, sinon null.
Future<DateTime?> getGameCooldown(String gameId) async {
  final box = await Hive.openBox<int>(_cooldownBoxName);
  final ms = box.get(_cooldownKey(gameId));
  if (ms == null) return null;
  final end = DateTime.fromMillisecondsSinceEpoch(ms);
  if (DateTime.now().isAfter(end)) {
    await box.delete(_cooldownKey(gameId));
    return null;
  }
  return end;
}

/// Définit un cooldown de 16h à partir de maintenant.
Future<void> setGameCooldown(String gameId) async {
  final box = await Hive.openBox<int>(_cooldownBoxName);
  final end = DateTime.now().add(const Duration(hours: 16));
  await box.put(_cooldownKey(gameId), end.millisecondsSinceEpoch);
}

// ─── Provider cooldown ───────────────────────────────────────────────────────
final gameCooldownProvider =
    FutureProvider.family<DateTime?, String>((ref, gameId) async {
  return getGameCooldown(gameId);
});

// ─── Questions d'un jeu (inchangé, utilise Supabase) ─────────────────────────
final questionsProvider =
    FutureProvider.family<List<QuestionModel>, String>((ref, gameId) async {
  final data = await supabase
      .from('questions')
      .select()
      .eq('game_id', gameId)
      .order('position');
  return (data as List).map((j) => QuestionModel.fromJson(j)).toList();
});

// ─── Clés pour la progression locale ─────────────────────────────────────────
String _localScoreKey(String gameId, String userId) =>
    'score_${userId}_$gameId';
String _localQKey(String gameId, String userId) => 'qidx_${userId}_$gameId';
String _localFinishKey(String gameId, String userId) =>
    'finish_${userId}_$gameId';

Future<(dynamic, dynamic, dynamic)> loadLocalProgress(
    String gameId, String userId) async {
  final box = await Hive.openBox(_progressBoxName);
  final score = box.get(_localScoreKey(gameId, userId)) ?? 0;
  final q = box.get(_localQKey(gameId, userId)) ?? 0;
  final finish = box.get(_localFinishKey(gameId, userId)) ?? false;
  return (score, q, finish);
}

Future<void> saveLocalProgress(
    String gameId, String userId, int score, int questionIndex) async {
  final box = await Hive.openBox(_progressBoxName);
  await box.put(_localScoreKey(gameId, userId), score);
  await box.put(_localQKey(gameId, userId), questionIndex);
}

Future<void> clearLocalProgress(String gameId, String userId) async {
  final box = await Hive.openBox(_progressBoxName);
  await box.delete(_localScoreKey(gameId, userId));
  await box.delete(_localQKey(gameId, userId));
  await box.delete(_localFinishKey(gameId, userId));
}

// ─── Game Session Notifier ────────────────────────────────────────────────────
class GameSessionNotifier extends StateNotifier<GameSessionState> {
  final String gameId;
  final String userId;
  final bool isFinish;
  Timer? _autoSaveTimer; // sauvegarde toutes les 30 min si pas terminé

  GameSessionNotifier({
    required this.gameId,
    required this.userId,
    required this.isFinish,
    required int initialScore,
    required int initialQuestion,
  }) : super(GameSessionState(
          score: initialScore,
          currentQuestion: initialQuestion,
          completed: false,
          startedAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
        )) {
    // Timer 30 min → sauvegarder même si pas terminé
    _autoSaveTimer = Timer(const Duration(minutes: 30), _autoSave);
  }

  void addScore(int pts) {
    state = state.copyWith(
      score: state.score + pts,
      lastActiveAt: DateTime.now(),
    );
    saveLocalProgress(gameId, userId, state.score, state.currentQuestion);
  }

  /// Avance à la question suivante (la question actuelle est perdue si on quitte)
  void nextQuestion() {
    state = state.copyWith(
      currentQuestion: state.currentQuestion + 1,
      lastActiveAt: DateTime.now(),
    );
    saveLocalProgress(
      gameId,
      userId,
      state.score,
      state.currentQuestion,
    );
  }

  Future<void> finish() async {
    state = state.copyWith(completed: true);
    _autoSaveTimer?.cancel();
    await _saveToDb(completed: true);
    await clearLocalProgress(gameId, userId);
  }

  Future<void> _autoSave() async {
    if (!state.completed) {
      await _saveToDb(completed: false);
    }
  }

  Future<void> _saveToDb({required bool completed}) async {
    try {
      await supabase.rpc('save_game_progress', params: {
        'p_user_id': userId,
        'p_game_id': gameId,
        'p_score': state.score,
        'p_current_q': state.currentQuestion,
        'p_completed': completed,
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    // Sauvegarde locale à la sortie
    saveLocalProgress(gameId, userId, state.score, state.currentQuestion);
    super.dispose();
  }
}

final gameSessionProvider = StateNotifierProvider.autoDispose.family<
    GameSessionNotifier, GameSessionState, (String, String, int, int, bool)>(
  (ref, args) {
    final (gameId, userId, score, question, isFinish) = args;
    return GameSessionNotifier(
      gameId: gameId,
      userId: userId,
      isFinish: isFinish,
      initialScore: score,
      initialQuestion: question,
    );
  },
);

final hasParticipatedProvider =
    FutureProvider.family<bool, String>((ref, gameId) async {
  final userIdAsync = ref.watch(currentUserProvider);
  String userId = '';

  userIdAsync.when(
    data: (user) async {
      if (user == null) return;
      userId = user.id;
    },
    error: (Object error, StackTrace stackTrace) {},
    loading: () {},
  );
  final data = await supabase
      .from('game_participations')
      .select('id')
      .eq('user_id', userId)
      .eq('game_id', gameId)
      .maybeSingle();
  return data != null;
});
