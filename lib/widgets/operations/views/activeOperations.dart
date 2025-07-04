import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/store/areas.dart';
import 'package:plannerop/store/chargersOp.dart';
import 'package:plannerop/store/feedings.dart';
import 'package:plannerop/utils/operations.dart' hide buildDetailRow;
import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/operations/components/OperationCard.dart';
import 'package:plannerop/widgets/operations/components/feedingAware.dart';
import 'package:plannerop/widgets/operations/edit/editOperationForm.dart';
import 'package:provider/provider.dart';
import 'package:plannerop/store/operations.dart';
import 'package:plannerop/widgets/operations/components/utils/emptyState.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/widgets/operations/components/completeDialogs.dart';
import 'package:plannerop/widgets/operations/components/utils.dart';

class ActiveOperationsView extends StatefulWidget {
  final String searchQuery;

  const ActiveOperationsView({Key? key, required this.searchQuery})
      : super(key: key);

  @override
  _ActiveOperationsViewState createState() => _ActiveOperationsViewState();
}

class _ActiveOperationsViewState extends State<ActiveOperationsView> {
  String? _selectedArea;
  int? _selectedSupervisorId;
  bool _showFilters = false;
  Map<int, bool> alimentacionStatus = {};

  @override
  Widget build(BuildContext context) {
    // Obtener áreas disponibles del provider
    final areasProvider = Provider.of<AreasProvider>(context);
    final areas = areasProvider.areas.map((area) => area.name).toSet().toList();

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

        var activeAssignments = assignmentsProvider.inProgressOperations;

        // Ordenar y traer las más recientes
        activeAssignments.sort((a, b) => b.date.compareTo(a.date));

        // Aplicar filtros
        var filteredAssignments = activeAssignments.where((assignment) {
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
            await assignmentsProvider.refreshActiveOperations(context);
          },
          child: Column(
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
              Expanded(
                child: filteredAssignments.isEmpty
                    ? _buildEmptyState(activeAssignments)
                    : _buildAssignmentGrid(filteredAssignments),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(List<Operation> activeAssignments) {
    return EmptyState(
      message: activeAssignments.isEmpty
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
    );
  }

  Widget _buildAssignmentGrid(List<Operation> assignments) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Consumer<FeedingProvider>(
          builder: (context, feedingProvider, _) {
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: assignments.length,
              itemBuilder: (context, index) {
                final assignment = assignments[index];

                return OperationCard(
                  assignment: assignment,
                  onTap: _showAssignmentDetails,
                  statusColor: const Color(0xFF38A169), // Verde para activas
                  statusText: 'EN CURSO',
                  showFoodInfo: true, // Mostrar información de alimentación
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showAssignmentDetails(
      BuildContext context, Operation assignment) async {
    final assignmentsProvider =
        Provider.of<OperationsProvider>(context, listen: false);

    // ✅ MOSTRAR DIÁLOGO INMEDIATAMENTE SIN ESPERAR DATOS DE ALIMENTACIÓN
    showOperationDetails(
      context: context,
      assignment: assignment,
      statusColor: const Color(0xFF38A169),
      statusText: 'EN CURSO',
      alimentacionStatus: alimentacionStatus,
      foods: [], // Se calculará en el FutureBuilder
      setState: () => setState(() {}),

      // ✅ USAR FUTUREBUILDER PARA CARGAR ALIMENTACIÓN SIN BLOQUEAR LA UI
      workersBuilder: (assignment, context) {
        return FeedingAwareWidget(
          operationId: assignment.id ?? 0,
          assignment: assignment,
          alimentacionStatus: alimentacionStatus,
          onAlimentacionChanged: (workerId, entregada) {
            setState(() {
              alimentacionStatus[workerId] = entregada;
            });
          },
        );
      },

      // Action buttons (sin cambios)
      actionsBuilder: (context, assignment) => [
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
              _showEditDialog(context, assignment, assignmentsProvider);
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
        Expanded(
          child:
              Consumer<OperationsProvider>(builder: (context, provider, child) {
            return NeumorphicButton(
              style: NeumorphicStyle(
                depth: 2,
                intensity: 0.7,
                color: const Color(0xFF3182CE),
                boxShape:
                    NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context);
                showCompletionDialog(
                    context: context,
                    assignment: assignment,
                    provider: provider);
              },
              child: const Text(
                'Completar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
        ),
      ],

      // Floating action button (sin cambios)
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
          showCancelDialog(context, assignment, assignmentsProvider);
        },
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, Operation assignment, OperationsProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: EditOperationForm(
              assignment: assignment,
              onSave: (updatedAssignment) {
                provider.updateOperation(
                  id: updatedAssignment.id!,
                  status: updatedAssignment.status,
                  endDate: updatedAssignment.endDate,
                  endTime: updatedAssignment.endTime,
                  context: context,
                );
                showSuccessToast(context, 'Operación actualizada');
                Navigator.pop(context);
              },
              onCancel: () => Navigator.pop(context),
            ),
          ),
        );
      },
    );
  }
}
