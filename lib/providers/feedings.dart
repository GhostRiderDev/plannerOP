import 'package:flutter/material.dart';
import 'package:plannerop/services/feedings/feedings.dart';
import 'package:plannerop/utils/toast.dart';

class FeedingProvider extends ChangeNotifier {
  // Mapa de alimentación {operationId: {workerId: {type: bool}}}
  Map<int, Map<int, Map<String, FeedingRecord>>> _feedingStatus = {};

  bool _isLoading = false;
  final Set<int> _loadedOperations = {};
  final Map<int, DateTime> _lastLoadedTime = {};
  final Duration _cacheValidDuration = const Duration(minutes: 5);

  // Getters
  Map<int, Map<int, Map<String, bool>>> get feedingStatus {
    // Convertir a formato booleano para compatibilidad
    Map<int, Map<int, Map<String, bool>>> result = {};
    _feedingStatus.forEach((operationId, workers) {
      result[operationId] = {};
      workers.forEach((workerId, foods) {
        result[operationId]![workerId] = {};
        foods.forEach((foodType, record) {
          result[operationId]![workerId]![foodType] = record.isDelivered;
        });
      });
    });
    return result;
  }

  bool get isLoading => _isLoading;

  final FeedingService _feedingService = FeedingService();

  // Convertir tipo de comida al formato de la API
  String _getFeedingTypeForApi(String foodType) {
    switch (foodType) {
      case 'Desayuno':
        return 'BREAKFAST';
      case 'Almuerzo':
        return 'LUNCH';
      case 'Cena':
        return 'DINNER';
      case 'Media noche':
        return 'SNACK';
      default:
        return 'BREAKFAST';
    }
  }

  // Convertir tipo de API a formato de UI
  String _getFeedingTypeFromApi(String apiType) {
    switch (apiType) {
      case 'BREAKFAST':
        return 'Desayuno';
      case 'LUNCH':
        return 'Almuerzo';
      case 'DINNER':
        return 'Cena';
      case 'SNACK':
        return 'Media noche';
      default:
        return 'Desayuno';
    }
  }

  // Verificar si la alimentación está marcada
  bool isMarked(int operationId, int workerId, String foodType) {
    return _feedingStatus[operationId]?[workerId]?[foodType]?.isDelivered ??
        false;
  }

  int? getFeedingRecordId(int operationId, int workerId, String foodType) {
    return _feedingStatus[operationId]?[workerId]?[foodType]?.id;
  }

