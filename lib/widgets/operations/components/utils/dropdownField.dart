import 'package:flutter/material.dart';
import 'package:plannerop/utils/toast.dart';

class DropdownField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final List<String> options;
  final Function(String)? onSelected;
  final bool enabled;
  final bool allowClear;

  const DropdownField({
    Key? key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.options,
    this.onSelected,
    this.enabled = true,
    this.allowClear = true,
  }) : super(key: key);

  @override
  State<DropdownField> createState() => _DropdownFieldState();
}

class _DropdownFieldState extends State<DropdownField> {
  // Estado local para manejar el texto visible
  late String _displayText;

  @override
  void initState() {
    super.initState();
    _displayText = widget.controller.text;
    // Añadir listener al controller para mantener el texto sincronizado
    widget.controller.addListener(_updateDisplayText);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateDisplayText);
    super.dispose();
  }

  void _updateDisplayText() {
    if (mounted) {
      setState(() {
        _displayText = widget.controller.text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Asegurarse de que tengamos el valor más actualizado
    _displayText = widget.controller.text;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: widget.enabled
                ? () {
                    _showSearchableDropdownDialog(context);
                  }
                : () {
                    // Si no está habilitado, mostrar un mensaje
                    if (widget.label == 'Tarea') {
                      showErrorToast(
                          context, 'Primero debes seleccionar un área');
                    }
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: widget.enabled
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFFE2E8F0).withOpacity(0.7),
                ),
                borderRadius: BorderRadius.circular(8),
                color: widget.enabled ? Colors.white : const Color(0xFFF7FAFC),
              ),
              child: Row(
                children: [
                  Icon(widget.icon,
                      size: 20,
                      color: widget.enabled
                          ? const Color(0xFF718096)
                          : const Color(0xFF718096).withOpacity(0.7)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _displayText.isEmpty ? widget.hint : _displayText,
                      style: TextStyle(
                        color: _displayText.isEmpty
                            ? (widget.enabled
                                ? const Color(0xFFA0AEC0)
                                : const Color(0xFFA0AEC0).withOpacity(0.7))
                            : (widget.enabled ? Colors.black : Colors.black87),
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down,
                      color: widget.enabled
                          ? const Color(0xFF718096)
                          : const Color(0xFF718096).withOpacity(0.7)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchableDropdownDialog(BuildContext context) {
    // Comprobar si hay opciones disponibles
    if (widget.options.isEmpty) {
      showErrorToast(context, "No hay opciones disponibles");
      return;
    }

    debugPrint('Mostrando dropdown con ${widget.options.length} opciones');

    // Solo usar búsqueda si hay más de 10 opciones
    final bool useSearch = widget.options.length > 10;

    // Controlador para el campo de búsqueda
    final searchController = TextEditingController();
    // Lista de opciones filtradas
    List<String> filteredOptions = List.from(widget.options);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.hint),
                  // Solo mostrar campo de búsqueda si hay más de 10 opciones
                  if (useSearch) ...[
                    const SizedBox(height: 8),
                    // Campo de búsqueda
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        // Filtrar opciones cuando cambia el texto
                        setState(() {
                          if (value.isEmpty) {
                            filteredOptions = List.from(widget.options);
                          } else {
                            filteredOptions = widget.options
                                .where((option) => option
                                    .toLowerCase()
                                    .contains(value.toLowerCase()))
                                .toList();
                          }
                        });
                      },
                    ),
                  ],
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height:
                    useSearch ? 300 : null, // Altura controlada si hay búsqueda
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Añadir opción para borrar selección si allowClear es true y hay texto
                    if (widget.allowClear && widget.controller.text.isNotEmpty)
                      ListTile(
                        title: const Text(
                          'Borrar selección',
                          style: TextStyle(color: Colors.red),
                        ),
                        leading: const Icon(Icons.clear, color: Colors.red),
                        onTap: () {
                          widget.controller.clear();
                          setState(() {
                            _displayText = '';
                          });
                          Navigator.of(context).pop();

                          // Si hay una función de callback, llamarla con string vacío
                          if (widget.onSelected != null) {
                            widget.onSelected!('');
                          }
                        },
                      ),
                    if (widget.allowClear && widget.controller.text.isNotEmpty)
                      const Divider(),

                    // Lista de opciones filtradas
                    Flexible(
                      child: filteredOptions.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('No se encontraron resultados',
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic)),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap:
                                  !useSearch, // Ajustar tamaño solo si no hay búsqueda
                              itemCount: filteredOptions.length,
                              itemBuilder: (context, index) {
                                final option = filteredOptions[index];
                                return ListTile(
                                  title: Text(option),
                                  onTap: () {
                                    // Actualizar el controlador con la opción seleccionada
                                    widget.controller.text = option;
                                    // También actualizar el estado local
                                    setState(() {
                                      _displayText = option;
                                    });

                                    debugPrint('Seleccionada opción: $option');
                                    Navigator.of(context).pop();

                                    // Si hay una función de callback, la llamamos
                                    if (widget.onSelected != null) {
                                      widget.onSelected!(option);
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
              // Limitar el tamaño del diálogo
              contentPadding: const EdgeInsets.only(
                  top: 10, left: 20, right: 20, bottom: 0),
            );
          },
        );
      },
    );
  }
}
