import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../model/producto_xml.dart';
import '../service/punto_red_pago_service.dart';
import '../service/saldo_service.dart';
import 'punto_red_ticket_screen.dart';
import 'paypal_pago_screen.dart';

class PagarServicioScreen extends StatefulWidget {
  final ProductoXML producto;
  final String correoUsuario;

  const PagarServicioScreen({
    super.key,
    required this.producto,
    required this.correoUsuario,
  });

  @override
  State<PagarServicioScreen> createState() => _PagarServicioScreenState();
}

class _PagarServicioScreenState extends State<PagarServicioScreen> {
  final _refCtrl = TextEditingController();
  final _saldoService = SaldoService();
  bool _procesando = false;
  String? _error;

  final Color _bgColor = const Color(0xFFFFF0F5);
  final Color _pinkPrimary = const Color(0xFFE91E63);
  // Eliminamos _pinkLight porque no se estaba usando

  Future<void> _pagar() async {
    final ref = _refCtrl.text.trim();
    if (ref.length < 10) {
      setState(() => _error = 'Debes ingresar exactamente 10 dígitos');
      return;
    }

    setState(() {
      _procesando = true;
      _error = null;
    });

    try {
      final saldo = await _saldoService.obtenerSaldo();
      if (!mounted) return;
      if (saldo < widget.producto.precio) {
        throw Exception('Saldo insuficiente en PayPal (\$${saldo.toStringAsFixed(2)}).');
      }

      final bool? pagoExitoso = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaypalPagoScreen(
            total: widget.producto.precio,
            correoUsuario: widget.correoUsuario,
            descripcion: '${widget.producto.servicio}: ${widget.producto.producto}',
          ),
        ),
      );

      if (!mounted) return;
      if (pagoExitoso != true) {
        setState(() => _procesando = false);
        return;
      }

      await _saldoService.descontarSaldo(widget.producto.precio);
      if (!mounted) return;

      final tx = await PuntoRedPagoService.sendTx(
        producto: widget.producto,
        identificador: ref,
        usuarioCorreo: widget.correoUsuario,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PuntoRedTicketScreen(
            tx: tx,
            servicio: widget.producto.servicio,
            producto: widget.producto.producto,
            telefono: ref,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _procesando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Detalles de pago',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withValues(alpha: 0.08), // Corregido
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _bgColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.storefront, color: _pinkPrimary, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.producto.servicio.toUpperCase(),
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.producto.producto,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Divider(color: Colors.grey.shade200, thickness: 1),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total a pagar', style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
                        Text(
                          '\$${widget.producto.precio.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _pinkPrimary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  'Ingresa el número de referencia',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _refCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
                decoration: InputDecoration(
                  hintText: '0000000000',
                  hintStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 2),
                  prefixIcon: Icon(Icons.pin_outlined, color: _pinkPrimary),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: _pinkPrimary, width: 2)),
                ),
              ),
              const SizedBox(height: 40),
              Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink.shade400, Colors.pink.shade700],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withValues(alpha: 0.4), // Corregido
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: _procesando ? null : _pagar,
                  child: _procesando
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline, color: Colors.white),
                            SizedBox(width: 8),
                            Text('PAGAR CON PAYPAL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                          ],
                        ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 28),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_error!, style: const TextStyle(fontSize: 14, color: Colors.black87))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _refCtrl.dispose();
    super.dispose();
  }
}