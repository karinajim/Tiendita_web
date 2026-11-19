import 'package:flutter/material.dart';
import '../model/usuario.dart';
import '../service/usuario_service.dart';
import '../service/biometria_service.dart';
import '../service/google_auth_service.dart';
import '../main.dart';
import '../widgets/banner_offline.dart';
import 'usuario_form_screen.dart';
import 'usuario_list_screen.dart';
import 'usuario_screen.dart';
import 'recuperar_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _servicio = UsuarioService();
  final _biometriaService = BiometriaService();
  final _googleService = GoogleAuthService();

  final _correoController = TextEditingController();
  final _passController = TextEditingController();

  String? _mensajeError;
  bool _cargando = false;
  bool _verPass = false;
  bool _biometriaDisponible = false;
  bool _biometriaActivada = false;

  @override
  void initState() {
    super.initState();
    _verificarBiometria();
  }

  Future<void> _verificarBiometria() async {
    final disponible = await _biometriaService.soportaBiometria();
    final activada = await _biometriaService.estaActivada();

    if (mounted) {
      setState(() {
        _biometriaDisponible = disponible;
        _biometriaActivada = activada && disponible;

        if (activada) {
          _biometriaService.obtenerCorreo().then((correo) {
            if (correo != null && mounted) {
              _correoController.text = correo;
            }
          });
        }
      });
    }
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _mensajeError = null;
    });

    final usuario = await _servicio.login(
      _correoController.text.trim(),
      _passController.text,
    );

    if (usuario == null) {
      setState(() {
        _mensajeError = 'Correo o contraseña incorrectos';
        _cargando = false;
      });
      return;
    }

    await _postLogin(usuario);
  }

  Future<void> _iniciarConHuella() async {
    if (!_biometriaDisponible || !_biometriaActivada) return;

    final correo = await _biometriaService.obtenerCorreo();
    if (correo == null) return;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fingerprint, size: 60, color: Colors.pink),
                  SizedBox(height: 16),
                  Text('Verificando huella...'),
                  SizedBox(height: 16),
                  CircularProgressIndicator(color: Colors.pink),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final autenticado = await _biometriaService.autenticar();
    if (mounted) Navigator.pop(context);
    if (!autenticado) return;

    final usuario = await _servicio.obtenerUsuarioPorCorreo(correo);
    if (usuario == null) {
      if (mounted) setState(() => _mensajeError = 'Usuario no encontrado');
      return;
    }

    await _postLogin(usuario);
  }

  Future<void> _iniciarConGoogle() async {
    setState(() {
      _cargando = true;
      _mensajeError = null;
    });

    try {
      final confirmar = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: const Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4285F4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Iniciar sesión con Google',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Elige una cuenta para continuar en Mi Tiendita:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.pink.shade100,
                      child: const Text(
                        'G',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.pink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Usuario Google',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'usuario.google@gmail.com',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4285F4),
                foregroundColor: Colors.white,
              ),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );

      if (confirmar != true) {
        setState(() => _cargando = false);
        return;
      }

      final resultado = await _googleService.iniciarSesionConGoogle();

      if (resultado == null) {
        setState(() {
          _mensajeError = 'Inicio de sesión cancelado';
          _cargando = false;
        });
        return;
      }

      final correoGoogle = resultado['correo']!;
      final nombreGoogle = resultado['nombre']!;

      final usuarioExistente =
          await _servicio.obtenerUsuarioPorCorreo(correoGoogle);

      if (usuarioExistente != null) {
        await _postLogin(usuarioExistente);
      } else {
        final rolUsuario = await _servicio.obtenerRoles();
        final rolUser =
            rolUsuario.where((r) => r.rol == 'usuario').toList();
        if (rolUser.isEmpty) {
          setState(() {
            _mensajeError = 'Error: no hay rol de usuario';
            _cargando = false;
          });
          return;
        }

        final nuevoUsuario = Usuario(
          nombre: nombreGoogle,
          correo: correoGoogle,
          pass: 'GoogleAuth123!',
          roleId: rolUser.first.id!,
        );

        await _servicio.registrarUsuario(nuevoUsuario);

        final usuarioCreado =
            await _servicio.obtenerUsuarioPorCorreo(correoGoogle);

        if (usuarioCreado != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Cuenta creada con Google'),
                backgroundColor: Colors.green,
              ),
            );
          }
          await _postLogin(usuarioCreado);
        }
      }
    } catch (e) {
      setState(() {
        _mensajeError = 'Error con Google: $e';
        _cargando = false;
      });
    }
  }

  Future<void> _postLogin(Usuario usuario) async {
    final nombreRol = await _servicio.obtenerNombreRol(usuario.roleId);

    if (!mounted) return;

    // SOLO mostrar activación de huella si NO es admin
    if (_biometriaDisponible && !_biometriaActivada && nombreRol != 'admin') {
      final quiereActivar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.fingerprint, color: Colors.pink),
              SizedBox(width: 8),
              Text('Ingreso con huella'),
            ],
          ),
          content: const Text(
            '¿Quieres activar el ingreso rápido con tu huella dactilar para la próxima vez?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Ahora no'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
              ),
              child: const Text('Activar'),
            ),
          ],
        ),
      );

      if (quiereActivar == true) {
        await _biometriaService.guardarCorreo(usuario.correo);
      }
    }

    // Si es admin, asegurarse que la huella esté desactivada
    if (nombreRol == 'admin') {
      await _biometriaService.desactivar();
    }

    _redirigirSegunRol(nombreRol, usuario);
  }

  void _redirigirSegunRol(String nombreRol, usuario) {
    if (nombreRol == 'admin') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const UsuarioListScreen(rolActual: 'admin'),
        ),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => UsuarioScreen(usuarioActual: usuario),
        ),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _correoController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: Column(
        children: [
          BannerOffline(conexion: conexionService),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const SizedBox(height: 20),
                    Icon(Icons.lock_person,
                        size: 80, color: Colors.pink.shade300),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _correoController,
                      decoration: const InputDecoration(
                        labelText: 'Correo',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Escribe tu correo' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passController,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_verPass
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () =>
                              setState(() => _verPass = !_verPass),
                        ),
                      ),
                      obscureText: !_verPass,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Escribe tu contraseña'
                          : null,
                    ),
                    if (_mensajeError != null) ...[
                      const SizedBox(height: 12),
                      Text(_mensajeError!,
                          style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const RecuperarPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text('¿Olvidaste tu contraseña?'),
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (_biometriaDisponible && _biometriaActivada) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _cargando ? null : _iniciarConHuella,
                        icon: const Icon(Icons.fingerprint,
                            color: Colors.pink),
                        label: const Text(
                          'Ingresar con huella',
                          style: TextStyle(
                            color: Colors.pink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.pink),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _cargando ? null : _iniciarSesion,
                      icon: const Icon(Icons.login),
                      label: Text(
                          _cargando ? 'Entrando...' : 'Iniciar sesión'),
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

                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'o',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed: _cargando ? null : _iniciarConGoogle,
                      icon: const Icon(
                        Icons.g_mobiledata,
                        size: 28,
                        color: Color(0xFF4285F4),
                      ),
                      label: const Text(
                        'Iniciar sesión con Google',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const UsuarioFormScreen()),
                        );
                      },
                      child: const Text('¿No tienes cuenta? Regístrate aquí'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}