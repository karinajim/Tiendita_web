import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometriaService {
  static const String _keyCorreoGuardado = 'biometria_correo';

  final LocalAuthentication _auth = LocalAuthentication();

  /// Verifica si el dispositivo soporta biometría
  Future<bool> soportaBiometria() async {
    // Si estamos en web, no hay biometría disponible
    if (kIsWeb) return false; 

    try {
      final disponible = await _auth.canCheckBiometrics;
      final soportado = await _auth.isDeviceSupported();
      // En emulador (x86) no hay sensor real
      // Devolvemos true para poder probar
      if (kDebugMode) {
        return true;
      }
      return disponible && soportado;
    } catch (e) {
      debugPrint('Error al verificar biometría: $e');
      return kDebugMode;
    }
  }

  /// Autentica con huella REAL.
  /// - En celular: valida la huella de verdad.
  /// - En emulador: simula la autenticación para pruebas.
  Future<bool> autenticar() async {
    // Si estamos en web, no se puede autenticar con huella
    if (kIsWeb) return false;

    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Ingresa con tu huella para acceder a Mi Tiendita',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (ok) return true;

      // Si el sensor devolvió false (huella incorrecta),
      // NO permitimos el acceso en producción.
      if (kReleaseMode) {
        return false;
      }
    } catch (e) {
      debugPrint('Error al autenticar: $e');
      // Solo permitir simulación en debug
      if (kReleaseMode) {
        return false;
      }
    }

    // MODO DEMO: SOLO en modo debug (emulador)
    if (kDebugMode) {
      debugPrint('✅ [DEBUG] Huella simulada (solo en emulador)');
      return true;
    }

    return false;
  }

  Future<void> guardarCorreo(String correo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCorreoGuardado, correo);
  }

  Future<String?> obtenerCorreo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCorreoGuardado);
  }

  Future<bool> estaActivada() async {
    final correo = await obtenerCorreo();
    return correo != null && correo.isNotEmpty;
  }

  Future<void> desactivar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCorreoGuardado);
  }

  Future<bool> estaActivadaParaCorreo(String correo) async {
    final correoGuardado = await obtenerCorreo();
    return correoGuardado != null && correoGuardado == correo;
  }
}