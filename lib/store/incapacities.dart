import 'package:flutter/material.dart';
import 'package:plannerop/core/model/incapacity.dart';
import 'package:plannerop/services/incapacities/Incapacities.dart';

class IncapacityProvider with ChangeNotifier {
  List<Incapacity> _incapacities = [];
  bool _isLoading = false;
  String _error = '';

  final IncapacityService _incapacityService = IncapacityService();

  // Getters
  List<Incapacity> get incapacities => [..._incapacities];
  bool get isLoading => _isLoading;
  String get error => _error;

  // Registrar nueva incapacidad
  Future<bool> registerIncapacity(
      Incapacity incapacity, BuildContext context) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final success =
          await _incapacityService.registerIncapacity(incapacity, context);

      if (success) {
        _incapacities.add(incapacity);
        notifyListeners();
      } else {
        _error = 'Error al registrar la incapacidad';
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Nuevo método para obtener la incapacidad actual de un trabajador
  Future<Incapacity?> getCurrentIncapacityForWorker(
    int workerId,
    DateTime? startDate,
    DateTime? endDate,
    BuildContext context,
  ) async {
    try {
      if (startDate == null || endDate == null) {
        return null;
      }

      // Buscar incapacidades del trabajador en el rango de fechas actual
      final incapacities = await _incapacityService.searchIncapacities(
        workerId: workerId,
        dateDisableStart: startDate,
        dateDisableEnd: endDate,
        context: context,
      );

      if (incapacities.isEmpty) {
        return null;
      }

      // Ordenar por fecha de creación descendente y tomar la más reciente
      incapacities.sort((a, b) {
        final aDate = a.createdAt ?? a.startDate ?? DateTime(1970);
        final bDate = b.createdAt ?? b.startDate ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

      return incapacities.first;
    } catch (e) {
      debugPrint('Error al obtener incapacidad actual: $e');
      return null;
    }
  }

  // Mapear enum a string para mostrar
  String mapTypeToDisplayString(IncapacityType type) {
    switch (type) {
      case IncapacityType.INITIAL:
        return 'Inicial';
      case IncapacityType.EXTENSION:
        return 'Prórroga';
    }
  }

  String mapCauseToDisplayString(IncapacityCause cause) {
    switch (cause) {
      case IncapacityCause.LABOR:
        return 'Accidente Laboral';
      case IncapacityCause.TRANSIT:
        return 'Accidente de Tránsito';
      case IncapacityCause.DISEASE:
        return 'Enfermedad General';
    }
  }

  // Mapear string a enum
  IncapacityType mapStringToType(String type) {
    switch (type) {
      case 'Inicial':
        return IncapacityType.INITIAL;
      case 'Prórroga':
        return IncapacityType.EXTENSION;
      default:
        return IncapacityType.INITIAL;
    }
  }

  IncapacityCause mapStringToCause(String cause) {
    switch (cause) {
      case 'Accidente Laboral':
        return IncapacityCause.LABOR;
      case 'Accidente de Tránsito':
        return IncapacityCause.TRANSIT;
      case 'Enfermedad General':
        return IncapacityCause.DISEASE;
      default:
        return IncapacityCause.DISEASE;
    }
  }

  void clear() {
    _incapacities = [];
    notifyListeners();
  }
}
