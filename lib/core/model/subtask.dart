import 'package:plannerop/core/model/tariff.dart';

class SubTask {
  final String name;
  final String code;
  final int id;
  List<Tariff> tariffs;

  SubTask({
    required this.name,
    required this.code,
    required this.id,
    this.tariffs = const [],
  });

  @override
  String toString() => name;

  // Factory constructor para crear desde JSON
  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      id: json['id'] as int,
      name: json['name'].toString().toUpperCase(),
      code: json['code'].toString().toUpperCase(),
      tariffs: (json['Tariff'] as List)
          .map((tariff) => Tariff.fromJson(tariff))
          .toList(),
    );
  }

  // Método para convertir a JSON
  Map<String, dynamic> toJson(int id) {
    return {
      'id': id,
      'name': name,
      'code': code,
      'Tariff': tariffs.map((tariff) => tariff.toJson()).toList(),
    };
  }
}
