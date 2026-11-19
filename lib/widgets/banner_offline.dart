import 'package:flutter/material.dart';
import '../service/conexion_service.dart';

class BannerOffline extends StatelessWidget {
  final ConexionService conexion;

  const BannerOffline({super.key, required this.conexion});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: conexion,
      builder: (context, _) {
        if (conexion.estaOnline) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.orange.shade700,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Sin conexión a internet. Algunas funciones están limitadas.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}