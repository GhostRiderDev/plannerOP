import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/network/httpClient.dart';
import 'package:plannerop/dto/workers/fetchWorkers.dart';
import 'package:plannerop/providers/auth.dart';
import 'package:provider/provider.dart';

class WorkerService {
  final ApiClient _apiClient = ApiClient();

  // Versión que acepta un token directamente, sin depender del contexto
  Future<FetchWorkersDto> fetchWorkers() async {
    try {
      var url = '/worker';
      var response = await _apiClient.get(url);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        final List<Worker> workers = [];
        for (var w in jsonResponse) {
          try {
            // Convertir fechas de string a DateTime si es necesario
            DateTime? startDate;
            DateTime? endDate;

            if (w['createdAt'] != null) {
              startDate = DateTime.tryParse(w['createdAt'].toString());
            }

            if (w['updatedAt'] != null) {
              endDate = DateTime.tryParse(w['updatedAt'].toString());
            }

            // Determinar el estado correcto
            WorkerStatus status = WorkerStatus.available;
            if (w['status'] == 'ASSIGNED') {
              status = WorkerStatus.assigned;
            }

            if (w['status'] == 'UNAVALIABLE') {
              status = WorkerStatus.unavailable;
            }

            if (w['status'] == 'DEACTIVATED') {
              status = WorkerStatus.deactivated;
            }

            if (w['status'] == 'DISABLE') {
              status = WorkerStatus.incapacitated;
            }

            if (w['status'] == 'AVALIABLE') {
              status = WorkerStatus.available;
            }

            workers.add(Worker(
              id: w['id'],
              document: w['dni'],
              name: w['name'],
              phone: w['phone'],
              status: status,
              area: '${w['jobArea']['name']}',
              code: '${w['code']}',
              failures: w['failures'] ?? 0,
              startDate: startDate ?? DateTime.now(),
              endDate: endDate ?? DateTime.now(),
              incapacityStartDate: w['dateDisableStart'] != null
                  ? DateTime.tryParse(w['dateDisableStart'].toString()) ??
                      DateTime.now()
                  : DateTime.now(),
              incapacityEndDate: w['dateDisableEnd'] != null
                  ? DateTime.tryParse(w['dateDisableEnd'].toString()) ??
                      DateTime.now()
                  : DateTime.now(),
              deactivationDate: w['dateRetierment'] != null
                  ? DateTime.tryParse(w['dateRetierment'].toString()) ??
                      DateTime.now()
                  : DateTime.now(),
            ));
          } catch (e) {
            debugPrint('Error procesando trabajador: $e');
          }
        }

        return FetchWorkersDto(workers: workers, isSuccess: true);
      } else {
        debugPrint('Error en API: ${response.statusCode} - ${response.body}');
        return FetchWorkersDto(workers: [], isSuccess: false);
      }
    } on SocketException catch (e) {
      debugPrint('Error de conexión: $e');
      return FetchWorkersDto(workers: [], isSuccess: false);
    } on HttpException catch (e) {
      debugPrint('Error HTTP: $e');
      return FetchWorkersDto(workers: [], isSuccess: false);
    } on FormatException catch (e) {
      debugPrint('Error de formato: $e');
      return FetchWorkersDto(workers: [], isSuccess: false);
    } on Exception catch (e) {
      debugPrint('Error en fetchWorkers: $e');
      return FetchWorkersDto(workers: [], isSuccess: false);
    }
  }

  // Método para registrar un nuevo trabajador
  Future<Map<String, dynamic>> registerWorker(Worker worker, int userId) async {
    try {
      var url = '/worker';
      final payload = {
        'name': worker.name,
        'dni': worker.document,
        'phone': worker.phone,
        'id_area': worker.idArea,
        'status': 'AVALIABLE',
        'id_user': userId,
        'code': worker.code,
      };
      var response = await _apiClient.post(url, body: payload);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Trabajador registrado correctamente'
        };
      } else if (response.statusCode == 409) {
        // Conflict - recurso ya existe
        // Intentar obtener información más específica del error
        Map<String, dynamic> errorResponse = jsonDecode(response.body);
        String errorMessage =
            errorResponse['message'] ?? 'El trabajador ya existe';

        // Analizar mensaje para determinar qué campo está duplicado
        String fieldError = 'documento';
        if (errorMessage.toLowerCase().contains('dni')) {
          fieldError = 'documento';
        } else if (errorMessage.toLowerCase().contains('phone')) {
          fieldError = 'teléfono';
        } else if (errorMessage.toLowerCase().contains('code')) {
          fieldError = 'código';
        }

        return {
          'success': false,
          'message': 'Ya existe un trabajador con este $fieldError',
          'field': fieldError
        };
      } else {
        return {
          'success': false,
          'message': 'Error en API: ${response.statusCode} - ${response.body}'
        };
      }
    } catch (e) {
      debugPrint('Error en registerWorker: $e');
      return {'success': false, 'message': 'Error al registrar trabajador: $e'};
    }
  }

  // Método para actualizar el estado de un trabajador en la API
  Future<bool> updateWorkerStatus(
      int workerId, String newStatus, BuildContext context,
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      var url = '/worker/$workerId';

      var statusToAPI = {
        'available': 'AVALIABLE',
        'assigned': 'ASSIGNED',
        'unavailable': 'UNAVALIABLE',
        'deactivated': 'DEACTIVATED',
        'incapacitated': 'DISABLE',
      };

      // Prepara el cuerpo de la solicitud
      Map<String, dynamic> body = {
        'status': statusToAPI[newStatus],
      };

      // Añadir fechas según el estado
      if (newStatus == 'incapacitated' &&
          startDate != null &&
          endDate != null) {
        body['dateDisableStart'] = DateFormat('yyyy-MM-dd').format(startDate);
        body['dateDisableEnd'] = DateFormat('yyyy-MM-dd').format(endDate);
      } else if (newStatus == 'deactivated' && startDate != null) {
        body['dateRetierment'] = DateFormat('yyyy-MM-dd').format(startDate);
      }

      var response = await _apiClient.patch(
        url,
        body: body,
      );

      debugPrint('API Response: ${response.statusCode} - ${response.body}');

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Error en updateWorkerStatus: $e');
      return false;
    }
  }

