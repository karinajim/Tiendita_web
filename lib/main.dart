import 'package:flutter/material.dart';
import 'view/login_screen.dart';
import 'service/usuario_service.dart';
import 'service/tema_service.dart';
import 'service/conexion_service.dart';
import 'service/productos_xml_service.dart';
import 'model/rol.dart';

final temaService = TemaService();
final conexionService = ConexionService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await temaService.cargarPreferencia();
  await _crearRolesIniciales();
  await _cargarProductosXML();
  runApp(const MiApp());
}

Future<void> _crearRolesIniciales() async {
  final servicio = UsuarioService();
  final roles = await servicio.obtenerRoles();

  if (roles.isEmpty) {
    await servicio.registrarRol(Rol(rol: 'usuario'));
    await servicio.registrarRol(Rol(rol: 'admin'));
  }
}

Future<void> _cargarProductosXML() async {
  try {
    final servicio = ProductosXMLService();
    final total = await servicio.contar();

    if (total == 0) {
      final cargados = await servicio.cargarDesdeAsset();
      debugPrint('✅ Se cargaron $cargados productos del XML');
    } else {
      debugPrint('📦 Ya hay $total productos en la BD');
    }
  } catch (e) {
    debugPrint('❌ Error al cargar productos XML: $e');
  }
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: temaService,
      builder: (context, _) {
        return MaterialApp(
          title: 'Gestión de usuarios',
          debugShowCheckedModeBanner: false,
          themeMode: temaService.themeMode,
          theme: _temaClaro(),
          darkTheme: _temaOscuro(),
          home: const LoginScreen(),
        );
      },
    );
  }

  ThemeData _temaClaro() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.pink,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFFFF0F5),
      cardColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  ThemeData _temaOscuro() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.pink,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      cardColor: const Color(0xFF2A2A2A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFAD1457),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFAD1457),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}