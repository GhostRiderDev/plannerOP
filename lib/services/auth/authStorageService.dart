import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthStorageService {
  static final AuthStorageService _instance = AuthStorageService._internal();
  factory AuthStorageService() => _instance;

  // Obtener hash key desde las variables de entorno
  final String _hashKey = dotenv.get('HASH_KEY', fallback: 'default_hash_key');

  // Instancia de almacenamiento seguro
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Clave de encriptación
  late final encrypt.Key _encryptionKey;
  late final encrypt.IV _iv;

  AuthStorageService._internal() {
    _encryptionKey = encrypt.Key.fromUtf8(_hashKey);
    _iv = encrypt.IV.fromLength(16);
  }

  // Claves de almacenamiento
  static const String _tokenKey = 'auth_token';
  static const String _usernameKey = 'username';
  static const String _passwordKey = 'password';
  static const String _lastLoginKey = 'last_login';

  // Método para encriptar texto
  String _encrypt(String plainText) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
    return encrypter.encrypt(plainText, iv: _iv).base64;
  }

  // Método para desencriptar texto
  String _decrypt(String encryptedText) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
    return encrypter.decrypt64(encryptedText, iv: _iv);
  }

  // Guardar credenciales en almacenamiento seguro
  Future<void> saveCredentials({
    required String token,
    required String username,
    required String password,
  }) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    await _secureStorage.write(key: _usernameKey, value: _encrypt(username));
    await _secureStorage.write(key: _passwordKey, value: _encrypt(password));
    await _secureStorage.write(
        key: _lastLoginKey, value: DateTime.now().toIso8601String());
  }

  // Obtener token almacenado
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  // Obtener nombre de usuario almacenado
  Future<String?> getUsername() async {
    final encryptedUsername = await _secureStorage.read(key: _usernameKey);
    if (encryptedUsername == null) return null;
    return _decrypt(encryptedUsername);
  }

  // Obtener contraseña almacenada
  Future<String?> getPassword() async {
    final encryptedPassword = await _secureStorage.read(key: _passwordKey);
    if (encryptedPassword == null) return null;
    return _decrypt(encryptedPassword);
  }

  // Verificar si el token es válido y no ha expirado
  Future<bool> isTokenValid() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;

    try {
      // Verificar si el token está expirado
      if (JwtDecoder.isExpired(token)) {
        return false;
      }

      // Verificar si el token tiene más de un día
      final lastLogin = await _secureStorage.read(key: _lastLoginKey);
      if (lastLogin != null) {
        final loginDate = DateTime.parse(lastLogin);
        final now = DateTime.now();
        // Configurar por cuánto tiempo queremos que sea válida la sesión (1 día)
        if (now.difference(loginDate).inDays >= 1) {
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error validando token: $e');
      return false;
    }
  }

  // Borrar credenciales almacenadas
  Future<void> clearCredentials() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _usernameKey);
    await _secureStorage.delete(key: _passwordKey);
    await _secureStorage.delete(key: _lastLoginKey);
  }

  // Verificar si hay credenciales almacenadas
  Future<bool> hasCredentials() async {
    final username = await getUsername();
    final password = await getPassword();
    return username != null && password != null;
  }
}
