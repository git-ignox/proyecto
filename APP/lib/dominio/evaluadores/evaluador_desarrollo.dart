import '../algoritmos/motor_similitud.dart';
import '../diagnostico/clasificador_errores.dart';
import '../modelos/desarrollo.dart';
import '../modelos/resultado_evaluacion.dart';

/// Evaluador de preguntas de desarrollo y respuestas abiertas de matemáticas.
/// Utiliza el motor híbrido de similitud (Levenshtein + Jaccard + TF-IDF/Coseno)
/// y verificación difusa de conceptos y fórmulas clave.
class EvaluadorDesarrollo {
  const EvaluadorDesarrollo({
    this.motorSimilitud = const MotorSimilitud(),
    this.clasificador = const ClasificadorErrores(),
  });

  final MotorSimilitud motorSimilitud;
  final ClasificadorErrores clasificador;

  /// Evalúa la respuesta abierta del estudiante contra la solución modelo del ejercicio.
  ResultadoEvaluacion evaluar(Desarrollo ejercicio, dynamic respuesta) {
    final textoRespuesta = respuesta?.toString().trim() ?? '';

    if (textoRespuesta.isEmpty) {
      final err = clasificador.clasificarDesarrollo(
        ejercicio,
        const AnalisisSimilitud(
          similitudLevenshtein: 0,
          similitudJaccard: 0,
          similitudCoseno: 0,
          similitudHibrida: 0,
          palabrasClaveEncontradas: [],
          palabrasClaveFaltantes: [],
        ),
      );
      return ResultadoEvaluacion(
        esCorrecto: false,
        puntaje: 0.0,
        retroalimentacion: 'Debes escribir tu desarrollo o procedimiento para evaluar.',
        errorDetectado: err,
      );
    }

    final analisis = motorSimilitud.analizar(
      respuesta: textoRespuesta,
      solucion: ejercicio.solucion,
      palabrasClave: ejercicio.palabrasClave,
    );

    // Cálculo del puntaje integrado
    double puntajeCalculado;
    if (ejercicio.palabrasClave.isNotEmpty) {
      puntajeCalculado = (0.50 * analisis.similitudHibrida +
              0.50 * analisis.porcentajePalabrasClave)
          .clamp(0.0, 1.0);
    } else {
      puntajeCalculado = analisis.similitudHibrida;
    }

    final esCorrecto = puntajeCalculado >= ejercicio.umbralSimilitud;

    // Construcción de la retroalimentación pedagógica
    final buffer = StringBuffer();
    if (esCorrecto) {
      if (puntajeCalculado >= 0.80) {
        buffer.write('¡Excelente desarrollo! Tu respuesta es muy completa y clara.');
      } else {
        buffer.write('¡Buen trabajo! Tu procedimiento contiene las ideas principales correctas.');
      }
    } else {
      if (puntajeCalculado >= 0.40) {
        buffer.write('Respuesta parcial. Tienes nociones correctas pero faltan detalles del procedimiento.');
      } else {
        buffer.write('Tu respuesta difiere significativamente de la solución esperada.');
      }
    }

    if (analisis.palabrasClaveFaltantes.isNotEmpty) {
      buffer.write(' Te faltó mencionar o calcular: ${analisis.palabrasClaveFaltantes.join(", ")}.');
    }

    final err = esCorrecto ? null : clasificador.clasificarDesarrollo(ejercicio, analisis);

    return ResultadoEvaluacion(
      esCorrecto: esCorrecto,
      puntaje: puntajeCalculado,
      retroalimentacion: buffer.toString(),
      errorDetectado: err,
      similitudLevenshtein: analisis.similitudLevenshtein,
      similitudJaccard: analisis.similitudJaccard,
      similitudCoseno: analisis.similitudCoseno,
      similitudHibrida: analisis.similitudHibrida,
      palabrasClaveEncontradas: analisis.palabrasClaveEncontradas,
      palabrasClaveFaltantes: analisis.palabrasClaveFaltantes,
    );
  }
}
