import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/providers/operations.dart';
import 'package:plannerop/providers/workers.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/operations/components/completationDialogs/hoursCompletetion.dart';
import 'package:provider/provider.dart';

//SIMPLIFICAR: Función principal SIN NAVIGATOR.POP PREMATURO
Future<void> showCompletionDialog({
  required BuildContext context,
  required Operation operation,
  required OperationsProvider provider,
}) async {
  //CAPTURAR NAVIGATOR AL INICIO
  final navigator = Navigator.of(context);

  try {
    final workersProvider =
        Provider.of<WorkersProvider>(context, listen: false);

    if (!context.mounted) {
      debugPrint('Context no montado al inicio');
      return;
    }

    //PROCESAR cada grupo SECUENCIALMENTE
    for (int i = 0; i < operation.groups.length; i++) {
      final group = operation.groups[i];
      ;

      List<Worker> groupWorkers = group.workers
          .map((workerId) => workersProvider.getWorkerById(workerId))
          .where((worker) => worker != null)
          .cast<Worker>()
          .toList();

      //USAR COMPLETER PARA CONTROL PRECISO
      final Completer<bool> groupCompleter = Completer<bool>();

      final completed = await _processGroup(
        context,
        operation,
        groupWorkers,
        group,
        provider,
        groupCompleter,
      );

      if (!completed) {
        debugPrint('Grupo ${group.id} no completado, abortando');
        if (context.mounted) {
          showErrorToast(context,
              'No se pudo completar el grupo ${group.name ?? group.id}');
        }
        return;
      }
    }

    //COMPLETAR operación FINAL
    await _completeOperationFinal(context, operation, provider);

    //CERRAR DIALOGO SOLO AL FINAL
    if (navigator.mounted) {
      navigator.pop();
    }
  } catch (e) {
    debugPrint('💥 Error en showCompletionDialog: $e');
    if (context.mounted) {
      showErrorToast(context, 'Error al procesar la operación: $e');
    }
  }
}

//PROCESAR GRUPO CON COMPLETER
Future<bool> _processGroup(
  BuildContext context,
  Operation operation,
  List<Worker> groupWorkers,
  WorkerGroup group,
  OperationsProvider provider,
  Completer<bool> completer,
) async {
  try {
    final ID_UNIT_HOURS = int.parse(dotenv.get('ID_UNIT_HOURS') ?? '2');
    final ID_UNIT_JORNAL = int.parse(dotenv.get('ID_UNIT_JORNAL') ?? '1');

    if (!context.mounted) {
      debugPrint('Context desmontado antes de procesar grupo');
      return false;
    }

    if (group.idUnitOfMeasure == ID_UNIT_JORNAL ||
        group.idUnitOfMeasure == ID_UNIT_HOURS) {
      //MOSTRAR DIÁLOGO DE HORAS
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return HoursCompletetion(
            group: group,
            onStateChanged: () {
              //CERRAR SOLO EL DIÁLOGO DE HORAS
              Navigator.of(dialogContext).pop();
              //COMPLETAR COMPLETER
              if (!completer.isCompleted) {
                completer.complete(true);
              }
            },
          );
        },
      );

      //ESPERAR RESULTADO CON TIMEOUT
      return await completer.future.timeout(
        Duration(minutes: 5),
        onTimeout: () {
          debugPrint('⏰ Timeout procesando grupo ${group.id}');
          return false;
        },
      );
    } else if (group.idUnitOfMeasure == 4) {
      return await _showSimpleContainerDialog(context);
    } else {
      return await _showSimpleGenericDialog(context, group);
    }
  } catch (e) {
    debugPrint('💥 Error procesando grupo ${group.id}: $e');
    return false;
  }
}

