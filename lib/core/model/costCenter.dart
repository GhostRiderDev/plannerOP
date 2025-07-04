class Costcenter {
  final int id;
  final String code;
  final String name;

  Costcenter({
    required this.id,
    required this.code,
    required this.name,
  });

  @override
  String toString() => name;
  // Factory constructor to create from JSON
  factory Costcenter.fromJson(Map<String, dynamic> json) {
    return Costcenter(
      id: json['id'] as int,
      code: json['code'].toString().toUpperCase(),
      name: json['name'].toString().toUpperCase(),
    );
  }

  // Method to convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
    };
  }
}
