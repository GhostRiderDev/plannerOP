import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/area.dart';
import 'package:plannerop/core/model/client.dart';
import 'package:plannerop/core/model/programming.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/store/areas.dart';
import 'package:plannerop/store/clients.dart';
import 'package:plannerop/store/workers.dart';
import 'package:plannerop/utils/neumophomic.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/operations/add/addOperationContent.dart';
import 'package:plannerop/widgets/operations/add/addOperationHeader.dart';
import 'package:plannerop/widgets/operations/add/validate.dart';
import 'package:plannerop/widgets/operations/components/utils/Button.dart';
import 'package:plannerop/widgets/operations/components/utils/Loader.dart';
import 'package:provider/provider.dart';
import '../components/successDialog.dart';

class AddOperationDialog extends StatefulWidget {
  const AddOperationDialog({Key? key}) : super(key: key);

  @override
  State<AddOperationDialog> createState() => AddOperationDialogState();
}

class AddOperationDialogState extends State<AddOperationDialog> {
  // Controladores para los campos de texto
  final _areaController = TextEditingController();
  final _startDateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _taskController = TextEditingController();
  final _zoneController = TextEditingController();
  final _clientController = TextEditingController();
  final _endDateController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _motorshipController = TextEditingController();
  final _chargerController = TextEditingController();
  final _programmingController = TextEditingController();
  Programming? _selectedProgramming;
  bool _startDateLockedByGroup = false;
  bool _startTimeLockedByGroup = false;
  bool _endDateLockedByGroup = false;
  bool _endTimeLockedByGroup = false;

  // Lista de trabajadores seleccionados
  List<Worker> _selectedWorkers = [];
  List<WorkerGroup> _selectedGroups = [];

  List<Worker> _allWorkers = [];
  List<Area> _areas = [];
  List<String> _currentTasks = [];
  List<Client> _clients = [];

  // variable para controlar el estado de carga
  bool _isSaving = false;

  @override
  void dispose() {
    _areaController.dispose();
    _startDateController.dispose();
    _startTimeController.dispose();
    _programmingController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Establecer la fecha y hora actuales por defecto
    _startDateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _startTimeController.text = DateFormat('HH:mm').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    _areas = Provider.of<AreasProvider>(context).areas;
    _clients = Provider.of<ClientsProvider>(context).clients;
    _allWorkers = Provider.of<WorkersProvider>(context).workers;
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: screenWidth < 600 ? screenWidth - 32 : screenWidth * 0.8,
        ),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera del diálogo
              AddOperationHeader(),
              const SizedBox(height: 20),

              // Contenido principal del formulario
              AddOperationContent(
                selectedGroups: _selectedGroups,
                allWorkers: _allWorkers,
                areaController: _areaController,
                startDateController: _startDateController,
                startTimeController: _startTimeController,
                taskController: _taskController,
                currentTasks: _currentTasks,
                zoneController: _zoneController,
                clientController: _clientController,
                areas: _areas,
                clients: _clients,
                endDateController: _endDateController,
                endTimeController: _endTimeController,
                motorshipController: _motorshipController,
                chargerController: _chargerController,
                programmingController: _programmingController,
                startDateLockedByGroup: _startDateLockedByGroup,
                startTimeLockedByGroup: _startTimeLockedByGroup,
                endDateLockedByGroup: _endDateLockedByGroup,
                endTimeLockedByGroup: _endTimeLockedByGroup,
                onWorkersChanged: _updateSelectedWorkers,
                onGroupsChanged: updateSelectedGroups,
                onProgrammingSelected: (programming) {
                  setState(() {
                    _selectedProgramming = programming;
                    if (programming != null) {
                      _programmingController.text =
                          programming.id_operation.toString();
                    } else {
                      _programmingController.text = '';
                    }
                    debugPrint(
                        'Programación seleccionada: ID=${_selectedProgramming?.id}');
                  });
                },
                onWorkersRemovedFromGroup: (group, removedWorkers) {
                  setState(() {
                    final groupIndex =
                        _selectedGroups.indexWhere((g) => g.id == group.id);
                    if (groupIndex >= 0) {
                      final currentGroup = _selectedGroups[groupIndex];
                      final updatedWorkers = currentGroup.workers
                          .where((workerId) =>
                              !removedWorkers.any((w) => w.id == workerId))
                          .toList();
                      final updatedWorkersData = currentGroup.workersData
                          ?.where((w) => !removedWorkers
                              .any((removed) => removed.id == w.id))
                          .toList();

                      if (updatedWorkers.isEmpty) {
                        _selectedGroups.removeAt(groupIndex);
                      } else {
                        final updatedGroup = WorkerGroup(
                          id: currentGroup.id,
                          name: currentGroup.name,
                          startTime: currentGroup.startTime,
                          endTime: currentGroup.endTime,
                          startDate: currentGroup.startDate,
                          endDate: currentGroup.endDate,
                          serviceId: currentGroup.serviceId,
                          workers: updatedWorkers,
                          workersData: updatedWorkersData,
                        );
                        _selectedGroups[groupIndex] = updatedGroup;
                      }
                    }
                  });
                  _processGroupSchedules();
                  showSuccessToast(context,
                      "Trabajador${removedWorkers.length > 1 ? 'es' : ''} removido${removedWorkers.length > 1 ? 's' : ''} del grupo");
                },
              ),

