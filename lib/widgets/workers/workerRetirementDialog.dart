import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/store/workers.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/operations/components/utils/Loader.dart';
import 'package:provider/provider.dart';

class WorkerRetirementDialog extends StatefulWidget {
  final Worker worker;
  final Color specialtyColor;
  final Function(Worker) onRetire;

  const WorkerRetirementDialog({
    Key? key,
    required this.worker,
    required this.specialtyColor,
    required this.onRetire,
  }) : super(key: key);

  @override
  State<WorkerRetirementDialog> createState() => _WorkerRetirementDialogState();
}

class _WorkerRetirementDialogState extends State<WorkerRetirementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  String? _selectedReason;
  DateTime _retirementDate = DateTime.now();

  // Lista de motivos de retiro
  final List<String> _retirementReasons = [
    'Renuncia voluntaria',
    'Término de contrato',
    'Jubilación',
    'Reestructuración',
    'Bajo desempeño',
    'Otro'
  ];

  @override
  void dispose() {
    _reasonController.dispose();
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
                // Encabezado con alerta
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.exit_to_app,
                              color: Colors.grey[700],
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Retirar Trabajador',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF718096)),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Mensaje de advertencia
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.amber[800],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Esta acción marca al trabajador como retirado y no podrá ser asignado a nuevas tareas.',
                          style: TextStyle(
                            color: Colors.amber[900],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Información del trabajador
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: widget.specialtyColor,
                        radius: 24,
                        child: Text(
                          widget.worker.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.worker.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        widget.specialtyColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    widget.worker.area,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: widget.specialtyColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '· Doc: ${widget.worker.document}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Selector de fecha de retiro
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fecha efectiva de retiro',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF4A5568),
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('dd/MM/yyyy').format(_retirementDate),
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

                const SizedBox(height: 20),

                // Selector de motivo
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Motivo de retiro',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF4A5568),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<String>(
                          value: _selectedReason,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          hint: const Text('Seleccionar motivo'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor selecciona un motivo';
                            }
                            return null;
                          },
                          items: _retirementReasons.map((String reason) {
                            return DropdownMenuItem<String>(
                              value: reason,
                              child: Text(reason),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedReason = newValue;

                              // Si se selecciona "Otro", mostrar campo adicional
                              if (newValue == 'Otro') {
                                _showAdditionalReasonDialog(context);
                              }
                            });
                          },
                        ),
                      ),
                    ),

                    // Mostrar motivo adicional si se seleccionó "Otro"
                    if (_selectedReason == 'Otro' &&
                        _reasonController.text.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Motivo especificado:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF718096),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _reasonController.text,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
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
                      onPressed: _isLoading ? null : _confirmRetirement,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? AppLoader(
                              color: Colors.white,
                              size: LoaderSize.medium,
                            )
                          : const Text(
                              'Confirmar Retiro',
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _retirementDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF718096),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _retirementDate) {
      setState(() {
        _retirementDate = picked;
      });
    }
  }

  void _showAdditionalReasonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Especifique el motivo'),
        content: TextField(
          controller: _reasonController,
          decoration: const InputDecoration(
            hintText: 'Describa el motivo del retiro',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _confirmRetirement() {
    if (_formKey.currentState!.validate()) {
      // Mostrar diálogo de confirmación adicional
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar retiro'),
          content: Text(
            '¿Está seguro que desea retirar a ${widget.worker.name}?\n\n'
            'Esta acción es irreversible y el trabajador no podrá ser asignado a nuevas tareas.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _processRetirement();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
              ),
              child: const Text('Retirar'),
            ),
          ],
        ),
      );
    }
  }

// Modificar el método _processRetirement
  void _processRetirement() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Actualizar el estado del trabajador a retirado
      final success = await Provider.of<WorkersProvider>(context, listen: false)
          .retireWorker(widget.worker, _retirementDate, context);

      if (success) {
        // Cerrar el diálogo con éxito
        showInfoToast(context, 'Trabajador retirado exitosamente');

        Navigator.of(context).pop();
      } else {
        throw Exception('Error al procesar el retiro en la API');
      }
    } catch (e) {
      // Mostrar error en caso de fallo
      showErrorToast(context, 'Error al retirar al trabajador');

      setState(() {
        _isLoading = false;
      });
    }
  }
}
