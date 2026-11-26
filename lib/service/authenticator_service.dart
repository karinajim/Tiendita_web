import 'package:otp/otp.dart';

class AuthenticatorService {
  // Genera una clave secreta para el usuario
  static String generarSecreto() => OTP.randomSecret();

  // Genera la URL para el QR (se arma manualmente para evitar errores de versión)
  static String generarUrlQR(String correo, String secreto) {
    // Formato estándar para Google Authenticator
    return 'otpauth://totp/MiTiendita:$correo?secret=$secreto&issuer=MiTiendita';
  }

  // Verifica el código de 6 dígitos que ingresa el usuario
  static bool verificarCodigo(String secreto, String codigoIngresado) {
    // En la versión 3.1.3, el secreto y la hora van como argumentos posicionales
    final codigoActual = OTP.generateTOTPCodeString(
      secreto,
      DateTime.now().millisecondsSinceEpoch,
      interval: 30, // Cambia cada 30 seg
      length: 6,
      algorithm: Algorithm.SHA1, // Google Authenticator usa SHA1 por defecto
    );
    return codigoActual == codigoIngresado;
  }
}