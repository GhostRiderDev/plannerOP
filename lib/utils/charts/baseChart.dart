import 'package:flutter/material.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/services/operations/operationReports.dart';
import 'package:plannerop/utils/charts/mapper.dart';
import 'package:plannerop/widgets/operations/components/utils/Loader.dart';

abstract class BaseChart<T> extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String area;
  final int? zone;
  final String? motorship;
  final String? status;

  const BaseChart({
    Key? key,
    required this.startDate,
    required this.endDate,
    required this.area,
    this.zone,
    this.motorship,
    this.status,
  }) : super(key: key);
}

abstract class BaseChartState<T, W extends BaseChart<T>> extends State<W> {
  late List<T> _data;
  int _selectedIndex = -1;
  bool _isLoading = true;
  String? _errorMessage;
  final PaginatedOperationsService _operationsService =
      PaginatedOperationsService();

  List<T> get data => _data;
  int get selectedIndex => _selectedIndex;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Métodos abstractos que cada gráfico debe implementar
  String get chartTitle;
  List<T> processAssignmentData(List<Operation> assignments);
  Widget buildChart();
  Widget? buildEmptyState() => null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(W oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate ||
        oldWidget.area != widget.area ||
        oldWidget.zone != widget.zone ||
        oldWidget.motorship != widget.motorship ||
        oldWidget.status != widget.status) {
      _loadData();
    }
  }

  void _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Convertir estado UI a estado de API si es necesario
      List<String>? apiStatuses;
      if (widget.status != null &&
          widget.status!.isNotEmpty &&
          widget.status != 'Todos') {
        apiStatuses = [StatusMapper.mapUIStatusToAPI(widget.status!)];
      }

      // Obtener operaciones de la API con el rango de fechas y estados
      final operations = await _operationsService.fetchOperationsByDateRange(
        context,
        widget.startDate,
        widget.endDate,
        statuses: apiStatuses,
      );

      if (!mounted) return;

      // Procesar los datos específicos del gráfico
      final processedData = processAssignmentData(operations);

      setState(() {
        _data = processedData;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Error al cargar datos: $e';
        _isLoading = false;
        _data = [];
      });

      debugPrint('Error en _loadData: $e');
    }
  }

  void setSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void setError(String error) {
    setState(() {
      _errorMessage = error;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            chartTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
        if (_isLoading)
          AppLoader(
            size: LoaderSize.medium,
            color: Colors.blue,
          )
        else if (_errorMessage != null)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          )
        else if (_data.isEmpty)
          Expanded(
            child: buildEmptyState() ??
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart, size: 48, color: Color(0xFF718096)),
                      SizedBox(height: 16),
                      Text(
                        'No hay datos disponibles para el filtro seleccionado',
                        style: TextStyle(color: Color(0xFF718096)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
          )
        else
          Expanded(child: buildChart()),
      ],
    );
  }
}
