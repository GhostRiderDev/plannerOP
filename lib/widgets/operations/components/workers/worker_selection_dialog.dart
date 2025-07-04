import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/store/workers.dart';
import 'package:plannerop/utils/constants.dart';
import 'package:provider/provider.dart';

class WorkerSelectionDialog extends StatefulWidget {
  final List<Worker> selectedWorkers;
  final List<Worker> allSelectedWorkers; // Lista de trabajadores seleccionados
  final List<Worker>?
      availableWorkers; // Opcional, permite pasar trabajadores filtrados
  final Map<int, double>? workerHours; // Horas trabajadas por cada trabajador
  final String title; // Título del diálogo

  const WorkerSelectionDialog(
      {Key? key,
      required this.selectedWorkers,
      this.availableWorkers,
      this.workerHours,
      required this.allSelectedWorkers,
      required this.title})
      : super(key: key);

  @override
  State<WorkerSelectionDialog> createState() => _WorkerSelectionDialogState();
}

class _WorkerSelectionDialogState extends State<WorkerSelectionDialog> {
  // Lista de trabajadores seleccionados (copia local)
  late List<Worker> _selectedWorkers;

  // Controlador para la búsqueda
  final _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isAlreadySelectedInAnyGroup(Worker worker) {
    return widget.allSelectedWorkers
        .any((selected) => selected.id == worker.id);
  }

  // Lista de áreas seleccionadas para filtrar
  List<String> _selectedAreas = [];

