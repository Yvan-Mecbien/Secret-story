// lib/features/auth/providers/auth_provider.dart
import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:ui';
import 'package:app/features/auth/HashService.dart';
import 'package:app/features/auth/StorageService.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:app/shared/models/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/supabase_client.dart';

// Anti brute-force et rate limiting
class RateLimiter {
  static final RateLimiter _instance = RateLimiter._internal();
  factory RateLimiter() => _instance;
  RateLimiter._internal();

  final Map<String, List<DateTime>> _attempts = HashMap();
  final int _maxAttempts = 3;
  Duration _lockDuration = Duration(minutes: 5);

  bool canAttempt(String key) {
    _cleanOldAttempts(key);
    final attempts = _attempts[key] ?? [];
    return attempts.length < _maxAttempts;
  }

  void registerAttempt(String key) {
    _cleanOldAttempts(key);
    final attempts = _attempts[key] ?? [];
    attempts.add(DateTime.now());
    _attempts[key] = attempts;
  }

  void clearAttempts(String key) {
    _attempts.remove(key);
  }

  int getRemainingAttempts(String key) {
    _cleanOldAttempts(key);
    final attempts = _attempts[key] ?? [];
    return _maxAttempts - attempts.length;
  }

  Duration? getLockTimeRemaining(String key) {
    _cleanOldAttempts(key);
    final attempts = _attempts[key] ?? [];
    if (attempts.isEmpty) return null;

    final now = DateTime.now();
    final lockUntil = attempts.first.add(_lockDuration);

    return now.isBefore(lockUntil) ? lockUntil.difference(now) : null;
  }

  void _cleanOldAttempts(String key) {
    final now = DateTime.now();
    final attempts = _attempts[key] ?? [];
    attempts.removeWhere((attempt) => now.difference(attempt) > _lockDuration);

    if (attempts.isEmpty) {
      _attempts.remove(key);
    } else {
      _attempts[key] = attempts;
    }
  }
}

final rateLimiterProvider = Provider<RateLimiter>((ref) => RateLimiter());
final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());
final hashServiceProvider = Provider<HashService>((ref) => HashService());

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authNotifier = ref.read(authNotifierProvider.notifier);
  return await authNotifier.getCurrentUser();
});

