import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import '../charts/areaChart.dart';
import '../charts/shipPersonnelChart.dart';
import '../charts/zoneDistributionChart.dart';
import '../charts/workerStatusChart.dart';
import '../charts/hourlyDistributionChart.dart';

class ChartFactory {
  static Widget createChart({
    required String chartType,
    required DateTime startDate,
    required DateTime endDate,
    required String area,
    int? zone,
    String? motorship,
    String? status,
  }) {
    Widget chart;

    switch (chartType) {
      case 'Personal por Buque':
        chart = ShipPersonnelChart(
          startDate: startDate,
          endDate: endDate,
          area: area,
          zone: zone,
          motorship: motorship,
          status: status,
        );
        break;
      case 'Distribución por Áreas':
        chart = AreaDistributionChart(
          startDate: startDate,
          endDate: endDate,
          area: area,
          zone: zone,
          status: status,
          motorship: motorship,
        );
        break;
      case 'Distribución por Zonas':
        chart = ZoneDistributionChart(
          startDate: startDate,
          endDate: endDate,
          area: area,
          zone: zone,
          motorship: motorship,
          status: status,
        );
        break;
      case 'Estado de Trabajadores':
        chart = WorkerStatusChart(
          startDate: startDate,
          endDate: endDate,
          area: area,
        );
        break;
      case 'Distribución de Trabajadores por Horas':
        chart = HourlyDistributionChart(
          startDate: startDate,
          endDate: endDate,
          area: area,
        );
        break;
      default:
        chart = const Center(child: Text('Gráfico no disponible'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Neumorphic(
        style: NeumorphicStyle(
          depth: 3,
          intensity: 0.6,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: chart,
        ),
      ),
    );
  }
}
