import 'package:plannerop/core/model/user.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/workerGroup.dart';

class Operation {
  int? id;
  // final List<Worker> workers;
  List<Worker> workersFinished = [];
  final List<int> inChagers;
  final String area;
  // final String task;
  final DateTime date;
  final String time;
  final User? supervisor;
  final String? endTime;
  final String status; // 'PENDING', 'INPROGRESS', 'COMPLETED', 'CANCELED'
  final DateTime? endDate;
  final int zone;
  final String? motorship;
  final int userId;
  final int areaId;
  // final int taskId;
  final int clientId;
  final int? id_clientProgramming;
  DateTime? createdAt;
  DateTime? updatedAt;
  List<Worker> deletedWorkers = [];
  List<WorkerGroup> groups = [];

  set endTime(String? endTime) {
    this.endTime = endTime;
  }

  set endDate(DateTime? endDate) {
    this.endDate = endDate;
  }

  Operation({
    this.id,
    required this.inChagers,
    required this.area,
    required this.date,
    required this.time,
    this.endTime,
    required this.zone,
    this.status = 'PENDING',
    this.endDate,
    this.motorship,
    this.supervisor,
    this.deletedWorkers = const [],
    required this.userId,
    required this.areaId,
    required this.clientId,
    this.id_clientProgramming,
    this.createdAt,
    this.updatedAt,
    this.groups = const [],
    this.workersFinished = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'area': area,
      'date': date.toIso8601String(),
      'time': time,
      'status': status,
      'endTime': endTime,
      'endDate': endDate?.toIso8601String(),
      'zone': zone,
      'motorship': motorship,
      'userId': userId,
      'areaId': areaId,
      'clientId': clientId,
      'inChargedIds': inChagers,
      'id_clientProgramming': id_clientProgramming,
    };
  }

  static Operation fromJson(Map<String, dynamic> json, List<Worker> workers) {
    return Operation(
      id: json['id'],
      area: json['jobArea']['name'],
      date: DateTime.parse(json['dateStart']),
      time: json['timeStrat'],
      status: json['status'],
      endTime: json['timeEnd'],
      endDate: json['dateEnd'] != null ? DateTime.parse(json['dateEnd']) : null,
      zone: json['zone'],
      motorship: json['motorship'],
      userId: json['id_user'],
      areaId: json['jobArea']['id'],
      clientId: json['id_client'],
      inChagers: json['inChargedIds'],
      createdAt: DateTime.parse(json['createAt']),
      updatedAt: DateTime.parse(json['updateAt']),
      id_clientProgramming: json['id_clientProgramming'],
    );
  }

  @override
  String toString() {
    return 'Operation{id: $id, area: $area, date: $date, time: $time, status: $status, endTime: $endTime, endDate: $endDate, zone: $zone, motorship: $motorship, userId: $userId, areaId: $areaId, clientId: $clientId}';
  }
}
