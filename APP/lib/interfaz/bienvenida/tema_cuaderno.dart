// ============================================================
// tema_cuaderno.dart — Tokens semánticos de diseño estilo cuaderno
//
// Centraliza los colores y estilos para el modo claro y oscuro.
//   • Paleta: Crema / Naranja / Negro / Gris / Rojo margen
//   • Modo claro: fondo crema cálido (#F7F0DF), líneas muy tenues (#D6D0C4)
//   • Modo oscuro: fondo gris muy oscuro (#171717), líneas sutiles
//   • Sin inversiones crudas; conserva la identidad visual de cuaderno físico.
// ============================================================

import 'package:flutter/material.dart';

/// Tokens semánticos para la interfaz con estética de cuaderno moderno.
class TemaCuaderno {
  const TemaCuaderno({
    required this.brightness,
    required this.background,
    required this.paperLine,
    required this.marginLine,
    required this.primaryText,
    required this.secondaryText,
    required this.annotationText,
    required this.primaryButton,
    required this.primaryButtonText,
    required this.secondaryButtonBorder,
    required this.secondaryButtonText,
    required this.decorativeElement,
    required this.accentHighlight,
  });

  final Brightness brightness;

  /// Fondo completo tipo papel (crema en claro, gris grafito oscuro en noche).
  final Color background;

  /// Líneas horizontales de cuaderno, muy tenues para no obstaculizar la lectura.
  final Color paperLine;

  /// Línea vertical roja del margen izquierdo del cuaderno.
  final Color marginLine;

  /// Color para el título principal y elementos de mayor jerarquía.
  final Color primaryText;

  /// Color para párrafos editoriales y descripciones (Times New Roman MT).
  final Color secondaryText;

  /// Color para anotaciones manuscritas / apuntes marginales (Comic Sans MS).
  final Color annotationText;

  /// Color para la acción principal (naranja de acento).
  final Color primaryButton;

  /// Texto del botón de acción principal para asegurar contraste accesible.
  final Color primaryButtonText;

  /// Borde sutil del botón secundario.
  final Color secondaryButtonBorder;

  /// Texto del botón secundario.
  final Color secondaryButtonText;

  /// Color para pequeños detalles gráficos (marcas, viñetas, grapas).
  final Color decorativeElement;

  /// Tono de resaltado sutil para recuadros de apuntes.
  final Color accentHighlight;

  bool get isDark => brightness == Brightness.dark;

  /// Obtiene la configuración de tema según el brillo del sistema / contexto.
  factory TemaCuaderno.of(BuildContext context) {
    final themeBrightness = Theme.of(context).brightness;
    final platformBrightness = MediaQuery.maybePlatformBrightnessOf(context);
    final isDark =
        themeBrightness == Brightness.dark ||
        platformBrightness == Brightness.dark;

    return isDark ? TemaCuaderno.dark() : TemaCuaderno.light();
  }

  /// Configuración de modo claro: papel crema cálido y tinta oscura.
  factory TemaCuaderno.light() {
    return const TemaCuaderno(
      brightness: Brightness.light,
      background: Color(0xFFF7F0DF), // Crema suave de cuaderno físico
      paperLine: Color(
        0x18A69C8B,
      ), // Líneas horizontales mucho más tenues y sutiles
      marginLine: Color(0xFFD9534F), // Rojo margen clásico
      primaryText: Color(0xFF171717), // Negro editorial
      secondaryText: Color(0xFF3A3A3A), // Gris oscuro legible
      annotationText: Color(0xFF4A443C), // Grafito de lápiz
      primaryButton: Color(0xFFF28C28), // Naranja principal
      primaryButtonText: Color(0xFF171717), // Máximo contraste legible
      secondaryButtonBorder: Color(0x66171717),
      secondaryButtonText: Color(0xFF171717),
      decorativeElement: Color(0x558A8072),
      accentHighlight: Color(0x1AF28C28),
    );
  }

  /// Configuración de modo oscuro: cuaderno en interpretación nocturna.
  factory TemaCuaderno.dark() {
    return const TemaCuaderno(
      brightness: Brightness.dark,
      background: Color(0xFF171717), // Negro / grafito oscuro profundo
      paperLine: Color(0x0EFFFFFF), // Líneas muy sutiles y tenues
      marginLine: Color(0xFFC94A46), // Rojo suavizado para descansar la vista
      primaryText: Color(0xFFF7F0DF), // Crema sobre fondo oscuro
      secondaryText: Color(0xFFB0AAA0), // Gris claro editorial
      annotationText: Color(0xFFD6D0C4), // Trazado claro tipo tiza suave
      primaryButton: Color(0xFFF28C28), // Naranja vibrante accesible
      primaryButtonText: Color(0xFF171717), // Texto oscuro contrastado
      secondaryButtonBorder: Color(0x66F7F0DF),
      secondaryButtonText: Color(0xFFF7F0DF),
      decorativeElement: Color(0x44FFFFFF),
      accentHighlight: Color(0x26F28C28),
    );
  }
}
