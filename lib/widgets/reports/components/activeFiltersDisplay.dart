import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ActiveFiltersDisplay extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String selectedArea;
  final int? selectedZone;
  final String? selectedMotorship;
  final String? selectedStatus;
  final VoidCallback onChangeFilters;

  const ActiveFiltersDisplay({
    Key? key,
    required this.startDate,
    required this.endDate,
    required this.selectedArea,
    this.selectedZone,
    this.selectedMotorship,
    this.selectedStatus,
    required this.onChangeFilters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String dateRange;
    if (_isSameDay(startDate, endDate)) {
      dateRange = DateFormat('dd/MM/yyyy').format(startDate);
    } else {
      dateRange =
          "${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}";
    }

    List<String> activeFilters = [];

    activeFilters.add("Fecha: $dateRange");
    if (selectedArea != 'Todas') activeFilters.add("Área: $selectedArea");
    if (selectedZone != null) activeFilters.add("Zona: $selectedZone");
    if (selectedMotorship != null)
      activeFilters.add("Motonave: $selectedMotorship");
    if (selectedStatus != null) activeFilters.add("Estado: $selectedStatus");

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      color: const Color(0xFFF7FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_alt_outlined,
                  size: 16, color: Color(0xFF718096)),
              const SizedBox(width: 8),
              const Text(
                "Filtros activos:",
                style: TextStyle(
                    color: Color(0xFF4A5568), fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              TextButton(
                onPressed: onChangeFilters,
                child: const Text(
                  "Cambiar filtros",
                  style: TextStyle(
                      color: Color(0xFF3182CE), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: activeFilters
                .map((filter) => Chip(
                      label: Text(filter, style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