// Método completo para actualizar un trabajador
  Future<bool> updateWorker(Worker worker, BuildContext context) async {
    // debugPrint('Actualizando worker: ${worker.id}');
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final String token = authProvider.accessToken;

      if (token.isEmpty) {
        debugPrint('No hay token disponible');
        return false;
      }

      var url = '/worker/${worker.id}';

      // Mapear estados internos a la API
      var statusToAPI = {
        WorkerStatus.available: 'AVALIABLE',
        WorkerStatus.assigned: 'ASSIGNED',
        WorkerStatus.unavailable: 'UNAVALIABLE',
        WorkerStatus.deactivated: 'DEACTIVATED',
        WorkerStatus.incapacitated: 'DISABLE',
      };

      // Crear el cuerpo de la solicitud con los datos básicos
      Map<String, dynamic> body = {
        'name': worker.name,
        'dni': worker.document,
        'phone': worker.phone,
        'status': statusToAPI[worker.status] ?? 'AVALIABLE',
        'code': worker.code,
      };

      if (worker.idArea != 0) {
        body['id_area'] = worker.idArea;
      }

      body['failures'] = worker.failures;

      // Añadir fechas específicas según el estado
      if (worker.status == WorkerStatus.incapacitated) {
        if (worker.incapacityStartDate != null) {
          body['dateDisableStart'] =
              DateFormat('yyyy-MM-dd').format(worker.incapacityStartDate!);
        }

        if (worker.incapacityEndDate != null) {
          body['dateDisableEnd'] =
              DateFormat('yyyy-MM-dd').format(worker.incapacityEndDate!);
        }
      }

      if (worker.status == WorkerStatus.deactivated &&
          worker.deactivationDate != null) {
        body['dateRetierment'] =
            DateFormat('yyyy-MM-dd').format(worker.deactivationDate!);
      }

      var response = await _apiClient.patch(
        url,
        body: body,
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Error en updateWorker: $e');
      return false;
    }
  }
}
