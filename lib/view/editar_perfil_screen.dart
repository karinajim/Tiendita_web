import 'package:flutter/material.dart';
import '../model/usuario.dart';
import '../service/usuario_service.dart';

class EditarPerfilScreen extends StatefulWidget {
  final Usuario usuarioActual;

  const EditarPerfilScreen({super.key, required this.usuarioActual});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _servicio = UsuarioService();

  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _passActualController = TextEditingController();
  final _passNuevaController = TextEditingController();
  final _passConfirmarController = TextEditingController();

  bool _cambiarPassword = false;
  bool _verPassActual = false;
  bool _verPassNueva = false;
  bool _verPassConfirmar = false;
  bool _guardando = false;
  String? _mensajeError;

  @override
  void initState() {
    super.initState();
    _nombreController.text = widget.usuarioActual.nombre;
    _correoController.text = widget.usuarioActual.correo;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _passActualController.dispose();
    _passNuevaController.dispose();
    _passConfirmarController.dispose();
    super.dispose();
  }

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

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _mensajeError = null;
      _guardando = true;
    });

    final nombre = _nombreController.text.trim();
    final correo = _correoController.text.trim().toLowerCase();
    final idActual = widget.usuarioActual.id!;

    // Verificar correo duplicado
    if (correo != widget.usuarioActual.correo.toLowerCase()) {
      final duplicado =
          await _servicio.correoExisteEnOtroUsuario(correo, idActual);
      if (duplicado) {
        setState(() {
          _mensajeError = 'Ese correo ya está registrado por otro usuario';
          _guardando = false;
        });
        return;
      }
    }

    // Determinar la contraseña final
    String passFinal = widget.usuarioActual.pass;

    if (_cambiarPassword) {
      // Verificar contraseña actual
      if (_passActualController.text != widget.usuarioActual.pass) {
        setState(() {
          _mensajeError = 'La contraseña actual es incorrecta';
          _guardando = false;
        });
        return;
      }
      passFinal = _passNuevaController.text;
    }

    try {
      await _servicio.actualizarPerfil(
        id: idActual,
        nombre: nombre,
        correo: correo,
        pass: passFinal,
      );

      // Actualizar el objeto usuario en memoria
      final usuarioActualizado = Usuario(
        id: widget.usuarioActual.id,
        nombre: nombre,
        correo: correo,
        pass: passFinal,
        roleId: widget.usuarioActual.roleId,
        desc: widget.usuarioActual.desc,
        tokenRecuperacion: widget.usuarioActual.tokenRecuperacion,
        tokenExpiracion: widget.usuarioActual.tokenExpiracion,
        codigoVerificacion: widget.usuarioActual.codigoVerificacion,
        codigoExpiracion: widget.usuarioActual.codigoExpiracion,
        createdAt: widget.usuarioActual.createdAt,
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('¡Perfil actualizado!'),
            content: const Text('Tus cambios se guardaron correctamente.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context, usuarioActualizado);
                },
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _mensajeError = 'Error al guardar: $e';
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(title: const Text('Editar Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ---------- NOMBRE ----------
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Escribe tu nombre';
                  }
                  if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                  if (v.trim().length > 100) return 'Máximo 100 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // ---------- CORREO ----------
              TextFormField(
                controller: _correoController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Escribe tu correo';
                  if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$')
                      .hasMatch(v.trim())) {
                    return 'Correo inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // ---------- SWITCH CAMBIAR CONTRASEÑA ----------
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.pink.shade100),
                ),
                child: SwitchListTile(
                  value: _cambiarPassword,
                  onChanged: (v) {
                    setState(() {
                      _cambiarPassword = v;
                      if (!v) {
                        _passActualController.clear();
                        _passNuevaController.clear();
                        _passConfirmarController.clear();
                      }
                    });
                  },
                  title: const Text(
                    'Cambiar contraseña',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Activa esta opción para cambiar tu contraseña',
                    style: TextStyle(fontSize: 12),
                  ),
                  activeThumbColor: Colors.pink,
                ),
              ),

              // ---------- CAMPOS DE CONTRASEÑA ----------
              if (_cambiarPassword) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passActualController,
                  decoration: InputDecoration(
                    labelText: 'Contraseña actual',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_verPassActual
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => _verPassActual = !_verPassActual),
                    ),
                  ),
                  obscureText: !_verPassActual,
                  validator: (v) {
                    if (!_cambiarPassword) return null;
                    if (v == null || v.isEmpty) return 'Escribe tu actual';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passNuevaController,
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    helperText: 'Mín. 8 chars, 1 mayús, 1 minús, 1 núm, 1 especial',
                    helperMaxLines: 2,
                    suffixIcon: IconButton(
                      icon: Icon(_verPassNueva
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => _verPassNueva = !_verPassNueva),
                    ),
                  ),
                  obscureText: !_verPassNueva,
                  validator: (v) {
                    if (!_cambiarPassword) return null;
                    return _validarPassword(v);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passConfirmarController,
                  decoration: InputDecoration(
                    labelText: 'Confirmar nueva contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_verPassConfirmar
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => setState(
                          () => _verPassConfirmar = !_verPassConfirmar),
                    ),
                  ),
                  obscureText: !_verPassConfirmar,
                  validator: (v) {
                    if (!_cambiarPassword) return null;
                    if (v == null || v.isEmpty) return 'Confirma la contraseña';
                    if (v != _passNuevaController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
              ],

              if (_mensajeError != null) ...[
                const SizedBox(height: 12),
                Text(_mensajeError!,
                    style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: const Icon(Icons.save),
                label: Text(_guardando ? 'Guardando...' : 'Guardar cambios'),
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