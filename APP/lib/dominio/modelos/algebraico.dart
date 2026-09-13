import 'ejercicio.dart';
import 'tipo_ejercicio.dart';

/// Ejercicio con respuesta de expresión algebraica o simbólica.
class Algebraico extends Ejercicio {
  const Algebraico({
    required super.id,
    required super.posicion,
    required super.nivel,
    required super.enunciado,
    required this.expresionCanonica,
    this.formasEquivalentes = const [],
    super.tags,
    super.pistas,
    super.explicacion,
    super.puntos,
  });

  /// Expresión canónica simplificada esperada (e.g. "(x-3)(x+3)").
  final String expresionCanonica;

  /// Formas equivalentes válidas aceptadas (e.g. "(x+3)(x-3)").
  final List<String> formasEquivalentes;

  @override
  TipoEjercicio get tipo => TipoEjercicio.algebraico;
}
