import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/store/workers.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/operations/components/utils/Loader.dart';
import 'package:provider/provider.dart';
import 'package:plannerop/widgets/operations/components/utils/dropdownField.dart';

class WorkerIncapacitationDialog extends StatefulWidget {
  final Worker worker;
  final Function(Worker, DateTime, DateTime) onIncapacitate;

  const WorkerIncapacitationDialog({
    Key? key,
    required this.worker,
    required this.onIncapacitate,
  }) : super(key: key);

  @override
  State<WorkerIncapacitationDialog> createState() =>
      _WorkerIncapacitationDialogState();
}

class _WorkerIncapacitationDialogState
    extends State<WorkerIncapacitationDialog> {
  final _formKey = GlobalKey<FormState>();

  DateTime _startDate = DateTime.now();
  DateTime _endDate =
      DateTime.now().add(const Duration(days: 7)); // Por defecto 7 días

  final TextEditingController _tipoIncapacidadController =
      TextEditingController();
  final TextEditingController _causaIncapacidadController =
      TextEditingController();
  final TextEditingController _motivoController = TextEditingController();

  bool _isLoading = false;

  // Lista de opciones
  final List<String> _tiposIncapacidad = [
    'Inicial',
    'Prórroga',
  ];

  final List<String> _causasIncapacidad = [
    'Accidente Laboral',
    'Accidente de Tránsito',
    'Enfermedad General',
  ];

  @override
  void dispose() {
    _tipoIncapacidadController.dispose();
    _causaIncapacidadController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        'Registrar Incapacidad',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[700],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF718096)),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Tipo de incapacidad
                DropdownField(
                  label: 'Tipo de incapacidad',
                  hint: 'Seleccionar tipo',
                  icon: Icons.category_outlined,
                  controller: _tipoIncapacidadController,
                  options: _tiposIncapacidad,
                  onSelected: (value) {
                    // Callback opcional si necesitas hacer algo cuando se selecciona
                  },
                ),

                // Causa de incapacidad
                DropdownField(
                  label: 'Causa de incapacidad',
                  hint: 'Seleccionar causa',
                  icon: Icons.healing_outlined,
                  controller: _causaIncapacidadController,
                  options: _causasIncapacidad,
                  onSelected: (value) {
                    // Callback opcional si necesitas hacer algo cuando se selecciona
                  },
                ),

                // Fechas de incapacidad
                Row(
                  children: [
                    // Fecha inicial
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Fecha inicial',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF4A5568),
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectDate(context, true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Colors.purple[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(_startDate),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF2D3748),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Fecha final
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Fecha final',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF4A5568),
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectDate(context, false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Colors.purple[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(_endDate),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF2D3748),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Duración calculada
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Colors.purple[700],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Duración: ${_calculateDuration()} días',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.purple[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Color(0xFF718096),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitIncapacitation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[700],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? AppLoader(
                              size: LoaderSize.medium,
                              color: Colors.white,
                            )
                          : const Text(
                              'Registrar Incapacidad',
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
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate ? _startDate : _endDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: isStartDate
          ? DateTime.now().subtract(const Duration(days: 30))
          : _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.purple[700]!,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Si la fecha de inicio es posterior a la de fin, ajustamos la fecha de fin
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  int _calculateDuration() {
    return _endDate.difference(_startDate).inDays + 1;
  }

  // Validar que todos los campos requeridos estén completados
  bool _validateForm() {
    if (_tipoIncapacidadController.text.isEmpty) {
      showErrorToast(context, 'Por favor selecciona el tipo de incapacidad');
      return false;
    }
    if (_causaIncapacidadController.text.isEmpty) {
      showErrorToast(context, 'Por favor selecciona la causa de incapacidad');
      return false;
    }

    return true;
  }

  // Modificar el método _submitIncapacitation
  void _submitIncapacitation() async {
    if (_formKey.currentState!.validate() && _validateForm()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Llamar a la función para incapacitar al trabajador con los nuevos parámetros
        final success =
            await Provider.of<WorkersProvider>(context, listen: false)
                .incapacitateWorker(
          widget.worker,
          _startDate,
          _endDate,
          context,
          tipo: _tipoIncapacidadController.text,
          causa: _causaIncapacidadController.text,
        );

        if (success) {
          // Mostrar mensaje de éxito y cerrar el diálogo
          showSuccessToast(context, 'Incapacidad registrada con éxito');

          // Llamar al callback con los datos
          widget.onIncapacitate(widget.worker, _startDate, _endDate);

          Navigator.of(context).pop();
        } else {
          throw Exception('Error al registrar la incapacidad en la API');
        }
      } catch (e) {
        // Mostrar mensaje de error
        showErrorToast(context, 'Error al registrar la incapacidad');

        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
