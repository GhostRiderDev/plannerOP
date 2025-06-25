import 'package:flutter/material.dart';
import './chartData.dart';

class ChartLegend extends StatelessWidget {
  final List<ChartData> data;
  final int selectedIndex;
  final Function(int) onItemTap;
  final bool horizontal;
  final String valueLabel;
  final bool showPercentage;

  const ChartLegend({
    Key? key,
    required this.data,
    required this.selectedIndex,
    required this.onItemTap,
    this.horizontal = true,
    this.valueLabel = 'items',
    this.showPercentage = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (horizontal) {
      return _buildHorizontalLegend();
    } else {
      return _buildVerticalLegend();
    }
  }

  Widget _buildHorizontalLegend() {
    return Container(
      // Quitar la altura fija y dejar que se ajuste al contenido
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 4), // Reducir padding vertical
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize:
              MainAxisSize.min, // Importante para que se ajuste al contenido
          children: data.asMap().entries.map((entry) {
            return _buildLegendItem(entry.key);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildVerticalLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 4, // Reducido de 6 a 4
        children: data.asMap().entries.map((entry) {
          return _buildLegendItem(entry.key);
        }).toList(),
      ),
    );
  }

  Widget _buildLegendItem(int index) {
    final item = data[index];
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        if (isSelected) {
          onItemTap(-1);
        } else {
          onItemTap(index);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3), // Reducido margen
        padding: const EdgeInsets.symmetric(
            horizontal: 6, vertical: 3), // Reducido padding vertical
        constraints: const BoxConstraints(
          minHeight: 32, // Altura mínima fija
          maxHeight: 40, // Altura máxima para evitar que crezca demasiado
        ),
        decoration: BoxDecoration(
          color: isSelected ? item.color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6), // Reducido el radio
          border: Border.all(
            color: isSelected ? item.color : item.color.withOpacity(0.6),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Fila principal con indicador y texto
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, // Círculo aún más pequeño
                  height: 6,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  _truncateName(item.name),
                  style: TextStyle(
                    fontSize: 10, // Fuente más pequeña
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? item.color : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _truncateName(String name) {
    return name.length > 14 ? '${name.substring(0, 5)}...' : name; // Más corto
  }
}
