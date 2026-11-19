import 'dart:async';
import 'package:flutter/material.dart';
import '../service/usuario_service.dart';
import '../util/mail_helper.dart';
import 'nueva_password_screen.dart';

class VerificarOtpScreen extends StatefulWidget {
  final String correo;

  const VerificarOtpScreen({super.key, required this.correo});

  @override
  State<VerificarOtpScreen> createState() => _VerificarOtpScreenState();
}

class _VerificarOtpScreenState extends State<VerificarOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _servicio = UsuarioService();

  String? _mensajeError;
  bool _verificando = false;

  int _segundosRestantes = 60;
  Timer? _timer;
  bool _puedeReenviar = false;

  @override
  void initState() {
    super.initState();
    _iniciarTemporizador();
  }

  void _iniciarTemporizador() {
    _segundosRestantes = 60;
    _puedeReenviar = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_segundosRestantes <= 1) {
        t.cancel();
        setState(() {
          _puedeReenviar = true;
          _segundosRestantes = 0;
        });
      } else {
        setState(() => _segundosRestantes--);
      }
    });
  }

  Future<void> _verificar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _mensajeError = null;
      _verificando = true;
    });

    final codigo = _codigoController.text.trim();
    final valido = await _servicio.verificarOtp(widget.correo, codigo);

    if (!valido) {
      setState(() {
        _mensajeError = 'Código incorrecto o expirado';
        _verificando = false;
      });
      return;
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => NuevaPasswordScreen(correo: widget.correo),
        ),
      );
    }
  }

  Future<void> _reenviar() async {
    setState(() {
      _mensajeError = null;
      _verificando = true;
    });

    try {
      final codigo = _servicio.generarOtp();
      await _servicio.guardarOtp(widget.correo, codigo);
      await MailHelper.sendOtpEmail(widget.correo, codigo);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código reenviado')),
        );
      }
      _iniciarTemporizador();
    } catch (e) {
      setState(() => _mensajeError = 'Error al reenviar: $e');
    } finally {
      if (mounted) setState(() => _verificando = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codigoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(title: const Text('Verificar código')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 20),
              Icon(Icons.mark_email_read_outlined,
                  size: 80, color: Colors.pink.shade300),
              const SizedBox(height: 20),
              const Text(
                'Ingresa el código',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Enviamos un código de 6 dígitos a:\n${widget.correo}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _codigoController,
                decoration: const InputDecoration(
                  labelText: 'Código de 6 dígitos',
                  prefixIcon: Icon(Icons.pin_outlined),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Escribe el código';
                  }
                  if (v.trim().length != 6) {
                    return 'El código debe tener 6 dígitos';
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
                onPressed: _verificando ? null : _verificar,
                icon: const Icon(Icons.check_circle),
                label: Text(_verificando ? 'Verificando...' : 'Verificar código'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: (_puedeReenviar && !_verificando) ? _reenviar : null,
                child: Text(
                  _puedeReenviar
                      ? 'Reenviar código'
                      : 'Reenviar en $_segundosRestantes s',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}