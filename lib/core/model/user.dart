class User {
  int id;
  String name;
  String dni;
  String phone;
  String cargo;
  String? role;
  int idSite;

  User({
    required this.id,
    required this.name,
    required this.dni,
    required this.phone,
    required this.cargo,
    required this.idSite,
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
      idSite: json['id_site'] ?? 0,
    );
  }

  // toString()
  @override
  String toString() {
    return 'User{id: $id, name: $name, dni: $dni, phone: $phone, cargo: $cargo}';
  }
}
