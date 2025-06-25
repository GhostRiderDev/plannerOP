import 'package:flutter/material.dart';
import 'package:plannerop/core/model/area.dart';
import 'package:plannerop/core/model/client.dart';
import 'package:plannerop/core/model/programming.dart';
import 'package:plannerop/widgets/operations/add/programmingSelector.dart';
import 'package:plannerop/widgets/operations/components/utils/timeField.dart';
import '../components/utils/dropdownField.dart';
import '../components/utils/dateField.dart';

class OperationForm extends StatefulWidget {
  final TextEditingController zoneController;
  final TextEditingController startDateController;
  final TextEditingController startTimeController;
  final TextEditingController taskController;
  final TextEditingController areaController;
  final TextEditingController clientController;
  final TextEditingController? endDateController;
  final TextEditingController? endTimeController;
  final TextEditingController programmingController;
  final List<String> currentTasks;
  final List<Area> areas;
  final List<Client> clients;
  final bool showEndDateTime;
  final TextEditingController? motorshipController;
  //propiedades de bloqueo basadas en grupos
  final bool startDateLocked;
  final bool startTimeLocked;
  final bool endDateLocked;
  final bool endTimeLocked;
  //función para cuando los horarios cambien
  final Function(DateTime?, DateTime?, String?, String?)? onScheduleChanged;
  final Function(Programming) onProgrammingSelected;

  const OperationForm({
    Key? key,
    required this.zoneController,
    required this.startDateController,
    required this.startTimeController,
    required this.taskController,
    required this.areaController,
    required this.currentTasks,
    required this.clientController,
    required this.clients,
    required this.areas,
    required this.programmingController,
    this.endDateController,
    this.endTimeController,
    this.motorshipController,
    this.showEndDateTime = false,
    this.startDateLocked = false,
    this.startTimeLocked = false,
    this.endDateLocked = false,
    this.endTimeLocked = false,
    this.onScheduleChanged,
    required this.onProgrammingSelected,
  }) : super(key: key);

  @override
  State<OperationForm> createState() => _AssignmentFormState();
}

class _AssignmentFormState extends State<OperationForm> {
  int _dateUpdateCounter = 0;
  int _timeUpdateCounter = 0;
  int _endDateUpdateCounter = 0;
  int _endTimeUpdateCounter = 0;
  bool _isShipArea = false;
  String? _selectedClientName;
  Programming? _selectedProgramming;

  @override
  void initState() {
    super.initState();

    // Añadir listeners a los controladores existentes
    widget.startTimeController.addListener(_onTimeChanged);
    widget.startDateController.addListener(_onDateChanged);
    if (widget.endTimeController != null) {
      widget.endTimeController!.addListener(_onEndTimeChanged);
    }
    if (widget.endDateController != null) {
      widget.endDateController!.addListener(_onEndDateChanged);
    }

    ;

    // Verificar si el area es BUQUE
    _checkIfShipArea(widget.areaController.text);

    // Inicializar el nombre del cliente si ya hay uno seleccionado
    if (widget.clientController.text.isNotEmpty) {
      _selectedClientName = widget.clientController.text;
    }
  }

  // Método para verificar si el área es de tipo "BUQUE"
  void _checkIfShipArea(String area) {
    setState(() {
      _isShipArea = area.toUpperCase() == 'BUQUE';
    });

    // Si el área ya no es buque, limpiar el campo de motonave
    if (!_isShipArea && widget.motorshipController != null) {
      widget.motorshipController!.clear();
    }
  }

  @override
  void dispose() {
    // Remover listeners existentes
    widget.startTimeController.removeListener(_onTimeChanged);
    widget.startDateController.removeListener(_onDateChanged);
    if (widget.endTimeController != null) {
      widget.endTimeController!.removeListener(_onEndTimeChanged);
    }
    if (widget.endDateController != null) {
      widget.endDateController!.removeListener(_onEndDateChanged);
    }

    super.dispose();
  }

  void _onEndTimeChanged() {
    setState(() {
      _endTimeUpdateCounter++;
    });
  }

  void _onEndDateChanged() {
    _handleEndDateChanged(widget.endDateController?.text ?? "");
  }

  void _handleEndDateChanged(String newDate) {
    // Actualizar el contador para forzar rebuild
    setState(() {
      _endDateUpdateCounter++;
    });

    // También resetear el campo de hora fin si es necesario
    if (widget.endTimeController != null &&
        widget.endTimeController!.text.isNotEmpty) {
      widget.endTimeController!.clear();
    }
  }

  void _onTimeChanged() {
    setState(() {
      _timeUpdateCounter++;
    });
  }

  void _onDateChanged() {
    _handleDateChanged(widget.startDateController.text);
  }

