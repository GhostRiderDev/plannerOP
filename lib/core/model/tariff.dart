import 'package:plannerop/core/model/costCenter.dart';

class Tariff {
  final int id;
  final String code;

  Tariff({
    required this.id,
    required this.code,
  });

  // Factory constructor para crear desde JSON
  factory Tariff.fromJson(Map<String, dynamic> json) {
    return Tariff(
      id: json['id'] as int,
      code: json['code'].toString().toUpperCase(),
    );
  }

  // Método para convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
    };
  }
}
