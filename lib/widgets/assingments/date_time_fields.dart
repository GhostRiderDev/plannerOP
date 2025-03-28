import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/utils/toast.dart';

class DateField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final Function(String)? onDateChanged; // Añadir esta callback
  final bool isOptional;

  const DateField({
    Key? key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.onDateChanged, // Opcional para notificar cambios
    this.isOptional = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          GestureDetector(
            onTap: () async {
              final DateTime now = DateTime.now();
              final DateTime firstDate = now;
              final DateTime lastDate =
                  DateTime(now.year + 3, now.month, now.day);

              // Intentar usar la fecha actual del campo o usar hoy
              DateTime initialDate;
              try {
                // Verificar que el texto no esté vacío antes de intentar parsearlo
                if (controller.text.isNotEmpty) {
                  initialDate = DateFormat('dd/MM/yyyy').parse(controller.text);
                  // Si la fecha es anterior a hoy, usar hoy
                  if (initialDate.isBefore(firstDate)) {
                    initialDate = firstDate;
                  }
                } else {
                  // Si el campo está vacío, usar la fecha actual
                  initialDate = firstDate;
                }
              } catch (_) {
                initialDate = firstDate;
              }

              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: firstDate,
                lastDate: lastDate,
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.light().copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF3182CE),
                        onPrimary: Colors.white,
                      ),
                      dialogBackgroundColor: Colors.white,
                    ),
                    child: child!,
                  );
                },
              );

              if (picked != null) {
                final formattedDate = DateFormat('dd/MM/yyyy').format(picked);
                controller.text = formattedDate;

                // Notificar que la fecha ha cambiado
                if (onDateChanged != null) {
                  onDateChanged!(formattedDate);

                  // Log para debug
                  debugPrint('Fecha cambiada a: $formattedDate');
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: const Color(0xFF718096)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      controller.text.isEmpty ? hint : controller.text,
                      style: TextStyle(
                        color: controller.text.isEmpty
                            ? const Color(0xFFA0AEC0)
                            : Colors.black,
                      ),
                    ),
                  ),
                  const Icon(Icons.calendar_today, color: Color(0xFF718096)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TimeField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextEditingController? dateController;
  final bool isOptional;
  final bool isEndTime; // Nuevo parámetro para identificar si es hora de fin

  const TimeField({
    Key? key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.dateController,
    this.isOptional = false,
    this.isEndTime = false, // Por defecto, asumimos que es hora de inicio
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint(
        'TimeField build - date: ${dateController?.text}, time: ${controller.text}, isEndTime: $isEndTime');

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
          GestureDetector(
            onTap: () => _selectTime(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: const Color(0xFF718096)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      controller.text.isEmpty ? hint : controller.text,
                      style: TextStyle(
                        color: controller.text.isEmpty
                            ? const Color(0xFFA0AEC0)
                            : Colors.black,
                      ),
                    ),
                  ),
                  const Icon(Icons.access_time, color: Color(0xFF718096)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    try {
      // Determinar la hora inicial para el selector
      TimeOfDay initialTime;
      try {
        if (controller.text.isNotEmpty) {
          final timeParts = controller.text.split(':');
          initialTime = TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          );
        } else {
          initialTime = TimeOfDay.now();
        }
      } catch (e) {
        debugPrint('Error parsing time: $e');
        initialTime = TimeOfDay.now();
      }

      // Verificar si es hoy para establecer restricciones de hora (solo para hora de inicio)
      bool isToday = false;
      TimeOfDay? minimumTime;

      // Solo verificamos restricciones para hora de inicio si tenemos una fecha y no es hora final
      if (!isEndTime &&
          dateController != null &&
          dateController!.text.isNotEmpty) {
        try {
          final selectedDate =
              DateFormat('dd/MM/yyyy').parse(dateController!.text);
          final now = DateTime.now();

          // Verificar si es hoy
          isToday = selectedDate.year == now.year &&
              selectedDate.month == now.month &&
              selectedDate.day == now.day;

          if (isToday) {
            minimumTime = TimeOfDay.now();
            // Añadir log más detallado para depuración
            final period = minimumTime.hour >= 12 ? 'PM' : 'AM';
            final hour12Format = minimumTime.hour > 12
                ? minimumTime.hour - 12
                : minimumTime.hour == 0
                    ? 12
                    : minimumTime.hour;

            debugPrint(
                'Hora mínima: ${minimumTime.hour}:${minimumTime.minute} ($hour12Format:${minimumTime.minute.toString().padLeft(2, '0')} $period)');
          }
        } catch (e) {
          debugPrint('Error al validar fecha: $e');
        }
      }

      // Mostrar el selector de hora
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: initialTime,
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF3182CE),
                onPrimary: Colors.white,
              ),
              dialogBackgroundColor: Colors.white,
            ),
            child: child!,
          );
        },
      );

      // Si el usuario seleccionó una hora
      if (picked != null) {
        // Añadir log detallado para la hora seleccionada
        final pickedPeriod = picked.hour >= 12 ? 'PM' : 'AM';
        final pickedHour12 = picked.hour > 12
            ? picked.hour - 12
            : picked.hour == 0
                ? 12
                : picked.hour;

        debugPrint(
            'Hora seleccionada: ${picked.hour}:${picked.minute} ($pickedHour12:${picked.minute.toString().padLeft(2, '0')} $pickedPeriod)');

        // Comprobación solo si es el día de hoy y es una hora de inicio
        if (!isEndTime && isToday && minimumTime != null) {
          final selectedMinutes = picked.hour * 60 + picked.minute;
          final minimumMinutes = minimumTime.hour * 60 + minimumTime.minute;

          if (selectedMinutes < minimumMinutes) {
            // Mensaje más claro especificando la hora actual
            final formattedMinTime =
                '${minimumTime.hour}:${minimumTime.minute.toString().padLeft(2, '0')}';
            showAlertToast(
                context,
                'No puedes seleccionar ${picked.hour}:${picked.minute.toString().padLeft(2, '0')}, '
                'debe ser posterior a la hora actual ($formattedMinTime)');
            return; // No actualizar el controlador si la hora es inválida
          }
        }

        // Formatear la hora seleccionada
        final hour = picked.hour.toString().padLeft(2, '0');
        final minute = picked.minute.toString().padLeft(2, '0');
        controller.text = '$hour:$minute';

        // Obligar actualización de UI si es necesario
        if (context is StatefulElement) {
          (context.state as State).setState(() {});
        }

        debugPrint('Hora guardada: ${controller.text}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error en selector de hora: $e');
      debugPrint('Stack trace: $stackTrace');

      // Mostrar un error genérico
      showErrorToast(context, 'Error al seleccionar la hora');
    }
  }
}
