import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/store/auth.dart';
import 'package:plannerop/utils/charts/chartData.dart';
import 'package:provider/provider.dart';

class PaginatedOperationsService {
  final String API_URL = dotenv.get('API_URL');

  /// Obtener operaciones paginadas por rango de fechas y estado
  Future<List<Operation>> fetchOperationsByDateRange(
    BuildContext context,
    DateTime startDate,
    DateTime endDate, {
    List<String>? statuses, // Lista de estados
    int page = 1,
    int limit = 100, // Por defecto traer muchos registros
  }) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final String token = authProvider.accessToken;

      if (token.isEmpty) {
        debugPrint('No hay token disponible');
        return [];
      }

      // Formatear las fechas para la API (YYYY-MM-DD)
      final String formattedStartDate =
          DateFormat('yyyy-MM-dd').format(startDate);
      final String formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);

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
        // Enviar cada estado como parámetro separado o como string separado por comas
        // Opción 1: Como string separado por comas
        queryParams['status'] = statuses.join(',');

        // Opción 2: Si la API espera múltiples parámetros status
        // for (int i = 0; i < statuses.length; i++) {
        //   queryParams['status[$i]'] = statuses[i];
        // }
      }

      // Construir URI con parámetros
      final Uri url = Uri.parse('$API_URL/operation/paginated').replace(
        queryParameters: queryParams,
      );

      debugPrint('Fetching operations: $url');
      debugPrint('Query parameters: $queryParams');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> items = jsonResponse['items'] ?? [];

        debugPrint('Received ${items.length} operations from API');

        return items
            .map((operationData) => _parseOperation(operationData))
            .toList();
      } else if (response.statusCode == 401) {
        authProvider.logout();
        throw Exception('Token no válido');
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
    BuildContext context,
    DateTime date,
  ) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.accessToken;

      if (token == null) {
        debugPrint('Token no disponible');
        return null;
      }

      // Formatear fecha para la API
      final formattedDate =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      final url = Uri.parse(
          '${API_URL}/operation/analytics/worker-distribution?date=$formattedDate');

      debugPrint('Fetching hourly distribution from: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

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
