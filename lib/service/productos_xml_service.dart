import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:xml/xml.dart';
import '../database/database_helper.dart';
import '../model/producto_xml.dart';

class ProductosXMLService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Carga el XML desde el asset y guarda los productos en SQLite.
  Future<int> cargarDesdeAsset() async {
    try {
      final xmlString = await rootBundle.loadString('assets/productos.xml');
      return await cargarDesdeXML(xmlString);
    } catch (e) {
      debugPrint('❌ Error al leer el asset: $e');
      rethrow;
    }
  }

  /// Parsea el XML y guarda los productos en SQLite.
  Future<int> cargarDesdeXML(String xmlString) async {
    try {
      final document = XmlDocument.parse(xmlString);
      final root = document.rootElement;

      final mensaje = root.findElements('MENSAJE').firstOrNull;
      final codigo = mensaje?.findElements('CODIGO').firstOrNull?.innerText;

      if (codigo != '01') {
        throw Exception('Código de respuesta inválido: $codigo');
      }

      debugPrint('✅ XML válido. Parseando productos...');

      final productosXML = <ProductoXML>[];
      final productosElement = root.findElements('PRODUCTOS').firstOrNull;

      if (productosElement == null) {
        throw Exception('No se encontró la sección <PRODUCTOS>');
      }

      for (final elemento in productosElement.findElements('producto')) {
        try {
          final servicio = elemento.getAttribute('servicio') ?? '';
          final producto = elemento.getAttribute('producto') ?? '';
          final idServicio =
              int.tryParse(elemento.getAttribute('idServicio') ?? '0') ?? 0;
          final idProducto =
              int.tryParse(elemento.getAttribute('idProducto') ?? '0') ?? 0;
          final idCatTipoServicio = int.tryParse(
                  elemento.getAttribute('idCatTipoServicio') ?? '0') ??
              0;
          final tipoFront =
              int.tryParse(elemento.getAttribute('tipoFront') ?? '0') ?? 0;
          final hasDigitoVerificador =
              elemento.getAttribute('hasDigitoVerificador') == 'true';
          final precio =
              double.tryParse(elemento.getAttribute('precio') ?? '0') ?? 0.0;
          final showAyuda = elemento.getAttribute('showAyuda') == 'true';
          final tipoReferencia =
              elemento.getAttribute('tipoReferencia') ?? '';

          String legend = '';
          final legendElement = elemento.findElements('legend').firstOrNull;
          if (legendElement != null) {
            legend = legendElement.innerText.trim();
          }

          productosXML.add(ProductoXML(
            servicio: servicio,
            producto: producto,
            idServicio: idServicio,
            idProducto: idProducto,
            idCatTipoServicio: idCatTipoServicio,
            tipoFront: tipoFront,
            hasDigitoVerificador: hasDigitoVerificador,
            precio: precio,
            showAyuda: showAyuda,
            tipoReferencia: tipoReferencia,
            legend: legend,
          ));
        } catch (e) {
          debugPrint('Error al parsear un producto: $e');
        }
      }

      debugPrint('📦 ${productosXML.length} productos parseados.');

      await _dbHelper.limpiarProductosXML();
      await _dbHelper.insertarProductosXML(productosXML);

      debugPrint('💾 Productos guardados en SQLite.');

      return productosXML.length;
    } catch (e) {
      debugPrint('❌ Error al cargar XML: $e');
      rethrow;
    }
  }

  Future<List<ProductoXML>> obtenerTodos() async {
    return await _dbHelper.obtenerProductosXML();
  }

  Future<List<ProductoXML>> buscar(String texto) async {
    return await _dbHelper.buscarProductosXML(texto);
  }

  Future<int> contar() async {
    return await _dbHelper.contarProductosXML();
  }
}