  // En el método markFeeding en FeedingProvider, añadir una notificación específica
  Future<bool> markFeeding({
    required int operationId,
    required int workerId,
    required String foodType,
    required BuildContext context,
  }) async {
    // Si ya está marcada, no hacer nada
    if (isMarked(operationId, workerId, foodType)) {
      return true;
    }

    _isLoading = true;
    notifyListeners();

    bool success = false;
    int? newFeedingId;

    try {
      String apiType = _getFeedingTypeForApi(foodType);

      // Marcar como entregada y obtener el ID
      final result = await _feedingService.markFeeding(
        workerId: workerId,
        operationId: operationId,
        type: apiType,
        context: context,
      );

      success = result['success'] ?? false;
      newFeedingId = result['id'];

      if (success && newFeedingId != null) {
        // Inicializar estructura de datos si es necesario
        _feedingStatus[operationId] ??= {};
        _feedingStatus[operationId]![workerId] ??= {};

        // ✅ ALMACENAR REGISTRO COMPLETO CON ID
        _feedingStatus[operationId]![workerId]![foodType] = FeedingRecord(
          id: newFeedingId,
          isDelivered: true,
          deliveryDate: DateTime.now(),
        );

        showSuccessToast(context, "$foodType entregado");
        notifyListeners();
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      showErrorToast(context, "Error al registrar alimentación: $e");
      return false;
    }
  }

  //  MODIFICAR unmarkFeeding para usar el ID
  Future<bool> unmarkFeeding({
    required int operationId,
    required int workerId,
    required String foodType,
    required BuildContext context,
  }) async {
    // Si no está marcada, no hacer nada
    if (!isMarked(operationId, workerId, foodType)) {
      return true;
    }

    //  OBTENER EL ID DEL REGISTRO
    final feedingId = getFeedingRecordId(operationId, workerId, foodType);
    if (feedingId == null) {
      showErrorToast(context, "No se encontró el registro de alimentación");
      return false;
    }

    _isLoading = true;
    notifyListeners();

    bool success = false;

    try {
      //  USAR EL ID ESPECÍFICO PARA ELIMINAR
      success = await _feedingService.unmarkFeedingById(
        feedingId: feedingId,
        context: context,
      );

      if (success) {
        // Actualizar el estado local
        if (_feedingStatus[operationId] != null &&
            _feedingStatus[operationId]![workerId] != null) {
          _feedingStatus[operationId]![workerId]![foodType] = FeedingRecord(
            id: feedingId,
            isDelivered: false,
            deliveryDate: null,
          );
        }

        showSuccessToast(context, "$foodType desmarcado");
        notifyListeners();
      }

      _isLoading = false;
      notifyListeners();

      return success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      showErrorToast(context, "Error al desmarcar alimentación: $e");
      return false;
    }
  }

  bool areAllWorkersMarked(
      int operationId, List<int> workerIds, String foodType) {
    if (_feedingStatus[operationId] == null) {
      return false;
    }

    for (var workerId in workerIds) {
      if (!isMarked(operationId, workerId, foodType)) {
        return false;
      }
    }

    return true;
  }

  Future<void> loadFeedingStatusForOperation(
      int operationId, BuildContext context) async {
    //  VERIFICAR CACHE MÁS ESTRICTO
    if (_loadedOperations.contains(operationId)) {
      final lastLoaded = _lastLoadedTime[operationId];
      if (lastLoaded != null &&
          DateTime.now().difference(lastLoaded) < _cacheValidDuration) {
        return; // Usar datos en cache SIN notificar cambios
      }
    }

    //  EVITAR NOTIFICACIONES DURANTE LA CONSTRUCCIÓN
    bool wasLoading = _isLoading;
    bool hadData = _feedingStatus.containsKey(operationId);

    // Solo marcar como loading si no estaba cargando y no hay datos
    if (!wasLoading && !hadData) {
      _isLoading = true;
      //  USAR SCHEDULEMICROTASK PARA EVITAR NOTIFICAR DURANTE BUILD
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          notifyListeners();
        }
      });
    }

    try {
      final feedingService = FeedingService();
      final List<dynamic> feedingData =
          await feedingService.getFeedingsForOperation(operationId, context);

      // Inicializar la estructura de datos para esta operación
      _feedingStatus[operationId] = {};

      //  PROCESAR DATOS INCLUYENDO LOS IDs
      for (var feeding in feedingData) {
        int workerId = feeding['id_worker'];
        String type = feeding['type'];
        String foodType = _getFeedingTypeFromApi(type);
        int feedingId = feeding['id']; //  OBTENER EL ID
        String? dateFeeding = feeding['dateFeeding'];

        _feedingStatus[operationId]![workerId] ??= {};
        _feedingStatus[operationId]![workerId]![foodType] = FeedingRecord(
          id: feedingId,
          isDelivered: true,
          deliveryDate:
              dateFeeding != null ? DateTime.tryParse(dateFeeding) : null,
        );
      }

      // Marcar como cargado con timestamp
      _loadedOperations.add(operationId);
      _lastLoadedTime[operationId] = DateTime.now();

      // Notificar cambios
      if (!wasLoading && !hadData) {
        _isLoading = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            notifyListeners();
          }
        });
      }
    } catch (e) {
      debugPrint('Error cargando alimentación: $e');
      if (!wasLoading && !hadData) {
        _isLoading = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            notifyListeners();
          }
        });
      }
    }
  }

  //  AGREGAR GETTER PARA VERIFICAR SI EL PROVIDER ESTÁ MONTADO
  bool get mounted => hasListeners;

  //  MÉTODO PARA VERIFICAR SI HAY DATOS CARGADOS
  bool hasFeedingDataForOperation(int operationId) {
    return _feedingStatus.containsKey(operationId) &&
        _loadedOperations.contains(operationId);
  }

  // Método para forzar recarga si es necesario
  Future<void> forceLoadFeedingStatusForOperation(
      int operationId, BuildContext context) async {
    _loadedOperations.remove(operationId);
    _lastLoadedTime.remove(operationId);
    await loadFeedingStatusForOperation(operationId, context);
  }

  // Limpiar cache cuando sea necesario
  void clearCache() {
    _loadedOperations.clear();
    _lastLoadedTime.clear();
  }

  // Limpiar datos
  void clear() {
    _feedingStatus = {};
    notifyListeners();
  }
}

class FeedingRecord {
  final int id;
  final bool isDelivered;
  final DateTime? deliveryDate;

  FeedingRecord({
    required this.id,
    required this.isDelivered,
    this.deliveryDate,
  });
}
