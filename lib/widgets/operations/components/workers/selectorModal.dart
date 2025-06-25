// Modal a pantalla completa para mostrar las programaciones
import 'package:flutter/material.dart';
import 'package:plannerop/core/model/programming.dart';

class ProgrammingSelectionModal extends StatelessWidget {
  final String startDate;
  final List<Programming> programmings;
  final List<Programming> selectableProgrammings;
  final List<Programming> nonSelectableProgrammings;
  final Programming? selectedProgramming;
  final bool isLoading;
  final Function(Programming) onProgrammingSelected;
  final VoidCallback onRefresh;
  final Color Function(String) getStatusColor;
  final String Function(String) getStatusText;

  const ProgrammingSelectionModal({
    Key? key,
    required this.startDate,
    required this.programmings,
    required this.selectableProgrammings,
    required this.nonSelectableProgrammings,
    required this.selectedProgramming,
    required this.isLoading,
    required this.onProgrammingSelected,
    required this.onRefresh,
    required this.getStatusColor,
    required this.getStatusText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Seleccionar Programación',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Lista de programaciones
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Programaciones disponibles (UNASSIGNED)
                if (selectableProgrammings.isNotEmpty) ...[
                  const Text(
                    'Disponibles para asignar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...selectableProgrammings.map((programming) =>
                      _buildProgrammingItem(programming, true)),
                ],

                // Programaciones no disponibles (ASSIGNED y COMPLETED)
                if (nonSelectableProgrammings.isNotEmpty) ...[
                  if (selectableProgrammings.isNotEmpty)
                    const SizedBox(height: 24),
                  const Text(
                    'No disponibles',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF718096),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...nonSelectableProgrammings.map((programming) =>
                      _buildProgrammingItem(programming, false)),
                ],

                if (programmings.isEmpty && !isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No hay programaciones disponibles',
                        style: TextStyle(
                          color: Color(0xFF718096),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgrammingItem(Programming programming, bool isSelectable) {
    final isSelected = selectedProgramming?.id == programming.id;
    final statusColor = getStatusColor(programming.status);

    return GestureDetector(
      onTap: isSelectable ? () => onProgrammingSelected(programming) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? statusColor.withOpacity(0.1)
              : (isSelectable ? Colors.white : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? statusColor
                : (isSelectable
                    ? const Color(0xFFE2E8F0)
                    : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Opacity(
          opacity: isSelectable ? 1.0 : 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      programming.service,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isSelectable
                            ? const Color(0xFF2D3748)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      getStatusText(programming.status),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              // ✅ AGREGAR INFORMACIÓN DEL CLIENTE
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.business,
                    size: 12,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      programming.client,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    programming.timeStart,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.location_on_outlined,
                    size: 12,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      programming.ubication,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (!isSelectable)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Esta programación no está disponible para nuevas asignaciones',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
