class ProductoXML {
  final String servicio;
  final String producto;
  final int idServicio;
  final int idProducto;
  final int idCatTipoServicio;
  final int tipoFront;
  final bool hasDigitoVerificador;
  final double precio;
  final bool showAyuda;
  final String tipoReferencia;
  final String legend;

  ProductoXML({
    required this.servicio,
    required this.producto,
    required this.idServicio,
    required this.idProducto,
    required this.idCatTipoServicio,
    required this.tipoFront,
    required this.hasDigitoVerificador,
    required this.precio,
    required this.showAyuda,
    required this.tipoReferencia,
    required this.legend,
  });

  Map<String, dynamic> toMap() {
    return {
      'servicio': servicio,
      'producto': producto,
      'id_servicio': idServicio,
      'id_producto': idProducto,
      'id_cat_tipo_servicio': idCatTipoServicio,
      'tipo_front': tipoFront,
      'has_digito_verificador': hasDigitoVerificador ? 1 : 0,
      'precio': precio,
      'show_ayuda': showAyuda ? 1 : 0,
      'tipo_referencia': tipoReferencia,
      'legend': legend,
    };
  }

  factory ProductoXML.fromMap(Map<String, dynamic> map) {
    return ProductoXML(
      servicio: map['servicio'] ?? '',
      producto: map['producto'] ?? '',
      idServicio: map['id_servicio'] ?? 0,
      idProducto: map['id_producto'] ?? 0,
      idCatTipoServicio: map['id_cat_tipo_servicio'] ?? 0,
      tipoFront: map['tipo_front'] ?? 0,
      hasDigitoVerificador: (map['has_digito_verificador'] ?? 0) == 1,
      precio: (map['precio'] as num?)?.toDouble() ?? 0.0,
      showAyuda: (map['show_ayuda'] ?? 0) == 1,
      tipoReferencia: map['tipo_referencia'] ?? '',
      legend: map['legend'] ?? '',
    );
  }
}