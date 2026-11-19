import 'dart:math';
import '../database/database_helper.dart';
import '../model/usuario.dart';
import '../model/rol.dart';

class UsuarioService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> registrarUsuario(Usuario usuario) async {
    return await _dbHelper.insertarUsuario(usuario);
  }

  Future<int> actualizarUsuario(Usuario usuario) async {
    return await _dbHelper.actualizarUsuario(usuario);
  }

  Future<List<Usuario>> obtenerUsuarios() async {
    return await _dbHelper.obtenerUsuarios();
  }

  Future<int> registrarRol(Rol rol) async {
    return await _dbHelper.insertarRol(rol);
  }

  Future<List<Rol>> obtenerRoles() async {
    return await _dbHelper.obtenerRoles();
  }

  Future<Usuario?> login(String correo, String pass) async {
    return await _dbHelper.obtenerUsuarioPorCredenciales(correo, pass);
  }

  Future<String> obtenerNombreRol(int roleId) async {
    final roles = await obtenerRoles();
    final coincidencias = roles.where((r) => r.id == roleId).toList();
    return coincidencias.isNotEmpty ? coincidencias.first.rol : 'Sin rol';
  }

  Future<bool> correoExiste(String correo) async {
    final usuario = await _dbHelper.obtenerUsuarioPorCorreo(correo);
    return usuario != null;
  }

  Future<int> contarAdmins() async {
    final roles = await obtenerRoles();
    final adminRol = roles.where((r) => r.rol == 'admin').toList();
    if (adminRol.isEmpty) return 0;
    return await _dbHelper.contarUsuariosPorRol(adminRol.first.id!);
  }

  Future<int> contarUsuariosTotal() async {
    return await _dbHelper.contarUsuarios();
  }

  Future<int> eliminarUsuario(int id) async {
    return await _dbHelper.eliminarUsuario(id);
  }

  // ---------- OTP / RECUPERACIÓN ----------
  String generarOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<void> guardarOtp(String correo, String codigo) async {
    final ahora = DateTime.now();
    final expiracion = ahora.add(const Duration(minutes: 10));
    final expiracionStr = expiracion.toIso8601String();
    await _dbHelper.guardarCodigoOtp(correo, codigo, expiracionStr);
  }

  Future<bool> verificarOtp(String correo, String codigoIngresado) async {
    final datos = await _dbHelper.obtenerDatosOtp(correo);
    if (datos == null) return false;

    final codigoGuardado = datos['codigo_verificacion'] as String?;
    final expiracionStr = datos['codigo_expiracion'] as String?;

    if (codigoGuardado == null || expiracionStr == null) return false;
    if (codigoGuardado != codigoIngresado) return false;

    final expiracion = DateTime.tryParse(expiracionStr);
    if (expiracion == null) return false;
    if (DateTime.now().isAfter(expiracion)) return false;

    return true;
  }

  Future<void> cambiarPassword(String correo, String nuevaPass) async {
    await _dbHelper.actualizarPassword(correo, nuevaPass);
  }

  // ---------- EDITAR PERFIL ----------
  Future<bool> correoExisteEnOtroUsuario(String correo, int idActual) async {
    return await _dbHelper.correoExisteEnOtroUsuario(correo, idActual);
  }

  Future<void> actualizarPerfil({
    required int id,
    required String nombre,
    required String correo,
    required String pass,
  }) async {
    await _dbHelper.actualizarPerfil(id, nombre, correo, pass);
  }

  // ---------- OBTENER POR CORREO ----------
  Future<Usuario?> obtenerUsuarioPorCorreo(String correo) async {
    return await _dbHelper.obtenerUsuarioPorCorreo(correo);
  }

  // ---------- ACTUALIZAR UBICACIÓN ----------
  Future<void> actualizarUbicacionUsuario({
    required int id,
    required double latitud,
    required double longitud,
  }) async {
    await _dbHelper.actualizarUbicacionUsuario(id, latitud, longitud);
  }
}