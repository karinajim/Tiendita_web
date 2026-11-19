import 'package:flutter/material.dart';
import '../model/usuario.dart';
import '../model/rol.dart';
import '../service/usuario_service.dart';
import 'usuario_form_screen.dart';
import 'login_screen.dart';
import 'producto_list_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _servicio = UsuarioService();
  List<Usuario> _usuarios = [];
  List<Rol> _roles = [];
  int _totalUsuarios = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final usuarios = await _servicio.obtenerUsuarios();
    final roles = await _servicio.obtenerRoles();
    final total = await _servicio.contarUsuariosTotal();
    setState(() {
      _usuarios = usuarios;
      _roles = roles;
      _totalUsuarios = total;
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

  Future<void> _confirmarEliminar(Usuario usuario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text(
            '¿Seguro que quieres eliminar a ${usuario.nombre}? Esta acción no se puede deshacer.'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        title: const Text('Panel de Administrador'),
        actions: [
          IconButton(
            onPressed: _cerrarSesion,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Column(
        children: [
          // ---------- TARJETA "MODO ADMINISTRADOR" ----------
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
                const Icon(Icons.admin_panel_settings,
                    color: Colors.white, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Modo: Administrador',
                        style: TextStyle(
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

          // ---------- BOTÓN PARA IR A PRODUCTOS ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProductoListScreen()),
                  );
                },
                icon: const Icon(Icons.inventory_2),
                label: const Text('Gestionar Productos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ---------- LISTA DE USUARIOS ----------
          Expanded(
            child: _usuarios.isEmpty
                ? const Center(child: Text('Todavía no hay usuarios'))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: _usuarios.length,
                    itemBuilder: (context, index) {
                      final usuario = _usuarios[index];
                      final rol = _nombreDelRol(usuario.roleId);
                      final esUsuarioAdmin = rol == 'admin';

                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: esUsuarioAdmin
                                ? Colors.pink
                                : Colors.pink.shade100,
                            foregroundColor: esUsuarioAdmin
                                ? Colors.white
                                : Colors.pink.shade800,
                            child: Text(
                              usuario.nombre.isNotEmpty
                                  ? usuario.nombre[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(usuario.nombre,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(usuario.correo),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: esUsuarioAdmin
                                      ? Colors.pink.shade50
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: esUsuarioAdmin
                                        ? Colors.pink
                                        : Colors.grey,
                                  ),
                                ),
                                child: Text(
                                  rol,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: esUsuarioAdmin
                                        ? Colors.pink.shade700
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                tooltip: 'Eliminar',
                                onPressed: () => _confirmarEliminar(usuario),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const UsuarioFormScreen()),
          );
          _cargarDatos();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}