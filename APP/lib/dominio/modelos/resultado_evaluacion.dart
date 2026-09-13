import 'error_aprendizaje.dart';

/// Resultado devuelto tras evaluar la respuesta de un estudiante.
class ResultadoEvaluacion {
  const ResultadoEvaluacion({
    required this.esCorrecto,
    required this.puntaje,
    required this.retroalimentacion,
    this.errorDetectado,
    this.similitudLevenshtein = 0.0,
    this.similitudJaccard = 0.0,
    this.similitudCoseno = 0.0,
    this.similitudHibrida = 0.0,
    this.palabrasClaveEncontradas = const [],
    this.palabrasClaveFaltantes = const [],
  });

  /// Indica si la respuesta cumple con los criterios de aprobación.
  final bool esCorrecto;

  /// Calificación proporcional obtenida entre 0.0 y 1.0.
  final double puntaje;

  /// Mensaje formativo o explicativo del resultado.
  final String retroalimentacion;

  /// Error de aprendizaje identificado si la respuesta no es correcta.
  final ErrorAprendizaje? errorDetectado;

  /// Similitud normalizada calculada por distancia de edición de Levenshtein (0.0 a 1.0).
  final double similitudLevenshtein;

  /// Similitud calculada por coincidencia de tokens y n-gramas de Jaccard (0.0 a 1.0).
  final double similitudJaccard;

  /// Similitud semántica calculada mediante vectores TF-IDF y producto Coseno (0.0 a 1.0).
  final double similitudCoseno;

  /// Similitud ponderada global combinando Levenshtein + Jaccard + TF-IDF (0.0 a 1.0).
  final double similitudHibrida;

  /// Términos o fórmulas clave detectadas en la respuesta del estudiante.
  final List<String> palabrasClaveEncontradas;

  /// Términos o fórmulas clave que faltaron en la respuesta.
  final List<String> palabrasClaveFaltantes;

  /// Constructor de conveniencia para respuestas correctas simples.
  factory ResultadoEvaluacion.correcto({String mensaje = '¡Respuesta correcta!'}) {
    return ResultadoEvaluacion(
      esCorrecto: true,
      puntaje: 1.0,
      retroalimentacion: mensaje,
    );
  }

  /// Constructor de conveniencia para respuestas incorrectas simples.
  factory ResultadoEvaluacion.incorrecto({
    String mensaje = 'Respuesta incorrecta.',
    ErrorAprendizaje? error,
  }) {
    return ResultadoEvaluacion(
      esCorrecto: false,
      puntaje: 0.0,
      retroalimentacion: mensaje,
      errorDetectado: error,
    );
  }
}
