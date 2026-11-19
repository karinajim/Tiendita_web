import 'package:flutter/material.dart';
import '../model/producto_xml.dart';
import '../service/productos_xml_service.dart';
import '../util/logo_servicio.dart';
import 'pagar_servicio_screen.dart'; // <-- ESTA ES LA LÍNEA CLAVE
import 'historial_transacciones_screen.dart';

class ProductosXMLListScreen extends StatefulWidget {
  final String correoUsuario;

  const ProductosXMLListScreen({super.key, required this.correoUsuario});

  @override
  State<ProductosXMLListScreen> createState() => _ProductosXMLListScreenState();
}

class _ProductosXMLListScreenState extends State<ProductosXMLListScreen> {
  final _servicio = ProductosXMLService();
  List<ProductoXML> _productos = [];
  List<ProductoXML> _productosFiltrados = [];
  List<MapEntry<int, List<ProductoXML>>> _grupos = [];
  bool _cargando = true;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    setState(() => _cargando = true);
    final lista = await _servicio.obtenerTodos();
    setState(() {
      _productos = lista;
      _productosFiltrados = lista;
      _agrupar();
      _cargando = false;
    });
  }

  void _agrupar() {
    final mapa = <int, List<ProductoXML>>{};
    for (final p in _productosFiltrados) {
      mapa.putIfAbsent(p.idServicio, () => []).add(p);
    }
    _grupos = mapa.entries.toList()
      ..sort((a, b) => a.value.first.servicio.toLowerCase().compareTo(b.value.first.servicio.toLowerCase()));
  }

  void _filtrar(String query) {
    setState(() {
      _busqueda = query;
      if (query.isEmpty) {
        _productosFiltrados = _productos;
      } else {
        final q = query.toLowerCase().trim();
        _productosFiltrados = _productos
            .where((p) =>
                p.producto.toLowerCase().contains(q) ||
                p.servicio.toLowerCase().contains(q) ||
                p.idProducto.toString() == q ||
                p.idServicio.toString() == q)
            .toList();
      }
      _agrupar();
    });
  }

  String _inicial(String s) => s.isNotEmpty ? s[0].toUpperCase() : '?';

  void _pagar(ProductoXML p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PagarServicioScreen(
          producto: p,
          correoUsuario: widget.correoUsuario,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        title: const Text('Catálogo de servicios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistorialTransaccionesScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.pink, Color(0xFFFF8FB1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¡Encuentra tu servicio!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_productosFiltrados.length} productos · ${_grupos.length} servicios',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: _filtrar,
                  decoration: InputDecoration(
                    hintText: 'Buscar producto, servicio o ID...',
                    prefixIcon: const Icon(Icons.search, color: Colors.pink),
                    suffixIcon: _busqueda.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _filtrar(''))
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: Colors.pink))
                : _grupos.isEmpty
                    ? Center(child: Text(_busqueda.isEmpty ? 'No hay productos cargados' : 'No se encontraron productos'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: _grupos.length,
                        itemBuilder: (context, index) => _tarjetaGrupo(_grupos[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaGrupo(MapEntry<int, List<ProductoXML>> g) {
    final productos = g.value;
    final nombre = productos.first.servicio;
    final esServ = productos.first.tipoFront == 2;
    final desde = productos.map((p) => p.precio).reduce((a, b) => a < b ? a : b);

    return Card(
      key: ValueKey('grupo_${g.key}'),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.pink.shade100),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: LogoServicio(idServicio: g.key, inicial: _inicial(nombre), size: 48),
          title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${productos.length} productos',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.pink.shade700),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${esServ ? 'Comisión desde' : 'Desde'} \$${desde.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          children: productos.map(_filaProducto).toList(),
        ),
      ),
    );
  }

  Widget _filaProducto(ProductoXML p) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.pink.shade50)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.producto, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('ID: ${p.idProducto}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                if (p.legend.isNotEmpty)
                  Text(p.legend, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  p.tipoFront == 2 ? 'Comisión \$${p.precio.toStringAsFixed(2)}' : '\$${p.precio.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.pink.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(height: 6),
              ElevatedButton(
                onPressed: () => _pagar(p),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: const Text('PAGAR', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}