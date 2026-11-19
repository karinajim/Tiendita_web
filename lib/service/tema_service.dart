import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TemaService extends ChangeNotifier {
  static const String _key = 'modo_oscuro';

  bool _modoOscuro = false;

  bool get modoOscuro => _modoOscuro;

  ThemeMode get themeMode => _modoOscuro ? ThemeMode.dark : ThemeMode.light;

  Future<void> cargarPreferencia() async {
    final prefs = await SharedPreferences.getInstance();
    _modoOscuro = prefs.getBool(_key) ?? false;
    notifyListeners();
  }

  Future<void> cambiarTema(bool oscuro) async {
    _modoOscuro = oscuro;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, oscuro);
    notifyListeners();
  }
}