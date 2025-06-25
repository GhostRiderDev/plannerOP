import 'package:flutter/material.dart';
import 'package:plannerop/widgets/operations/components/utils/Loader.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/fault.dart';
import 'package:plannerop/widgets/workers/workerFilter.dart';
import 'package:plannerop/widgets/workers/workerStats.dart';
import 'package:plannerop/widgets/workers/workerListItem.dart';
import 'package:plannerop/widgets/workers/workerEmptyState.dart';
import 'package:plannerop/widgets/workers/workerDetailDialog.dart';
import 'package:plannerop/store/workers.dart';
import 'package:plannerop/store/faults.dart';

class WorkersContent extends StatelessWidget {
  final String searchQuery;
  final WorkerFilter currentFilter;
  final FaultType? selectedFaultType;
  final Function(WorkerFilter) onFilterChanged;
  final Function(FaultType?) onFaultTypeChanged;
  final Function(Worker) onAddWorker;
  final Function(Worker, Worker) onUpdateWorker;

  const WorkersContent({
    Key? key,
    required this.searchQuery,
    required this.currentFilter,
    this.selectedFaultType,
    required this.onFilterChanged,
    required this.onFaultTypeChanged,
    required this.onAddWorker,
    required this.onUpdateWorker,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<WorkersProvider, FaultsProvider>(
      builder: (context, workersProvider, faultsProvider, _) {
        return Column(
          children: [
            // Stats Cards con filtros
            WorkerStatsCards(
              totalWorkers: workersProvider.totalWorkerWithoutRetired,
              assignedWorkers: workersProvider.assignedWorkers,
              currentFilter: currentFilter,
              disabledWorkers: workersProvider.disabledWorkers,
              retiredWorkers: workersProvider.retiredWorkers,
              onFilterChanged: onFilterChanged,
            ),

            // Filtros de faltas si está activo
            if (currentFilter == WorkerFilter.faults) _buildFaultFilters(),

            // Lista de trabajadores
            Expanded(
              child:
                  _buildWorkersList(workersProvider, faultsProvider, context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFaultFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFaultChip('Todas', null),
            _buildFaultChip('Inasistencia', FaultType.INASSISTANCE,
                color: const Color(0xFFE53E3E), icon: Icons.event_busy),
            _buildFaultChip('Abandono', FaultType.ABANDONMENT,
                color: const Color(0xFFED8936), icon: Icons.exit_to_app),
            _buildFaultChip('Falta de Respeto', FaultType.IRRESPECTFUL,
                color: const Color(0xFF805AD5),
                icon: Icons.sentiment_very_dissatisfied),
          ],
        ),
      ),
    );
  }

  Widget _buildFaultChip(String label, FaultType? type,
      {Color? color, IconData? icon}) {
    final isSelected = selectedFaultType == type;

    return GestureDetector(
      onTap: () => onFaultTypeChanged(type),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? Colors.blue).withOpacity(0.2)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? (color ?? Colors.blue) : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 16,
                  color:
                      isSelected ? (color ?? Colors.blue) : Colors.grey[600]),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? (color ?? Colors.blue) : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkersList(WorkersProvider workersProvider,
      FaultsProvider faultsProvider, BuildContext context) {
    final workers =
        _getFilteredWorkers(workersProvider, faultsProvider, context);
    final filteredWorkers = _applySearchFilter(workers);

    if (filteredWorkers.isEmpty) {
      return WorkerEmptyState(searchQuery: searchQuery);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 5, bottom: 100),
        itemCount: filteredWorkers.length,
        itemBuilder: (context, index) {
          final worker = filteredWorkers[index];
          final specialtyColor = _getColorArea(worker.idArea);

          return WorkerListItem(
            worker: worker,
            specialtyColor: specialtyColor,
            onTap: () => _showWorkerDetails(
                context, worker, specialtyColor, faultsProvider),
          );
        },
      ),
    );
  }

  List<Worker> _getFilteredWorkers(WorkersProvider workersProvider,
      FaultsProvider faultsProvider, BuildContext context) {
    List<Worker> workers;

    switch (currentFilter) {
      case WorkerFilter.all:
        workers = workersProvider.workers
            .where((w) => w.status != WorkerStatus.deactivated)
            .toList();
        workers.sort((a, b) => b.failures.compareTo(a.failures));
        break;
      case WorkerFilter.available:
        workers = workersProvider.fetchWorkersByStatus(WorkerStatus.available);
        break;
      case WorkerFilter.assigned:
        workers = workersProvider.fetchWorkersByStatus(WorkerStatus.assigned);
        break;
      case WorkerFilter.disabled:
        workers =
            workersProvider.fetchWorkersByStatus(WorkerStatus.incapacitated);
        break;
      case WorkerFilter.retired:
        workers =
            workersProvider.fetchWorkersByStatus(WorkerStatus.deactivated);
        workers
            .sort((a, b) => b.deactivationDate!.compareTo(a.deactivationDate!));
        break;
      case WorkerFilter.faults:
        workers = faultsProvider.getWorkersWithMostFaults(context);
        if (selectedFaultType != null) {
          workers = workers.where((worker) {
            final workerFaults =
                faultsProvider.fetchFaultsByWorker(context, worker.id);
            return workerFaults.any((fault) => fault.type == selectedFaultType);
          }).toList();
        }
        _sortByMostRecentFaults(workers, faultsProvider, context);
        break;
    }

    return workers;
  }

  void _sortByMostRecentFaults(List<Worker> workers,
      FaultsProvider faultsProvider, BuildContext context) {
    workers.sort((a, b) {
      final faultsA = faultsProvider.fetchFaultsByWorker(context, a.id);
      final faultsB = faultsProvider.fetchFaultsByWorker(context, b.id);

      if (faultsA.isNotEmpty && faultsB.isNotEmpty) {
        final latestFaultA = faultsA.reduce((curr, next) =>
            curr.createdAt.isAfter(next.createdAt) ? curr : next);
        final latestFaultB = faultsB.reduce((curr, next) =>
            curr.createdAt.isAfter(next.createdAt) ? curr : next);
        return latestFaultB.createdAt.compareTo(latestFaultA.createdAt);
      }

      if (faultsA.isNotEmpty) return -1;
      if (faultsB.isNotEmpty) return 1;
      return a.name.compareTo(b.name);
    });
  }

  List<Worker> _applySearchFilter(List<Worker> workers) {
    if (searchQuery.isEmpty) return workers;

    return workers
        .where((worker) =>
            worker.name.toLowerCase().contains(searchQuery) ||
            worker.area.toLowerCase().contains(searchQuery) ||
            worker.document.toLowerCase().contains(searchQuery))
        .toList();
  }

  Color _getColorArea(int idArea) {
    const colors = [
      Colors.indigo,
      Colors.teal,
      Colors.pink,
      Colors.orange,
      Colors.purple,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.teal
    ];
    return colors[idArea % colors.length];
  }

  void _showWorkerDetails(BuildContext context, Worker worker,
      Color specialtyColor, FaultsProvider faultsProvider) {
    if (currentFilter == WorkerFilter.faults) {
      _showFaultsDialog(context, worker, specialtyColor, faultsProvider);
    } else {
      showDialog(
        context: context,
        builder: (context) => WorkerDetailDialog(
          worker: worker,
          isAssigned: worker.status == WorkerStatus.assigned,
          specialtyColor: specialtyColor,
          onUpdateWorker: onUpdateWorker,
        ),
      );
    }
  }

  void _showFaultsDialog(BuildContext context, Worker worker,
      Color specialtyColor, FaultsProvider faultsProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AppLoader(
        color: Colors.white,
        size: LoaderSize.small,
      ),
    );

    List<Fault> faults = faultsProvider.fetchFaultsByWorker(context, worker.id);
    Navigator.of(context).pop();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          FaultType? dialogSelectedFaultType;

          final filteredFaults = dialogSelectedFaultType == null
              ? faults
              : faults.where((f) => f.type == dialogSelectedFaultType).toList();

          filteredFaults.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: double.maxFinite,
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: specialtyColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            worker.name.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: specialtyColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(worker.name,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(worker.document,
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Filtros dentro del diálogo
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildDialogFaultChip(
                            'Todas', null, dialogSelectedFaultType, setState),
                        _buildDialogFaultChip(
                            'Inasistencia',
                            FaultType.INASSISTANCE,
                            dialogSelectedFaultType,
                            setState,
                            color: const Color(0xFFE53E3E),
                            icon: Icons.event_busy),
                        _buildDialogFaultChip('Abandono', FaultType.ABANDONMENT,
                            dialogSelectedFaultType, setState,
                            color: const Color(0xFFED8936),
                            icon: Icons.exit_to_app),
                        _buildDialogFaultChip(
                            'Falta de Respeto',
                            FaultType.IRRESPECTFUL,
                            dialogSelectedFaultType,
                            setState,
                            color: const Color(0xFF805AD5),
                            icon: Icons.sentiment_very_dissatisfied),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Stats
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dialogSelectedFaultType == null
                              ? 'Faltas acumuladas:'
                              : 'Faltas de este tipo:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700]),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text('${filteredFaults.length}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Lista de faltas
                  Expanded(
                    child: filteredFaults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.info_outline,
                                    size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  dialogSelectedFaultType == null
                                      ? 'No hay faltas registradas'
                                      : 'No hay faltas de este tipo',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredFaults.length,
                            itemBuilder: (context, index) {
                              final fault = filteredFaults[index];
                              return _buildFaultItem(fault);
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDialogFaultChip(String label, FaultType? type,
      FaultType? selectedType, StateSetter setState,
      {Color? color, IconData? icon}) {
    final isSelected = selectedType == type;

    return GestureDetector(
      onTap: () => setState(() => selectedType = type),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? Colors.blue).withOpacity(0.2)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? (color ?? Colors.blue) : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 16,
                  color:
                      isSelected ? (color ?? Colors.blue) : Colors.grey[600]),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? (color ?? Colors.blue) : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaultItem(Fault fault) {
    IconData icon;
    Color color;
    String typeText;

    switch (fault.type) {
      case FaultType.INASSISTANCE:
        icon = Icons.event_busy;
        color = const Color(0xFFE53E3E);
        typeText = 'Inasistencia';
        break;
      case FaultType.ABANDONMENT:
        icon = Icons.exit_to_app;
        color = const Color(0xFFED8936);
        typeText = 'Abandono';
        break;
      case FaultType.IRRESPECTFUL:
        icon = Icons.sentiment_very_dissatisfied;
        color = const Color(0xFF805AD5);
        typeText = 'Falta de Respeto';
        break;
    }

    final formattedDate = DateFormat('dd/MM/yyyy').format(fault.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  typeText,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: color, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4)),
                child: Text(formattedDate,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(fault.description, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
