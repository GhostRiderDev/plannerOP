import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/task.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/store/task.dart';
import 'package:plannerop/utils/groups/groups.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/operations/components/serviceSelector.dart';
import 'package:provider/provider.dart';
import 'worker_selection_dialog.dart';

class GroupCreationResult {
  final WorkerGroup group;
  final List<Worker> workers;

  GroupCreationResult(this.group, this.workers);
}

/// Muestra opciones para añadir trabajadores (individual o grupo)
void showWorkerAddOptions({
  required BuildContext context,
  required VoidCallback onAddIndividual,
  required VoidCallback onAddGroup,
}) {
  onAddGroup();
  // showModalBottomSheet(
  //   context: context,
  //   shape: const RoundedRectangleBorder(
  //     borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
  //   ),
  //   builder: (context) {
  //     return SafeArea(
  //       child: Padding(
  //         padding: const EdgeInsets.symmetric(vertical: 16.0),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             const Text(
  //               'Añadir trabajadores',
  //               style: TextStyle(
  //                 fontWeight: FontWeight.bold,
  //                 fontSize: 16,
  //               ),
  //             ),
  //             const SizedBox(height: 16),
  //             ListTile(
  //               leading: const CircleAvatar(
  //                 backgroundColor: Color(0xFF3182CE),
  //                 child: Icon(Icons.person_add, color: Colors.white, size: 20),
  //               ),
  //               title: const Text('Trabajador individual'),
  //               subtitle: const Text('Añadir un solo trabajador'),
  //               onTap: () {
  //                 Navigator.pop(context);
  //                 onAddIndividual();
  //               },
  //             ),
  //             const Divider(height: 1),
  //             ListTile(
  //               leading: const CircleAvatar(
  //                 backgroundColor: Color(0xFF38A169),
  //                 child: Icon(Icons.group_add, color: Colors.white, size: 20),
  //               ),
  //               title: const Text('Grupo con horario común'),
  //               subtitle:
  //                   const Text('Definir horario y seleccionar trabajadores'),
  //               onTap: () {
  //                 Navigator.pop(context);
  //                 onAddGroup();
  //               },
  //             ),
  //           ],
  //         ),
  //       ),
  //     );
  //   },
  // );
}

/// Crear un grupo de trabajadores
Future<GroupCreationResult?> createWorkerGroup({
  required BuildContext context,
  required List<Worker> filteredWorkers,
  required Map<int, double> workerHours,
  required List<Worker> selectedWorkers,
  // NUEVO: Añadir parámetro para grupos existentes
  List<WorkerGroup>? existingGroups,
}) async {
  // Paso 1: Mostrar diálogo para seleccionar horarios
  final scheduleData = await _showGroupScheduleDialog(context);
  if (scheduleData == null) return null;

  final String? startTime = scheduleData['startTime'];
  final String? endTime = scheduleData['endTime'];
  final DateTime? startDate = scheduleData['startDate'];
  final DateTime? endDate = scheduleData['endDate'];
  final int selectedServiceId = scheduleData['serviceId'] ?? 0;

  // Verificar que al menos tenga un horario definido
  if (startTime == null) {
    showAlertToast(context, "Debes definir al menos el horario de inicio");
    return null;
  }

  // NUEVO: Crear lista completa de trabajadores ya seleccionados
  List<Worker> allSelectedWorkers = [];

  // Añadir trabajadores individuales
  allSelectedWorkers.addAll(selectedWorkers);

  // Añadir trabajadores de grupos existentes
  if (existingGroups != null) {
    for (var group in existingGroups) {
      if (group.workersData != null) {
        allSelectedWorkers.addAll(group.workersData!);
      }
    }
  }

  // Remover duplicados basados en ID
  final uniqueWorkerIds = <int>{};
  allSelectedWorkers = allSelectedWorkers.where((worker) {
    if (uniqueWorkerIds.contains(worker.id)) {
      return false;
    }
    uniqueWorkerIds.add(worker.id);
    return true;
  }).toList();

  // Paso 2: Mostrar diálogo para seleccionar trabajadores con la lista completa
  final workers = await showDialog<List<Worker>>(
    context: context,
    builder: (context) => WorkerSelectionDialog(
      selectedWorkers: const [],
      availableWorkers: filteredWorkers,
      workerHours: workerHours,
      title: 'Seleccionar trabajadores',
      allSelectedWorkers: allSelectedWorkers, // CORREGIDO: Pasar lista completa
    ),
  );

  if (workers == null || workers.isEmpty) return null;

  // Crear el grupo
  String groupName = getGroupName(startDate, endDate, startTime, endTime);

  String? startDateStr =
      startDate != null ? DateFormat('yyyy-MM-dd').format(startDate) : null;
  String? endDateStr =
      endDate != null ? DateFormat('yyyy-MM-dd').format(endDate) : null;

  final newGroup = WorkerGroup(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    startTime: startTime,
    endTime: endTime,
    startDate: startDateStr,
    endDate: endDateStr,
    workers: workers.map((worker) => worker.id).toList(),
    workersData: workers,
    name: groupName,
    serviceId: selectedServiceId,
  );

  return GroupCreationResult(newGroup, workers);
}

