import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';
import '../database/database_helper.dart';
import '../model/producto_xml.dart';
import '../util/cripto_helper.dart';

class ResultadoTx {
  final bool exito;
  final bool pendiente;
  final bool saldoInsuficiente;
  final String? codigo;
  final String? numAutorizacion;
  final String detalle;

  ResultadoTx({
    required this.exito,
    this.pendiente = false,
    this.saldoInsuficiente = false,
    this.codigo,
    this.numAutorizacion,
    required this.detalle,
  });
}

class SendTxService {
  static const String _baseUrl = 'https://gestopago.portalventas.net/sistema';
  static const String _apiKey = 'YSX1HpAFum4TpCecyFBxs4eIjAlbhKqK6fpcSQp8'; 
  static const String _idDistribuidor = '83';
  static const String _codigoDispositivo = 'GPS83-TPV-17';
  static const String _password = '12345678';
  static const String _secretKey = 'HPo7OLqB4Fkk4E2yGOtwqw8H5fHR9kNx67OR4g4UdlA=';
  static const String _iv = 'p5ldmBPdd/9pjC0bDC/nSg==';
  static const String _unidad = '083';
  
  static const Duration _esperaToken = Duration(seconds: 30);
  static const Duration _esperaSendTx = Duration(seconds: 70);

  static const String _kToken = 'tx_token_v2';
  static const String _kTokenFecha = 'tx_token_ts';

  static bool esPin(ProductoXML p) => p.idCatTipoServicio == 10 || p.idCatTipoServicio == 11;
  static bool esPagoServicio(ProductoXML p) => !esPin(p) && p.tipoFront == 2;
  static bool pideTelefono(ProductoXML p) => !esPin(p) && p.tipoFront == 1;

  // --- PASO 1 DEL DIAGRAMA: OBTENER TOKEN ---
  static Future<String> _pedirToken() async {
    final uri = Uri.parse('$_baseUrl/app/jwt-gp/authenticate/').replace(
      queryParameters: {
        'idDistribuidor': _idDistribuidor,
        'codigoDispositivo': _codigoDispositivo,
        'password': _password,
      },
    );

    final r = await http.post(uri, headers: {'X-API-Key': _apiKey}).timeout(_esperaToken);
    final datos = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    final token = datos['token'] as String?;
    
    if (r.statusCode != 200 || datos['success'] != true || token == null) {
      throw Exception('No se obtuvo el token (${r.statusCode})');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    await prefs.setString(_kTokenFecha, DateTime.now().toIso8601String());
    return token;
  }

  static Future<String> _token({bool forzarNuevo = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final guardado = prefs.getString(_kToken);
    final fecha = DateTime.tryParse(prefs.getString(_kTokenFecha) ?? '');
    final vigente = fecha != null && DateTime.now().difference(fecha) < const Duration(hours: 23);
    
    if (!forzarNuevo && guardado != null && vigente) return guardado;
    return _pedirToken();
  }

  static String _horaApi(DateTime h) {
    String d(int n) => n.toString().padLeft(2, '0');
    return '${h.year}${d(h.month)}${d(h.day)}${d(h.hour)}${d(h.minute)}${d(h.second)}';
  }

  static String _horaLegible(DateTime h) {
    String d(int n) => n.toString().padLeft(2, '0');
    return '${d(h.day)}/${d(h.month)}/${h.year} ${d(h.hour)}:${d(h.minute)}';
  }

  // --- PASO 2, 3 Y 4 DEL DIAGRAMA ---
  static Future<ResultadoTx> enviar({
    required ProductoXML producto,
    String refTel = '',
    double? monto,
  }) async {
    final ahora = DateTime.now();
    final precio = monto ?? producto.precio;

    final String telefonoCampo;
    if (esPin(producto)) {
      telefonoCampo = '#1111111111';
    } else if (producto.tipoFront == 1) {
      telefonoCampo = refTel;
    } else {
      telefonoCampo = '1111111111';
    }

    // 1. Creamos el JSON (Petición JSON)
    final payload = <String, dynamic>{
      'idProducto': producto.idProducto,
      'idServicio': producto.idServicio,
      'telefono': telefonoCampo,
      'horaLocal': _horaApi(ahora),
      'upc': ahora.millisecondsSinceEpoch.toString(),
      'unidad': _unidad,
      if (esPagoServicio(producto)) 'referencia': refTel,
      if (esPagoServicio(producto)) 'montoPago': precio,
    };

    // 2. Firmamos la petición (Cifrado AES)
    final signed = CriptoHelper.encrypt(payload, _iv, _secretKey);
    final cuerpo = {
      'random': ahora.millisecondsSinceEpoch.toString(), 
      'signed': signed
    };
    
    final uri = Uri.parse('$_baseUrl/service/sendTx.do');

    try {
      // 3. Enviamos con el Bearer Token
      var token = await _token();
      var resp = await http.post(
        uri, 
        headers: {
          'X-API-Key': _apiKey,
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded', // Importante para Punto Red
        }, 
        body: cuerpo, // Enviamos 'random' y 'signed'
      ).timeout(_esperaSendTx);

      if (resp.statusCode == 401 || resp.statusCode == 403) {
        token = await _token(forzarNuevo: true);
        resp = await http.post(
          uri, 
          headers: {
            'X-API-Key': _apiKey,
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/x-www-form-urlencoded',
          }, 
          body: cuerpo,
        ).timeout(_esperaSendTx);
      }

      if (resp.statusCode != 200) {
        return ResultadoTx(exito: false, detalle: 'Error HTTP ${resp.statusCode}');
      }

      // 4. Leemos el XML de respuesta (Código 01)
      final texto = utf8.decode(resp.bodyBytes);
      final doc = XmlDocument.parse(texto);
      
      String t(String n) => doc.findAllElements(n).firstOrNull?.innerText.trim() ?? '';

      String codigo = t('CODIGO');
      String mensajeServidor = t('TEXTO');
      if (codigo.isEmpty) {
        codigo = t('CODIGO_MENSAJE');
        mensajeServidor = t('MENSAJE');
      }
      
      final autorizacion = t('NUM_AUTORIZACION'); 

      final exito = codigo == '01';

      if (exito) {
        await DatabaseHelper().insertarTransaccion({
          'id_servicio': producto.idServicio,
          'id_producto': producto.idProducto,
          'servicio': producto.servicio,
          'producto': producto.producto,
          'telefono': refTel.isEmpty ? '-' : refTel,
          'precio': precio,
          'codigo': codigo,
          'mensaje': mensajeServidor,
          'num_autorizacion': autorizacion,
          'fecha': _horaLegible(ahora),
        });
      }

      return ResultadoTx(
        exito: exito,
        pendiente: codigo == '82',
        saldoInsuficiente: codigo == '02',
        codigo: codigo,
        numAutorizacion: autorizacion.isEmpty ? null : autorizacion,
        detalle: mensajeServidor.isEmpty ? 'Error $codigo' : mensajeServidor,
      );
    } catch (e) {
      return ResultadoTx(exito: false, detalle: 'Error de conexión: $e');
    }
  }
}