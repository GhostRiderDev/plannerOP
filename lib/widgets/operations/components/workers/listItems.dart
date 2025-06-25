import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/core/model/task.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/store/task.dart';
import 'package:plannerop/utils/worker_utils.dart';
import 'package:plannerop/widgets/operations/components/utils/Button.dart';
import 'package:plannerop/widgets/operations/components/utils/Loader.dart';
import 'package:provider/provider.dart';

// Construir el encabezado de la lista
Widget buildWorkersListHeader({
  required BuildContext context,
  required VoidCallback onAddPressed,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        'Trabajadores Asignados',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Color(0xFF4A5568),
        ),
      ),
      AppButton(
          text: 'Añadir',
          icon: Icons.add,
          onPressed: onAddPressed,
          size: AppButtonSize.small),
    ],
  );
}

// Construir la lista de trabajadores con HashMaps y Sets
Widget buildWorkerList({
  required BuildContext context,
  required List<WorkerGroup> selectedGroups,
  required Map<int, double> workerHours,
  required int? assignmentId,
  required bool inEditMode,
  required List<Worker> deletedWorkers,
  required Function(WorkerGroup, int) onDeleteGroup,
  required Function(List<WorkerGroup>)? onGroupsChanged,
  Function(WorkerGroup, List<Worker>)? onWorkersAddedToGroup,
  Function(WorkerGroup, List<Worker>)? onWorkersRemovedFromGroup,
}) {
  if (selectedGroups.isEmpty) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFFF7FAFC),
      ),
      child: const Center(
        child: Text(
          'No hay trabajadores seleccionados',
          style: TextStyle(
            color: Color(0xFF718096),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFE2E8F0)),
      borderRadius: BorderRadius.circular(8),
      color: const Color(0xFFF7FAFC),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // SECCIÓN 2: GRUPOS DE TRABAJADORES
        if (selectedGroups.isNotEmpty)
          _buildGroupsSection(
            context: context,
            groups: selectedGroups,
            workerHours: workerHours,
            selectedGroups: selectedGroups,
            assignmentId: assignmentId,
            inEditMode: inEditMode,
            deletedWorkers: deletedWorkers,
            onDeleteGroup: onDeleteGroup,
            onGroupsChanged: onGroupsChanged,
            onWorkersAddedToGroup: onWorkersAddedToGroup,
            onWorkersRemovedFromGroup: onWorkersRemovedFromGroup,
          ),

        // Información adicional sobre horas
        if (workerHours.isNotEmpty) buildHoursInfoText(),
      ],
    ),
  );
}

// Nueva función para construir la sección de grupos
Widget _buildGroupsSection({
  required BuildContext context,
  required List<WorkerGroup> groups,
  required Map<int, double> workerHours,
  required List<WorkerGroup> selectedGroups,
  required int? assignmentId,
  required bool inEditMode,
  required List<Worker> deletedWorkers,
  required Function(WorkerGroup, int) onDeleteGroup,
  required Function(List<WorkerGroup>)? onGroupsChanged,
  Function(WorkerGroup, List<Worker>)? onWorkersAddedToGroup,
  Function(WorkerGroup, List<Worker>)? onWorkersRemovedFromGroup,
}) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFE6FFFA)), // Borde verde claro
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado de la sección
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFE6FFFA), // Fondo verde claro para grupos
            borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
          ),
          child: Row(
            children: [
              const Icon(Icons.groups_outlined,
                  size: 16, color: Color(0xFF2C7A7B)),
              const SizedBox(width: 8),
              Text(
                'Grupos de trabajadores',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF2C7A7B),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF38A169), // Verde más oscuro
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${groups.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Lista de grupos
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: groups.length,
          separatorBuilder: (context, index) =>
              const Divider(height: 1, thickness: 1),
          padding: const EdgeInsets.symmetric(vertical: 0),
          itemBuilder: (context, index) {
            final group = groups[index];

            return _buildGroupSection(
              context: context,
              group: group,
              workerHours: workerHours,
              selectedGroups: selectedGroups,
              assignmentId: assignmentId,
              inEditMode: inEditMode,
              deletedWorkers: deletedWorkers,
              onDeleteGroup: onDeleteGroup,
              onGroupsChanged: onGroupsChanged,
              workers: group.workersData ?? [],
              onWorkersAddedToGroup: onWorkersAddedToGroup,
              onWorkersRemovedFromGroup: onWorkersRemovedFromGroup,
            );
          },
        ),
      ],
    ),
  );
}

