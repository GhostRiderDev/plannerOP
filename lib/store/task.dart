import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:plannerop/core/model/task.dart';
import 'package:plannerop/services/task/task.dart';

class TasksProvider extends ChangeNotifier {
  final TaskService _taskService = TaskService();
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;
  bool _hasBeenLoaded = false;
  bool _hasAttemptedLoading = false;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasBeenLoaded => _hasBeenLoaded;
  bool get hasAttemptedLoading => _hasAttemptedLoading;

  // Método para cargar tareas solo si es necesario
  Future<void> loadTasksIfNeeded(BuildContext context) async {
    if (_isLoading || _hasAttemptedLoading) {
      return;
    }
    return loadTasks(context);
  }

  // MEJORADO: Método asíncrono con mejor debugging
  Future<String> getTaskNameByIdServiceAsync(
      int id, BuildContext context) async {
    // Si no se han cargado las tareas aún, cargarlas
    if (!_hasAttemptedLoading && !_isLoading) {
      // Usar scheduler para cargar después del build
      SchedulerBinding.instance.addPostFrameCallback((_) {
        loadTasks(context);
      });

      // Esperar a que se inicie la carga
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Esperar a que terminen de cargar con timeout
    int maxWaitCycles = 50; // 5 segundos máximo
    int waitCycle = 0;

    while (_isLoading && waitCycle < maxWaitCycles) {
      await Future.delayed(const Duration(milliseconds: 100));
      waitCycle++;
    }

    if (waitCycle >= maxWaitCycles) {
      return 'Error: Timeout cargando servicios';
    }

    // Verificar si tenemos tareas cargadas
    if (_tasks.isEmpty) {
      return 'No hay servicios disponibles';
    }

    // Buscar la tarea
    final task = _tasks.firstWhere(
      (task) => task.id == id,
      orElse: () => Task(id: 0, name: ''),
    );

    return task.name.isNotEmpty ? task.name : 'Servicio ID $id no encontrado';
  }

  // MEJORADO: Cargar las tareas desde el API
  Future<void> loadTasks(BuildContext context) async {
    if (_isLoading) {
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      _safeNotifyListeners();

      final result = await _taskService.fetchTasks(context);
      _hasAttemptedLoading = true;

      if (result.isSuccess) {
        _tasks = result.tasks;
        _hasBeenLoaded = true;

        // Debug: Mostrar algunas tareas cargadas
        if (_tasks.isNotEmpty) {}
      } else {
        _error = result.errorMessage ?? 'Error al cargar tareas';
      }
    } catch (e) {
      _error = 'Error inesperado: $e';
      debugPrint('💥 Excepción cargando tareas: $e');
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Método para notificar de forma segura
  void _safeNotifyListeners() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  // Lista de nombres de tareas
  List<String> get taskNames => _tasks.map((task) => task.name).toList();

  Task getTaskByName(String name) {
    return _tasks.firstWhere((task) => task.name == name,
        orElse: () => Task(id: 0, name: ''));
  }

  // MEJORADO: Método síncrono con mejor debugging
  String getTaskNameByIdService(int id) {
    final task = _tasks.firstWhere((task) => task.id == id,
        orElse: () => Task(id: 0, name: ''));

    return task.name.isEmpty ? 'Servicio no especificado' : task.name;
  }

  // NUEVO: Método para buscar manualmente una tarea (para debugging)
  void debugSearchTask(int id) {
    for (var task in _tasks) {
      if (task.id == id) {
        return;
      }
    }
  }

  // Método para verificar si existe una tarea
  bool hasTaskWithId(int id) {
    return _tasks.any((task) => task.id == id);
  }

  void clear() {
    _tasks = [];
    notifyListeners();
  }
}
