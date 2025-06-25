import 'package:flutter/material.dart';
import 'package:plannerop/core/model/operation.dart';

abstract class ChartData {
  final String name;
  final int value;
  final Color color;
  final double percentage;

  ChartData({
    required this.name,
    required this.value,
    required this.color,
    this.percentage = 0.0,
  });
}

class AreaData extends ChartData {
  final int assignments;
  final String dateRange;

  AreaData({
    required String name,
    required int personnel,
    required Color color,
    this.assignments = 0,
    this.dateRange = '',
    double percentage = 0,
  }) : super(
          name: name,
          value: personnel,
          color: color,
          percentage: percentage,
        );
}

class ZoneData extends ChartData {
  final int totalAssignments;
  final Map<String, int> taskCounts;
  final Map<String, int> statusCounts;
  final int zoneNumber;
  final String dateRange;

  ZoneData({
    required String name,
    required int personnel,
    required Color color,
    this.totalAssignments = 0,
    this.taskCounts = const {},
    this.statusCounts = const {},
    this.zoneNumber = 0,
    this.dateRange = '',
    double percentage = 0,
  }) : super(
          name: name,
          value: personnel,
          color: color,
          percentage: percentage,
        );
}

class ShipData extends ChartData {
  final int totalAssignments;
  final String dateRange;
  final List<Map<String, dynamic>> workers;
  final List<Operation> assignmentList;

  ShipData({
    required String name,
    required int personnel,
    required Color color,
    this.totalAssignments = 0,
    this.dateRange = '',
    this.workers = const [],
    this.assignmentList = const [],
    double percentage = 0,
  }) : super(
          name: name,
          value: personnel,
          color: color,
          percentage: percentage,
        );

  // Getter para mantener compatibilidad
  int get personnel => value;
}

class HourlyDistributionData extends ChartData {
  final String hour;
  final List<WorkerInfo> workers;

  HourlyDistributionData({
    required this.hour,
    required int workerCount,
    required this.workers,
    Color color = const Color(0xFF3182CE),
    double percentage = 0.0,
  }) : super(
          name: hour,
          value: workerCount,
          color: color,
          percentage: percentage,
        );

  // Getter para mantener compatibilidad
  int get workerCount => value;

  factory HourlyDistributionData.fromJson(Map<String, dynamic> json) {
    return HourlyDistributionData(
      hour: json['hour'] ?? '',
      workerCount: (json['workerIds'] as List<dynamic>?)?.length ?? 0,
      workers: [], // Se llenará después con la información completa
    );
  }
}

class WorkerInfo {
  final int id;
  final String name;
  final String dni;

  WorkerInfo({
    required this.id,
    required this.name,
    required this.dni,
  });

  factory WorkerInfo.fromJson(Map<String, dynamic> json) {
    return WorkerInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      dni: json['dni'] ?? '',
    );
  }
}

class HourlyDistributionResponse {
  final String date;
  final List<WorkerInfo> allWorkers;
  final List<HourlyDistributionData> distribution;

  HourlyDistributionResponse({
    required this.date,
    required this.allWorkers,
    required this.distribution,
  });

  factory HourlyDistributionResponse.fromJson(Map<String, dynamic> json) {
    // Crear mapa de trabajadores para búsqueda rápida
    final workersMap = <int, WorkerInfo>{};
    if (json['workers'] != null) {
      for (var workerJson in json['workers'] as List<dynamic>) {
        final worker = WorkerInfo.fromJson(workerJson);
        workersMap[worker.id] = worker;
      }
    }

    // Procesar distribución con colores graduales
    final distributionList = <HourlyDistributionData>[];
    if (json['distribution'] != null) {
      final distData = json['distribution'] as List<dynamic>;

      for (int i = 0; i < distData.length; i++) {
        final distJson = distData[i];
        final workerIds = (distJson['workerIds'] as List<dynamic>?)
                ?.map((id) => id as int)
                .toList() ??
            [];

        final workers = workerIds
            .map((id) => workersMap[id])
            .where((worker) => worker != null)
            .cast<WorkerInfo>()
            .toList();

        // Generar color basado en la intensidad de trabajadores
        final intensity = workerIds.length.toDouble();
        final maxIntensity = distData
            .map((d) => (d['workerIds'] as List?)?.length ?? 0)
            .reduce((a, b) => a > b ? a : b)
            .toDouble();

        final colorIntensity =
            maxIntensity > 0 ? intensity / maxIntensity : 0.0;
        final color = Color.lerp(
              const Color(0xFF63B3ED), // Azul claro para pocos trabajadores
              const Color(0xFF2B6CB0), // Azul oscuro para muchos trabajadores
              colorIntensity,
            ) ??
            const Color(0xFF3182CE);

        distributionList.add(HourlyDistributionData(
          hour: distJson['hour'] ?? '',
          workerCount: workerIds.length,
          workers: workers,
          color: color,
          percentage: maxIntensity > 0 ? (intensity / maxIntensity) * 100 : 0,
        ));
      }
    }

    return HourlyDistributionResponse(
      date: json['date'] ?? '',
      allWorkers: workersMap.values.toList(),
      distribution: distributionList,
    );
  }
}
