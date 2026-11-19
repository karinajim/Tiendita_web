import '../database/database_helper.dart';
import '../model/producto.dart';

class ProductoService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> registrarProducto(Producto producto) async {
    return await _dbHelper.insertarProducto(producto);
  }

  Future<int> actualizarProducto(Producto producto) async {
    return await _dbHelper.actualizarProducto(producto);
  }

  Future<int> eliminarProducto(int id) async {
    return await _dbHelper.eliminarProducto(id);
  }

  Future<List<Producto>> obtenerProductos() async {
    return await _dbHelper.obtenerProductos();
  }

  Future<Producto?> obtenerProductoPorId(int id) async {
    return await _dbHelper.obtenerProductoPorId(id);
  }

  Future<int> contarProductos() async {
    final lista = await _dbHelper.obtenerProductos();
    return lista.length;
  }

  Future<bool> tituloExiste(String titulo, {int? excluirId}) async {
    return await _dbHelper.existeProductoConTitulo(titulo, excluirId: excluirId);
  }
}