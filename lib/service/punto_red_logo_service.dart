// Servicio para descargar los logos de Punto Red.
// Endpoint requiere Authorization Bearer + X-API-Key.
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PuntoRedLogoService {
  static const String _baseUrl = 'https://gestopago.portalventas.net';

  // Token completo de Postman (sin la palabra "Bearer")
  static const String _token = 'PEGA_AQUI_TU_TOKEN_COMPLETO';

  // X-API-Key completo de Postman
  static const String _apiKey = 'PEGA_AQUI_TU_API_KEY_COMPLETA';

  // Cache en memoria
  static final Map<String, Uint8List> _cache = {};

  static Future<Uint8List?> obtenerLogo(String idServicio) async {
    if (_cache.containsKey(idServicio)) return _cache[idServicio];

    final url = Uri.parse(
      '$_baseUrl/sistema/images/gestopago/servicios/$idServicio.png',
    );

    try {
      final resp = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_token',
          'X-API-Key': _apiKey,
          'Accept': 'image/png',
        },
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode != 200) {
        debugPrint('⚠️ Logo $idServicio falló: ${resp.statusCode}');
        return null;
      }

      _cache[idServicio] = resp.bodyBytes;
      return resp.bodyBytes;
    } catch (e) {
      debugPrint('⚠️ Error al descargar logo $idServicio: $e');
      return null;
    }
  }

  static void limpiarCache() => _cache.clear();
}