// ============================================================
// app_colors.dart — Tokens de color centralizados para el LMS
//
// Paleta base:
//   Naranja principal : #DB4406  (acentos, botones, glow)
//   Crema             : #FDF8EF  (tarjetas, texto sobre oscuro)
//
// Todas las variantes se derivan de estos dos colores.
// No usar colores fuera de esta paleta salvo negro/blanco puro.
// ============================================================

import 'dart:ui';

abstract final class AppColors {
  // ── Naranja ──────────────────────────────────────────────────────────────
  /// Naranja principal. Botones, acentos, íconos activos.
  static const Color naranja = Color(0xFFDB4406);

  /// Naranja más luminoso. Highlight de orbs, estados hover.
  static const Color naranjaVivo = Color(0xFFF5602A);

  /// Naranja oscuro. Sombra cálida, borde de tarjeta en foco.
  static const Color naranjaOscuro = Color(0xFFA83204);

  /// Ámbar cálido. Orb secundario (esfera de luz amarilla-naranja).
  static const Color ambar = Color(0xFFF59E0B);

  /// Ámbar pálido. Highlight de borde superior de tarjeta.
  static const Color ambarClaro = Color(0xFFFDE68A);

  // ── Crema ─────────────────────────────────────────────────────────────────
  /// Crema principal. Fondo de tarjetas, texto sobre oscuro.
  static const Color crema = Color(0xFFFDF8EF);

  /// Crema con opacidad media. Texto secundario, bordes suaves.
  static const Color cremaMedio = Color(0xCCFDF8EF); // 80%

  /// Crema sutil. Bordes de campos sin foco, grilla.
  static const Color cremaFino = Color(0x33FDF8EF); // 20%

  // ── Fondo ─────────────────────────────────────────────────────────────────
  /// Fondo base oscuro. Derivado del naranja → café muy oscuro.
  /// Contraste máximo para los orbs y la tarjeta crema.
  static const Color fondoOscuro = Color(0xFF1A0D06);

  /// Capa intermedia oscura. Para capas de blur secundarias.
  static const Color fondoMedio = Color(0xFF2A1508);

  // ── Glows / sombras ───────────────────────────────────────────────────────
  /// Sombra cálida del botón primario (naranja con 50% opacidad).
  static const Color glowNaranja = Color(0x80DB4406);

  /// Sombra de tarjeta (naranja con 15% opacidad, tono suave).
  static const Color sombraTarjeta = Color(0x26DB4406);

  // ── Orbs de fondo ─────────────────────────────────────────────────────────
  /// Color base del orb naranja (35% opacidad).
  static const Color orbNaranja = Color(0x59DB4406);

  /// Color base del orb ámbar (25% opacidad).
  static const Color orbAmbar = Color(0x40F59E0B);

  /// Color base del orb naranja vivo para el accent orb.
  static const Color orbVivo = Color(0x33F5602A);

  // ── Paleta Cuaderno Editorial ─────────────────────────────────────────────
  /// Naranja principal para acciones (#F28C28).
  static const Color naranjaCuaderno = Color(0xFFF28C28);

  /// Crema suave de papel físico para modo claro (#F7F0DF).
  static const Color cremaPapel = Color(0xFFF7F0DF);

  /// Negro editorial de alto contraste para textos y títulos (#171717).
  static const Color negroEditorial = Color(0xFF171717);

  /// Gris oscuro para descripciones editoriales (#3A3A3A).
  static const Color grisOscuroEditorial = Color(0xFF3A3A3A);

  /// Gris medio para detalles estructurados (#777777).
  static const Color grisMedioEditorial = Color(0xFF777777);

  /// Gris tenue para líneas del cuaderno (#D6D0C4).
  static const Color grisLineaPapel = Color(0xFFD6D0C4);

  /// Rojo clásico para la línea vertical del margen izquierdo (#D9534F).
  static const Color rojoMargen = Color(0xFFD9534F);

  /// Rojo suavizado para margen en modo oscuro (#C94A46).
  static const Color rojoMargenOscuro = Color(0xFFC94A46);
}

