import 'dart:convert';
import 'package:flutter/material.dart';
import '../service/compra_service.dart';
import 'pedido_detalle_screen.dart';

class PedidoListScreen extends StatefulWidget {
  const PedidoListScreen({super.key});

  @override
  State<PedidoListScreen> createState() => _PedidoListScreenState();
}

class _PedidoListScreenState extends State<PedidoListScreen> {
  final _servicio = CompraService();
  List<Map<String, dynamic>> _pedidos = [];
  List<Map<String, dynamic>> _pedidosFiltrados = [];
  bool _cargando = true;
  String _filtroEstado = 'todos';

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
  }

  Future<void> _cargarPedidos() async {
    setState(() => _cargando = true);
    final lista = await _servicio.obtenerTodosLosPedidos();
    setState(() {
      _pedidos = lista;
      _aplicarFiltro();
      _cargando = false;
    });
  }

  void _aplicarFiltro() {
    if (_filtroEstado == 'todos') {
      _pedidosFiltrados = _pedidos;
    } else {
      _pedidosFiltrados = _pedidos
          .where((p) => (p['estado'] ?? 'pendiente') == _filtroEstado)
          .toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(title: const Text('Gestor de Pedidos')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _chipFiltro('todos', 'Todos'),
                _chipFiltro('pendiente', 'Pendientes'),
                _chipFiltro('aprobado', 'Aprobados'),
                _chipFiltro('enviado', 'Enviados'),
                _chipFiltro('entregado', 'Entregados'),
                _chipFiltro('cancelado', 'Cancelados'),
              ],
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.pink))
                : _pedidosFiltrados.isEmpty
                    ? const Center(child: Text('No hay pedidos con este filtro'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _pedidosFiltrados.length,
                        itemBuilder: (context, index) {
                          final p = _pedidosFiltrados[index];
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
                                child: Text(
                                  '#${p['id']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              title: Text(
                                p['correo_usuario'] ?? '',
                                style:
                                    const TextStyle(fontWeight: FontWeight.bold),
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
                                      border: Border.all(
                                          color: _colorEstado(estado)),
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
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PedidoDetalleScreen(pedido: p),
                                  ),
                                );
                                _cargarPedidos();
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chipFiltro(String valor, String etiqueta) {
    final seleccionado = _filtroEstado == valor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(etiqueta),
        selected: seleccionado,
        onSelected: (_) {
          setState(() {
            _filtroEstado = valor;
            _aplicarFiltro();
          });
        },
        selectedColor: Colors.pink.shade200,
        checkmarkColor: Colors.pink.shade800,
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