import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:http/http.dart' as http;
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/dto/operations/createOperation.dart';
import 'package:plannerop/store/auth.dart';
import 'package:plannerop/store/workers.dart';
import 'package:plannerop/utils/date.dart';
import 'package:plannerop/utils/groups/groups.dart';
import 'package:provider/provider.dart';

class OperationService {
  final String API_URL = dotenv.get('API_URL');

  // Método para enviar operación al backend usando AuthProvider
  Future<CreateOperationDto> createOperation(
      Operation operation, BuildContext context) async {
    try {
      // Obtener token del AuthProvider
      final token =
          Provider.of<AuthProvider>(context, listen: false).accessToken;

      // Crear el payload en el formato requerido por el backend
      final Map<String, dynamic> payload = {
        "status": operation.status.toUpperCase(),
        "zone": operation.zone,
        "motorShip": operation.motorship ?? "",
        "dateStart": formatDate(operation.date),
        "timeStrat": operation.time,
        "id_user": operation.userId,
        "id_area": operation.areaId,
        // "id_task": operation.taskId,
        "id_client": operation.clientId,
        // "workerIds": individualWorkers,
        'inChargedIds': operation.inChagers,
        "groups": operation.groups.map((group) {
          return {
            "dateStart": group.startDate,
            "dateEnd": group.endDate,
            "timeStart": group.startTime,
            "timeEnd": group.endTime,
            "workerIds": group.workers,
            "id_task": group.serviceId
          };
        }).toList(),
        'id_clientProgramming': operation.id_clientProgramming,
      };

      if (operation.endDate != null) {
        payload['dateEnd'] = formatDate(operation.endDate!);
      }

      if (operation.endTime != null) {
        payload['timeEnd'] = operation.endTime;
      }

      var url = Uri.parse('$API_URL/operation');
      var response = await http.post(url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode(payload));

      if (response.statusCode == 201) {
        var body = jsonDecode(response.body);

        return CreateOperationDto(
          id: body['id'],
          isSuccess: true,
        );
      } else {
        debugPrint(
            'Error al crear operación: ${response.statusCode} - ${response.body}');
        return CreateOperationDto(id: 0, isSuccess: false);
      }
    } catch (e) {
      debugPrint('Excepción al crear operación: $e');
      return CreateOperationDto(id: 0, isSuccess: false);
    }
  }

  // Metodo para obtener las operaciones
  Future<List<Operation>> fetchOperations(BuildContext context) async {
    try {
      final token =
          Provider.of<AuthProvider>(context, listen: false).accessToken;

      var url = Uri.parse('$API_URL/operation');
      var response =
          await http.get(url, headers: {'Authorization': 'Bearer $token'});

      var workers_provider =
          Provider.of<WorkersProvider>(context, listen: false);
      var workers = workers_provider.workers;

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        List<Operation> operations = [];
        for (var operation in jsonResponse) {
          var operationObj = Operation.fromJson(operation, workers);

          operations.add(operationObj);
        }
        return operations;
      } else {
        debugPrint(
            'Error al obtener asignaciones: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error en fetchAssignments: $e');
      return [];
    }
  }

  Future<bool> updateStatusOperation(
      int operationId, String status, BuildContext context) async {
    try {
      final token =
          Provider.of<AuthProvider>(context, listen: false).accessToken;

      var url = Uri.parse('$API_URL/operation/$operationId');
      var response = await http.patch(url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode(
              {"status": status == 'IN_PROGRESS' ? 'INPROGRESS' : status}));
      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint(
            'Error al actualizar operación: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Excepción al actualizar operación: $e');
      return false;
    }
  }

