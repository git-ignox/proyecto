import 'package:flutter/material.dart';

/// Widget visual para renderizar Códigos de Barras de presencia en aula
/// mediante un CustomPainter que dibuja barras verticales de grosor variable.
class WidgetCodigoBarras extends StatelessWidget {
  const WidgetCodigoBarras({
    super.key,
    required this.codigo,
    this.ancho = 240,
    this.alto = 80,
    this.mostrarTexto = true,
    this.colorBarras = Colors.black,
    this.colorFondo = Colors.white,
    this.permiteExpandir = true,
  });

  final String codigo;
  final double ancho;
  final double alto;
  final bool mostrarTexto;
  final Color colorBarras;
  final Color colorFondo;
  final bool permiteExpandir;

  String get _codigoLegible {
    if (codigo.length <= 16) return codigo;
    // Si es un token base64 largo, muestra una clave legible y limpia
    final hash = codigo.hashCode.abs().toRadixString(16).padLeft(8, '0').toUpperCase();
    return 'CSM-${hash.substring(0, 4)}-${hash.substring(4, 8)}';
  }

  @override
  Widget build(BuildContext context) {
    final barcodeWidget = Container(
      width: ancho,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: ancho - 24,
            height: alto,
            child: CustomPaint(
              painter: _PintorCodigoBarras(
                dato: codigo,
                colorBarras: colorBarras,
              ),
            ),
          ),
          if (mostrarTexto) ...[
            const SizedBox(height: 6),
            Text(
              _codigoLegible,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.5,
                color: colorBarras,
              ),
            ),
          ],
        ],
      ),
    );

    if (!permiteExpandir) return barcodeWidget;

    return InkWell(
      onTap: () => _mostrarProyector(context),
      borderRadius: BorderRadius.circular(8),
      child: Tooltip(
        message: 'Toca para ampliar el Código de Barras en pantalla completa',
        child: barcodeWidget,
      ),
    );
  }

  void _mostrarProyector(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.barcode_reader, color: Colors.indigo, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Código de Barras para Proyección',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 24),
              const Text(
                'Muestra este código de barras a los alumnos para validar presencia en el aula:',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.indigo.shade300, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: 320,
                      height: 120,
                      child: CustomPaint(
                        painter: _PintorCodigoBarras(
                          dato: codigo,
                          colorBarras: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _codigoLegible,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Código rotativo con vigencia de 90 segundos.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.check),
                label: const Text('Cerrar Proyector'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// CustomPainter que genera patrones verticales de Código de Barras (estilo Code 128)
class _PintorCodigoBarras extends CustomPainter {
  _PintorCodigoBarras({
    required this.dato,
    required this.colorBarras,
  });

  final String dato;
  final Color colorBarras;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colorBarras
      ..style = PaintingStyle.fill;

    // Generar un patrón determinista de anchos de barras y espacios basado en el dato
    final pattern = _generarPatronModulos(dato);
    if (pattern.isEmpty) return;

    final moduleWidth = size.width / pattern.length;

    for (int i = 0; i < pattern.length; i++) {
      if (pattern[i]) {
        final left = i * moduleWidth;
        final rect = Rect.fromLTWH(left, 0, moduleWidth + 0.3, size.height);
        canvas.drawRect(rect, paint);
      }
    }
  }

  /// Genera secuencia booleana (true = barra negra, false = espacio blanco)
  /// respetando guardas de inicio/fin y secuencias pseudo Code-128
  List<bool> _generarPatronModulos(String input) {
    final List<bool> modulos = [];

    // Guarda de inicio (Start guard: barra-espacio-barra-espacio)
    modulos.addAll([true, true, false, true, false, false]);

    final seed = input.hashCode;
    int current = seed;

    final chars = input.isEmpty ? 'BARCODE128' : input;
    for (int i = 0; i < chars.length && modulos.length < 90; i++) {
      final code = chars.codeUnitAt(i) ^ (current & 0xFF);
      current = (current * 1103515245 + 12345) & 0x7FFFFFFF;

      // Cada carácter genera 6 módulos con variaciones de ancho
      final bit0 = (code & 1) != 0;
      final bit1 = (code & 2) != 0;
      final bit2 = (code & 4) != 0;
      final bit3 = (code & 8) != 0;

      modulos.add(true);
      modulos.add(bit0);
      modulos.add(false);
      modulos.add(bit1);
      modulos.add(true);
      modulos.add(!bit2 || bit3);
      modulos.add(false);
    }

    // Guarda de finalización (Stop guard: barra-barra-espacio-barra)
    modulos.addAll([true, false, true, true, false, true, true]);

    return modulos;
  }

  @override
  bool shouldRepaint(covariant _PintorCodigoBarras oldDelegate) {
    return oldDelegate.dato != dato || oldDelegate.colorBarras != colorBarras;
  }
}
