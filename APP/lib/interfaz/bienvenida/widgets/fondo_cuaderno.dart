// ============================================================
// fondo_cuaderno.dart — Fondo tipo hoja de cuaderno dibujado por código
//
// Renderizado eficiente mediante CustomPainter:
//   • Líneas horizontales tenues con separación regular (30px)
//   • Margen vertical rojo clásico en el flanco izquierdo
//   • Adaptación automática a insets/safe area y dark/light theme
//   • Cero imágenes rasterizadas; 100% vectorial, responsive y GPU-friendly
// ============================================================

import 'package:flutter/material.dart';

import '../tema_cuaderno.dart';

/// Widget de fondo que pinta una hoja de cuaderno completa detrás de la interfaz.
class FondoCuaderno extends StatelessWidget {
  const FondoCuaderno({super.key, required this.tema, this.child});

  final TemaCuaderno tema;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return Container(
      color: tema.background,
      child: CustomPaint(
        painter: _PintorHojaCuaderno(
          tema: tema,
          leftInset: padding.left,
          topInset: padding.top,
          bottomInset: padding.bottom,
        ),
        // SizedBox.expand garantiza que el painter recibe el tamaño completo
        // del padre (toda la pantalla), no solo el área del child.
        child: SizedBox.expand(child: child),
      ),
    );
  }
}

class _PintorHojaCuaderno extends CustomPainter {
  const _PintorHojaCuaderno({
    required this.tema,
    required this.leftInset,
    required this.topInset,
    required this.bottomInset,
  });

  final TemaCuaderno tema;
  final double leftInset;
  final double topInset;
  final double bottomInset;

  static const double _espaciadoLineas = 24.0;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = tema.paperLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true;

    // 1. Líneas horizontales regulares y tenues a lo largo de toda la pantalla hacia abajo
    for (double y = _espaciadoLineas; y <= size.height; y += _espaciadoLineas) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // 2. Línea vertical roja del margen izquierdo
    // En pantallas estrechas (móvil) dejamos un margen compacto (44px + inset),
    // y en pantallas amplias (desktop) un margen más holgado (68px + inset).
    final double margenOffset = size.width < 768
        ? (leftInset + 44.0)
        : (leftInset + 68.0);

    final marginPaint = Paint()
      ..color = tema.marginLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;

    canvas.drawLine(
      Offset(margenOffset, 0),
      Offset(margenOffset, size.height),
      marginPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PintorHojaCuaderno oldDelegate) {
    return oldDelegate.tema.brightness != tema.brightness ||
        oldDelegate.leftInset != leftInset ||
        oldDelegate.topInset != topInset ||
        oldDelegate.bottomInset != bottomInset;
  }
}
