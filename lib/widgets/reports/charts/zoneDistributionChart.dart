import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/mapper/operation.dart';
import 'package:plannerop/utils/charts/baseChart.dart';
import 'package:plannerop/utils/charts/chartData.dart';
import 'package:plannerop/utils/charts/info.dart';
import 'package:plannerop/utils/charts/legend.dart';
import 'package:plannerop/utils/charts/painters.dart';

class ZoneDistributionChart extends BaseChart<ZoneData> {
  const ZoneDistributionChart({
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
  State<ZoneDistributionChart> createState() => _ZoneDistributionChartState();
}

class _ZoneDistributionChartState
    extends BaseChartState<ZoneData, ZoneDistributionChart> {
  @override
  String get chartTitle => 'Distribución por Zona';

  @override
  List<ZoneData> processAssignmentData(List<Operation> assignments) {
    try {
      final filteredAssignments = assignments.where((assignment) {
        // Filtrar por fecha
        if (!assignment.date
                .isAfter(widget.startDate.subtract(const Duration(days: 1))) ||
            !assignment.date
                .isBefore(widget.endDate.add(const Duration(days: 1)))) {
          return false;
        }

        // Filtrar por área
        if (widget.area != 'Todas' && assignment.area != widget.area) {
          return false;
        }

        // Aplicar otros filtros
        if (widget.zone != null) {
          int? assignmentZone;
          try {
            assignmentZone = int.tryParse(assignment.zone.toString());
          } catch (e) {
            assignmentZone = null;
          }
          if (assignmentZone != widget.zone) return false;
        }

        if (widget.motorship != null && widget.motorship!.isNotEmpty) {
          if (assignment.motorship == null ||
              assignment.motorship != widget.motorship) {
            return false;
          }
        }

        if (widget.status != null && widget.status!.isNotEmpty) {
          String normalizedStatus = getOperationStatusText(assignment.status);
          if (normalizedStatus != widget.status) return false;
        }

        return true;
      }).toList();

      // Agrupar por zona
      final Map<int, List<Operation>> zoneAssignments = {};
      for (var assignment in filteredAssignments) {
        final zone = assignment.zone;
        if (!zoneAssignments.containsKey(zone)) {
          zoneAssignments[zone] = [];
        }
        zoneAssignments[zone]!.add(assignment);
      }

      // Colores para cada zona
      final List<Color> zoneColors = [
        const Color(0xFF4299E1),
        const Color(0xFF48BB78),
        const Color(0xFFED8936),
        const Color(0xFF9F7AEA),
        const Color(0xFF38B2AC),
        const Color(0xFFECC94B),
        const Color(0xFFE53E3E),
        const Color(0xFF805AD5),
        const Color(0xFF3182CE),
        const Color(0xFF2F855A),
      ];

      final result = <ZoneData>[];
      final totalPersonnel = filteredAssignments.fold<Set<int>>(
        <int>{},
        (Set<int> acc, assignment) {
          for (var group in assignment.groups) {
            acc.addAll(group.workers);
          }
          return acc;
        },
      ).length;

      zoneAssignments.forEach((zone, assignments) {
        final Set<int> uniqueWorkerIds = {};
        Map<String, int> taskCounts = {};
        Map<String, int> statusCounts = {};

        for (var assignment in assignments) {
          // Contar trabajadores únicos
          for (var group in assignment.groups) {
            uniqueWorkerIds.addAll(group.workers);
          }

          // Contar por estado y tipo
          statusCounts[assignment.status] =
              (statusCounts[assignment.status] ?? 0) + 1;
          // final taskType = assignment.type ?? 'Sin tipo';
          // taskCounts[taskType] = (taskCounts[taskType] ?? 0) + 1;
        }

        final personnelCount = uniqueWorkerIds.length;
        final percentage =
            totalPersonnel > 0 ? (personnelCount / totalPersonnel) * 100 : 0.0;

        result.add(ZoneData(
          name: 'Zona $zone',
          personnel: personnelCount,
          color: zoneColors[(zone - 1) % zoneColors.length],
          totalAssignments: assignments.length,
          taskCounts: taskCounts,
          statusCounts: statusCounts,
          zoneNumber: zone,
          dateRange:
              '${DateFormat('dd/MM/yyyy').format(widget.startDate)} - ${DateFormat('dd/MM/yyyy').format(widget.endDate)}',
          percentage: percentage,
        ));
      });

      result.sort((a, b) => b.value.compareTo(a.value));
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
        Expanded(
          flex: 3,
          child: _buildPieChart(),
        ),
        const SizedBox(height: 16),
        Expanded(
          flex: 2,
          child: _buildLegendWithDetails(),
        ),
      ],
    );
  }

  Widget _buildPieChart() {
    return Center(
      child: SizedBox(
        width: 240,
        height: 240,
        child: Stack(
          children: [
            CustomPaint(
              size: const Size(240, 240),
              painter: PieChartPainter(data, selectedIndex),
            ),
            Center(
              child: ChartCenterInfo(
                data: data,
                selectedIndex: selectedIndex,
                totalLabel: 'Personal',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendWithDetails() {
    return Column(
      children: [
        if (selectedIndex != -1) _buildSelectedZoneDetail(data[selectedIndex]),
        Expanded(
          child: ChartLegend(
            data: data,
            selectedIndex: selectedIndex,
            onItemTap: (index) {
              setSelectedIndex(selectedIndex == index ? -1 : index);
            },
            horizontal: false,
            valueLabel: 'personal',
            showPercentage: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedZoneDetail(ZoneData zoneData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: zoneData.color.withOpacity(0.5)),
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
              Icon(Icons.location_on, color: zoneData.color, size: 16),
              const SizedBox(width: 8),
              Text(
                zoneData.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: zoneData.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Personal:', '${zoneData.value}'),
          _buildInfoRow('Operaciones:', '${zoneData.totalAssignments}'),
          if (zoneData.taskCounts.isNotEmpty) ...[
            const Divider(),
            ...zoneData.taskCounts.entries.take(3).map(
                  (e) => _buildInfoRow(e.key, '${e.value}'),
                ),
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
}
