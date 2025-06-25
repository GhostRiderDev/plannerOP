import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/core/model/programming.dart';
import 'package:plannerop/core/model/user.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/mapper/operation.dart';
import 'package:plannerop/store/operations.dart';
import 'package:plannerop/store/chargersOp.dart';
import 'package:plannerop/store/clients.dart';
import 'package:plannerop/store/programmings.dart';
import 'package:plannerop/store/task.dart';
import 'package:plannerop/utils/groups/groups.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/operations/components/utils.dart';
import 'package:plannerop/widgets/operations/components/utils/Loader.dart';
import 'package:provider/provider.dart';

Future<Widget> _buildClientProgrammingRow(
    BuildContext context, int programmingId) async {
  try {
    final programmingsProvider =
        Provider.of<ProgrammingsProvider>(context, listen: false);

    // Buscar la programación por ID (primero en caché, luego en backend)
    Programming? programming =
        await programmingsProvider.fetchProgrammingById(programmingId, context);

    if (programming != null) {
      // Agregar al caché para futuros usos
      programmingsProvider.addProgrammingToCache(programming);
      return _buildProgrammingDetailCard(programming);
    } else {
      return buildDetailRow(
          'Programación Cliente', 'ID: $programmingId (No encontrada)');
    }
  } catch (e) {
    debugPrint('Error al obtener programación del cliente: $e');
    return buildDetailRow('Programación Cliente', 'Error al cargar: $e');
  }
}

