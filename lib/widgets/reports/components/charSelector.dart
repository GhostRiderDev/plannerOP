import 'package:flutter/material.dart';

class ChartSelector extends StatelessWidget {
  final String selectedChart;
  final Function(String) onChartChanged;
  final List<Map<String, dynamic>> chartOptions;

  const ChartSelector({
    Key? key,
    required this.selectedChart,
    required this.onChartChanged,
    required this.chartOptions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              spreadRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: ButtonTheme(
            alignedDropdown: true,
            child: DropdownButton<String>(
              value: selectedChart,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: Color(0xFF4299E1)),
              elevation: 2,
              style: const TextStyle(
                color: Color(0xFF2D3748),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  onChartChanged(newValue);
                }
              },
              items: chartOptions
                  .map<DropdownMenuItem<String>>((Map<String, dynamic> item) {
                return DropdownMenuItem<String>(
                  value: item['title'],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Icon(item['icon'],
                            color: const Color(0xFF4299E1), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item['title'],
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
