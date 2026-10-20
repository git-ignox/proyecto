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

import 'package:flutter/material.dart';

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

  // ── Paleta Oficial Claude / macOS Dark Glass System ────────────────────────
  /// Terracota insignia de Claude (#D97757 / Crail Orange).
  static const Color claudeTerracota = Color(0xFFD97757);

  /// Terracota oscuro para estados hover y presionados (#C15F3C).
  static const Color claudeTerracotaOscuro = Color(0xFFC15F3C);

  /// Terracota traslúcido para fondos de selección e insignias glass (#D97757 con 18% opacidad).
  static const Color claudeTerracotaClaro = Color(0x2ED97757);

  /// Fondo oscuro grafito insignia del escritorio macOS (#121110).
  static const Color claudeFondo = Color(0xFF121110);

  /// Fondo de tarjeta o superficie de vidrio oscuro (#1E1D1B).
  static const Color claudeSuperficie = Color(0xFF1E1D1B);

  /// Fondo secundario de contenedor suave / pill (#262523).
  static const Color claudeSuperficieSuave = Color(0xFF262523);

  /// Borde hairline sutil blanco brillante traslúcido (14% opacidad).
  static const Color claudeBorde = Color(0x24FFFFFF);

  /// Borde intermedio / foco blanco traslúcido (40% opacidad).
  static const Color claudeBordeFoco = Color(0x66FFFFFF);

  /// Texto blanco hueso principal de alto contraste (#F5F3ED).
  static const Color claudeTextoPrincipal = Color(0xFFF5F3ED);

  /// Texto secundario plateado suave (#A3A199).
  static const Color claudeTextoSecundario = Color(0xFFA3A199);

  /// Texto atenuado / placeholder (#6E6C66).
  static const Color claudeTextoAtenuado = Color(0xFF6E6C66);

  /// Verde salvia / esmeralda (#34D399).
  static const Color claudeVerde = Color(0xFF34D399);

  /// Verde translúcido glass.
  static const Color claudeVerdeClaro = Color(0x2634D399);

  /// Azul pizarra / cielo (#38BDF8).
  static const Color claudeAzul = Color(0xFF38BDF8);

  /// Azul translúcido glass.
  static const Color claudeAzulClaro = Color(0x2638BDF8);

  /// Ámbar / Miel cálido (#FBBF24).
  static const Color claudeAmbar = Color(0xFFFBBF24);

  /// Ámbar translúcido glass.
  static const Color claudeAmbarClaro = Color(0x26FBBF24);

  /// Fondo oscuro modo noche (#121110).
  static const Color claudeFondoOscuro = Color(0xFF121110);

  /// Superficie oscura modo noche (#1E1D1B).
  static const Color claudeSuperficieOscura = Color(0xFF1E1D1B);

  /// Botón primario sólido crema / hueso (#ECE7DE).
  static const Color claudeBotonPrimario = Color(0xFFECE7DE);

  /// Texto de botón primario carbón oscuro (#1E1D1B).
  static const Color claudeBotonPrimarioTexto = Color(0xFF1E1D1B);

  // ── Paleta Modo Claro: Blanco y Crema ────────────────────────────────────
  /// Fondo cálido suave blanco y crema para modo claro (#F9F7F1).
  static const Color cremaFondo = Color(0xFFF9F7F1);

  /// Superficie principal modo claro: blanco crema puro (#FFFDF8).
  static const Color cremaSuperficie = Color(0xFFFFFDF8);

  /// Superficie secundaria suave modo claro (#F4EFE6).
  static const Color cremaSuperficieSuave = Color(0xFFF4EFE6);

  /// Borde sutil para modo claro (#E5DFD2 / 12% negro).
  static const Color cremaBorde = Color(0x1F1E1D1B);

  /// Borde destacado / foco modo claro (#331E1D1B).
  static const Color cremaBordeFoco = Color(0x381E1D1B);

  /// Texto principal carbón oscuro en modo claro (#1E1D1B).
  static const Color cremaTextoPrincipal = Color(0xFF1E1D1B);

  /// Texto secundario gris cálido en modo claro (#737067).
  static const Color cremaTextoSecundario = Color(0xFF737067);

  /// Texto atenuado en modo claro (#9E9B91).
  static const Color cremaTextoAtenuado = Color(0xFF9E9B91);

  /// Botón primario para modo claro (#1E1D1B).
  static const Color cremaBotonPrimario = Color(0xFF1E1D1B);

  /// Texto de botón primario modo claro (#FFFDF8).
  static const Color cremaBotonPrimarioTexto = Color(0xFFFFFDF8);

  // ── Helpers Reactivos al Tema ───────────────────────────────────────────
  /// Retorna si el contexto actual está en modo oscuro.
  static bool esOscuro(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Fondo adaptable según el tema (grafito oscuro en noche, crema cálido en día).
  static Color fondo(BuildContext context) =>
      esOscuro(context) ? claudeFondo : cremaFondo;

  /// Superficie adaptable según el tema.
  static Color superficie(BuildContext context) =>
      esOscuro(context) ? claudeSuperficie : cremaSuperficie;

  /// Superficie suave adaptable (pills, chips, recuadros secundarios).
  static Color superficieSuave(BuildContext context) =>
      esOscuro(context) ? claudeSuperficieSuave : cremaSuperficieSuave;

  /// Borde hairline adaptable según el tema.
  static Color borde(BuildContext context) =>
      esOscuro(context) ? claudeBorde : cremaBorde;

  /// Borde con foco / hover adaptable.
  static Color bordeFoco(BuildContext context) =>
      esOscuro(context) ? claudeBordeFoco : cremaBordeFoco;

  /// Texto principal de alto contraste adaptable.
  static Color textoPrincipal(BuildContext context) =>
      esOscuro(context) ? claudeTextoPrincipal : cremaTextoPrincipal;

  /// Texto secundario adaptable.
  static Color textoSecundario(BuildContext context) =>
      esOscuro(context) ? claudeTextoSecundario : cremaTextoSecundario;

  /// Texto atenuado adaptable.
  static Color textoAtenuado(BuildContext context) =>
      esOscuro(context) ? claudeTextoAtenuado : cremaTextoAtenuado;

  /// Glow cálido emanando de detrás del widget (terracota en oscuro, ámbar/terracota suave en claro).
  static List<BoxShadow> glowDetras(
    BuildContext context, {
    Color? color,
    double blur = 38.0,
    double spread = 2.0,
    double intensidad = 1.0,
  }) {
    final dark = esOscuro(context);
    final baseAlpha = dark ? 0.28 : 0.16;
    final glow = color != null
        ? color.withValues(alpha: color.a * intensidad)
        : (dark
            ? const Color(0xFFD97757).withValues(alpha: baseAlpha * intensidad)
            : const Color(0xFFD97757).withValues(alpha: baseAlpha * intensidad));

    if (dark) {
      return [
        BoxShadow(
          color: glow,
          blurRadius: blur,
          spreadRadius: spread,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.45),
          blurRadius: blur * 0.7,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.20),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
    } else {
      return [
        BoxShadow(
          color: glow,
          blurRadius: blur,
          spreadRadius: spread,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFF2A1508).withValues(alpha: 0.08),
          blurRadius: blur * 0.5,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
    }
  }
}

