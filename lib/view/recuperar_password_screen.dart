import 'package:flutter/material.dart';
import '../service/usuario_service.dart';
import '../util/mail_helper.dart';
import 'verificar_otp_screen.dart';

class RecuperarPasswordScreen extends StatefulWidget {
  const RecuperarPasswordScreen({super.key});

  @override
  State<RecuperarPasswordScreen> createState() =>
      _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState extends State<RecuperarPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _servicio = UsuarioService();

  String? _mensajeError;
  bool _enviando = false;

  @override
  void dispose() {
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _enviarCodigo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _mensajeError = null;
      _enviando = true;
    });

    final correo = _correoController.text.trim().toLowerCase();

    final existe = await _servicio.correoExiste(correo);
    if (!existe) {
      setState(() {
        _mensajeError = 'No existe una cuenta con ese correo';
        _enviando = false;
      });
      return;
    }

    final codigo = _servicio.generarOtp();
    await _servicio.guardarOtp(correo, codigo);

    try {
      await MailHelper.sendOtpEmail(correo, codigo);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerificarOtpScreen(correo: correo),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _mensajeError = 'Error al enviar el código: $e';
        _enviando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 20),
              Icon(Icons.lock_reset,
                  size: 80, color: Colors.pink.shade300),
              const SizedBox(height: 20),
              const Text(
                'Ingresa tu correo',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Te enviaremos un código de 6 dígitos para restablecer tu contraseña.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _correoController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Escribe tu correo';
                  }
                  if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$')
                      .hasMatch(v.trim())) {
                    return 'Correo inválido';
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
                onPressed: _enviando ? null : _enviarCodigo,
                icon: const Icon(Icons.send),
                label: Text(_enviando ? 'Enviando...' : 'Enviar código'),
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