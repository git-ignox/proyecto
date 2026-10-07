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

  /// Configuración de modo claro: papel crema cálido y estética editorial Claude.
  factory TemaCuaderno.light() {
    return const TemaCuaderno(
      brightness: Brightness.light,
      background: Color(0xFFF7F0DF), // Crema suave de papel físico (#F7F0DF / Claude tone)
      paperLine: Color(0x18A69C8B), // Líneas horizontales tenues
      marginLine: Color(0xFFD97757), // Terracota Claude (#D97757)
      primaryText: Color(0xFF141413), // Negro carbón Claude (#141413)
      secondaryText: Color(0xFF73726C), // Gris cálido Claude (#73726C)
      annotationText: Color(0xFF788C5D), // Verde salvia Claude (#788C5D)
      primaryButton: Color(0xFFD97757), // Terracota oficial Crail Orange (#D97757)
      primaryButtonText: Color(0xFFFFFFFF), // Blanco sobre terracota
      secondaryButtonBorder: Color(0xFFE8E6DC), // Borde hairline sutil Claude
      secondaryButtonText: Color(0xFF141413),
      decorativeElement: Color(0xFFB0AEA5),
      accentHighlight: Color(0x1AD97757),
    );
  }

  /// Configuración de modo oscuro: cuaderno en interpretación nocturna Claude.
  factory TemaCuaderno.dark() {
    return const TemaCuaderno(
      brightness: Brightness.dark,
      background: Color(0xFF171717), // Negro grafito profundo (#171717)
      paperLine: Color(0x0EFFFFFF), // Líneas muy sutiles y tenues
      marginLine: Color(0xFFD97757), // Terracota suave
      primaryText: Color(0xFFFAF9F5), // Blanco cálido Claude sobre oscuro
      secondaryText: Color(0xFFB0AEA5), // Gris claro editorial Claude
      annotationText: Color(0xFFE8E6DC),
      primaryButton: Color(0xFFD97757), // Terracota oficial Claude (#D97757)
      primaryButtonText: Color(0xFFFFFFFF),
      secondaryButtonBorder: Color(0x33FAF9F5),
      secondaryButtonText: Color(0xFFFAF9F5),
      decorativeElement: Color(0x44FFFFFF),
      accentHighlight: Color(0x26D97757),
    );
  }
}
