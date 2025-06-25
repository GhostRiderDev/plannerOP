import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';

class ReportFilter extends StatefulWidget {
  final List<String> periods;
  final List<String> areas;
  final List<int> zones;
  final List<String> motorships;
  final List<String> statuses;
  final String selectedPeriod;
  final String selectedArea;
  final int? selectedZone;
  final String? selectedMotorship;
  final String? selectedStatus;
  final DateTime startDate;
  final DateTime endDate;
  final Function({
    String? period,
    String? area,
    int? zone,
    String? motorship,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) onApply;
  final bool isChartsView;

  const ReportFilter({
    Key? key,
    required this.periods,
    required this.areas,
    required this.zones,
    required this.motorships,
    required this.statuses,
    required this.selectedPeriod,
    required this.selectedArea,
    this.selectedZone,
    this.selectedMotorship,
    this.selectedStatus,
    required this.startDate,
    required this.endDate,
    required this.onApply,
    required this.isChartsView,
  }) : super(key: key);

  @override
  State<ReportFilter> createState() => _ReportFilterState();
}

class _ReportFilterState extends State<ReportFilter> {
  late String _period;
  late String _area;
  int? _zone;
  String? _motorship;
  String? _status;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isRangeMode = false; // Para alternar entre fecha única y rango

  @override
  void initState() {
    super.initState();
    _initializeFilters();
  }

  @override
  void didUpdateWidget(ReportFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPeriod != widget.selectedPeriod ||
        oldWidget.selectedArea != widget.selectedArea ||
        oldWidget.selectedZone != widget.selectedZone ||
        oldWidget.selectedMotorship != widget.selectedMotorship ||
        oldWidget.selectedStatus != widget.selectedStatus ||
        oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate) {
      _initializeFilters();
    }
  }

