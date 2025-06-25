import 'dart:async';
import 'package:flutter/material.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/dto/operations/createOperation.dart';
import 'package:plannerop/services/operations/operation.dart';
import 'package:plannerop/store/programmings.dart';
import 'package:plannerop/store/workerGroup.dart';
import 'package:provider/provider.dart';

class OperationsProvider extends ChangeNotifier {
  final OperationService _operationService = OperationService();
  List<Operation> _operations = [];
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;
  final Duration _refreshInterval = const Duration(seconds: 30);

  List<Operation> get operations => _operations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  BuildContext? _lastContext;

  List<Operation> get pendingOperations =>
      _operations.where((a) => a.status == 'PENDING').toList();

  List<Operation> get inProgressOperations =>
      _operations.where((a) => a.status == 'INPROGRESS').toList();

  List<Operation> get completedOperations =>
      _operations.where((a) => a.status == 'COMPLETED').toList();

  OperationsProvider() {
    _startRefreshTimer();
  }

  void changeIsLoadingOff() {
    _isLoading = false;
    notifyListeners();
  }

  // No olvidar añadir dispose para limpiar el temporizador
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Actualizar el método completeGroup para incluir fecha y hora de inicio
  Future<bool> completeGroup(
    Operation assignment,
    List<Worker> workers,
    String groupId,
    DateTime endDate,
    String endTime,
    BuildContext context,
  ) async {
    // debugPrint('Completando grupo/individual: $groupId');

    // Add a timeout to prevent UI from being stuck
    bool hasCompleted = false;
    Timer? timeoutTimer;

    timeoutTimer = Timer(Duration(seconds: 15), () {
      if (!hasCompleted) {
        // debugPrint('Operation timed out - forcing state reset');
        _isLoading = false;
        _error = 'La operación tardó demasiado tiempo. Inténtalo de nuevo.';
        notifyListeners();
      }
    });

    try {
      _error = null;
      notifyListeners();

      // Determinar fecha y hora de inicio según sea grupo o individual
      DateTime startDate;
      String startTime;

      // Si es un grupo específico, buscar sus datos de inicio
      if (groupId != "individual" && !groupId.startsWith("worker_")) {
        // Buscar el grupo por ID
        final group = assignment.groups.firstWhere(
          (g) => g.id == groupId,
          orElse: () =>
              WorkerGroup(workers: [], name: "", id: "", serviceId: 0),
        );

        // Si el grupo tiene fecha y hora de inicio, usarlas
        if (group.startDate != null && group.startTime != null) {
          startDate = DateTime.parse(group.startDate!);
          startTime = group.startTime!;
        } else {
          // Si no tiene, usar los de la operación principal
          startDate = assignment.date;
          startTime = assignment.time;
        }
      } else {
        // Para trabajadores individuales o grupos genéricos, usar los de la operación
        startDate = assignment.date;
        startTime = assignment.time;
      }

      // Obtener IDs de los trabajadores a completar
      final List<int> workerIds = workers.map((w) => w.id).toList();

      // Si es un grupo, usar sus IDs de trabajadores
      var workerIdsToSend = groupId.startsWith("worker_")
          ? [int.parse(groupId.split("_")[1])]
          : workerIds;

      // Verificar si este es el último grupo
      bool isLastGroup = false;
      if (groupId != "individual" && !groupId.startsWith("worker_")) {
        // Contar cuántos grupos quedarían después de completar este
        final remainingGroups =
            assignment.groups.where((g) => g.id != groupId).toList();
        isLastGroup = remainingGroups.isEmpty;
      }

      // Si es el último grupo, completar toda la operación
      if (isLastGroup) {
        debugPrint('Es el último grupo, completando toda la operación');
        hasCompleted = true;
        timeoutTimer.cancel();
        return await completeOperation(
            assignment.id ?? 0, endDate, endTime, context);
      }

      // Si no, enviar petición para completar sólo este grupo/trabajador
      final success = await _operationService.completeGroupOperation(
        assignment.id ?? 0,
        workerIdsToSend,
        groupId,
        endDate,
        startDate,
        startTime,
        endTime,
        context,
      );

      if (success) {
        // Actualizar en la lista local - quitar estos trabajadores o grupos
        final index = _operations.indexWhere((a) => a.id == assignment.id);

        if (index >= 0) {
          // Si es un grupo, eliminarlo de la lista de grupos
          // Crear una nueva lista de grupos sin el grupo completado
          final updatedGroups =
              _operations[index].groups.where((g) => g.id != groupId).toList();

          // Actualizar la operación con los grupos actualizados
          _operations[index] = Operation(
              id: assignment.id,
              area: assignment.area,
              date: assignment.date,
              time: assignment.time,
              supervisor: assignment.supervisor,
              status: assignment.status,
              endDate: assignment.endDate,
              endTime: assignment.endTime,
              zone: assignment.zone,
              motorship: assignment.motorship,
              userId: assignment.userId,
              areaId: assignment.areaId,
              clientId: assignment.clientId,
              inChagers: assignment.inChagers,
              groups: updatedGroups, // Actualizar con la lista filtrada
              id_clientProgramming: assignment.id_clientProgramming);
        }
        notifyListeners();
      }

      _isLoading = false;
      hasCompleted = true;
      timeoutTimer.cancel();
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('Error en completeGroupOrIndividual: $e');
      _error = 'Error: $e';
      _isLoading = false;
      hasCompleted = true;
      timeoutTimer.cancel();
      notifyListeners();
      return false;
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      if (_lastContext != null) {
        refreshActiveOperations(_lastContext!);
      }
    });
  }

  // Método para refrescar solo operaciones activas
  Future<void> refreshActiveOperations(BuildContext context) async {
    _lastContext = context;

    try {
      // Refrescar solo asignaciones activas y pendientes
      final updatedOperations = await _operationService
          .fetchOperationsByStatus(context, ['INPROGRESS', 'PENDING']);

      if (updatedOperations.isNotEmpty) {
        // Actualizar lista existente
        _updateAssignmentsList(updatedOperations);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error al refrescar asignaciones activas: $e');
      // No mostrar error para refrescos silenciosos
    }
  }

  Future<bool> completeOperation(
      int id, DateTime endDate, String endTime, BuildContext context) async {
    // debugPrint('Completando operación...');
    try {
      final success = await _operationService.completeOperation(
          id, 'COMPLETED', endDate, endTime, context);

      if (success) {
        final index = _operations.indexWhere((a) => a.id == id);
        if (index >= 0) {
          final currentOperation = _operations[index];
          _operations[index] = Operation(
            id: currentOperation.id,
            // workers: currentOperation.workers,
            area: currentOperation.area,
            // task: currentOperation.task,
            date: currentOperation.date,
            time: currentOperation.time,
            zone: currentOperation.zone,
            status: 'COMPLETED',
            endDate: currentOperation.endDate ?? endDate,
            endTime: currentOperation.endTime ?? endTime,
            motorship: currentOperation.motorship,
            userId: currentOperation.userId,
            areaId: currentOperation.areaId,
            // taskId: currentOperation.taskId,
            clientId: currentOperation.clientId,
            inChagers: currentOperation.inChagers,
            groups: currentOperation.groups,
            id_clientProgramming: currentOperation.id_clientProgramming,
          );
          notifyListeners();
        }
      }

      return success;
    } catch (e) {
      debugPrint('Error al completar la operación: $e');
      return false;
    }
  }

// Método para eliminar un grupo de una asignación
  Future<bool> removeGroupFromOperation(Map<String, List<int>> workersGroups,
      BuildContext context, int assigmentId) async {
    try {
      // Llamar al servicio para eliminar el grupo en el backend
      final success = await _operationService.removeGroupFromOperation(
          assigmentId, context, workersGroups);

      if (success) {
        // Si fue exitoso, actualizar la operación local
        final index = _operations.indexWhere((a) => a.id == assigmentId);
        if (index >= 0) {
          // Crear una copia actualizada de la operación sin el grupo
          final updatedGroups = _operations[index]
              .groups
              .where((g) => !workersGroups.containsKey(g.id))
              .toList();

          // Actualizar la operación
          _operations[index] = Operation(
            id: _operations[index].id,
            // workers: _operations[index].workers,
            area: _operations[index].area,
            // task: _operations[index].task,
            date: _operations[index].date,
            time: _operations[index].time,
            zone: _operations[index].zone,
            status: _operations[index].status,
            endDate: _operations[index].endDate,
            endTime: _operations[index].endTime,
            motorship: _operations[index].motorship,
            userId: _operations[index].userId,
            areaId: _operations[index].areaId,
            // taskId: _operations[index].taskId,
            clientId: _operations[index].clientId,
            inChagers: _operations[index].inChagers,
            groups: updatedGroups,
            deletedWorkers: _operations[index].deletedWorkers,
            id_clientProgramming: _operations[index].id_clientProgramming,
          );

          notifyListeners();
        }

        return true;
      } else {
        _error = "Error al eliminar el grupo en el servidor";
        return false;
      }
    } catch (e) {
      debugPrint('Error en removeGroupFromAssignment: $e');
      _error = 'Error: $e';
      return false;
    }
  }

// Añadir este método al provider de asignaciones
  Future<bool> connectWorkersToAssignment(
      List<int> individualWorkerIds,
      List<Map<String, dynamic>> groupsToConnect,
      BuildContext context,
      int assignmentId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Llamar al servicio para conectar los trabajadores en el backend
      final success = await _operationService.connectWorkersToOperation(
          assignmentId, individualWorkerIds, groupsToConnect, context);

      _isLoading = false;
      notifyListeners();

      return success;
    } catch (e) {
      debugPrint('Error en connectWorkersToAssignment: $e');
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

// Método actualizado para agregar operación con todos los campos
  Future<bool> addAssignment({
    required String area,
    required int areaId,
    required DateTime date,
    required String time,
    required int zoneId,
    required int userId,
    required int clientId,
    int? id_clientProgramming,
    required List<int> chargerIds,
    required List<WorkerGroup> groups,
    String? clientName,
    DateTime? endDate,
    String? endTime,
    String? motorship,
    BuildContext? context,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newAssignment = Operation(
        area: area,
        date: date,
        time: time,
        zone: zoneId,
        status: 'PENDING',
        endDate: endDate,
        endTime: endTime,
        motorship: motorship,
        userId: userId,
        areaId: areaId,
        clientId: clientId,
        inChagers: chargerIds,
        groups: groups,
        id_clientProgramming: id_clientProgramming,
      );

      CreateOperationDto response = CreateOperationDto(id: 0, isSuccess: false);
      if (context != null) {
        response =
            await _operationService.createOperation(newAssignment, context);
        newAssignment.id = response.id;
      }

      if (response.isSuccess) {
        //  Refrescar la operación para obtener los IDs reales de los grupos
        if (context != null && response.id > 0) {
          await _refreshCreatedOperation(response.id, context);
        } else {
          // Si no se puede refrescar, agregar la operación con IDs temporales
          _operations.add(newAssignment);
        }

        //  Actualizar estado de la programación si existe
        if (id_clientProgramming != null && context != null) {
          ProgrammingsProvider programmingProvider =
              Provider.of<ProgrammingsProvider>(context, listen: false);

          await programmingProvider.updateProgrammingStatus(
              id_clientProgramming, 'ASSIGNED', context);
        }

        // await _saveAssignments();
      } else {
        _error = "Error al crear la operación en el servidor";
      }

      WorkerGroupsProvider workerGroupsProvider =
          Provider.of<WorkerGroupsProvider>(context!, listen: false);
      workerGroupsProvider.groups.clear();

      _isLoading = false;
      notifyListeners();
      return response.isSuccess;
    } catch (e) {
      debugPrint('Error al agregar operación: $e');
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

//  Refrescar una operación específica después de crearla
  Future<void> _refreshCreatedOperation(
      int operationId, BuildContext context) async {
    try {
      // Obtener la operación específica del backend
      final refreshedOperations = await _operationService
          .fetchOperationsByStatus(context, ['PENDING', 'INPROGRESS']);

      // Buscar la operación específica en la respuesta usando where (más seguro)
      final matchingOperations =
          refreshedOperations.where((op) => op.id == operationId).toList();

      if (matchingOperations.isNotEmpty) {
        final refreshedOperation = matchingOperations.first;
        // Agregar la operación refrescada con los IDs reales
        _operations.add(refreshedOperation);
      } else {
        debugPrint(
            'No se pudo encontrar la operación $operationId en la respuesta del backend');
        debugPrint(
            'Operaciones encontradas: ${refreshedOperations.map((op) => op.id).toList()}');
      }
    } catch (e) {
      debugPrint('Error al refrescar operación creada: $e');
      // No throw error, solo log, para no afectar el flujo principal
    }
  }

  Future<bool> updateOperation({
    required int id,
    String? status,
    DateTime? endDate,
    String? endTime,
    BuildContext? context,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final index = _operations.indexWhere((a) => a.id == id);
      if (index < 0) return false;

      final currentAssignment = _operations[index];

      // Actualizar en backend si hay contexto
      if (context != null && status != null) {
        final success =
            await _operationService.updateStatusOperation(id, status, context);
        if (!success) return false;
      }

      // Actualizar localmente
      _operations[index] = Operation(
        id: currentAssignment.id,
        area: currentAssignment.area,
        date: currentAssignment.date,
        time: currentAssignment.time,
        zone: currentAssignment.zone,
        status: status ?? currentAssignment.status,
        endDate: endDate ?? currentAssignment.endDate,
        endTime: endTime ?? currentAssignment.endTime,
        motorship: currentAssignment.motorship,
        userId: currentAssignment.userId,
        areaId: currentAssignment.areaId,
        clientId: currentAssignment.clientId,
        inChagers: currentAssignment.inChagers,
        groups: currentAssignment.groups,
        id_clientProgramming: currentAssignment.id_clientProgramming,
      );

      // await _saveAssignments();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

// Añadir a la clase AssignmentsProvider
  Future<void> loadAssignmentsWithPriority(BuildContext context) async {
    final hasExistingData = _operations.isNotEmpty;

    if (!hasExistingData) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      // Primera fase: Cargar asignaciones activas y pendientes (alta prioridad)
      final highPriorityAssignments = await _operationService
          .fetchOperationsByStatus(context, ['INPROGRESS', 'PENDING']);

      // Actualizar primero las asignaciones de alta prioridad
      if (highPriorityAssignments.isNotEmpty) {
        // Actualizar asignaciones actuales
        _updateAssignmentsList(highPriorityAssignments);

        // Notificar cambios para actualizar la UI inmediatamente
        if (!hasExistingData) {
          _isLoading = false;
        }
        notifyListeners();
      }

      // Segunda fase: Cargar asignaciones completadas (baja prioridad) en segundo plano
      _loadCompletedAssignmentsInBackground(context);
    } catch (e) {
      debugPrint('Error al cargar asignaciones prioritarias: $e');
      _error = 'Error al cargar asignaciones: $e';

      if (!hasExistingData) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

// Método auxiliar para cargar asignaciones completadas en segundo plano
  Future<void> _loadCompletedAssignmentsInBackground(
      BuildContext context) async {
    // debugPrint('Cargando asignaciones completadas en segundo plano...');
    try {
      final completedAssignments = await _operationService
          .fetchOperationsByStatus(context, ['COMPLETED']);

      if (completedAssignments.isNotEmpty) {
        // Actualizar solo las asignaciones completadas
        _updateAssignmentsList(completedAssignments);
        notifyListeners();
      }
    } catch (e) {
      debugPrint(
          'Error al cargar asignaciones completadas en segundo plano: $e');
      // No establecer error ni notificar, ya que es carga en segundo plano
    }
  }

// Método para actualizar la lista de asignaciones eficientemente
  void _updateAssignmentsList(List<Operation> newAssignments) {
    for (var newAssignment in newAssignments) {
      final index = _operations.indexWhere((a) => a.id == newAssignment.id);
      if (index >= 0) {
        // Actualizar operación existente
        _operations[index] = newAssignment;
      } else {
        // Añadir nueva operación
        _operations.add(newAssignment);
      }
    }
  }

  void clear() {
    //  LIMPIAR LA LISTA PRINCIPAL
    _operations.clear();
    _error = null;
    _isLoading = false;

    //  CANCELAR TIMER Y LIMPIAR CONTEXTO
    if (_refreshTimer != null) {
      _refreshTimer!.cancel();
      _refreshTimer = null;
      debugPrint("🔥 Timer de refresh cancelado");
    }

    _lastContext = null;

    notifyListeners();
  }
}
