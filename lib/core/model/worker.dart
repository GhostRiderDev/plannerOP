class Worker {
  final int id;
  final String name;
  final String area;
  final String phone;
  final String document;
  final DateTime startDate;
  final DateTime? endDate;
  DateTime? incapacityStartDate;
  DateTime? incapacityEndDate;
  DateTime? deactivationDate;
  int idArea;
  final WorkerStatus status;
  final String code;
  final int failures;

  Worker({
    required this.name,
    required this.area,
    required this.phone,
    required this.document,
    required this.status,
    required this.startDate,
    required this.code,
    this.endDate,
    this.incapacityStartDate,
    this.incapacityEndDate,
    this.deactivationDate,
    this.idArea = 0,
    this.failures = 0,
    required this.id,
  });

  void setIncapacityDates(DateTime startDate, DateTime endDate) {
    incapacityStartDate = startDate;
    incapacityEndDate = endDate;
  }

  void setDeactivationDate(DateTime date) {
    deactivationDate = date;
  }

  @override
  String toString() {
    return 'Worker{id: $id, name: $name, area: $area, phone: $phone, document: $document, startDate: $startDate, endDate: $endDate, incapacityStartDate: $incapacityStartDate, incapacityEndDate: $incapacityEndDate, deactivationDate: $deactivationDate, idArea: $idArea, status: $status, code: $code, failures: $failures}';
  }
}

enum WorkerStatus {
  available,
  assigned,
  unavailable,
  deactivated,
  incapacitated,
}
