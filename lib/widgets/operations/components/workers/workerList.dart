import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/store/workerGroup.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:provider/provider.dart';
import 'worker_selection_dialog.dart';
import 'hoursCalculator.dart';
import 'groupDialogs.dart';
import 'listItems.dart';
import 'groupUtils.dart';

class SelectedWorkersList extends StatefulWidget {
  // [Mantener todos los props existentes]
  final List<Worker> selectedWorkers;
  final List<WorkerGroup> selectedGroups;
  final Function(List<Worker>) onWorkersChanged;
  final Function(List<WorkerGroup>)? onGroupsChanged;
  final bool inEditMode;
  final List<Worker> deletedWorkers;
  final Function(List<Worker>)? onDeletedWorkersChanged;
  final List<Worker> availableWorkers;
  final List<WorkerGroup>? initialGroups;
  final int? assignmentId;
  Function(WorkerGroup, List<Worker>)? onWorkersAddedToGroup;
  Function(WorkerGroup, List<Worker>)? onWorkersRemovedFromGroup;

  SelectedWorkersList({
    Key? key,
    required this.selectedWorkers,
    required this.selectedGroups,
    required this.onWorkersChanged,
    required this.availableWorkers,
    required this.onGroupsChanged,
    this.inEditMode = false,
    this.deletedWorkers = const [],
    this.onDeletedWorkersChanged,
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
  bool _isCalculatingHours = false;
  List<WorkerGroup> _workerGroups = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialGroups != null && widget.initialGroups!.isNotEmpty) {
      _workerGroups = List.from(widget.initialGroups!);
    }
    _calculateWorkerHours();
  }

  // Este método ahora llama al método en worker_hours_calculator.dart
  Future<void> _calculateWorkerHours() async {
    setState(() {
      _isCalculatingHours = true;
    });

    final result = await calculateWorkerHours(context, widget.selectedWorkers);

    setState(() {
      _workerHours = result.hoursMap;
      _filteredWorkers = result.filteredWorkers;
      _isCalculatingHours = false;
    });
  }

  // Abre el diálogo para seleccionar trabajadores
  Future<void> _openWorkerSelectionDialog() async {
    await _calculateWorkerHours();

    final result = await showDialog<List<Worker>>(
      context: context,
      builder: (context) => WorkerSelectionDialog(
        selectedWorkers: widget.selectedWorkers,
        availableWorkers: _filteredWorkers,
        workerHours: _workerHours,
        title: 'Seleccionar trabajadores',
        allSelectedWorkers: widget.selectedWorkers,
      ),
    );

    if (result != null) {
      widget.onWorkersChanged(result);
      notifyDialogAboutWorkerChanges(context);
    }
  }

  // Mostrar opciones para añadir
  void _showAddOptions() {
    showWorkerAddOptions(
      context: context,
      onAddIndividual: _openWorkerSelectionDialog,
      onAddGroup: _createNewGroup,
    );
  }

  // Crear un nuevo grupo (ahora delega en group_dialogs.dart)
  Future<void> _createNewGroup() async {
    await _calculateWorkerHours();

    final result = await createWorkerGroup(
      context: context,
      filteredWorkers: _filteredWorkers,
      workerHours: _workerHours,
      selectedWorkers: widget.selectedWorkers,
      existingGroups: widget.selectedGroups,
    );

    if (result != null) {
      final newGroup = result.group;
      final selectedWorkers = result.workers;

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
      selectedWorkers: widget.selectedWorkers,
      selectedGroups: widget.selectedGroups,
      inEditMode: widget.inEditMode,
      deletedWorkers: widget.deletedWorkers,
      onDeletedWorkersChanged: widget.onDeletedWorkersChanged,
      onGroupsChanged: widget.onGroupsChanged,
      onWorkersChanged: (updatedWorkers) {
        // Aquí está el cambio clave: No pasamos automáticamente la lista actualizada
        // sino que preservamos los trabajadores que no estaban exclusivamente en este grupo
        widget.onWorkersChanged(updatedWorkers);
      },
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
          isCalculatingHours: _isCalculatingHours,
          onAddPressed: _showAddOptions,
        ),

        const SizedBox(height: 8),

        // Lista de trabajadores
        buildWorkerList(
          context: context,
          selectedWorkers: widget.selectedWorkers,
          selectedGroups: widget.selectedGroups,
          workerHours: _workerHours,
          assignmentId: widget.assignmentId,
          inEditMode: widget.inEditMode,
          deletedWorkers: widget.deletedWorkers,
          onDeleteGroup: _onDeleteGroup,
          onDeletedWorkersChanged: widget.onDeletedWorkersChanged,
          onWorkersChanged: widget.onWorkersChanged,
          onGroupsChanged: widget.onGroupsChanged,
          onWorkersAddedToGroup: widget.onWorkersAddedToGroup,
          onWorkersRemovedFromGroup: widget.onWorkersRemovedFromGroup,
        ),

        // Información adicional
        if (widget.selectedWorkers.isNotEmpty && _workerHours.isNotEmpty)
          buildHoursInfoText(),
      ],
    );
  }
}
