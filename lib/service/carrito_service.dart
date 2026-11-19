import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/producto.dart';

class CarritoService {
  static const String _key = 'carrito_usuario';

  Future<List<Map<String, dynamic>>> obtenerCarrito() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final List<dynamic> lista = json.decode(raw);
    return lista.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> guardarCarrito(List<Map<String, dynamic>> carrito) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(carrito));
  }

  Future<void> limpiarCarrito() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> agregarProducto(Producto producto, int cantidad) async {
    final carrito = await obtenerCarrito();
    final index = carrito.indexWhere((item) => item['id'] == producto.id);
    if (index != -1) {
      carrito[index]['cantidad'] =
          (carrito[index]['cantidad'] as int) + cantidad;
    } else {
      carrito.add({
        'id': producto.id,
        'titulo': producto.titulo,
        'precio': producto.precio,
        'imagen_url': producto.imagenUrl,
        'cantidad': cantidad,
      });
    }
    await guardarCarrito(carrito);
  }

  Future<void> eliminarProducto(int idProducto) async {
    final carrito = await obtenerCarrito();
    carrito.removeWhere((item) => item['id'] == idProducto);
    await guardarCarrito(carrito);
  }

  Future<int> contarItems() async {
    final carrito = await obtenerCarrito();
    return carrito.fold<int>(
        0, (sum, item) => sum + (item['cantidad'] as int));
  }

  double calcularTotal(List<Map<String, dynamic>> carrito) {
    return carrito.fold<double>(
      0.0,
      (sum, item) =>
          sum + ((item['precio'] as num) * (item['cantidad'] as num)),
    );
  }
}