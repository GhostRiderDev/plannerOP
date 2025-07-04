import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/store/workers.dart';
import 'package:plannerop/utils/groups/groupCard.dart';

import 'package:provider/provider.dart';

String getGroupName(DateTime? startDate, DateTime? endDate, String? startTime,
    String? endTime) {
  String groupName = '';

  bool hasDifferentDates = startDate != null &&
      endDate != null &&
      DateFormat('yyyy-MM-dd').format(startDate) !=
          DateFormat('yyyy-MM-dd').format(endDate);

  if (startDate != null &&
      endDate != null &&
      startTime != null &&
      endTime != null) {
    if (hasDifferentDates) {
      groupName =
          ' ${DateFormat('dd/MM').format(startDate)} $startTime - ${DateFormat('dd/MM').format(endDate)} $endTime';
    } else {
      groupName =
          ' ${DateFormat('dd/MM').format(startDate)} $startTime-$endTime';
    }
  } else if (startDate != null && endDate != null) {
    if (hasDifferentDates) {
      groupName =
          ' ${DateFormat('dd/MM').format(startDate)} - ${DateFormat('dd/MM').format(endDate)}';
    } else {
      groupName = ' ${DateFormat('dd/MM').format(startDate)}';
    }
  } else if (startTime != null && endTime != null) {
    groupName = ' $startTime-$endTime';
  } else if (startDate != null && startTime != null) {
    groupName = ' ${DateFormat('dd/MM').format(startDate)} $startTime';
  } else if (endDate != null && endTime != null) {
    groupName = 'Fin: ${DateFormat('dd/MM').format(endDate)} $endTime';
  } else if (startDate != null) {
    groupName = 'Inicio: ${DateFormat('dd/MM').format(startDate)}';
  } else if (endDate != null) {
    groupName = 'Fin: ${DateFormat('dd/MM').format(endDate)}';
  } else if (startTime != null) {
    groupName = 'Inicio: $startTime';
  } else if (endTime != null) {
    groupName = 'Fin: $endTime';
  }

  return groupName;
}

//  Contenedor principal de grupos
Widget buildGroupsSection(
    BuildContext context, List<WorkerGroup> groups, String title,
    {required Operation assignment,
    Map<int, bool> alimentacionStatus = const {},
    List<String> foods = const [],
    Function(int, bool)? onAlimentacionChanged,
    Function? setState}) {
  // Preparar datos de trabajadores
  for (var group in groups) {
    group.workersData = group.workers
        .map((workerId) =>
            context.read<WorkersProvider>().getWorkerById(workerId))
        .toList();
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 57, 80, 121),
        ),
      ),
      const SizedBox(height: 12),

      // Lista de grupos
      ...groups.asMap().entries.map((entry) {
        final index = entry.key;
        final group = entry.value;

        return GroupCard(
          group: group,
          groupIndex: index,
          assignment: assignment,
          onAlimentacionChanged: onAlimentacionChanged,
          setState: setState,
        );
      }).toList(),
    ],
  );
}
