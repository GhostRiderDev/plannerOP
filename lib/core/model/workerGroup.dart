import 'package:plannerop/core/model/worker.dart';

class WorkerGroup {
  final String? startTime;
  final String? endTime;
  final String? startDate;
  final String? endDate;
  final List<int> workers;
  List<Worker>? workersData;
  final int serviceId;
  final String name;
  final String? id;
  final String serviceName;

  WorkerGroup(
      {this.startTime,
      this.endTime,
      this.startDate,
      this.endDate,
      this.workersData,
      required this.workers,
      required this.name,
      required this.id,
      required this.serviceId,
      required this.serviceName});

  String toJson() {
    return '''
    {
      "startTime": "$startTime",
      "endTime": "$endTime",
      "startDate": "$startDate",
      "endDate": "$endDate",
      "workers": ${workers.join(',')},
      "serviceId": $serviceId,
      "name": "$name",
      "id": "$id",
      "serviceName": "$serviceName"
    }
    ''';
  }
}
