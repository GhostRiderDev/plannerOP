import 'package:flutter/material.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/services/operations/operationReports.dart';
import 'package:plannerop/utils/charts/baseChart.dart';
import 'package:plannerop/utils/charts/chartData.dart';
import 'package:plannerop/utils/charts/painters.dart';
import 'package:plannerop/utils/charts/legend.dart';

class HourlyDistributionChart extends BaseChart<ChartData> {
  const HourlyDistributionChart({
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
  State<HourlyDistributionChart> createState() =>
      _HourlyDistributionChartState();
}

class _HourlyDistributionChartState
    extends BaseChartState<ChartData, HourlyDistributionChart> {
  HourlyDistributionResponse? _distributionResponse;
  final PaginatedOperationsService _operationsService =
      PaginatedOperationsService();

  List<ChartData> _data = [];
  bool _isLoading = true;
  String? _errorMessage;
  int selectedIndex = -1;

  @override
  String get chartTitle => 'Distribución Horaria de Trabajadores';

  @override
  void initState() {
    super.initState();
    _loadHourlyData();
  }

  @override
  void didUpdateWidget(HourlyDistributionChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate) {
      _loadHourlyData();
    }
  }

  Future<void> _loadHourlyData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint(
          'Cargando distribución horaria para fecha: ${widget.startDate}');

      final distributionResponse =
          await _operationsService.fetchHourlyDistribution(
        context,
        widget.startDate,
      );

      if (!mounted) return;

      debugPrint('Respuesta recibida: ${distributionResponse != null}');

      if (distributionResponse != null) {
        debugPrint(
            'Datos de distribución: ${distributionResponse.distribution.length} franjas horarias');

        setState(() {
          _distributionResponse = distributionResponse;
          _data = distributionResponse.distribution
              .map((item) => HourlyDistributionData(
                    color: _getColorForHour(item.hour),
                    hour: item.hour,
                    workerCount: item.workerCount,
                    workers: item.workers,
                  ))
              .toList();
          _isLoading = false;
        });

        debugPrint('Datos procesados: ${_data.length} elementos');
        for (var item in _data) {
          debugPrint('  ${item.name}: ${item.value} trabajadores');
        }
      } else {
        setState(() {
          _errorMessage =
              'No se pudieron cargar los datos de distribución horaria';
          _isLoading = false;
          _data = [];
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Error al cargar datos: $e';
        _isLoading = false;
        _data = [];
      });

      debugPrint('Error en _loadHourlyData: $e');
    }
  }

  Color _getColorForHour(String hour) {
    // Extraer la hora inicial de la franja (ej: "06:00-07:00" -> 6)
    final hourInt = int.tryParse(hour.split(':')[0]) ?? 0;

    // Colores según la hora del día
    if (hourInt >= 6 && hourInt < 12) {
      return const Color(0xFF38A169); // Verde para mañana
    } else if (hourInt >= 12 && hourInt < 18) {
      return const Color(0xFF3182CE); // Azul para tarde
    } else if (hourInt >= 18 && hourInt < 24) {
      return const Color(0xFFED8936); // Naranja para noche
    } else {
      return const Color(0xFF805AD5); // Púrpura para madrugada
    }
  }

  @override
  List<ChartData> processAssignmentData(List<Operation> assignments) {
    return _data;
  }

  @override
  Widget buildChart() {
    if (_data.isEmpty) {
      return buildEmptyState() ?? Container();
    }

    return Column(
      children: [
        // Información de la fecha
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF3182CE).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF3182CE).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today,
                  size: 16, color: Color(0xFF3182CE)),
              const SizedBox(width: 8),
              Text(
                'Fecha: ${_distributionResponse?.date ?? widget.startDate.toString().split(' ')[0]}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF3182CE),
                ),
              ),
            ],
          ),
        ),

        // Gráfico principal con scroll horizontal (sin interacción)
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: (_data.length * 60.0)
                  .clamp(400.0, double.infinity), // Ancho mínimo y dinámico
              child: CustomPaint(
                size: Size((_data.length * 60.0).clamp(400.0, double.infinity),
                    double.infinity),
                painter: HourlyLineChartPainter(
                  _data.cast<HourlyDistributionData>(),
                  selectedIndex,
                  maxValue: _data.isNotEmpty
                      ? _data
                          .map((e) => e.value)
                          .reduce((a, b) => a > b ? a : b)
                          .toDouble()
                      : 10.0,
                ),
              ),
            ),
          ),
        ),

        // Leyenda con scroll horizontal e interacción
        Expanded(
          flex: 2,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Text(
                'Franjas Horarias (Toca para ver detalles)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ChartLegend(
                    data: _data,
                    selectedIndex: selectedIndex,
                    onItemTap: (index) {
                      setState(() {
                        selectedIndex = selectedIndex == index ? -1 : index;
                      });

                      // Mostrar modal con detalles cuando se toca la etiqueta
                      if (selectedIndex != -1 &&
                          _distributionResponse != null &&
                          index < _distributionResponse!.distribution.length) {
                        _showWorkerDetailsModal(context,
                            _distributionResponse!.distribution[index]);
                      }
                    },
                    horizontal: true,
                    valueLabel: 'trabajadores',
                    showPercentage: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showWorkerDetailsModal(
      BuildContext context, HourlyDistributionData data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header con el color de la hora
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.1),
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: data.color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Franja Horaria: ${data.hour}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          '${data.workerCount} trabajadores activos',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Lista de trabajadores
            Expanded(
              child: data.workers.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off,
                              size: 48, color: Color(0xFF718096)),
                          SizedBox(height: 16),
                          Text(
                            'No hay trabajadores en esta franja horaria',
                            style: TextStyle(color: Color(0xFF718096)),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: data.workers.length,
                      itemBuilder: (context, index) {
                        final worker = data.workers[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: data.color,
                              child: Text(
                                worker.name.isNotEmpty
                                    ? worker.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              worker.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.badge,
                                        size: 14, color: Color(0xFF718096)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'DNI: ${worker.dni}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF718096),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.tag,
                                        size: 14, color: Color(0xFF718096)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'ID: ${worker.id}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF718096),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF38A169).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Activo',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF38A169),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget? buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule, size: 48, color: Color(0xFF718096)),
          SizedBox(height: 16),
          Text(
            'No hay datos de distribución horaria para la fecha seleccionada',
            style: TextStyle(color: Color(0xFF718096)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
