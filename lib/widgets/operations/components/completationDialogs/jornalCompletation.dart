// lib/widgets/operations/components/completationDialogs/jornalCompletation.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/providers/operations.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/operations/components/utils/Loader.dart';

/// Diálogo especializado para completar jornadas laborales
void showJornalCompletionDialog(
  BuildContext context,
  Operation assignment,
  List<Worker> workers,
  String groupId,
  OperationsProvider provider,
  Function setState,
  WorkerGroup group,
) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return JornalCompletionDialog(
        assignment: assignment,
        workers: workers,
        groupId: groupId,
        provider: provider,
        onStateChanged: setState,
        group: group,
      );
    },
  );
}

class JornalCompletionDialog extends StatefulWidget {
  final Operation assignment;
  final List<Worker> workers;
  final String groupId;
  final OperationsProvider provider;
  final Function onStateChanged;
  final WorkerGroup group;

  const JornalCompletionDialog({
    Key? key,
    required this.assignment,
    required this.workers,
    required this.groupId,
    required this.provider,
    required this.onStateChanged,
    required this.group,
  }) : super(key: key);

  @override
  State<JornalCompletionDialog> createState() => _JornalCompletionDialogState();
}

class _JornalCompletionDialogState extends State<JornalCompletionDialog> {
  bool _isProcessing = false;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // ✅ Controladores para horas extras
  final TextEditingController _extraHoursController = TextEditingController();
  final TextEditingController _observationsController = TextEditingController();

  // Calculados
  late String _formattedDate;
  late String _formattedTime;
  double _extraHours = 0.0;

