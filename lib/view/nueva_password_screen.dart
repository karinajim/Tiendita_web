import 'package:flutter/material.dart';
import '../service/usuario_service.dart';

class NuevaPasswordScreen extends StatefulWidget {
  final String correo;

  const NuevaPasswordScreen({super.key, required this.correo});

  @override
  State<NuevaPasswordScreen> createState() => _NuevaPasswordScreenState();
}

class _NuevaPasswordScreenState extends State<NuevaPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();
  final _servicio = UsuarioService();

  String? _mensajeError;
  bool _guardando = false;
  bool _verPass = false;
  bool _verConfirm = false;

  @override
  void dispose() {
    _passController.dispose();
    _confirmController.dispose();
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

    if (_passController.text != _confirmController.text) {
      setState(() => _mensajeError = 'Las contraseñas no coinciden');
      return;
    }

    setState(() {
      _mensajeError = null;
      _guardando = true;
    });

    try {
      await _servicio.cambiarPassword(widget.correo, _passController.text);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('¡Contraseña actualizada!'),
            content: const Text(
                'Ya puedes iniciar sesión con tu nueva contraseña.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  // Regresar al Login (borrar historial)
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Ir al Login'),
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
      appBar: AppBar(title: const Text('Nueva contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 20),
              Icon(Icons.password, size: 80, color: Colors.pink.shade300),
              const SizedBox(height: 20),
              const Text(
                'Crea tu nueva contraseña',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Debe tener al menos 8 caracteres, 1 mayúscula, 1 minúscula, 1 número y 1 carácter especial.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _passController,
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
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
              TextFormField(
                controller: _confirmController,
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _verConfirm ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _verConfirm = !_verConfirm),
                  ),
                ),
                obscureText: !_verConfirm,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Confirma la contraseña';
                  if (v != _passController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              if (_mensajeError != null) ...[
                const SizedBox(height: 12),
                Text(_mensajeError!,
                    style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: const Icon(Icons.save),
                label: Text(_guardando ? 'Guardando...' : 'Guardar contraseña'),
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