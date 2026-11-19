import 'package:flutter/material.dart';
import '../model/usuario.dart';
import '../model/rol.dart';
import '../service/usuario_service.dart';
import '../service/biometria_service.dart';
import '../service/productos_xml_service.dart'; // <-- IMPORTANTE: Agregamos el servicio de importación
import '../main.dart';
import '../widgets/banner_offline.dart';
import 'usuario_form_screen.dart';
import 'login_screen.dart';
import 'producto_list_screen.dart';
import 'pedido_list_screen.dart';
import 'productos_xml_list_screen.dart';
import 'usuario_screen.dart';

class UsuarioListScreen extends StatefulWidget {
  final String rolActual;

  const UsuarioListScreen({super.key, required this.rolActual});

  @override
  State<UsuarioListScreen> createState() => _UsuarioListScreenState();
}

class _UsuarioListScreenState extends State<UsuarioListScreen> {
  final _servicio = UsuarioService();
  List<Usuario> _usuarios = [];
  List<Rol> _roles = [];
  int _totalUsuarios = 0;
  
  Usuario? _adminUser; 
  String _nombreAdmin = 'Admin Sistema';
  String _correoAdmin = '';

  bool get _esAdmin => widget.rolActual == 'admin';

  @override
  void initState() {
    super.initState();
    if (_esAdmin) {
      _desactivarHuellaAdmin();
    }
    _cargarDatos();
  }

  Future<void> _desactivarHuellaAdmin() async {
    final biometria = BiometriaService();
    final correoGuardado = await biometria.obtenerCorreo();
    if (correoGuardado != null && correoGuardado.isNotEmpty) {
      await biometria.desactivar();
    }
  }

  Future<void> _cargarDatos() async {
    final usuarios = await _servicio.obtenerUsuarios();
    final roles = await _servicio.obtenerRoles();
    final total = await _servicio.contarUsuariosTotal();

    String nombreAdmin = 'Admin Sistema';
    String correoAdmin = '';
    Usuario? adminObj;

    if (_esAdmin) {
      final adminRol = roles.where((r) => r.rol == 'admin').toList();
      if (adminRol.isNotEmpty) {
        final admins = usuarios.where((u) => u.roleId == adminRol.first.id).toList();
        if (admins.isNotEmpty) {
          nombreAdmin = admins.first.nombre;
          correoAdmin = admins.first.correo;
          adminObj = admins.first; 
        }
      }
    }

    setState(() {
      _usuarios = usuarios;
      _roles = roles;
      _totalUsuarios = total;
      _nombreAdmin = nombreAdmin;
      _correoAdmin = correoAdmin;
      _adminUser = adminObj; 
    });
  }

  String _nombreDelRol(int roleId) {
    final rol = _roles.where((r) => r.id == roleId).toList();
    return rol.isNotEmpty ? rol.first.rol : 'Sin rol';
  }

