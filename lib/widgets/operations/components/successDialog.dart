import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/core/model/worker.dart';

void showAssignmentSuccessDialog({
  required BuildContext context,
  required List<Worker> selectedWorkers,
  required String startDateText,
  required String startTimeText,
  required String taskText,
  required String zoneText,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF38A169),
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                '¡Operación creada exitosamente!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'La operación para ${selectedWorkers.length} trabajador${selectedWorkers.length > 1 ? 'es' : ''} ha sido programada para el $startDateText a las $startTimeText.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF718096),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tarea: $taskText\nÁrea: $zoneText',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF718096),
                ),
              ),
              if (selectedWorkers.length <= 3) ...[
                const SizedBox(height: 8),
                Text(
                  'Trabajadores: ${selectedWorkers.map((w) => w.name).join(', ')}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF718096),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              NeumorphicButton(
                style: NeumorphicStyle(
                  depth: 2,
                  intensity: 0.6,
                  color: const Color(0xFF3182CE),
                  boxShape:
                      NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Aceptar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
