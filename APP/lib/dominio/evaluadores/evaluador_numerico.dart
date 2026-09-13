import 'dart:math';
import '../diagnostico/clasificador_errores.dart';
import '../modelos/numerico.dart';
import '../modelos/resultado_evaluacion.dart';

/// Evaluador de respuestas numéricas (soporta enteros, decimales, fracciones y tolerancias).
class EvaluadorNumerico {
  const EvaluadorNumerico({
    this.clasificador = const ClasificadorErrores(),
  });

  final ClasificadorErrores clasificador;

  /// Intenta parsear un texto a `double`. Soporta formatos decimales ("3.14", "3,14")
  /// y fracciones simples ("3/4", "-1/2", "7/3").
  double? parsearNumero(String entrada) {
    String limpio = entrada.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (limpio.isEmpty) return null;

    // Verificar si es fracción
    if (limpio.contains('/')) {
      final partes = limpio.split('/');
      if (partes.length == 2) {
        final num = double.tryParse(partes[0]);
        final den = double.tryParse(partes[1]);
        if (num != null && den != null && den != 0) {
          return num / den;
        }
      }
    }

    // Casos especiales comunes
    if (limpio.toLowerCase() == 'pi' || limpio == 'π') return pi;
    if (limpio.toLowerCase() == 'e') return e;

    return double.tryParse(limpio);
  }

  /// Evalúa la respuesta ingresada por el estudiante contra el valor esperado.
  ResultadoEvaluacion evaluar(Numerico ejercicio, dynamic respuesta) {
    if (respuesta == null) {
      final err = clasificador.clasificarNumerico(ejercicio, null, null);
      return ResultadoEvaluacion.incorrecto(
        mensaje: 'Debes ingresar un valor numérico.',
        error: err,
      );
    }

    double? valorIngresado;
    if (respuesta is num) {
      valorIngresado = respuesta.toDouble();
    } else if (respuesta is String) {
      valorIngresado = parsearNumero(respuesta);
    }

    if (valorIngresado == null) {
      final err = clasificador.clasificarNumerico(ejercicio, respuesta, null);
      return ResultadoEvaluacion.incorrecto(
        mensaje: 'No se pudo interpretar el número ingresado. Puedes usar decimales (3.5) o fracciones (7/2).',
        error: err,
      );
    }

    final diferencia = (valorIngresado - ejercicio.valorEsperado).abs();
    final esCorrecto = diferencia <= ejercicio.tolerancia;

    if (esCorrecto) {
      return ResultadoEvaluacion.correcto(
        mensaje: '¡Correcto! El valor ingresado es exacto.',
      );
    }

    final err = clasificador.clasificarNumerico(ejercicio, respuesta, valorIngresado);

    // Si está muy cerca pero fuera de tolerancia (error de redondeo)
    if (diferencia <= ejercicio.tolerancia * 10) {
      return ResultadoEvaluacion(
        esCorrecto: false,
        puntaje: 0.5,
        retroalimentacion: 'Muy cerca, pero revisa el redondeo o la precisión decimal.',
        errorDetectado: err,
      );
    }

    final unidadTexto = ejercicio.unidad != null ? ' ${ejercicio.unidad}' : '';
    return ResultadoEvaluacion.incorrecto(
      mensaje: 'Valor incorrecto. El resultado esperado era aproximadamente ${ejercicio.valorEsperado}$unidadTexto.',
      error: err,
    );
  }
}
