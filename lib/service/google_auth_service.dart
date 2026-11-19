import 'package:flutter/foundation.dart';

class GoogleAuthService {
  /// Simula el inicio de sesión con Google.
  /// Devuelve un Map con {correo, nombre} o null si cancela.
  Future<Map<String, String>?> iniciarSesionConGoogle() async {
    // Simulamos un retraso de 1.5 segundos (como si abriera Google)
    await Future.delayed(const Duration(milliseconds: 1500));

    // Devolvemos un usuario de Google simulado
    return {
      'correo': 'usuario.google@gmail.com',
      'nombre': 'Usuario Google',
    };
  }

  /// Cierra la sesión de Google (simulada)
  Future<void> cerrarSesion() async {
    debugPrint('🔓 Sesión de Google cerrada (simulada)');
  }
}