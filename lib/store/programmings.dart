import 'package:flutter/material.dart';
import 'package:plannerop/core/model/programming.dart';
import 'package:plannerop/services/programmings/programmings.dart';

class ProgrammingsProvider extends ChangeNotifier {
  final ProgrammingsService _programmingsService = ProgrammingsService();
  List<Programming> _programmings = [];
  List<Programming> _overdueProgrammings = [];
  bool _isLoading = false;
  String? _error;

  List<Programming> get programmings => _programmings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Programming> get overdueProgrammings => _overdueProgrammings;
  int get overdueCount => _overdueProgrammings.length;
  bool get hasOverdueProgrammings => _overdueProgrammings.isNotEmpty;

  // Método que se llama cada vez que se cargan programaciones
  void _checkForOverdueProgrammings() {
    final now = DateTime.now();
    _overdueProgrammings = _programmings.where((programming) {
      // Solo programaciones no asignadas
      if (programming.status != 'UNASSIGNED') return false;

      try {
        final programmingDateTime =
            _combineDateAndTime(programming.dateStart, programming.timeStart);
        return programmingDateTime.isBefore(now);
      } catch (e) {
        return false;
      }
    }).toList();

    // Notificar cambios
    notifyListeners();
  }

  DateTime _combineDateAndTime(String dateStr, String timeStr) {
    final date = DateTime.parse(dateStr);
    final timeParts = timeStr.split(':');
    final hours = int.parse(timeParts[0]);
    final minutes = int.parse(timeParts[1]);

    return DateTime(date.year, date.month, date.day, hours, minutes);
  }

  // Actualizar estado de una programación
  Future<bool> updateProgrammingStatus(
      int programmingId, String newStatus, BuildContext context) async {
    try {
      debugPrint(
          'Actualizando estado de programación $programmingId a $newStatus');

      final success = await _programmingsService.updateProgrammingStatus(
          programmingId, newStatus, context);

      if (success) {
        // Actualizar la programación en la lista local si existe
        final index = _programmings.indexWhere((p) => p.id == programmingId);
        if (index >= 0) {
          _programmings[index] = Programming(
            id: _programmings[index].id,
            service_request: _programmings[index].service_request,
            service: _programmings[index].service,
            dateStart: _programmings[index].dateStart,
            timeStart: _programmings[index].timeStart,
            ubication: _programmings[index].ubication,
            client: _programmings[index].client,
            status: newStatus, // ACTUALIZAR ESTADO
            id_operation: _programmings[index].id_operation,
            id_user: _programmings[index].id_user,
          );
          notifyListeners();
        }

        debugPrint('Programación $programmingId actualizada exitosamente');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error al actualizar estado de programación: $e');
      return false;
    }
  }

  Future<void> fetchProgrammingsByDate(
      String date, BuildContext context) async {
    // Usar Future.microtask para ejecutar notifyListeners() después de que termine la construcción
    Future.microtask(() {
      _isLoading = true;
      _error = null;
      notifyListeners();
    });

    try {
      final programmingsToday =
          await _programmingsService.getProgrammingsByDate(date, context);

      final programmingsTomorrow =
          await _programmingsService.getProgrammingsByDate(
              DateTime.now()
                  .add(const Duration(days: 1))
                  .toIso8601String()
                  .split('T')[0],
              context);

      // Asegurarse de que estemos fuera del ciclo de construcción
      _programmings = [...programmingsToday, ...programmingsTomorrow];

      // Usar Future.microtask también para la actualización final
      Future.microtask(() {
        _isLoading = false;
        notifyListeners();
      });

      _checkForOverdueProgrammings();
    } catch (e) {
      _error = 'Error al obtener programaciones: $e';

      Future.microtask(() {
        _isLoading = false;
        notifyListeners();
      });
    }
  }

  //  Buscar programación por ID
  Future<Programming?> fetchProgrammingById(
      int programmingId, BuildContext context) async {
    try {
      // Primero buscar en la lista actual
      try {
        return _programmings.firstWhere((p) => p.id == programmingId);
      } catch (e) {
        // Si no está en la lista actual, buscar en el backend
        // debugPrint(
        //     'Programación $programmingId no encontrada en caché, buscando en backend...');
      }

      // Si no está en la lista actual, hacer llamada al backend
      return await _programmingsService.getProgrammingById(
          programmingId, context);
    } catch (e) {
      // debugPrint('Error al buscar programación por ID: $e');
      return null;
    }
  }

  //  Refrescar programaciones forzadamente
  Future<void> refreshProgrammings(BuildContext context,
      {String? specificDate}) async {
    // debugPrint('Refrescando programaciones del cliente...');

    // Determinar qué fecha usar
    final String dateToFetch = specificDate ??
        DateTime.now().toIso8601String().split('T')[0]; // Formato YYYY-MM-DD

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final programmingsToday = await _programmingsService
          .getProgrammingsByDate(dateToFetch, context);
      final programmingsTomorrow =
          await _programmingsService.getProgrammingsByDate(
              DateTime.now()
                  .add(const Duration(days: 1))
                  .toIso8601String()
                  .split('T')[0],
              context);

      // Limpiar la lista actual y cargar nuevas programaciones
      _programmings.clear();
      _programmings.addAll(programmingsToday);
      _programmings.addAll(programmingsTomorrow);
    } catch (e) {
      _error = 'Error al refrescar programaciones: $e';
      debugPrint('Error al refrescar programaciones: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método para agregar una programación a la lista sin duplicados
  void addProgrammingToCache(Programming programming) {
    final index = _programmings.indexWhere((p) => p.id == programming.id);
    if (index >= 0) {
      _programmings[index] = programming;
    } else {
      _programmings.add(programming);
    }
    notifyListeners();
  }

  //  Limpiar caché
  void clear() {
    _programmings = [];
    notifyListeners();
  }
}
