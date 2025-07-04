import 'package:flutter/material.dart';
import 'package:plannerop/core/model/fault.dart';
import 'package:plannerop/core/model/incapacity.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/services/faults/fault.dart';
import 'package:plannerop/services/workers/workers.dart';
import 'package:plannerop/dto/workers/fetchWorkers.dart';
import 'package:plannerop/store/faults.dart';
import 'package:plannerop/store/incapacities.dart';
import 'package:provider/provider.dart';

class WorkersProvider with ChangeNotifier {
  // Lista de trabajadores
  final List<Worker> _workers = [];

  // Estado de carga
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _hasLoadedInitialData =
      false; // Flag para controlar si ya se cargaron datos

  // Servicio de trabajadores
  final WorkerService _workerService = WorkerService();
  final FaultService _faultService = FaultService();

  // Getters
  List<Worker> get workers => [..._workers];
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;

  bool get hasLoadedInitialData => _hasLoadedInitialData;

  List<Worker> getFilteredWorkers(String searchQuery) {
    if (searchQuery.isEmpty) {
      return [..._workers];
    }
    return _workers
        .where((worker) =>
            worker.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  int get totalWorkerWithoutRetired =>
      _workers.where((w) => w.status != WorkerStatus.deactivated).length;

  List<Worker> get workersWithoutRetiredAndDisabled => _workers
      .where((w) =>
          w.status != WorkerStatus.deactivated &&
          w.status != WorkerStatus.incapacitated)
      .toList();

  int get totalWorkers => _workers.length;

  List<Worker> getWorkersAvailable() {
    return _workers.where((w) => w.status == WorkerStatus.available).toList();
  }

  int get assignedWorkers =>
      _workers.where((w) => w.status == WorkerStatus.assigned).length;

  int get disabledWorkers =>
      _workers.where((w) => w.status == WorkerStatus.incapacitated).length;

  int get retiredWorkers =>
      _workers.where((w) => w.status == WorkerStatus.deactivated).length;

  int get availableWorkers =>
      _workers.where((w) => w.status == WorkerStatus.available).length;

  Worker getWorkerById(int id) {
    return _workers.firstWhere((w) => w.id == id,
        orElse: () => Worker(
              id: 0,
              name: '',
              area: '',
              phone: '',
              document: '',
              status: WorkerStatus.available,
              startDate: DateTime.now(),
              code: '',
              failures: 0,
              idArea: 0,
            ));
  }

  // Método modificado para cargar trabajadores solo la primera vez
  Future<void> fetchWorkersIfNeeded(BuildContext context) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      // debugPrint('Cargando trabajadores desde API (primera vez)...');
      final FetchWorkersDto result = await _workerService.fetchWorkers(context);

      if (result.isSuccess && result.workers.isNotEmpty) {
        _workers.clear();
        _workers.addAll(result.workers);
        // debugPrint(
        //     'Datos iniciales cargados correctamente: ${_workers.length} trabajadores');
      } else {
        _hasError = true;
        _errorMessage =
            'No se encontraron trabajadores o hubo un error en la API';
        debugPrint('Error o lista vacía en carga de trabajadores');
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Error de conexión: ${e.toString()}';
      debugPrint('Excepción en fetchWorkers: $e');
    } finally {
      _isLoading = false;
      _hasLoadedInitialData = true; // Marcar que ya se intentó cargar datos
      notifyListeners();
    }
  }

  // Métodos para manipular los trabajadores
  Future<Map<String, dynamic>> addWorker(
      Worker worker, BuildContext context) async {
    try {
      // Llamar al servicio y esperar respuesta
      final result = await _workerService.registerWorker(worker, context);

      // Si fue exitoso, agregar a la lista local
      if (result['success']) {
        _workers.add(worker);
        notifyListeners();
      }

      // Devolver el resultado para que la UI pueda mostrar mensajes apropiados
      return result;
    } catch (e) {
      debugPrint('Error en addWorker: $e');
      return {'success': false, 'message': 'Error al agregar trabajador: $e'};
    }
  }

  List<Worker> fetchWorkersByStatus(WorkerStatus status) {
    return _workers.where((w) => w.status == status).toList();
  }

  // Método  para actualizar un trabajador
  Future<bool> updateWorker(
      Worker oldWorker, Worker newWorker, BuildContext context) async {
    try {
      // Llamar al servicio para actualizar en la API
      final success = await _workerService.updateWorker(newWorker, context);
      if (success) {
        // debugPrint('Trabajador actualizado correctamente en la API');
        // Actualizar en la lista local
        final index = _workers.indexWhere((w) => w.id == oldWorker.id);
        if (index >= 0) {
          _workers[index] = newWorker;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error en updateWorker del provider: $e');
      return false;
    }
  }

  Future<bool> retireWorker(
      Worker worker, DateTime retirementDate, BuildContext context) async {
    // Crear una copia del trabajador con los nuevos datos
    final updatedWorker = Worker(
        id: worker.id,
        name: worker.name,
        area: worker.area,
        phone: worker.phone,
        document: worker.document,
        status: WorkerStatus.deactivated,
        startDate: worker.startDate,
        endDate: worker.endDate,
        code: worker.code,
        deactivationDate: retirementDate,
        failures: worker.failures);

    // Usar el método general
    return updateWorker(worker, updatedWorker, context);
  }

  // Método para asignar un trabajador
  void assignWorker(Worker worker, DateTime endDate) {
    final index = _workers.indexWhere((w) => w.name == worker.name);
    if (index >= 0) {
      final updatedWorker = Worker(
          id: worker.id,
          name: worker.name,
          area: worker.area,
          phone: worker.phone,
          document: worker.document,
          status: WorkerStatus.assigned,
          startDate: worker.startDate,
          endDate: endDate,
          code: worker.code,
          incapacityEndDate: worker.incapacityEndDate,
          incapacityStartDate: worker.incapacityStartDate,
          failures: worker.failures);
      _workers[index] = updatedWorker;
      notifyListeners();
    }
  }

  Future<bool> incapacitateWorker(
    Worker worker,
    DateTime startDate,
    DateTime endDate,
    BuildContext context, {
    String? tipo,
    String? causa,
  }) async {
    try {
      // 1. Primero registrar la incapacidad en /inability
      if (tipo != null && causa != null) {
        final incapacityProvider =
            Provider.of<IncapacityProvider>(context, listen: false);

        final incapacity = Incapacity(
          workerId: worker.id,
          type: incapacityProvider.mapStringToType(tipo),
          cause: incapacityProvider.mapStringToCause(causa),
          startDate: startDate,
          endDate: endDate,
        );

        final incapacitySuccess =
            await incapacityProvider.registerIncapacity(incapacity, context);
        if (!incapacitySuccess) {
          debugPrint('Error al registrar incapacidad en /inability');
          return false;
        }
      }

      // 2. Luego actualizar el worker (como ya se hacía)
      final updatedWorker = Worker(
        id: worker.id,
        name: worker.name,
        area: worker.area,
        phone: worker.phone,
        document: worker.document,
        status: WorkerStatus.incapacitated,
        startDate: worker.startDate,
        endDate: worker.endDate,
        code: worker.code,
        incapacityStartDate: startDate,
        incapacityEndDate: endDate,
        failures: worker.failures,
        deactivationDate: worker.deactivationDate,
      );

      return updateWorker(worker, updatedWorker, context);
    } catch (e) {
      debugPrint('Error en incapacitateWorker: $e');
      return false;
    }
  }

  // Método para asignar un trabajador a  una operación
  Future<bool> assignWorkerToOperation(
      Worker worker, BuildContext context) async {
    try {
      // Llamar al servicio para actualizar el estado en el backend
      final success = await _workerService.updateWorkerStatus(
          worker.id, "assigned", context);

      if (success) {
        // Actualizar estado localmente
        final index = _workers.indexWhere((w) => w.id == worker.id);
        if (index >= 0) {
          final updatedWorker = Worker(
              id: worker.id,
              name: worker.name,
              area: worker.area,
              phone: worker.phone,
              document: worker.document,
              status: WorkerStatus.assigned,
              startDate: worker.startDate,
              endDate: null,
              code: worker.code,
              incapacityEndDate: worker.incapacityEndDate,
              incapacityStartDate: worker.incapacityStartDate,
              failures: worker.failures);
          _workers[index] = updatedWorker;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error al asignar trabajador: $e');
      return false;
    }
  }
}
