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

  // ── Paleta Oficial Claude / Anthropic Design System ────────────────────────
  /// Terracota insignia de Claude (#D97757 / Crail Orange).
  static const Color claudeTerracota = Color(0xFFD97757);

  /// Terracota oscuro para estados hover y presionados (#C15F3C).
  static const Color claudeTerracotaOscuro = Color(0xFFC15F3C);

  /// Terracota muy claro para fondos de selección (#FBECE7).
  static const Color claudeTerracotaClaro = Color(0xFFFBECE7);

  /// Fondo apergaminado cálido insignia de Claude (#FAF9F5).
  static const Color claudeFondo = Color(0xFFFAF9F5);

  /// Fondo de tarjeta o superficie blanca cálida (#FFFFFF).
  static const Color claudeSuperficie = Color(0xFFFFFFFF);

  /// Fondo secundario de tarjeta / contenedor suave (#F3F1EA).
  static const Color claudeSuperficieSuave = Color(0xFFF3F1EA);

  /// Borde hairline sutil (#E8E6DC).
  static const Color claudeBorde = Color(0xFFE8E6DC);

  /// Borde intermedio / foco (#D5D2C7).
  static const Color claudeBordeFoco = Color(0xFFD5D2C7);

  /// Texto oscuro principal (#141413 / Obsidian Black).
  static const Color claudeTextoPrincipal = Color(0xFF141413);

  /// Texto secundario / gris medio (#73726C).
  static const Color claudeTextoSecundario = Color(0xFF73726C);

  /// Texto atenuado / placeholder (#B0AEA5).
  static const Color claudeTextoAtenuado = Color(0xFFB0AEA5);

  /// Verde salvia / oliva (#788C5D).
  static const Color claudeVerde = Color(0xFF788C5D);

  /// Verde salvia claro (#EEF2E8).
  static const Color claudeVerdeClaro = Color(0xFFEEF2E8);

  /// Azul pizarra (#6A9BCC).
  static const Color claudeAzul = Color(0xFF6A9BCC);

  /// Azul pizarra claro (#E8F0F8).
  static const Color claudeAzulClaro = Color(0xFFE8F0F8);

  /// Ámbar / Miel cálido (#D29034).
  static const Color claudeAmbar = Color(0xFFD29034);

  /// Ámbar claro (#FAF2E6).
  static const Color claudeAmbarClaro = Color(0xFFFAF2E6);

  /// Fondo oscuro modo noche (#1F1E1D).
  static const Color claudeFondoOscuro = Color(0xFF1F1E1D);

  /// Superficie oscura modo noche (#262523).
  static const Color claudeSuperficieOscura = Color(0xFF262523);
}

