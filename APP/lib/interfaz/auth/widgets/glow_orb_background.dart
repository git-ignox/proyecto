// ============================================================
// glow_orb_background.dart — Fondo con esferas de luz difusas
//
// Renderiza 4 orbs de luz en tonos naranja/ámbar que se mueven
// suavemente en trayectorias circulares independientes.
//
// Técnica:
//   1. Cada orb es un Container circular con RadialGradient.
//   2. Un Stack los superpone sobre el fondo oscuro.
//   3. Un único BackdropFilter con ImageFilter.blur(80,80) sobre
//      toda la capa los convierte en manchas de luz difusas.
//   4. Cada AnimationController corre a velocidad y fase distintas
//      para que los movimientos nunca se sincronicen (look orgánico).
//
// Ajuste de paleta: todos los colores vienen de AppColors, lo que
// permite cambiar la estética global sin tocar este archivo.
// ============================================================

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import '../../design/app_colors.dart';

/// Fondo animado de esferas de luz difusas para la pantalla de auth.
/// Colocar como primer elemento de un [Stack] de tamaño completo.
class GlowOrbBackground extends StatefulWidget {
  const GlowOrbBackground({super.key, this.child});

  final Widget? child;

  @override
  State<GlowOrbBackground> createState() => _GlowOrbBackgroundState();
}

class _GlowOrbBackgroundState extends State<GlowOrbBackground>
    with TickerProviderStateMixin {
  // Configuración de los 4 orbs: color, radio, velocidad, posición inicial
  static const _orbConfigs = [
    _OrbConfig(
      color: AppColors.orbNaranja,
      radius: 180,
      durationMs: 11000,
      // Inicio en cuadrante superior-izquierdo
      centerX: 0.15,
      centerY: 0.12,
      amplitude: 0.08, // cuánto se mueve en X/Y relativo al ancho/alto
    ),
    _OrbConfig(
      color: AppColors.orbAmbar,
      radius: 220,
      durationMs: 14000,
      centerX: 0.82,
      centerY: 0.20,
      amplitude: 0.07,
    ),
    _OrbConfig(
      color: AppColors.orbVivo,
      radius: 150,
      durationMs: 9500,
      centerX: 0.60,
      centerY: 0.78,
      amplitude: 0.10,
    ),
    _OrbConfig(
      color: AppColors.orbNaranja,
      radius: 200,
      durationMs: 13000,
      centerX: 0.25,
      centerY: 0.68,
      amplitude: 0.06,
    ),
  ];

  late final List<AnimationController> _controllers;
  // Desfase de fase inicial para que cada orb arranque en un ángulo distinto
  static const _phaseOffsets = [0.0, 0.3, 0.6, 0.85];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_orbConfigs.length, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: _orbConfigs[i].durationMs),
      )..repeat();
      return ctrl;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      // Fondo base oscuro: café muy oscuro derivado del naranja
      color: AppColors.fondoOscuro,
      child: Stack(
        children: [
          // ── Capa de orbs ──────────────────────────────────────────────────
          // Los orbs se pintan sin blur primero...
          ...List.generate(_orbConfigs.length, (i) {
            final config = _orbConfigs[i];
            return AnimatedBuilder(
              animation: _controllers[i],
              builder: (context, _) {
                final t = (_controllers[i].value + _phaseOffsets[i]) % 1.0;
                // Movimiento circular suave via seno/coseno
                final angle = t * 2 * math.pi;
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;
                    // Posición central relativa + desplazamiento sinusoidal
                    final cx = w * config.centerX +
                        w * config.amplitude * math.cos(angle);
                    final cy = h * config.centerY +
                        h * config.amplitude * math.sin(angle);
                    final r = config.radius.toDouble();

                    return Positioned(
                      left: cx - r,
                      top: cy - r,
                      child: Container(
                        width: r * 2,
                        height: r * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              config.color,
                              config.color.withAlpha(0), // desvanece al borde
                            ],
                            stops: const [0.0, 1.0],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }),

          // ── Blur global sobre los orbs ────────────────────────────────────
          // sigmaX/Y 80 produce el efecto "lámpara de lava desenfocada".
          // Se aplica SOLO sobre los orbs, no sobre el contenido encima.
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),

          // ── Contenido encima ──────────────────────────────────────────────
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

// Configuración inmutable de cada orb (const → sin overhead en hot reload)
class _OrbConfig {
  const _OrbConfig({
    required this.color,
    required this.radius,
    required this.durationMs,
    required this.centerX,
    required this.centerY,
    required this.amplitude,
  });

  final Color color;
  final int radius;
  final int durationMs;
  final double centerX; // 0.0–1.0 relativo al ancho del contenedor
  final double centerY; // 0.0–1.0 relativo al alto del contenedor
  final double amplitude; // 0.0–1.0 relativo al ancho/alto
}
