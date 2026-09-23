// ============================================================
// app_text_styles.dart — Tokens tipográficos centralizados
//
// Fuente: Plus Jakarta Sans (moderna, geométrica, legible).
// Jerarquía: display → title → subtitle → body → caption → label
// Todos los estilos usan AppColors para no hardcodear colores.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  // ── Display ───────────────────────────────────────────────────────────────
  /// Título grande de pantalla. Ej: nombre de la app.
  static TextStyle get display => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.crema,
        letterSpacing: -0.5,
        height: 1.1,
      );

  /// Variante display con gradiente naranja-crema (para uso en ShaderMask).
  static TextStyle get displayAccent => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.1,
        foreground: Paint()
          ..shader = const LinearGradient(
            colors: [AppColors.naranjaVivo, AppColors.ambar],
          ).createShader(const Rect.fromLTWH(0, 0, 220, 40)),
      );

  // ── Título ────────────────────────────────────────────────────────────────
  /// Título de sección / header de tarjeta.
  static TextStyle get title => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.crema,
        letterSpacing: -0.3,
      );

  // ── Subtítulo ─────────────────────────────────────────────────────────────
  /// Descripción breve debajo del título.
  static TextStyle get subtitle => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.cremaMedio,
        letterSpacing: 0.1,
        height: 1.5,
      );

  // ── Cuerpo ────────────────────────────────────────────────────────────────
  /// Texto de campos, etiquetas de formulario.
  static TextStyle get body => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.crema,
      );

  // ── Caption ───────────────────────────────────────────────────────────────
  /// Texto auxiliar pequeño (errores, hints).
  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.cremaMedio,
      );

  // ── Label ─────────────────────────────────────────────────────────────────
  /// Etiqueta de botón (solo uppercase si se aplica TextCapitalization).
  static TextStyle get label => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.crema,
        letterSpacing: 0.5,
      );

  /// Etiqueta de botón secundario / texto link.
  static TextStyle get labelSecondary => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.cremaMedio,
      );

  // ── Tab toggle ────────────────────────────────────────────────────────────
  /// Etiqueta del selector Login/Registro activo.
  static TextStyle get tabActive => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.crema,
      );

  /// Etiqueta del selector Login/Registro inactivo.
  static TextStyle get tabInactive => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.cremaMedio,
      );
}
