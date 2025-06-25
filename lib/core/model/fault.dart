import 'package:plannerop/core/model/worker.dart';

class Fault {
  int id;
  final String description;
  final FaultType type;
  final Worker worker;
  final DateTime createdAt;

  Fault(
      {required this.description,
      required this.type,
      this.id = 0,
      required this.worker,
      required this.createdAt});
}

enum FaultType {
  INASSISTANCE,
  IRRESPECTFUL,
  ABANDONMENT,
}
