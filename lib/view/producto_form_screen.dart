import 'package:flutter/material.dart';
import '../model/producto.dart';
import '../service/producto_service.dart';

class ProductoFormScreen extends StatefulWidget {
  final Producto? productoAEditar;

  const ProductoFormScreen({super.key, this.productoAEditar});

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _servicio = ProductoService();

  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _stockController = TextEditingController();
  final _imagenController = TextEditingController();

  String? _mensajeError;
  bool _guardando = false;

  bool get _esEdicion => widget.productoAEditar != null;

  static const int _tituloMin = 3;
  static const int _tituloMax = 100;
  static const int _descMin = 10;
  static const int _descMax = 500;
  static const double _precioMax = 1000000.0;
  static const int _stockMax = 99999;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      final p = widget.productoAEditar!;
      _tituloController.text = p.titulo;
      _descripcionController.text = p.descripcion;
      _precioController.text = p.precio.toString();
      _stockController.text = p.stock.toString();
      _imagenController.text = p.imagenUrl;
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _stockController.dispose();
    _imagenController.dispose();
    super.dispose();
  }

  String? _validarTitulo(String? v) {
    if (v == null || v.trim().isEmpty) return 'Escribe un título';
    final t = v.trim();
    if (t.length < _tituloMin) return 'Mínimo $_tituloMin caracteres';
    if (t.length > _tituloMax) return 'Máximo $_tituloMax caracteres';
    return null;
  }

  String? _validarDescripcion(String? v) {
    if (v == null || v.trim().isEmpty) return 'Escribe una descripción';
    final t = v.trim();
    if (t.length < _descMin) return 'Mínimo $_descMin caracteres';
    if (t.length > _descMax) return 'Máximo $_descMax caracteres';
    return null;
  }

  String? _validarPrecio(String? v) {
    if (v == null || v.trim().isEmpty) return 'Escribe un precio';
    final n = double.tryParse(v.trim());
    if (n == null) return 'Precio inválido';
    if (n <= 0) return 'El precio debe ser mayor a 0';
    if (n > _precioMax) {
      return 'Máximo \$${_precioMax.toStringAsFixed(0)}';
    }
    final partes = v.trim().split('.');
    if (partes.length == 2 && partes[1].length > 2) {
      return 'Máximo 2 decimales';
    }
    return null;
  }

  String? _validarStock(String? v) {
    if (v == null || v.trim().isEmpty) return 'Escribe un stock';
    if (v.contains('.')) return 'Stock debe ser número entero';
    final n = int.tryParse(v.trim());
    if (n == null) return 'Stock inválido';
    if (n < 0) return 'El stock no puede ser negativo';
    if (n > _stockMax) return 'Máximo $_stockMax';
    return null;
  }

  String? _validarUrl(String? v) {
    if (v == null || v.trim().isEmpty) return 'Escribe la URL de la imagen';
    final t = v.trim();
    if (!t.startsWith('http://') && !t.startsWith('https://')) {
      return 'Debe empezar con http:// o https://';
    }
    final uri = Uri.tryParse(t);
    if (uri == null || !uri.hasAbsolutePath) return 'URL inválida';
    final extensiones = ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.svg'];
    final tieneExtension = extensiones.any((e) => t.toLowerCase().endsWith(e));
    if (!tieneExtension && !t.contains('?')) {
      return 'Debe terminar en .jpg, .png, .webp, .gif, .svg';
    }
    return null;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _mensajeError = null;
      _guardando = true;
    });

    final existeTitulo = await _servicio.tituloExiste(
      _tituloController.text.trim(),
      excluirId: widget.productoAEditar?.id,
    );
    if (existeTitulo) {
      setState(() {
        _mensajeError = 'Ya existe un producto con ese título';
        _guardando = false;
      });
      return;
    }

    final producto = Producto(
      id: widget.productoAEditar?.id,
      titulo: _tituloController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      precio: double.parse(_precioController.text.trim()),
      stock: int.parse(_stockController.text.trim()),
      imagenUrl: _imagenController.text.trim(),
    );

    try {
      if (_esEdicion) {
        await _servicio.actualizarProducto(producto);
      } else {
        await _servicio.registrarProducto(producto);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _mensajeError = 'No se pudo guardar: $e';
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar producto' : 'Agregar producto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.pink.shade100),
                  ),
                  child: _imagenController.text.isEmpty
                      ? Icon(Icons.image,
                          size: 60, color: Colors.pink.shade200)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            _imagenController.text,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.broken_image,
                              size: 60,
                              color: Colors.pink.shade200,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _tituloController,
                decoration: InputDecoration(
                  labelText: 'Título del producto',
                  prefixIcon: const Icon(Icons.title),
                  counterText:
                      '${_tituloController.text.length}/$_tituloMax',
                ),
                maxLength: _tituloMax,
                onChanged: (_) => setState(() {}),
                validator: _validarTitulo,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descripcionController,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  prefixIcon: const Icon(Icons.description),
                  counterText:
                      '${_descripcionController.text.length}/$_descMax',
                ),
                maxLines: 3,
                maxLength: _descMax,
                onChanged: (_) => setState(() {}),
                validator: _validarDescripcion,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _precioController,
                decoration: const InputDecoration(
                  labelText: 'Precio (MXN)',
                  prefixIcon: Icon(Icons.attach_money),
                  helperText: 'Máx \$1,000,000 · Máx 2 decimales',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: _validarPrecio,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock (cantidad disponible)',
                  prefixIcon: Icon(Icons.numbers),
                  helperText: 'Entero entre 0 y 99,999',
                ),
                keyboardType: TextInputType.number,
                validator: _validarStock,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _imagenController,
                decoration: const InputDecoration(
                  labelText: 'URL de la imagen',
                  prefixIcon: Icon(Icons.link),
                  helperText: 'Ej: https://ejemplo.com/imagen.jpg',
                ),
                keyboardType: TextInputType.url,
                onChanged: (_) => setState(() {}),
                validator: _validarUrl,
              ),

              if (_mensajeError != null) ...[
                const SizedBox(height: 12),
                Text(_mensajeError!,
                    style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: Icon(_esEdicion ? Icons.save : Icons.add),
                label: Text(
                  _guardando
                      ? 'Guardando...'
                      : (_esEdicion ? 'Guardar cambios' : 'Agregar producto'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}