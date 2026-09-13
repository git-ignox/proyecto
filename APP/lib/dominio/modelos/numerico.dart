import 'ejercicio.dart';
import 'tipo_ejercicio.dart';

/// Ejercicio con respuesta numérica (admite enteros, decimales, fracciones y tolerancias).
class Numerico extends Ejercicio {
  const Numerico({
    required super.id,
    required super.posicion,
    required super.nivel,
    required super.enunciado,
    required this.valorEsperado,
    this.tolerancia = 0.0001,
    this.unidad,
    super.tags,
    super.pistas,
    super.explicacion,
    super.puntos,
  });

  /// Valor numérico exacto esperado (e.g. 3.1415, 42.0, 0.75).
  final double valorEsperado;

  /// Margen de error absoluto permitido (|valor - valorEsperado| <= tolerancia).
  final double tolerancia;

  /// Unidad de medida requerida u opcional (e.g. "cm", "m/s", "°").
  final String? unidad;

  @override
  TipoEjercicio get tipo => TipoEjercicio.numerico;
}
