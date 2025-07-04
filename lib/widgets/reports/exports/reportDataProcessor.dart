import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/mapper/operation.dart';
import 'package:plannerop/store/clients.dart';
import 'package:plannerop/store/chargersOp.dart';
import 'package:plannerop/store/task.dart';
import 'package:plannerop/store/workers.dart';
import 'package:plannerop/widgets/reports/exports/WorkerReportRow.dart';
import 'package:provider/provider.dart';

class ReportDataProcessor {
  static Future<ReportData> processOperations(
    List<Operation> operations,
    String reportTitle,
    String dateRange,
    BuildContext context,
  ) async {
    final List<WorkerReportRow> workerRows = [];
    final List<GeneralReportRow> generalRows = [];

    // Obtener providers necesarios
    final clientsProvider =
        Provider.of<ClientsProvider>(context, listen: false);
    final chargersProvider =
        Provider.of<ChargersOpProvider>(context, listen: false);
    final tasksProvider = Provider.of<TasksProvider>(context, listen: false);
    final workersProvider =
        Provider.of<WorkersProvider>(context, listen: false);

    // Estadísticas
    final Map<String, int> statistics = {
      'total': operations.length,
      'completed': 0,
      'inProgress': 0,
      'pending': 0,
      'canceled': 0,
      'totalWorkers': 0,
    };

    for (final operation in operations) {
      // Obtener información adicional usando providers
      final clientName = _getClientName(clientsProvider, operation.clientId);
      final supervisorNames =
          _getSupervisorNames(chargersProvider, operation.inChagers);
      final taskName = await _getTaskName(tasksProvider, operation, context);

      // Actualizar estadísticas de estado
      switch (operation.status.toUpperCase()) {
        case 'COMPLETED':
          statistics['completed'] = statistics['completed']! + 1;
          break;
        case 'INPROGRESS':
          statistics['inProgress'] = statistics['inProgress']! + 1;
          break;
        case 'PENDING':
          statistics['pending'] = statistics['pending']! + 1;
          break;
        case 'CANCELED':
          statistics['canceled'] = statistics['canceled']! + 1;
          break;
      }

      if (operation.groups.isEmpty) {
        // Operación sin grupos
        final generalRow = _createGeneralRowFromOperation(
          operation,
          0,
          0,
          clientName,
          supervisorNames,
          taskName,
        );
        generalRows.add(generalRow);

        final workerRow = _createWorkerRowFromOperation(
          operation,
          'Sin asignar',
          '-',
          'N/A',
          clientName,
          supervisorNames,
          taskName,
        );
        workerRows.add(workerRow);
      } else {
        // Procesar cada grupo
        int totalWorkersInOperation = 0;
        int totalShiftsInOperation = operation.groups.length;

        for (int groupIndex = 0;
            groupIndex < operation.groups.length;
            groupIndex++) {
          final group = operation.groups[groupIndex];
          totalWorkersInOperation += group.workers.length;

          final shiftName = 'Turno ${groupIndex + 1}';

          if (group.workers.isEmpty) {
            // Grupo sin trabajadores
            final workerRow = _createWorkerRowFromGroup(
              operation,
              group,
              shiftName,
              'Sin asignar',
              '-',
              clientName,
              supervisorNames,
              taskName,
            );
            workerRows.add(workerRow);
          } else {
            // Procesar cada trabajador del grupo
            for (final workerId in group.workers) {
              String workerName = 'Trabajador #$workerId';
              String workerDni =
                  workersProvider.getWorkerById(workerId).document ?? '-';

              // Buscar datos del trabajador
              if (group.workersData != null && group.workersData!.isNotEmpty) {
                final workerData = group.workersData!
                    .where((w) => w.id == workerId)
                    .firstOrNull;

                if (workerData != null) {
                  workerName = workerData.name;
                }
              }

              final workerRow = _createWorkerRowFromGroup(
                operation,
                group,
                shiftName,
                workerName,
                workerDni,
                clientName,
                supervisorNames,
                taskName,
              );
              workerRows.add(workerRow);
            }
          }
        }

        // Crear fila general para la operación
        final generalRow = _createGeneralRowFromOperation(
          operation,
          totalWorkersInOperation,
          totalShiftsInOperation,
          clientName,
          supervisorNames,
          taskName,
        );
        generalRows.add(generalRow);

        statistics['totalWorkers'] =
            statistics['totalWorkers']! + totalWorkersInOperation;
      }
    }

    return ReportData(
      workerRows: workerRows,
      generalRows: generalRows,
      reportTitle: reportTitle,
      dateRange: dateRange,
      statistics: statistics,
    );
  }

  // Métodos auxiliares para obtener información de los providers
  static String _getClientName(ClientsProvider clientsProvider, int clientId) {
    try {
      final client = clientsProvider.getClientById(clientId);
      return client.name;
    } catch (e) {
      return 'Cliente desconocido';
    }
  }

  static String _getSupervisorNames(
      ChargersOpProvider chargersProvider, List<int> chargerIds) {
    try {
      final supervisorNames = <String>[];
      for (final chargerId in chargerIds) {
        final charger = chargersProvider.chargers
            .where((c) => c.id == chargerId)
            .firstOrNull;
        if (charger != null) {
          supervisorNames.add(charger.name);
        }
      }
      return supervisorNames.isNotEmpty
          ? supervisorNames.join(', ')
          : 'Sin supervisor';
    } catch (e) {
      return 'Supervisor desconocido';
    }
  }

