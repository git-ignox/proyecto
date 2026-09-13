import 'ejercicio.dart';
import 'tipo_ejercicio.dart';

/// Ejercicio de desarrollo o respuesta abierta matemática.
class Desarrollo extends Ejercicio {
  const Desarrollo({
    required super.id,
    required super.posicion,
    required super.nivel,
    required super.enunciado,
    required this.solucion,
    this.palabrasClave = const [],
    this.umbralSimilitud = 0.60,
    super.tags,
    super.pistas,
    super.explicacion,
    super.puntos,
  });

  /// Solución o respuesta modelo/ejemplo esperada.
  final String solucion;

  /// Conceptos, variables, fórmulas o términos indispensables.
  final List<String> palabrasClave;

  /// Umbral mínimo de similitud combinada.
  final double umbralSimilitud;

  @override
  TipoEjercicio get tipo => TipoEjercicio.desarrollo;
}
