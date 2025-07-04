import 'package:flutter/material.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/store/operations.dart';

import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/operations/edit/editOperationForm.dart';
import 'package:provider/provider.dart';

// Eliminar un grupo de trabajadores
void deleteWorkerGroup({
  required BuildContext context,
  required WorkerGroup group,
  required int assignmentId,
  required List<WorkerGroup> selectedGroups,
  required List<Worker> selectedWorkers,
  required bool inEditMode,
  required List<Worker> deletedWorkers,
  required Function(List<Worker>)? onDeletedWorkersChanged,
  required Function(List<Worker>) onWorkersChanged,
  required Function(List<WorkerGroup>)? onGroupsChanged,
  required VoidCallback onRemoveFromLocal,
  bool preserveIndividualWorkers = false,
}) {
  // 1. Eliminar el grupo de la lista de grupos
  selectedGroups.removeWhere((g) => g.id == group.id);
  onRemoveFromLocal();

  // 2. NO eliminar trabajadores - simplemente mantener la lista tal cual
  // Los trabajadores que estaban en el grupo ahora serán individuales

  // 3. Sincronizar con el backend si estamos en modo edición
  if (inEditMode) {
    _syncGroupDeletionWithBackend(context, group, assignmentId);
  }

  // 4. Notificar cambios en los grupos (pero no en trabajadores)
  if (onGroupsChanged != null) {
    onGroupsChanged(selectedGroups);
  }

  // 5. Mostrar mensaje de confirmación
  showSuccessToast(context, "Grupo eliminado correctamente");
}

// Eliminar un trabajador individual
void removeWorker({
  required BuildContext context,
  required Worker worker,
  required int index,
  required List<Worker> selectedWorkers,
  required List<WorkerGroup> selectedGroups,
  required WorkerGroup? workerGroup,
  required int? assignmentId,
  required bool inEditMode,
  required List<Worker> deletedWorkers,
  required Function(List<Worker>)? onDeletedWorkersChanged,
  required Function(List<Worker>) onWorkersChanged,
  required Function(List<WorkerGroup>)? onGroupsChanged,
}) {
  // Si estamos en modo edición, llamar a la API
  if (inEditMode && assignmentId != null) {
    final assignmentsProvider =
        Provider.of<OperationsProvider>(context, listen: false);

    Map<String, List<int>> data = {
      workerGroup!.id.toString(): [worker.id],
    };

    assignmentsProvider.removeGroupFromOperation(
      data,
      context,
      assignmentId,
    );

    showSuccessToast(context, "Trabajador eliminado");
  }

  final updatedList = List<Worker>.from(selectedWorkers);
  final removedWorker = updatedList.removeAt(index);

  // Si es parte de un grupo, actualizar el grupo
  if (workerGroup != null) {
    // Quitar el trabajador del grupo
    workerGroup.workers.removeWhere((wId) => wId == worker.id);

    // Si el grupo queda vacío, eliminar el grupo
    if (workerGroup.workers.isEmpty) {
      selectedGroups.removeWhere((g) => g.id == workerGroup.id);

      // Notificar cambio en grupos
      if (onGroupsChanged != null) {
        onGroupsChanged(selectedGroups);
      }
    }
  }

  // En modo edición, registrar el trabajador eliminado
  if (inEditMode && onDeletedWorkersChanged != null) {
    List<Worker> updatedDeletedWorkers = List.from(deletedWorkers);

    // Solo agregar si no está ya en la lista
    if (!updatedDeletedWorkers.any((w) => w.id == removedWorker.id)) {
      updatedDeletedWorkers.add(removedWorker);
      onDeletedWorkersChanged(updatedDeletedWorkers);
    }
  }

  onWorkersChanged(updatedList);
}

// Sincronizar la eliminación de un grupo con el backend
void _syncGroupDeletionWithBackend(
  BuildContext context,
  WorkerGroup group,
  int assignmentId,
) {
  // Obtener el provider de asignaciones
  final assignmentsProvider =
      Provider.of<OperationsProvider>(context, listen: false);

  // Buscar el contexto del formulario de edición
  BuildContext? editFormContext =
      context.findAncestorStateOfType<EditOperationFormState>()?.context;

  if (editFormContext != null) {
    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Crear los datos del grupo a eliminar
    Map<String, List<int>> data = {
      group.id.toString(): group.workers,
    };

    // Llamar al servicio de backend para eliminar el grupo
    try {
      assignmentsProvider
          .removeGroupFromOperation(data, context, assignmentId)
          .then((_) {
        // Cerrar el indicador de carga
        Navigator.of(context, rootNavigator: true).pop();
        // Mostrar mensaje de éxito
        showSuccessToast(context, "Grupo eliminado correctamente");
      }).catchError((error) {
        // Cerrar el indicador de carga
        Navigator.of(context, rootNavigator: true).pop();
        // Mostrar mensaje de error
        showErrorToast(context, "Error al eliminar el grupo: $error");
      });
    } catch (e) {
      // Cerrar el indicador de carga
      Navigator.of(context, rootNavigator: true).pop();
      // Mostrar mensaje de error
      showErrorToast(context, "Error al eliminar el grupo: $e");
    }
  }
}
