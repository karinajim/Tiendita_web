import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class HistorialTransaccionesScreen extends StatefulWidget {
  const HistorialTransaccionesScreen({super.key});

  @override
  State<HistorialTransaccionesScreen> createState() =>
      _HistorialTransaccionesScreenState();
}

class _HistorialTransaccionesScreenState
    extends State<HistorialTransaccionesScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final lista = await DatabaseHelper().obtenerTransacciones();
    setState(() {
      _items = lista;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(title: const Text('Historial de transacciones')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : _items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 80, color: Colors.pink),
                      SizedBox(height: 12),
                      Text('Todavía no hay transacciones exitosas'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final t = _items[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.check, color: Colors.white),
                        ),
                        title: Text(
                          t['producto'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('🏢 ${t['servicio']}'),
                            Text('📱 ${t['telefono']}'),
                            Text('📅 ${t['fecha']}'),
                            if (t['num_autorizacion'] != null)
                              Text('Autorización: ${t['num_autorizacion']}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600)),
                          ],
                        ),
                        trailing: Text(
                          '\$${(t['precio'] as num).toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.pink.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}