import 'package:flutter/material.dart';
import '../model/usuario.dart';
import '../model/rol.dart';
import '../service/usuario_service.dart';

class UsuarioFormScreen extends StatefulWidget {
  final Usuario? usuarioAEditar;

  const UsuarioFormScreen({super.key, this.usuarioAEditar});

  @override
  State<UsuarioFormScreen> createState() => _UsuarioFormScreenState();
}

class _UsuarioFormScreenState extends State<UsuarioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _servicio = UsuarioService();

  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _passController = TextEditingController();

  List<Rol> _roles = [];
  int? _roleIdSeleccionado;

  int _adminsExistentes = 0;
  bool get _adminBloqueado => _adminsExistentes >= 2;
  bool get _esEdicion => widget.usuarioAEditar != null;

  String? _mensajeError;
  bool _guardando = false;
  bool _verPass = false;

  @override
  void initState() {
    super.initState();
    _cargarRolesYAdmins();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _cargarRolesYAdmins() async {
    final lista = await _servicio.obtenerRoles();
    final totalAdmins = await _servicio.contarAdmins();

    setState(() {
      _roles = lista;
      _adminsExistentes = totalAdmins;

      if (_esEdicion) {
        final u = widget.usuarioAEditar!;
        _nombreController.text = u.nombre;
        _correoController.text = u.correo;
        _passController.text = u.pass;
        _roleIdSeleccionado = u.roleId;
      } else {
        final usuarioRol = lista.where((r) => r.rol == 'usuario').toList();
        _roleIdSeleccionado = usuarioRol.isNotEmpty
            ? usuarioRol.first.id
            : (lista.isNotEmpty ? lista.first.id : null);
      }
    });
  }

  bool _esRolAdmin(int? roleId) {
    if (roleId == null) return false;
    return _roles.any((r) => r.id == roleId && r.rol == 'admin');
  }

  // ---------- VALIDACIÓN DE NOMBRE ----------
  String? _validarNombre(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Escribe tu nombre completo';
    }

    final nombre = valor.trim();

    // Mínimo 5 caracteres
    if (nombre.length < 5) {
      return 'Mínimo 5 caracteres (ej. "Juan Pérez")';
    }

    // Máximo 36 caracteres
    if (nombre.length > 36) {
      return 'Máximo 36 caracteres (tienes ${nombre.length})';
    }

    // Debe tener al menos un espacio (nombre y apellido)
    if (!nombre.contains(' ')) {
      return 'Escribe nombre y apellido (ej. "Juan Pérez")';
    }

    // Cada palabra debe tener al menos 2 caracteres
    final palabras =
        nombre.split(' ').where((p) => p.trim().isNotEmpty).toList();
    if (palabras.length < 2) {
      return 'Escribe nombre y apellido';
    }
    for (final palabra in palabras) {
      if (palabra.length < 2) {
        return 'Cada nombre debe tener al menos 2 letras';
      }
    }

    // Solo letras y espacios (sin números ni símbolos)
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$').hasMatch(nombre)) {
      return 'Solo se permiten letras y espacios';
    }

    return null;
  }

  // ---------- VALIDACIÓN DE PASSWORD ----------
  String? _validarPassword(String? valor) {
    if (valor == null || valor.isEmpty) return 'Escribe una contraseña';
    if (valor.length < 8) return 'Mínimo 8 caracteres';
    if (!RegExp(r'[A-Z]').hasMatch(valor)) return 'Al menos 1 mayúscula';
    if (!RegExp(r'[a-z]').hasMatch(valor)) return 'Al menos 1 minúscula';
    if (!RegExp(r'[0-9]').hasMatch(valor)) return 'Al menos 1 número';
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=]').hasMatch(valor)) {
      return 'Al menos 1 carácter especial';
    }
    return null;
  }

  Future<void> _guardarUsuario() async {
    if (!_formKey.currentState!.validate()) return;
    if (_roleIdSeleccionado == null) return;

    setState(() {
      _mensajeError = null;
      _guardando = true;
    });

    final yaExiste = await _servicio.correoExiste(_correoController.text.trim());
    if (yaExiste) {
      final mismoCorreo = _esEdicion &&
          widget.usuarioAEditar!.correo == _correoController.text.trim();
      if (!mismoCorreo) {
        setState(() {
          _mensajeError = 'Ese correo ya está registrado';
          _guardando = false;
        });
        return;
      }
    }

    if (_esRolAdmin(_roleIdSeleccionado)) {
      final totalAdmins = await _servicio.contarAdmins();
      final eraAdminAntes = _esEdicion &&
          _roles.any((r) =>
              r.id == widget.usuarioAEditar!.roleId && r.rol == 'admin');

      if (totalAdmins >= 2 && !eraAdminAntes) {
        setState(() {
          _mensajeError = 'Ya existen 2 administradores. Elige el rol "usuario".';
          _guardando = false;
          _adminsExistentes = totalAdmins;
        });
        return;
      }
    }

    final usuario = Usuario(
      id: widget.usuarioAEditar?.id,
      nombre: _nombreController.text.trim(),
      correo: _correoController.text.trim(),
      pass: _passController.text,
      roleId: _roleIdSeleccionado!,
    );

    try {
      if (_esEdicion) {
        await _servicio.actualizarUsuario(usuario);
      } else {
        await _servicio.registrarUsuario(usuario);
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
        title: Text(_esEdicion ? 'Editar usuario' : 'Registrar usuario'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ---------- NOMBRE ----------
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: const Icon(Icons.person_outline),
                  helperText: 'Nombre y apellido (5-36 caracteres)',
                  counterText: '${_nombreController.text.length}/36',
                ),
                maxLength: 36,
                onChanged: (_) => setState(() {}),
                validator: _validarNombre,
              ),
              const SizedBox(height: 12),

              // ---------- CORREO ----------
              TextFormField(
                controller: _correoController,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Escribe un correo';
                  if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$')
                      .hasMatch(v.trim())) {
                    return 'Correo inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // ---------- CONTRASEÑA ----------
              TextFormField(
                controller: _passController,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  helperText:
                      'Mín. 8 caracteres, 1 mayúscula, 1 minúscula, 1 número y 1 carácter especial',
                  helperMaxLines: 3,
                  suffixIcon: IconButton(
                    icon: Icon(
                        _verPass ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _verPass = !_verPass),
                  ),
                ),
                obscureText: !_verPass,
                validator: _validarPassword,
              ),
              const SizedBox(height: 12),

              // ---------- ROL ----------
              _roles.isEmpty
                  ? const Text('No hay roles disponibles todavía')
                  : _construirDropdownRol(),

              if (_adminBloqueado && !_esEdicion) ...[
                const SizedBox(height: 8),
                Text(
                  'Ya existen 2 administradores. El rol "admin" está deshabilitado.',
                  style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                ),
              ],

              if (_mensajeError != null) ...[
                const SizedBox(height: 12),
                Text(_mensajeError!,
                    style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _guardando ? null : _guardarUsuario,
                child: Text(
                  _guardando
                      ? 'Guardando...'
                      : (_esEdicion ? 'Guardar cambios' : 'Registrar usuario'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirDropdownRol() {
    final rolesDisponibles = (!_esEdicion && _adminBloqueado)
        ? _roles.where((r) => r.rol != 'admin').toList()
        : _roles;

    if (!rolesDisponibles.any((r) => r.id == _roleIdSeleccionado)) {
      _roleIdSeleccionado =
          rolesDisponibles.isNotEmpty ? rolesDisponibles.first.id : null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int>(
          key: ValueKey(_roleIdSeleccionado),
          initialValue: _roleIdSeleccionado,
          decoration: const InputDecoration(labelText: 'Rol'),
          isExpanded: true,
          items: rolesDisponibles.map((rol) {
            return DropdownMenuItem<int>(
              value: rol.id,
              child: Text(rol.rol),
            );
          }).toList(),
          onChanged: (valor) {
            setState(() {
              _roleIdSeleccionado = valor;
              _mensajeError = null;
            });
          },
        ),
        if (!_esEdicion && _adminBloqueado) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                const Text('admin', style: TextStyle(color: Colors.grey)),
                const Spacer(),
                Text(
                  'No disponible',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}