import 'posicion_curricular.dart';
import 'tipo_ejercicio.dart';

/// Clase base inmutable para cualquier ejercicio matemático en la app.
/// Organizado mediante 3 parámetros numéricos: tema, subtema y lección (e.g. 3.2.1).
abstract class Ejercicio implements Comparable<Ejercicio> {
  const Ejercicio({
    required this.id,
    required this.posicion,
    required this.nivel,
    required this.enunciado,
    this.tags = const [],
    this.pistas = const [],
    this.explicacion = '',
    this.puntos = 10,
  });

  /// Identificador único del ejercicio.
  final String id;

  /// Etiquetas conceptuales o de habilidades (e.g. ['aritmetica', 'suma', 'acarreo']).
  final List<String> tags;

  /// Posición curricular basada en los 3 parámetros numéricos: tema, subtema, lección.
  final PosicionCurricular posicion;

  /// Nivel de dificultad (1 = básico, 2 = intermedio, 3 = avanzado).
  final int nivel;

  /// Enunciado del problema.
  final String enunciado;

  /// Pistas de ayuda progresivas.
  final List<String> pistas;

  /// Explicación pedagógica de la solución.
  final String explicacion;

  /// Puntuación del ejercicio.
  final int puntos;

  /// Tipo específico de ejercicio.
  TipoEjercicio get tipo;

  // Acceso directo a los 3 parámetros numéricos de organización:
  int get tema => posicion.tema;
  int get subtema => posicion.subtema;
  int get leccion => posicion.leccion;
  String get codigoTema => posicion.codigo;

  @override
  int compareTo(Ejercicio other) => posicion.compareTo(other.posicion);
}
