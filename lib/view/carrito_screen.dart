import 'package:flutter/material.dart';
import '../service/carrito_service.dart';
import '../service/compra_service.dart';
import '../service/usuario_service.dart';
import '../service/geolocalizacion_service.dart';
import 'paypal_pago_screen.dart';

class CarritoScreen extends StatefulWidget {
  final String correoUsuario;

  const CarritoScreen({super.key, required this.correoUsuario});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  final _carritoService = CarritoService();
  final _compraService = CompraService();
  final _geoService = GeolocalizacionService();

  List<Map<String, dynamic>> _carrito = [];
  double _total = 0;
  bool _cargando = true;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _cargarCarrito();
  }

  Future<void> _cargarCarrito() async {
    setState(() => _cargando = true);
    final c = await _carritoService.obtenerCarrito();
    setState(() {
      _carrito = c;
      _total = _carritoService.calcularTotal(c);
      _cargando = false;
    });
  }

  Future<void> _eliminarItem(int id) async {
    await _carritoService.eliminarProducto(id);
    _cargarCarrito();
  }

  Future<String> _obtenerCorreoAdmin() async {
    final servicio = UsuarioService();
    final usuarios = await servicio.obtenerUsuarios();
    final roles = await servicio.obtenerRoles();
    final rolAdmin = roles.where((r) => r.rol == 'admin').toList();
    if (rolAdmin.isEmpty) return '';
    final adminUser =
        usuarios.where((u) => u.roleId == rolAdmin.first.id).toList();
    return adminUser.isNotEmpty ? adminUser.first.correo : '';
  }

  Future<void> _realizarCompra({required String metodoPago}) async {
    setState(() => _procesando = true);

    try {
      final usuarioActual = await UsuarioService()
          .obtenerUsuarioPorCorreo(widget.correoUsuario);

      double? latFinal;
      double? lngFinal;

      if (usuarioActual != null &&
          usuarioActual.latitud != null &&
          usuarioActual.longitud != null) {
        latFinal = usuarioActual.latitud;
        lngFinal = usuarioActual.longitud;
      } else {
        final posicion = await _geoService.obtenerUbicacion();
        latFinal = posicion?.latitude;
        lngFinal = posicion?.longitude;
      }

      final adminCorreo = await _obtenerCorreoAdmin();

      await _compraService.procesarCompra(
        correoDestino: widget.correoUsuario,
        carrito: _carrito,
        correoAdmin: adminCorreo,
        latitud: latFinal,
        longitud: lngFinal,
      );

      await _carritoService.limpiarCarrito();

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('¡Compra exitosa con $metodoPago!'),
            content: Text(
              'Tu compra se realizó correctamente.\n\n'
              'Se ha enviado un resumen a:\n${widget.correoUsuario}'
              '${latFinal != null ? "\n\n📍 Ubicación registrada para entrega." : ""}',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _confirmarCompraNormal() async {
    if (_carrito.isEmpty) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar compra'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Deseas finalizar tu compra?'),
            const SizedBox(height: 8),
            Text('Total: \$${_total.toStringAsFixed(2)} MXN',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              '📍 Se usará tu ubicación guardada para la entrega.',
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
    await _realizarCompra(metodoPago: 'efectivo');
  }

  Future<void> _pagarConPaypal() async {
    if (_carrito.isEmpty) return;

    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PaypalPagoScreen(
          total: _total,
          correoUsuario: widget.correoUsuario,
          descripcion: 'Compra en Tienda (${_carrito.length} artículos)',
        ),
      ),
    );

    if (resultado == true) {
      await _realizarCompra(metodoPago: 'PayPal');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(title: const Text('Mi Carrito')),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: Colors.pink))
          : _carrito.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          size: 80, color: Colors.pink),
                      SizedBox(height: 12),
                      Text('Tu carrito está vacío'),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _carrito.length,
                        itemBuilder: (context, index) {
                          final item = _carrito[index];
                          final subtotal = (item['precio'] as num) *
                              (item['cantidad'] as num);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: item['imagen_url'] == null ||
                                        item['imagen_url'].toString().isEmpty
                                    ? Container(
                                        width: 50,
                                        height: 50,
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.image),
                                      )
                                    : Image.network(
                                        item['imagen_url'],
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Container(
                                          width: 50,
                                          height: 50,
                                          color: Colors.grey.shade200,
                                          child:
                                              const Icon(Icons.broken_image),
                                        ),
                                      ),
                              ),
                              title: Text(
                                item['titulo'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'x${item['cantidad']} · \$${(item['precio'] as num).toStringAsFixed(2)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '\$${subtotal.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.pink.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _eliminarItem(item['id']),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total:',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                '\$${_total.toStringAsFixed(2)} MXN',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.pink.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _procesando
                                  ? null
                                  : _confirmarCompraNormal,
                              icon: const Icon(Icons.check_circle),
                              label: Text(_procesando
                                  ? 'Procesando...'
                                  : 'Confirmar compra'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  _procesando ? null : _pagarConPaypal,
                              icon: const Icon(Icons.payment),
                              label: const Text('Pagar con PayPal'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF003087),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}