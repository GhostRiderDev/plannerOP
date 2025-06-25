import 'package:flutter/material.dart';
import 'package:plannerop/widgets/operations/components/utils/Loader.dart';
import 'package:provider/provider.dart';
import 'package:plannerop/store/workers.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/utils/charts/chartData.dart';
import 'package:plannerop/utils/charts/painters.dart';
import 'package:plannerop/utils/charts/info.dart';
import 'package:plannerop/utils/charts/legend.dart';

class WorkerStatusChart extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String area;

  const WorkerStatusChart({
    Key? key,
    required this.startDate,
    required this.endDate,
    required this.area,
  }) : super(key: key);

  @override
  State<WorkerStatusChart> createState() => _WorkerStatusChartState();
}

class _WorkerStatusChartState extends State<WorkerStatusChart> {
  late List<WorkerStatusData> _statusData;
  int _selectedIndex = -1;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(WorkerStatusChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.area != widget.area) {
      _loadData();
    }
  }

  void _loadData() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
  }

  List<WorkerStatusData> processWorkersData(List<Worker> workers) {
    try {
      final filteredWorkers = widget.area == 'Todas'
          ? workers
          : workers.where((worker) => worker.area == widget.area).toList();

      final Map<String, int> statusCount = {
        'Disponible': 0,
        'Asignado': 0,
        'Incapacitado': 0,
        'Retirado': 0,
      };

      for (var worker in filteredWorkers) {
        switch (worker.status) {
          case WorkerStatus.available:
            statusCount['Disponible'] = (statusCount['Disponible'] ?? 0) + 1;
            break;
          case WorkerStatus.assigned:
            statusCount['Asignado'] = (statusCount['Asignado'] ?? 0) + 1;
            break;
          case WorkerStatus.incapacitated:
            statusCount['Incapacitado'] =
                (statusCount['Incapacitado'] ?? 0) + 1;
            break;
          case WorkerStatus.deactivated:
            statusCount['Retirado'] = (statusCount['Retirado'] ?? 0) + 1;
            break;
          default:
            break;
        }
      }

      final total =
          statusCount.values.fold<int>(0, (sum, count) => sum + count);

      final List<WorkerStatusData> result = [
        WorkerStatusData('Disponible', statusCount['Disponible'] ?? 0,
            const Color(0xFF48BB78), total),
        WorkerStatusData('Asignado', statusCount['Asignado'] ?? 0,
            const Color(0xFF4299E1), total),
        WorkerStatusData('Incapacitado', statusCount['Incapacitado'] ?? 0,
            const Color(0xFFF56565), total),
        WorkerStatusData('Retirado', statusCount['Retirado'] ?? 0,
            const Color(0xFF718096), total),
      ];

      return result;
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al procesar datos: $e';
      });
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkersProvider>(
      builder: (context, workersProvider, child) {
        final workers = workersProvider.workers;

        if (_isLoading && workers.isNotEmpty) {
          _statusData = processWorkersData(workers);
          _isLoading = false;
        }

        if (_isLoading && workers.isEmpty && !workersProvider.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            workersProvider.fetchWorkersIfNeeded(context);
          });
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Estado de Trabajadores',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
            if (_isLoading || workersProvider.isLoading)
              AppLoader(
                size: LoaderSize.medium,
                color: Colors.blue,
              )
            else if (_errorMessage != null)
              Expanded(
                child: Center(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (_statusData.isEmpty || workers.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No hay datos disponibles para el filtro seleccionado',
                    style: TextStyle(color: Color(0xFF718096)),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Expanded(child: _buildChart()),
          ],
        );
      },
    );
  }

  Widget _buildChart() {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                children: [
                  CustomPaint(
                    size: const Size(200, 200),
                    painter: DonutChartPainter(
                      _statusData,
                      _selectedIndex,
                      innerRadiusRatio: 0.5,
                    ),
                  ),
                  Center(
                    child: ChartCenterInfo(
                      data: _statusData,
                      selectedIndex: _selectedIndex,
                      totalLabel: 'Trabajadores',
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
          child: ChartLegend(
            data: _statusData,
            selectedIndex: _selectedIndex,
            onItemTap: (index) {
              setState(() {
                _selectedIndex = _selectedIndex == index ? -1 : index;
              });
            },
            horizontal: false,
            valueLabel: 'trabajadores',
            showPercentage: true,
          ),
        ),
      ],
    );
  }
}

// Actualizar WorkerStatusData para extender ChartData
class WorkerStatusData extends ChartData {
  WorkerStatusData(String status, int count, Color color, int total)
      : super(
          name: status,
          value: count,
          color: color,
          percentage: total > 0 ? (count / total) * 100 : 0.0,
        );
}