// Widget para una sección de grupo con sus trabajadores
Widget _buildGroupSection({
  required BuildContext context,
  required WorkerGroup group,
  required List<Worker> workers,
  required Map<int, double> workerHours,
  required List<WorkerGroup> selectedGroups,
  required int? assignmentId,
  required bool inEditMode,
  required List<Worker> deletedWorkers,
  required Function(WorkerGroup, int) onDeleteGroup,
  required Function(List<WorkerGroup>)? onGroupsChanged,
  Function(WorkerGroup, List<Worker>)? onWorkersAddedToGroup,
  Function(WorkerGroup, List<Worker>)? onWorkersRemovedFromGroup,
}) {
  // Obtener la tarea correspondiente al grupo
  final tasksProvider = Provider.of<TasksProvider>(context, listen: false);
  String serviceName = "Servicio no especificado";

  if (group.serviceId > 0) {
    final service = tasksProvider.tasks.firstWhere(
      (task) => task.id == group.serviceId,
      orElse: () => Task(id: 0, name: ""),
    );
    if (service.name.isNotEmpty) {
      serviceName = service.name;
    }
  }

  return Card(
    margin: const EdgeInsets.symmetric(vertical: 4),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabecera del grupo
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF38A169),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.group, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      group.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete,
                        color: Colors.white70, size: 20),
                    onPressed: () => _deleteCompleteGroup(
                      context: context,
                      group: group,
                      workers: workers,
                      onWorkersRemovedFromGroup: onWorkersRemovedFromGroup,
                      onDeleteGroup: onDeleteGroup,
                      assignmentId: assignmentId,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Eliminar grupo',
                  ),
                ],
              ),

              // Segunda fila con servicio y horarios
              if (group.serviceId > 0) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.work_outline,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        serviceName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Contador de trabajadores
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: const Color(0xFFE6FFFA),
          child: Row(
            children: [
              const Icon(Icons.person, size: 14, color: Color(0xFF2C7A7B)),
              const SizedBox(width: 6),
              Text(
                '${workers.length} trabajador${workers.length != 1 ? 'es' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C7A7B),
                ),
              ),
            ],
          ),
        ),

        // Lista de trabajadores del grupo
        Container(
          color: const Color(0xFFE6FFFA),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: workers.length,
            itemBuilder: (context, index) {
              final worker = workers[index];

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                dense: true,
                leading: buildWorkerAvatar(worker),
                title: Text(
                  worker.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: const Color(0xFF2D3748), // Color por defecto
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.area,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: Color(0xFF38A169), size: 20),
                  onPressed: () => _removeWorkerFromGroup(
                    context: context,
                    worker: worker,
                    group: group,
                    onWorkersRemovedFromGroup: onWorkersRemovedFromGroup,
                  ),
                  tooltip: 'Quitar del grupo',
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

void _deleteCompleteGroup({
  required BuildContext context,
  required WorkerGroup group,
  required List<Worker> workers,
  required Function(WorkerGroup, List<Worker>)? onWorkersRemovedFromGroup,
  required Function(WorkerGroup, int) onDeleteGroup,
  required int? assignmentId,
}) {
  if (onWorkersRemovedFromGroup != null && workers.isNotEmpty) {
    onWorkersRemovedFromGroup(group, workers);
  } else {
    debugPrint("No callback available or no workers in group");

    // Fallback al método original si no hay callback
    if (assignmentId != null) {
      onDeleteGroup(group, assignmentId);
    }
  }
}

void _removeWorkerFromGroup({
  required BuildContext context,
  required Worker worker,
  required WorkerGroup group,
  required Function(WorkerGroup, List<Worker>)? onWorkersRemovedFromGroup,
}) {
  if (onWorkersRemovedFromGroup != null) {
    debugPrint(
        "Removing worker ${worker.name} from group ${group.name} via callback");
    onWorkersRemovedFromGroup(group, [worker]);
  } else {
    debugPrint("No callback available for removing worker from group");
  }
}

// Función para eliminar un trabajador (con opción para solo quitarlo del grupo)
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
  bool removeFromGroupOnly = true, // Nuevo parámetro
}) {
  // Si solo queremos quitar al trabajador del grupo pero dejarlo como individual
  if (removeFromGroupOnly && workerGroup != null) {
    // Clonar el grupo y actualizar la lista de trabajadores
    final updatedGroup = WorkerGroup(
      id: workerGroup.id,
      name: workerGroup.name,
      startTime: workerGroup.startTime,
      endTime: workerGroup.endTime,
      startDate: workerGroup.startDate,
      endDate: workerGroup.endDate,
      serviceId: workerGroup.serviceId,
      workers: [...workerGroup.workers]..remove(worker.id),
    );

    // Actualizar la lista de grupos
    final updatedGroups = selectedGroups.map((g) {
      return g.id == workerGroup.id ? updatedGroup : g;
    }).toList();

    // Eliminar el grupo si se quedó sin trabajadores
    final filteredGroups =
        updatedGroups.where((g) => g.workers.isNotEmpty).toList();

    // Notificar los cambios
    if (onGroupsChanged != null) {
      onGroupsChanged(filteredGroups);
    }

    return;
  }

  // Si estamos en modo edición, también actualizamos la lista de trabajadores eliminados
  if (inEditMode && assignmentId != null && onDeletedWorkersChanged != null) {
    final List<Worker> updatedDeletedWorkers = List.from(deletedWorkers);
    updatedDeletedWorkers.add(worker);
    onDeletedWorkersChanged(updatedDeletedWorkers);
  }

  // Actualizar grupos si es necesario
  if (workerGroup != null && onGroupsChanged != null) {
    // Quitar al trabajador de cualquier grupo
    final updatedGroups = selectedGroups.map((group) {
      if (group.workers.contains(worker.id)) {
        return WorkerGroup(
          id: group.id,
          name: group.name,
          startTime: group.startTime,
          endTime: group.endTime,
          startDate: group.startDate,
          endDate: group.endDate,
          serviceId: group.serviceId,
          workers: [...group.workers]..remove(worker.id),
        );
      }
      return group;
    }).toList();

    // Eliminar grupos vacíos
    final filteredGroups =
        updatedGroups.where((g) => g.workers.isNotEmpty).toList();
    onGroupsChanged(filteredGroups);
  }
}