  void _initializeFilters() {
    _period = widget.selectedPeriod;
    _area = widget.selectedArea;
    _zone = widget.selectedZone;
    _motorship = widget.selectedMotorship;
    _status = widget.selectedStatus;
    _startDate = widget.startDate;
    _endDate = widget.endDate;

    // Determinar si es modo rango basado en las fechas
    _isRangeMode = !_isSameDay(_startDate, _endDate);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _applyFiltersImmediately() {
    widget.onApply(
      period: 'Calendario',
      area: widget.isChartsView ? 'Todas' : _area,
      zone: widget.isChartsView ? null : _zone,
      motorship: widget.isChartsView ? null : _motorship,
      status: _status,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtrar reportes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              if (widget.isChartsView)
                IconButton(
                  icon: const Icon(Icons.info_outline,
                      size: 18, color: Color(0xFF718096)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'En modo gráficas, selecciona una fecha y estado para filtrar'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Contenido del filtro diferente según el modo
          widget.isChartsView
              ? _buildChartModeFilter()
              : _buildTableModeFilter(),

          const SizedBox(height: 24),

          // Botones
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              NeumorphicButton(
                style: NeumorphicStyle(
                  depth: 2,
                  intensity: 0.6,
                  color: Colors.white,
                  boxShape:
                      NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                ),
                onPressed: () {
                  setState(() {
                    _period = 'Hoy';
                    _area = 'Todas';
                    _zone = null;
                    _motorship = null;
                    _status = null;
                    _isRangeMode = false;

                    // Establecer fecha de hoy
                    final now = DateTime.now();
                    _startDate = DateTime(now.year, now.month, now.day);
                    _endDate =
                        DateTime(now.year, now.month, now.day, 23, 59, 59);
                  });

                  widget.onApply(
                    period: 'Hoy',
                    area: _area,
                    zone: _zone,
                    motorship: _motorship,
                    status: _status,
                    startDate: _startDate,
                    endDate: _endDate,
                  );
                },
                child: const Text(
                  'Restablecer',
                  style: TextStyle(
                    color: Color(0xFF718096),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              NeumorphicButton(
                style: NeumorphicStyle(
                  depth: 2,
                  intensity: 0.6,
                  color: const Color(0xFF3182CE),
                  boxShape:
                      NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                ),
                onPressed: () {
                  widget.onApply(
                    period: 'Calendario',
                    area: widget.isChartsView ? 'Todas' : _area,
                    zone: widget.isChartsView ? null : _zone,
                    motorship: widget.isChartsView ? null : _motorship,
                    status: _status,
                    startDate: _startDate,
                    endDate: _endDate,
                  );
                },
                child: const Text(
                  'Aplicar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Filtro simplificado para modo gráficas
  Widget _buildChartModeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Estado y selector de fecha
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                'Estado',
                _status,
                widget.statuses,
                (String? value) {
                  setState(() {
                    _status = value;
                  });
                  _applyFiltersImmediately();
                },
                nullOption: 'Todos',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCalendarSelector(),
            ),
          ],
        ),
      ],
    );
  }

  // Filtro completo para modo tabla
  Widget _buildTableModeFilter() {
    return Column(
      children: [
        // Primera fila: Calendario y Estado
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildCalendarSelector(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdown(
                'Estado',
                _status,
                widget.statuses,
                (String? value) {
                  setState(() {
                    _status = value;
                  });
                },
                nullOption: 'Todos',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Segunda fila: Área y Zona
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                'Área',
                _area,
                widget.areas,
                (String? value) {
                  if (value != null) {
                    setState(() {
                      _area = value;
                      _zone = null;
                      _motorship = null;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildIntDropdown(
                'Zona',
                _zone,
                widget.zones,
                (int? value) {
                  setState(() {
                    _zone = value;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Tercera fila: Motonave
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                'Motonave',
                _motorship,
                widget.motorships,
                (String? value) {
                  setState(() {
                    _motorship = value;
                  });
                },
                nullOption: 'Todas',
              ),
            ),
            const Expanded(child: SizedBox()), // Espacio vacío
          ],
        ),
      ],
    );
  }

  Widget _buildCalendarSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Fecha',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A5568),
              ),
            ),
            const Spacer(),
            // Toggle para modo rango
            if (!widget.isChartsView)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isRangeMode = !_isRangeMode;
                    if (!_isRangeMode) {
                      // Si cambiamos a fecha única, usar solo la fecha de inicio
                      _endDate = DateTime(_startDate.year, _startDate.month,
                          _startDate.day, 23, 59, 59);
                    }
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isRangeMode
                        ? const Color(0xFF3182CE).withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          _isRangeMode ? const Color(0xFF3182CE) : Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isRangeMode ? Icons.date_range : Icons.today,
                        size: 14,
                        color: _isRangeMode
                            ? const Color(0xFF3182CE)
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isRangeMode ? 'Rango' : 'Única',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _isRangeMode
                              ? const Color(0xFF3182CE)
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Selector de fecha
        Neumorphic(
          style: NeumorphicStyle(
            depth: -2,
            intensity: 0.6,
            color: Colors.white,
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
          ),
          child: InkWell(
            onTap: _showDateSelector,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    _isRangeMode ? Icons.date_range : Icons.today,
                    color: const Color(0xFF3182CE),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isRangeMode
                              ? 'Rango de fechas'
                              : 'Fecha seleccionada',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getDateDisplayText(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF718096),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getDateDisplayText() {
    if (_isRangeMode) {
      if (_isSameDay(_startDate, _endDate)) {
        return DateFormat('dd/MM/yyyy').format(_startDate);
      }
      return '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}';
    } else {
      return DateFormat('dd/MM/yyyy').format(_startDate);
    }
  }

  Future<void> _showDateSelector() async {
    if (_isRangeMode) {
      // Mostrar selector de rango
      final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        initialDateRange: DateTimeRange(
          start: _startDate,
          end: DateTime(_endDate.year, _endDate.month, _endDate.day),
        ),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF3182CE),
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        setState(() {
          _startDate =
              DateTime(picked.start.year, picked.start.month, picked.start.day);
          _endDate = DateTime(
              picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
        });

        if (widget.isChartsView) {
          _applyFiltersImmediately();
        }
      }
    } else {
      // Mostrar selector de fecha única
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _startDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF3182CE),
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        setState(() {
          _startDate = DateTime(picked.year, picked.month, picked.day);
          _endDate =
              DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        });

        if (widget.isChartsView) {
          _applyFiltersImmediately();
        }
      }
    }
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged, {
    String? nullOption,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 8),
        Neumorphic(
          style: NeumorphicStyle(
            depth: -2,
            intensity: 0.6,
            color: Colors.white,
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(nullOption ?? 'Seleccionar...'),
              items: [
                if (nullOption != null)
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(nullOption),
                  ),
                ...items.map((item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    )),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIntDropdown(
    String label,
    int? value,
    List<int> items,
    ValueChanged<int?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 8),
        Neumorphic(
          style: NeumorphicStyle(
            depth: -2,
            intensity: 0.6,
            color: Colors.white,
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              hint: const Text('Todas'),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('Todas'),
                ),
                ...items.map((item) => DropdownMenuItem<int>(
                      value: item,
                      child: Text('Zona $item'),
                    )),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
