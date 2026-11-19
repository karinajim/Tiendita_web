import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../service/compra_service.dart';
import '../util/mail_helper.dart';

class PedidoDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> pedido;

  const PedidoDetalleScreen({super.key, required this.pedido});

  @override
  State<PedidoDetalleScreen> createState() => _PedidoDetalleScreenState();
}

class _PedidoDetalleScreenState extends State<PedidoDetalleScreen> {
  final _servicio = CompraService();
  late String _estadoActual;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _estadoActual = widget.pedido['estado'] ?? 'pendiente';
  }

  List<Map<String, dynamic>> get _items {
    final raw = widget.pedido['detalle'];
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

  Future<void> _cambiarEstado(String nuevoEstado) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar estado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Cambiar el pedido a "$nuevoEstado"?'),
            const SizedBox(height: 12),
            const Text(
              '📧 Se enviará un correo automático al cliente notificando el cambio.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _enviando = true);

    await _servicio.cambiarEstadoPedido(widget.pedido['id'], nuevoEstado);
    setState(() => _estadoActual = nuevoEstado);

    try {
      final correoCliente = widget.pedido['correo_usuario'] ?? '';
      if (correoCliente.isNotEmpty) {
        await MailHelper.sendOrderStatusUpdateEmail(
          correoCliente,
          widget.pedido['id'].toString(),
          nuevoEstado,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Pedido marcado como $nuevoEstado. Correo enviado al cliente.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado cambiado pero error al enviar correo: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pedido;
    final items = _items;

    final lat = (p['latitud'] as num?)?.toDouble();
    final lng = (p['longitud'] as num?)?.toDouble();
    final tieneUbicacion = lat != null && lng != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(title: Text('Pedido #${p['id']}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: _colorEstado(_estadoActual), width: 2),
              ),
              child: Column(
                children: [
                  Text('Estado actual',
                      style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 6),
                  Text(
                    _estadoActual.toUpperCase(),
                    style: TextStyle(
                      color: _colorEstado(_estadoActual),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _seccion(
              'Información del pedido',
              [
                _fila('Cliente', p['correo_usuario'] ?? ''),
                _fila('Fecha', p['fecha'] ?? ''),
                _fila('Total',
                    '\$${(p['total'] as num).toStringAsFixed(2)} MXN',
                    negrita: true),
              ],
            ),
            const SizedBox(height: 16),

            if (tieneUbicacion) ...[
              const Text(
                '📍 Ubicación de entrega',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.pink.shade100),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(lat, lng),
                      zoom: 16,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('entrega'),
                        position: LatLng(lat, lng),
                        infoWindow:
                            const InfoWindow(title: 'Ubicación de entrega'),
                      ),
                    },
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_off,
                        color: Colors.orange.shade800, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'El cliente no registró su ubicación.',
                        style: TextStyle(
                            fontSize: 12, color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

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

            const Text('Cambiar estado del pedido:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              '📧 Se enviará un correo al cliente automáticamente.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),

            if (_enviando)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.pink),
                ),
              ),

            _botonEstado('Aprobar', 'aprobado', Colors.blue),
            const SizedBox(height: 8),
            _botonEstado('Marcar como Enviado', 'enviado', Colors.purple),
            const SizedBox(height: 8),
            _botonEstado('Marcar como Entregado', 'entregado', Colors.green),
            const SizedBox(height: 8),
            _botonEstado('Cancelar pedido', 'cancelado', Colors.red),
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

  Widget _botonEstado(String etiqueta, String estado, Color color) {
    final esActual = _estadoActual == estado;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed:
            (esActual || _enviando) ? null : () => _cambiarEstado(estado),
        icon: Icon(esActual ? Icons.check_circle : Icons.circle_outlined,
            size: 18),
        label: Text(esActual ? '$etiqueta (actual)' : etiqueta),
        style: ElevatedButton.styleFrom(
          backgroundColor: esActual ? Colors.grey.shade300 : color,
          foregroundColor: esActual ? Colors.grey.shade700 : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}