import '../diagnostico/clasificador_errores.dart';
import '../modelos/resultado_evaluacion.dart';
import '../modelos/seleccion_multiple.dart';

/// Evaluador para ejercicios de selección múltiple (opción única o múltiple).
class EvaluadorSeleccionMultiple {
  const EvaluadorSeleccionMultiple({
    this.clasificador = const ClasificadorErrores(),
  });

  final ClasificadorErrores clasificador;

  /// Evalúa [seleccionados] (puede ser `String` con un ID o `List<String>` con múltiples IDs).
  ResultadoEvaluacion evaluar(SeleccionMultiple ejercicio, dynamic seleccionados) {
    List<String> idsSeleccionados = [];

    if (seleccionados is String) {
      if (seleccionados.trim().isNotEmpty) {
        idsSeleccionados = [seleccionados.trim()];
      }
    } else if (seleccionados is List) {
      idsSeleccionados = seleccionados.map((e) => e.toString().trim()).toList();
    }

    if (idsSeleccionados.isEmpty) {
      final err = clasificador.clasificarSeleccionMultiple(ejercicio, idsSeleccionados);
      return ResultadoEvaluacion.incorrecto(
        mensaje: 'No has seleccionado ninguna opción.',
        error: err,
      );
    }

    final correctos = ejercicio.idsCorrectos.toSet();
    final seleccionadosSet = idsSeleccionados.toSet();

    final esExacto = correctos.length == seleccionadosSet.length &&
        correctos.containsAll(seleccionadosSet);

    if (esExacto) {
      return ResultadoEvaluacion.correcto(
        mensaje: '¡Excelente! Has seleccionado la respuesta correcta.',
      );
    }

    final err = clasificador.clasificarSeleccionMultiple(ejercicio, idsSeleccionados);

    // Calcular puntaje parcial si permite selección múltiple
    if (ejercicio.permiteMultiple && correctos.isNotEmpty) {
      final aciertos = seleccionadosSet.intersection(correctos).length;
      final desaciertos = seleccionadosSet.difference(correctos).length;
      final puntajeCalculado = ((aciertos - desaciertos) / correctos.length).clamp(0.0, 1.0);

      return ResultadoEvaluacion(
        esCorrecto: false,
        puntaje: puntajeCalculado,
        retroalimentacion: 'Has acertado $aciertos de ${correctos.length} opciones correctas.',
        errorDetectado: err,
      );
    }

    // Buscar si hay retroalimentación personalizada en la opción elegida
    String mensaje = 'La opción seleccionada no es correcta.';
    if (idsSeleccionados.length == 1) {
      final opcionElegida = ejercicio.opciones.firstWhere(
        (o) => o.id == idsSeleccionados.first,
        orElse: () => const Opcion(id: '', texto: '', esCorrecta: false),
      );
      if (opcionElegida.retroalimentacion != null &&
          opcionElegida.retroalimentacion!.isNotEmpty) {
        mensaje = opcionElegida.retroalimentacion!;
      }
    }

    return ResultadoEvaluacion.incorrecto(
      mensaje: mensaje,
      error: err,
    );
  }
}