  @override
  void initState() {
    super.initState();
    _formattedDate = DateFormat('dd/MM/yyyy').format(_selectedDate);
    _formattedTime =
        "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.access_time, color: Color(0xFF3182CE)),
          SizedBox(width: 8),
          Text('Completar Jornada Laboral'),
        ],
      ),
      content: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWorkerInfo(),
              SizedBox(height: 20),
              _buildGroupInfo(),
              SizedBox(height: 20),
              _buildDateTimeSection(),
              SizedBox(height: 20),
              _buildExtraHoursSection(),
              SizedBox(height: 16),
              _buildObservationsSection(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor:
                _isProcessing ? Color(0xFFCBD5E0) : Color(0xFF718096),
          ),
          child: Text('Cancelar'),
        ),
        NeumorphicButton(
          style: NeumorphicStyle(
            depth: _isProcessing ? 0 : 2,
            intensity: 0.7,
            color: _isProcessing ? Color(0xFF9AE6B4) : Color(0xFF3182CE),
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
          ),
          onPressed: _isProcessing ? null : _handleCompletion,
          child: SizedBox(
            width: 120,
            height: 36,
            child: Center(
              child: _isProcessing
                  ? AppLoader(
                      color: Colors.white,
                      size: LoaderSize.medium,
                      message: 'Procesando...')
                  : Text(
                      'Completar Jornada',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  /// Información de los trabajadores
  Widget _buildWorkerInfo() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, size: 16, color: Color(0xFF4A5568)),
              SizedBox(width: 6),
              Text(
                'Trabajadores (${widget.workers.length})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A5568),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ...widget.workers
              .map((worker) => Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${worker.name}',
                      style: TextStyle(fontSize: 13, color: Color(0xFF2D3748)),
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  /// Información del grupo/servicio
  Widget _buildGroupInfo() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFF0F8FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFBEE3F8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.work, size: 16, color: Color(0xFF3182CE)),
              SizedBox(width: 6),
              Text(
                'Servicio',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3182CE),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            widget.group.serviceName ?? 'Sin servicio asignado',
            style: TextStyle(fontSize: 13, color: Color(0xFF2D3748)),
          ),
          if (widget.group.startTime != null) ...[
            SizedBox(height: 8),
            Text(
              'Horario programado: ${widget.group.startTime} - ${widget.group.endTime ?? 'Sin definir'}',
              style: TextStyle(fontSize: 12, color: Color(0xFF718096)),
            ),
          ],
        ],
      ),
    );
  }

  /// Sección de fecha y hora de finalización
  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Finalización de Jornada',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildDateField()),
            SizedBox(width: 12),
            Expanded(child: _buildTimeField()),
          ],
        ),
      ],
    );
  }

  /// Campo de fecha
  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fecha',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A5568)),
        ),
        SizedBox(height: 4),
        GestureDetector(
          onTap: _isProcessing ? null : _selectDate,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Color(0xFF718096)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _formattedDate,
                    style: TextStyle(fontSize: 13, color: Color(0xFF2D3748)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Campo de hora
  Widget _buildTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hora',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A5568)),
        ),
        SizedBox(height: 4),
        GestureDetector(
          onTap: _isProcessing ? null : _selectTime,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Color(0xFF718096)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _formattedTime,
                    style: TextStyle(fontSize: 13, color: Color(0xFF2D3748)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Sección de horas extras
  Widget _buildExtraHoursSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.schedule, size: 16, color: Color(0xFFD69E2E)),
            SizedBox(width: 6),
            Text(
              'Horas Extras',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _extraHoursController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            hintText: '0.0',
            suffixText: 'horas',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onChanged: (value) {
            setState(() {
              _extraHours = double.tryParse(value) ?? 0.0;
            });
          },
        ),
        if (_extraHours > 0) ...[
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Color(0xFFF6E05E)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Color(0xFFD69E2E)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Se registrarán ${_extraHours.toStringAsFixed(1)} horas extras',
                    style: TextStyle(fontSize: 12, color: Color(0xFFB7791F)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Sección de observaciones
  Widget _buildObservationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Observaciones (opcional)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A5568),
          ),
        ),
        SizedBox(height: 6),
        TextFormField(
          controller: _observationsController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Comentarios adicionales sobre la jornada...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            contentPadding: EdgeInsets.all(10),
          ),
        ),
      ],
    );
  }

  /// Seleccionar fecha
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(Duration(days: 30)),
      lastDate: DateTime.now().add(Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _formattedDate = DateFormat('dd/MM/yyyy').format(_selectedDate);
      });
    }
  }

  /// Seleccionar hora
  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _formattedTime =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  /// Manejar la finalización de la jornada
  Future<void> _handleCompletion() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Crear copia de la operación con los datos de finalización
      Operation completedAssignment = Operation(
        id: widget.assignment.id,
        area: widget.assignment.area,
        date: widget.assignment.date,
        time: widget.assignment.time,
        supervisor: widget.assignment.supervisor,
        status: widget.assignment.status,
        endDate: _selectedDate,
        endTime: _formattedTime,
        zone: widget.assignment.zone,
        motorship: widget.assignment.motorship,
        userId: widget.assignment.userId,
        areaId: widget.assignment.areaId,
        clientId: widget.assignment.clientId,
        inChagers: widget.assignment.inChagers,
        groups: widget.assignment.groups,
        id_clientProgramming: widget.assignment.id_clientProgramming,
      );

      // ✅ Datos específicos de jornada laboral
      final jornalData = {
        'extraHours': _extraHours,
        'observations': _observationsController.text.trim(),
        'unitOfMeasure': widget.group.idUnitOfMeasure,
      };

      // Llamar a API para completar jornada laboral
      // final success = await widget.provider.completeJornalGroup(
      //   completedAssignment,
      //   widget.workers,
      //   widget.groupId,
      //   _selectedDate,
      //   _formattedTime,
      //   jornalData,
      //   context,
      // );

      // Navigator.of(context).pop();
      // Navigator.of(context).pop();

      // if (success) {
      //   widget.onStateChanged();
      //   showSuccessToast(
      //     context,
      //     'Jornada completada: ${_extraHours > 0 ? "${_extraHours}h extras registradas" : "Sin horas extras"}',
      //   );
      // }
    } catch (e) {
      debugPrint('Error al completar jornada: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        showErrorToast(context, 'Error al completar la jornada: $e');
      }
    }
  }

  @override
  void dispose() {
    _extraHoursController.dispose();
    _observationsController.dispose();
    super.dispose();
  }
}
