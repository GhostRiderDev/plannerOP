class Programming {
  int? id;
  String service_request;
  String service;
  String dateStart;
  String timeStart;
  String ubication;
  String client;
  String status;
  int? id_operation;
  int? id_user;

  Programming({
    this.id,
    required this.service_request,
    required this.service,
    required this.dateStart,
    required this.timeStart,
    required this.ubication,
    required this.client,
    required this.status,
    this.id_operation,
    this.id_user,
  });

  factory Programming.fromJson(Map<String, dynamic> json) {
    return Programming(
      id: json['id'],
      service_request: json['service_request'],
      service: json['service'],
      dateStart: json['dateStart'],
      timeStart: json['timeStart'],
      ubication: json['ubication'],
      client: json['client'],
      status: json['status'],
      id_operation: json['id_operation'],
      id_user: json['id_user'],
    );
  }
}
