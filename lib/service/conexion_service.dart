import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConexionService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _suscripcion;

  bool _estaOnline = true;

  bool get estaOnline => _estaOnline;
  bool get estaOffline => !_estaOnline;

  ConexionService() {
    _inicializar();
  }

  Future<void> _inicializar() async {
    // Verificar el estado inicial
    final resultado = await _connectivity.checkConnectivity();
    _actualizarEstado(resultado);

    // Escuchar cambios de conexión
    _suscripcion = _connectivity.onConnectivityChanged.listen(_actualizarEstado);
  }

  void _actualizarEstado(List<ConnectivityResult> resultados) {
    final estabaOnline = _estaOnline;

    // Si algún resultado NO es "none", está online
    _estaOnline = resultados.any((r) => r != ConnectivityResult.none);

    // Solo notificar si cambió el estado
    if (estabaOnline != _estaOnline) {
      debugPrint('🌐 Estado de conexión: ${_estaOnline ? "ONLINE" : "OFFLINE"}');
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    super.dispose();
  }
}