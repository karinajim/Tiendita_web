import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class MailHelper {
  static const String _username = 'jkarinacarrillo42@gmail.com';
  static const String _password = 'lfepbekiyhjkwqou'; // 👈 Nueva, SIN espacios

  static final smtpServer = gmail(_username, _password);

  static Future<void> sendEmail(
    String destino,
    String asunto,
    String mensaje, {
    String? htmlContent,
  }) async {
    final message = Message()
      ..from = Address(_username, 'Mi Tiendita')
      ..recipients.add(destino)
      ..subject = asunto
      ..text = mensaje
      ..html = htmlContent ?? "<p style='font-family: Roboto;'>$mensaje</p>";

    try {
      await send(message, smtpServer);
      debugPrint('✅ Correo enviado a $destino');
    } catch (e) {
      debugPrint('❌ Error al enviar correo: $e');
      rethrow;
    }
  }

  static Future<void> sendPurchaseSummaryEmail(
    String destino,
    List<Map<String, dynamic>> productos,
    double total,
  ) async {
    final ahora = DateTime.now();
    final fecha =
        '${ahora.day.toString().padLeft(2, '0')}/${ahora.month.toString().padLeft(2, '0')}/${ahora.year} '
        '${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}';

    final asunto = 'Resumen de tu compra - Mi Tiendita';
    final htmlContent = """
    <html>
      <body style="font-family: Roboto, sans-serif; color: #333;">
        <div style="max-width: 600px; margin: auto; padding: 20px; border: 1px solid #f8bbd0; border-radius: 12px;">
          <h1 style="color: #e91e63; text-align: center;">¡Gracias por tu compra!</h1>
          <p><strong>Fecha y hora:</strong> $fecha</p>
          <p>Aquí tienes el resumen de tu pedido:</p>

          <table border="1" cellpadding="10" cellspacing="0" style="width: 100%; border-collapse: collapse;">
            <thead style="background-color: #fce4ec; color: #333;">
              <tr>
                <th>Producto</th>
                <th>Cantidad</th>
                <th>Precio Unitario</th>
                <th>Subtotal</th>
              </tr>
            </thead>
            <tbody>
              ${productos.map((p) => """
              <tr style="text-align: center;">
                <td>${p['titulo']}</td>
                <td>${p['cantidad']}</td>
                <td>\$${(p['precio'] as num).toStringAsFixed(2)}</td>
                <td>\$${((p['precio'] as num) * (p['cantidad'] as num)).toStringAsFixed(2)}</td>
              </tr>
              """).join('')}
            </tbody>
          </table>

          <h2 style="color: #e91e63;">Total: \$${total.toStringAsFixed(2)} MXN</h2>

          <p style="text-align: center; font-size: 12px; color: #777;">
            Si tienes dudas, responde a este correo.
          </p>
        </div>
      </body>
    </html>
    """;

    await sendEmail(destino, asunto, 'Gracias por tu compra',
        htmlContent: htmlContent);
  }

  static Future<void> sendNewOrderNotificationToAdmin(
    String correoAdmin,
    String correoCliente,
    List<Map<String, dynamic>> productos,
    double total,
  ) async {
    final ahora = DateTime.now();
    final fecha =
        '${ahora.day.toString().padLeft(2, '0')}/${ahora.month.toString().padLeft(2, '0')}/${ahora.year} '
        '${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}';

    final asunto = '🔔 Nuevo pedido recibido - Mi Tiendita';
    final htmlContent = """
    <html>
      <body style="font-family: Roboto, sans-serif; color: #333;">
        <div style="max-width: 600px; margin: auto; padding: 20px; border: 1px solid #f8bbd0; border-radius: 12px;">
          <h1 style="color: #e91e63; text-align: center;">🔔 Nuevo Pedido</h1>
          <p><strong>Fecha y hora:</strong> $fecha</p>
          <p><strong>Cliente:</strong> $correoCliente</p>

          <h2>Productos solicitados</h2>
          <table border="1" cellpadding="10" cellspacing="0" style="width: 100%; border-collapse: collapse;">
            <thead style="background-color: #fce4ec; color: #333;">
              <tr>
                <th>Producto</th>
                <th>Cantidad</th>
                <th>Precio</th>
                <th>Subtotal</th>
              </tr>
            </thead>
            <tbody>
              ${productos.map((p) => """
              <tr style="text-align: center;">
                <td>${p['titulo']}</td>
                <td>${p['cantidad']}</td>
                <td>\$${(p['precio'] as num).toStringAsFixed(2)}</td>
                <td>\$${((p['precio'] as num) * (p['cantidad'] as num)).toStringAsFixed(2)}</td>
              </tr>
              """).join('')}
            </tbody>
          </table>

          <h2 style="color: #e91e63;">Total del pedido: \$${total.toStringAsFixed(2)} MXN</h2>

          <p>Ingresa al panel de administrador para gestionar este pedido.</p>

          <p style="text-align: center; font-size: 12px; color: #777;">
            Mi Tiendita - Sistema de pedidos
          </p>
        </div>
      </body>
    </html>
    """;

    await sendEmail(correoAdmin, asunto, 'Nuevo pedido recibido',
        htmlContent: htmlContent);
  }
    static Future<void> sendOtpEmail(
    String destino,
    String codigo,
  ) async {
    final asunto = 'Código de recuperación - Mi Tiendita';
    final htmlContent = """
    <html>
      <body style="font-family: Roboto, sans-serif; color: #333;">
        <div style="max-width: 600px; margin: auto; padding: 20px; border: 1px solid #f8bbd0; border-radius: 12px;">
          <h1 style="color: #e91e63; text-align: center;">Recuperación de contraseña</h1>
          <p>Has solicitado restablecer tu contraseña.</p>
          <p>Usa el siguiente código para continuar:</p>

          <div style="text-align: center; margin: 30px 0;">
            <span style="display: inline-block; padding: 15px 30px; background: #fce4ec; border: 2px solid #e91e63; border-radius: 12px; font-size: 32px; font-weight: bold; color: #e91e63; letter-spacing: 8px;">
              $codigo
            </span>
          </div>

          <p style="text-align: center; color: #d81b60; font-weight: bold;">
            ⏰ Este código expira en 10 minutos
          </p>

          <p style="text-align: center; font-size: 12px; color: #777;">
            Si no solicitaste este cambio, ignora este correo.
          </p>

          <p style="text-align: center; font-size: 12px; color: #777;">
            Mi Tiendita - Sistema de seguridad
          </p>
        </div>
      </body>
    </html>
    """;

    await sendEmail(destino, asunto, 'Tu código es: $codigo',
        htmlContent: htmlContent);
  }
    static Future<void> sendOrderStatusUpdateEmail(
    String destino,
    String numeroPedido,
    String nuevoEstado,
  ) async {
    String estadoTexto;
    String color;
    String emoji;
    String mensaje;

    switch (nuevoEstado) {
      case 'aprobado':
        estadoTexto = 'Aprobado';
        color = '#2196F3';
        emoji = '✅';
        mensaje =
            'Tu pedido ha sido aprobado por el administrador. Pronto será enviado.';
        break;
      case 'enviado':
        estadoTexto = 'Enviado';
        color = '#9C27B0';
        emoji = '🚚';
        mensaje =
            '¡Tu pedido ya va en camino! Llegará pronto a tu domicilio.';
        break;
      case 'entregado':
        estadoTexto = 'Entregado';
        color = '#4CAF50';
        emoji = '🎉';
        mensaje = '¡Tu pedido ha sido entregado! Gracias por tu compra.';
        break;
      case 'cancelado':
        estadoTexto = 'Cancelado';
        color = '#F44336';
        emoji = '❌';
        mensaje =
            'Tu pedido ha sido cancelado. Si tienes dudas, contáctanos.';
        break;
      default:
        estadoTexto = nuevoEstado;
        color = '#FF9800';
        emoji = 'ℹ️';
        mensaje = 'El estado de tu pedido ha sido actualizado.';
    }

    final asunto = '$emoji Tu pedido #$numeroPedido ha sido $estadoTexto';
    final htmlContent = """
    <html>
      <body style="font-family: Roboto, sans-serif; color: #333;">
        <div style="max-width: 600px; margin: auto; padding: 20px; border: 1px solid #f8bbd0; border-radius: 12px;">
          <h1 style="color: #e91e63; text-align: center;">$emoji Actualización de tu pedido</h1>

          <div style="text-align: center; margin: 20px 0;">
            <p style="font-size: 16px; color: #666;">Pedido</p>
            <h2 style="color: #e91e63; margin: 5px 0;">#$numeroPedido</h2>
          </div>

          <div style="text-align: center; padding: 20px; background: #fce4ec; border-radius: 12px; margin: 20px 0;">
            <p style="font-size: 14px; color: #666; margin: 0;">Nuevo estado</p>
            <h1 style="color: $color; margin: 10px 0; font-size: 32px;">$estadoTexto</h1>
          </div>

          <p style="text-align: center; font-size: 15px; color: #333;">$mensaje</p>

          <p style="text-align: center; font-size: 12px; color: #777; margin-top: 30px;">
            Mi Tiendita - Sistema de pedidos
          </p>
        </div>
      </body>
    </html>
    """;

    await sendEmail(destino, asunto, '$emoji Pedido #$numeroPedido: $estadoTexto',
        htmlContent: htmlContent);
  }
    // Agrega este método dentro de tu clase MailHelper
  static Future<void> sendPaymentReceiptEmail({
    required String destino,
    required String servicio,
    required String producto,
    required String referencia,
    required String monto,
    required String autorizacion,
  }) async {
    final asunto = 'Comprobante de pago - $servicio';
    final htmlContent = """
    <html>
      <body style="font-family: Roboto, sans-serif; color: #333;">
        <div style="max-width: 600px; margin: auto; padding: 20px; border: 1px solid #f8bbd0; border-radius: 12px;">
          <h1 style="color: #e91e63; text-align: center;">¡Pago Exitoso!</h1>
          <p>Tu pago de <strong>$servicio - $producto</strong> se ha procesado correctamente.</p>
          
          <div style="background: #fce4ec; padding: 20px; border-radius: 12px; margin: 20px 0;">
            <p style="margin: 5px 0;"><strong>Referencia/Teléfono:</strong> $referencia</p>
            <p style="margin: 5px 0;"><strong>Monto pagado:</strong> \$$monto MXN</p>
            <p style="margin: 5px 0;"><strong>Número de Autorización:</strong> $autorizacion</p>
          </div>
          
          <p style="text-align: center; font-size: 12px; color: #777;">
            Gracias por usar Mi Tiendita.
          </p>
        </div>
      </body>
    </html>
    """;

    await sendEmail(destino, asunto, 'Comprobante de pago: $autorizacion',
        htmlContent: htmlContent);
  }
    // Agrega este método al final de tu clase MailHelper
  static Future<void> sendPaymentOtpEmail(
    String destino,
    String codigo,
  ) async {
    final asunto = 'Código de verificación de pago - Mi Tiendita';
    final htmlContent = """
    <html>
      <body style="font-family: Roboto, sans-serif; color: #333;">
        <div style="max-width: 600px; margin: auto; padding: 20px; border: 1px solid #f8bbd0; border-radius: 12px;">
          <h1 style="color: #e91e63; text-align: center;">Verificación de Pago</h1>
          <p>Estás a un paso de completar tu pago en Mi Tiendita.</p>
          <p>Usa el siguiente código para confirmar la transacción:</p>

          <div style="text-align: center; margin: 30px 0;">
            <span style="display: inline-block; padding: 15px 30px; background: #fce4ec; border: 2px solid #e91e63; border-radius: 12px; font-size: 32px; font-weight: bold; color: #e91e63; letter-spacing: 8px;">
              $codigo
            </span>
          </div>

          <p style="text-align: center; color: #d81b60; font-weight: bold;">
            ⏰ Este código expira en 10 minutos
          </p>

          <p style="text-align: center; font-size: 12px; color: #777;">
            Si no solicitaste este pago, por favor ignora este correo.
          </p>

          <p style="text-align: center; font-size: 12px; color: #777;">
            Mi Tiendita - Sistema de seguridad
          </p>
        </div>
      </body>
    </html>
    """;

    await sendEmail(destino, asunto, 'Tu código de verificación de pago es: $codigo',
        htmlContent: htmlContent);
  }
}