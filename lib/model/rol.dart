class Rol {
  int? id;
  String rol;

  Rol({this.id, required this.rol});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rol': rol,
    };
  }

  factory Rol.fromMap(Map<String, dynamic> map) {
    return Rol(
      id: map['id'],
      rol: map['rol'],
    );
  }
}