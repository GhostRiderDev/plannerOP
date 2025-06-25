import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/core/model/area.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/store/areas.dart';
import 'package:provider/provider.dart';

class WorkerAddDialog extends StatefulWidget {
  final Function(Worker) onWorkerAdded;

  const WorkerAddDialog({
    Key? key,
    required this.onWorkerAdded,
  }) : super(key: key);

  @override
  State<WorkerAddDialog> createState() => _WorkerAddDialogState();

  static void show(BuildContext context, Function(Worker) onWorkerAdded) {
    showDialog(
      context: context,
      builder: (context) => WorkerAddDialog(
        onWorkerAdded: onWorkerAdded,
      ),
    );
  }
}

class _WorkerAddDialogState extends State<WorkerAddDialog> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final documentController = TextEditingController();
  final phoneController = TextEditingController();
  final codeController = TextEditingController();

  // Estados para controlar errores de validación
  String? _nameError;
  String? _documentError;
  String? _phoneError;
  String? _codeError;

  // Lista de áreas disponibles
  List<Area> areas = [];

  // Valor seleccionado por defecto
  int? selectedArea;

  // Flag para inicialización
  bool _areasInitialized = false;

  @override
  void dispose() {
    nameController.dispose();
    documentController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  // Método para validar el nombre
  bool _validateName() {
    if (nameController.text.trim().isEmpty) {
      setState(() {
        _nameError = 'El nombre es obligatorio';
      });
      return false;
    }

    // Validar que el nombre tenga al menos 2 palabras (nombre y apellido)
    final parts = nameController.text.trim().split(' ');
    if (parts.length < 2 || parts.where((part) => part.isNotEmpty).length < 2) {
      setState(() {
        _nameError = 'Ingrese nombre y apellido';
      });
      return false;
    }

    // Validar que solo contenga letras y espacios
    RegExp nameRegExp = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$');
    if (!nameRegExp.hasMatch(nameController.text.trim())) {
      setState(() {
        _nameError = 'Ingrese solo letras';
      });
      return false;
    }

    setState(() {
      _nameError = null;
    });
    return true;
  }

  // Método para validar el documento
  bool _validateDocument() {
    final document = documentController.text.trim();

    if (document.isEmpty) {
      setState(() {
        _documentError = 'El documento es obligatorio';
      });
      return false;
    }

    // Validar que el documento tenga entre 8 y 12 caracteres
    if (document.length < 8 || document.length > 12) {
      setState(() {
        _documentError = 'El documento debe tener entre 8 y 12 caracteres';
      });
      return false;
    }

    // Validar que solo contenga letras y números
    RegExp documentRegExp = RegExp(r'^[a-zA-Z0-9]+$');
    if (!documentRegExp.hasMatch(document)) {
      setState(() {
        _documentError =
            'Solo letras y números, sin espacios ni caracteres especiales';
      });
      return false;
    }

    setState(() {
      _documentError = null;
    });
    return true;
  }

  // Metado para validar el codigo
  bool _validateCode() {
    final code = codeController.text.trim();

    if (code.isEmpty) {
      setState(() {
        _codeError = 'El código es obligatorio';
      });
      return false;
    }

    // Validar que el código tenga entre 4 y 6 caracteres
    if (code.length < 4 || code.length > 6) {
      setState(() {
        _codeError = 'El código debe tener entre 4 y 6 caracteres';
      });
      return false;
    }

    // Validar que solo contenga letras y números
    RegExp codeRegExp = RegExp(r'^[a-zA-Z0-9]+$');
    if (!codeRegExp.hasMatch(code)) {
      setState(() {
        _codeError =
            'Solo letras y números, sin espacios ni caracteres especiales';
      });
      return false;
    }

    setState(() {
      _codeError = null;
    });
    return true;
  }

  // Método para validar el teléfono
  bool _validatePhone() {
    final phone = phoneController.text.trim();

    if (phone.isEmpty) {
      setState(() {
        _phoneError = 'El teléfono es obligatorio';
      });
      return false;
    }

    // Validar que tenga entre 8 y 10 dígitos
    if (phone.length < 8 || phone.length > 10) {
      setState(() {
        _phoneError = 'El teléfono debe tener entre 8 y 10 dígitos';
      });
      return false;
    }

    // Validar que solo contenga números
    RegExp phoneRegExp = RegExp(r'^[0-9]+$');
    if (!phoneRegExp.hasMatch(phone)) {
      setState(() {
        _phoneError = 'Solo se permiten números';
      });
      return false;
    }

    setState(() {
      _phoneError = null;
    });
    return true;
  }

  // Método para validar todos los campos
  bool _validateForm() {
    bool isNameValid = _validateName();
    bool isDocumentValid = _validateDocument();
    bool isPhoneValid = _validatePhone();

    return isNameValid && isDocumentValid && isPhoneValid;
  }

  @override
  Widget build(BuildContext context) {
    areas = Provider.of<AreasProvider>(context).areas;

    // Inicializar selectedArea solo la primera vez
    if (!_areasInitialized && areas.isNotEmpty) {
      selectedArea = areas.first.id;
      _areasInitialized = true;
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cabecera
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4299E1).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_add,
                    color: Color(0xFF4299E1),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Agregar Trabajador',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 20),

                // Campo de nombre
                // Para el campo de nombre, modifica así:
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: _nameError != null
                        ? Border.all(color: Colors.red, width: 1.0)
                        : null,
                  ),
                  child: TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      labelStyle: TextStyle(
                        color: _nameError != null ? Colors.red : null,
                      ),
                      prefixIcon: Icon(
                        Icons.person,
                        color: _nameError != null
                            ? Colors.red
                            : const Color(0xFF4299E1),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      // Quitar errorText para evitar duplicación
                      // errorText: _nameError,
                    ),
                    onChanged: (_) {
                      if (_nameError != null) _validateName();
                    },
                  ),
                ),
                if (_nameError != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12, top: 4),
                      child: Text(
                        _nameError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // Para el campo de documento
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: _documentError != null
                        ? Border.all(color: Colors.red, width: 1.0)
                        : null,
                  ),
                  child: TextField(
                    controller: documentController,
                    decoration: InputDecoration(
                      labelText: 'Documento',
                      labelStyle: TextStyle(
                        color: _documentError != null ? Colors.red : null,
                      ),
                      prefixIcon: Icon(
                        Icons.badge,
                        color: _documentError != null
                            ? Colors.red
                            : const Color(0xFF4299E1),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      hintText: 'DNI, Pasaporte, etc.',
                      // Quitar errorText para evitar duplicación
                      // errorText: _documentError,
                    ),
                    onChanged: (_) {
                      if (_documentError != null) _validateDocument();
                    },
                  ),
                ),
                if (_documentError != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12, top: 4),
                      child: Text(
                        _documentError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),

                // Para el campo de codigo
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: _codeError != null
                        ? Border.all(color: Colors.red, width: 1.0)
                        : null,
                  ),
                  child: TextField(
                    controller: codeController,
                    decoration: InputDecoration(
                      labelText: 'Codigo',
                      labelStyle: TextStyle(
                        color: _codeError != null ? Colors.red : null,
                      ),
                      prefixIcon: Icon(
                        Icons.qr_code,
                        color: _codeError != null
                            ? Colors.red
                            : const Color(0xFF4299E1),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      hintText: 'Codigo de trabajador',
                      // Quitar errorText para evitar duplicación
                      // errorText: _documentError,
                    ),
                    onChanged: (_) {
                      if (_codeError != null) _validateCode();
                    },
                  ),
                ),
                if (_codeError != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12, top: 4),
                      child: Text(
                        _codeError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),

                // Campo de área con dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.work, color: Color(0xFF4299E1)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: selectedArea,
                            hint: const Text('Seleccionar área'),
                            items: areas.map((Area area) {
                              return DropdownMenuItem<int>(
                                value: area.id,
                                child: Text(area.name),
                              );
                            }).toList(),
                            onChanged: (int? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedArea = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Para el campo de teléfono
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: _phoneError != null
                        ? Border.all(color: Colors.red, width: 1.0)
                        : null,
                  ),
                  child: TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Teléfono de contacto',
                      labelStyle: TextStyle(
                        color: _phoneError != null ? Colors.red : null,
                      ),
                      prefixIcon: Icon(
                        Icons.phone,
                        color: _phoneError != null
                            ? Colors.red
                            : const Color(0xFF4299E1),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      // Quitar errorText para evitar duplicación
                      // errorText: _phoneError,
                    ),
                    onChanged: (_) {
                      if (_phoneError != null) _validatePhone();
                    },
                  ),
                ),
                if (_phoneError != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12, top: 4),
                      child: Text(
                        _phoneError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_validateForm() && selectedArea != null) {
                            debugPrint('Selected area: $selectedArea');
                            final newWorker = Worker(
                                id: 0,
                                name: nameController.text.trim(),
                                area: areas
                                    .firstWhere(
                                        (area) => area.id == selectedArea,
                                        orElse: () => Area(id: 0, name: ''))
                                    .name,
                                idArea: selectedArea ?? 0,
                                phone: phoneController.text.trim(),
                                document: documentController.text.trim(),
                                status: WorkerStatus.available,
                                startDate: DateTime.now(),
                                endDate: null,
                                code: codeController.text.trim(),
                                failures: 0);

                            widget.onWorkerAdded(newWorker);
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4299E1),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Guardar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
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
}
