// ============================================================
// auth_text_field.dart — Campo de texto con estilo glass
//
// Apariencia:
//   • Fondo: crema al 8% sobre oscuro (glass tenue)
//   • Borde: crema al 20% en reposo → naranja al 60% en foco
//   • Texto: crema #FDF8EF
//   • Icono prefijo: naranja #DB4406
//   • Label flotante: crema al 70%
//   • Error: texto rojo cálido (#FF6B35) sin borde rojo agresivo
//
// Proporciona [focusNode] interno — no necesita pasarse desde afuera.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../design/app_colors.dart';

/// Campo de texto glassmorphism para formularios de autenticación.
///
/// Maneja su propio [FocusNode] para la animación de borde al recibir foco.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final Widget? suffixIcon;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late final FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()
      ..addListener(() {
        if (mounted) setState(() => _hasFocus = _focusNode.hasFocus);
      });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Borde cambia suavemente entre crema-tenue y naranja-vivo al enfocar
    final borderColor = _hasFocus
        ? AppColors.naranja.withAlpha(180)   // naranja al ~70% en foco
        : AppColors.crema.withAlpha(51);     // crema al ~20% en reposo

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        // Fondo tenue crema/glass para el campo
        color: AppColors.crema.withAlpha(20),
        border: Border.all(color: borderColor, width: 1.2),
        // Glow sutil naranja cuando está en foco
        boxShadow: _hasFocus
            ? [
                BoxShadow(
                  color: AppColors.naranja.withAlpha(40),
                  blurRadius: 12,
                  offset: Offset.zero,
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onFieldSubmitted,
        style: GoogleFonts.plusJakartaSans(
          color: AppColors.crema,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: AppColors.naranja,
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: GoogleFonts.plusJakartaSans(
            color: AppColors.crema.withAlpha(178), // crema al 70%
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          floatingLabelStyle: GoogleFonts.plusJakartaSans(
            color: AppColors.naranjaVivo,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(widget.icon, color: AppColors.naranja, size: 20),
          suffixIcon: widget.suffixIcon,
          // Sin borde propio — el borde lo maneja el AnimatedContainer externo
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          // Error con color cálido, sin borde rojo agresivo
          errorStyle: GoogleFonts.plusJakartaSans(
            color: const Color(0xFFFF6B35), // naranja-rojo cálido
            fontSize: 11,
          ),
        ),
      ),
    )
        // Animación de entrada: fade + slide desde abajo al aparecer
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }
}
