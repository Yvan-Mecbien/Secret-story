import 'dart:math';
import 'package:app/features/auth/StorageService.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_client.dart';
import '../../shared/models/models.dart';
import 'package:hive/hive.dart';

const _maxVotesPerDay = 3; // Nombre maximal de votes
const _windowHours = 15; // Fenêtre de 15 heures
const _windowMilliseconds = _windowHours * 60 * 60 * 1000;

// Clés Hive
const _votesBoxName = 'votes_box';
const _timestampsKey = 'vote_timestamps';

// ─── Provider ────────────────────────────────────────────────────────────────
final votesRemainingProvider =
    StateNotifierProvider<VotesRemainingNotifier, int>(
  (ref) => VotesRemainingNotifier(),
);

class VotesRemainingNotifier extends StateNotifier<int> {
  late final Box _box;

  VotesRemainingNotifier() : super(_maxVotesPerDay) {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox(_votesBoxName);
    _updateRemaining();
  }

  /// Calcule le nombre de votes encore possibles dans la fenêtre glissante
  void _updateRemaining() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final List<int> timestamps = _getStoredTimestamps();

    // Garder uniquement les votes des dernières 15h
    final validTimestamps =
        timestamps.where((ts) => now - ts <= _windowMilliseconds).toList();

    // Mettre à jour la boîte avec la liste filtrée
    _box.put(_timestampsKey, validTimestamps);

    final used = validTimestamps.length;
    state = (_maxVotesPerDay - used).clamp(0, _maxVotesPerDay);
  }

  /// Récupère la liste des timestamps stockés
  List<int> _getStoredTimestamps() {
    final list = _box.get(_timestampsKey);
    if (list == null) return [];
    return List<int>.from(list);
  }

  /// À appeler APRÈS un vote réussi
  Future<void> consume() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final timestamps = _getStoredTimestamps();
    timestamps.add(now);
    await _box.put(_timestampsKey, timestamps);
    _updateRemaining();
  }

  /// Force un rechargement (utile après un changement de compte, etc.)
  Future<void> reload() async => _updateRemaining();
}

// ─── Joueurs votables ────────────────────────────────────────────────────────
final votablePlayersProvider = FutureProvider<List<UserModel>>((ref) async {
  final currentUserId = await StorageService.getUserId();

  final all = await supabase
      .from('users')
      .select('*, groups(*)')
      .eq('is_eliminated', false)
      .order('pseudo');

  final players = (all as List).map((j) => UserModel.fromJson(j)).toList();

  final byPoints = [...players]..sort((a, b) => b.points.compareTo(a.points));
  final top3Ids = byPoints.take(3).map((p) => p.id).toSet();

  return players
      .where((u) => u.id != currentUserId && !top3Ids.contains(u.id))
      .toList();
});

// ─── Secrets aléatoires ──────────────────────────────────────────────────────
final randomSecretsProvider = FutureProvider<List<String>>((ref) async {
  final currentUserId = await StorageService.getUserId();

  final data = await supabase
      .from('users')
      .select('secret')
      .eq('is_eliminated', false)
      .neq('id', currentUserId ?? '');

  final secrets = (data as List).map((j) => j['secret'] as String).toList();

  final rng = Random();
  for (int i = secrets.length - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final tmp = secrets[i];
    secrets[i] = secrets[j];
    secrets[j] = tmp;
  }

  return secrets;
});

// ─── Indices publics ─────────────────────────────────────────────────────────

final indicesProvider = FutureProvider<List<IndiceModel>>((ref) async {
  final data = await supabase
      .from('indices')
      .select('*, user_id(id, pseudo)')
      .eq('visible', true)
      .order('created_at', ascending: false);
  return (data as List).map((j) => IndiceModel.fromJson(j)).toList();
});

// ─── Indices cachés (visible = false), triés par date ────────────────────────
// Utilisé pour afficher le badge sur l'icône et la liste dans le dialogue
final hiddenIndicesProvider = FutureProvider<List<IndiceModel>>((ref) async {
  final data = await supabase
      .from('indices')
      .select('*, user_id(pseudo)')
      .eq('visible', false)
      .order('created_at', ascending: true); // plus anciens en premier

  return (data as List).map((j) => IndiceModel.fromJson(j)).toList();
});

// ─── Vote notifier ───────────────────────────────────────────────────────────

class VoteNotifier extends StateNotifier<VoteResultState> {
  VoteNotifier() : super(const VoteResultState());

  Future<void> castVote({
    required String targetPlayerId,
    required String secretProposed,
    required VotesRemainingNotifier votesNotifier,
  }) async {
    state = const VoteResultState(isLoading: true);

    try {
      final userId = await StorageService.getUserId();
      if (userId == null) throw Exception('Utilisateur non trouvé');

      // Appel unique à la fonction SQL (toute la logique est côté base)
      final result = await supabase.rpc('process_vote', params: {
        'p_voter_id': userId,
        'p_target_player_id': targetPlayerId,
        'p_secret_proposed': secretProposed,
      });

      final correct = result['correct'] as bool? ?? false;
      final indiceGiven = result['indice_given'] as bool? ?? false;

      // Consommer un vote (si vous avez un système de votes quotidiens)
      await votesNotifier.consume();

      // Recharger le compteur de votes (car un vote vient d'être ajouté en base)
      await votesNotifier.reload();

      state = VoteResultState(
        correct: correct,
        indiceGiven: indiceGiven,
      );
    } catch (e) {
      state = VoteResultState(error: e.toString());
      rethrow;
    }
  }

  void reset() => state = const VoteResultState();
}

// Mise à jour de l'état
class VoteResultState {
  final bool isLoading;
  final bool? correct;
  final bool? indiceGiven;
  final String? error;

  const VoteResultState({
    this.isLoading = false,
    this.correct,
    this.indiceGiven,
    this.error,
  });
}

// ─── Provider ────────────────────────────────────────────────────────────────
final voteNotifierProvider =
    StateNotifierProvider.autoDispose<VoteNotifier, VoteResultState>(
  (_) => VoteNotifier(),
);
