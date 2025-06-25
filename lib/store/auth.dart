import 'package:flutter/material.dart';
import 'package:plannerop/services/auth/authStorageService.dart';
import 'package:plannerop/services/auth/signin.dart';
import 'package:plannerop/store/areas.dart';
import 'package:plannerop/store/chargersOp.dart';
import 'package:plannerop/store/clients.dart';
import 'package:plannerop/store/faults.dart';
import 'package:plannerop/store/feedings.dart';
import 'package:plannerop/store/operations.dart';
import 'package:plannerop/store/programmings.dart';
import 'package:plannerop/store/task.dart';
import 'package:plannerop/store/user.dart';
import 'package:plannerop/store/workers.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // ✅ REFERENCIAS A LOS PROVIDERS REALES, NO NUEVAS INSTANCIAS
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

  // ✅ CONSTRUCTOR QUE RECIBE LAS INSTANCIAS REALES
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

  // Cerrar sesión y limpiar datos almacenados
  Future<void> logout() async {
    debugPrint("🧹 [AuthProvider] Iniciando logout...");
    try {
      // Limpieza de credenciales
      await _authStorage.clearCredentials();
      _accessToken = '';
      _isAuthenticated = false;

      // ✅ VERIFICAR ANTES DE LIMPIAR
      debugPrint("🔍 [AuthProvider] Estado antes de limpiar providers:");
      debugPrint("Operations count: ${_operationsProvider.operations.length}");

      // ✅ LIMPIAR OPERATIONS PROVIDER CON VERIFICACIÓN
      _operationsProvider.clear();

      // ✅ VERIFICAR DESPUÉS DE LIMPIAR
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

      debugPrint("✅ [AuthProvider] Logout completado");
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [AuthProvider] Error en logout: $e');
    }
  }

  // Intentar iniciar sesión automáticamente al iniciar la app
  Future<bool> tryAutoLogin(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Verificar si hay un token válido primero
      if (await _authStorage.isTokenValid()) {
        final token = await _authStorage.getToken();
        if (token != null) {
          _accessToken = token;
          _isAuthenticated = true;
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      // Si no hay token válido pero hay credenciales guardadas, intentar login automático
      final username = await _authStorage.getUsername();
      final password = await _authStorage.getPassword();

      if (username != null && password != null) {
        final response =
            await _signinService.signin(username, password, context);

        if (response.isSuccess) {
          _accessToken = response.accessToken;
          _isAuthenticated = true;

          // Actualizar el token y la fecha de último login
          await _authStorage.saveCredentials(
            token: response.accessToken,
            username: username,
            password: password,
          );

          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Error en auto-login: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
