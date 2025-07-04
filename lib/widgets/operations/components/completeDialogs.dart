import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/store/operations.dart';
import 'package:plannerop/store/workers.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:provider/provider.dart';

// Dialogo para confirmar la finalización de una operación
void showCompletionDialog({
  required BuildContext context,
  required Operation assignment,
  required OperationsProvider provider,
}) {
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
            title: const Text('Completar operación'),
            content: const Text(
              '¿Estás seguro de que deseas marcar esta operación como completada?',
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
                child: const Text('Cancelar'),
              ),
              NeumorphicButton(
                style: NeumorphicStyle(
                  depth: isProcessing ? 0 : 2,
                  intensity: 0.7,
                  color: isProcessing
                      ? const Color(0xFF9AE6B4)
                      : const Color(0xFF38A169),
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
                          final now = DateTime.now();
                          final currentTime = DateFormat('HH:mm').format(now);

                          var endTimeToSave =
                              assignment.endTime?.isNotEmpty == true
                                  ? assignment.endTime
                                  : currentTime;

                          endTimeToSave ??= currentTime;

                          final success = await provider.completeOperation(
                              assignment.id ?? 0,
                              assignment.endDate ?? now,
                              endTimeToSave,
                              context);

                          if (success) {
                            // final workersProvider =
                            //     Provider.of<WorkersProvider>(context,
                            //         listen: false);
                            // for (var worker in assignment.workers) {
                            //   workersProvider.releaseWorkerObject(
                            //       worker, context);
                            // }

                            Navigator.pop(dialogContext);
                            showSuccessToast(
                                context, 'Operación completada exitosamente');
                          } else {
                            setDialogState(() {
                              isProcessing = false;
                            });
                            showErrorToast(context,
                                'Error al completar la operación: ${provider.error ?? "Desconocido"}');
                          }
                        } catch (e) {
                          debugPrint('Error al completar operación: $e');
                          if (context.mounted) {
                            setDialogState(() {
                              isProcessing = false;
                            });
                            showErrorToast(
                                context, 'Error al completar operación: $e');
                          }
                        }
                      },
                child: Container(
                  width: 100,
                  height: 36,
                  child: Center(
                    child: isProcessing
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
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
                        : const Text(
                            'Confirmar',
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

// Diálogo para confirmar la finalización de un único trabajador
void showIndividualCompletionDialog(BuildContext context, Operation assignment,
    Worker worker, OperationsProvider provider, WorkerGroup group) {
  // TODO ENVIAR EL TRABAJADOR COMO PARAMETRO Y SU RESPECTIVO GRUPO
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
            title: Text('Completar Tarea de Trabajador'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: Color(0xFF718096), fontSize: 14),
                      children: [
                        TextSpan(
                            text: 'Se marcará como completada la tarea de '),
                        TextSpan(
                          text: worker.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ],
                    ),
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
                        setDialogState(() {
                          isProcessing = true;
                        });

                        try {
                          // Liberar al trabajador individual y marcarlo como completado
                          final workersProvider = Provider.of<WorkersProvider>(
                              context,
                              listen: false);

                          // Crear copia de la operación con solo el trabajador completado
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
                            groups: assignment
                                .groups, // Mantener los grupos actuales
                            id_clientProgramming:
                                assignment.id_clientProgramming,
                          );

                          // Llamar a API para completar operación individual
                          final success = await provider.completeGroup(
                            completedAssignment,
                            [worker],
                            "worker_${worker.id}",
                            selectedDate,
                            formattedTime,
                            context,
                          );

                          // Liberar trabajador solo si la operación tuvo éxito
                          if (success) {
                            // await workersProvider.releaseWorkerObject(
                            //     worker, context);

                            // IMPORTANTE: No modificar directamente la lista de workers
                            // Esto evita problemas con los grupos
                          }

                          Navigator.of(dialogContext).pop();

                          // Cerrar el diálogo de detalles completo para forzar reconstrucción
                          Navigator.of(context).pop();

                          // Mostrar mensaje de éxito
                          if (success) {
                            showSuccessToast(context,
                                'Tarea completada exitosamente para ${worker.name}');
                          }
                        } catch (e) {
                          debugPrint('Error al completar tarea individual: $e');

                          if (context.mounted) {
                            setDialogState(() {
                              isProcessing = false;
                            });
                            showErrorToast(
                                context, 'Error al completar la tarea: $e');
                          }
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
