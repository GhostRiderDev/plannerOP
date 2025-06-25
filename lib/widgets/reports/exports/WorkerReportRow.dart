class WorkerReportRow {
  final int operationId;
  final String status;
  final String area;
  final String client;
  final String supervisors;
  final String startDate;
  final String startTime;
  final String endDate;
  final String endTime;
  final String workedHours;
  final String vessel;
  final String task;
  final String shift;
  final String workerDni;
  final String workerName;

  WorkerReportRow({
    required this.operationId,
    required this.status,
    required this.area,
    required this.client,
    required this.supervisors,
    required this.startDate,
    required this.startTime,
    required this.endDate,
    required this.endTime,
    required this.workedHours,
    required this.vessel,
    required this.task,
    required this.shift,
    required this.workerDni,
    required this.workerName,
  });
}

class GeneralReportRow {
  final int operationId;
  final String status;
  final String area;
  final String client;
  final String supervisors;
  final String startDate;
  final String startTime;
  final String endDate;
  final String endTime;
  final String workedHours;
  final String vessel;
  final String task;
  final int totalWorkers;
  final int totalShifts;

  GeneralReportRow({
    required this.operationId,
    required this.status,
    required this.area,
    required this.client,
    required this.supervisors,
    required this.startDate,
    required this.startTime,
    required this.endDate,
    required this.endTime,
    required this.workedHours,
    required this.vessel,
    required this.task,
    required this.totalWorkers,
    required this.totalShifts,
  });
}

class ReportData {
  final List<WorkerReportRow> workerRows;
  final List<GeneralReportRow> generalRows;
  final String reportTitle;
  final String dateRange;
  final Map<String, int> statistics;

  ReportData({
    required this.workerRows,
    required this.generalRows,
    required this.reportTitle,
    required this.dateRange,
    required this.statistics,
  });
}
