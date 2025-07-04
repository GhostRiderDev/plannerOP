import 'package:flutter/material.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/store/feedings.dart';
import 'package:plannerop/utils/feedingUtils.dart';
import 'package:plannerop/utils/worker_utils.dart';
import 'package:plannerop/widgets/operations/components/utils.dart';

//  Lista de trabajadores del grupo
class WorkersList extends StatelessWidget {
  final WorkerGroup group;
  final Operation assignment;
  final bool isGroupCompleted;
  final bool hasGroupFoodRights;
  final String currentFoodType;
  final String? groupStartTime;
  final String? groupEndTime;
  final FeedingProvider feedingProvider;
  final Function(int, bool)? onAlimentacionChanged;
  final Function(WorkerGroup, List<Worker>)? onWorkersAddedToGroup;
  final Function(WorkerGroup, List<Worker>)? onWorkersRemovedFromGroup;

  const WorkersList({
    Key? key,
    required this.group,
    required this.assignment,
    required this.isGroupCompleted,
    required this.hasGroupFoodRights,
    required this.currentFoodType,
    required this.groupStartTime,
    required this.groupEndTime,
    required this.feedingProvider,
    this.onAlimentacionChanged,
    this.onWorkersAddedToGroup,
    this.onWorkersRemovedFromGroup,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.people,
          size: 16,
          color: isGroupCompleted
              ? const Color(0xFF38A169)
              : const Color(0xFF4A5568),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isGroupCompleted
                    ? 'Trabajadores completados:'
                    : 'Trabajadores asignados:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isGroupCompleted
                      ? const Color(0xFF38A169)
                      : const Color(0xFF4A5568),
                ),
              ),
              const SizedBox(height: 6),

              // Lista de trabajadores
              if (group.workersData != null && group.workersData!.isNotEmpty)
                ...group.workersData!
                    .map((worker) => _buildWorkerItem(context, worker))
              else
                _buildEmptyWorkersContainer(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkerItem(BuildContext context, dynamic worker) {
    // Verificar estado de alimentación solo si NO está completado
    bool alimentacionEntregada = false;
    bool puedeMarcarAlimentacion = false;

    if (!isGroupCompleted && hasGroupFoodRights) {
      alimentacionEntregada = feedingProvider.isMarked(
        assignment.id ?? 0,
        worker.id,
        currentFoodType,
      );
      puedeMarcarAlimentacion = FeedingUtils.puedeMarcarAlimentacion(
        groupStartTime,
        groupEndTime,
        context,
        assignment.id ?? 0,
        worker.id,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isGroupCompleted
            ? Colors.green.shade50.withOpacity(0.8)
            : (alimentacionEntregada
                ? Colors.green.shade50.withOpacity(0.7)
                : Colors.white),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isGroupCompleted
              ? Colors.green.withOpacity(0.5)
              : (alimentacionEntregada
                  ? Colors.green.withOpacity(0.3)
                  : const Color(0xFF3182CE).withOpacity(0.2)),
        ),
      ),
      child: Column(
        children: [
          // PRIMERA FILA: Info del trabajador
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 12,
                backgroundColor:
                    isGroupCompleted ? Colors.green : getColorForWorker(worker),
                child: isGroupCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : Text(
                        worker.name.isNotEmpty
                            ? worker.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(width: 8),

              // Info del trabajador
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isGroupCompleted
                            ? const Color(0xFF38A169)
                            : const Color(0xFF2D3748),
                      ),
                    ),
                    Text(
                      'DNI: ${worker.document}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isGroupCompleted
                            ? const Color(0xFF38A169)
                            : const Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),

              if (!isGroupCompleted && onWorkersRemovedFromGroup != null)
                IconButton(
                  icon: Icon(Icons.remove_circle_outline,
                      color: Colors.red[600], size: 16),
                  onPressed: () => _removeWorkerFromGroup(worker),
                  tooltip: 'Remover del grupo',
                ),

              // Mostrar estado de completado
              if (isGroupCompleted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38A169),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'FINALIZADO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),

          // SEGUNDA FILA: Botón de alimentación (solo si NO está completado)
          if (!isGroupCompleted &&
              hasGroupFoodRights &&
              onAlimentacionChanged != null &&
              currentFoodType.isNotEmpty)
            _buildFeedingButton(context, worker, alimentacionEntregada,
                puedeMarcarAlimentacion),
        ],
      ),
    );
  }

  void _removeWorkerFromGroup(dynamic worker) {
    if (onWorkersRemovedFromGroup != null) {
      // Convertir worker a Worker si es necesario
      final workerObj = worker is Worker
          ? worker
          : Worker(
              id: worker.id,
              name: worker.name,
              document: worker.document,
              area: worker.area ?? assignment.area,
              phone: worker.phone ?? '',
              status: WorkerStatus.assigned,
              startDate: DateTime.now(),
              code: worker.code ?? '',
              failures: worker.failures ?? 0,
              idArea: assignment.areaId,
            );

      onWorkersRemovedFromGroup!(group, [workerObj]);
    }
  }

  Widget _buildFeedingButton(
    BuildContext context,
    dynamic worker,
    bool alimentacionEntregada,
    bool puedeMarcarAlimentacion,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: GestureDetector(
        onTap: alimentacionEntregada
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'La alimentación ya fue entregada a ${worker.name}'),
                    backgroundColor: Colors.blue,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            : (puedeMarcarAlimentacion
                ? () {
                    onAlimentacionChanged!(worker.id, true);
                  }
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'La alimentación no está disponible en este horario'),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: alimentacionEntregada
                ? Colors.green.withOpacity(0.1)
                : (puedeMarcarAlimentacion
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: alimentacionEntregada
                  ? Colors.green.withOpacity(0.3)
                  : (puedeMarcarAlimentacion
                      ? Colors.orange.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.3)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                getIconForFoodType(currentFoodType, alimentacionEntregada),
                size: 14,
                color: alimentacionEntregada
                    ? Colors.green[700]
                    : (puedeMarcarAlimentacion
                        ? Colors.orange[700]
                        : Colors.grey[700]),
              ),
              const SizedBox(width: 4),
              Text(
                alimentacionEntregada
                    ? '$currentFoodType entregado'
                    : (puedeMarcarAlimentacion
                        ? 'Marcar $currentFoodType'
                        : 'No disponible'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: alimentacionEntregada
                      ? Colors.green[700]
                      : (puedeMarcarAlimentacion
                          ? Colors.orange[700]
                          : Colors.grey[700]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyWorkersContainer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isGroupCompleted
            ? const Color(0xFFE6FFFA)
            : const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isGroupCompleted
              ? const Color(0xFF38A169)
              : const Color(0xFFFEB2B2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isGroupCompleted ? Icons.check_circle : Icons.info_outline,
            size: 14,
            color: isGroupCompleted
                ? const Color(0xFF38A169)
                : const Color(0xFFE53E3E),
          ),
          const SizedBox(width: 6),
          Text(
            isGroupCompleted
                ? '${group.workers.length} trabajador${group.workers.length != 1 ? 'es' : ''} completado${group.workers.length != 1 ? 's' : ''}'
                : '${group.workers.length} trabajador${group.workers.length != 1 ? 'es' : ''} asignado${group.workers.length != 1 ? 's' : ''} (detalles no disponibles)',
            style: TextStyle(
              fontSize: 11,
              color: isGroupCompleted
                  ? const Color(0xFF38A169)
                  : const Color(0xFFE53E3E),
              fontStyle: isGroupCompleted ? FontStyle.normal : FontStyle.italic,
              fontWeight:
                  isGroupCompleted ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
