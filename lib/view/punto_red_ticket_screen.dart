import 'package:flutter/material.dart';
import '../model/punto_red_transaccion.dart';

class PuntoRedTicketScreen extends StatelessWidget {
  final PuntoRedTransaccion tx;
  final String servicio;
  final String producto;
  final String telefono;

  const PuntoRedTicketScreen({
    super.key,
    required this.tx,
    required this.servicio,
    required this.producto,
    required this.telefono,
  });

  @override
  Widget build(BuildContext context) {
    final Color rosaFuerte = Colors.pink.shade600;
    final Color rosaClaro = Colors.pink.shade50;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        title: const Text('¡Pago Completado!', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: rosaFuerte,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withValues(alpha: 0.1), // Corregido
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  decoration: BoxDecoration(
                    color: rosaClaro,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.green, size: 50),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Transacción Exitosa',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.pink.shade200),
                        ),
                        child: Text(
                          'Folio: ${tx.idTx}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: rosaFuerte),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _filaDetalle('Servicio', servicio),
                      _filaDetalle('Producto', producto),
                      _filaDetalle('Referencia', telefono),
                      _filaDetalle('Autorización', tx.numAutorizacion),
                      _filaDetalle('Fecha', tx.fecha),
                      
                      const SizedBox(height: 20),
                      
                      Row(
                        children: List.generate(150 ~/ 2, (index) => Expanded(
                          child: Container(
                            color: index % 2 == 0 ? Colors.transparent : Colors.grey.shade300,
                            height: 1,
                          ),
                        )),
                      ),
                      
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Pagado', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                          Text(
                            tx.montoFormateado,
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: rosaFuerte),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: rosaFuerte,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                          child: const Text('FINALIZAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filaDetalle(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}