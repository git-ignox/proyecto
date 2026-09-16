import '../dominio/modelos/evaluacion.dart';

/// Contrato abstracto para la persistencia y gestión de evaluaciones y notas.
abstract class RepositorioEvaluaciones {
  /// Obtiene todas las evaluaciones registradas para una clase escolar.
  Future<List<Evaluacion>> obtenerEvaluacionesPorClase(String claseId);

  /// Obtiene una evaluación específica por su identificador.
  Future<Evaluacion?> obtenerEvaluacionPorId(String id);

  /// Crea y registra una nueva evaluación.
  Future<Evaluacion> crearEvaluacion(Evaluacion evaluacion);

  /// Elimina una evaluación y sus notas asociadas.
  Future<bool> eliminarEvaluacion(String evaluacionId);

  /// Obtiene todas las calificaciones registradas para una evaluación específica.
  Future<List<NotaEvaluacion>> obtenerNotasPorEvaluacion(String evaluacionId);

  /// Obtiene todas las notas de todas las evaluaciones pertenecientes a una clase.
  Future<List<NotaEvaluacion>> obtenerNotasPorClase(String claseId);

  /// Obtiene el historial de notas de un estudiante específico.
  Future<List<NotaEvaluacion>> obtenerNotasPorAlumno(String alumnoUid);

  /// Guarda o actualiza una calificación individual (para pruebas rápidas o edición).
  Future<NotaEvaluacion> guardarNota(NotaEvaluacion nota);

  /// Guarda en lote una lista de notas (por ejemplo, tras importar un archivo CSV).
  Future<int> guardarNotasEnBloque(List<NotaEvaluacion> notas);

  /// Actualiza una nota cargada previamente (útil ante errores de tipeo).
  Future<bool> actualizarNota(NotaEvaluacion nota);

  /// Elimina una nota específica.
  Future<bool> eliminarNota(String notaId);

  /// Flujo reactivo de evaluaciones para una clase.
  Stream<List<Evaluacion>> streamEvaluacionesPorClase(String claseId);

  /// Flujo reactivo de notas para una clase.
  Stream<List<NotaEvaluacion>> streamNotasPorClase(String claseId);
}
