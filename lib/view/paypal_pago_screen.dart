import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaypalPagoScreen extends StatefulWidget {
  final double total;
  final String correoUsuario;
  final String descripcion;

  const PaypalPagoScreen({
    super.key,
    required this.total,
    required this.correoUsuario,
    required this.descripcion,
  });

  @override
  State<PaypalPagoScreen> createState() => _PaypalPagoScreenState();
}

class _PaypalPagoScreenState extends State<PaypalPagoScreen> {
  static const String _clientId =
      'BAAAxIK2HCScOHVBaY9II0uxa5U5aIDneUguvRHLpC3fSFV6kQbzESNtkgRv-jUABxY9BgQ3yNGPvYtup8';

  late final WebViewController _controller;
  bool _cargando = true;
  bool _pagoCompletado = false;

  @override
  void initState() {
    super.initState();
    _configurarWebView();
  }

  void _configurarWebView() {
    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>PayPal Checkout</title>
  <style>
    body {
      font-family: -apple-system, Roboto, sans-serif;
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      margin: 0;
      background: #fff;
      padding: 20px;
      box-sizing: border-box;
    }
    h2 { color: #003087; text-align: center; margin-bottom: 5px; }
    .desc { font-size: 14px; color: #666; margin-bottom: 5px; text-align: center; }
    .precio { font-size: 22px; font-weight: bold; color: #e91e63; margin-bottom: 20px; }
    #paypal-button-container { max-width: 400px; width: 90%; }
  </style>
  <script src="https://www.sandbox.paypal.com/sdk/js?client-id=$_clientId&currency=MXN"></script>
</head>
<body>
  <h2>Mi Tiendita</h2>
  <div class="desc">${widget.descripcion}</div>
  <div class="precio">\$${widget.total.toStringAsFixed(2)} MXN</div>
  <div id="paypal-button-container"></div>

  <script>
    window.onload = function() {
      paypal.Buttons({
        style: { layout: 'vertical', color: 'blue', shape: 'rect', label: 'paypal' },
        createOrder: function(data, actions) {
          return actions.order.create({
            purchase_units: [{
              amount: { value: '${widget.total.toStringAsFixed(2)}' },
              description: '${widget.descripcion}'
            }]
          });
        },
        onApprove: function(data, actions) {
          return actions.order.capture().then(function(details) {
            if (window.FlutterPayPal) {
              window.FlutterPayPal.postMessage('pagoExitoso:' + data.orderID);
            }
          });
        },
        onError: function(err) {
          if (window.FlutterPayPal) {
            window.FlutterPayPal.postMessage('pagoError:' + err.toString());
          }
        },
        onCancel: function(data) {
          if (window.FlutterPayPal) {
            window.FlutterPayPal.postMessage('pagoCancelado');
          }
        }
      }).render('#paypal-button-container');
    };
  </script>
</body>
</html>
''';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) setState(() => _cargando = true);
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _cargando = false);
          },
        ),
      );

    _controller.addJavaScriptChannel(
      'FlutterPayPal',
      onMessageReceived: (JavaScriptMessage message) {
        final data = message.message;
        if (data.startsWith('pagoExitoso')) {
          _mostrarExito();
        } else if (data.startsWith('pagoCancelado')) {
          if (mounted) Navigator.pop(context, false);
        }
      },
    );

    _controller.loadHtmlString(html, baseUrl: 'https://www.sandbox.paypal.com');
  }

  void _mostrarExito() {
    if (_pagoCompletado) return;
    _pagoCompletado = true;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 8),
              Text('¡Pago exitoso!'),
            ],
          ),
          content: Text(
            'Tu pago de \$${widget.total.toStringAsFixed(2)} MXN fue procesado.\n\n'
            'Presiona "Continuar" para finalizar.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003087),
                foregroundColor: Colors.white,
              ),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        title: const Text('Pagar con PayPal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context, false),
            tooltip: 'Cancelar',
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_cargando)
            const Center(
              child: CircularProgressIndicator(color: Colors.pink),
            ),
        ],
      ),
    );
  }
}