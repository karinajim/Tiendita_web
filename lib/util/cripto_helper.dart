import 'dart:convert';
import 'package:encrypt/encrypt.dart' as enc;

class CriptoHelper {
  /// Equivalente a encrypt(plainText, iv, secretKey) de Node (AES-256-CBC).
  /// iv y secretKey vienen en base64 (key = 32 bytes, iv = 16 bytes).
  static String encrypt(dynamic plainText, String ivB64, String secretKeyB64) {
    final key = enc.Key(base64.decode(secretKeyB64));
    final iv = enc.IV(base64.decode(ivB64));
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    return encrypter.encrypt(jsonEncode(plainText), iv: iv).base64;
  }
}