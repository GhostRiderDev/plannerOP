import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/core/network/httpClient.dart';
import 'package:plannerop/utils/charts/chartData.dart';

class PaginatedOperationsService {
  final ApiClient _apiClient = ApiClient();

  /// Obtener operaciones paginadas por rango de fechas y estado
  Future<List<Operation>> fetchOperationsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    List<String>? statuses, // Lista de estados
    int page = 1,
    int limit = 100, // Por defecto traer muchos registros
  }) async {
    try {
      // Formatear las fechas para la API (YYYY-MM-DD)
      final String formattedStartDate =
          DateFormat('yyyy-MM-dd').format(startDate);

      // Construir parámetros de consulta
      Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        'dateStart': formattedStartDate,
        // 'dateEnd': formattedEndDate,
        'activatePaginated': 'false',
      };

      // Agregar parámetros de estado si se proporcionan
      if (statuses != null && statuses.isNotEmpty) {
        queryParams['status'] = statuses.join(',');
      }

      // Construir URL con parámetros como string
      String url = '/operation/paginated';
      if (queryParams.isNotEmpty) {
        url += '?';
        url += queryParams.entries
            .map((entry) => '${entry.key}=${entry.value}')
            .join('&');
      }

      final response = await _apiClient.get(
        url,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> items = jsonResponse['items'] ?? [];

        debugPrint('Received ${items.length} operations from API');

        return items
            .map((operationData) => _parseOperation(operationData))
            .toList();
      } else {
        debugPrint(
            'Error al obtener operaciones: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error en fetchOperationsByDateRange: $e');
      return [];
    }
  }

  Future<HourlyDistributionResponse?> fetchHourlyDistribution(
    DateTime date,
  ) async {
    try {
      // Formatear fecha para la API
      final formattedDate =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      final url =
          '/operation/analytics/worker-distribution?date=$formattedDate';

      debugPrint('Fetching hourly distribution from: $url');

      final response = await _apiClient.get(url);

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return HourlyDistributionResponse.fromJson(jsonData);
      } else {
        debugPrint(
            'Error al obtener distribución horaria: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error en fetchHourlyDistribution: $e');
      return null;
    }
  }

  Operation _parseOperation(Map<String, dynamic> operationData) {
    try {
      // Procesar grupos de trabajadores
      List<WorkerGroup> groups = [];
      if (operationData['workerGroups'] != null) {
        for (var groupData in operationData['workerGroups']) {
          final schedule = groupData['schedule'] ?? {};
          final workers = groupData['workers'] as List<dynamic>? ?? [];

          // Convertir workers a lista de Worker objects y IDs
          List<Worker> workersData = [];
          List<int> workerIds = [];

          for (var workerData in workers) {
            final workerId = workerData['id'] as int;
            workerIds.add(workerId);

            // Crear objeto Worker básico
            workersData.add(Worker(
              id: workerId,
              name: workerData['name'] ?? 'Trabajador #$workerId',
              area: operationData['jobArea']?['name'] ?? '',
              phone: workerData['phone'] ?? '',
              document: workerData['document'] ?? '',
              status: WorkerStatus.assigned,
              startDate: DateTime.now(),
              code: workerData['code'] ?? 'TR-$workerId',
            ));
          }

          groups.add(WorkerGroup(
            id: groupData['groupId']?.toString() ?? '',
            startTime: schedule['timeStart'],
            endTime: schedule['timeEnd'],
            startDate: schedule['dateStart'],
            endDate: schedule['dateEnd'],
            workers: workerIds,
            workersData: workersData,
            name: "Grupo ${groupData['groupId'] ?? ''}",
            serviceId: schedule['id_task'] ?? 0,
            serviceName: schedule['task'] ?? '',
            subTaskId: schedule['id_subtask'] ?? 0,
            subTaskName: schedule['subtask'] ?? '',
            tariffId: schedule['id_tariff'] ?? 0,
            idUnitOfMeasure: schedule['id_unit_of_measure'] ?? 0,
            unitOfMeasure: schedule['unit_of_measure'] ?? '',
          ));
        }
      }

      // Procesar encargados
      List<int> inChargers = [];
      if (operationData['inCharge'] != null) {
        for (var charger in operationData['inCharge']) {
          inChargers.add(charger['id'] as int);
        }
      }

      return Operation(
        id: operationData['id'],
        area: operationData['jobArea']?['name'] ?? 'Sin área',
        date: DateTime.parse(operationData['dateStart']),
        time: operationData['timeStart'] ?? '',
        status: operationData['status'] ?? 'PENDING',
        endTime: operationData['timeEnd'],
        endDate: operationData['dateEnd'] != null
            ? DateTime.parse(operationData['dateEnd'])
            : null,
        zone: operationData['zone'] ?? 0,
        motorship: operationData['motorShip'],
        userId: operationData['id_user'] ?? 0,
        areaId: operationData['jobArea']?['id'] ?? 0,
        clientId: operationData['id_client'] ?? 0,
        inChagers: inChargers,
        groups: groups,
        id_clientProgramming: operationData['id_clientProgramming'],
        createdAt: DateTime.parse(operationData['createAt']),
        updatedAt: DateTime.parse(operationData['updateAt']),
      );
    } catch (e) {
      debugPrint('Error al parsear operación: $e');
      debugPrint('Datos de operación problemáticos: $operationData');
      rethrow;
    }
  }
}
