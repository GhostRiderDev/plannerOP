import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/mapper/operation.dart';
import 'package:plannerop/store/operations.dart';
import 'package:plannerop/utils/operations.dart';
import 'package:plannerop/widgets/operations/components/utils/emptyState.dart';
import 'package:provider/provider.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:intl/intl.dart';

class RecentOps extends StatelessWidget {
  const RecentOps({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OperationsProvider>(
      builder: (context, provider, child) {
        // Obtener las asignaciones ordenadas por fecha reciente
        final allAssignments = [...provider.operations];
        allAssignments.sort((a, b) {
          final dateA = a.endDate ?? a.date;
          final dateB = b.endDate ?? b.date;
          return dateB.compareTo(dateA);
        });

        // Limitar a 7 elementos
        final recentOps = allAssignments.take(7).toList();
        final int itemCount = recentOps.isEmpty ? 0 : recentOps.length;

        return Neumorphic(
          style: NeumorphicStyle(
            depth: 3,
            intensity: 0.5,
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
            color: const Color(0xFFF7FAFC),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: const [
                    Icon(Icons.history, color: Color(0xFF4299E1), size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Operaciones Recientes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 270,
                  child: Neumorphic(
                    style: NeumorphicStyle(
                      depth: 2,
                      intensity: 0.6,
                      boxShape: NeumorphicBoxShape.roundRect(
                          BorderRadius.circular(12)),
                      color: Colors.white,
                    ),
                    child: itemCount == 0
                        ? _buildEmptyState()
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount: itemCount,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final assignment = recentOps[index];

                              // Determinar el estado de la operación
                              String estado;
                              Color colorFondo;
                              Color colorTexto;

                              switch (assignment.status) {
                                case 'PENDING':
                                  estado = 'Pendiente';
                                  colorFondo = const Color(0xFFFEF5E7);
                                  colorTexto = const Color(0xFFB7791F);
                                  break;
                                case 'INPROGRESS':
                                  estado = 'En curso';
                                  colorFondo = const Color(0xFFEBF4FF);
                                  colorTexto = const Color(0xFF2B6CB0);
                                  break;
                                case 'COMPLETED':
                                  estado = 'Finalizada';
                                  colorFondo = const Color(0xFFE6FFED);
                                  colorTexto = const Color(0xFF2F855A);
                                  break;
                                default:
                                  estado = 'Pendiente';
                                  colorFondo = const Color(0xFFFEF5E7);
                                  colorTexto = const Color(0xFFB7791F);
                              }

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 6.0),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FutureBuilder<List<Widget>>(
                                      future: getServicesGroups(
                                          context, assignment.groups),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const CircularProgressIndicator(
                                              strokeWidth: 2);
                                        } else if (snapshot.hasError) {
                                          return Text(
                                              'Error: ${snapshot.error}');
                                        } else if (snapshot.hasData) {
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: snapshot.data!,
                                          );
                                        } else {
                                          return const SizedBox.shrink();
                                        }
                                      },
                                    )
                                  ],
                                ),
                                subtitle: Text(
                                  'Área: ${assignment.area}',
                                  style: const TextStyle(
                                    color: Color(0xFF718096),
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: colorFondo,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    estado,
                                    style: TextStyle(
                                      color: colorTexto,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  // CAMBIO: Usar showOperationDetails en lugar del método personalizado
                                  _showRecentOperationDetails(
                                      context, assignment);
                                },
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      message: 'No hay operaciones recientes',
    );
  }

  //  Usar showOperationDetails
  void _showRecentOperationDetails(BuildContext context, Operation assignment) {
    // Determinar estado y colores
    String estado;
    Color statusColor;

    switch (assignment.status.toUpperCase()) {
      case 'PENDING':
        estado = 'Pendiente';
        statusColor = const Color(0xFFB7791F);
        break;
      case 'INPROGRESS':
        estado = 'En curso';
        statusColor = const Color(0xFF2B6CB0);
        break;
      case 'COMPLETED':
        estado = 'Finalizada';
        statusColor = const Color(0xFF2F855A);
        break;
      case 'CANCELED':
        estado = 'Cancelada';
        statusColor = const Color(0xFFE53E3E);
        break;
      default:
        estado = 'Pendiente';
        statusColor = const Color(0xFFB7791F);
    }

    // Usar showOperationDetails con configuración para operaciones recientes
    showOperationDetails(
      context: context,
      assignment: assignment,
      statusColor: statusColor,
      statusText: estado,

      // Builder personalizado para detalles adicionales específicos de recientes
      detailsBuilder: (operation) {
        final formattedStartDate =
            DateFormat('dd/MM/yyyy').format(operation.date);
        final formattedEndDate = operation.endDate != null
            ? DateFormat('dd/MM/yyyy').format(operation.endDate!)
            : 'No especificada';

        return [
          buildDetailRow('Fecha', formattedStartDate),
          buildDetailRow('Hora', operation.time),
          buildDetailRow('Estado', estado),
          if (operation.endTime != null)
            buildDetailRow(
                'Hora de finalización', operation.endTime ?? 'No especificada'),
          if (operation.endDate != null)
            buildDetailRow('Fecha de finalización', formattedEndDate),
          buildDetailRow('Zona',
              operation.zone == 0 ? 'Sin zona' : 'Zona ${operation.zone}'),
          if (operation.motorship != null && operation.motorship!.isNotEmpty)
            buildDetailRow('Motonave', operation.motorship!),

          // Información adicional para operaciones recientes
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  getStatusIcon(operation.status),
                  color: statusColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Esta operación se encuentra en estado: $estado',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ];
      },

      // Botones de acción simples para operaciones recientes
      actionsBuilder: (context, operation) {
        return [
          // Solo botón de cerrar para operaciones recientes
          Expanded(
            child: NeumorphicButton(
              style: NeumorphicStyle(
                depth: 2,
                intensity: 0.7,
                color: const Color(0xFF3182CE),
                boxShape:
                    NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cerrar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ];
      },
    );
  }
}