  static Future<String> _getTaskName(TasksProvider tasksProvider,
      Operation operation, BuildContext context) async {
    try {
      // Intentar obtener el nombre de la tarea del primer grupo si existe
      if (operation.groups.isNotEmpty) {
        final firstGroup = operation.groups.first;
        if (firstGroup.serviceId > 0) {
          return await tasksProvider.getTaskNameByIdServiceAsync(
              firstGroup.serviceId, context);
        }
      }
      return 'Tarea no especificada';
    } catch (e) {
      return 'Tarea desconocida';
    }
  }

  static WorkerReportRow _createWorkerRowFromOperation(
    Operation operation,
    String workerName,
    String workerDni,
    String shiftName,
    String clientName,
    String supervisorNames,
    String taskName,
  ) {
    return WorkerReportRow(
      operationId: operation.id!,
      status: getOperationStatusText(operation.status),
      area: operation.area,
      client: clientName,
      supervisors: supervisorNames,
      startDate: DateFormat('dd/MM/yyyy').format(operation.date),
      startTime: operation.time,
      endDate: operation.endDate != null
          ? DateFormat('dd/MM/yyyy').format(operation.endDate!)
          : 'N/A',
      endTime: operation.endTime ?? 'N/A',
      workedHours: _calculateWorkedHours(operation),
      vessel: operation.motorship ?? 'N/A',
      task: taskName,
      shift: shiftName,
      workerDni: workerDni,
      workerName: workerName,
    );
  }

  static WorkerReportRow _createWorkerRowFromGroup(
    Operation operation,
    WorkerGroup group,
    String shiftName,
    String workerName,
    String workerDni,
    String clientName,
    String supervisorNames,
    String taskName,
  ) {
    return WorkerReportRow(
      operationId: operation.id!,
      status: getOperationStatusText(operation.status),
      area: operation.area,
      client: clientName,
      supervisors: supervisorNames,
      startDate: group.startDate != null && group.startDate!.isNotEmpty
          ? DateFormat('dd/MM/yyyy').format(DateTime.parse(group.startDate!))
          : DateFormat('dd/MM/yyyy').format(operation.date),
      startTime: group.startTime ?? operation.time,
      endDate: group.endDate != null && group.endDate!.isNotEmpty
          ? DateFormat('dd/MM/yyyy').format(DateTime.parse(group.endDate!))
          : (operation.endDate != null
              ? DateFormat('dd/MM/yyyy').format(operation.endDate!)
              : 'N/A'),
      endTime: group.endTime ?? operation.endTime ?? 'N/A',
      workedHours: _calculateGroupWorkedHours(operation, group),
      vessel: operation.motorship ?? 'N/A',
      task: taskName,
      shift: shiftName,
      workerDni: workerDni,
      workerName: workerName,
    );
  }

  static GeneralReportRow _createGeneralRowFromOperation(
    Operation operation,
    int totalWorkers,
    int totalShifts,
    String clientName,
    String supervisorNames,
    String taskName,
  ) {
    return GeneralReportRow(
      operationId: operation.id!,
      status: getOperationStatusText(operation.status),
      area: operation.area,
      client: clientName,
      supervisors: supervisorNames,
      startDate: DateFormat('dd/MM/yyyy').format(operation.date),
      startTime: operation.time,
      endDate: operation.endDate != null
          ? DateFormat('dd/MM/yyyy').format(operation.endDate!)
          : 'N/A',
      endTime: operation.endTime ?? 'N/A',
      workedHours: _calculateWorkedHours(operation),
      vessel: operation.motorship ?? 'N/A',
      task: taskName,
      totalWorkers: totalWorkers,
      totalShifts: totalShifts,
    );
  }

  static String _calculateWorkedHours(Operation operation) {
    if (operation.endDate == null || operation.endTime == null) {
      return 'N/A';
    }

    try {
      final startDateTime = _parseDateTime(operation.date, operation.time);
      final endDateTime =
          _parseDateTime(operation.endDate!, operation.endTime!);

      final difference = endDateTime.difference(startDateTime);
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;

      return '${hours}h ${minutes}m';
    } catch (e) {
      return 'N/A';
    }
  }

  static String _calculateGroupWorkedHours(
      Operation operation, WorkerGroup group) {
    DateTime startDate;
    String startTime;
    DateTime? endDate;
    String? endTime;

    // Usar fechas del grupo si están disponibles, si no usar las de la operación
    if (group.startDate != null && group.startDate!.isNotEmpty) {
      try {
        startDate = DateTime.parse(group.startDate!);
      } catch (e) {
        startDate = operation.date;
      }
    } else {
      startDate = operation.date;
    }

    startTime = group.startTime ?? operation.time;

    if (group.endDate != null && group.endDate!.isNotEmpty) {
      try {
        endDate = DateTime.parse(group.endDate!);
      } catch (e) {
        endDate = operation.endDate;
      }
    } else {
      endDate = operation.endDate;
    }

    endTime = group.endTime ?? operation.endTime;

    if (endDate == null || endTime == null) {
      return 'N/A';
    }

    try {
      final startDateTime = _parseDateTime(startDate, startTime);
      final endDateTime = _parseDateTime(endDate, endTime);

      final difference = endDateTime.difference(startDateTime);
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;

      return '${hours}h ${minutes}m';
    } catch (e) {
      return 'N/A';
    }
  }

  static DateTime _parseDateTime(DateTime date, String time) {
    if (time.isEmpty) {
      return date; // Si no hay hora, solo devolvemos la fecha
    }

    final timeParts = time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;

    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}