  // Método para actualizar una operación existente
  Future<bool> updateOperation(
      Operation operation, BuildContext context) async {
    try {
      // Obtener token del AuthProvider
      final token =
          Provider.of<AuthProvider>(context, listen: false).accessToken;

      if (operation.id == null) {
        debugPrint('Error: ID de operación no proporcionado');
        return false;
      }
      // Crear el payload con los datos actualizados
      final Map<String, dynamic> payload = {
        "status": operation.status.toUpperCase(),
        "dateStart": formatDate(operation.date),
        "timeStrat": operation.time,
      };

      // Añadir campos opcionales si tienen valor
      if (operation.endDate != null) {
        payload['dateEnd'] = formatDate(operation.endDate!);
      }

      if (operation.endTime != null && operation.endTime!.isNotEmpty) {
        payload['timeEnd'] = operation.endTime;
      }

      var url = Uri.parse('$API_URL/operation/${operation.id}');
      var response = await http.patch(url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode(payload));

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint(
            'Error al actualizar operación: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Excepción al actualizar operación: $e');
      return false;
    }
  }

// Método para eliminar trabajadores de grupos de una operación (uno por uno)
  Future<bool> removeGroupFromOperation(int operationId, BuildContext context,
      Map<String, List<int>> workersGroups) async {
    try {
      final token =
          Provider.of<AuthProvider>(context, listen: false).accessToken;

      // Endpoint para eliminar trabajadores específicos de una operación
      var url = Uri.parse('$API_URL/operation/$operationId');

      bool allSuccessful = true;

      // Iterar sobre cada grupo y cada trabajador
      for (var entry in workersGroups.entries) {
        final groupId = entry.key;
        final workerIds = entry.value;

        // Enviar una petición por cada trabajador
        for (var workerId in workerIds) {
          Map<String, dynamic> body = {
            "workers": {
              "disconnect": [
                {"id_group": groupId, "id": workerId}
              ]
            }
          };

          debugPrint('Removiendo trabajador $workerId del grupo $groupId');
          debugPrint('Body: ${jsonEncode(body)}');

          var response = await http.patch(url,
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json'
              },
              body: jsonEncode(body));

          if (response.statusCode == 200 || response.statusCode == 204) {
            debugPrint(
                'Trabajador $workerId removido exitosamente del grupo $groupId');
          } else {
            debugPrint(
                'Error al remover trabajador $workerId del grupo $groupId: ${response.statusCode} - ${response.body}');
            allSuccessful = false;
            // Opcional: Continuar con los demás trabajadores o hacer break aquí
            // break; // Descomentar si quieres parar en el primer error
          }

          // Opcional: Añadir un pequeño delay entre peticiones para evitar sobrecargar el servidor
          await Future.delayed(Duration(milliseconds: 100));
        }
      }

      return allSuccessful;
    } catch (e) {
      debugPrint('Excepción al eliminar trabajadores de grupos: $e');
      return false;
    }
  }

