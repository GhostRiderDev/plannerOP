import 'package:flutter/material.dart';

enum WorkerFilter { all, available, assigned, disabled, retired, faults }

class WorkerStats extends StatelessWidget {
  final int totalWorkers;
  final int assignedWorkers;
  final int disabledWorkers;
  final int retiredWorkers;
  final WorkerFilter currentFilter;
  final Function(WorkerFilter) onFilterChanged;

  const WorkerStats({
    Key? key,
    required this.totalWorkers,
    required this.assignedWorkers,
    required this.disabledWorkers,
    required this.retiredWorkers,
    required this.currentFilter,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final availableWorkers = totalWorkers - assignedWorkers;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildTouchableStatCard(
            title: 'Total',
            value: '$totalWorkers',
            icon: Icons.people_alt,
            color: const Color(0xFF4299E1),
            lightColor: const Color(0xFFEBF8FF),
            isSelected: currentFilter == WorkerFilter.all,
            onTap: () => onFilterChanged(WorkerFilter.all),
          ),
          const SizedBox(width: 12),
          _buildTouchableStatCard(
            title: 'Disponibles',
            value: '$availableWorkers',
            icon: Icons.check_circle,
            color: const Color(0xFF38A169),
            lightColor: const Color(0xFFF0FFF4),
            isSelected: currentFilter == WorkerFilter.available,
            onTap: () => onFilterChanged(WorkerFilter.available),
          ),
          const SizedBox(width: 12),
          _buildTouchableStatCard(
            title: 'Asignados',
            value: '$assignedWorkers',
            icon: Icons.assignment_ind,
            color: const Color(0xFFED8936),
            lightColor: const Color(0xFFFFFAF0),
            isSelected: currentFilter == WorkerFilter.assigned,
            onTap: () => onFilterChanged(WorkerFilter.assigned),
          ),
          const SizedBox(width: 12),
          _buildTouchableStatCard(
            title: 'Incapacitados',
            value: '$disabledWorkers',
            icon: Icons.block,
            color: const Color(0xFFE53E3E),
            lightColor: const Color(0xFFFEE2E2),
            isSelected: currentFilter == WorkerFilter.disabled,
            onTap: () => onFilterChanged(WorkerFilter.disabled),
          ),
          const SizedBox(width: 12),
          _buildTouchableStatCard(
            title: 'Retirados',
            value: '$retiredWorkers',
            icon: Icons.person_remove,
            color: const Color(0xFF718096),
            lightColor: const Color(0xFFE2E8F0),
            isSelected: currentFilter == WorkerFilter.retired,
            onTap: () => onFilterChanged(WorkerFilter.retired),
          ),
        ],
      ),
    );
  }

  Widget _buildTouchableStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color lightColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : lightColor,
            borderRadius: BorderRadius.circular(15),
            border: isSelected ? Border.all(color: color, width: 2) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.3)
                      : color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
