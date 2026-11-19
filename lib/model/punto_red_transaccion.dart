class PuntoRedTransaccion {
  final String idTx;
  final String numAutorizacion;
  final double saldo;
  final double comision;
  final double monto;
  final String fecha;
  final String mensaje;
  final String codigoMensaje;
  final String pin;
  final String legend;
  final Map<String, String> raw;

  PuntoRedTransaccion({
    required this.idTx,
    required this.numAutorizacion,
    required this.saldo,
    required this.comision,
    required this.monto,
    required this.fecha,
    required this.mensaje,
    required this.codigoMensaje,
    this.pin = '',
    this.legend = '',
    required this.raw,
  });

  bool get exitosa {
    final c = codigoMensaje.trim();
    return c == '00' || c == '01' || c == '06' || (idTx.isNotEmpty && idTx != '-1' && mensaje.isEmpty);
  }

  factory PuntoRedTransaccion.fromMap(Map<String, String> m) {
    double d(String k) => double.tryParse(m[k] ?? '') ?? 0.0;
    return PuntoRedTransaccion(
      idTx: m['ID_TX'] ?? '',
      numAutorizacion: m['NUM_AUTORIZACION'] ?? '',
      saldo: d('SALDO'),
      comision: d('COMISION'),
      monto: d('MONTO'),
      fecha: m['FECHA'] ?? '',
      mensaje: m['TEXTO'] ?? m['MENSAJE'] ?? '',
      codigoMensaje: m['CODIGO'] ?? m['CODIGO_MENSAJE'] ?? '',
      pin: m['PIN'] ?? '',
      legend: m['legend'] ?? m['LEYENDA'] ?? '',
      raw: m,
    );
  }

  String get montoFormateado => '\$${monto.toStringAsFixed(2)}';
  String get comisionFormateada => '\$${comision.toStringAsFixed(2)}';
  String get saldoFormateado => '\$${saldo.toStringAsFixed(2)}';
}