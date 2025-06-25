class User {
  int id;
  String name;
  String dni;
  String phone;
  String cargo;
  String? role;

  User({
    required this.id,
    required this.name,
    required this.dni,
    required this.phone,
    required this.cargo,
    this.role,
  });

  static User fromJson(Map<String, dynamic> json) {
    return User(
      cargo: json['occupation'],
      id: json['id'],
      name: json['name'],
      dni: json['dni'],
      phone: json['phone'],
      role: json['role'],
    );
  }

  // toString()
  @override
  String toString() {
    return 'User{id: $id, name: $name, dni: $dni, phone: $phone, cargo: $cargo}';
  }
}