// Widget mejorado para mostrar los detalles de la programación
Widget _buildProgrammingDetailCard(Programming programming) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F8FF), // Azul muy claro
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFF3182CE).withOpacity(0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección
        Row(
          children: [
            const Icon(
              Icons.event_note,
              size: 16,
              color: Color(0xFF3182CE),
            ),
            const SizedBox(width: 6),
            const Text(
              'Programación del Cliente',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A5568),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: getStatusColor(programming.status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                getOperationStatusText(programming.status),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Detalles de la programación
        _buildProgrammingDetailRow('Solicitud', programming.service_request),
        _buildProgrammingDetailRow('Servicio', programming.service),
        _buildProgrammingDetailRow('Cliente', programming.client),
        _buildProgrammingDetailRow('Ubicación', programming.ubication),

        Row(
          children: [
            Expanded(
              child: _buildProgrammingDetailRow(
                  'Fecha',
                  DateFormat('dd/MM/yyyy')
                      .format(DateTime.parse(programming.dateStart))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildProgrammingDetailRow('Hora', programming.timeStart),
            ),
          ],
        ),
      ],
    ),
  );
}

// Widget auxiliar para las filas de detalles de programación
Widget _buildProgrammingDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF718096),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Shows assignment details in a modal bottom sheet
void showOperationDetails({
  required BuildContext context,
  required Operation assignment,
  // Appearance customization
  Color statusColor = const Color(0xFF3182CE),
  String statusText = 'Pendiente',
  // Content builders
  List<Widget> Function(Operation)? detailsBuilder,
  Widget Function(Operation, BuildContext)? workersBuilder,
  // Actions
  List<Widget> Function(BuildContext, Operation)? actionsBuilder,
  Widget Function(BuildContext, Operation)? floatingActionBuilder,
  // Groups configuration
  Map<int, bool> alimentacionStatus = const {},
  List<String> foods = const [],
  Function(int, bool)? onAlimentacionChanged,
  Function? setState,
  // Event handlers
  VoidCallback? onClose,
}) {
  // Get in-charge users
  final inChargersFormat =
      Provider.of<ChargersOpProvider>(context, listen: false)
          .chargers
          .where((charger) => assignment.inChagers.contains(charger.id))
          .map((charger) {
    return User(
      id: charger.id,
      name: charger.name,
      cargo: charger.cargo,
      dni: charger.dni,
      phone: charger.phone,
    );
  }).toList();

  // Default details builder if none provided
  List<Widget> buildDefaultDetails(Operation assignment) {
    return [
      buildDetailRow('Fecha', DateFormat('dd/MM/yyyy').format(assignment.date)),
      buildDetailRow('Hora', assignment.time),
      buildDetailRow('Estado', statusText),
      if (assignment.endTime != null)
        buildDetailRow(
            'Hora de finalización', assignment.endTime ?? 'No especificada'),
      if (assignment.endDate != null)
        buildDetailRow('Fecha de finalización',
            DateFormat('dd/MM/yyyy').format(assignment.endDate!)),
      assignment.zone != 0
          ? buildDetailRow('Zona', 'Zona ${assignment.zone}')
          : buildDetailRow('Zona', 'N/A'),
      if (assignment.motorship != null && assignment.motorship!.isNotEmpty)
        buildDetailRow('Motonave', assignment.motorship!),

      // Programación del Cliente
      if (assignment.id_clientProgramming != null &&
          assignment.id_clientProgramming != 0)
        FutureBuilder<Widget>(
          future: _buildClientProgrammingRow(
              context, assignment.id_clientProgramming!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return buildDetailRow('Programación Cliente', 'Cargando...');
            } else if (snapshot.hasError) {
              return buildDetailRow('Programación Cliente', 'Error al cargar');
            } else if (snapshot.hasData) {
              return snapshot.data!;
            } else {
              return buildDetailRow('Programación Cliente', 'No encontrada');
            }
          },
        ),
    ];
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.room_outlined,
                            size: 16,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            assignment.area,
                            style: TextStyle(
                              fontSize: 14,
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Assignment details
                        buildDetailSection(
                          title: 'Detalles de la operación',
                          children: detailsBuilder != null
                              ? detailsBuilder(assignment)
                              : buildDefaultDetails(assignment),
                        ),
                        const SizedBox(height: 20),

                        // Workers section
                        if (workersBuilder != null) ...[
                          workersBuilder(assignment, context),
                          const SizedBox(height: 20),
                        ],

                        if (assignment.status == 'PENDING' ||
                            assignment.status == "COMPLETED") ...[
                          // Groups section with enhanced support
                          buildGroupsSection(
                            context,
                            assignment.groups,
                            'Grupos de trabajo',
                            assignment: assignment,
                            alimentacionStatus: alimentacionStatus,
                            foods: foods,
                            onAlimentacionChanged: onAlimentacionChanged,
                            setState: setState,
                          ),
                        ],

                        // In-charges section
                        if (inChargersFormat.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          buildDetailSection(
                            title: 'Encargados de la operación',
                            children: inChargersFormat
                                .map((charger) => buildInChargerItem(charger))
                                .toList(),
                          ),
                        ],
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                if (actionsBuilder != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: actionsBuilder(context, assignment),
                    ),
                  ),
              ],
            ),
          ),

          // Floating action button (e.g. cancel button)
          if (floatingActionBuilder != null)
            Positioned(
              right: 20,
              bottom: 90,
              child: floatingActionBuilder(context, assignment),
            ),
        ],
      );
    },
  );
}

Widget buildDetailSection(
    {required String title, required List<Widget> children}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2D3748),
        ),
      ),
      const SizedBox(height: 12),
      ...children,
    ],
  );
}

/// Funcion que construye un item de la card
Widget buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A5568),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
      ],
    ),
  );
}

