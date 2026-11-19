class Producto {
  int? id;
  String titulo;
  String descripcion;
  double precio;
  int stock;
  String imagenUrl;

  Producto({
    this.id,
    required this.titulo,
    required this.descripcion,
    required this.precio,
    required this.stock,
    required this.imagenUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'precio': precio,
      'stock': stock,
      'imagen_url': imagenUrl,
    };
  }

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'],
      titulo: map['titulo'] ?? '',
      descripcion: map['descripcion'] ?? '',
      precio: (map['precio'] as num?)?.toDouble() ?? 0.0,
      stock: map['stock'] ?? 0,
      imagenUrl: map['imagen_url'] ?? '',
    );
  }
}