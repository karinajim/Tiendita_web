import 'dart:convert';
import 'package:flutter/material.dart';

class MiPedidoDetalleScreen extends StatelessWidget {
  final Map<String, dynamic> pedido;

  const MiPedidoDetalleScreen({super.key, required this.pedido});

  List<Map<String, dynamic>> get _items {
    final raw = pedido['detalle'];
    if (raw == null) return [];
    try {
      final List<dynamic> lista = json.decode(raw.toString());
      return lista.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'aprobado':
        return Colors.blue;
      case 'enviado':
        return Colors.purple;
      case 'entregado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _descripcionEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Tu pedido está siendo revisado por el administrador.';
      case 'aprobado':
        return 'El administrador aprobó tu pedido. Pronto será enviado.';
      case 'enviado':
        return '¡Tu pedido ya va en camino!';
      case 'entregado':
        return 'Tu pedido ha sido entregado. ¡Gracias por tu compra!';
      case 'cancelado':
        return 'Este pedido ha sido cancelado.';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = pedido['estado'] ?? 'pendiente';
    final items = _items;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(title: Text('Pedido #${pedido['id']}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------- ESTADO ----------
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _colorEstado(estado), width: 2),
              ),
              child: Column(
                children: [
                  Text('Estado del pedido',
                      style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 6),
                  Text(
                    estado.toUpperCase(),
                    style: TextStyle(
                      color: _colorEstado(estado),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _descripcionEstado(estado),
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ---------- INFO ----------
            _seccion(
              'Información del pedido',
              [
                _fila('Fecha', pedido['fecha'] ?? ''),
                _fila('Total',
                    '\$${(pedido['total'] as num).toStringAsFixed(2)} MXN',
                    negrita: true),
              ],
            ),
            const SizedBox(height: 16),

            // ---------- PRODUCTOS ----------
            _seccion(
              'Productos (${items.length})',
              items.map((item) {
                final subtotal =
                    (item['precio'] as num) * (item['cantidad'] as num);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['titulo'] ?? '',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'x${item['cantidad']} · \$${(item['precio'] as num).toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '\$${subtotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.pink.shade700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ---------- INFO ADICIONAL ----------
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.pink.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.pink.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recibirás un correo cuando el administrador actualice el estado de tu pedido.',
                      style: TextStyle(
                          fontSize: 12, color: Colors.pink.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seccion(String titulo, List<Widget> hijos) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.pink.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.pink.shade700,
                  fontSize: 14)),
          const SizedBox(height: 12),
          ...hijos,
        ],
      ),
    );
  }

  Widget _fila(String etiqueta, String valor, {bool negrita = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(etiqueta,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              valor,
              style: TextStyle(
                fontSize: 14,
                fontWeight: negrita ? FontWeight.bold : FontWeight.normal,
                color: negrita ? Colors.pink.shade700 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}