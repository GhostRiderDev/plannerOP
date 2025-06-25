import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/utils/operations.dart';
import 'package:plannerop/utils/feedingUtils.dart';
import 'package:plannerop/widgets/operations/components/utils/Loader.dart';

class OperationCard extends StatelessWidget {
  final Operation assignment;
  final Function(BuildContext, Operation) onTap;

  // Customization parameters
  final Color statusColor;
  final String statusText;
  final bool showCompletionDate;
  final bool showFoodInfo;
  final Widget? actionButton;

  const OperationCard({
    Key? key,
    required this.assignment,
    required this.onTap,
    required this.statusColor,
    required this.statusText,
    this.showCompletionDate = false,
    this.showFoodInfo = false,
    this.actionButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Neumorphic(
      style: NeumorphicStyle(
        depth: 2,
        intensity: 0.4,
        color: Colors.white,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
        lightSource: LightSource.topLeft,
        shadowDarkColorEmboss: Colors.grey.withValues(alpha: .2),
        shadowLightColorEmboss: Colors.white,
      ),
      child: InkWell(
        onTap: () => onTap(context, assignment),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: statusColor, width: 3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //  INFORMACIÓN PRINCIPAL
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Task info - principal
                  Expanded(child: _buildTaskInfo(context)),

                  // Action button - si existe, colocarlo arriba a la derecha
                  if (actionButton != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: actionButton!,
                    ),
                ],
              ),

              // Completion date (for completed assignments)
              if (showCompletionDate && assignment.endDate != null)
                _buildCompletionDate(),

              const SizedBox(height: 12),

              // INFORMACIÓN SECUNDARIA
              _buildFooterSection(context),
            ],
          ),
        ),
      ),
    );
  }

  // Separar la sección footer en su propio método
  Widget _buildFooterSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Separator
        Container(
          height: 1,
          color: const Color(0xFFEDF2F7),
          margin: const EdgeInsets.only(bottom: 8),
        ),

        // Area info
        Row(
          children: [
            const Icon(
              Icons.place_outlined,
              size: 14,
              color: Color(0xFF718096),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                assignment.area,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF718096),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Footer info (workers + time)
        _buildFooterInfo(),

        // Food chips - si están habilitados
        if (showFoodInfo) ...[
          const SizedBox(height: 8),
          _buildFoodChips(context),
        ],
      ],
    );
  }

  Widget _buildFooterInfo() {
    return Row(
      children: [
        // Worker count
        Icon(
          Icons.people_outline,
          size: 12,
          color: const Color(0xFF718096).withValues(alpha: .8),
        ),
        const SizedBox(width: 3),
        Text(
          "${_getWorkerCount()} ",
          style: TextStyle(
            fontSize: 11,
            color: const Color(0xFF718096).withValues(alpha: .8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),

        // Time
        Icon(
          Icons.access_time,
          size: 12,
          color: const Color(0xFF718096).withValues(alpha: .8),
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            assignment.time +
                (assignment.endTime != null ? " - ${assignment.endTime}" : ""),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: const Color(0xFF718096).withValues(alpha: .8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Helper para contar trabajadores
  int _getWorkerCount() {
    int count = 0;
    for (var group in assignment.groups) {
      count += group.workers.length;
    }
    return count;
  }

  Widget _buildTaskInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FutureBuilder<List<Widget>>(
          future: getServicesGroups(context, assignment.groups),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoader(
                size: LoaderSize.medium,
                color: Colors.blue,
              );
            }

            if (snapshot.hasError) {
              return Text(
                'Error loading services',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.withValues(alpha: 0.7),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: snapshot.data ?? [],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCompletionDate() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 12,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            DateFormat('dd/MM/yyyy')
                .format(assignment.endDate ?? DateTime.now()),
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodChips(BuildContext context) {
    // Get foods based on assignment times
    List<String> foods = FeedingUtils.determinateFoods(
        assignment.time, assignment.endTime, context);

    if (foods.isEmpty ||
        foods.contains('Sin alimentación') ||
        foods.contains('Sin alimentación actual')) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: foods.map((food) {
        IconData icon;
        Color color;

        switch (food) {
          case 'Desayuno':
            icon = Icons.free_breakfast;
            color = Colors.orange;
            break;
          case 'Almuerzo':
            icon = Icons.restaurant;
            color = Colors.green;
            break;
          case 'Cena':
            icon = Icons.dinner_dining;
            color = Colors.blue;
            break;
          case 'Media noche':
            icon = Icons.fastfood;
            color = Colors.purple;
            break;
          default:
            icon = Icons.fastfood;
            color = Colors.grey;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: .3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 10, color: color),
              const SizedBox(width: 2),
              Text(
                food,
                style: TextStyle(
                  fontSize: 9,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
