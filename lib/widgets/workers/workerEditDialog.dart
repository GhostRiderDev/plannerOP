import 'package:flutter/material.dart';
import 'package:plannerop/core/model/area.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/mapper/operation.dart';
import 'package:plannerop/store/areas.dart';
import 'package:plannerop/utils/operations.dart';
import 'package:plannerop/widgets/workers/workerIncapacitationDialog.dart';

// Import necesario para el método min
import 'dart:math' as Math;

import 'package:provider/provider.dart';

class WorkerEditDialog extends StatefulWidget {
  final Worker worker;
  final Color specialtyColor;
  final Function(Worker, Worker) onUpdateWorker;

  const WorkerEditDialog({
    Key? key,
    required this.worker,
    required this.specialtyColor,
    required this.onUpdateWorker,
  }) : super(key: key);

  @override
  State<WorkerEditDialog> createState() => _WorkerEditDialogState();
}

class _WorkerEditDialogState extends State<WorkerEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _documentController;
  late TextEditingController _phoneController;
  late TextEditingController _areaController;
  late TextEditingController _codeController;
  bool _isLoading = false;

  // Variables para el estado del trabajador
  late WorkerStatus _selectedStatus;
  DateTime? _startDate; // Fecha de inicio de incapacidad
  DateTime? _endDate; // Fecha de fin de incapacidad o retiro

  // Lista de áreas disponibles
  List<Area> _areas = [];

  // Lista de estados disponibles
  final List<WorkerStatus> _statuses = [
    WorkerStatus.available,
    WorkerStatus.assigned,
    WorkerStatus.incapacitated,
    WorkerStatus.deactivated,
  ];

  // Mapeo de estados a nombres para mostrar
  final Map<WorkerStatus, String> _statusNames = {
    WorkerStatus.available: 'Disponible',
    WorkerStatus.assigned: 'Asignado',
    WorkerStatus.incapacitated: 'Incapacitado',
    WorkerStatus.deactivated: 'Retirado',
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.worker.name);
    _documentController = TextEditingController(text: widget.worker.document);
    _phoneController = TextEditingController(text: widget.worker.phone);
    _areaController = TextEditingController(text: widget.worker.area);
    _codeController = TextEditingController(text: widget.worker.code);
    _selectedStatus = widget.worker.status;

    // Inicializar fechas si existen
    _startDate = widget.worker.startDate;
    _endDate = widget.worker.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _documentController.dispose();
    _phoneController.dispose();
    _areaController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      // Validaciones existentes...

      setState(() {
        _isLoading = true;
      });

      try {
        // Determinar las fechas de incapacidad y retiro basadas en el estado seleccionado
        DateTime? incapacityStartDate;
        DateTime? incapacityEndDate;
        DateTime? deactivationDate;

        // Asignar las fechas según el estado seleccionado
        if (_selectedStatus == WorkerStatus.incapacitated) {
          incapacityStartDate = _startDate;
          incapacityEndDate = _endDate;
          // Mantener la fecha de retiro como estaba
          deactivationDate = widget.worker.deactivationDate;
        } else if (_selectedStatus == WorkerStatus.deactivated) {
          deactivationDate = _endDate;
          // Mantener fechas de incapacidad como estaban
          incapacityStartDate = widget.worker.incapacityStartDate;
          incapacityEndDate = widget.worker.incapacityEndDate;
        } else {
          // Para otros estados, mantener las fechas anteriores
          incapacityStartDate = widget.worker.incapacityStartDate;
          incapacityEndDate = widget.worker.incapacityEndDate;
          deactivationDate = widget.worker.deactivationDate;
        }

        // Crear un nuevo trabajador con los datos modificados y las fechas correctas
        final updatedWorker = Worker(
          id: widget.worker.id,
          name: _nameController.text,
          area: _areaController.text,
          phone: _phoneController.text,
          document: _documentController.text,
          status: _selectedStatus,
          startDate:
              widget.worker.startDate, // Fecha de inicio del trabajo (mantener)
          endDate: _selectedStatus == WorkerStatus.assigned
              ? _endDate
              : null, // Fecha fin operación
          code: _codeController.text,
          incapacityStartDate: incapacityStartDate, // Usar la fecha calculada
          incapacityEndDate: incapacityEndDate, // Usar la fecha calculada
          deactivationDate: deactivationDate, // Usar la fecha calculada
          idArea:
              _areas.firstWhere((area) => area.name == _areaController.text).id,
        );

        // Llamar a la función para actualizar el trabajador
        widget.onUpdateWorker(widget.worker, updatedWorker);

        // Cerrar el diálogo con éxito
        Navigator.of(context).pop();
      } catch (e) {
        // Código de manejo de error existente...
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _areas = Provider.of<AreasProvider>(context).areas;
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Editar Trabajador',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF718096)),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Campo de código de trabajador
                _buildTextField(
                  label: 'Código',
                  controller: _codeController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa un código';
                    }
                    return null;
                  },
                  maxLength: 10,
                  prefix: const Icon(Icons.code, size: 18),
                ),
                const SizedBox(height: 16),

                // Campo de nombre
                _buildTextField(
                  label: 'Nombre completo',
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa un nombre';
                    }
                    return null;
                  },
                  prefix: const Icon(Icons.person, size: 18),
                ),
                const SizedBox(height: 16),

                // Campo de documento
                _buildTextField(
                  label: 'Documento',
                  controller: _documentController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa un número de documento';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.number,
                  prefix: const Icon(Icons.assignment_ind, size: 18),
                ),
                const SizedBox(height: 16),

                // Campo de teléfono
                _buildTextField(
                  label: 'Teléfono',
                  controller: _phoneController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa un teléfono';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.phone,
                  prefix: const Icon(Icons.phone, size: 18),
                ),
                const SizedBox(height: 16),

                // Selector de área
                _buildAreaDropdown(),
                const SizedBox(height: 16),

                // Selector de estado
                _buildStatusDropdown(),
                const SizedBox(height: 16),

                // Campos de fechas de incapacidad (condicional)
                if (_selectedStatus == WorkerStatus.incapacitated)
                  _buildIncapacitationDateFields(widget.worker),

                // Campo de fecha de retiro (condicional)
                if (_selectedStatus == WorkerStatus.deactivated)
                  _buildRetirementDateField(),

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
                      onPressed: _isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.specialtyColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Guardar Cambios',
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    Widget? prefix,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLength: maxLength,
          decoration: InputDecoration(
            prefixIcon: prefix,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: widget.specialtyColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            counterText: '',
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildAreaDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Área',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            color: Colors.white,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: DropdownButtonFormField<int>(
            // Use area ID as the value to ensure uniqueness
            value: _areas.any((area) => area.name == _areaController.text)
                ? _areas
                    .firstWhere((area) => area.name == _areaController.text,
                        orElse: () => _areas.first)
                    .id
                : null,
            isExpanded: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(Icons.business, size: 18),
            ),
            hint: const Text('Seleccionar área'),
            validator: (value) {
              if (value == null) {
                return 'Por favor selecciona un área';
              }
              return null;
            },
            items: _areas.map((Area area) {
              return DropdownMenuItem<int>(
                value: area.id,
                child: Text(area.name),
              );
            }).toList(),
            onChanged: (int? newValue) {
              if (newValue != null) {
                final selectedArea =
                    _areas.firstWhere((area) => area.id == newValue);
                setState(() {
                  _areaController.text = selectedArea.name;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estado',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            color: Colors.white,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: DropdownButtonFormField<WorkerStatus>(
            value: _selectedStatus,
            isExpanded: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(Icons.person_outline, size: 18),
            ),
            items: _statuses.map((WorkerStatus status) {
              return DropdownMenuItem<WorkerStatus>(
                value: status,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: getStatusColor(status.name),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(_statusNames[status]!),
                  ],
                ),
              );
            }).toList(),
            onChanged: (WorkerStatus? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedStatus = newValue;

                  // Si cambiamos a un estado que no requiere fechas, las limpiamos
                  if (newValue != WorkerStatus.incapacitated &&
                      newValue != WorkerStatus.deactivated) {
                    _startDate = null;
                    _endDate = null;
                  }

                  // Si cambiamos a retirado, establecemos la fecha actual como predeterminada
                  if (newValue == WorkerStatus.deactivated &&
                      _endDate == null) {
                    _endDate = DateTime.now();
                  }

                  // Si cambiamos a incapacitado, establecemos fechas predeterminadas
                  if (newValue == WorkerStatus.incapacitated) {
                    _startDate ??= DateTime.now();
                    _endDate ??= DateTime.now().add(const Duration(days: 7));
                  }
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIncapacitationDateFields(Worker worker) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // Contenedor informativo
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple[100]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.purple[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Para registrar una nueva incapacidad, haga clic en el botón "Registrar Incapacidad".',
                  style: TextStyle(color: Colors.purple[700]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Botón para abrir el diálogo de incapacitación
        ElevatedButton(
          onPressed: () => _showIncapacitationDialog(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple[700],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.medical_services, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Registrar Incapacidad',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showIncapacitationDialog() {
    showDialog(
      context: context,
      builder: (context) => WorkerIncapacitationDialog(
        worker: widget.worker,
        onIncapacitate: onIncapacitate,
      ),
    );
  }

  void onIncapacitate(Worker worker, DateTime startDate, DateTime endDate) {
    setState(() {
      _startDate = startDate;
      _endDate = endDate;
    });
  }

  Widget _buildRetirementDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // Contenedor informativo
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.grey[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'El trabajador será marcado como retirado y no podrá ser asignado.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Fecha de retiro
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fecha de retiro',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF4A5568),
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () => _selectDate(context, false),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _endDate != null
                            ? DateFormat('dd/MM/yyyy').format(_endDate!)
                            : 'Seleccionar fecha',
                        style: TextStyle(
                          color: _endDate != null
                              ? const Color(0xFF2D3748)
                              : const Color(0xFF718096),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    DateTime? initialDate;
    DateTime? firstDate;
    DateTime? lastDate;

    // Establecer fechas según sea primera o última
    if (isStartDate) {
      // Para fecha de inicio de incapacidad mantener validaciones
      initialDate = _startDate ?? DateTime.now();
      firstDate = DateTime.now().subtract(const Duration(days: 30));
      lastDate = _endDate ?? DateTime.now().add(const Duration(days: 365));
    } else if (_selectedStatus == WorkerStatus.incapacitated) {
      // Para fecha fin de incapacidad mantener validaciones
      firstDate = _startDate ?? DateTime.now();
      initialDate = _endDate ?? firstDate;
      lastDate = DateTime.now().add(const Duration(days: 365));
    } else {
      // Para fecha de retiro no aplicar validaciones
      initialDate = _endDate ?? DateTime.now();
      firstDate = DateTime(2000); // Permitir fechas muy anteriores
      lastDate = DateTime.now().add(const Duration(days: 365));
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              // Color según el estado
              primary: _selectedStatus == WorkerStatus.incapacitated
                  ? Colors.purple
                  : Colors.grey[700]!,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;

          // Solo para incapacidad: Si la fecha inicial es mayor que la final, actualizar la final
          if (_selectedStatus == WorkerStatus.incapacitated &&
              _endDate != null &&
              picked.isAfter(_endDate!)) {
            _endDate = picked.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }
}
