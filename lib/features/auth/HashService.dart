// lib/shared/services/hash_service.dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class HashService {
  static final HashService _instance = HashService._internal();
  factory HashService() => _instance;
  HashService._internal();

  // Hacher un mot de passe avec SHA-256
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Hacher avec un sel (plus sécurisé)
  String hashPasswordWithSalt(String password, String salt) {
    final saltedPassword = '$password$salt';
    final bytes = utf8.encode(saltedPassword);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Générer un sel aléatoire
  String generateSalt() {
    final random = Random.secure();
    final saltBytes = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      saltBytes[i] = random.nextInt(256);
    }
    return base64.encode(saltBytes);
  }

  // Vérifier un mot de passe
  bool verifyPassword(String password, String hashedPassword, String salt) {
    final hashedInput = hashPasswordWithSalt(password, salt);
    return hashedInput == hashedPassword;
  }
}