//COMPLETAR OPERACIÓN FINAL
Future<void> _completeOperationFinal(
  BuildContext context,
  Operation operation,
  OperationsProvider provider,
) async {
  try {
    //MOSTRAR LOADER SIN CERRAR CONTEXTO
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loaderContext) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Completando operación...',
                    style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text('Por favor espera',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ],
            ),
          ),
        ),
      ),
    );

    //COMPLETAR operación
    final now = DateTime.now();
    final currentTime = DateFormat('HH:mm').format(now);
    final endTimeToSave =
        operation.endTime?.isNotEmpty == true ? operation.endTime : currentTime;

    final success = await provider.completeOperation(
      operation.id ?? 0,
      operation.endDate ?? now,
      endTimeToSave ?? currentTime,
    );

    //CERRAR LOADER
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop(); // Cerrar loader
    }

    if (success) {
      if (context.mounted) {
        showSuccessToast(context, 'Operación completada exitosamente');
      }
    } else {
      debugPrint('Error al completar operación: ${provider.error}');
      if (context.mounted) {
        showErrorToast(context,
            'Error al completar la operación: ${provider.error ?? "Desconocido"}');
      }
    }
  } catch (e) {
    //CERRAR LOADER EN CASO DE ERROR
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }

    if (context.mounted) {
      showErrorToast(context, 'Error al completar operación: $e');
    }
  }
}

//DIÁLOGOS SIMPLES
Future<bool> _showSimpleContainerDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Completar por Contenedores'),
      content: Text('Funcionalidad por implementar'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text('Completar'),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<bool> _showSimpleGenericDialog(
    BuildContext context, WorkerGroup group) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Completar Grupo'),
      content: Text('¿Completar grupo ${group.name ?? group.id}?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text('Completar'),
        ),
      ],
    ),
  );
  return result ?? false;
}

//RESTO DE FUNCIONES IGUAL...
Future<void> showHoursCompletionDialog(
  BuildContext context,
  Operation assignment,
  List<Worker> workers,
  String groupId,
  OperationsProvider provider,
  Function onStateChanged,
  WorkerGroup group,
) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return HoursCompletetion(
        onStateChanged: () {
          onStateChanged();
          Navigator.pop(dialogContext);
        },
        group: group,
        // onCancel: () {
        //   Navigator.pop(dialogContext);
        //   if (!completer.isCompleted) completer.complete();
        // },
      );
    },
  );
}

Future<void> showTonnageCompletionDialog(
  BuildContext context,
  Operation assignment,
  List<Worker> workers,
  String groupId,
  OperationsProvider provider,
  Function onStateChanged,
  WorkerGroup group,
) async {
  // Implementar diálogo de toneladas
  final Completer<void> completer = Completer<void>();

  // TODO: Implementar diálogo específico para toneladas
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Completar por Toneladas'),
      content: Text('Diálogo para toneladas - Por implementar'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            if (!completer.isCompleted) completer.complete();
          },
          child: Text('Cerrar'),
        ),
      ],
    ),
  );

  return completer.future;
}

Future<void> showContainerCompletionDialog(
  BuildContext context,
  Operation assignment,
  List<Worker> workers,
  String groupId,
  OperationsProvider provider,
  Function onStateChanged,
  WorkerGroup group,
) async {
  // Implementar diálogo de contenedores
  final Completer<void> completer = Completer<void>();

  // TODO: Implementar diálogo específico para contenedores
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Completar por Contenedores'),
      content: Text('Diálogo para contenedores - Por implementar'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            if (!completer.isCompleted) completer.complete();
          },
          child: Text('Cerrar'),
        ),
      ],
    ),
  );

  return completer.future;
}

