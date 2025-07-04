import 'package:flutter/material.dart';

class ChartConstants {
  static const List<Map<String, dynamic>> chartOptions = [
    {'title': 'Distribución por Áreas', 'icon': Icons.pie_chart},
    {
      'title': 'Personal por Buque',
      'icon': Icons.directions_boat_filled_outlined
    },
    {
      'title': 'Distribución por Zonas',
      'icon': Icons.pie_chart_outline_rounded
    },
    {'title': 'Estado de Trabajadores', 'icon': Icons.people_outline_rounded},
    {
      'title': 'Distribución de Trabajadores por Horas',
      'icon': Icons.trending_up_rounded
    },
  ];
}
