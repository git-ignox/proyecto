// ============================================================
// primary_glow_button.dart — Botón principal con glow naranja
//
// Apariencia:
//   • Fondo: naranja sólido #DB4406
//   • Sombra: glow naranja difuso (BoxShadow con blur 20)
//   • Al presionar: escala 0.96 + reducción del glow (ScaleTransition)
//   • Al cargar: spinner crema reemplaza el label
//   • Animación de entrada: shimmer horizontal (flutter_animate)
//
// El glow se implementa con BoxDecoration+BoxShadow en vez de
// ShaderMask para preservar la forma redondeada sin artefactos.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../design/app_colors.dart';

/// Botón primario naranja con efecto glow y feedback de presión.
class PrimaryGlowButton extends StatefulWidget {
  const PrimaryGlowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  State<PrimaryGlowButton> createState() => _PrimaryGlowButtonState();
}

class _PrimaryGlowButtonState extends State<PrimaryGlowButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    // Escala de 1.0 → 0.96 al presionar
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _pressCtrl.forward();
  void _onTapUp(_) => _pressCtrl.reverse();
  void _onTapCancel() => _pressCtrl.reverse();

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: isEnabled ? _onTapDown : null,
        onTapUp: isEnabled ? _onTapUp : null,
        onTapCancel: isEnabled ? _onTapCancel : null,
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (context, child) {
            // El glow se reduce al presionar para reforzar el feedback táctil
            final glowIntensity = 1.0 - (_pressCtrl.value * 0.5);
            return Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: isEnabled
                    ? AppColors.naranja
                    : AppColors.naranja.withAlpha(100),
                borderRadius: BorderRadius.circular(14),
                // Glow naranja: sombra difusa principal + sombra más amplia
                boxShadow: isEnabled
                    ? [
                        BoxShadow(
                          color: AppColors.glowNaranja
                              .withAlpha((128 * glowIntensity).round()),
                          blurRadius: 20 * glowIntensity,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: AppColors.naranja
                              .withAlpha((40 * glowIntensity).round()),
                          blurRadius: 40 * glowIntensity,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [],
              ),
              child: child,
            );
          },
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isEnabled ? widget.onPressed : null,
              borderRadius: BorderRadius.circular(14),
              splashColor: Colors.white.withAlpha(20),
              highlightColor: Colors.transparent,
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.crema,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon,
                                color: AppColors.crema, size: 20),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.label,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.crema,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    )
        // Animación de entrada: shimmer + fade al aparecer en pantalla
        .animate()
        .shimmer(
          duration: 600.ms,
          delay: 400.ms,
          color: Colors.white.withAlpha(25),
        )
        .fadeIn(duration: 350.ms, delay: 200.ms);
  }
}