  void _handleDateChanged(String newDate) {
    // Actualizar el contador para forzar rebuild
    setState(() {
      _dateUpdateCounter++;
    });

    // También podríamos resetear el campo de hora si es necesario
    if (widget.startTimeController.text.isNotEmpty) {
      // Opcional: limpiar la hora si cambia la fecha, para forzar una nueva selección
      widget.startTimeController.clear();
    }

    // debugPrint('Fecha actualizada: $newDate, contador: $_dateUpdateCounter');
  }

  @override
  Widget build(BuildContext context) {
    // Crear la lista de zonas del 1 al 10
    final List<String> zones =
        List.generate(10, (index) => 'Zona ${index + 1}');

    return Column(
      children: [
        // Campo de selección de zona
        DropdownField(
          label: 'Área',
          hint: 'Seleccionar área',
          icon: Icons.location_on_outlined,
          controller: widget.areaController,
          options: widget.areas.map((area) => area.name).toList(),
          onSelected: (area) {
            // Esta es la línea clave que falta
            _checkIfShipArea(area);
            // debugPrint('Área seleccionada: $area');
          },
        ),

        if (_isShipArea && widget.motorshipController != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nombre de Motonave',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF4A5568),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: TextField(
                    controller: widget.motorshipController,
                    decoration: const InputDecoration(
                      hintText: 'Ingrese el nombre de la motonave',
                      prefixIcon: Icon(Icons.directions_boat,
                          size: 20, color: Color(0xFF718096)),
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Color(0xFFA0AEC0)),
                    ),
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ),

        // Campo de fecha de inicio - Ahora con callback
        DateField(
          label: 'Fecha de inicio',
          hint: 'DD/MM/AAAA',
          icon: Icons.calendar_today_outlined,
          controller: widget.startDateController,
          onDateChanged: _handleDateChanged,
          key: ValueKey('date_field_$_dateUpdateCounter'),
          locked: widget.startDateLocked,
          lockedMessage: widget.startDateLocked ? '' : null,
        ),

        // Campo de hora de inicio
        TimeField(
          label: 'Hora de inicio',
          hint: 'HH:MM',
          icon: Icons.schedule_outlined,
          controller: widget.startTimeController,
          dateController: widget.startDateController,
          // Añadir key para forzar reconstrucción cuando la fecha cambia
          key: ValueKey(
              'time_field_${_dateUpdateCounter}_${_timeUpdateCounter}'),
          locked: widget.startTimeLocked, // Pasar estado de bloqueo
          lockedMessage: widget.startTimeLocked
              ? 'Hora definida por grupo de trabajo'
              : null,
        ),

        // Mostrar campos opcionales de fecha y hora de fin si están habilitados
        if (widget.showEndDateTime && widget.endDateController != null) ...[
          // Divider con "opcional" para indicar que estos campos no son requeridos
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[300])),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    widget.endDateLocked || widget.endTimeLocked
                        ? "FINALIZACIÓN"
                        : "FINALIZACIÓN (OPCIONAL)",
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey[300])),
              ],
            ),
          ),

          // Campo de fecha de fin (opcional)
          DateField(
            label: 'Fecha de finalización',
            hint: 'DD/MM/AAAA',
            icon: Icons.event_outlined,
            controller: widget.endDateController!,
            onDateChanged: _handleEndDateChanged,
            key: ValueKey('end_date_field_$_endDateUpdateCounter'),
            locked: widget.endDateLocked,
            lockedMessage: widget.endDateLocked ? '' : null,
          ),

          // Campo de hora de fin (opcional)
          if (widget.endTimeController != null)
            TimeField(
              label: 'Hora de finalización',
              hint: 'HH:MM',
              icon: Icons.access_time_outlined,
              controller: widget.endTimeController!,
              dateController: widget.endDateController,
              isEndTime: true,
              locked: widget.endTimeLocked,
              lockedMessage: widget.endTimeLocked
                  ? 'Hora definida por grupo de trabajo'
                  : null,
            ),
        ],

        DropdownField(
          label: 'Zona',
          hint: 'Seleccionar zona',
          icon: Icons.grid_view_outlined, // Ícono de cuadrícula para zonas
          controller: widget.zoneController,
          options: zones, // Lista de zonas generada
          onSelected: (zone) => debugPrint('Zona seleccionada: $zone'),
        ),
        DropdownField(
          label: 'Cliente',
          hint: 'Seleccionar cliente',
          icon: Icons.person_outline,
          controller: widget.clientController,
          options: widget.clients.map((client) => client.name).toList(),
        ),

        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: ProgrammingSelector(
            startDate: widget.startDateController.text,
            initialValue: _selectedProgramming,
            onProgrammingSelected: widget.onProgrammingSelected,
          ),
        ),
      ],
    );
  }
}
