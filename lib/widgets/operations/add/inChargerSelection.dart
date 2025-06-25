import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/core/model/user.dart';
import 'package:plannerop/store/chargersOp.dart';
import 'package:plannerop/widgets/operations/components/utils/Button.dart';
import 'package:provider/provider.dart';

class MultiChargerSelectionField extends StatefulWidget {
  final TextEditingController controller;

  const MultiChargerSelectionField({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<MultiChargerSelectionField> createState() =>
      _MultiChargerSelectionFieldState();
}

class _MultiChargerSelectionFieldState
    extends State<MultiChargerSelectionField> {
  List<User> _selectedChargers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Deserializar los IDs almacenados en el controlador
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSelectedChargers();
    });
  }

  void _initializeSelectedChargers() {
    if (widget.controller.text.isNotEmpty) {
      try {
        final chargersProvider =
            Provider.of<ChargersOpProvider>(context, listen: false);
        final allChargers = chargersProvider.chargers;

        // El controlador tiene una lista de IDs separados por coma
        final chargerIds = widget.controller.text.split(',');

        // Convertir los IDs a enteros y buscar los encargados correspondientes
        final selectedChargers = <User>[];
        for (final idStr in chargerIds) {
          try {
            final id = int.parse(idStr.trim());
            final charger = allChargers.firstWhere(
              (c) => c.id == id,
              orElse: () => throw Exception('Charger not found'),
            );
            selectedChargers.add(charger);
          } catch (e) {
            // Ignorar errores de conversión o chargers no encontrados
          }
        }

        setState(() {
          _selectedChargers = selectedChargers;
        });
      } catch (e) {
        // Ignorar errores de inicialización
      }
    }
  }

  // Actualiza el controller con los IDs de los encargados seleccionados
  void _updateControllerValue() {
    final chargerIds = _selectedChargers.map((c) => c.id.toString()).join(',');
    widget.controller.text = chargerIds;
  }

  Color _getColorForCharger(User charger) {
    return const Color(0xFF3182CE); // Color estándar para encargados
  }

  @override
  Widget build(BuildContext context) {
    final chargersProvider = Provider.of<ChargersOpProvider>(context);
    final availableChargers = chargersProvider.chargers
        .where((c) => !_selectedChargers.any((sc) => sc.id == c.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título y botón para agregar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Encargados Asignados',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF4A5568),
              ),
            ),
            // NeumorphicButton(
            //   style: NeumorphicStyle(
            //     depth: 2,
            //     intensity: 0.6,
            //     boxShape:
            //         NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
            //     color: const Color(0xFF3182CE),
            //   ),
            //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            //   onPressed: () =>
            //       _showChargerSelectionDialog(context, availableChargers),
            //   child: Row(
            //     mainAxisSize: MainAxisSize.min,
            //     children: const [
            //       Icon(
            //         Icons.person_add,
            //         size: 16,
            //         color: Colors.white,
            //       ),
            //       SizedBox(width: 6),
            //       Text(
            //         "Añadir",
            //         style: TextStyle(
            //           color: Colors.white,
            //           fontWeight: FontWeight.w500,
            //           fontSize: 12,
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            AppButton(
              text: "Añadir",
              icon: Icons.person_add,
              onPressed: () =>
                  _showChargerSelectionDialog(context, availableChargers),
              size: AppButtonSize.small,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Lista de encargados seleccionados
        _selectedChargers.isEmpty
            ? Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFF7FAFC),
                ),
                child: const Center(
                  child: Text(
                    'No hay encargados seleccionados',
                    style: TextStyle(
                      color: Color(0xFF718096),
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            : Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _selectedChargers.length,
                  itemBuilder: (context, index) {
                    final charger = _selectedChargers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 4),
                      elevation: 0,
                      color: const Color(0xFFF7FAFC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        dense: true,
                        leading: CircleAvatar(
                          backgroundColor: _getColorForCharger(charger),
                          radius: 16,
                          child: Text(
                            charger.name.isNotEmpty
                                ? charger.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        title: Text(
                          charger.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        subtitle: Text(
                          charger.cargo,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF718096),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 20),
                          onPressed: () {
                            setState(() {
                              _selectedChargers.removeAt(index);
                              _updateControllerValue();
                            });
                          },
                          tooltip: 'Eliminar',
                        ),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  void _showChargerSelectionDialog(
      BuildContext context, List<User> availableChargers) {
    final _searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Filtrar encargados disponibles con la búsqueda
          final filteredChargers = _searchQuery.isEmpty
              ? availableChargers
              : availableChargers
                  .where((charger) => charger.name
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()))
                  .toList();

          return AlertDialog(
            title: const Text('Seleccionar Encargados'),
            content: Container(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  // Campo de búsqueda
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar encargado...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Lista de encargados disponibles
                  Expanded(
                    child: filteredChargers.isEmpty
                        ? Center(
                            child: Text(
                              _searchQuery.isEmpty
                                  ? 'No hay encargados disponibles'
                                  : 'No se encontraron coincidencias',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredChargers.length,
                            itemBuilder: (context, index) {
                              final charger = filteredChargers[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF3182CE),
                                  child: Text(
                                    charger.name.isNotEmpty
                                        ? charger.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(charger.name),
                                subtitle: Text(charger.cargo),
                                onTap: () {
                                  this.setState(() {
                                    _selectedChargers.add(charger);
                                    _updateControllerValue();
                                  });
                                  Navigator.pop(context);
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
                child: const Text('Cancelar'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