  void _cerrarSesion() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _irAFormulario({Usuario? usuario}) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UsuarioFormScreen(usuarioAEditar: usuario),
      ),
    );
    if (resultado == true) _cargarDatos();
  }

  Future<void> _confirmarEliminar(Usuario usuario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text(
          '¿Seguro que quieres eliminar a ${usuario.nombre}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _servicio.eliminarUsuario(usuario.id!);
      _cargarDatos();
    }
  }

  // --- NUEVA FUNCIÓN PARA IMPORTAR PUNTO RED ---
  Future<void> _importarPuntoRed() async {
    // Mostramos un cuadro de diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: Colors.pink),
            SizedBox(width: 20),
            Text("Importando catálogo..."),
          ],
        ),
      ),
    );

    try {
      final servicio = ProductosXMLService();
      // Ejecutamos la carga desde el archivo assets/productos.xml
      final cantidad = await servicio.cargarDesdeAsset(); 

      if (!mounted) return;
      Navigator.pop(context); // Cerramos el cuadro de carga

      // Mostramos mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Se importaron $cantidad productos de Punto Red con éxito'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Cerramos el cuadro de carga
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al importar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _construirDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF8BBD0), Color(0xFFF48FB1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  child: Text(
                    _nombreAdmin.isNotEmpty
                        ? _nombreAdmin[0].toUpperCase()
                        : 'A',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFAD1457),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _nombreAdmin,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Administrador',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _itemDrawer(
            icono: Icons.inventory_2_outlined,
            titulo: 'Productos',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ProductoListScreen()),
              );
            },
          ),
          _itemDrawer(
            icono: Icons.people_outline,
            titulo: 'Gestionar Usuarios',
            subtitulo: 'Crear, editar, eliminar',
            onTap: () {
              Navigator.pop(context);
              _irAFormulario();
            },
          ),
          _itemDrawer(
            icono: Icons.receipt_long_outlined,
            titulo: 'Pedidos',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PedidoListScreen()),
              );
            },
          ),
          _itemDrawer(
            icono: Icons.bar_chart_outlined,
            titulo: 'Reportes',
            onTap: () {
              Navigator.pop(context);
              _mostrarProximamente();
            },
          ),
          const Divider(height: 20),
          
          // AQUÍ CONECTAMOS EL BOTÓN A LA FUNCIÓN REAL
          _itemDrawer(
            icono: Icons.cloud_download_outlined,
            titulo: 'Importar Punto Red',
            subtitulo: 'Cargar catálogo de servicios',
            onTap: () {
              Navigator.pop(context); // Cierra el menú
              _importarPuntoRed(); // Llama a la función de importación
            },
          ),
          
          _itemDrawer(
            icono: Icons.storefront_outlined,
            titulo: 'Catálogo Punto Red',
            subtitulo: 'Ver servicios importados',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductosXMLListScreen(
                    correoUsuario: _correoAdmin, 
                  ),
                ),
              );
            },
          ),
          const Divider(height: 20),
          _itemDrawer(
            icono: Icons.notifications_none_outlined,
            titulo: 'Notificaciones',
            onTap: () {
              Navigator.pop(context);
              _mostrarProximamente();
            },
          ),
          _itemDrawer(
            icono: Icons.person_outline,
            titulo: 'Mi perfil',
            onTap: () {
              Navigator.pop(context);
              if (_adminUser != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UsuarioScreen(usuarioActual: _adminUser!),
                  ),
                );
              } else {
                _mostrarProximamente();
              }
            },
          ),
          const Divider(height: 20),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Cerrar sesión',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _cerrarSesion();
            },
          ),
        ],
      ),
    );
  }

  Widget _itemDrawer({
    required IconData icono,
    required String titulo,
    String? subtitulo,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icono, color: const Color(0xFFEC407A)),
      title: Text(
        titulo,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitulo != null
          ? Text(
              subtitulo,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            )
          : null,
      onTap: onTap,
    );
  }

  void _mostrarProximamente() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Próximamente disponible'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        title: Text(_esAdmin ? 'Panel de Administrador' : 'Panel de Usuario'),
        actions: [
          IconButton(
            onPressed: _cerrarSesion,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      drawer: _esAdmin ? _construirDrawer() : null,
      body: Column(
        children: [
          BannerOffline(conexion: conexionService),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
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
                  child: Row(
                    children: [
                      Icon(
                        _esAdmin
                            ? Icons.admin_panel_settings
                            : Icons.person_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Modo: ${_esAdmin ? "Administrador" : "Usuario"}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Usuarios registrados: $_totalUsuarios',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Lista de usuarios',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      if (_esAdmin)
                        ElevatedButton.icon(
                          onPressed: () => _irAFormulario(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Agregar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ..._usuarios.map((u) {
                  final rol = _nombreDelRol(u.roleId);
                  final esAdmin = rol == 'admin';

                  return Card(
                    margin: const EdgeInsets.only(
                        bottom: 10, left: 12, right: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      leading: CircleAvatar(
                        backgroundColor: esAdmin
                            ? Colors.pink
                            : Colors.pink.shade100,
                        foregroundColor: esAdmin
                            ? Colors.white
                            : Colors.pink.shade800,
                        child: Text(
                          u.nombre.isNotEmpty
                              ? u.nombre[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(u.nombre,
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(u.correo),
                      trailing: _esAdmin
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: esAdmin
                                        ? Colors.pink.shade50
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: esAdmin
                                          ? Colors.pink
                                          : Colors.grey,
                                    ),
                                  ),
                                  child: Text(
                                    rol,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: esAdmin
                                          ? Colors.pink.shade700
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      color: Colors.blue),
                                  tooltip: 'Editar',
                                  onPressed: () => _irAFormulario(usuario: u),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  tooltip: 'Eliminar',
                                  onPressed: () => _confirmarEliminar(u),
                                ),
                              ],
                            )
                          : Text(
                              rol,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.pink.shade700,
                              ),
                            ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}