              const SizedBox(height: 24),
              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    text: 'Cancelar',
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    size: AppButtonSize.longer,
                    type: AppButtonType.danger,
                  ),
                  const SizedBox(width: 12),
                  NeumorphicButton(
                    style: neumorphicButtonStyle(
                      color: _isSaving ? const Color(0xFF90CDF4) : Colors.blue,
                      depth: _isSaving ? 0 : 2,
                    ),
                    onPressed: _isSaving
                        ? null
                        : () async {
                            setState(() {
                              _isSaving = true;
                            });

                            final isValid = await validateFields(
                              context: context,
                              selectedWorkers: _selectedWorkers,
                              selectedGroups: _selectedGroups,
                              areaControl: _areaController.text,
                              startDateControl: _startDateController.text,
                              startTimeControl: _startTimeController.text,
                              clientControl: _clientController.text,
                              motorshipControl: _motorshipController.text,
                              chargerControl: _chargerController.text,
                              endDateControl: _endDateController.text,
                              endTimeControl: _endTimeController.text,
                              zoneControl: _zoneController.text,
                              selectedProgramming: _selectedProgramming,
                            );

                            if (!isValid) {
                              setState(() {
                                _isSaving = false;
                              });
                              return;
                            }

                            Navigator.of(context).pop();
                            _showSuccessDialog(context);
                          },
                    child: Container(
                      width: 100,
                      child: Center(
                        child: _isSaving
                            ? AppLoader(
                                size: LoaderSize.medium,
                                strokeWidth: 2,
                                message: 'Guardando...',
                                color: Colors.white,
                              )
                            : const Text(
                                'Guardar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                  // AppButton(
                  //   text: _isSaving ? 'Guardando...' : 'Guardar',
                  //   onPressed: _isSaving
                  //       ? null
                  //       : () async {
                  //           setState(() {
                  //             _isSaving = true;
                  //           });

                  //           final isValid = await validateFields(
                  //             context: context,
                  //             selectedWorkers: _selectedWorkers,
                  //             selectedGroups: _selectedGroups,
                  //             areaControl: _areaController.text,
                  //             startDateControl: _startDateController.text,
                  //             startTimeControl: _startTimeController.text,
                  //             clientControl: _clientController.text,
                  //             motorshipControl: _motorshipController.text,
                  //             chargerControl: _chargerController.text,
                  //             endDateControl: _endDateController.text,
                  //             endTimeControl: _endTimeController.text,
                  //             zoneControl: _zoneController.text,
                  //             selectedProgramming: _selectedProgramming,
                  //           );

                  //           if (!isValid) {
                  //             setState(() {
                  //               _isSaving = false;
                  //             });
                  //             return;
                  //           }

                  //           Navigator.of(context).pop();
                  //           _showSuccessDialog(context);
                  //         },
                  //   size: AppButtonSize.longer,
                  // )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Método para procesar los horarios de grupos
  void _processGroupSchedules() {
    if (_selectedGroups.isEmpty) {
      resetGroupScheduleLocks();
      return;
    }
    DateTime? earliestStartDateTime;
    DateTime? latestEndDateTime;

    for (var group in _selectedGroups) {
      if (group.startDate != null && group.startTime != null) {
        try {
          final dateParts = DateTime.parse(group.startDate!);
          final timeParts = group.startTime!.split(':');
          final hours = int.parse(timeParts[0]);
          final minutes = int.parse(timeParts[1]);

          final combinedStartDateTime = DateTime(
            dateParts.year,
            dateParts.month,
            dateParts.day,
            hours,
            minutes,
          );

          if (earliestStartDateTime == null ||
              combinedStartDateTime.isBefore(earliestStartDateTime)) {
            earliestStartDateTime = combinedStartDateTime;
          }
        } catch (e) {
          debugPrint('Error al combinar fecha/hora de inicio: $e');
        }
      }

      if (group.endDate != null && group.endTime != null) {
        try {
          final dateParts = DateTime.parse(group.endDate!);
          final timeParts = group.endTime!.split(':');
          final hours = int.parse(timeParts[0]);
          final minutes = int.parse(timeParts[1]);

          final combinedEndDateTime = DateTime(
            dateParts.year,
            dateParts.month,
            dateParts.day,
            hours,
            minutes,
          );

          if (latestEndDateTime == null ||
              combinedEndDateTime.isAfter(latestEndDateTime)) {
            latestEndDateTime = combinedEndDateTime;
          }
        } catch (e) {
          debugPrint('Error al combinar fecha/hora de fin: $e');
        }
      }

      if (group.startDate != null &&
          group.startTime == null &&
          earliestStartDateTime == null) {
        try {
          final startDate = DateTime.parse(group.startDate!);
          if (earliestStartDateTime == null) {
            earliestStartDateTime =
                DateTime(startDate.year, startDate.month, startDate.day, 0, 0);
          }
        } catch (e) {
          debugPrint('Error al procesar fecha de inicio sin hora: $e');
        }
      }

      if (group.startTime != null &&
          group.startDate == null &&
          earliestStartDateTime == null) {
        try {
          final timeParts = group.startTime!.split(':');
          final hours = int.parse(timeParts[0]);
          final minutes = int.parse(timeParts[1]);

          final now = DateTime.now();
          final timeOnlyStart =
              DateTime(now.year, now.month, now.day, hours, minutes);

          if (earliestStartDateTime == null) {
            earliestStartDateTime = timeOnlyStart;
          }
        } catch (e) {
          debugPrint('Error al procesar hora de inicio sin fecha: $e');
        }
      }

      if (group.endDate != null &&
          group.endTime == null &&
          latestEndDateTime == null) {
        try {
          final endDate = DateTime.parse(group.endDate!);
          if (latestEndDateTime == null) {
            latestEndDateTime =
                DateTime(endDate.year, endDate.month, endDate.day, 23, 59);
          }
        } catch (e) {
          debugPrint('Error al procesar fecha de fin sin hora: $e');
        }
      }

      if (group.endTime?.isEmpty == false &&
          group.endDate == null &&
          latestEndDateTime == null) {
        try {
          final timeParts = group.endTime!.split(':');
          final hours = int.parse(timeParts[0]);
          final minutes = int.parse(timeParts[1]);

          final now = DateTime.now();
          final timeOnlyEnd =
              DateTime(now.year, now.month, now.day, hours, minutes);

          if (latestEndDateTime == null) {
            latestEndDateTime = timeOnlyEnd;
          }
        } catch (e) {
          debugPrint('Error al procesar hora de fin sin fecha: $e');
        }
      }
    }

    setState(() {
      if (earliestStartDateTime != null) {
        _startDateController.text =
            DateFormat('dd/MM/yyyy').format(earliestStartDateTime);
        _startDateLockedByGroup = true;

        final hour = earliestStartDateTime.hour.toString().padLeft(2, '0');
        final minute = earliestStartDateTime.minute.toString().padLeft(2, '0');
        _startTimeController.text = '$hour:$minute';
        _startTimeLockedByGroup = true;
      } else {
        _startDateLockedByGroup = false;
        _startTimeLockedByGroup = false;
      }

      if (latestEndDateTime != null) {
        _endDateController.text =
            DateFormat('dd/MM/yyyy').format(latestEndDateTime);
        _endDateLockedByGroup = true;

        final hour = latestEndDateTime.hour.toString().padLeft(2, '0');
        final minute = latestEndDateTime.minute.toString().padLeft(2, '0');
        _endTimeController.text = '$hour:$minute';
        _endTimeLockedByGroup = true;
      } else {
        _endDateLockedByGroup = false;
        _endTimeLockedByGroup = false;
      }
    });
  }

  void resetGroupScheduleLocks() {
    setState(() {
      _startDateLockedByGroup = false;
      _startTimeLockedByGroup = false;
      _endDateLockedByGroup = false;
      _endTimeLockedByGroup = false;

      if (_endDateController.text.isNotEmpty ||
          _endTimeController.text.isNotEmpty) {
        _endDateController.text = '';
        _endTimeController.text = '';
      }

      if (_startDateController.text.isEmpty) {
        _startDateController.text =
            DateFormat('dd/MM/yyyy').format(DateTime.now());
      }

      if (_startTimeController.text.isEmpty) {
        _startTimeController.text = DateFormat('HH:mm').format(DateTime.now());
      }
    });
  }

  void _updateSelectedWorkers(List<Worker> workers) {
    setState(() {
      _selectedWorkers = workers;
    });
  }

  void updateSelectedGroups(List<WorkerGroup> groups) {
    setState(() {
      _selectedGroups = groups;
    });
    _processGroupSchedules();
  }

  void _showSuccessDialog(BuildContext context) {
    showAssignmentSuccessDialog(
      context: context,
      selectedWorkers: _selectedWorkers,
      startDateText: _startDateController.text,
      startTimeText: _startTimeController.text,
      taskText: _taskController.text,
      zoneText: _zoneController.text,
    );
  }
}
