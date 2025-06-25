import 'package:flutter/material.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/utils/constants.dart';

class WorkerActionsBar extends StatelessWidget {
  final Worker worker;
  final Color specialtyColor;
  final VoidCallback onClose;
  final VoidCallback onEdit;
  final VoidCallback? onIncapacitate;
  final VoidCallback? onRetire;

  const WorkerActionsBar({
    Key? key,
    required this.worker,
    required this.specialtyColor,
    required this.onClose,
    required this.onEdit,
    this.onIncapacitate,
    this.onRetire,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool canBeIncapacitated =
        worker.status != WorkerStatus.incapacitated &&
            worker.status != WorkerStatus.deactivated &&
            onIncapacitate != null;

    final bool canBeRetired =
        worker.status != WorkerStatus.deactivated && onRetire != null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botón de cerrar
          _buildActionButton(
            icon: Icons.close,
            label: 'Cerrar',
            onPressed: onClose,
            color: Colors.grey.shade700,
          ),

          // Botón de editar
          _buildActionButton(
            icon: Icons.edit,
            label: 'Editar',
            onPressed: onEdit,
            color: specialtyColor,
          ),

          // Botón de incapacitar (si aplica)
          if (canBeIncapacitated)
            _buildActionButton(
              icon: Icons.medical_services_outlined,
              label: 'Incapacitar',
              onPressed: onIncapacitate!,
              color: Colors.purple,
            ),

          // Botón de retirar (si aplica)
          if (canBeRetired)
            _buildActionButton(
              icon: Icons.exit_to_app,
              label: 'Retirar',
              onPressed: onRetire!,
              color: Colors.red.shade700,
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
