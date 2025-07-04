import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/mapper/operation.dart';
import 'package:plannerop/store/operations.dart';
import 'package:plannerop/store/workers.dart';
import 'package:plannerop/store/task.dart';
import 'package:plannerop/store/clients.dart';
import 'package:plannerop/store/chargersOp.dart';

import 'package:provider/provider.dart';

class ReportDataTable extends StatefulWidget {
  final String periodName;
  final DateTime startDate;
  final DateTime endDate;
  final String area;
  final int? zone;
  final String? motorship;
  final String? status;

  const ReportDataTable({
    Key? key,
    required this.periodName,
    required this.startDate,
    required this.endDate,
    required this.area,
    this.zone,
    this.motorship,
    this.status,
  }) : super(key: key);

  @override
  State<ReportDataTable> createState() => _ReportDataTableState();
}

class _ReportDataTableState extends State<ReportDataTable> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _sortAscending = true;
  int _sortColumnIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Operation> _getFilteredData(List<Operation> allAssignments) {
    final filtered = allAssignments.where((data) {
      // PASO 2: Filtrar solo por fecha SIEMPRE
      final dataDate = DateTime(data.date.year, data.date.month, data.date.day);
      final startDate = DateTime(
          widget.startDate.year, widget.startDate.month, widget.startDate.day);
      final endDate = DateTime(
          widget.endDate.year, widget.endDate.month, widget.endDate.day);

      if (dataDate.isBefore(startDate) || dataDate.isAfter(endDate)) {
        return false;
      }

      // PASO 3: Filtrar por área SOLO si no es "Todas"
      if (widget.area != null &&
          widget.area != 'Todas' &&
          widget.area.isNotEmpty) {
        if (data.area != widget.area) {
          return false;
        }
      }

      // PASO 4: Filtrar por zona SOLO si se especifica
      if (widget.zone != null && widget.zone! > 0) {
        int? dataZone = int.tryParse(data.zone.toString());
        if (dataZone != widget.zone) {
          return false;
        }
      }

      // PASO 5: Filtrar por motonave SOLO si se especifica
      if (widget.motorship != null &&
          widget.motorship!.isNotEmpty &&
          widget.motorship != "Todas" &&
          widget.motorship != "Seleccionar") {
        if (data.motorship != widget.motorship) {
          return false;
        }
      }

      // PASO 6: Filtrar por estado - SIMPLIFICADO
      if (widget.status != null &&
          widget.status!.isNotEmpty &&
          widget.status != "Todos" &&
          widget.status != "Seleccionar") {
        String filterStatus = widget.status!;
        String dataStatus = data.status;

        bool statusMatch = false;

        // Comparaciones directas para "En Curso"
        if (filterStatus == "En curso") {
          statusMatch = dataStatus.toUpperCase() == "INPROGRESS" ||
              dataStatus.toLowerCase() == "en curso" ||
              dataStatus.toLowerCase() == "in progress" ||
              dataStatus == "En Curso";
        }
        // Comparaciones directas para "Pendiente"
        else if (filterStatus == "Pendiente") {
          statusMatch = dataStatus.toUpperCase() == "PENDING" ||
              dataStatus.toLowerCase() == "pendiente";
        }
        // Comparaciones directas para "Completada"
        else if (filterStatus == "Completada") {
          statusMatch = dataStatus.toUpperCase() == "COMPLETED" ||
              dataStatus.toLowerCase() == "completada" ||
              dataStatus.toLowerCase() == "completed";
        }
        // Comparaciones directas para "Cancelada"
        else if (filterStatus == "Cancelada") {
          statusMatch = dataStatus.toUpperCase() == "CANCELED" ||
              dataStatus.toLowerCase() == "cancelada" ||
              dataStatus.toLowerCase() == "cancelled";
        }
        // Si no es ninguno de los anteriores, comparar directamente
        else {
          statusMatch = dataStatus == filterStatus ||
              dataStatus.toUpperCase() == filterStatus.toUpperCase();
        }

        if (!statusMatch) {
          return false;
        }
      }

      // PASO 7: Filtrar por búsqueda SOLO si hay texto
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        bool found = false;

        // Buscar en ID
        if (data.id.toString().contains(searchLower)) found = true;

        // Buscar en área
        if (!found && data.area.toLowerCase().contains(searchLower))
          found = true;

        // Buscar en motonave
        if (!found &&
            data.motorship != null &&
            data.motorship!.toLowerCase().contains(searchLower)) found = true;

        // Buscar en trabajadores
        if (!found) {
          for (var group in data.groups) {
            if (group.workersData != null) {
              for (var worker in group.workersData!) {
                if (worker.name.toLowerCase().contains(searchLower) ||
                    worker.document.toLowerCase().contains(searchLower)) {
                  found = true;
                  break;
                }
              }
            }
            if (found) break;
          }
        }

        if (!found) return false;
      }

      return true;
    }).toList();

    if (filtered.isEmpty) {
    } else {}

    // Ordenar
    filtered.sort((a, b) {
      switch (_sortColumnIndex) {
        case 0:
          return (a.id ?? 0).compareTo(b.id ?? 0);
        case 1:
          return a.date.compareTo(b.date);
        case 5:
          return a.area.compareTo(b.area);
        case 12:
          return a.status.compareTo(b.status);
        default:
          return 0;
      }
    });

    if (!_sortAscending) {
      filtered.sort((a, b) => -(filtered.indexOf(a) - filtered.indexOf(b)));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final assignmentsProvider = Provider.of<OperationsProvider>(context);
    final usersProvider = Provider.of<WorkersProvider>(context, listen: false);

    // Obtenemos las asignaciones del provider
    final allAssignments = assignmentsProvider.operations;

    // Aplicamos los filtros a las asignaciones
    final filteredData = _getFilteredData(allAssignments);

    return Column(
      children: [
        // Barra de búsqueda
        _buildSearchBar(),

        // Resumen de resultados
        _buildResultsSummary(filteredData.length),

        const SizedBox(height: 10),

        // Tabla de datos
        Expanded(
          child: filteredData.isEmpty
              ? _buildEmptyState()
              : FutureBuilder<Widget>(
                  future: _buildDataTable(filteredData, usersProvider),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    return snapshot.data ?? const SizedBox();
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Neumorphic(
        style: NeumorphicStyle(
          depth: -3,
          intensity: 0.7,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
          color: const Color(0xFFF7FAFC),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Buscar por ID, trabajador, área o motonave...',
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildResultsSummary(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Mostrando $count ${count == 1 ? 'operación' : 'operaciones'}',
            style: const TextStyle(
              color: Color(0xFF718096),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'Período: ${widget.periodName}',
            style: const TextStyle(
              color: Color(0xFF4A5568),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<Widget> _buildDataTable(
      List<Operation> data, WorkersProvider usersProvider) async {
    final rows = await _buildExpandedRows(data);

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(
            const Color(0xFFF7FAFC),
          ),
          columnSpacing: 24,
          horizontalMargin: 16,
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          columns: [
            _buildDataColumn('ID Op.', 0),
            _buildDataColumn('Fecha Inicial', 1),
            _buildDataColumn('Hora Inicial', 2),
            _buildDataColumn('Nombre Completo', 3),
            _buildDataColumn('Documento', 4),
            _buildDataColumn('Área', 5),
            _buildDataColumn('Zona', 6),
            _buildDataColumn('Motonave', 7),
            _buildDataColumn('Tarea', 8),
            _buildDataColumn('Turno', 9),
            _buildDataColumn('Fecha Fin', 10),
            _buildDataColumn('Hora Fin', 11),
            _buildDataColumn('Estado', 12),
          ],
          rows: await rows,
        ),
      ),
    );
  }

  // Método para expandir las filas con un trabajador por fila (igual que en Excel)
  Future<List<DataRow>> _buildExpandedRows(List<Operation> data) async {
    List<DataRow> rows = [];

    // Para alternar colores por operación
    int? lastOperationId;
    int currentOperationOrder = 0;

    for (var assignment in data) {
      // Determinar si es una nueva operación
      bool isNewOperation = lastOperationId != assignment.id;
      if (isNewOperation) {
        lastOperationId = assignment.id;
        currentOperationOrder++;
      }

      // Color de fondo para filas de la misma operación
      final backgroundColor = currentOperationOrder % 2 == 0
          ? const Color(0xFFF7FAFC)
          : const Color(0xFFEDF2F7);

      // Obtener información adicional
      final taskName = await _getTaskName(assignment);
      final clientName = _getClientName(assignment.clientId);
      final supervisorNames = _getSupervisorNames(assignment.inChagers);

      if (assignment.groups.isEmpty) {
        // Operación sin grupos
        rows.add(
          DataRow(
            color: MaterialStateProperty.all(backgroundColor),
            cells: [
              DataCell(Text(assignment.id?.toString() ?? 'N/A')),
              DataCell(Text(DateFormat('dd/MM/yyyy').format(assignment.date))),
              DataCell(Text(assignment.time)),
              DataCell(const Text('Sin asignar')),
              DataCell(const Text('-')),
              DataCell(Text(assignment.area)),
              DataCell(
                  Text('${assignment.zone == 0 ? 'N/A' : assignment.zone}')),
              DataCell(Text(assignment.motorship ?? 'N/A')),
              DataCell(Text(taskName)),
              DataCell(const Text('N/A')),
              DataCell(Text(assignment.endDate != null
                  ? DateFormat('dd/MM/yyyy').format(assignment.endDate!)
                  : 'N/A')),
              DataCell(Text(assignment.endTime ?? 'N/A')),
              DataCell(_buildStatusWidget(assignment.status)),
            ],
          ),
        );
      } else {
        // Procesar cada grupo
        for (int groupIndex = 0;
            groupIndex < assignment.groups.length;
            groupIndex++) {
          final group = assignment.groups[groupIndex];
          final shiftName = 'Turno ${groupIndex + 1}';

          if (group.workers.isEmpty) {
            // Grupo sin trabajadores
            rows.add(
              DataRow(
                color: MaterialStateProperty.all(backgroundColor),
                cells: [
                  DataCell(Text(assignment.id?.toString() ?? 'N/A')),
                  DataCell(
                      Text(DateFormat('dd/MM/yyyy').format(assignment.date))),
                  DataCell(Text(group.startTime ?? assignment.time)),
                  DataCell(const Text('Sin asignar')),
                  DataCell(const Text('-')),
                  DataCell(Text(assignment.area)),
                  DataCell(Text(
                      '${assignment.zone == 0 ? 'N/A' : assignment.zone}')),
                  DataCell(Text(assignment.motorship ?? 'N/A')),
                  DataCell(Text(taskName)),
                  DataCell(Text(shiftName)),
                  DataCell(Text(_getEndDate(assignment, group))),
                  DataCell(Text(_getEndTime(assignment, group))),
                  DataCell(_buildStatusWidget(assignment.status)),
                ],
              ),
            );
          } else {
            // Procesar cada trabajador del grupo
            for (final workerId in group.workers) {
              String workerName = 'Trabajador #$workerId';
              String workerDni = '-';

              // Buscar datos del trabajador
              if (group.workersData != null && group.workersData!.isNotEmpty) {
                final workerData = group.workersData!
                    .where((w) => w.id == workerId)
                    .firstOrNull;

                if (workerData != null) {
                  workerName = workerData.name;
                  workerDni = workerData.document.isNotEmpty
                      ? workerData.document
                      : workerData.code;
                }
              } else {
                // Buscar en el provider de trabajadores
                final workersProvider =
                    Provider.of<WorkersProvider>(context, listen: false);
                final worker = workersProvider.getWorkerById(workerId);
                if (worker != null) {
                  workerName = worker.name;
                  workerDni = worker.document.isNotEmpty
                      ? worker.document
                      : worker.code;
                }
              }

              rows.add(
                DataRow(
                  color: MaterialStateProperty.all(backgroundColor),
                  cells: [
                    DataCell(Text(assignment.id?.toString() ?? 'N/A')),
                    DataCell(
                        Text(DateFormat('dd/MM/yyyy').format(assignment.date))),
                    DataCell(Text(group.startTime ?? assignment.time)),
                    DataCell(Text(workerName)),
                    DataCell(Text(workerDni)),
                    DataCell(Text(assignment.area)),
                    DataCell(Text(
                        '${assignment.zone == 0 ? 'N/A' : assignment.zone}')),
                    DataCell(Text(assignment.motorship ?? 'N/A')),
                    DataCell(Text(taskName)),
                    DataCell(Text(shiftName)),
                    DataCell(Text(_getEndDate(assignment, group))),
                    DataCell(Text(_getEndTime(assignment, group))),
                    DataCell(_buildStatusWidget(assignment.status)),
                  ],
                ),
              );
            }
          }
        }
      }
    }

    return rows;
  }

  // Métodos auxiliares para obtener información adicional
  Future<String> _getTaskName(Operation assignment) async {
    try {
      final tasksProvider = Provider.of<TasksProvider>(context, listen: false);
      if (assignment.groups.isNotEmpty) {
        final firstGroup = assignment.groups.first;
        if (firstGroup.serviceId > 0) {
          return await tasksProvider.getTaskNameByIdServiceAsync(
              firstGroup.serviceId, context);
        }
      }
      return 'Tarea no especificada';
    } catch (e) {
      return 'Tarea desconocida';
    }
  }

  String _getClientName(int clientId) {
    try {
      final clientsProvider =
          Provider.of<ClientsProvider>(context, listen: false);
      final client = clientsProvider.getClientById(clientId);
      return client.name;
    } catch (e) {
      return 'Cliente desconocido';
    }
  }

  String _getSupervisorNames(List<int> chargerIds) {
    try {
      final chargersProvider =
          Provider.of<ChargersOpProvider>(context, listen: false);
      final supervisorNames = <String>[];
      for (final chargerId in chargerIds) {
        final charger = chargersProvider.chargers
            .where((c) => c.id == chargerId)
            .firstOrNull;
        if (charger != null) {
          supervisorNames.add(charger.name);
        }
      }
      return supervisorNames.isNotEmpty
          ? supervisorNames.join(', ')
          : 'Sin supervisor';
    } catch (e) {
      return 'Supervisor desconocido';
    }
  }

  String _getEndDate(Operation assignment, group) {
    if (group.endDate != null && group.endDate!.isNotEmpty) {
      try {
        final endDate = DateTime.parse(group.endDate!);
        return DateFormat('dd/MM/yyyy').format(endDate);
      } catch (e) {
        // Si falla el parsing del grupo, usar la fecha de la operación
      }
    }

    if (assignment.endDate != null) {
      return DateFormat('dd/MM/yyyy').format(assignment.endDate!);
    }

    return 'N/A';
  }

  String _getEndTime(Operation assignment, group) {
    return group.endTime ?? assignment.endTime ?? 'N/A';
  }

  DataColumn _buildDataColumn(String label, int columnIndex) {
    return DataColumn(
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      onSort: (columnIndex, ascending) {
        setState(() {
          _sortColumnIndex = columnIndex;
          _sortAscending = ascending;
        });
      },
    );
  }

  Widget _buildStatusWidget(String status) {
    Color color = getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        getOperationStatusText(status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Color(0xFFCBD5E0),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay operaciones disponibles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF718096),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta cambiar los filtros o el período de fechas',
            style: TextStyle(
              color: const Color(0xFF718096).withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          NeumorphicButton(
            style: NeumorphicStyle(
              depth: 2,
              intensity: 0.7,
              color: const Color(0xFFF7FAFC),
              boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
              });
            },
            child: const Text(
              'Limpiar búsqueda',
              style: TextStyle(
                color: Color(0xFF3182CE),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