/// Diálogo para configurar horario del grupo
Future<Map<String, dynamic>?> _showGroupScheduleDialog(
    BuildContext context) async {
  String? startTime;
  String? endTime;
  DateTime? startDate;
  DateTime? endDate;
  int selectedServiceId = 0;
  bool showValidationErrors = false;

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false, // Evitar que se cierre al tocar fuera
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final tasksProvider =
            Provider.of<TasksProvider>(context, listen: false);
        final List<Task> availableTasks = tasksProvider.tasks;

        // Función para validar los campos sin cerrar el diálogo
        void validateAndContinue() {
          setState(() {
            showValidationErrors = true;
          });

          // Verificar campos obligatorios
          if (startTime == null ||
              startTime!.isEmpty ||
              selectedServiceId <= 0) {
            // Mostrar error sin cerrar el diálogo
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Debes completar los campos obligatorios (*)'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
            return; // No continuar si falta información
          }

          // Si todo está bien, cerrar con los datos
          Navigator.pop(context, {
            'startTime': startTime,
            'endTime': endTime,
            'startDate': startDate,
            'endDate': endDate,
            'serviceId': selectedServiceId,
          });
        }

        // Verifica si el servicio es inválido para destacar el campo
        bool isServiceInvalid = showValidationErrors && selectedServiceId <= 0;
        bool isStartTimeInvalid = showValidationErrors && (startTime == null);

        return AlertDialog(
          title: const Text('Definir horario común'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Define horarios comunes para este grupo de trabajadores:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),

                // Sección de fecha y hora de inicio
                const Text(
                  'INICIO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF718096),
                  ),
                ),
                const SizedBox(height: 8),

                // Fecha de inicio
                GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );

                    if (picked != null) {
                      setState(() {
                        startDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 18, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Fecha inicio',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF718096),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                startDate != null
                                    ? DateFormat('dd/MM/yyyy')
                                        .format(startDate!)
                                    : 'Seleccionar',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: startDate != null
                                      ? Colors.black
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Hora de inicio - CAMPO REQUERIDO
                GestureDetector(
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                      builder: (context, child) {
                        return MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                            alwaysUse24HourFormat: false,
                          ),
                          child: child!,
                        );
                      },
                    );

                    if (picked != null) {
                      setState(() {
                        final hour = picked.hour.toString().padLeft(2, '0');
                        final minute = picked.minute.toString().padLeft(2, '0');
                        startTime = '$hour:$minute';
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isStartTimeInvalid
                            ? Colors.red.shade300
                            : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 18,
                            color: isStartTimeInvalid
                                ? Colors.red.shade600
                                : Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hora inicio *', // Marcar como obligatorio
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isStartTimeInvalid
                                      ? Colors.red.shade600
                                      : const Color(0xFF718096),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                startTime ?? 'Seleccionar',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: startTime != null
                                      ? Colors.black
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Sección de fecha y hora de finalización
                const Text(
                  'FINALIZACIÓN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF718096),
                  ),
                ),
                const SizedBox(height: 8),

                // Fecha de finalización
                GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );

                    if (picked != null) {
                      setState(() {
                        endDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 18, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Fecha fin',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF718096),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                endDate != null
                                    ? DateFormat('dd/MM/yyyy').format(endDate!)
                                    : 'Seleccionar',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: endDate != null
                                      ? Colors.black
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Hora de finalización
                GestureDetector(
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                      builder: (context, child) {
                        return MediaQuery(
                          data: MediaQuery.of(context),
                          child: child!,
                        );
                      },
                    );

                    if (picked != null) {
                      setState(() {
                        final hour = picked.hour.toString().padLeft(2, '0');
                        final minute = picked.minute.toString().padLeft(2, '0');
                        endTime = '$hour:$minute';
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 18, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hora fin',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF718096),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                endTime ?? 'Seleccionar',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: endTime != null
                                      ? Colors.black
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // SERVICIO (OBLIGATORIO) - Sección con título
                const Text(
                  'SERVICIO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF718096),
                  ),
                ),
                const SizedBox(height: 8),

                // Selector de servicio con borde rojo si es inválido
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isServiceInvalid
                          ? Colors.red.shade300
                          : Colors.transparent,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isServiceInvalid)
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 8.0, top: 4.0, bottom: 2.0),
                          child: Text(
                            'Servicio *', // Marcar como obligatorio
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      buildServiceSelector(
                        context,
                        availableTasks,
                        selectedServiceId,
                        (newSelection) {
                          setState(() {
                            selectedServiceId = newSelection;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Mensaje de campos obligatorios
                if (showValidationErrors &&
                    (isStartTimeInvalid || isServiceInvalid))
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.red.shade700, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Los campos marcados con * son obligatorios',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3182CE),
                foregroundColor: Colors.white,
              ),
              onPressed: validateAndContinue, // Usar función de validación
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    ),
  );

  return result;
}