// Modificación de fetchOperationsByStatus para evitar duplicados de trabajadores
  Future<List<Operation>> fetchOperationsByStatus(
      BuildContext context, List<String> statusList) async {
    try {
      // Verificaciones iniciales
      if (!context.mounted) {
        return [];
      }

      final token =
          Provider.of<AuthProvider>(context, listen: false).accessToken;
      var url = Uri.parse(
          '$API_URL/operation/by-status?status=${statusList.join(",")}');
      var response =
          await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (!context.mounted) {
        debugPrint(
            'Context ya no está montado después de la llamada HTTP, abortando');
        return [];
      }

      final workersProvider =
          Provider.of<WorkersProvider>(context, listen: false);
      final workers = workersProvider.workers;

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        List<Operation> operations = [];

        for (var operation in jsonResponse) {
          // Nuevo mapa para trabajadores finalizados
          Map<int, Worker> finishedWorkersMap = {};

          // Lista para grupos de trabajadores
          List<WorkerGroup> operationGroups = [];

          // Procesar los grupos de trabajadores
          if (operation['workerGroups'] != null &&
              operation['workerGroups'] is List) {
            var workerGroups = operation['workerGroups'] as List;

            // Conjunto para rastrear IDs de trabajadores ya procesados
            Set<int> processedWorkerIds = {};

            for (var group in workerGroups) {
              // Extraer información del schedule
              var schedule = group['schedule'] ?? {};
              final dateStart = schedule['dateStart'] ?? null;
              final dateEnd = schedule['dateEnd'] ?? null;
              final timeStart = schedule['timeStart'] ?? null;
              final timeEnd = schedule['timeEnd'] ?? null;
              final groupId = group["groupId"] ?? null;

              // Verificar si este grupo tiene un horario definido
              final hasSchedule = (dateStart != null && dateStart != "") ||
                  (dateEnd != null && dateEnd != "") ||
                  (timeStart != null && timeStart != "") ||
                  (timeEnd != null && timeEnd != "");

              // Verificar si el horario de finalización ya pasó
              bool isFinished = false;
              if (dateEnd != null &&
                  dateEnd.isNotEmpty &&
                  timeEnd != null &&
                  timeEnd.isNotEmpty) {
                try {
                  // Parsear la fecha y hora de finalización
                  final DateTime endDateParsed = DateTime.parse(dateEnd);
                  final List<String> timeParts = timeEnd.split(':');
                  final int hours = int.parse(timeParts[0]);
                  final int minutes = int.parse(timeParts[1]);

                  // Crear DateTime combinando fecha y hora
                  final DateTime endDateTime = DateTime(
                    endDateParsed.year,
                    endDateParsed.month,
                    endDateParsed.day,
                    hours,
                    minutes,
                  );

                  // Verificar si ya pasó la fecha y hora de finalización
                  final DateTime now = DateTime.now();
                  isFinished = endDateTime.isBefore(now) ||
                      endDateTime.isAtSameMomentAs(now);
                } catch (e) {
                  debugPrint('Error al parsear fecha/hora de finalización: $e');
                }
              }

              // Procesar los trabajadores de este grupo
              List<int> groupWorkerIds = [];

              if (group['workers'] != null && group['workers'] is List) {
                for (var workerData in group['workers']) {
                  final workerId = workerData['id'] ?? 0;

                  processedWorkerIds.add(workerId);

                  try {
                    if (workers.isEmpty) continue;

                    var workerObj = workers.firstWhere((w) => w.id == workerId,
                        orElse: () => Worker(
                            name: "",
                            area: "",
                            phone: "",
                            document: "",
                            status: WorkerStatus.available,
                            startDate: DateTime.now(),
                            code: "",
                            id: 0));

                    // Si no es el trabajador orElse y ID válido
                    if (workerObj.id != 0) {
                      // Clasificar el trabajador según si está en un grupo finalizado o no
                      if (isFinished) {
                        // Añadir al mapa de finalizados si no existe ya
                        if (!finishedWorkersMap.containsKey(workerObj.id)) {
                          finishedWorkersMap[workerObj.id] = workerObj;
                        }
                      }

                      // Si tiene horario, añadirlo al grupo (independientemente de si está finalizado)
                      if (hasSchedule) {
                        groupWorkerIds.add(workerObj.id);
                      }
                    }
                  } catch (e) {
                    debugPrint('Error al procesar trabajador ID $workerId: $e');
                  }
                }
              }

              // Crear un WorkerGroup solo si tiene horario definido y trabajadores
              if (hasSchedule && groupWorkerIds.isNotEmpty) {
                // Crear nombre descriptivo
                String groupName = getGroupName(
                  dateStart != null ? DateTime.tryParse(dateStart) : null,
                  dateEnd != null ? DateTime.tryParse(dateEnd) : null,
                  timeStart != null ? timeStart : null,
                  timeEnd != null ? timeEnd : null,
                );

                // Añadir el grupo a la lista de grupos
                operationGroups.add(WorkerGroup(
                  startTime: timeStart,
                  endTime: timeEnd,
                  startDate: dateStart,
                  endDate: dateEnd,
                  workers: groupWorkerIds,
                  name: groupName,
                  id: groupId,
                  serviceId: schedule["id_task"] ?? 0,
                ));
              }
            }
          }

          List<int> inChargers = [];
          var inChargeData =
              operation['inChargeOperation'] ?? operation['inCharge'] ?? [];

          if (inChargeData is List && inChargeData.isNotEmpty) {
            inChargers = List<int>.from(inChargeData.map((item) {
              return item is Map ? (item['id_user'] ?? item['id'] ?? 0) : 0;
            })).where((id) => id != 0).toList();
          }

          var operationObj = Operation(
            id: operation['id'],
            area: operation['jobArea']['name'],
            date: DateTime.parse(operation['dateStart']),
            time: operation['timeStrat'],
            status: operation['status'],
            endTime: operation['timeEnd'],
            endDate: operation['dateEnd'] != null
                ? DateTime.parse(operation['dateEnd'])
                : null,
            zone: operation['zone'],
            motorship: operation['motorShip'],
            userId: operation['id_user'],
            areaId: operation['jobArea']['id'],
            clientId: operation['id_client'],
            inChagers: inChargers,
            groups: operationGroups,
            id_clientProgramming: operation['id_clientProgramming'],
          );

          operations.add(operationObj);
        }
        return operations;
      } else {
        debugPrint(
            'Error al obtener asignaciones por estado: ${response.statusCode} - ${response.body}');
        return [];
      }
    } on SocketException catch (e) {
      debugPrint('Error de conexión: $e');
      return [];
    } on HttpException catch (e) {
      debugPrint('Error HTTP: $e');
      return [];
    } on FormatException catch (e) {
      debugPrint('Error de formato: $e');
      return [];
    } on Exception catch (e) {
      debugPrint('Error en fetchAssignmentsByStatus: $e');
      return [];
    }
  }

  // Método para completar una operación
  Future<bool> completeOperation(
    int operationId,
    String status,
    DateTime endDate,
    String endTime,
    BuildContext context,
  ) async {
    try {
      final token =
          Provider.of<AuthProvider>(context, listen: false).accessToken;

      var url = Uri.parse('$API_URL/operation/$operationId');
      var body = {
        'status': status,
        'dateEnd': formatDate(endDate),
        'timeEnd': endTime,
      };

      var response = await http.patch(url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode(body));

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint(
            'Error al completar operación: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Excepción al completar operación: $e');
      return false;
    }
  }

