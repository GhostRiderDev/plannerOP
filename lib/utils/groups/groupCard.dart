import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/store/operations.dart';
import 'package:plannerop/store/feedings.dart';
import 'package:plannerop/utils/feedingUtils.dart';
import 'package:plannerop/utils/groups/groups.dart';
import 'package:plannerop/utils/groups/workerList.dart';
import 'package:plannerop/utils/operations.dart';
import 'package:plannerop/widgets/operations/components/completeDialogs.dart';
import 'package:provider/provider.dart';

//  Tarjeta individual de grupo
class GroupCard extends StatelessWidget {
  final WorkerGroup group;
  final int groupIndex;
  final Operation assignment;
  final Function(int, bool)? onAlimentacionChanged;
  final Function? setState;

  const GroupCard({
    Key? key,
    required this.group,
    required this.groupIndex,
    required this.assignment,
    this.onAlimentacionChanged,
    this.setState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final feedingProvider = Provider.of<FeedingProvider>(context);
    final assignmentsProvider =
        Provider.of<OperationsProvider>(context, listen: false);

    // Verificar si el grupo ya está completado
    bool isGroupCompleted = group.endDate != null &&
        group.endDate!.isNotEmpty &&
        group.endTime != null &&
        group.endTime!.isNotEmpty;

    bool canCompleteGroup = assignment.status != 'PENDING' && !isGroupCompleted;

    // Calcular alimentación específica para este grupo
    List<String> groupFoods = [];
    bool hasGroupFoodRights = false;
    String currentFoodType = '';

    String? groupStartTime = group.startTime;
    String? groupEndTime = group.endTime;

    if ((groupStartTime == null || groupStartTime.isEmpty)) {
      groupStartTime = assignment.time;
      groupEndTime = assignment.endTime;
    }

    // Solo calcular alimentación si el grupo NO está completado
    if (!isGroupCompleted &&
        groupStartTime != null &&
        groupStartTime.isNotEmpty) {
      groupFoods = FeedingUtils.determinateFoodsWithDeliveryStatus(
        groupStartTime,
        groupEndTime,
        context,
        operationId: assignment.id,
        workerId: null,
      );

      hasGroupFoodRights = groupFoods.isNotEmpty &&
          !groupFoods.contains('Sin alimentación') &&
          !groupFoods.contains('Sin alimentación actual') &&
          !groupFoods[0].contains('ya entregado');

      if (hasGroupFoodRights) {
        currentFoodType = groupFoods[0];
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isGroupCompleted
            ? const Color(0xFFE6FFFA) // Verde muy claro para completados
            : const Color(0xFFF7FAFC), // Color original para activos
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isGroupCompleted
              ? const Color(0xFF38A169) // Verde para completados
              : const Color(0xFFE2E8F0), // Color original
          width: isGroupCompleted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CABECERA CON BOTÓN DE COMPLETAR GRUPO
          _buildGroupHeader(
            context,
            isGroupCompleted,
            canCompleteGroup,
            assignmentsProvider,
          ),

          const SizedBox(height: 8),

          // INFORMACIÓN DEL GRUPO
          _buildGroupInfo(context, isGroupCompleted),

          const SizedBox(height: 8),

          // LISTA DE TRABAJADORES
          WorkersList(
            group: group,
            assignment: assignment,
            isGroupCompleted: isGroupCompleted,
            hasGroupFoodRights: hasGroupFoodRights,
            currentFoodType: currentFoodType,
            groupStartTime: groupStartTime,
            groupEndTime: groupEndTime,
            feedingProvider: feedingProvider,
            onAlimentacionChanged: onAlimentacionChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(
    BuildContext context,
    bool isGroupCompleted,
    bool canCompleteGroup,
    OperationsProvider assignmentsProvider,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isGroupCompleted
                ? const Color(0xFF38A169) // Verde para completados
                : const Color(0xFF3182CE), // Azul original
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isGroupCompleted
                ? 'Grupo ${groupIndex + 1} - COMPLETADO'
                : 'Grupo ${groupIndex + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const Spacer(),
        if (canCompleteGroup)
          NeumorphicButton(
            style: NeumorphicStyle(
              depth: 2,
              intensity: 0.5,
              color: Colors.white,
              boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(4)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            onPressed: () {
              if (group.workersData != null) {
                showGroupCompletionDialog(
                  context,
                  assignment,
                  group.workersData!,
                  group.id ?? "",
                  assignmentsProvider,
                  setState ?? () {},
                );
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.done_all, color: Color(0xFF38A169), size: 14),
                SizedBox(width: 4),
                Text(
                  'Completar grupo',
                  style: TextStyle(
                    color: Color(0xFF38A169),
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          )
        else if (isGroupCompleted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF38A169),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.check_circle, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  'Completado',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          )
        else if (assignment.status == 'PENDING')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFECC94B),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.schedule, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  'Pendiente',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildGroupInfo(BuildContext context, bool isGroupCompleted) {
    return Column(
      children: [
        // Horario del grupo
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isGroupCompleted
                    ? const Color(0xFFD6F5D6) // Verde claro para completados
                    : const Color(0xFFEDF2F7), // Color original
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isGroupCompleted ? Icons.check_circle : Icons.access_time,
                    size: 12,
                    color: isGroupCompleted
                        ? const Color(0xFF38A169)
                        : const Color(0xFF4A5568),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    getGroupName(
                      group.startDate != null
                          ? DateTime.parse(group.startDate!)
                          : null,
                      group.endDate != null
                          ? DateTime.parse(group.endDate!)
                          : null,
                      group.startTime,
                      group.endTime,
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isGroupCompleted
                          ? const Color(0xFF38A169)
                          : const Color(0xFF4A5568),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Servicio
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.design_services,
                    size: 16,
                    color: isGroupCompleted
                        ? const Color(0xFF38A169)
                        : const Color(0xFF3182CE),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: FutureBuilder<String>(
                      future: getServiceName(context, group.serviceId),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Text(
                            snapshot.data!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isGroupCompleted
                                  ? const Color(0xFF38A169)
                                  : const Color(0xFF2D3748),
                            ),
                          );
                        } else {
                          return Text(
                            'Cargando...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isGroupCompleted
                                  ? const Color(0xFF38A169)
                                  : const Color(0xFF2D3748),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
