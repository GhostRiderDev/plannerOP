import 'package:flutter/material.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/services/operations/operationReports.dart';

class ReportsProvider extends ChangeNotifier {
  // Estado de filtros
  String _selectedPeriod = "Hoy";
  String _selectedArea = "Todas";
  int? _selectedZone;
  String? _selectedMotorship;
  String? _selectedStatus;
  late DateTime _startDate;
  late DateTime _endDate;

  // Estado de UI
  bool _isLoadingFilterData = false;
  bool _isFiltering = false;
  bool _isExporting = false;
  bool _showCharts = true;
  String _selectedChart = "Distribución por Áreas";

  // Datos
  List<String> _areas = [];
  List<int> _zones = List.generate(10, (index) => index + 1);
  List<String> _motorships = [];
  final List<String> _statuses = [
    "Completada",
    "En curso",
    "Pendiente",
    "Cancelada"
  ];

  final PaginatedOperationsService _operationsService =
      PaginatedOperationsService();

  // Getters
  String get selectedPeriod => _selectedPeriod;
  String get selectedArea => _selectedArea;
  int? get selectedZone => _selectedZone;
  String? get selectedMotorship => _selectedMotorship;
  String? get selectedStatus => _selectedStatus;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  bool get isLoadingFilterData => _isLoadingFilterData;
  bool get isFiltering => _isFiltering;
  bool get isExporting => _isExporting;
  bool get showCharts => _showCharts;
  String get selectedChart => _selectedChart;
  List<String> get areas => _areas;
  List<int> get zones => _zones;
  List<String> get motorships => _motorships;
  List<String> get statuses => _statuses;

  ReportsProvider() {
    _initializeDates();
  }

  void _initializeDates() {
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  Future<void> loadFilterData(BuildContext context) async {
    if (_isLoadingFilterData) return;

    _isLoadingFilterData = true;
    notifyListeners();

    try {
      final DateTime rangeStart =
          DateTime.now().subtract(const Duration(days: 30));
      final DateTime rangeEnd = DateTime.now().add(const Duration(days: 1));

      final List<Operation> operations =
          await _operationsService.fetchOperationsByDateRange(
        context,
        rangeStart,
        rangeEnd,
      );

      final areasSet = operations.map((a) => a.area).toSet();
      final areasList = ['Todas', ...areasSet.toList()..sort()];

      final motorshipsSet = operations
          .where((a) => a.motorship != null && a.motorship!.isNotEmpty)
          .map((a) => a.motorship!)
          .toSet();
      final motorshipsList = motorshipsSet.toList()..sort();

      _areas = areasList;
      _motorships = motorshipsList;
    } catch (e) {
      _areas = ['Todas'];
      _motorships = [];
      debugPrint('Error cargando datos de filtro: $e');
    } finally {
      _isLoadingFilterData = false;
      notifyListeners();
    }
  }

  void applyFilter({
    String? period,
    String? area,
    int? zone,
    String? motorship,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (period != null) {
      _selectedPeriod = period;
      if (startDate == null && endDate == null) {
        _updateDatesForPeriod(period);
      }
    }

    if (area != null) _selectedArea = area;
    _selectedZone = zone;
    _selectedMotorship = motorship;
    _selectedStatus = status;

    if (startDate != null && endDate != null) {
      _startDate = startDate;
      _endDate = endDate;
    }

    _isFiltering = false;
    notifyListeners();
  }

  void _updateDatesForPeriod(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'Hoy':
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'Ayer':
        final yesterday = now.subtract(const Duration(days: 1));
        _startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
        _endDate = DateTime(
            yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        break;
      case 'Semana':
        _startDate = now.subtract(Duration(days: now.weekday - 1));
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'Mes':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
    }
  }

  void toggleFilterPanel() {
    _isFiltering = !_isFiltering;
    if (_isFiltering) _isExporting = false;
    notifyListeners();
  }

  void toggleExportPanel() {
    _isExporting = !_isExporting;
    if (_isExporting) _isFiltering = false;
    notifyListeners();
  }

  void toggleView() {
    _showCharts = !_showCharts;
    notifyListeners();
  }

  void setSelectedChart(String chart) {
    _selectedChart = chart;
    notifyListeners();
  }
}
