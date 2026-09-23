// ============================================================
// grid_overlay.dart — Grilla sutil de fondo
//
// Implementada con CustomPainter: sin dependencias extra.
// Dibuja líneas horizontales y verticales de baja opacidad
// sobre el fondo oscuro, dando un look de grilla futurista.
//
// Parámetros ajustables:
//   spacing   : separación entre líneas (recomendado 28 px)
//   lineColor : color de las líneas (crema al 6% por defecto)
//   lineWidth : grosor de línea (0.5 px por defecto)
// ============================================================

import 'package:flutter/material.dart';

/// Superpone una grilla de líneas finas sobre cualquier widget hijo.
/// Usar con [Stack] o como fondo independiente de tamaño completo.
class GridOverlay extends StatelessWidget {
  const GridOverlay({
    super.key,
    this.child,
    // 28 px produce ~30 celdas en un móvil estándar — suficiente densidad
    // sin sobrecargar visualmente. Ajustar entre 24–36 según el dispositivo.
    this.spacing = 28.0,
    this.lineColor = const Color(0x0FFDF8EF), // crema al ~6%
    this.lineWidth = 0.5,
  });

  final Widget? child;
  final double spacing;
  final Color lineColor;
  final double lineWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(
        spacing: spacing,
        lineColor: lineColor,
        lineWidth: lineWidth,
      ),
      child: child,
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({
    required this.spacing,
    required this.lineColor,
    required this.lineWidth,
  });

  final double spacing;
  final Color lineColor;
  final double lineWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;

    // Líneas verticales
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Líneas horizontales
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.spacing != spacing ||
      old.lineColor != lineColor ||
      old.lineWidth != lineWidth;
}
