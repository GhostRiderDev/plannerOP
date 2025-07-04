import 'package:flutter/material.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/store/operations.dart';

import 'package:plannerop/store/workers.dart';
import 'package:plannerop/widgets/operations/add/addOperationDialog.dart';
import 'package:provider/provider.dart';

class WorkerHoursResult {
  final Map<int, double> hoursMap;
  final List<Worker> filteredWorkers;

  WorkerHoursResult(this.hoursMap, this.filteredWorkers);
}

Future<WorkerHoursResult> calculateWorkerHours(
    BuildContext context, List<Worker> selectedWorkers) async {
  final assignmentsProvider =
      Provider.of<OperationsProvider>(context, listen: false);
  final workersProvider = Provider.of<WorkersProvider>(context, listen: false);

  final completedAssignments = assignmentsProvider.completedOperations
      .where((assignment) =>
          assignment.date.isAfter(DateTime.now().subtract(Duration(days: 2))))
      .toList();

  final availableWorkers = workersProvider.workersWithoutRetiredAndDisabled;

  // Mapa para acumular las horas por trabajador
  Map<int, double> hoursMap = {};

  // Procesar todas las asignaciones completadas
  for (var assignment in completedAssignments) {
    // Ignorar asignaciones futuras o de hace más de un día
    if (assignment.date.isAfter(DateTime.now()) ||
        assignment.date.isBefore(DateTime.now().subtract(Duration(days: 1)))) {
      continue;
    }

    if (assignment.endDate != null && assignment.endTime != null) {
      // final double assignmentHours = calculateAssignmentDuration(assignment);

      // Asignar estas horas a cada trabajador de la operación
      // for (var worker in assignment.workers) {
      //   hoursMap[worker.id] = (hoursMap[worker.id] ?? 0) + assignmentHours;
      // }
    }
  }

  return WorkerHoursResult(hoursMap, availableWorkers);
}

double calculateAssignmentDuration(Operation assignment) {
  if (assignment.endDate == null || assignment.endTime == null) {
    return 0.0;
  }

  // Obtener hora de inicio
  final startTimeParts = assignment.time.split(':');
  final startDateTime = DateTime(
    assignment.date.year,
    assignment.date.month,
    assignment.date.day,
    int.parse(startTimeParts[0]),
    int.parse(startTimeParts[1]),
  );

  // Obtener hora de fin
  final endTimeParts = assignment.endTime!.split(':');
  final endDateTime = DateTime(
    assignment.endDate!.year,
    assignment.endDate!.month,
    assignment.endDate!.day,
    int.parse(endTimeParts[0]),
    int.parse(endTimeParts[1]),
  );

  // Calcular diferencia en horas
  final difference = endDateTime.difference(startDateTime);
  final fmtDiff = difference.inMinutes / 60.0;
  final unsignedDiif = fmtDiff.abs();
  return unsignedDiif > 0 ? unsignedDiif : 0.0;
}

String getHoursText(int workerId, Map<int, double> workerHours) {
  final hours = workerHours[workerId] ?? 0.0;
  return '${hours.toStringAsFixed(1)} horas trabajadas';
}

bool isWorkerAvailable(int workerId, Map<int, double> workerHours) {
  final hours = workerHours[workerId] ?? 0.0;
  return hours < 12.0;
}

void notifyDialogAboutWorkerChanges(BuildContext context) {
  final addAssignmentDialog =
      context.findAncestorStateOfType<AddOperationDialogState>();

  if (addAssignmentDialog != null) {
    addAssignmentDialog.resetGroupScheduleLocks();
  }
}
