import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/utils/charts/baseChart.dart';
import 'package:plannerop/utils/charts/chartData.dart';
import 'package:plannerop/utils/charts/painters.dart';
import 'package:plannerop/utils/charts/legend.dart';
import 'package:plannerop/utils/charts/mapper.dart'; // Cambiar translate por mapper

class ShipPersonnelChart extends BaseChart<ShipData> {
  const ShipPersonnelChart({
    Key? key,
    required DateTime startDate,
    required DateTime endDate,
    required String area,
    int? zone,
    String? motorship,
    String? status,
  }) : super(
          key: key,
          startDate: startDate,
          endDate: endDate,
          area: area,
          zone: zone,
          motorship: motorship,
          status: status,
        );

  @override
  State<ShipPersonnelChart> createState() => _ShipPersonnelChartState();
}

class _ShipPersonnelChartState
    extends BaseChartState<ShipData, ShipPersonnelChart> {
  @override
  String get chartTitle => 'Personal por Buque';

  @override
  List<ShipData> processAssignmentData(List<Operation> assignments) {
    try {
      var filteredAssignments = assignments.where((assignment) {
        // Aplicar filtros adicionales
        if (widget.area != "Todas" && assignment.area != widget.area) {
          return false;
        }

        if (widget.zone != null) {
          int? assignmentZone;
          try {
            assignmentZone = int.tryParse(assignment.zone.toString());
          } catch (e) {
            assignmentZone = null;
          }
          if (assignmentZone != widget.zone) {
            return false;
          }
        }

        if (widget.motorship != null &&
            widget.motorship!.isNotEmpty &&
            widget.motorship != "Todas") {
          if (assignment.motorship == null ||
              assignment.motorship != widget.motorship) {
            return false;
          }
        }

        if (widget.status != null &&
            widget.status!.isNotEmpty &&
            widget.status != 'Todos') {
          String normalizedStatus =
              StatusMapper.mapAPIStatusToUI(assignment.status);
          if (normalizedStatus != widget.status) {
            return false;
          }
        }

        return true;
      }).toList();

      // Agrupar por motorship
      final Map<String, List<Operation>> shipAssignments = {};
      for (var assignment in filteredAssignments) {
        if (assignment.motorship != null && assignment.motorship!.isNotEmpty) {
          final motorshipKey = assignment.motorship!;
          if (!shipAssignments.containsKey(motorshipKey)) {
            shipAssignments[motorshipKey] = [];
          }
          shipAssignments[motorshipKey]!.add(assignment);
        }
      }

      // Paleta de colores
      final List<Color> colorPalette = [
        const Color(0xFF3182CE), // Azul
        const Color(0xFF38A169), // Verde
        const Color(0xFFED8936), // Naranja
        const Color(0xFF805AD5), // Púrpura
        const Color(0xFFE53E3E), // Rojo
        const Color(0xFF4A5568), // Gris azulado
        const Color(0xFFD69E2E), // Amarillo
        const Color(0xFF00B5D8), // Cian
        const Color(0xFFDD6B20), // Naranja oscuro
        const Color(0xFFD53F8C), // Rosa
      ];

      final result = <ShipData>[];
      int colorIndex = 0;

      // Ordenar por cantidad de personal
      final sortedEntries = shipAssignments.entries.toList()
        ..sort((a, b) {
          final Set<int> uniqueWorkersA = {};
          final Set<int> uniqueWorkersB = {};

          for (var assignment in a.value) {
            for (var group in assignment.groups) {
              uniqueWorkersA.addAll(group.workers);
            }
          }

          for (var assignment in b.value) {
            for (var group in assignment.groups) {
              uniqueWorkersB.addAll(group.workers);
            }
          }

          return uniqueWorkersB.length.compareTo(uniqueWorkersA.length);
        });

      // Calcular total para porcentajes
      final totalPersonnel = sortedEntries.fold<Set<int>>(
        <int>{},
        (Set<int> acc, entry) {
          for (var assignment in entry.value) {
            for (var group in assignment.groups) {
              acc.addAll(group.workers);
            }
          }
          return acc;
        },
      ).length;

      for (var entry in sortedEntries) {
        final shipName = entry.key;
        final assignments = entry.value;

        // Contar trabajadores únicos
        final Set<int> uniqueWorkerIds = {};
        final List<Map<String, dynamic>> workersDetails = [];

        for (var assignment in assignments) {
          for (var group in assignment.groups) {
            for (var workerId in group.workers) {
              if (!uniqueWorkerIds.contains(workerId)) {
                uniqueWorkerIds.add(workerId);

                // Intentar obtener información del trabajador
                if (group.workersData != null &&
                    group.workersData!.isNotEmpty) {
                  final workerData = group.workersData!
                      .where((w) => w.id == workerId)
                      .firstOrNull;

                  if (workerData != null) {
                    workersDetails.add({
                      'id': workerId,
                      'name': workerData.name,
                      'code': workerData.code,
                      'phone': workerData.phone,
                    });
                  } else {
                    workersDetails.add({
                      'id': workerId,
                      'name': 'Trabajador #$workerId',
                      'code': 'TR-$workerId',
                      'phone': 'N/A',
                    });
                  }
                } else {
                  workersDetails.add({
                    'id': workerId,
                    'name': 'Trabajador #$workerId',
                    'code': 'TR-$workerId',
                    'phone': 'N/A',
                  });
                }
              }
            }
          }
        }

        final totalAssignments = assignments.length;
        final totalPersonnelShip = uniqueWorkerIds.length;
        final percentage = totalPersonnel > 0
            ? (totalPersonnelShip / totalPersonnel) * 100
            : 0.0;

        result.add(ShipData(
          name: shipName,
          personnel: totalPersonnelShip,
          color: colorPalette[colorIndex % colorPalette.length],
          totalAssignments: totalAssignments,
          dateRange:
              '${DateFormat('dd/MM/yyyy').format(widget.startDate)} - ${DateFormat('dd/MM/yyyy').format(widget.endDate)}',
          workers: workersDetails,
          assignmentList: assignments,
          percentage: percentage,
        ));

        colorIndex++;
      }

      return result;
    } catch (e) {
      setError('Error al procesar datos: $e');
      return [];
    }
  }

  @override
  Widget buildChart() {
    return Column(
      children: [
        // Gráfico de barras
        Expanded(
          flex: 3,
          child: _buildBarChart(),
        ),
        const SizedBox(height: 16),
        // Información detallada del elemento seleccionado
        if (selectedIndex != -1 && selectedIndex < data.length)
          _buildSelectedShipInfo(data[selectedIndex]),
        // Leyenda horizontal
        Expanded(
          flex: 2,
          child: ChartLegend(
            data: data,
            selectedIndex: selectedIndex,
            onItemTap: (index) {
              setSelectedIndex(selectedIndex == index ? -1 : index);
            },
            horizontal: true,
            valueLabel: 'personal',
            showPercentage: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedShipInfo(ShipData shipData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: shipData.color.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_boat, color: shipData.color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  shipData.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: shipData.color,
                  ),
                ),
              ),
              // Botón X para cerrar/deseleccionar
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setSelectedIndex(-1),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Personal:', '${shipData.personnel}'),
          _buildInfoRow('Operaciones:', '${shipData.totalAssignments}'),
          _buildInfoRow('Período:', shipData.dateRange),
          if (shipData.workers.isNotEmpty && shipData.workers.length <= 3) ...[
            const SizedBox(height: 8),
            const Text(
              'Trabajadores:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A5568),
              ),
            ),
            ...shipData.workers.take(3).map((worker) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Text(
                    '• ${worker['name']}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          Text(value,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No hay datos de buques disponibles',
          style: TextStyle(color: Color(0xFF718096)),
        ),
      );
    }

    final maxValue = data.isEmpty
        ? 1
        : data.fold<int>(
            1,
            (max, shipData) =>
                shipData.personnel > max ? shipData.personnel : max);

    return Container(
      padding: const EdgeInsets.all(16),
      child: CustomPaint(
        size: const Size(double.infinity, double.infinity),
        painter: BarChartPainter(
          data,
          selectedIndex,
          maxValue: maxValue.toDouble(),
        ),
      ),
    );
  }
}
