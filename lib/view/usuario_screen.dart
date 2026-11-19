import 'package:flutter/material.dart';
import '../model/usuario.dart';
import '../service/usuario_service.dart';
import '../service/biometria_service.dart';
import '../service/geolocalizacion_service.dart';
import '../service/saldo_service.dart';
import '../main.dart';
import '../widgets/banner_offline.dart';
import 'login_screen.dart';
import 'producto_tienda_screen.dart';
import 'mis_pedidos_screen.dart';
import 'editar_perfil_screen.dart';

class UsuarioScreen extends StatefulWidget {
  final Usuario usuarioActual;

  const UsuarioScreen({super.key, required this.usuarioActual});

  @override
  State<UsuarioScreen> createState() => _UsuarioScreenState();
}

class _UsuarioScreenState extends State<UsuarioScreen> {
  final _servicio = UsuarioService();
  final _biometriaService = BiometriaService();
  final _geoService = GeolocalizacionService();
  final _saldoService = SaldoService();
  
  String _nombreRol = 'usuario';
  late Usuario _usuario;
  bool _biometriaActivada = false;

  @override
  void initState() {
    super.initState();
    _usuario = widget.usuarioActual;
    _cargarRol();
    _cargarEstadoBiometria();
    _saldoService.cargarSaldo();
  }

  Future<void> _cargarRol() async {
    final rol = await _servicio.obtenerNombreRol(_usuario.roleId);
    setState(() => _nombreRol = rol);
  }

  Future<void> _cargarEstadoBiometria() async {
    final correoGuardado = await _biometriaService.obtenerCorreo();
    if (mounted) {
      setState(() {
        _biometriaActivada = correoGuardado == _usuario.correo;
      });
    }
  }

  Future<void> _toggleBiometria(bool activar) async {
    if (activar) {
      await _biometriaService.guardarCorreo(_usuario.correo);
      setState(() => _biometriaActivada = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Ingreso con huella activado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Desactivar huella'),
          content: const Text(
            '¿Seguro que quieres desactivar el ingreso con huella? Tendrás que iniciar sesión con tu correo y contraseña.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Desactivar'),
            ),
          ],
        ),
      );

      if (confirmar == true) {
        await _biometriaService.desactivar();
        setState(() => _biometriaActivada = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔓 Ingreso con huella desactivado'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  Future<void> _actualizarUbicacion() async {
    final posicion = await _geoService.obtenerUbicacion();

    if (posicion == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ No se pudo obtener la ubicación'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    await _servicio.actualizarUbicacionUsuario(
      id: _usuario.id!,
      latitud: posicion.latitude,
      longitud: posicion.longitude,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ Ubicación actualizada: ${posicion.latitude.toStringAsFixed(4)}, ${posicion.longitude.toStringAsFixed(4)}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _cerrarSesion() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _irAEditarPerfil() async {
    final resultado = await Navigator.push<Usuario>(
      context,
      MaterialPageRoute(
        builder: (context) => EditarPerfilScreen(usuarioActual: _usuario),
      ),
    );

    if (resultado != null) {
      setState(() => _usuario = resultado);
      _cargarEstadoBiometria();
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = _usuario;
    final esOscuro = temaService.modoOscuro;
    final colorTexto = esOscuro ? Colors.white : Colors.black87;
    final colorFondoCard = esOscuro ? const Color(0xFF2A2A2A) : Colors.white;
    final colorBorde = esOscuro ? Colors.pink.shade900 : Colors.pink.shade100;

    return AnimatedBuilder(
      animation: temaService,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Mi Perfil'),
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
              BannerOffline(conexion: conexionService),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorFondoCard,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 45,
                              backgroundColor: Colors.pink.shade100,
                              child: Text(
                                u.nombre.isNotEmpty
                                    ? u.nombre[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.pink.shade800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              u.nombre,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: colorTexto,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.pink.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.pink.shade200),
                              ),
                              child: Text(
                                'Rol: ${_nombreRol == 'admin' ? 'Administrador' : 'Usuario Estándar'}',
                                style: TextStyle(
                                  color: Colors.pink.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // TARJETA DE SALDO
                      AnimatedBuilder(
                        animation: _saldoService,
                        builder: (context, _) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorFondoCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colorBorde),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.paypal, color: Colors.blue),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Saldo disponible en PayPal',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: colorTexto,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        'Moneda: MXN',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '\$${_saldoService.saldo.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      ),
                      const SizedBox(height: 20),

                      _campoInfo('Nombre Completo', u.nombre, colorFondoCard,
                          colorBorde, colorTexto),
                      const SizedBox(height: 12),
                      _campoInfo('Correo Electrónico', u.correo, colorFondoCard,
                          colorBorde, colorTexto),
                      const SizedBox(height: 12),
                      _campoInfo('Contraseña', '••••••••', colorFondoCard,
                          colorBorde, colorTexto),
                      const SizedBox(height: 24),

                      // USO DE MATERIAL EN VEZ DE CONTAINER PARA EVITAR ERRORES
                      Material(
                        color: colorFondoCard,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: colorBorde),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SwitchListTile(
                          value: temaService.modoOscuro,
                          onChanged: (v) async {
                            await temaService.cambiarTema(v);
                          },
                          title: Text(
                            'Modo oscuro',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorTexto,
                            ),
                          ),
                          subtitle: Text(
                            'Cambia entre tema claro y oscuro',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500),
                          ),
                          activeThumbColor: Colors.pink,
                          secondary: Icon(
                            temaService.modoOscuro
                                ? Icons.dark_mode
                                : Icons.light_mode,
                            color: Colors.pink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Material(
                        color: colorFondoCard,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: colorBorde),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SwitchListTile(
                          value: _biometriaActivada,
                          onChanged: _toggleBiometria,
                          title: Text(
                            'Ingreso con huella',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorTexto,
                            ),
                          ),
                          subtitle: Text(
                            _biometriaActivada
                                ? 'Activado · Puedes usar tu huella para entrar'
                                : 'Desactivado · Usa correo y contraseña',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500),
                          ),
                          activeThumbColor: Colors.pink,
                          secondary: Icon(
                            Icons.fingerprint,
                            color: _biometriaActivada
                                ? Colors.pink
                                : Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Material(
                        color: colorFondoCard,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: colorBorde),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          leading: Icon(
                            Icons.location_on,
                            color: Colors.pink.shade600,
                            size: 32,
                          ),
                          title: Text(
                            'Mi ubicación',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorTexto,
                            ),
                          ),
                          subtitle: Text(
                            'Actualizar para futuras entregas',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_location_alt,
                                color: Colors.pink),
                            onPressed: _actualizarUbicacion,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _irAEditarPerfil,
                          icon: const Icon(Icons.edit),
                          label: const Text('Editar perfil'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductoTiendaScreen(
                                  correoUsuario: u.correo,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.storefront),
                          label: const Text('Ver tienda'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink.shade300,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MisPedidosScreen(
                                  correoUsuario: u.correo,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.receipt_long),
                          label: const Text('Mis Pedidos'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink.shade200,
                            foregroundColor: Colors.pink.shade900,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _cerrarSesion,
                          icon: const Icon(Icons.logout),
                          label: const Text('Cerrar sesión'),
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _campoInfo(
    String etiqueta,
    String valor,
    Color colorFondo,
    Color colorBorde,
    Color colorTexto,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorBorde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: TextStyle(
              color: Colors.pink.shade700,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(valor, style: TextStyle(fontSize: 15, color: colorTexto)),
        ],
      ),
    );
  }
}