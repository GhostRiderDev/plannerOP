import 'package:flutter/material.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/store/feedings.dart';
import 'package:plannerop/utils/feedingUtils.dart';
import 'package:plannerop/utils/groups/groups.dart';
import 'package:plannerop/widgets/operations/components/workers/buildWorkerItem.dart';
import 'package:provider/provider.dart';

// ✅ NUEVO WIDGET PARA MANEJAR LA CARGA DE ALIMENTACIÓN
class FeedingAwareWidget extends StatefulWidget {
  final int operationId;
  final Operation assignment;
  final Map<int, bool> alimentacionStatus;
  final Function(int, bool) onAlimentacionChanged;

  const FeedingAwareWidget({
    Key? key,
    required this.operationId,
    required this.assignment,
    required this.alimentacionStatus,
    required this.onAlimentacionChanged,
  }) : super(key: key);

  @override
  State<FeedingAwareWidget> createState() => _FeedingAwareWidgetState();
}

class _FeedingAwareWidgetState extends State<FeedingAwareWidget> {
  bool _isLoading = true;
  bool _hasError = false;
  List<String> _foods = [];
  FeedingProvider? _feedingProvider;

  @override
  void initState() {
    super.initState();
    _loadFeedingData();
  }

  Future<void> _loadFeedingData() async {
    if (!mounted) return;

    try {
      _feedingProvider = Provider.of<FeedingProvider>(context, listen: false);

      // Cargar datos de alimentación sin bloquear la UI
      await _feedingProvider!
          .loadFeedingStatusForOperation(widget.operationId, context);

      // Calcular foods después de cargar los datos
      if (mounted) {
        _foods = FeedingUtils.determinateFoodsWithDeliveryStatus(
            widget.assignment.time, widget.assignment.endTime, context,
            operationId: widget.operationId);

        setState(() {
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando alimentación: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Cargando información de alimentación...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: Colors.orange[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Error al cargar información de alimentación',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orange[600],
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
                _loadFeedingData();
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    // ✅ DATOS CARGADOS, MOSTRAR CONTENIDO COMPLETO
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mostrar información de alimentación si está disponible
        if (_foods.isNotEmpty && _foods[0] != "Sin alimentación")
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.restaurant, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Alimentación disponible: ${_foods.join(", ")}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // ✅ MOSTRAR GRUPOS DE TRABAJO CON ALIMENTACIÓN
        if (widget.assignment.groups.isNotEmpty)
          buildGroupsSection(
            context,
            widget.assignment.groups,
            'Grupos de trabajo',
            assignment: widget.assignment,
            alimentacionStatus: widget.alimentacionStatus,
            foods: _foods,
            onAlimentacionChanged:
                _foods.isNotEmpty && _foods[0] != "Sin alimentación"
                    ? (workerId, entregada) {
                        if (_foods.isNotEmpty && _feedingProvider != null) {
                          _feedingProvider!.markFeeding(
                            operationId: widget.operationId,
                            workerId: workerId,
                            foodType: _foods[0],
                            context: context,
                          );
                        }
                        widget.onAlimentacionChanged(workerId, entregada);
                      }
                    : null,
            setState: () {
              if (mounted) {
                setState(() {});
              }
            },
          ),

        // Mostrar trabajadores eliminados si los hay
        if (widget.assignment.deletedWorkers.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildDeletedWorkersSection(),
        ],
      ],
    );
  }

  Widget _buildDeletedWorkersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trabajadores eliminados',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 12),
        ...widget.assignment.deletedWorkers.map((worker) {
          bool entregada = widget.alimentacionStatus[worker.id] ?? false;
          bool tieneDerechoAlimentacion =
              _foods.isNotEmpty && _foods[0] != "Sin alimentación";

          return buildWorkerItem(
            worker,
            context,
            isDeleted: true,
            alimentacionEntregada: entregada,
            onAlimentacionChanged: tieneDerechoAlimentacion
                ? (newValue) {
                    if (_foods.isNotEmpty && _feedingProvider != null) {
                      _feedingProvider!.markFeeding(
                        operationId: widget.operationId,
                        workerId: worker.id,
                        foodType: _foods[0],
                        context: context,
                      );
                    }
                    widget.onAlimentacionChanged(worker.id, newValue);
                  }
                : null,
          );
        }).toList(),
      ],
    );
  }
}
