import 'package:flutter/material.dart';
import './chartData.dart';

class ChartCenterInfo extends StatelessWidget {
  final List<ChartData> data;
  final int selectedIndex;
  final String totalLabel;
  final String selectedLabel;

  const ChartCenterInfo({
    Key? key,
    required this.data,
    required this.selectedIndex,
    this.totalLabel = 'Total',
    this.selectedLabel = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = data.fold<int>(0, (sum, item) => sum + item.value);
    final isSelected = selectedIndex != -1 && selectedIndex < data.length;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!isSelected) ...[
            Text(
              '$total',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              totalLabel,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ] else ...[
            Text(
              '${data[selectedIndex].value}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: data[selectedIndex].color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${data[selectedIndex].percentage.round()}%',
              style: TextStyle(
                fontSize: 12,
                color: data[selectedIndex].color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
