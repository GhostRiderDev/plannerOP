import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/area.dart';
import 'package:plannerop/core/model/client.dart';
import 'package:plannerop/core/model/programming.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/store/areas.dart';
import 'package:plannerop/store/clients.dart';
import 'package:plannerop/store/operations.dart';
import 'package:plannerop/store/user.dart';
import 'package:plannerop/store/workers.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:provider/provider.dart';

Future<bool> validateFields({
  required BuildContext context,
  required List<Worker> selectedWorkers,
  required List<WorkerGroup> selectedGroups,
  required String areaControl,
  required String startDateControl,
  required String startTimeControl,
  required String clientControl,
  required String motorshipControl,
  required String chargerControl,
  required String endDateControl,
  required String zoneControl,
  required String endTimeControl,
  required Programming? selectedProgramming,
}) async {
  if (selectedGroups.isEmpty) {
    showAlertToast(context, 'Por favor, selecciona al menos un grupo');
    return false;
  }

  if (areaControl.isEmpty) {
    showAlertToast(context, 'Por favor, selecciona un área');
    return false;
  }

  if (startDateControl.isEmpty) {
    showAlertToast(context, 'Por favor, selecciona una fecha de inicio');
    return false;
  }

  if (startTimeControl.isEmpty) {
    showAlertToast(context, 'Por favor, selecciona una hora de inicio');
    return false;
  }

  if (clientControl.isEmpty) {
    showAlertToast(context, 'Por favor, selecciona un cliente');
    return false;
  }

  if (areaControl.toUpperCase() == 'BUQUE' && motorshipControl.isEmpty) {
    showAlertToast(context, 'Por favor, ingresa el nombre de la motonave');
    return false;
  }

  if (chargerControl.isEmpty) {
    showAlertToast(context, 'Por favor, selecciona al menos un encargado');
    return false;
  }

  try {
    final workersProvider =
        Provider.of<WorkersProvider>(context, listen: false);
    final areasProvider = Provider.of<AreasProvider>(context, listen: false);
    final operationsProvider =
        Provider.of<OperationsProvider>(context, listen: false);

    final startDate = DateFormat('dd/MM/yyyy').parse(startDateControl);

    DateTime? endDate;
    if (endDateControl.isNotEmpty) {
      endDate = DateFormat('dd/MM/yyyy').parse(endDateControl);
    }

    final selectedArea = areasProvider.areas.firstWhere(
        (area) => area.name == areaControl,
        orElse: () => Area(id: 0, name: areaControl));

    var clientsProvider = Provider.of<ClientsProvider>(context, listen: false);

    int clientId = clientsProvider.clients
        .firstWhere((client) => client.name == clientControl,
            orElse: () => Client(id: 1, name: clientControl))
        .id;

    int zoneNum = 1;
    final zoneText = zoneControl;
    if (zoneText.startsWith('Zona ')) {
      zoneNum = int.tryParse(zoneText.substring(5)) ?? 1;
    }

    zoneNum = zoneControl.isEmpty == true ? 0 : zoneNum;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user.id;

    List<int> chargerIds = [];
    if (chargerControl.isNotEmpty) {
      try {
        final chargerIdStrings = chargerControl.split(',');
        for (String idStr in chargerIdStrings) {
          if (idStr.trim().isNotEmpty) {
            final parsedId = int.parse(idStr.trim());
            if (parsedId > 0) {
              chargerIds.add(parsedId);
            }
          }
        }
      } catch (e) {
        debugPrint('Error al procesar IDs de encargados: $e');
        debugPrint('Texto en controller: ${chargerControl}');
      }
    }

    final success = await operationsProvider.addAssignment(
      area: areaControl,
      areaId: selectedArea.id,
      date: startDate,
      time: startTimeControl,
      zoneId: zoneNum,
      userId: userId,
      clientId: clientId,
      clientName: clientControl,
      endDate: endDate,
      endTime: endTimeControl.isNotEmpty ? endTimeControl : null,
      motorship: areaControl.toUpperCase() == 'BUQUE' ? motorshipControl : null,
      chargerIds: chargerIds,
      context: context,
      groups: selectedGroups,
      id_clientProgramming: selectedProgramming?.id,
    );

    if (!success) {
      showErrorToast(context,
          'Error al guardar la operación: ${operationsProvider.error}');
      return false;
    }

    for (var worker in selectedWorkers) {
      DateTime workerEndDate =
          endDate ?? startDate.add(const Duration(days: 7));
      workersProvider.assignWorker(worker, workerEndDate);
    }

    return true;
  } catch (e) {
    debugPrint('Error en _validateFields: $e');
    showErrorToast(context, 'Error al procesar los datos: $e');
    return false;
  }
}
