import 'ejercicio.dart';
import 'tipo_ejercicio.dart';

/// Representa una alternativa u opción en un ejercicio de selección múltiple.
class Opcion {
  const Opcion({
    required this.id,
    required this.texto,
    required this.esCorrecta,
    this.retroalimentacion,
  });

  /// Identificador único de la opción (e.g. "a", "b", "c").
  final String id;

  /// Texto o contenido matemático de la opción.
  final String texto;

  /// Indica si esta opción es correcta.
  final bool esCorrecta;

  /// Mensaje explicativo específico al seleccionar esta opción.
  final String? retroalimentacion;
}

/// Ejercicio de selección múltiple (única o múltiple respuesta).
class SeleccionMultiple extends Ejercicio {
  const SeleccionMultiple({
    required super.id,
    required super.posicion,
    required super.nivel,
    required super.enunciado,
    required this.opciones,
    this.permiteMultiple = false,
    super.tags,
    super.pistas,
    super.explicacion,
    super.puntos,
  });

  /// Lista de opciones disponibles.
  final List<Opcion> opciones;

  /// Permite seleccionar más de una opción válida.
  final bool permiteMultiple;

  @override
  TipoEjercicio get tipo => TipoEjercicio.seleccionMultiple;

  /// Retorna los IDs de las opciones que son correctas.
  List<String> get idsCorrectos =>
      opciones.where((o) => o.esCorrecta).map((o) => o.id).toList();
}