// Construir la cabecera del grupo
Widget buildGroupHeader({
  required BuildContext context,
  required WorkerGroup group,
  required VoidCallback onDelete,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Color(0xFF38A169),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(6),
        topRight: Radius.circular(6),
      ),
    ),
    child: Row(
      children: [
        Icon(Icons.access_time, color: Colors.white, size: 14),
        SizedBox(width: 4),
        Expanded(
          child: Text(
            group.name,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.delete, color: Colors.red, size: 20),
          onPressed: onDelete,
        ),
      ],
    ),
  );
}

// Construir los detalles del trabajador
Widget buildWorkerDetails({
  required BuildContext context,
  required Worker worker,
  required Map<int, double> workerHours,
  required bool isAvailable,
  required VoidCallback onDelete,
}) {
  return ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    dense: true,
    leading: buildWorkerAvatar(worker),
    title: Text(
      worker.name,
      style: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 14,
        color: isAvailable ? const Color(0xFF2D3748) : Colors.red[700],
      ),
    ),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          worker.area,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF718096),
          ),
        ),
      ],
    ),
    trailing: IconButton(
      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
      onPressed: onDelete,
      tooltip: 'Eliminar',
    ),
  );
}

// Construir el avatar del trabajador
Widget buildWorkerAvatar(Worker worker) {
  return Stack(
    children: [
      CircleAvatar(
        backgroundColor: getColorForWorker(worker),
        radius: 16,
        child: Text(
          worker.name.isNotEmpty ? worker.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    ],
  );
}

// Texto informativo sobre horas
Widget buildHoursInfoText() {
  return Padding(
    padding: const EdgeInsets.only(top: 8.0),
    child: Text(
      '* Los trabajadores deben tener menos de 12 horas acumuladas en el día',
      style: TextStyle(
        fontSize: 12,
        fontStyle: FontStyle.italic,
        color: Colors.grey[600],
      ),
    ),
  );
}
