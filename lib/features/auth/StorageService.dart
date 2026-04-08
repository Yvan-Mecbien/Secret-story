// lib/shared/services/storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _sessionTokenKey = 'session_token';
  static const String _userIdKey = 'user_id';
  static const String _sessionExpiresKey = 'session_expires';

  late SharedPreferences _prefs;

  // Initialiser le service
  static Future<StorageService> init() async {
    final instance = StorageService();
    instance._prefs = await SharedPreferences.getInstance();
    return instance;
  }

  /// Clé SharedPreferences — true si l'onboarding a déjà été vu
  static const _kOnboardingSeen = 'onboarding_seen';

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardingSeen) ?? false;
  }

  Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingSeen, true);
  }

  // Sauvegarder la session
  Future<void> saveSession({
    required String token,
    required String userId,
    required String expiresAt,
  }) async {
    await _prefs.setString(_sessionTokenKey, token);
    await _prefs.setString(_userIdKey, userId);
    await _prefs.setString(_sessionExpiresKey, expiresAt);
  }

  // Récupérer le token de session
  String? getSessionToken() {
    return _prefs.getString(_sessionTokenKey);
  }

  // Récupérer l'ID utilisateur
  String? getUserId2() {
    return _prefs.getString(_userIdKey);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // Récupérer la date d'expiration
  String? getSessionExpires() {
    return _prefs.getString(_sessionExpiresKey);
  }

  // Vérifier si la session est valide
  bool isSessionValid() {
    final expiresAt = getSessionExpires();
    if (expiresAt == null) return false;

    try {
      final expiryDate = DateTime.parse(expiresAt);
      return DateTime.now().isBefore(expiryDate);
    } catch (e) {
      return false;
    }
  }

  // Supprimer la session
  Future<void> clearSession() async {
    await _prefs.remove(_sessionTokenKey);
    await _prefs.remove(_userIdKey);
    await _prefs.remove(_sessionExpiresKey);
  }

  // Vérifier si l'utilisateur est connecté
  bool isLoggedIn() {
    return getSessionToken() != null && isSessionValid();
  }
}
