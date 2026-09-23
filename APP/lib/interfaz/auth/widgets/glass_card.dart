// ============================================================
// glass_card.dart — Contenedor de vidrio (glassmorphism)
//
// Implementado directamente con BackdropFilter + Container para
// evitar los problemas de constraints de GlassmorphicContainer
// cuando el padre no provee un tamaño fijo (ej: Column con
// mainAxisSize: min).
//
// Combina:
//   • ClipRRect para que el blur se confine al borde redondeado
//   • BackdropFilter con ImageFilter.blur para el frosted glass
//   • Fondo crema semi-transparente
//   • Borde superior con gradiente blanco→transparente (rim-light)
//   • Sombra cálida naranja de baja opacidad para sensación de elevación
//
// Parámetros ajustables:
//   blurSigma  : intensidad del blur (12–20 recomendado)
//   borderRadius: radio de esquinas (24 por defecto)
//   padding    : relleno interno
//   child      : contenido de la tarjeta
// ============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../design/app_colors.dart';

/// Tarjeta de vidrio esmerilado con borde rim-light y sombra cálida.
///
/// Usar como contenedor principal del formulario de autenticación,
/// y como base para cualquier otra tarjeta de la app que necesite
/// el look glassmorphism.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.blurSigma = 18.0,
    // 24 px de radio: suficiente para look "soft card" sin parecer circular
    this.borderRadius = 24.0,
    this.padding = const EdgeInsets.all(28),
  });

  final Widget child;

  /// Intensidad del efecto blur del fondo (Gaussian sigma).
  /// Valores: 10 = sutil, 18 = estándar, 28 = muy difuso.
  final double blurSigma;

  /// Radio de las esquinas de la tarjeta.
  final double borderRadius;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    return Container(
      // Sombra cálida naranja — eleva la tarjeta visualmente sin usar elevation
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.sombraTarjeta,
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
          // Segunda sombra más difusa para profundidad extra
          BoxShadow(
            color: AppColors.naranja.withAlpha(10),
            blurRadius: 80,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      // ClipRRect confina el BackdropFilter dentro del borde redondeado
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          // blur: difumina el fondo visible detrás de la tarjeta
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            decoration: BoxDecoration(
              // Fondo crema semi-transparente — base del efecto glass
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.crema.withAlpha(30), // ~12% — esquina superior más opaca
                  AppColors.crema.withAlpha(18), // ~7%  — cuerpo de la tarjeta
                ],
              ),
              borderRadius: radius,
              border: Border.all(
                // Borde rim-light: gradiente blanco→transparente creado via
                // BoxDecoration no soporta gradient en border directamente,
                // así que usamos un color crema uniforme de bajo alpha —
                // el efecto rim-light principal se da por la diferencia de
                // opacidad del gradiente en la esquina superior del fondo.
                color: Colors.white.withAlpha(45),
                width: 1.0,
              ),
            ),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
