import 'package:flutter/material.dart';
import 'package:plannerop/core/model/area.dart';
import 'package:plannerop/core/model/client.dart';
import 'package:plannerop/core/model/programming.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/widgets/operations/add/inChargerSelection.dart';
import 'package:plannerop/widgets/operations/components/workers/workerList.dart';
import 'operationForm.dart';

class AddOperationContent extends StatelessWidget {
  final List<Worker> selectedWorkers;
  final List<WorkerGroup> selectedGroups;
  final List<Worker> allWorkers;
  final TextEditingController areaController;
  final TextEditingController startDateController;
  final TextEditingController startTimeController;
  final TextEditingController taskController;
  final List<String> currentTasks;
  final TextEditingController zoneController;
  final TextEditingController clientController;
  final List<Area> areas;
  final List<Client> clients;
  final TextEditingController endDateController;
  final TextEditingController endTimeController;
  final TextEditingController motorshipController;
  final TextEditingController chargerController;
  final TextEditingController programmingController;
  final bool startDateLockedByGroup;
  final bool startTimeLockedByGroup;
  final bool endDateLockedByGroup;
  final bool endTimeLockedByGroup;
  final Function(List<Worker>) onWorkersChanged;
  final Function(List<WorkerGroup>) onGroupsChanged;
  final Function(Programming?) onProgrammingSelected;
  final Function(WorkerGroup, List<Worker>) onWorkersRemovedFromGroup;

  const AddOperationContent({
    Key? key,
    required this.selectedWorkers,
    required this.selectedGroups,
    required this.allWorkers,
    required this.areaController,
    required this.startDateController,
    required this.startTimeController,
    required this.taskController,
    required this.currentTasks,
    required this.zoneController,
    required this.clientController,
    required this.areas,
    required this.clients,
    required this.endDateController,
    required this.endTimeController,
    required this.motorshipController,
    required this.chargerController,
    required this.programmingController,
    required this.startDateLockedByGroup,
    required this.startTimeLockedByGroup,
    required this.endDateLockedByGroup,
    required this.endTimeLockedByGroup,
    required this.onWorkersChanged,
    required this.onGroupsChanged,
    required this.onProgrammingSelected,
    required this.onWorkersRemovedFromGroup,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lista de trabajadores seleccionados
        SelectedWorkersList(
          selectedWorkers: selectedWorkers,
          onWorkersChanged: onWorkersChanged,
          availableWorkers: allWorkers,
          selectedGroups: selectedGroups,
          onGroupsChanged: onGroupsChanged,
          inEditMode: false,
          deletedWorkers: const [],
          onDeletedWorkersChanged: null,
          assignmentId: null,
          onWorkersAddedToGroup: null,
          onWorkersRemovedFromGroup: onWorkersRemovedFromGroup,
        ),
        const SizedBox(height: 12),

        // Formulario de operación
        OperationForm(
          areaController: areaController,
          startDateController: startDateController,
          startTimeController: startTimeController,
          taskController: taskController,
          currentTasks: currentTasks,
          zoneController: zoneController,
          clientController: clientController,
          areas: areas,
          clients: clients,
          endDateController: endDateController,
          endTimeController: endTimeController,
          showEndDateTime: true,
          motorshipController: motorshipController,
          startDateLocked: startDateLockedByGroup,
          startTimeLocked: startTimeLockedByGroup,
          endDateLocked: endDateLockedByGroup,
          endTimeLocked: endTimeLockedByGroup,
          programmingController: programmingController,
          onProgrammingSelected: onProgrammingSelected,
        ),

        const SizedBox(height: 24),

        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: MultiChargerSelectionField(
            controller: chargerController,
          ),
        ),
      ],
    );
  }
}
