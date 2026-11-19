import 'package:flutter/foundation.dart'; // <-- Importante para usar kIsWeb
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/usuario.dart';
import '../model/rol.dart';
import '../model/producto.dart';
import '../model/producto_xml.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('La base de datos SQLite no está soportada en Web.');
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'mi_app.db');
    return await openDatabase(
      path,
      version: 8,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // ... (Tu código original de creación de tablas se mantiene igual) ...
    await db.execute("""
      CREATE TABLE rol_permiso (id INTEGER PRIMARY KEY, rol TEXT NOT NULL)
    """);
    await db.execute("""
      CREATE TABLE user_app(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        nombre TEXT NOT NULL, desc TEXT, pass TEXT NOT NULL, correo TEXT NOT NULL,
        role_id INTEGER NOT NULL, token_recuperacion TEXT, token_expiracion TIMESTAMP,
        codigo_verificacion TEXT, codigo_expiracion TIMESTAMP,
        createdAT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        latitud REAL, longitud REAL, FOREIGN KEY (role_id) REFERENCES rol_permiso (id)
      )
    """);
    await db.execute("""
      CREATE TABLE producto (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, titulo TEXT NOT NULL,
        descripcion TEXT, precio REAL NOT NULL, stock INTEGER NOT NULL DEFAULT 0, imagen_url TEXT
      )
    """);
    await db.execute("""
      CREATE TABLE compra (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, correo_usuario TEXT NOT NULL,
        total REAL NOT NULL, detalle TEXT, fecha TEXT NOT NULL,
        estado TEXT NOT NULL DEFAULT 'pendiente', latitud REAL, longitud REAL
      )
    """);
    await db.execute("""
      CREATE TABLE producto_xml (
        id_producto INTEGER PRIMARY KEY, servicio TEXT NOT NULL, producto TEXT NOT NULL,
        id_servicio INTEGER NOT NULL, id_cat_tipo_servicio INTEGER, tipo_front INTEGER,
        has_digito_verificador INTEGER DEFAULT 0, precio REAL NOT NULL,
        show_ayuda INTEGER DEFAULT 0, tipo_referencia TEXT, legend TEXT
      )
    """);
    await db.execute("""
      CREATE TABLE transaccion (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, id_servicio INTEGER NOT NULL,
        id_producto INTEGER NOT NULL, servicio TEXT NOT NULL, producto TEXT NOT NULL,
        telefono TEXT NOT NULL, precio REAL NOT NULL, codigo TEXT, mensaje TEXT,
        num_autorizacion TEXT, fecha TEXT NOT NULL
      )
    """);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // ... (Tu código original de upgrade se mantiene igual) ...
    if (oldVersion < 2) { await db.execute("CREATE TABLE IF NOT EXISTS producto (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, titulo TEXT NOT NULL, descripcion TEXT, precio REAL NOT NULL, stock INTEGER NOT NULL DEFAULT 0, imagen_url TEXT)"); }
    if (oldVersion < 3) { await db.execute("CREATE TABLE IF NOT EXISTS compra (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, correo_usuario TEXT NOT NULL, total REAL NOT NULL, detalle TEXT, fecha TEXT NOT NULL)"); }
    if (oldVersion < 4) { await db.execute("ALTER TABLE compra ADD COLUMN estado TEXT NOT NULL DEFAULT 'pendiente'"); }
    if (oldVersion < 5) { await db.execute("ALTER TABLE compra ADD COLUMN latitud REAL"); await db.execute("ALTER TABLE compra ADD COLUMN longitud REAL"); }
    if (oldVersion < 6) { await db.execute("ALTER TABLE user_app ADD COLUMN latitud REAL"); await db.execute("ALTER TABLE user_app ADD COLUMN longitud REAL"); }
    if (oldVersion < 7) { await db.execute("CREATE TABLE IF NOT EXISTS producto_xml (id_producto INTEGER PRIMARY KEY, servicio TEXT NOT NULL, producto TEXT NOT NULL, id_servicio INTEGER NOT NULL, id_cat_tipo_servicio INTEGER, tipo_front INTEGER, has_digito_verificador INTEGER DEFAULT 0, precio REAL NOT NULL, show_ayuda INTEGER DEFAULT 0, tipo_referencia TEXT, legend TEXT)"); }
    if (oldVersion < 8) { await db.execute("CREATE TABLE IF NOT EXISTS transaccion (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, id_servicio INTEGER NOT NULL, id_producto INTEGER NOT NULL, servicio TEXT NOT NULL, producto TEXT NOT NULL, telefono TEXT NOT NULL, precio REAL NOT NULL, codigo TEXT, mensaje TEXT, num_autorizacion TEXT, fecha TEXT NOT NULL)"); }
  }

  // ---------- ROL ----------
  Future<int> insertarRol(Rol rol) async {
    if (kIsWeb) return 0;
    final db = await database;
    return await db.insert('rol_permiso', rol.toMap());
  }

  Future<List<Rol>> obtenerRoles() async {
    if (kIsWeb) return [];
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('rol_permiso');
    return List.generate(maps.length, (i) => Rol.fromMap(maps[i]));
  }

  // ---------- USUARIO ----------
  Future<int> insertarUsuario(Usuario usuario) async {
    if (kIsWeb) return 0;
    final db = await database;
    return await db.insert('user_app', usuario.toMap());
  }

  Future<int> actualizarUsuario(Usuario usuario) async {
    if (kIsWeb) return 0;
    final db = await database;
    return await db.update('user_app', usuario.toMap(), where: 'id = ?', whereArgs: [usuario.id]);
  }

  Future<List<Usuario>> obtenerUsuarios() async {
    if (kIsWeb) return [];
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('user_app');
    return List.generate(maps.length, (i) => Usuario.fromMap(maps[i]));
  }

  Future<Usuario?> obtenerUsuarioPorCredenciales(String correo, String pass) async {
    if (kIsWeb) return null; // En web no hay login real sin backend
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('user_app', where: 'correo = ? AND pass = ?', whereArgs: [correo, pass]);
    if (maps.isEmpty) return null;
    return Usuario.fromMap(maps.first);
  }

  Future<Usuario?> obtenerUsuarioPorCorreo(String correo) async {
    if (kIsWeb) return null;
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('user_app', where: 'correo = ?', whereArgs: [correo]);
    if (maps.isEmpty) return null;
    return Usuario.fromMap(maps.first);
  }

  Future<int> contarUsuariosPorRol(int roleId) async {
    if (kIsWeb) return 0;
    final db = await database;
    final maps = await db.query('user_app', where: 'role_id = ?', whereArgs: [roleId]);
    return maps.length;
  }

  Future<int> contarUsuarios() async {
    if (kIsWeb) return 0;
    final db = await database;
    final maps = await db.query('user_app');
    return maps.length;
  }

  Future<int> eliminarUsuario(int id) async {
    if (kIsWeb) return 0;
    final db = await database;
    return await db.delete('user_app', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> guardarCodigoOtp(String correo, String codigo, String expiracion) async {
    if (kIsWeb) return;
    final db = await database;
    await db.update('user_app', {'codigo_verificacion': codigo, 'codigo_expiracion': expiracion}, where: 'correo = ?', whereArgs: [correo]);
  }

  Future<Map<String, dynamic>?> obtenerDatosOtp(String correo) async {
    if (kIsWeb) return null;
    final db = await database;
    final maps = await db.query('user_app', columns: ['codigo_verificacion', 'codigo_expiracion'], where: 'correo = ?', whereArgs: [correo]);
    if (maps.isEmpty) return null;
    return maps.first;
  }

  Future<void> actualizarPassword(String correo, String nuevaPass) async {
    if (kIsWeb) return;
    final db = await database;
    await db.update('user_app', {'pass': nuevaPass, 'codigo_verificacion': null, 'codigo_expiracion': null}, where: 'correo = ?', whereArgs: [correo]);
  }

  Future<bool> correoExisteEnOtroUsuario(String correo, int idActual) async {
    if (kIsWeb) return false;
    final db = await database;
    final maps = await db.query('user_app', where: 'LOWER(correo) = ? AND id != ?', whereArgs: [correo.toLowerCase().trim(), idActual]);
    return maps.isNotEmpty;
  }

  Future<int> actualizarPerfil(int id, String nombre, String correo, String pass) async {
    if (kIsWeb) return 0;
    final db = await database;
    return await db.update('user_app', {'nombre': nombre, 'correo': correo, 'pass': pass}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> actualizarUbicacionUsuario(int id, double latitud, double longitud) async {
    if (kIsWeb) return 0;
    final db = await database;
    return await db.update('user_app', {'latitud': latitud, 'longitud': longitud}, where: 'id = ?', whereArgs: [id]);
  }

  // ---------- PRODUCTO ----------
  Future<int> insertarProducto(Producto producto) async {
    if (kIsWeb) return 0;
    final db = await database;
    return await db.insert('producto', producto.toMap());
  }

  Future<int> actualizarProducto(Producto producto) async {
    if (kIsWeb) return 0;
    final db = await database;
    return await db.update('producto', producto.toMap(), where: 'id = ?', whereArgs: [producto.id]);
  }

  Future<int> eliminarProducto(int id) async {
    if (kIsWeb) return 0;
    final db = await database;
    return await db.delete('producto', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Producto>> obtenerProductos() async {
    if (kIsWeb) return [];
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('producto', orderBy: 'id DESC');
    return List.generate(maps.length, (i) => Producto.fromMap(maps[i]));
  }

  Future<Producto?> obtenerProductoPorId(int id) async {
    if (kIsWeb) return null;
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('producto', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Producto.fromMap(maps.first);
  }

  Future<bool> existeProductoConTitulo(String titulo, {int? excluirId}) async {
    if (kIsWeb) return false;
    final db = await database;
    final maps = await db.query('producto', where: excluirId != null ? 'LOWER(titulo) = ? AND id != ?' : 'LOWER(titulo) = ?', whereArgs: excluirId != null ? [titulo.toLowerCase().trim(), excluirId] : [titulo.toLowerCase().trim()]);
    return maps.isNotEmpty;
  }

  // ---------- COMPRA ----------
  Future<int> insertarCompra({required String correoUsuario, required double total, required String detalle, required String fecha, double? latitud, double? longitud}) async {
    if (kIsWeb) return 0;
    final db = await database;
    return await db.insert('compra', {'correo_usuario': correoUsuario, 'total': total, 'detalle': detalle, 'fecha': fecha, 'latitud': latitud, 'longitud': longitud});
  }

  Future<List<Map<String, dynamic>>> obtenerComprasPorUsuario(String correo) async {
    if (kIsWeb) return [];
    final db = await database;
    return await db.query('compra', where: 'correo_usuario = ?', whereArgs: [correo], orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> obtenerTodasLasCompras() async {
    if (kIsWeb) return [];
    final db = await database;
    return await db.query('compra', orderBy: 'id DESC');
  }

  Future<int> actualizarEstadoCompra(int id, String nuevoEstado) async {
    if (kIsWeb) return 0;
    final db = await database;
    return await db.update('compra', {'estado': nuevoEstado}, where: 'id = ?', whereArgs: [id]);
  }

  // ---------- PRODUCTOS XML ----------
  Future<void> limpiarProductosXML() async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('producto_xml');
  }

  Future<int> insertarProductoXML(ProductoXML producto) async {
    if (kIsWeb) return 0;
    final db = await database;
    return await db.insert('producto_xml', producto.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> insertarProductosXML(List<ProductoXML> productos) async {
    if (kIsWeb) return 0;
    final db = await database;
    final batch = db.batch();
    for (final p in productos) {
      batch.insert('producto_xml', p.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    final results = await batch.commit(noResult: false);
    return results.length;
  }

  Future<List<ProductoXML>> obtenerProductosXML() async {
    if (kIsWeb) return [];
    final db = await database;
    final maps = await db.query('producto_xml', orderBy: 'id_producto ASC');
    return maps.map((m) => ProductoXML.fromMap(m)).toList();
  }

  Future<List<ProductoXML>> buscarProductosXML(String texto) async {
    if (kIsWeb) return [];
    final db = await database;
    final maps = await db.query('producto_xml', where: 'LOWER(producto) LIKE ? OR LOWER(servicio) LIKE ?', whereArgs: ['%${texto.toLowerCase()}%', '%${texto.toLowerCase()}%'], orderBy: 'id_producto ASC');
    return maps.map((m) => ProductoXML.fromMap(m)).toList();
  }

  Future<int> contarProductosXML() async {
    if (kIsWeb) return 0;
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM producto_xml');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ---------- TRANSACCIONES ----------
  Future<int> insertarTransaccion(Map<String, dynamic> t) async {
    if (kIsWeb) return 0;
    final db = await database;
    return await db.insert('transaccion', t);
  }

  Future<List<Map<String, dynamic>>> obtenerTransacciones() async {
    if (kIsWeb) return [];
    final db = await database;
    return await db.query('transaccion', orderBy: 'id DESC');
  }
}