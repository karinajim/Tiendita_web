class Usuario {
  int? id;
  String nombre;
  String? desc;
  String pass;
  String correo;
  int roleId;
  String? tokenRecuperacion;
  String? tokenExpiracion;
  String? codigoVerificacion;
  String? codigoExpiracion;
  String? createdAt;
  double? latitud;
  double? longitud;

  Usuario({
    this.id,
    required this.nombre,
    this.desc,
    required this.pass,
    required this.correo,
    required this.roleId,
    this.tokenRecuperacion,
    this.tokenExpiracion,
    this.codigoVerificacion,
    this.codigoExpiracion,
    this.createdAt,
    this.latitud,
    this.longitud,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'nombre': nombre,
      'desc': desc,
      'pass': pass,
      'correo': correo,
      'role_id': roleId,
      'token_recuperacion': tokenRecuperacion,
      'token_expiracion': tokenExpiracion,
      'codigo_verificacion': codigoVerificacion,
      'codigo_expiracion': codigoExpiracion,
      'latitud': latitud,
      'longitud': longitud,
    };

    if (createdAt != null) {
      map['createdAT'] = createdAt;
    }

    return map;
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'],
      nombre: map['nombre'],
      desc: map['desc'],
      pass: map['pass'],
      correo: map['correo'],
      roleId: map['role_id'],
      tokenRecuperacion: map['token_recuperacion'],
      tokenExpiracion: map['token_expiracion'],
      codigoVerificacion: map['codigo_verificacion'],
      codigoExpiracion: map['codigo_expiracion'],
      createdAt: map['createdAT'],
      latitud: (map['latitud'] as num?)?.toDouble(),
      longitud: (map['longitud'] as num?)?.toDouble(),
    );
  }
}