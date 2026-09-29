// ============================================================
// modelo_saludo_bienvenida.dart — Estructura de datos para saludos
//
// Desacoplada de la UI: permite añadir, quitar o modificar idiomas
// sin tocar los widgets de presentación ni la lógica de animación.
// ============================================================

import 'package:flutter/foundation.dart';

/// Modelo inmutable que representa un saludo de bienvenida en un idioma determinado.
@immutable
class SaludoBienvenida {
  const SaludoBienvenida({
    required this.texto,
    required this.idioma,
    required this.notaMarginal,
  });

  /// Texto del saludo para el título de alto impacto (ej. 'BIENVENIDO').
  final String texto;

  /// Nombre del idioma o procedencia (ej. 'Español', 'English', 'Quechua').
  final String idioma;

  /// Pequeña anotación complementaria tipo cuaderno escolar / universitario.
  final String notaMarginal;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaludoBienvenida &&
          runtimeType == other.runtimeType &&
          texto == other.texto &&
          idioma == other.idioma;

  @override
  int get hashCode => Object.hash(texto, idioma);
}

/// Catálogo centralizado y configurable de saludos de bienvenida.
abstract final class CatalogoSaludosBienvenida {
  /// Lista predeterminada de saludos en distintos idiomas.
  static const List<SaludoBienvenida> listaPorDefecto = [
    SaludoBienvenida(
      texto: 'BIENVENIDO',
      idioma: 'Español',
      notaMarginal: 'cuaderno de estudio · lección 1',
    ),
    SaludoBienvenida(
      texto: 'WELCOME',
      idioma: 'English',
      notaMarginal: 'study notebook · chapter one',
    ),
    SaludoBienvenida(
      texto: 'BEM-VINDO',
      idioma: 'Português',
      notaMarginal: 'caderno de anotações · página 1',
    ),
    SaludoBienvenida(
      texto: 'BUN VENIT',
      idioma: 'Română',
      notaMarginal: 'caiet de matematică · notițe',
    ),
    SaludoBienvenida(
      texto: 'ALLIN HAMUSQA',
      idioma: 'Quechua',
      notaMarginal: 'yachay qallariy · killka',
    ),
    SaludoBienvenida(
      texto: 'BIENVENUE',
      idioma: 'Français',
      notaMarginal: 'cahier d’exercices · première page',
    ),
    SaludoBienvenida(
      texto: 'WILLKOMMEN',
      idioma: 'Deutsch',
      notaMarginal: 'arbeitsheft mathematik · notizen',
    ),
    SaludoBienvenida(
      texto: 'BENVENUTO',
      idioma: 'Italiano',
      notaMarginal: 'quaderno di studio · prima stesura',
    ),
  ];
}