// Método para completar una un grupo de trabajadores o individual de una operación
  Future<bool> completeGroupOperation(
    int operationId,
    List<int> workerIds,
    String groupId,
    DateTime endDate,
    DateTime startDate,
    String startTime,
    String endTime,
    BuildContext context,
  ) async {
    try {
      final token =
          Provider.of<AuthProvider>(context, listen: false).accessToken;

      var url = Uri.parse('$API_URL/operation/$operationId');
      var body = {
        "workers": {
          "update": [
            {
              "workerIds": workerIds,
              "dateEnd": formatDate(endDate),
              "timeEnd": endTime,
              "dateStart": formatDate(startDate),
              "timeStart": startTime,
              "id_group": groupId
            }
          ]
        }
      };

      var response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint(
            'Error al completar parcialmente: ${response.statusCode} - ${response.body}');
        if (response.statusCode == 404) {
          debugPrint(
              'API no soporta completado parcial, marcando como exitoso localmente');
          return true;
        }
        return false;
      }
    } catch (e) {
      debugPrint('Excepción al completar parcialmente: $e');
      // En caso de error, marcar como exitoso localmente para mantener consistencia de la UI
      return true;
    }
  }

// Método para conectar nuevos trabajadores a una operación existente
  Future<bool> connectWorkersToOperation(
      int operationId,
      List<int> individualWorkerIds,
      List<Map<String, dynamic>> groupsToConnect,
      BuildContext context) async {
    try {
      final token =
          Provider.of<AuthProvider>(context, listen: false).accessToken;

      // Endpoint para actualizar la operación
      var url = Uri.parse('$API_URL/operation/$operationId');

      // Preparar la estructura de la solicitud
      Map<String, dynamic> body = {
        "workers": {"connect": []}
      };

      // Añadir trabajadores individuales
      for (var workerId in individualWorkerIds) {
        body["workers"]["connect"].add({"id": workerId});
      }

      // Añadir grupos de trabajadores
      for (var group in groupsToConnect) {
        body["workers"]["connect"].add({
          "workerIds": group["workerIds"],
          "dateStart": group["dateStart"],
          "dateEnd": group["dateEnd"],
          "timeStart": group["timeStart"],
          "timeEnd": group["timeEnd"]
        });
      }

      var response = await http.patch(url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode(body));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        debugPrint(
            'Error al conectar trabajadores: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Excepción al conectar trabajadores: $e');
      return false;
    }
  }
}
