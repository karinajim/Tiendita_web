import 'dart:convert';
import '../database/database_helper.dart';
import '../model/producto.dart';
import '../util/mail_helper.dart';
import 'package:flutter/foundation.dart';

class CompraService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<bool> procesarCompra({
    required String correoDestino,
    required List<Map<String, dynamic>> carrito,
    required String correoAdmin,
    double? latitud,
    double? longitud,
  }) async {
    try {
      for (final item in carrito) {
        final producto = await _dbHelper.obtenerProductoPorId(item['id']);
        if (producto == null) {
          throw Exception('Producto no encontrado: ${item['titulo']}');
        }
        if (producto.stock < (item['cantidad'] as int)) {
          throw Exception(
              'Stock insuficiente para "${producto.titulo}". Disponible: ${producto.stock}');
        }
      }

      for (final item in carrito) {
        final producto = await _dbHelper.obtenerProductoPorId(item['id']);
        if (producto != null) {
          final actualizado = Producto(
            id: producto.id,
            titulo: producto.titulo,
            descripcion: producto.descripcion,
            precio: producto.precio,
            stock: producto.stock - (item['cantidad'] as int),
            imagenUrl: producto.imagenUrl,
          );
          await _dbHelper.actualizarProducto(actualizado);
        }
      }

      final total = carrito.fold<double>(
        0.0,
        (sum, item) =>
            sum + ((item['precio'] as num) * (item['cantidad'] as num)),
      );

      final ahora = DateTime.now();
      final fecha =
          '${ahora.day.toString().padLeft(2, '0')}/'
          '${ahora.month.toString().padLeft(2, '0')}/'
          '${ahora.year} '
          '${ahora.hour.toString().padLeft(2, '0')}:'
          '${ahora.minute.toString().padLeft(2, '0')}';

      await _dbHelper.insertarCompra(
        correoUsuario: correoDestino,
        total: total,
        detalle: json.encode(carrito),
        fecha: fecha,
        latitud: latitud,
        longitud: longitud,
      );

      await MailHelper.sendPurchaseSummaryEmail(correoDestino, carrito, total);

      if (correoAdmin.isNotEmpty) {
        await MailHelper.sendNewOrderNotificationToAdmin(
          correoAdmin,
          correoDestino,
          carrito,
          total,
        );
      }

      return true;
    } catch (e) {
      debugPrint('Error procesando compra: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> historialDeCompras(String correo) async {
    return await _dbHelper.obtenerComprasPorUsuario(correo);
  }

  Future<List<Map<String, dynamic>>> obtenerTodosLosPedidos() async {
    return await _dbHelper.obtenerTodasLasCompras();
  }

  Future<void> cambiarEstadoPedido(int id, String nuevoEstado) async {
    await _dbHelper.actualizarEstadoCompra(id, nuevoEstado);
  }
}