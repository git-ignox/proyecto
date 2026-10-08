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
    // Borde cambia suavemente entre blanco-tenue y terracota-Claude al enfocar
    final borderColor = _hasFocus
        ? const Color(0xFFD97757).withOpacity(0.9) // Terracota Claude en foco
        : Colors.white.withOpacity(0.14);          // Traslúcido tenue en reposo

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        // Fondo tenue de vidrio para el campo
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: borderColor, width: 1.0),
        // Glow sutil cuando está en foco
        boxShadow: _hasFocus
            ? [
                BoxShadow(
                  color: const Color(0xFFD97757).withOpacity(0.25),
                  blurRadius: 10,
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
          color: const Color(0xFFFAF9F5),
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: const Color(0xFFD97757),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: GoogleFonts.plusJakartaSans(
            color: Colors.white.withOpacity(0.50),
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
          ),
          floatingLabelStyle: GoogleFonts.plusJakartaSans(
            color: const Color(0xFFD97757),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            widget.icon,
            color: _hasFocus
                ? const Color(0xFFD97757)
                : Colors.white.withOpacity(0.50),
            size: 19,
          ),
          suffixIcon: widget.suffixIcon,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          errorStyle: GoogleFonts.plusJakartaSans(
            color: const Color(0xFFFF6B55),
            fontSize: 11,
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 250.ms)
        .slideY(begin: 0.08, end: 0, duration: 250.ms, curve: Curves.easeOut);
  }
}
