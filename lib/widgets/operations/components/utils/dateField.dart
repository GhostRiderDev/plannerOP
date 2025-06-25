import 'package:flutter/material.dart';

class DateField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final Function(String) onDateChanged; // Añadir esta callback
  final bool isOptional;
  final bool locked;
  final String? lockedMessage;

  const DateField({
    Key? key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.onDateChanged,
    this.isOptional = false,
    this.locked = false,
    this.lockedMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF4A5568),
                  ),
                ),
              ),
              if (locked) // Mostrar un indicador de bloqueo
                Tooltip(
                  message: lockedMessage ?? 'Este campo no se puede modificar',
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
            onTap: locked
                ? null // Deshabilitar si está bloqueado
                : () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: controller.text.isNotEmpty
                          ? _parseDate(controller.text)
                          : DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (pickedDate != null) {
                      final formattedDate =
                          '${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}';
                      controller.text = formattedDate;
                      onDateChanged(formattedDate);
                    }
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: locked
                      ? const Color(0xFFEDF2F7)
                      : const Color(0xFFE2E8F0),
                ),
                borderRadius: BorderRadius.circular(8),
                color: locked
                    ? const Color(
                        0xFFF7FAFC) // Color más claro si está bloqueado
                    : Colors.white,
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: const Color(0xFF718096)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      controller.text.isNotEmpty ? controller.text : hint,
                      style: TextStyle(
                        color: controller.text.isNotEmpty
                            ? Colors.black
                            : const Color(0xFFA0AEC0),
                      ),
                    ),
                  ),
                  if (!locked) // Solo mostrar el icono del calendario si no está bloqueado
                    const Icon(Icons.arrow_drop_down, color: Color(0xFF718096)),
                ],
              ),
            ),
          ),
          // Mensaje opcional de validación
          if (locked && lockedMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                lockedMessage!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFE53E3E),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  DateTime _parseDate(String dateStr) {
    final parts = dateStr.split('/');
    return DateTime(
        int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
  }
}
