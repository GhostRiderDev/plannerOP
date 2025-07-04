import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/store/areas.dart';
import 'package:plannerop/store/chargersOp.dart';
import 'package:plannerop/utils/operations.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/operations/components/OperationCard.dart';
import 'package:plannerop/widgets/operations/components/utils.dart';
import 'package:plannerop/widgets/operations/edit/editOperationForm.dart';
import 'package:provider/provider.dart';
import 'package:plannerop/store/operations.dart';
import 'package:plannerop/widgets/operations/components/utils/emptyState.dart';
import 'package:plannerop/core/model/operation.dart';

class PendingOperationsView extends StatefulWidget {
  final String searchQuery;

  const PendingOperationsView({Key? key, required this.searchQuery})
      : super(key: key);

  @override
  _PendingOperationsViewState createState() => _PendingOperationsViewState();
}

class _PendingOperationsViewState extends State<PendingOperationsView> {
  String? _selectedArea;
  int? _selectedSupervisorId;
  bool _showFilters = false;

  @override
  Widget build(BuildContext context) {
    // Obtener áreas disponibles del provider
    final areasProvider = Provider.of<AreasProvider>(context);
    final areas = areasProvider.areas
        .map((area) => area.name) // sacar las areas unicas
        .toSet()
        .toList();

    // Verificar si el área seleccionada ya no existe en la lista filtrada
    if (_selectedArea != null && !areas.contains(_selectedArea)) {
      // Resetear si el área ya no existe
      _selectedArea = null;
    }

    // Obtener supervisores disponibles del provider
    final chargersProvider = Provider.of<ChargersOpProvider>(context);
    final supervisors = chargersProvider.chargers;

    // Verificar si el supervisor seleccionado aún existe
    if (_selectedSupervisorId != null &&
        !supervisors.any((s) => s.id == _selectedSupervisorId)) {
      _selectedSupervisorId = null;
    }

    return Consumer<OperationsProvider>(
      builder: (context, assignmentsProvider, child) {
        if (assignmentsProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final pendingAssignments = assignmentsProvider.pendingOperations;

        // Aplicar filtros
        var filteredAssignments = pendingAssignments.where((assignment) {
          // Filtrar por texto de búsqueda
          bool matchesSearch = true;

          // Filtrar por área seleccionada
          bool matchesArea = true;
          if (_selectedArea != null && _selectedArea!.isNotEmpty) {
            matchesArea = assignment.area == _selectedArea;
          }

          // Filtrar por supervisor seleccionado
          bool matchesSupervisor = true;
          if (_selectedSupervisorId != null) {
            matchesSupervisor =
                assignment.inChagers.contains(_selectedSupervisorId);
          }

          return matchesSearch && matchesArea && matchesSupervisor;
        }).toList();

        return RefreshIndicator(
          onRefresh: () async {
            // Si tuviéramos una recarga desde API la llamaríamos aquí
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              buildFilterBar(
                areas,
                supervisors,
                _showFilters,
                _selectedArea,
                _selectedSupervisorId,
                context,
                setState,
                onAreaChanged: (String? area) {
                  setState(() {
                    _selectedArea = area;
                  });
                },
                onSupervisorChanged: (int? supervisorId) {
                  setState(() {
                    _selectedSupervisorId = supervisorId;
                  });
                },
                onClearFilters: () {
                  setState(() {
                    _selectedArea = null;
                    _selectedSupervisorId = null;
                  });
                },
                onToggleFilters: () {
                  // AGREGAR ESTE CALLBACK
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
              ),
              filteredAssignments.isEmpty
                  ? EmptyState(
                      message: pendingAssignments.isEmpty
                          ? 'No hay asignaciones activas en este momento.'
                          : 'No hay asignaciones activas que coincidan con los filtros aplicados.',
                      showClearButton: widget.searchQuery.isNotEmpty ||
                          _selectedArea != null ||
                          _selectedSupervisorId != null,
                      onClear: () {
                        setState(() {
                          _selectedArea = null;
                          _selectedSupervisorId = null;
                        });
                      },
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: filteredAssignments.length,
                      itemBuilder: (context, index) {
                        final assignment = filteredAssignments[index];
                        return _buildAssignmentCard(
                            context, assignment, assignmentsProvider);
                      },
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssignmentCard(
      BuildContext context, Operation assignment, OperationsProvider provider) {
    return OperationCard(
      assignment: assignment,
      onTap: _showAssignmentDetails,
      statusColor: const Color(0xFFF6AD55),
      statusText: 'PENDIENTE',
      actionButton: Container(
        height: 24,
        width: 24,
        decoration: BoxDecoration(
          color: const Color(0xFF3182CE),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3182CE).withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showStartDialog(context, assignment, provider),
            customBorder: const CircleBorder(),
            child: const Icon(
              Icons.play_arrow_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _showAssignmentDetails(BuildContext context, Operation assignment) {
    final provider = Provider.of<OperationsProvider>(context, listen: false);

    showOperationDetails(
      context: context,
      assignment: assignment,
      statusColor: const Color(0xFFF6AD55),
      statusText: "Pendiente",
      actionsBuilder: (context, assignment) => [
        // Edit button
        Expanded(
          child: NeumorphicButton(
            style: NeumorphicStyle(
              depth: 2,
              intensity: 0.7,
              color: Colors.white,
              boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              // Show edit dialog
              showEditAssignmentForm(context, assignment);
            },
            child: const Text(
              'Editar',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF3182CE),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Start button
        Expanded(
          child: NeumorphicButton(
            style: NeumorphicStyle(
              depth: 2,
              intensity: 0.7,
              color: const Color(0xFF3182CE),
              boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _showStartDialog(context, assignment, provider);
            },
            child: const Text(
              'Iniciar',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
      floatingActionBuilder: (context, assignment) => NeumorphicButton(
        style: NeumorphicStyle(
          depth: 4,
          intensity: 0.8,
          color: const Color(0xFFF56565),
          boxShape: NeumorphicBoxShape.circle(),
          shadowDarkColor: const Color(0xFFC53030).withOpacity(0.4),
        ),
        padding: const EdgeInsets.all(16),
        onPressed: () {
          Navigator.pop(context);
          showCancelDialog(context, assignment, provider);
        },
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  void _showStartDialog(
      BuildContext context, Operation assignment, OperationsProvider provider) {
    // Variable de estado local para el diálogo
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Evitar cierre al tocar fuera del diálogo
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(// Usar StatefulBuilder para manejar estado local
            builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Iniciar operación'),
            content: const Text(
              '¿Estás seguro de que deseas iniciar esta operación?',
              style: TextStyle(color: Color(0xFF718096)),
            ),
            actions: [
              // Botón Cancelar (deshabilitado durante el procesamiento)
              TextButton(
                onPressed:
                    isProcessing ? null : () => Navigator.pop(dialogContext),
                style: TextButton.styleFrom(
                  foregroundColor: isProcessing
                      ? const Color(0xFFCBD5E0)
                      : const Color(0xFF718096),
                ),
                child: const Text('Cancelar'),
              ),
              // Botón Confirmar con estado de carga
              NeumorphicButton(
                style: NeumorphicStyle(
                  depth: isProcessing ? 0 : 2,
                  intensity: 0.7,
                  color: isProcessing
                      ? const Color(
                          0xFF90CDF4) // Color más claro cuando está procesando
                      : const Color(0xFF3182CE),
                  boxShape:
                      NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                ),
                onPressed: isProcessing
                    ? null
                    : () async {
                        // Actualizar estado del diálogo a "procesando"
                        setDialogState(() {
                          isProcessing = true;
                        });

                        try {
                          // Actualizar el estado de la operación a "INPROGRESS"
                          await provider.updateOperation(
                              id: assignment.id ?? 0,
                              status: "INPROGRESS",
                              context: context);

                          // Cerrar el diálogo
                          Navigator.pop(dialogContext);

                          // Mostrar mensaje de éxito
                          showSuccessToast(context, "Operación iniciada");
                        } catch (e) {
                          // En caso de error, volver a habilitar el botón
                          if (context.mounted) {
                            setDialogState(() {
                              isProcessing = false;
                            });
                            showErrorToast(
                                context, "Error al iniciar la operación");
                          }
                        }
                      },
                child: Container(
                  width: 100, // Ancho fijo para evitar redimensionamiento
                  height: 36,
                  child: Center(
                    child: isProcessing
                        ? Row(
                            // Mostrar indicador de carga
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Iniciando',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'Confirmar',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ),
            ],
          );
        });
      },
    );
  }
}
