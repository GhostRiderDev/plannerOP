import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/utils/toast.dart';

class TimeField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextEditingController? dateController;
  final bool isOptional;
  final bool isEndTime;
  final bool locked;
  final String? lockedMessage;

  const TimeField({
    Key? key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.dateController,
    this.isOptional = false,
    this.isEndTime = false,
    this.locked = false,
    this.lockedMessage,
  }) : super(key: key);

  @override
  State<TimeField> createState() => _TimeFieldState();
}

class _TimeFieldState extends State<TimeField> {
  @override
  void initState() {
    // debugPrint("Valor del campo: ${widget.controller.text}");
    super.initState();
    // Añadir un listener al controller para detectar cambios y forzar rebuild
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    // Remover el listener al destruir el widget
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {
        // Forzar rebuild cuando cambia el valor del controller
        debugPrint(
            'TimeField controller actualizado: ${widget.controller.text}');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar para debugging
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF4A5568),
                  ),
                ),
              ),
              if (widget.locked) // Mostrar un indicador de bloqueo
                Tooltip(
                  message: widget.lockedMessage ??
                      'Este campo no se puede modificar',
                  child: const Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: Color(0xFFE53E3E),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: widget.locked ||
                    (widget.dateController != null &&
                        widget.dateController!.text.isEmpty)
                ? null // Deshabilitar si está bloqueado o no hay fecha seleccionada
                : () async {
                    await _selectTime(context);
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                    color: widget.locked
                        ? const Color(0xFFEDF2F7)
                        : const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(8),
                color: widget.locked
                    ? const Color(
                        0xFFF7FAFC) // Color más claro si está bloqueado
                    : Colors.white,
              ),
              child: Row(
                children: [
                  Icon(widget.icon, size: 20, color: const Color(0xFF718096)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.controller.text.isEmpty
                          ? widget.hint
                          : widget.controller.text,
                      style: TextStyle(
                        color: widget.controller.text.isEmpty
                            ? const Color(0xFFA0AEC0)
                            : Colors.black,
                      ),
                    ),
                  ),
                  if (!widget
                      .locked) // Solo mostrar el icono del reloj si no está bloqueado
                    const Icon(Icons.arrow_drop_down, color: Color(0xFF718096)),
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
        if (widget.controller.text.isNotEmpty) {
          final timeParts = widget.controller.text.split(':');
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
      if (!widget.isEndTime &&
          widget.dateController != null &&
          widget.dateController!.text.isNotEmpty) {
        try {
          final selectedDate =
              DateFormat('dd/MM/yyyy').parse(widget.dateController!.text);
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
        if (!widget.isEndTime && isToday && minimumTime != null) {
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
        widget.controller.text = '$hour:$minute';

        // Obligar actualización de UI si es necesario
        if (context is StatefulElement) {
          (context.state).setState(() {});
        }

        debugPrint('Hora guardada: ${widget.controller.text}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error en selector de hora: $e');
      debugPrint('Stack trace: $stackTrace');

      // Mostrar un error genérico
      showErrorToast(context, 'Error al seleccionar la hora');
    }
  }
}
