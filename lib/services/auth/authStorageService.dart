// En lib/services/auth/authStorageService.dart - REEMPLAZAR todo el archivo
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

  //  BANDERA PARA EVITAR BUCLES RECURSIVOS
  bool _isClearing = false;

  AuthStorageService._internal() {
    try {
      _encryptionKey = encrypt.Key.fromUtf8(_hashKey);

      //  USAR UN IV FIJO BASADO EN LA HASH_KEY PARA CONSISTENCIA
      final ivString = _hashKey.length >= 16
          ? _hashKey.substring(0, 16)
          : _hashKey.padRight(16, '0');
      _iv = encrypt.IV.fromUtf8(ivString);
    } catch (e) {
      debugPrint('Error inicializando clave de encriptación: $e');
    }
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

  //  MÉTODO PARA DESENCRIPTAR TEXTO SIN BUCLES RECURSIVOS
  String _decrypt(String encryptedText) {
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
      return encrypter.decrypt64(encryptedText, iv: _iv);
    } catch (e) {
      debugPrint(' Error al desencriptar: $e');
      //  NO LLAMAR clearCredentials() AQUÍ para evitar bucle recursivo
      throw Exception('Error de desencriptación: $e');
    }
  }

  // Guardar credenciales en almacenamiento seguro
  Future<void> saveCredentials({
    required String token,
    required String username,
    required String password,
  }) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
      await _secureStorage.write(key: _usernameKey, value: _encrypt(username));
      await _secureStorage.write(key: _passwordKey, value: _encrypt(password));
      await _secureStorage.write(
          key: _lastLoginKey, value: DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint(' Error guardando credenciales: $e');
      throw e;
    }
  }

  // Obtener token almacenado
  Future<String?> getToken() async {
    try {
      return await _secureStorage.read(key: _tokenKey);
    } catch (e) {
      debugPrint(' Error obteniendo token: $e');
      return null;
    }
  }

  //  OBTENER NOMBRE DE USUARIO CON MANEJO SEGURO DE ERRORES
  Future<String?> getUsername() async {
    if (_isClearing) return null;

    try {
      final encryptedUsername = await _secureStorage.read(key: _usernameKey);
      if (encryptedUsername == null || encryptedUsername.isEmpty) return null;

      return _decrypt(encryptedUsername);
    } catch (e) {
      debugPrint(' Error obteniendo username: $e');
      //  MARCAR PARA LIMPIEZA SIN LLAMAR clearCredentials() INMEDIATAMENTE
      _scheduleCredentialsClear();
      return null;
    }
  }

  //  OBTENER CONTRASEÑA CON MANEJO SEGURO DE ERRORES
  Future<String?> getPassword() async {
    if (_isClearing) return null;

    try {
      final encryptedPassword = await _secureStorage.read(key: _passwordKey);
      if (encryptedPassword == null || encryptedPassword.isEmpty) return null;

      return _decrypt(encryptedPassword);
    } catch (e) {
      debugPrint(' Error obteniendo password: $e');
      //  MARCAR PARA LIMPIEZA SIN LLAMAR clearCredentials() INMEDIATAMENTE
      _scheduleCredentialsClear();
      return null;
    }
  }

  //  MÉTODO PARA PROGRAMAR LIMPIEZA DE CREDENCIALES SIN BUCLES
  void _scheduleCredentialsClear() {
    if (!_isClearing) {
      Future.microtask(() async {
        await clearCredentials();
      });
    }
  }

  //  MÉTODO SEGURO PARA OBTENER CREDENCIALES
  Future<Map<String, String?>> getSafeCredentials() async {
    try {
      final username = await getUsername();
      final password = await getPassword();
      final token = await getToken();

      if (username == null ||
          password == null ||
          username.isEmpty ||
          password.isEmpty) {
        debugPrint('Credenciales incompletas o corruptas');
        return {'username': null, 'password': null, 'token': null};
      }

      return {'username': username, 'password': password, 'token': token};
    } catch (e) {
      debugPrint(' Error obteniendo credenciales seguras: $e');
      return {'username': null, 'password': null, 'token': null};
    }
  }

  // Verificar si el token es válido y no ha expirado
  Future<bool> isTokenValid() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return false;

      // Verificar si el token está expirado
      if (JwtDecoder.isExpired(token)) {
        return false;
      }

      // Verificar si el token tiene más de un día
      final lastLogin = await _secureStorage.read(key: _lastLoginKey);
      if (lastLogin != null) {
        final loginDate = DateTime.parse(lastLogin);
        final now = DateTime.now();
        if (now.difference(loginDate).inDays >= 1) {
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint(' Error validando token: $e');
      return false;
    }
  }

  //  BORRAR CREDENCIALES CON PROTECCIÓN CONTRA BUCLES
  Future<void> clearCredentials() async {
    if (_isClearing) return;

    _isClearing = true;

    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _usernameKey);
      await _secureStorage.delete(key: _passwordKey);
      await _secureStorage.delete(key: _lastLoginKey);
      debugPrint(' Credenciales limpiadas correctamente');
    } catch (e) {
      debugPrint(' Error limpiando credenciales: $e');
    } finally {
      _isClearing = false;
    }
  }

  //  VERIFICAR CREDENCIALES SIN CAUSAR BUCLES
  Future<bool> hasCredentials() async {
    try {
      final credentials = await getSafeCredentials();
      final hasValid =
          credentials['username'] != null && credentials['password'] != null;
      return hasValid;
    } catch (e) {
      debugPrint(' Error verificando credenciales: $e');
      return false;
    }
  }
}
