import 'package:flutter/material.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/utils/toast.dart';

Widget buildWorkerItem(
  Worker worker,
  BuildContext context, {
  bool isDeleted = false,
  bool? alimentacionEntregada, // Añadir parámetro opcional
  Function(bool)? onAlimentacionChanged, // Callback para notificar cambios
  bool? isFinished = false, // Añadir parámetro opcional
}) {
  // Usar el valor proporcionado o defaultear a false
  final bool _alimentacionEntregada = alimentacionEntregada ?? false;

  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDeleted ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isDeleted ? Colors.red.shade100 : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Avatar del trabajador
          CircleAvatar(
            backgroundColor: Colors
                .primaries[worker.name.hashCode % Colors.primaries.length],
            radius: 16,
            child: Text(
              worker.name.isNotEmpty ? worker.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Información del trabajador
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  worker.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF2D3748),
                  ),
                ),
                Text(
                  worker.area,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),

          if (!(isFinished ?? false))
            TextButton.icon(
              onPressed: () {
                // Notificar cambio si hay callback
                if (onAlimentacionChanged != null) {
                  onAlimentacionChanged(!_alimentacionEntregada);
                  showSuccessToast(context,
                      "Alimentación ${_alimentacionEntregada ? 'no entregada' : 'entregada'}");
                }
              },
              icon: Icon(
                _alimentacionEntregada
                    ? Icons.restaurant
                    : Icons.restaurant_outlined,
                color: _alimentacionEntregada ? Colors.green : Colors.grey,
                size: 18,
              ),
              label: Text(
                _alimentacionEntregada ? 'Entregada' : 'Pendiente',
                style: TextStyle(
                  color:
                      _alimentacionEntregada ? Colors.green : Colors.grey[700],
                  fontSize: 12,
                  fontWeight: _alimentacionEntregada
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: _alimentacionEntregada
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.05),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _alimentacionEntregada
                        ? Colors.green
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            )
        ],
      ),
    ),
  );
}
