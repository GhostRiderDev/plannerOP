import 'package:flutter/material.dart';
import 'package:plannerop/widgets/workers/workerFilter.dart';
import 'package:plannerop/store/faults.dart';
import 'package:provider/provider.dart';

class WorkerStatsCards extends StatelessWidget {
  final int totalWorkers;
  final int assignedWorkers;
  final int disabledWorkers;
  final int retiredWorkers;
  final WorkerFilter currentFilter;
  final Function(WorkerFilter) onFilterChanged;

  const WorkerStatsCards({
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
    final availableWorkers = totalWorkers - assignedWorkers - disabledWorkers;

    final faultsProvider = Provider.of<FaultsProvider>(context);

    return Column(
      children: [
        // Cards de filtrado
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatCard(
                  title: 'Total',
                  value: '$totalWorkers',
                  icon: Icons.people_alt,
                  color: const Color(0xFF4299E1),
                  isSelected: currentFilter == WorkerFilter.all,
                  onTap: () => onFilterChanged(WorkerFilter.all),
                ),
                _buildStatCard(
                  title: 'Disponibles',
                  value: '$availableWorkers',
                  icon: Icons.check_circle,
                  color: const Color(0xFF38A169),
                  isSelected: currentFilter == WorkerFilter.available,
                  onTap: () => onFilterChanged(WorkerFilter.available),
                ),
                _buildStatCard(
                  title: 'Asignados',
                  value: '$assignedWorkers',
                  icon: Icons.assignment_ind,
                  color: const Color(0xFFED8936),
                  isSelected: currentFilter == WorkerFilter.assigned,
                  onTap: () => onFilterChanged(WorkerFilter.assigned),
                ),
                _buildStatCard(
                  title: 'Incapacitados',
                  value: '$disabledWorkers',
                  icon: Icons.medical_services_outlined,
                  color: const Color(0xFF805AD5),
                  isSelected: currentFilter == WorkerFilter.disabled,
                  onTap: () => onFilterChanged(WorkerFilter.disabled),
                ),
                _buildStatCard(
                  title: 'Retirados',
                  value: '$retiredWorkers',
                  icon: Icons.exit_to_app,
                  color: const Color(0xFF718096),
                  isSelected: currentFilter == WorkerFilter.retired,
                  onTap: () => onFilterChanged(WorkerFilter.retired),
                ),
                _buildStatCard(
                  title: 'Novedades',
                  value: '${faultsProvider.faults.length}',
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFF56565),
                  isSelected: currentFilter == WorkerFilter.faults,
                  onTap: () => onFilterChanged(WorkerFilter.faults),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    try {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 120,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.15) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: color, width: 2)
                    : Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Erorsisimo: $e');
      return Container();
    }
  }
}
