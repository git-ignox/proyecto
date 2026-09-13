import '../diagnostico/clasificador_errores.dart';
import '../modelos/algebraico.dart';
import '../modelos/resultado_evaluacion.dart';

/// Evaluador de expresiones algebraicas y simbólicas.
class EvaluadorAlgebraico {
  const EvaluadorAlgebraico({
    this.clasificador = const ClasificadorErrores(),
  });

  final ClasificadorErrores clasificador;

  /// Normaliza una expresión matemática (limpia espacios, signos redundantes, multiplicación implícita).
  String normalizar(String expr) {
    return expr
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('+-', '-')
        .replaceAll('-+', '-')
        .replaceAll('--', '+')
        .replaceAll('++', '+')
        .replaceAll('*', '')
        .replaceAll('·', '')
        .replaceAll('×', '')
        .trim();
  }

  /// Evalúa la expresión ingresada por el estudiante.
  ResultadoEvaluacion evaluar(Algebraico ejercicio, dynamic respuesta) {
    if (respuesta == null || respuesta.toString().trim().isEmpty) {
      final err = clasificador.clasificarAlgebraico(ejercicio, '', normalizar(ejercicio.expresionCanonica));
      return ResultadoEvaluacion.incorrecto(
        mensaje: 'Debes ingresar una expresión algebraica.',
        error: err,
      );
    }

    final entradaNorm = normalizar(respuesta.toString());
    final canonicaNorm = normalizar(ejercicio.expresionCanonica);

    if (entradaNorm == canonicaNorm) {
      return ResultadoEvaluacion.correcto(
        mensaje: '¡Excelente! La expresión simplificada es totalmente correcta.',
      );
    }

    // Verificar si coincide con alguna forma equivalente aceptada
    for (final eq in ejercicio.formasEquivalentes) {
      if (entradaNorm == normalizar(eq)) {
        return ResultadoEvaluacion.correcto(
          mensaje: '¡Correcto! Es una forma equivalente válida.',
        );
      }
    }

    final err = clasificador.clasificarAlgebraico(ejercicio, entradaNorm, canonicaNorm);

    return ResultadoEvaluacion.incorrecto(
      mensaje: 'La expresión no coincide con la forma canónica esperada: ${ejercicio.expresionCanonica}.',
      error: err,
    );
  }
}
