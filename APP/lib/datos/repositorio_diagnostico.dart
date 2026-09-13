import '../dominio/modelos/diagnostico_alumno.dart';
import '../dominio/modelos/examen_diagnostico.dart';
import '../dominio/modelos/intento_evaluacion.dart';
import '../dominio/modelos/progreso_examen_alumno.dart';

/// Contrato del repositorio para la gestión de intentos de evaluación,
/// diagnósticos pedagógicos y exámenes diagnósticos con variable de avance.
abstract class RepositorioDiagnostico {
  /// Registra un intento de respuesta de un ejercicio.
  Future<void> registrarIntento(IntentoEvaluacion intento);

  /// Obtiene la lista completa de intentos realizados por un usuario específico.
  Future<List<IntentoEvaluacion>> obtenerIntentosPorUsuario(String usuarioUid);

  /// Obtiene el diagnóstico pedagógico analizado del usuario.
  Future<DiagnosticoAlumno> obtenerDiagnostico(String usuarioUid);

  /// Obtiene todos los intentos registrados en la app (para vista docente/grupal).
  Future<List<IntentoEvaluacion>> obtenerTodosLosIntentos();

  /// Stream reactivo que emite el diagnóstico actualizado del usuario en tiempo real.
  Stream<DiagnosticoAlumno> diagnosticoStream(String usuarioUid);

  // --- Gestión de Exámenes Diagnósticos y Variables de Avance ---

  /// Guarda o actualiza un examen diagnóstico diseñado por el docente.
  Future<void> guardarExamen(ExamenDiagnostico examen);

  /// Obtiene la lista de todos los exámenes diagnósticos disponibles.
  Future<List<ExamenDiagnostico>> obtenerExamenes();

  /// Obtiene un examen diagnóstico específico por su identificador.
  Future<ExamenDiagnostico?> obtenerExamenPorId(String id);

  /// Elimina un examen diagnóstico.
  Future<void> eliminarExamen(String id);

  /// Registra o actualiza el progreso y calificación de un alumno en un examen.
  Future<void> registrarProgresoExamen(ProgresoExamenAlumno progreso);

  /// Obtiene el progreso de todos los alumnos que han rendido un examen específico.
  Future<List<ProgresoExamenAlumno>> obtenerProgresosDeExamen(String examenId);

  /// Obtiene el progreso de un alumno particular en un examen.
  Future<ProgresoExamenAlumno?> obtenerProgresoAlumno(String examenId, String alumnoUid);

  /// Limpia los datos en memoria.
  Future<void> limpiar();
}
