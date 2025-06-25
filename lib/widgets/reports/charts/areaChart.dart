import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/utils/charts/baseChart.dart';
import 'package:plannerop/utils/charts/chartData.dart';
import 'package:plannerop/utils/charts/painters.dart';
import 'package:plannerop/utils/charts/info.dart';
import 'package:plannerop/utils/charts/legend.dart';
import 'package:plannerop/utils/charts/mapper.dart';
// sqrt enable import

class AreaDistributionChart extends BaseChart<AreaData> {
  const AreaDistributionChart({
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
  State<AreaDistributionChart> createState() => _AreaDistributionChartState();
}

class _AreaDistributionChartState
    extends BaseChartState<AreaData, AreaDistributionChart> {
  @override
  String get chartTitle => 'Distribución por Áreas';

  @override
  List<AreaData> processAssignmentData(List<Operation> assignments) {
    try {
      debugPrint('AreaChart: Procesando ${assignments.length} operaciones');

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

      debugPrint(
          'AreaChart: ${filteredAssignments.length} operaciones después del filtrado');

      if (filteredAssignments.isEmpty) {
        debugPrint('AreaChart: No hay operaciones filtradas');
        return [];
      }

      // Agrupar por área
      final Map<String, List<Operation>> areaAssignments = {};
      for (var assignment in filteredAssignments) {
        final areaName =
            assignment.area.isNotEmpty ? assignment.area : 'Sin área';
        if (!areaAssignments.containsKey(areaName)) {
          areaAssignments[areaName] = [];
        }
        areaAssignments[areaName]!.add(assignment);
      }

      debugPrint(
          'AreaChart: Áreas encontradas: ${areaAssignments.keys.toList()}');

      // Colores para áreas
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

      final result = <AreaData>[];
      int colorIndex = 0;

      // Ordenar por cantidad de personal
      final sortedEntries = areaAssignments.entries.toList()
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

      // Calcular total de personal para porcentajes
      final totalPersonnel = filteredAssignments.fold<Set<int>>(
        <int>{},
        (Set<int> acc, assignment) {
          for (var group in assignment.groups) {
            acc.addAll(group.workers);
          }
          return acc;
        },
      ).length;

      debugPrint('AreaChart: Total de personal único: $totalPersonnel');

      for (var entry in sortedEntries) {
        final areaName = entry.key;
        final assignments = entry.value;
        final totalAssignments = assignments.length;

        // Calcular personal único
        final Set<int> uniqueWorkerIds = {};
        for (var assignment in assignments) {
          for (var group in assignment.groups) {
            uniqueWorkerIds.addAll(group.workers);
          }
        }

        final personnelCount = uniqueWorkerIds.length;
        double percentage = 0;
        if (totalPersonnel > 0) {
          percentage = (personnelCount / totalPersonnel) * 100;
        }

        debugPrint(
            'AreaChart: Área $areaName - $personnelCount trabajadores, $totalAssignments operaciones');

        result.add(AreaData(
          name: areaName,
          personnel: personnelCount,
          color: colorPalette[colorIndex % colorPalette.length],
          assignments: totalAssignments,
          dateRange:
              '${DateFormat('dd/MM/yyyy').format(widget.startDate)} - ${DateFormat('dd/MM/yyyy').format(widget.endDate)}',
          percentage: percentage,
        ));

        colorIndex++;
      }

      debugPrint('AreaChart: Resultado final: ${result.length} áreas');
      for (var area in result) {
        debugPrint('  - ${area.name}: ${area.value} trabajadores');
      }

      return result;
    } catch (e) {
      debugPrint('AreaChart: Error al procesar datos: $e');
      setError('Error al procesar datos: $e');
      return [];
    }
  }

  // Método personalizado para manejar la selección/deselección
  void _handleItemTap(int index) {
    debugPrint('Item tapped: $index, current selected: $selectedIndex');

    // Si el índice clickeado es el mismo que el seleccionado, deseleccionar
    if (selectedIndex == index) {
      setSelectedIndex(-1);
      debugPrint('Deselected item');
    } else {
      setSelectedIndex(index);
      debugPrint('Selected item: $index');
    }
  }

  @override
  Widget buildChart() {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Center(
            child: SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                children: [
                  // Hacer el gráfico circular clickeable
                  GestureDetector(
                    onTapDown: (details) => _handleChartTap(details),
                    child: CustomPaint(
                      size: const Size(240, 240),
                      painter: DonutChartPainter(
                        data,
                        selectedIndex,
                        innerRadiusRatio: 0.4,
                      ),
                    ),
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
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              if (selectedIndex != -1 && selectedIndex < data.length)
                _buildSelectedInfo(data[selectedIndex]),
              Expanded(
                child: ChartLegend(
                  data: data,
                  selectedIndex: selectedIndex,
                  onItemTap:
                      _handleItemTap, // Usar nuestro método personalizado
                  horizontal: true,
                  valueLabel: 'personal',
                  showPercentage: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Método para manejar taps en el gráfico circular
  void _handleChartTap(TapDownDetails details) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset localPosition =
        renderBox.globalToLocal(details.globalPosition);

    // Calcular el centro del gráfico
    final center = Offset(120, 120); // 240/2 = 120
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);

    // Verificar si el tap está dentro del donut (entre radio interno y externo)
    const outerRadius = 120.0;
    const innerRadius = 48.0; // 120 * 0.4

    if (distance >= innerRadius && distance <= outerRadius && data.isNotEmpty) {
      // Calcular el ángulo
      double angle = (atan2(dy, dx) + pi) % (2 * pi);

      // Encontrar qué segmento fue tocado
      double totalValue = data.fold(0, (sum, item) => sum + item.value);
      double currentAngle = 0;

      for (int i = 0; i < data.length; i++) {
        double segmentAngle = 2 * pi * (data[i].value / totalValue);
        if (angle >= currentAngle && angle <= currentAngle + segmentAngle) {
          _handleItemTap(i);
          return;
        }
        currentAngle += segmentAngle;
      }
    }
  }

  Widget _buildSelectedInfo(AreaData areaData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: areaData.color.withOpacity(0.5)),
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
              Icon(Icons.business, color: areaData.color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  areaData.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: areaData.color,
                  ),
                ),
              ),
              // Botón X para cerrar/deseleccionar
              GestureDetector(
                onTap: () => setSelectedIndex(-1),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Personal:', '${areaData.value}'),
          _buildInfoRow('Operaciones:', '${areaData.assignments}'),
          _buildInfoRow('Período:', areaData.dateRange),
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
