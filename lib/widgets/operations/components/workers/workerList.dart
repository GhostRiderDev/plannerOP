import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/store/workerGroup.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:provider/provider.dart';
import 'worker_selection_dialog.dart';
import 'groupDialogs.dart';
import 'listItems.dart';
import 'groupUtils.dart';

class SelectedWorkersList extends StatefulWidget {
  // [Mantener todos los props existentes]
  final List<WorkerGroup> selectedGroups;
  final Function(List<WorkerGroup>)? onGroupsChanged;
  final bool inEditMode;
  final List<Worker> deletedWorkers;
  final List<Worker> availableWorkers;
  final List<WorkerGroup>? initialGroups;
  final int? assignmentId;
  Function(WorkerGroup, List<Worker>)? onWorkersAddedToGroup;
  Function(WorkerGroup, List<Worker>)? onWorkersRemovedFromGroup;

  SelectedWorkersList({
    Key? key,
    required this.selectedGroups,
    required this.availableWorkers,
    required this.onGroupsChanged,
    this.inEditMode = false,
    this.deletedWorkers = const [],
    this.initialGroups,
    this.assignmentId,
    this.onWorkersAddedToGroup,
    this.onWorkersRemovedFromGroup,
  }) : super(key: key);

  @override
  State<SelectedWorkersList> createState() => _SelectedWorkersListState();
}

class _SelectedWorkersListState extends State<SelectedWorkersList> {
  // Estado principal
  Map<int, double> _workerHours = {};
  List<Worker> _filteredWorkers = [];
  List<WorkerGroup> _workerGroups = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialGroups != null && widget.initialGroups!.isNotEmpty) {
      _workerGroups = List.from(widget.initialGroups!);
    }
    setState(() {
      _filteredWorkers = List.from(widget.availableWorkers);
    });
  }

  // Mostrar opciones para añadir
  void _showAddOptions() {
    showWorkerAddOptions(
      context: context,
      onAddGroup: _createNewGroup,
    );
  }

  // Crear un nuevo grupo (ahora delega en group_dialogs.dart)
  Future<void> _createNewGroup() async {
    final result = await createWorkerGroup(
      context: context,
      filteredWorkers: _filteredWorkers,
      existingGroups: widget.selectedGroups,
    );

    if (result != null) {
      final newGroup = result.group;

      widget.selectedGroups.add(newGroup);

      final groupsProvider =
          Provider.of<WorkerGroupsProvider>(context, listen: false);
      groupsProvider.addGroup(newGroup);

      setState(() {
        _workerGroups.add(newGroup);
      });

      if (widget.onGroupsChanged != null) {
        widget.onGroupsChanged!(widget.selectedGroups);
      }

      showSuccessToast(context, "Grupo creado con éxito");
    }
  }

  // Eliminar un grupo
  void _onDeleteGroup(WorkerGroup group, int assignmentId) {
    //  Solo eliminar los trabajadores que pertenecen ÚNICAMENTE a este grupo
    deleteWorkerGroup(
      context: context,
      group: group,
      assignmentId: assignmentId,
      selectedGroups: widget.selectedGroups,
      inEditMode: widget.inEditMode,
      deletedWorkers: widget.deletedWorkers,
      onGroupsChanged: widget.onGroupsChanged,
      onRemoveFromLocal: () {
        setState(() {
          _workerGroups.removeWhere((g) => g.id == group.id);
        });
      },
      preserveIndividualWorkers:
          true, // Nuevo parámetro para indicar que queremos preservar individuales
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado con título y botón
        buildWorkersListHeader(
          context: context,
          onAddPressed: _showAddOptions,
        ),

        const SizedBox(height: 8),

        // Lista de trabajadores
        buildWorkerList(
          context: context,
          selectedGroups: widget.selectedGroups,
          workerHours: _workerHours,
          assignmentId: widget.assignmentId,
          inEditMode: widget.inEditMode,
          deletedWorkers: widget.deletedWorkers,
          onDeleteGroup: _onDeleteGroup,
          onGroupsChanged: widget.onGroupsChanged,
          onWorkersAddedToGroup: widget.onWorkersAddedToGroup,
          onWorkersRemovedFromGroup: widget.onWorkersRemovedFromGroup,
        ),

        // Información adicional
        if (_workerHours.isNotEmpty) buildHoursInfoText(),
      ],
    );
  }
}
