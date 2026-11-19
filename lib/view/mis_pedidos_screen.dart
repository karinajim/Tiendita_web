import 'dart:convert';
import 'package:flutter/material.dart';
import '../service/compra_service.dart';
import 'mi_pedido_detalle_screen.dart';

class MisPedidosScreen extends StatefulWidget {
  final String correoUsuario;

  const MisPedidosScreen({super.key, required this.correoUsuario});

  @override
  State<MisPedidosScreen> createState() => _MisPedidosScreenState();
}

class _MisPedidosScreenState extends State<MisPedidosScreen> {
  final _servicio = CompraService();
  List<Map<String, dynamic>> _pedidos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
  }

  Future<void> _cargarPedidos() async {
    setState(() => _cargando = true);
    final lista = await _servicio.historialDeCompras(widget.correoUsuario);
    setState(() {
      _pedidos = lista;
      _cargando = false;
    });
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

  IconData _iconoEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Icons.hourglass_empty;
      case 'aprobado':
        return Icons.check_circle_outline;
      case 'enviado':
        return Icons.local_shipping_outlined;
      case 'entregado':
        return Icons.check_circle;
      case 'cancelado':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(title: const Text('Mis Pedidos')),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: Colors.pink))
          : _pedidos.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 80, color: Colors.pink),
                      SizedBox(height: 12),
                      Text('Todavía no has hecho ningún pedido'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _pedidos.length,
                  itemBuilder: (context, index) {
                    final p = _pedidos[index];
                    final estado = p['estado'] ?? 'pendiente';
                    final detalle = _parsearDetalle(p['detalle']);
                    final cantidadItems = detalle.fold<int>(
                        0, (sum, item) => sum + (item['cantidad'] as int));

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: _colorEstado(estado),
                          child: Icon(
                            _iconoEstado(estado),
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          'Pedido #${p['id']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('📅 ${p['fecha']}'),
                            Text('📦 $cantidadItems producto(s)'),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _colorEstado(estado)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: _colorEstado(estado)),
                              ),
                              child: Text(
                                estado.toUpperCase(),
                                style: TextStyle(
                                  color: _colorEstado(estado),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '\$${(p['total'] as num).toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.pink.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MiPedidoDetalleScreen(pedido: p),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }

  List<Map<String, dynamic>> _parsearDetalle(dynamic raw) {
    if (raw == null) return [];
    try {
      final List<dynamic> lista = json.decode(raw.toString());
      return lista.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }
}