// Diálogo para confirmar la finalización de un grupo de trabajadores
void showGroupCompletionDialog(
    BuildContext context,
    Operation assignment,
    List<Worker> workers,
    String groupId,
    OperationsProvider provider,
    Function setState) {
  bool isProcessing = false;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  // Formatear fecha y hora para mostrar
  String formattedDate = DateFormat('dd/MM/yyyy').format(selectedDate);
  String formattedTime =
      "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}";

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(groupId == "individual"
                ? 'Completar Trabajadores Individuales'
                : 'Completar Grupo de Trabajadores'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Se marcarán como completadas las tareas de ${workers.length} trabajador(es).',
                    style: TextStyle(color: Color(0xFF718096)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Fecha de finalización',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: isProcessing
                        ? null
                        : () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate:
                                  DateTime.now().subtract(Duration(days: 30)),
                              lastDate: DateTime.now().add(Duration(days: 1)),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                selectedDate = picked;
                                formattedDate = DateFormat('dd/MM/yyyy')
                                    .format(selectedDate);
                              });
                            }
                          },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 18, color: Color(0xFF718096)),
                          SizedBox(width: 8),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          Spacer(),
                          Icon(Icons.arrow_drop_down, color: Color(0xFF718096)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Hora de finalización',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: isProcessing
                        ? null
                        : () async {
                            final TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (picked != null) {
                              setDialogState(() {
                                selectedTime = picked;
                                formattedTime =
                                    "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                              });
                            }
                          },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 18, color: Color(0xFF718096)),
                          SizedBox(width: 8),
                          Text(
                            formattedTime,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          Spacer(),
                          Icon(Icons.arrow_drop_down, color: Color(0xFF718096)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    isProcessing ? null : () => Navigator.pop(dialogContext),
                style: TextButton.styleFrom(
                  foregroundColor:
                      isProcessing ? Color(0xFFCBD5E0) : Color(0xFF718096),
                ),
                child: Text('Cancelar'),
              ),
              NeumorphicButton(
                style: NeumorphicStyle(
                  depth: isProcessing ? 0 : 2,
                  intensity: 0.7,
                  color: isProcessing ? Color(0xFF9AE6B4) : Color(0xFF38A169),
                  boxShape:
                      NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                ),
                onPressed: isProcessing
                    ? null
                    : () async {
                        // Liberar al grupo de trabajadores
                        var workersProvider = Provider.of<WorkersProvider>(
                            context,
                            listen: false);

                        try {
                          // Crear copia de la operación con solo los trabajadores completados
                          Operation completedAssignment = Operation(
                            id: assignment.id,
                            // workers: assignment.workers,
                            area: assignment.area,
                            // task: assignment.task,
                            date: assignment.date,
                            time: assignment.time,
                            supervisor: assignment.supervisor,
                            status: assignment.status,
                            endDate: selectedDate,
                            endTime: formattedTime,
                            zone: assignment.zone,
                            motorship: assignment.motorship,
                            userId: assignment.userId,
                            areaId: assignment.areaId,
                            // taskId: assignment.taskId,
                            clientId: assignment.clientId,
                            inChagers: assignment.inChagers,
                            groups: assignment.groups,
                            id_clientProgramming:
                                assignment.id_clientProgramming,
                          );

                          // Llamar a API para completar operación grupal
                          final success = await provider.completeGroup(
                            completedAssignment,
                            workers,
                            groupId,
                            selectedDate,
                            formattedTime,
                            context,
                          );

                          // Liberar trabajadores
                          // for (var worker in workers) {
                          //   await workersProvider.releaseWorkerObject(
                          //       worker, context);
                          // }
                          Navigator.of(dialogContext).pop();
                          Navigator.of(context).pop();

                          // Forzar actualización del estado global
                          if (success) {
                            setState();
                          }

                          if (context.mounted) {
                            showSuccessToast(
                                context,
                                groupId == "individual"
                                    ? 'Trabajadores individuales completados exitosamente'
                                    : 'Grupo de trabajadores completado exitosamente');
                          }
                        } catch (e) {
                          debugPrint('Error al completar tarea grupal: $e');

                          if (context.mounted) {
                            setDialogState(() {
                              isProcessing = false;
                            });
                            showErrorToast(
                                context, 'Error al completar la tarea: $e');
                          }
                        } finally {
                          // Resetear isProcessing al final del flujo exitoso
                          isProcessing = false;
                        }
                      },
                child: Container(
                  width: 100,
                  height: 36,
                  child: Center(
                    child: isProcessing
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Procesando',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Completar',
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
