import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../model/producto.dart';
import '../service/carrito_service.dart';
import '../service/producto_service.dart';
import 'carrito_screen.dart';

class ProductoTiendaScreen extends StatefulWidget {
  final String correoUsuario;

  const ProductoTiendaScreen({super.key, required this.correoUsuario});

  @override
  State<ProductoTiendaScreen> createState() => _ProductoTiendaScreenState();
}

class _ProductoTiendaScreenState extends State<ProductoTiendaScreen> {
  final _servicio = ProductoService();
  final _carritoService = CarritoService();

  List<Producto> _productos = [];
  bool _cargando = true;
  int _itemsCarrito = 0;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
    _actualizarContadorCarrito();
  }

  Future<void> _cargarProductos() async {
    setState(() => _cargando = true);
    final lista = await _servicio.obtenerProductos();
    setState(() {
      _productos = lista;
      _cargando = false;
    });
  }

  Future<void> _actualizarContadorCarrito() async {
    final n = await _carritoService.contarItems();
    if (mounted) setState(() => _itemsCarrito = n);
  }

  Future<void> _agregarAlCarrito(Producto producto, int cantidad) async {
    if (cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cantidad inválida')),
      );
      return;
    }
    if (cantidad > producto.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Solo hay ${producto.stock} disponibles')),
      );
      return;
    }

    await _carritoService.agregarProducto(producto, cantidad);
    await _actualizarContadorCarrito();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${producto.titulo} agregado (x$cantidad)'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ---------- COMPARTIR PRODUCTO ----------
  Future<void> _compartirProducto(Producto producto) async {
    final texto = '''
🛍️ ¡Mira este producto en Mi Tiendita!

📦 *${producto.titulo}*
📝 ${producto.descripcion}
💵 Precio: \$${producto.precio.toStringAsFixed(2)} MXN

¡Consíguelo ahora en Mi Tiendita! 🛒
''';

    try {
      await Share.share(
        texto,
        subject: 'Producto de Mi Tiendita: ${producto.titulo}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo compartir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarDialogoCantidad(Producto producto) {
    final controller = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(producto.titulo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Disponibles: ${producto.stock}'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final cant = int.tryParse(controller.text) ?? 0;
              Navigator.pop(ctx);
              _agregarAlCarrito(producto, cant);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
            ),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  Future<void> _irAlCarrito() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CarritoScreen(correoUsuario: widget.correoUsuario),
      ),
    );
    _cargarProductos();
    _actualizarContadorCarrito();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda'),
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: _irAlCarrito,
                icon: const Icon(Icons.shopping_cart),
                tooltip: 'Carrito',
              ),
              if (_itemsCarrito > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '$_itemsCarrito',
                      style: const TextStyle(
                        color: Colors.pink,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: Colors.pink))
          : _productos.isEmpty
              ? const Center(
                  child: Text('No hay productos disponibles aún'),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _productos.length,
                  itemBuilder: (context, index) {
                    final p = _productos[index];
                    final agotado = p.stock == 0;

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                p.imagenUrl.isEmpty
                                    ? Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(
                                            Icons.image_not_supported,
                                            color: Colors.grey),
                                      )
                                    : Image.network(
                                        p.imagenUrl,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Container(
                                          color: Colors.grey.shade200,
                                          child: const Icon(
                                              Icons.broken_image,
                                              color: Colors.grey),
                                        ),
                                      ),
                                if (agotado)
                                  Positioned.fill(
                                    child: Container(
                                      color:
                                          Colors.black.withValues(alpha: 0.5),
                                      child: const Center(
                                        child: Text(
                                          'AGOTADO',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                // Botón compartir
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Material(
                                    color:
                                        Colors.white.withValues(alpha: 0.9),
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: () => _compartirProducto(p),
                                      child: const Padding(
                                        padding: EdgeInsets.all(6),
                                        child: Icon(
                                          Icons.share,
                                          color: Colors.pink,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.titulo,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${p.precio.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.pink.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: agotado
                                        ? null
                                        : () =>
                                            _mostrarDialogoCantidad(p),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.pink,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      agotado ? 'Sin stock' : 'Comprar',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}