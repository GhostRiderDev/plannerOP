import 'dart:io';

import 'package:flutter/material.dart' hide Border;
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart' hide Border;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/services/operations/operationReports.dart';

import 'package:plannerop/utils/charts/mapper.dart';

import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/operations/components/utils/Loader.dart';
import 'package:plannerop/widgets/reports/exports/excelGenerator.dart';
import 'package:plannerop/widgets/reports/exports/reportDataProcessor.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/painting.dart' show Border, BorderSide;
import 'package:permission_handler/permission_handler.dart';

class ExportOptions extends StatefulWidget {
  final String periodName;
  final DateTime startDate;
  final DateTime endDate;
  final String area;
  final int? zone;
  final String? motorship;
  final String? status;
  final Function(String) onExport;

  const ExportOptions({
    Key? key,
    required this.periodName,
    required this.startDate,
    required this.endDate,
    required this.area,
    required this.onExport,
    this.zone,
    this.motorship,
    this.status,
  }) : super(key: key);

  @override
  State<ExportOptions> createState() => _ExportOptionsState();
}

class _ExportOptionsState extends State<ExportOptions> {
  List<Operation> _filteredAssignments = [];
  bool _isLoading = true;
  String? _errorMessage;

  final PaginatedOperationsService _operationsService =
      PaginatedOperationsService();

  @override
  void initState() {
    super.initState();
    _loadFilteredData();
  }

  @override
  void didUpdateWidget(ExportOptions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate ||
        oldWidget.area != widget.area ||
        oldWidget.zone != widget.zone ||
        oldWidget.motorship != widget.motorship ||
        oldWidget.status != widget.status) {
      _loadFilteredData();
    }
  }

  Future<void> _loadFilteredData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Cargando datos filtrados para exportación...');

      List<String>? apiStatuses;
      if (widget.status != null &&
          widget.status!.isNotEmpty &&
          widget.status != 'Todos') {
        apiStatuses = [StatusMapper.mapUIStatusToAPI(widget.status!)];
      }

      if (widget.status == 'Todos' || widget.status == null) {
        apiStatuses = ["COMPLETED", "PENDING", "INPROGRESS"];
      }

      final operations = await _operationsService.fetchOperationsByDateRange(
        context,
        widget.startDate,
        widget.endDate,
        statuses: apiStatuses,
      );

      if (!mounted) return;

      final filteredOperations = operations.where((operation) {
        if (widget.area != 'Todas' && operation.area != widget.area) {
          return false;
        }

        if (widget.zone != null) {
          int? operationZone;
          try {
            operationZone = operation.zone != null
                ? int.tryParse(operation.zone.toString())
                : null;
          } catch (e) {
            operationZone = null;
          }
          if (operationZone != widget.zone) {
            return false;
          }
        }

        if (widget.motorship != null && widget.motorship!.isNotEmpty) {
          if (operation.motorship == null ||
              operation.motorship != widget.motorship) {
            return false;
          }
        }

        return true;
      }).toList();

      setState(() {
        _filteredAssignments = filteredOperations;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando datos filtrados: $e');
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Error al cargar datos: $e';
        _isLoading = false;
        _filteredAssignments = [];
      });
    }
  }

  void _simulateExport(String type) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: AppLoader(
                message: 'Exportando $type...',
                color: Colors.blue,
                size: LoaderSize.medium,
              )),
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      Navigator.pop(context);

      switch (type) {
        case 'Excel Detallado':
          _exportDetailedExcel();
          break;
      }
    });
  }

  Future<void> _exportDetailedExcel() async {
    try {
      widget.onExport('Generando Excel detallado...');

      if (_filteredAssignments.isEmpty) {
        widget.onExport('No hay datos para exportar');
        return;
      }

      // Procesar datos
      final reportData = await ReportDataProcessor.processOperations(
          _filteredAssignments, _getReportTitle(), _getDateRange(), context);

      // ✅ USAR SOLO DIRECTORIO TEMPORAL (NO NECESITA PERMISOS)
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'reporte_operaciones_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File('${tempDir.path}/$fileName');

      // Generar Excel
      await ExcelGenerator.generateReportAtPath(reportData, file.path);

      // Compartir
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: reportData.reportTitle,
        text: 'Adjunto el reporte detallado de operaciones.',
      );

      widget.onExport('Excel detallado exportado correctamente');
    } catch (e) {
      debugPrint('Error al exportar Excel: $e');
      widget.onExport('Error al exportar: $e');
    }
  }

  String _getReportTitle() {
    String reportTitle = 'Reporte de Operaciones';

    if (widget.area != 'Todas') {
      reportTitle += ' - ${widget.area}';
    }

    if (widget.zone != null) {
      reportTitle += ' - Zona ${widget.zone}';
    }

    if (widget.motorship != null && widget.motorship!.isNotEmpty) {
      reportTitle += ' - ${widget.motorship}';
    }

    if (widget.status != null && widget.status!.isNotEmpty) {
      reportTitle += ' - ${widget.status}';
    }

    return reportTitle;
  }

  void _showErrorSnackbar(dynamic error) {
    showErrorToast(
        context, 'Error al exportar: ${error.toString().substring(0, 50)}');
  }

  String _getDateRange() {
    return widget.periodName == "Personalizado"
        ? "${DateFormat('dd/MM/yyyy').format(widget.startDate)} - ${DateFormat('dd/MM/yyyy').format(widget.endDate)}"
        : widget.periodName;
  }

  @override
  Widget build(BuildContext context) {
    String dateRange = _getDateRange();
    String reportTitle = _getReportTitle();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFF7FAFC),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.file_download,
                  color: Color(0xFF3182CE), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Exportar Reporte',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3182CE).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: AppLoader(
                size: LoaderSize.medium,
                color: const Color(0xFF3182CE),
                message: 'Cargando datos...',
              ),
            )
          else if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(_errorMessage!,
                          style: const TextStyle(color: Colors.red))),
                  TextButton(
                    onPressed: _loadFilteredData,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3182CE).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: const Color(0xFF3182CE).withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Título', reportTitle),
                  const SizedBox(height: 8),
                  _buildInfoRow('Período', dateRange),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                      'Operaciones', '${_filteredAssignments.length}'),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                      'Trabajadores', _getTotalWorkersCount().toString()),
                ],
              ),
            ),
          const SizedBox(height: 24),
          _buildExportButton(
            icon: Icons.table_chart,
            label: 'Exportar Excel Detallado (2 Hojas)',
            color: const Color(0xFF38A169),
            onPressed: _isLoading || _filteredAssignments.isEmpty
                ? null
                : () => _simulateExport('Excel Detallado'),
          ),
        ],
      ),
    );
  }

  int _getTotalWorkersCount() {
    int totalWorkers = 0;
    for (var operation in _filteredAssignments) {
      for (var group in operation.groups) {
        totalWorkers += group.workers.length;
      }
    }
    return totalWorkers;
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A5568),
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Color(0xFF2D3748), fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildExportButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: NeumorphicButton(
        style: NeumorphicStyle(
          depth: onPressed != null ? 3 : 1,
          intensity: 0.7,
          color: onPressed != null ? color : Colors.grey,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
