// ============================================================
// tipografia_cuaderno.dart — Familias tipográficas del diseño
//
// Jerarquía visual obligatoria:
//   1. Impact          → Títulos grandes, impacto visual dominante
//   2. Times New Roman → Contenido explicativo, párrafos editoriales
//   3. Comic Sans MS   → Pequeñas anotaciones, apuntes manuscritos
// ============================================================

import 'package:flutter/material.dart';

abstract final class TipografiaCuaderno {
  /// Tipografía principal de alto impacto para títulos.
  ///
  /// Condensada, pesada y visualmente dominante. Si la plataforma no
  /// cuenta con 'Impact' en su sistema, emplea fallbacks condensados
  /// de proporciones directas ('Anton', 'Trebuchet MS', 'Arial Black').
  static TextStyle impact({
    required Color color,
    required double fontSize,
    double letterSpacing = -0.6,
    double height = 0.95,
  }) {
    return TextStyle(
      fontFamily: 'Impact',
      fontFamilyFallback: const [
        'Anton',
        'Bebas Neue',
        'Trebuchet MS',
        'Arial Black',
        'sans-serif-condensed',
        'sans-serif',
      ],
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Tipografía clásica con serifa para el contenido editorial y explicativo.
  ///
  /// Refuerza la sensación de libro escolar y material educativo impreso.
  static TextStyle timesNewRoman({
    required Color color,
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    FontStyle fontStyle = FontStyle.normal,
    double height = 1.45,
    double letterSpacing = 0.15,
  }) {
    return TextStyle(
      fontFamily: 'Times New Roman MT',
      fontFamilyFallback: const [
        'Times New Roman',
        'Times',
        'Charter',
        'serif',
      ],
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Tipografía informal para anotaciones marginales y detalles manuscritos.
  ///
  /// Su uso es estrictamente deliberado y limitado a notas al pie o
  /// pequeños apuntes didácticos.
  static TextStyle comicSans({
    required Color color,
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    FontStyle fontStyle = FontStyle.normal,
    double height = 1.35,
    double letterSpacing = 0.2,
  }) {
    return TextStyle(
      fontFamily: 'Comic Sans MS',
      fontFamilyFallback: const [
        'Comic Sans',
        'Chalkboard SE',
        'Comic Neue',
        'cursive',
      ],
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}
