// ============================================================
// glow_orb_background.dart — Fondo con esferas de luz difusas
//
// Técnica correcta:
//   • LayoutBuilder envuelve el Stack entero → conocemos w/h una vez
//   • AnimatedBuilder devuelve Positioned directamente como hijo de Stack
//   • BackdropFilter con blur 80 convierte los orbs en manchas difusas
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
      centerX: 0.15,
      centerY: 0.12,
      amplitude: 0.08,
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

  // Desfase de fase para que los orbs no se muevan sincronizados
  static const _phaseOffsets = [0.0, 0.3, 0.6, 0.85];

  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_orbConfigs.length, (i) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: _orbConfigs[i].durationMs),
      )..repeat();
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
    // LayoutBuilder en el nivel raíz → conocemos las dimensiones antes
    // de construir el Stack, así Positioned siempre tiene un Stack como padre.
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return ColoredBox(
          color: AppColors.fondoOscuro,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // ── Orbs animados ───────────────────────────────────────────
              // Cada AnimatedBuilder devuelve un Positioned directamente,
              // que es hijo inmediato del Stack → no hay conflicto de ParentData.
              ...List.generate(_orbConfigs.length, (i) {
                final config = _orbConfigs[i];
                return AnimatedBuilder(
                  animation: _controllers[i],
                  builder: (context, _) {
                    final t =
                        (_controllers[i].value + _phaseOffsets[i]) % 1.0;
                    final angle = t * 2 * math.pi;
                    final r = config.radius.toDouble();
                    final cx = w * config.centerX +
                        w * config.amplitude * math.cos(angle);
                    final cy = h * config.centerY +
                        h * config.amplitude * math.sin(angle);

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
                              config.color.withAlpha(0),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),

              // ── Capa de blur global ─────────────────────────────────────
              // Se aplica SOBRE los orbs pero BAJO el contenido de la app.
              // sigma 80 → manchas de luz difusas estilo lámpara de lava.
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: const ColoredBox(color: Colors.transparent),
                ),
              ),

              // ── Contenido encima del fondo ──────────────────────────────
              if (widget.child != null)
                Positioned.fill(child: widget.child!),
            ],
          ),
        );
      },
    );
  }
}

// Configuración inmutable de cada orb (const → cero overhead)
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
  final double centerX;
  final double centerY;
  final double amplitude;
}
