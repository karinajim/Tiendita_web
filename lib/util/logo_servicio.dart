import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../service/punto_red_logo_service.dart';

class LogoServicio extends StatefulWidget {
  final int idServicio;
  final String inicial;
  final double size;

  const LogoServicio({
    super.key,
    required this.idServicio,
    required this.inicial,
    this.size = 48,
  });

  @override
  State<LogoServicio> createState() => _LogoServicioState();
}

class _LogoServicioState extends State<LogoServicio> {
  late Future<Uint8List?> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = PuntoRedLogoService.obtenerLogo(widget.idServicio.toString());
  }

  Widget _letra() => Center(
        child: Text(
          widget.inicial,
          style: TextStyle(
            fontSize: widget.size * 0.45,
            fontWeight: FontWeight.bold,
            color: Colors.pink,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.pink.shade100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: FutureBuilder<Uint8List?>(
          future: _futuro,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.pink),
                ),
              );
            }
            if (snap.data == null) return _letra(); // si falla, queda la letra
            return Padding(
              padding: const EdgeInsets.all(4),
              child: Image.memory(snap.data!, fit: BoxFit.contain),
            );
          },
        ),
      ),
    );
  }
}