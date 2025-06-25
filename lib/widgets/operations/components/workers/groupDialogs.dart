import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/task.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/store/task.dart';
import 'package:plannerop/utils/groups/groups.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/operations/components/serviceSelector.dart';
import 'package:plannerop/widgets/operations/components/utils/dateField.dart';
import 'package:plannerop/widgets/operations/components/utils/forms.dart';
import 'package:plannerop/widgets/operations/components/utils/timeField.dart';
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
  required VoidCallback onAddGroup,
}) {
  onAddGroup();
}

/// Crear un grupo de trabajadores
Future<GroupCreationResult?> createWorkerGroup({
  required BuildContext context,
  required List<Worker> filteredWorkers,
  //  Añadir parámetro para grupos existentes
  List<WorkerGroup>? existingGroups,
}) async {
  //  Mostrar diálogo para seleccionar horarios
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

  // Crear lista completa de trabajadores ya seleccionados
  List<Worker> allSelectedWorkers = [];

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

  debugPrint("Trabajadores únicos seleccionados: ${filteredWorkers.length}");

  //  Mostrar diálogo para seleccionar trabajadores con la lista completa
  final workers = await showDialog<List<Worker>>(
    context: context,
    builder: (context) => WorkerSelectionDialog(
      selectedWorkers: const [],
      availableWorkers: filteredWorkers,
      title: 'Seleccionar trabajadores',
      allSelectedWorkers: allSelectedWorkers,
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
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();

  int selectedServiceId = 0;
  bool showValidationErrors = false;

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final tasksProvider =
            Provider.of<TasksProvider>(context, listen: false);
        final List<Task> availableTasks = tasksProvider.tasks;

        void validateAndContinue() {
          setState(() {
            showValidationErrors = true;
          });

          if (startTimeController.text.isEmpty ||
              startDateController.text.isEmpty ||
              selectedServiceId <= 0) {
            showErrorToast(
                context, 'Debes completar todos los campos obligatorios (*)');
            return;
          }

          // Parsear las fechas para retornar
          DateTime? startDate;
          DateTime? endDate;

          try {
            if (startDateController.text.isNotEmpty) {
              startDate =
                  DateFormat('dd/MM/yyyy').parse(startDateController.text);
            }
            if (endDateController.text.isNotEmpty) {
              endDate = DateFormat('dd/MM/yyyy').parse(endDateController.text);
            }
          } catch (e) {
            debugPrint('Error parsing dates: $e');
          }

          Navigator.pop(context, {
            'startTime': startTimeController.text,
            'endTime': endTimeController.text,
            'startDate': startDate,
            'endDate': endDate,
            'serviceId': selectedServiceId,
          });
        }

        bool isServiceInvalid = showValidationErrors && selectedServiceId <= 0;

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

                //  SECCIÓN DE INICIO
                buildFormSection(
                  title: 'INICIO',
                  children: [
                    DateField(
                      label: 'Fecha inicio *',
                      controller: startDateController,
                      onDateChanged: (date) {
                        setState(() {
                          // Actualizar el controlador de fecha de inicio
                          startDateController.text = date;
                        });
                      },
                      hint: 'Seleccionar fecha de inicio',
                      icon: Icons.calendar_today,
                      isOptional: false,
                    ),
                    const SizedBox(height: 12),
                    TimeField(
                      label: 'Hora inicio *',
                      hint: 'Seleccionar hora de inicio',
                      icon: Icons.access_time,
                      controller: startTimeController,
                      dateController: startDateController,
                      isOptional: false,
                      locked: false,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                //  SECCIÓN DE FINALIZACIÓN
                buildFormSection(
                  title: 'FINALIZACIÓN',
                  children: [
                    DateField(
                      label: 'Fecha fin (opcional)',
                      controller: endDateController,
                      onDateChanged: (date) {
                        setState(() {
                          // Actualizar el controlador de fecha de fin
                          endDateController.text = date;
                        });
                      },
                      icon: Icons.calendar_today,
                      isOptional: true,
                      hint: 'Seleccionar fecha de fin',
                      locked: false,
                    ),
                    const SizedBox(height: 12),
                    TimeField(
                      label: 'Hora fin (opcional)',
                      hint: 'Seleccionar hora de fin',
                      icon: Icons.access_time,
                      controller: endTimeController,
                      dateController: endDateController,
                      isOptional: true,
                      isEndTime: true,
                      locked: false,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                //  SECCIÓN DE SERVICIO
                buildFormSection(
                  title: 'SERVICIO',
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isServiceInvalid
                              ? Colors.red.shade300
                              : Colors.transparent,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: buildServiceSelector(
                        context,
                        availableTasks,
                        selectedServiceId,
                        (newSelection) {
                          setState(() {
                            selectedServiceId = newSelection;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                //  MENSAJE DE VALIDACIÓN
                if (showValidationErrors) buildValidationMessage(),
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
              onPressed: validateAndContinue,
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    ),
  );

  return result;
}