  @override
  void initState() {
    super.initState();
    // Inicializar con la lista recibida
    _selectedWorkers = List.from(widget.selectedWorkers);

    // Escuchar cambios en el texto de búsqueda
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  // Obtener trabajadores disponibles (sin filtro de área ni búsqueda)
  List<Worker> _getAvailableWorkers(BuildContext context) {
    // Si se proporcionó una lista de trabajadores filtrados, usarla directamente
    if (widget.availableWorkers != null) {
      debugPrint('Usando lista de trabajadores filtrados proporcionada');
      return widget
          .availableWorkers!; // CAMBIO AQUÍ: Usar la lista proporcionada
    }

    // De lo contrario, obtener de WorkersProvider
    final workersProvider = Provider.of<WorkersProvider>(context);
    // return workersProvider.getWorkersAvailable();
    return workersProvider.workersWithoutRetiredAndDisabled;
  }

// También corrige este método para que considere correctamente los trabajadores seleccionados:
  bool _isSelected(Worker worker) {
    return _selectedWorkers.any((selected) => selected.id == worker.id);
  }

  // Método para alternar la selección de un trabajador
  void _toggleSelection(Worker worker) {
    setState(() {
      if (_isSelected(worker)) {
        _selectedWorkers.removeWhere((selected) => selected.id == worker.id);
      } else {
        _selectedWorkers.add(worker);
      }
    });
  }

  // Obtener todas las áreas disponibles
  List<String> _getAreas(BuildContext context) {
    List<String> areas = [];

    // Obtener todas las áreas de los trabajadores disponibles
    final availableWorkers = _getAvailableWorkers(context);

    for (var worker in availableWorkers) {
      if (!areas.contains(worker.area)) {
        areas.add(worker.area);
      }
    }

    areas.sort();
    return areas;
  }

  // Filtrar trabajadores basados en búsqueda y áreas seleccionadas
  List<Worker> _getFilteredWorkers(BuildContext context) {
    final List<Worker> availableWorkers = _getAvailableWorkers(context);

    // Filtrar por texto de búsqueda y áreas seleccionadas
    return availableWorkers.where((worker) {
      // Filtrar por texto
      final matchesSearch = worker.name.toLowerCase().contains(_searchQuery) ||
          worker.document.toLowerCase().contains(_searchQuery);

      // Filtrar por áreas seleccionadas (si hay alguna)
      final matchesArea =
          _selectedAreas.isEmpty || _selectedAreas.contains(worker.area);

      // El trabajador debe cumplir ambos filtros
      return matchesSearch && matchesArea;
    }).toList();
  }

  // Obtener horas trabajadas para un trabajador
  double _getWorkerHours(int workerId) {
    if (widget.workerHours == null) {
      return 0.0;
    }
    return widget.workerHours![workerId] ?? 0.0;
  }

  // Verificar si un trabajador está disponible (menos de 8 horas)
  bool _isWorkerAvailable(int workerId) {
    final hours = _getWorkerHours(workerId);
    return hours < 12.0;
  }

  @override
  Widget build(BuildContext context) {
    final filteredWorkers = _getFilteredWorkers(context);
    final areas = _getAreas(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 600,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Título con contador de seleccionados
            Row(
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3182CE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selectedWorkers.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Búsqueda
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar trabajador...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              ),
            ),

            const SizedBox(height: 16),

            // Filtro por áreas
            Container(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Chip para "Todas"
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Todas las áreas'),
                      selected: _selectedAreas.isEmpty,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedAreas = [];
                          });
                        }
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: const Color(0xFF3182CE).withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: _selectedAreas.isEmpty
                            ? const Color(0xFF3182CE)
                            : Colors.black,
                        fontWeight: _selectedAreas.isEmpty
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  // Chips para cada área
                  ...areas.map((area) {
                    final isSelected = _selectedAreas.contains(area);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(area),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedAreas = [area];
                            } else if (_selectedAreas.contains(area)) {
                              _selectedAreas.remove(area);
                            }
                          });
                        },
                        backgroundColor: Colors.grey[200],
                        selectedColor: const Color(0xFF3182CE).withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFF3182CE)
                              : Colors.black,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 16),
            // Lista de trabajadores filtrados
            Expanded(
              child: filteredWorkers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No se encontraron trabajadores',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredWorkers.length,
                      itemBuilder: (context, index) {
                        final worker = filteredWorkers[index];
                        final isCurrentlySelected = _isSelected(worker);
                        final isAlreadyInOtherGroups =
                            _isAlreadySelectedInAnyGroup(worker);
                        final isAvailable = _isWorkerAvailable(worker.id);
                        final workerHours = _getWorkerHours(worker.id);

                        // Determinar el color de fondo y borde
                        Color backgroundColor;
                        Color borderColor;

                        if (isCurrentlySelected) {
                          // Seleccionado actualmente - azul
                          backgroundColor =
                              const Color(0xFF3182CE).withOpacity(0.1);
                          borderColor = const Color(0xFF3182CE);
                        } else if (isAlreadyInOtherGroups) {
                          // Ya está en otros grupos - ámbar
                          backgroundColor = Colors.amber[50]!;
                          borderColor = Colors.amber[300]!;
                        } else if (!isAvailable) {
                          // No disponible - rojo claro
                          backgroundColor = Colors.red[50]!;
                          borderColor = Colors.red[200]!;
                        } else {
                          // Normal - blanco
                          backgroundColor = Colors.white;
                          borderColor = Colors.grey[300]!;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: borderColor,
                              width: isCurrentlySelected ? 2 : 1,
                            ),
                          ),
                          color: backgroundColor,
                          child: ListTile(
                            onTap: isAvailable || isAlreadyInOtherGroups
                                ? () => _toggleSelection(worker)
                                : null, // Permitir selección si está disponible O ya está en grupos
                            selected: isCurrentlySelected,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isAlreadyInOtherGroups
                                      ? Colors.amber[600]
                                      : getColorForArea(worker.area),
                                  child: Text(
                                    worker.name.isNotEmpty
                                        ? worker.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // Indicador para trabajadores ya en grupos
                                if (isAlreadyInOtherGroups)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.amber[600],
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 1.5),
                                      ),
                                      child: const Icon(
                                        Icons.group,
                                        color: Colors.white,
                                        size: 10,
                                      ),
                                    ),
                                  ),
                                // Indicador para trabajadores no disponibles
                                if (!isAvailable && !isAlreadyInOtherGroups)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 1.5),
                                      ),
                                      child: const Icon(
                                        Icons.warning,
                                        color: Colors.white,
                                        size: 10,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(
                              worker.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: !isAvailable && !isAlreadyInOtherGroups
                                    ? Colors.grey[500]
                                    : isAlreadyInOtherGroups
                                        ? Colors.amber[800]
                                        : null,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: isAlreadyInOtherGroups
                                            ? Colors.amber[600]
                                            : getColorForArea(worker.area),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      worker.area,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: !isAvailable &&
                                                !isAlreadyInOtherGroups
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                // Mostrar estado del trabajador
                                Row(
                                  children: [
                                    // Horas trabajadas
                                    Text(
                                      '${workerHours.toStringAsFixed(1)} horas trabajadas',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: isAvailable
                                            ? Colors.green[700]
                                            : Colors.red[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: isCurrentlySelected
                                ? const Icon(Icons.check_circle,
                                    color: Color(0xFF3182CE))
                                : isAlreadyInOtherGroups
                                    ? Tooltip(
                                        message:
                                            'Trabajador ya asignado a otros grupos (puede reasignarse)',
                                        child: Icon(Icons.group_outlined,
                                            color: Colors.amber[700]),
                                      )
                                    : !isAvailable
                                        ? Tooltip(
                                            message:
                                                'Trabajador no disponible (más de 12 horas trabajadas)',
                                            child: Icon(Icons.error_outline,
                                                color: Colors.red[700]),
                                          )
                                        : const SizedBox(width: 10),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 16),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                NeumorphicButton(
                  style: NeumorphicStyle(
                    depth: 2,
                    intensity: 0.6,
                    boxShape:
                        NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                    color: const Color(0xFF3182CE),
                  ),
                  onPressed: () => Navigator.of(context).pop(_selectedWorkers),
                  child: const Text(
                    'Confirmar Selección',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
