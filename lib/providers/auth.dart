import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:plannerop/services/auth/authStorageService.dart';
import 'package:plannerop/services/auth/signin.dart';
import 'package:plannerop/providers/areas.dart';
import 'package:plannerop/providers/chargersOp.dart';
import 'package:plannerop/providers/clients.dart';
import 'package:plannerop/providers/faults.dart';
import 'package:plannerop/providers/feedings.dart';
import 'package:plannerop/providers/operations.dart';
import 'package:plannerop/providers/programmings.dart';
import 'package:plannerop/providers/task.dart';
import 'package:plannerop/providers/user.dart';
import 'package:plannerop/providers/workers.dart';
import 'package:http/http.dart' as http;

class AuthProvider extends ChangeNotifier {
  String _accessToken = '';
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  String get accessToken => _accessToken;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  final AuthStorageService _authStorage = AuthStorageService();
  final SigninService _signinService = SigninService();

  final String API_URL = dotenv.get('API_URL');

  //  REFERENCIAS A LOS PROVIDERS REALES, NO NUEVAS INSTANCIAS
  late final OperationsProvider _operationsProvider;
  late final WorkersProvider _workersProvider;
  late final AreasProvider _areasProvider;
  late final ClientsProvider _clientsProvider;
  late final FeedingProvider _feedingProvider;
  late final FaultsProvider _faultsProvider;
  late final ProgrammingsProvider _programmingsProvider;
  late final TasksProvider _tasksProvider;
  late final UserProvider _userProvider;
  late final ChargersOpProvider _chargersOpProvider;

  //  CONSTRUCTOR QUE RECIBE LAS INSTANCIAS REALES
  AuthProvider({
    required OperationsProvider operationsProvider,
    required WorkersProvider workersProvider,
    required AreasProvider areasProvider,
    required ClientsProvider clientsProvider,
    required FeedingProvider feedingProvider,
    required FaultsProvider faultsProvider,
    required ProgrammingsProvider programmingsProvider,
    required TasksProvider tasksProvider,
    required UserProvider userProvider,
    required ChargersOpProvider chargersOpProvider,
  }) {
    _operationsProvider = operationsProvider;
    _workersProvider = workersProvider;
    _areasProvider = areasProvider;
    _clientsProvider = clientsProvider;
    _feedingProvider = feedingProvider;
    _faultsProvider = faultsProvider;
    _programmingsProvider = programmingsProvider;
    _tasksProvider = tasksProvider;
    _userProvider = userProvider;
    _chargersOpProvider = chargersOpProvider;
  }

  void setAccessToken(String token) {
    _accessToken = token;
    _isAuthenticated = token.isNotEmpty;
    notifyListeners();
  }

  void clearAccessToken() {
    _accessToken = '';
    _isAuthenticated = false;
    notifyListeners();
  }

  // Método para iniciar sesión y guardar credenciales
  Future<bool> login(
      String username, String password, BuildContext context) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _signinService.signin(username, password, context);

      if (response.isSuccess) {
        _accessToken = response.accessToken;
        _isAuthenticated = true;

        // Guardar credenciales encriptadas
        await _authStorage.saveCredentials(
          token: response.accessToken,
          username: username,
          password: password,
        );

        notifyListeners();
        return true;
      } else {
        _error = 'Credenciales inválidas';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> clearProvidersData() async {
    try {
      _operationsProvider.clear();
      _areasProvider.clear();
      _chargersOpProvider.clear();
      _clientsProvider.clear();
      _feedingProvider.clear();
      _workersProvider.clear();
      _faultsProvider.clear();
      _programmingsProvider.clear();
      _tasksProvider.clear();

      // NO limpiar userProvider aquí para cambio de sede
      // _userProvider.clear(); // Comentar esta línea

      notifyListeners();
    } catch (e) {
      debugPrint('❌ [AuthProvider] Error limpiando providers: $e');
    }
  }

  // Cerrar sesión y limpiar datos almacenados
  Future<void> logout() async {
    try {
      // Limpieza de credenciales
      await _authStorage.clearCredentials();
      _accessToken = '';
      _isAuthenticated = false;

      //  VERIFICAR ANTES DE LIMPIAR
      debugPrint("🔍 [AuthProvider] Estado antes de limpiar providers:");
      debugPrint("Operations count: ${_operationsProvider.operations.length}");

      //  LIMPIAR OPERATIONS PROVIDER CON VERIFICACIÓN
      _operationsProvider.clear();

      //  VERIFICAR DESPUÉS DE LIMPIAR
      debugPrint(
          "🔍 [AuthProvider] Estado después de limpiar OperationsProvider:");
      debugPrint("Operations count: ${_operationsProvider.operations.length}");
      debugPrint(
          "InProgress count: ${_operationsProvider.inProgressOperations.length}");

      // Limpiar otros providers
      _areasProvider.clear();
      _chargersOpProvider.clear();
      _clientsProvider.clear();
      _feedingProvider.clear();
      _workersProvider.clear();
      _faultsProvider.clear();
      _programmingsProvider.clear();
      _tasksProvider.clear();
      _userProvider.clear();

      debugPrint(" [AuthProvider] Logout completado");
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [AuthProvider] Error en logout: $e');
    }
  }

  // Intentar iniciar sesión automáticamente al iniciar la app
  Future<bool> tryAutoLogin(BuildContext context) async {
    debugPrint('🔑 [AuthProvider] Intentando auto-login');

    try {
      // ✅ USAR MÉTODO SEGURO
      final credentials = await _authStorage.getSafeCredentials();
      final username = credentials['username'];
      final password = credentials['password'];

      if (username == null || password == null) {
        debugPrint('🚫 [AuthProvider] No hay credenciales válidas almacenadas');
        return false;
      }

      debugPrint(
          '✅ [AuthProvider] Credenciales válidas encontradas, intentando login');
      return await login(username, password, context);
    } catch (e) {
      debugPrint('❌ [AuthProvider] Error en tryAutoLogin: $e');
      return false;
    }
  }

  Future<bool> refreshToken(
      int siteId, int? subsiteId, BuildContext context) async {
    try {
      final String token = _accessToken;

      final Map<String, dynamic> requestBody = {
        "id_site": siteId,
      };

      // Solo incluir subsite si está seleccionado
      if (subsiteId != null) {
        requestBody["id_subsite"] = subsiteId;
      }

      final url = Uri.parse('$API_URL/login/refresh');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final newToken = jsonResponse['access_token'];

        // AQUÍ ESTABA EL ERROR: No se actualizaba el token
        _accessToken = newToken;

        // Actualizar el token en el storage
        await _authStorage.saveCredentials(
          token: newToken,
          username: await _authStorage.getUsername() ?? '',
          password: await _authStorage.getPassword() ?? '',
        );

        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
