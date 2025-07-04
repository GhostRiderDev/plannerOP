import 'package:flutter/material.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/providers/operations.dart';
import 'package:plannerop/widgets/operations/components/completationDialogs/jornalCompletation.dart';

void showGroupCompletionDialogRequireData(
    BuildContext context,
    Operation assignment,
    List<Worker> workers,
    String groupId,
    OperationsProvider provider,
    Function setState,
    WorkerGroup group) {
  // DETERMINAR el tipo de diálogo basado en idUnitOfMeasure
  switch (group.idUnitOfMeasure) {
    case 1: // Jornada/Horas
      showJornalCompletionDialog(
        context,
        assignment,
        workers,
        groupId,
        provider,
        setState,
        group,
      );
      break;
    // case 2: // Por toneladas
    //   _showTonnageCompletionDialog(
    //     context,
    //     assignment,
    //     workers,
    //     groupId,
    //     provider,
    //     setState,
    //     group,
    //   );
    //   break;
    // case 3: // Por contenedores
    //   _showContainerCompletionDialog(
    //     context,
    //     assignment,
    //     workers,
    //     groupId,
    //     provider,
    //     setState,
    //     group,
    //   );
    //   break;
    // default:
    //   // Diálogo genérico (el que ya existía)
    //   _showGenericCompletionDialog(
    //     context,
    //     assignment,
    //     workers,
    //     groupId,
    //     provider,
    //     setState,
    //   );
    //   break;
  }
}
