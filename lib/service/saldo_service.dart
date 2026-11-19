import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SaldoService extends ChangeNotifier {
  static final SaldoService _instance = SaldoService._internal();
  factory SaldoService() => _instance;
  SaldoService._internal();

  static const String _keySaldo = 'saldo_paypal_simulado';
  double _saldoActual = 1500.0;

  double get saldo => _saldoActual;

  Future<void> cargarSaldo() async {
    final prefs = await SharedPreferences.getInstance();
    _saldoActual = prefs.getDouble(_keySaldo) ?? 1500.0;
    notifyListeners();
  }

  // ¡ESTE ES EL MÉTODO QUE FALTABA!
  Future<double> obtenerSaldo() async {
    final prefs = await SharedPreferences.getInstance();
    _saldoActual = prefs.getDouble(_keySaldo) ?? 1500.0;
    return _saldoActual;
  }

  Future<void> descontarSaldo(double monto) async {
    final prefs = await SharedPreferences.getInstance();
    _saldoActual -= monto;
    if (_saldoActual < 0) _saldoActual = 0;
    await prefs.setDouble(_keySaldo, _saldoActual);
    notifyListeners();
  }
}