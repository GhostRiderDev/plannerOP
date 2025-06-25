import 'package:flutter/material.dart';
import 'package:plannerop/core/model/fault.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/services/faults/fault.dart';
import 'package:plannerop/store/workers.dart';
import 'package:provider/provider.dart';

class FaultsProvider extends ChangeNotifier {
  List<Fault> _faults = [];
  bool _isLoading = false;
  bool _hasError = false;
  bool _hasLoadedInitialData = false;

  final FaultService _faultService = FaultService();

  // Getters
  List<Fault> get faults => _faults;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  bool get hasLoadedInitialData => _hasLoadedInitialData;

  // Añadir una falta local
  void addFault(Fault fault) {
    _faults.add(fault);
    notifyListeners();
  }

  // Eliminar una falta
  void removeFault(Fault fault) {
    _faults.remove(fault);
    notifyListeners();
  }

  // Cargar faltas desde la API
  Future<void> fetchFaults(BuildContext context) async {
    if (_isLoading) return;

    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      final faults = await _faultService.fetchFaults(context);
      _faults = faults;
      _hasLoadedInitialData = true;
    } catch (e) {
      debugPrint('Error al cargar faltas: $e');
      _hasError = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cargar faltas por trabajador
  List<Fault> fetchFaultsByWorker(BuildContext context, int workerId) {
    try {
      return faults.where((fault) => fault.worker.id == workerId).toList();
    } catch (e) {
      debugPrint('Error al cargar faltas por trabajador: $e');
      return [];
    }
  }

  // Obtener faltas por tipo
  List<Fault> getFaultsByType(FaultType type) {
    return _faults.where((fault) => fault.type == type).toList();
  }

  // Obtener trabajadores con más faltas (ordenados por cantidad y recencia)
  List<Worker> getWorkersWithMostFaults(BuildContext context) {
    // Si no hay faltas, retornar lista vacía inmediatamente
    if (_faults.isEmpty) {
      debugPrint('No hay faltas registradas');
      return [];
    }

    // Crear un mapa para contar faltas por trabajador
    final Map<int, int> workerFaultCount = {};

    // Mapa para almacenar la fecha de la falta más reciente por trabajador
    final Map<int, DateTime> latestFaultDate = {};

    // Contar la cantidad de faltas por trabajador y rastrear la falta más reciente
    for (Fault fault in _faults) {
      final workerId = fault.worker.id;

      // Incrementar contador de faltas
      workerFaultCount[workerId] = (workerFaultCount[workerId] ?? 0) + 1;

      // Si la falta tiene fecha, verificar si es la más reciente
      // Nota: Aquí asumo que cada falta puede tener o no un atributo 'date'
      // Si no existe, podemos usar un valor predeterminado (como la fecha actual)
      DateTime faultDate;
      if (fault.createdAt != null) {
        faultDate = fault.createdAt;
      } else {
        // Si no hay fecha, usar una fecha simulada basada en ID
        // Esto es solo para demostración - en producción, cada falta debería tener fecha
        faultDate = DateTime.now().subtract(Duration(days: fault.id % 30));
      }

      // Actualizar fecha más reciente si no existe o si esta es más reciente
      if (!latestFaultDate.containsKey(workerId) ||
          faultDate.isAfter(latestFaultDate[workerId]!)) {
        latestFaultDate[workerId] = faultDate;
      }
    }

    // Obtener lista única de trabajadores (sin duplicados)
    final Map<int, Worker> uniqueWorkersMap = {};
    for (final fault in _faults) {
      uniqueWorkersMap[fault.worker.id] = fault.worker;
    }

    // Convertir mapa a lista
    final uniqueWorkers = uniqueWorkersMap.values.toList();

    // Filtrar para mantener solo trabajadores con al menos una falta
    final workersWithFaults = uniqueWorkers.where((worker) {
      final faultCount = workerFaultCount[worker.id] ?? 0;
      return faultCount > 0;
    }).toList();

    // Ordenar trabajadores por cantidad de faltas (de mayor a menor)
    // Si tienen la misma cantidad, ordenar por la fecha de la falta más reciente (más reciente primero)
    workersWithFaults.sort((a, b) {
      final countA = workerFaultCount[a.id] ?? 0;
      final countB = workerFaultCount[b.id] ?? 0;

      // Si tienen distinta cantidad de faltas, ordenar por cantidad
      if (countA != countB) {
        return countB.compareTo(countA); // Orden descendente por cantidad
      }

      // Si tienen la misma cantidad de faltas, ordenar por fecha más reciente

      final dateA = latestFaultDate[a.id] ?? DateTime(1900);
      final dateB = latestFaultDate[b.id] ?? DateTime(1900);

      return dateB.compareTo(
          dateA); // Orden descendente por fecha (más reciente primero)
    });

    // debugPrint(
    //     'Trabajadores con faltas encontrados: ${workersWithFaults.length}');

    return workersWithFaults;
  }

  // Añadir un método para obtener la cantidad de faltas por trabajador
  int getFaultCountForWorker(int workerId) {
    return _faults.where((fault) => fault.worker.id == workerId).length;
  }

  // Registrar falta con descripción y actualizar el contador
  Future<bool> registerFault(
    Worker worker,
    BuildContext context, {
    String? description,
  }) async {
    try {
      // Llamar al servicio para registrar la falta
      final success = await _faultService.registerFault(worker, context,
          description: description);
      if (success) {
        final _workers =
            Provider.of<WorkersProvider>(context, listen: false).workers;

        // Actualizar el contador de faltas en la copia local del worker
        final index = _workers.indexWhere((w) => w.id == worker.id);
        if (index >= 0) {
          final updatedWorker = Worker(
            id: worker.id,
            name: worker.name,
            area: worker.area,
            phone: worker.phone,
            document: worker.document,
            status: worker.status,
            startDate: worker.startDate,
            endDate: worker.endDate,
            code: worker.code,
            incapacityStartDate: worker.incapacityStartDate,
            incapacityEndDate: worker.incapacityEndDate,
            failures: worker.failures + 1,
            idArea: worker.idArea,
            deactivationDate: worker.deactivationDate,
          );
          _workers[index] = updatedWorker;
          notifyListeners();
        }

        // Además de actualizar el worker, crear un registro de falta para el FaultsProvider
        if (description != null && description.isNotEmpty) {
          final faultsProvider =
              Provider.of<FaultsProvider>(context, listen: false);
          faultsProvider.addFault(Fault(
            description: description,
            type: FaultType.INASSISTANCE,
            id: 0, // El ID lo asignará la API
            worker: worker,
            createdAt: DateTime.now(),
          ));
        }

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error en registerFault: $e');
      return false;
    }
  }

  // Registrar abandono (solo registra el incidente, no incrementa el contador)
  Future<bool> registerAbandonment(
    Worker worker,
    BuildContext context, {
    String? description,
  }) async {
    try {
      if (description == null || description.isEmpty) {
        return false;
      }

      // Llamar al servicio para registrar el abandono
      final success = await _faultService.registerAbandonment(worker, context,
          description: description);

      final _workers =
          Provider.of<WorkersProvider>(context, listen: false).workers;

      if (success) {
        // Actualizar el contador de faltas en la copia local del worker
        final index = _workers.indexWhere((w) => w.id == worker.id);
        if (index >= 0) {
          final updatedWorker = Worker(
            id: worker.id,
            name: worker.name,
            area: worker.area,
            phone: worker.phone,
            document: worker.document,
            status: worker.status,
            startDate: worker.startDate,
            endDate: worker.endDate,
            code: worker.code,
            incapacityStartDate: worker.incapacityStartDate,
            incapacityEndDate: worker.incapacityEndDate,
            failures: worker.failures + 1,
            idArea: worker.idArea,
            deactivationDate: worker.deactivationDate,
          );
          _workers[index] = updatedWorker;
          notifyListeners();
        }

        // Además de actualizar el worker, crear un registro de falta para el FaultsProvider
        if (description.isNotEmpty) {
          final faultsProvider =
              Provider.of<FaultsProvider>(context, listen: false);
          faultsProvider.addFault(Fault(
            description: description,
            type: FaultType.INASSISTANCE,
            id: 0, // El ID lo asignará la API
            worker: worker,
            createdAt: DateTime.now(),
          ));
        }

        return true;
      }
      if (success) {
        // Crear un registro de abandono en el FaultsProvider
        final faultsProvider =
            Provider.of<FaultsProvider>(context, listen: false);
        faultsProvider.addFault(Fault(
          description: description,
          type: FaultType.ABANDONMENT,
          id: 0, // El ID lo asignará la API
          worker: worker,
          createdAt: DateTime.now(),
        ));

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error en registerAbandonment: $e');
      return false;
    }
  }

  // Registrar falta de respeto (solo registra el incidente, no incrementa el contador)
  Future<bool> registerDisrespect(
    Worker worker,
    BuildContext context, {
    String? description,
  }) async {
    try {
      if (description == null || description.isEmpty) {
        return false;
      }

      // Llamar al servicio para registrar la falta de respeto
      final success = await _faultService.registerDisrespect(worker, context,
          description: description);

      if (success) {
        final _workers =
            Provider.of<WorkersProvider>(context, listen: false).workers;

        // Actualizar el contador de faltas en la copia local del worker
        final index = _workers.indexWhere((w) => w.id == worker.id);
        if (index >= 0) {
          final updatedWorker = Worker(
            id: worker.id,
            name: worker.name,
            area: worker.area,
            phone: worker.phone,
            document: worker.document,
            status: worker.status,
            startDate: worker.startDate,
            endDate: worker.endDate,
            code: worker.code,
            incapacityStartDate: worker.incapacityStartDate,
            incapacityEndDate: worker.incapacityEndDate,
            failures: worker.failures + 1,
            idArea: worker.idArea,
            deactivationDate: worker.deactivationDate,
          );
          _workers[index] = updatedWorker;
          notifyListeners();
        }

        // Además de actualizar el worker, crear un registro de falta para el FaultsProvider
        if (description.isNotEmpty) {
          final faultsProvider =
              Provider.of<FaultsProvider>(context, listen: false);
          faultsProvider.addFault(Fault(
            description: description,
            type: FaultType.INASSISTANCE,
            id: 0, // El ID lo asignará la API
            worker: worker,
            createdAt: DateTime.now(),
          ));
        }

        return true;
      }
      if (success) {
        // Crear un registro de falta de respeto en el FaultsProvider
        final faultsProvider =
            Provider.of<FaultsProvider>(context, listen: false);
        faultsProvider.addFault(Fault(
          description: description,
          type: FaultType.IRRESPECTFUL,
          id: 0, // El ID lo asignará la API
          worker: worker,
          createdAt: DateTime.now(),
        ));

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error en registerDisrespect: $e');
      return false;
    }
  }

  void clear() {
    _faults = [];
    notifyListeners();
  }
}