// Método para mostrar el diálogo de cancelación (agregarlo si no existe)
void showCancelDialog(
    BuildContext context, Operation assignment, OperationsProvider provider) {
  bool isProcessing = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Cancelar operación'),
            content: const Text(
              '¿Estás seguro de que deseas cancelar esta operación?',
              style: TextStyle(color: Color(0xFF718096)),
            ),
            actions: [
              TextButton(
                onPressed:
                    isProcessing ? null : () => Navigator.pop(dialogContext),
                style: TextButton.styleFrom(
                  foregroundColor: isProcessing
                      ? const Color(0xFFCBD5E0)
                      : const Color(0xFF718096),
                ),
                child: const Text('No'),
              ),
              NeumorphicButton(
                style: NeumorphicStyle(
                  depth: isProcessing ? 0 : 2,
                  intensity: 0.7,
                  color: isProcessing
                      ? const Color(0xFFFED7D7)
                      : const Color(0xFFF56565),
                  boxShape:
                      NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                ),
                onPressed: isProcessing
                    ? null
                    : () async {
                        setDialogState(() {
                          isProcessing = true;
                        });

                        try {
                          debugPrint('Cancelando operación ${assignment.id}');

                          // Aquí iría la llamada a la API para cancelar
                          await provider.updateOperation(
                              id: assignment.id ?? 0,
                              status: 'CANCELED',
                              context: context);

                          Navigator.pop(dialogContext);
                          showSuccessToast(
                              context, 'Operación cancelada exitosamente');
                        } catch (e) {
                          debugPrint('Error al cancelar operación: $e');

                          if (context.mounted) {
                            setDialogState(() {
                              isProcessing = false;
                            });
                            showErrorToast(
                                context, 'Error al cancelar operación: $e');
                          }
                        }
                      },
                child: Container(
                  width: 100,
                  height: 36,
                  child: Center(
                    child: isProcessing
                        ? AppLoader(
                            color: Colors.white,
                            size: LoaderSize.small,
                          )
                        : const Text(
                            'Sí, cancelar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

// método para crear campos no editables con el mismo estilo que los editables
Widget buildNonEditableField({
  required String label,
  required String value,
  required IconData icon,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
            color: const Color(
                0xFFF7FAFC), // Color de fondo más claro para indicar que no es editable
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF718096)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF2D3748),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Map<int, String> _servicesCache = {};

Future<List<Widget>> getServicesGroups(
    BuildContext context, List<WorkerGroup> groups) async {
  List<Widget> serviceWidgets = [];
  for (var group in groups) {
    final serviceWidget = await getServiceGroup(context, group);
    if (serviceWidget != null) {
      serviceWidgets.add(serviceWidget);
    }
  }

  return serviceWidgets;
}

Future<Widget?> getServiceGroup(BuildContext context, WorkerGroup group) async {
  //  VERIFICAR SI EL CONTEXT AÚN ES VÁLIDO
  if (!context.mounted) {
    debugPrint('Context no está montado, retornando widget por defecto');
    return _buildDefaultServiceWidget(group);
  }

  try {
    String serviceName;

    //  USAR CACHE PARA EVITAR LLAMADAS REPETIDAS
    if (_servicesCache.containsKey(group.serviceId)) {
      serviceName = _servicesCache[group.serviceId]!;
    } else {
      //  VERIFICAR NUEVAMENTE ANTES DE ACCEDER AL PROVIDER
      if (!context.mounted) {
        return _buildDefaultServiceWidget(group);
      }

      final serviceProvider =
          Provider.of<TasksProvider>(context, listen: false);
      serviceName = await serviceProvider.getTaskNameByIdServiceAsync(
          group.serviceId, context);

      // Guardar en cache
      _servicesCache[group.serviceId] = serviceName;
    }

    //  VERIFICAR UNA VEZ MÁS ANTES DE RETORNAR EL WIDGET
    if (!context.mounted) {
      return _buildDefaultServiceWidget(group);
    }

    return Row(
      children: [
        Icon(
          Icons.design_services,
          size: 12,
          color: const Color(0xFF3182CE),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            serviceName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
      ],
    );
  } catch (e) {
    debugPrint('Error en getServiceGroup: $e');
    return _buildDefaultServiceWidget(group);
  }
}

//  WIDGET POR DEFECTO CUANDO NO SE PUEDE OBTENER EL SERVICIO
Widget _buildDefaultServiceWidget(WorkerGroup group) {
  return Row(
    children: [
      Icon(
        Icons.design_services,
        size: 12,
        color: const Color(0xFF718096), // Color más suave para indicar error
      ),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          'Servicio ${group.serviceId}', // Mostrar el ID como fallback
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF718096),
          ),
        ),
      ),
    ],
  );
}

// Obtener el nombre del cliente usando el ID
Future<String?> getClientName(BuildContext context, int clientId) async {
  final clientsProvider = Provider.of<ClientsProvider>(context, listen: false);
  final client = clientsProvider.getClientById(clientId);

  return client.name;
}

// Método auxiliar para obtener el nombre del servicio
Future<String> getServiceName(BuildContext context, int serviceId) async {
  try {
    final serviceProvider = Provider.of<TasksProvider>(context, listen: false);
    return await serviceProvider.getTaskNameByIdServiceAsync(
        serviceId, context);
  } catch (e) {
    return 'Servicio desconocido';
  }
}