final historyProvider = FutureProvider<List<PointHistory>>((ref) async {
  final userIdAsync = ref.watch(currentUserProvider);
  String uid = '';

  userIdAsync.when(
    data: (user) async {
      if (user == null) return;
      uid = user.id;
    },
    error: (Object error, StackTrace stackTrace) {},
    loading: () {},
  );
  final data = await supabase
      .from('point_history')
      .select()
      .eq('user_id', uid)
      .order('created_at', ascending: false)
      .limit(30);
  return (data as List).map((j) => PointHistory.fromJson(j)).toList();
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  AuthNotifier(
    this._rateLimiter,
    this._storageService,
    this._hashService,
  ) : super(const AsyncValue.data(null));

  final RateLimiter _rateLimiter;
  final StorageService _storageService;
  final HashService _hashService;
  final _uuid = const Uuid();

  Future<bool> checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> register({
    required String pseudo,
    required String password,
    required String secret,
    VoidCallback? onSuccess,
    Function(String)? onError,
  }) async {
    state = const AsyncValue.loading();

    try {
      final hasInternet = await checkInternetConnection();
      if (!hasInternet) {
        const errorMessage = 'Pas de connexion internet';
        if (onError != null) onError(errorMessage);
        state = AsyncValue.error(errorMessage, StackTrace.current);
        return;
      }
      // ignore: empty_catches
    } catch (e) {}

    try {
      final key = 'register_${pseudo.toLowerCase()}';

      if (!_rateLimiter.canAttempt(key)) {
        final remaining = _rateLimiter.getLockTimeRemaining(key);
        final errorMessage =
            'Trop de tentatives. Réessayez dans ${remaining?.inMinutes} minute${remaining?.inMinutes != 1 ? 's' : ''}';
        if (onError != null) onError(errorMessage);
        throw Exception(errorMessage);
      }

      _rateLimiter.registerAttempt(key);

      // Vérifier si le pseudo existe déjà
      try {
        final existingUser = await supabase
            .from('users')
            .select('id')
            .eq('pseudo', pseudo)
            .maybeSingle()
            .timeout(const Duration(seconds: 10));

        if (existingUser != null) {
          const errorMessage = 'Ce pseudo est déjà utilisé';
          if (onError != null) onError(errorMessage);
          throw Exception(errorMessage);
        }
      } catch (e) {
        if (e is TimeoutException) {
          const errorMessage =
              'Délai d\'attente dépassé. Vérifiez votre connexion.';
          if (onError != null) onError(errorMessage);
          throw Exception(errorMessage);
        }
        rethrow;
      }

      // Récupérer les groupes
      final groups = await supabase
          .from('groups')
          .select('id, nbr_membre')
          .order('nbr_membre', ascending: true)
          .timeout(const Duration(seconds: 10));

      if (groups.isEmpty) {
        const errorMessage = 'Aucun groupe disponible';
        if (onError != null) onError(errorMessage);
        throw Exception(errorMessage);
      }

      final bestGroup = (groups as List).first;
      final bestGroupId = bestGroup['id'] as String?;

      if (bestGroupId == null) {
        const errorMessage = 'ID du groupe invalide';
        if (onError != null) onError(errorMessage);
        throw Exception(errorMessage);
      }

      // Convertir l'ID du groupe en UUID
      String groupIdToSend;
      try {
        Uuid.parse(bestGroupId);
        groupIdToSend = bestGroupId;
        // print('✅ ID groupe déjà en UUID: $groupIdToSend');
      } catch (e) {
        groupIdToSend = _uuid.v5(Uuid.NAMESPACE_URL, bestGroupId);
        // print('🔄 ID groupe converti en UUID: $groupIdToSend');
      }

      final now = DateTime.now().toIso8601String();

      // HACHER LE MOT DE PASSE AVANT ENVOI
      final hashedPassword = _hashService.hashPassword(password);

      // Appel RPC qui crée l'utilisateur ET la session
      final result = await supabase.rpc('register_user_with_session', params: {
        'p_pseudo': pseudo,
        'p_email': _generateEmail(pseudo),
        'p_password': hashedPassword, // Envoyer le mot de passe haché
        'p_secret': secret,
        'p_group_id': groupIdToSend,
        'p_created_at': now,
      }).timeout(const Duration(seconds: 10));

      _rateLimiter.clearAttempts(key);

      if (result == null) {
        throw Exception('La fonction RPC n\'a retourné aucune donnée');
      }

      print('📦 Résultat RPC: $result');

      final userData = result as Map<String, dynamic>;

      if (userData['id'] == null) {
        throw Exception('ID utilisateur manquant dans le résultat');
      }
      print(userData);
      final newUser = UserModel.fromJson(userData);

      final sessionToken = userData['session_token'] as String?;
      final sessionExpiresAt = userData['session_expires_at'] as String?;

      if (sessionToken != null) {
        // print('✅ Session créée avec token: $sessionToken');

        // Utiliser StorageService pour sauvegarder la session
        await _storageService.saveSession(
          token: sessionToken,
          userId: newUser.id,
          expiresAt: sessionExpiresAt ??
              DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        );
      }

      print('✅ Utilisateur créé avec ID: ${newUser.id}');

      state = AsyncValue.data(newUser);

      if (onSuccess != null) {
        onSuccess();
      }
    } catch (e, st) {
      //  print('❌ Erreur: $e*');
      String errorMessage = 'Une erreur est survenue';

      if (e is TimeoutException) {
        errorMessage = 'Délai d\'attente dépassé. Vérifiez votre connexion.';
      } else if (e is PostgrestException) {
        errorMessage = e.message ?? 'Erreur de base de données';
      } else if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }

      state = AsyncValue.error(errorMessage, st);

      if (onError != null) {
        onError(errorMessage);
      }
    }
  }

  Future<void> login({
    required String pseudo,
    required String password,
    VoidCallback? onSuccess,
    Function(String)? onError,
  }) async {
    state = const AsyncValue.loading();
    try {
      final key = 'login_${pseudo.toLowerCase()}';

      if (!_rateLimiter.canAttempt(key)) {
        final remaining = _rateLimiter.getLockTimeRemaining(key);
        final errorMessage =
            'Trop de tentatives. Réessayez dans ${remaining?.inMinutes} minute${remaining?.inMinutes != 1 ? 's' : ''}';
        if (onError != null) {
          onError(errorMessage);
        }
        throw Exception(errorMessage);
      }

      _rateLimiter.registerAttempt(key);

      // Rechercher l'utilisateur
      final user = await supabase
          .from('users')
          .select('*, groups(*)')
          .eq('pseudo', pseudo)
          .maybeSingle();

      if (user == null) {
        const errorMessage = 'Pseudo ou mot de passe incorrect';
        if (onError != null) {
          onError(errorMessage);
        }
        throw Exception(errorMessage);
      }

      // HACHER LE MOT DE PASSE SAISI ET LE COMPARER
      final hashedInputPassword = _hashService.hashPassword(password);
      print('🔐 Mot de passe saisi haché: $hashedInputPassword');
      print('🔐 Mot de passe stocké: ${user['password']}');

      if (user['password'] != hashedInputPassword) {
        const errorMessage = 'Pseudo ou mot de passe incorrect';
        if (onError != null) {
          onError(errorMessage);
        }
        throw Exception(errorMessage);
      }

      // Créer une session
      await _createSession(user['id']);

      _rateLimiter.clearAttempts(key);
      state = AsyncValue.data(UserModel.fromJson(user));

      if (onSuccess != null) {
        onSuccess();
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      if (onError != null && e is Exception) {
        onError(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      await _deleteCurrentSession();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      // Vérifier la session locale
      if (!_storageService.isSessionValid()) {
        await _storageService.clearSession();
        return null;
      }

      final token = _storageService.getSessionToken();
      final userId = _storageService.getUserId2();

      if (token == null || userId == null) {
        return null;
      }

      // Vérifier la session dans Supabase
      final session = await supabase
          .from('sessions')
          .select()
          .eq('token', token)
          .maybeSingle();

      if (session == null) {
        await _storageService.clearSession();
        return null;
      }

      // Vérifier l'expiration
      final expiresAt = DateTime.parse(session['expires_at']);
      if (DateTime.now().isAfter(expiresAt)) {
        await supabase.from('sessions').delete().eq('token', token);
        await _storageService.clearSession();
        return null;
      }

      // Récupérer l'utilisateur avec son groupe
      final user = await supabase
          .from('users')
          .select('*, groups(*)')
          .eq('id', userId)
          .maybeSingle();

      if (user == null) {
        await _storageService.clearSession();
        return null;
      }

      return UserModel.fromJson(user);
    } catch (e) {
      print('Erreur lors de la récupération de l\'utilisateur: $e');
      return null;
    }
  }

  // Méthodes privées utilitaires
  String _generateEmail(String pseudo) {
    final cleanPseudo =
        pseudo.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    return '$cleanPseudo@secretstory.game';
  }

  String _generateSessionToken() {
    final random = Random.secure();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'sess_${timestamp}_${random.nextInt(1000000)}';
  }

  Future<UserModel?> _getUserById(String userId) async {
    final data = await supabase
        .from('users')
        .select('*, groups(*)')
        .eq('id', userId)
        .maybeSingle();

    return data != null ? UserModel.fromJson(data) : null;
  }

  Future<void> _createSession(String userId) async {
    final now = DateTime.now();
    final token = _generateSessionToken();
    final expiresAt = now.add(const Duration(days: 7));

    await supabase.from('sessions').insert({
      'user_id': userId,
      'token': token,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });

    // Utiliser StorageService
    await _storageService.saveSession(
      token: token,
      userId: userId,
      expiresAt: expiresAt.toIso8601String(),
    );
  }

  Future<void> _deleteCurrentSession() async {
    final token = _storageService.getSessionToken();

    if (token != null) {
      try {
        await supabase.from('sessions').delete().eq('token', token);
      } catch (e) {
        print('Erreur lors de la suppression de la session: $e');
      }
      await _storageService.clearSession();
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>(
  (ref) => AuthNotifier(
    ref.read(rateLimiterProvider),
    ref.read(storageServiceProvider),
    ref.read(hashServiceProvider),
  ),
);
