import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';

class ReportSummary extends StatelessWidget {
  final String periodName;
  final DateTime startDate;
  final DateTime endDate;
  final String area;

  const ReportSummary({
    Key? key,
    required this.periodName,
    required this.startDate,
    required this.endDate,
    required this.area,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSummaryCards(),
          const SizedBox(height: 24),
          _buildTopPerformers(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    String dateRangeText;
    if (periodName == 'Personalizado') {
      dateRangeText =
          "${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}";
    } else {
      dateRangeText = periodName;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen de Reportes: $dateRangeText',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          area == 'Todas' ? 'Todas las áreas' : 'Área: $area',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF718096),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Métricas clave',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Operaciones Totales',
                '128',
                Icons.assignment_outlined,
                const Color(0xFF3182CE),
                '+12% vs. periodo anterior',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Operaciones Completadas',
                '97',
                Icons.check_circle_outline,
                const Color(0xFF38A169),
                '+8% vs. periodo anterior',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Tasa de Finalización',
                '76%',
                Icons.trending_up_outlined,
                const Color(0xFF805AD5),
                '+5% vs. periodo anterior',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Tiempo Promedio',
                '4.2 días',
                Icons.timer_outlined,
                const Color(0xFFDD6B20),
                '-0.8 días vs. periodo anterior',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String comparison,
  ) {
    return Neumorphic(
      style: NeumorphicStyle(
        depth: 2,
        intensity: 0.8,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF718096),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              comparison,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4A5568),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPerformers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Trabajadores',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 16),
        Neumorphic(
          style: NeumorphicStyle(
            depth: 2,
            intensity: 0.8,
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
            color: Colors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                _buildTopPerformerItem(
                    'Carlos Méndez', 'Técnico de Mantenimiento', 24, 1),
                const Divider(height: 1),
                _buildTopPerformerItem(
                    'Ana Gutiérrez', 'Supervisora de Calidad', 19, 2),
                const Divider(height: 1),
                _buildTopPerformerItem(
                    'Roberto Sánchez', 'Técnico Eléctrico', 18, 3),
                const Divider(height: 1),
                _buildTopPerformerItem(
                    'Laura Torres', 'Ingeniera Industrial', 15, 4),
                const Divider(height: 1),
                _buildTopPerformerItem(
                    'Miguel Díaz', 'Técnico de Soporte', 12, 5),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopPerformerItem(
      String name, String position, int assignments, int rank) {
    Color rankColor;
    if (rank == 1) {
      rankColor = const Color(0xFFFFD700); // Gold
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // Silver
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32); // Bronze
    } else {
      rankColor = const Color(0xFF718096); // Regular
    }

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: rankColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: rankColor, width: rank <= 3 ? 2 : 1),
        ),
        child: Center(
          child: Text(
            '$rank',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: rankColor,
            ),
          ),
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Color(0xFF2D3748),
        ),
      ),
      subtitle: Text(
        position,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF718096),
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF3182CE).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$assignments tareas',
          style: const TextStyle(
            color: Color(0xFF3182CE),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D3748),
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
