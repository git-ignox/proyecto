// ============================================================
// primary_glow_button.dart — Botón principal estilo Claude
//
// Apariencia idéntica a Claude:
//   • Fondo: crema/hueso sólido #ECE7DE (o hover #F6F3EC)
//   • Texto: carbón oscuro #1E1D1B con tipografía limpia (14.5px, w600)
//   • Bordes redondeados modernos (12px)
//   • Feedback sutil de clic (escala 0.985)
//   • Spinner oscuro discreto durante la carga
// ============================================================

import 'package:flutter/material.dart';
import '../../widgets/claude_auth_components.dart';

/// Botón primario con apariencia editorial oficial de Claude.
class PrimaryGlowButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ClaudePrimaryButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      height: 48,
      borderRadius: 12,
    );
  }
}
