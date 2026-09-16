import '../dominio/modelos/reporte_pedagogico.dart';

/// Contrato abstracto para la persistencia y consulta de reportes pedagógicos.
abstract class RepositorioReportes {
  /// Obtiene los reportes de una clase, opcionalmente filtrados por período.
  Future<List<ReporteEstudiante>> obtenerReportesPorClase(
    String claseId, {
    String? periodo,
  });

  /// Obtiene todos los reportes históricos generados para un estudiante.
  Future<List<ReporteEstudiante>> obtenerReportesPorAlumno(String alumnoUid);

  /// Obtiene un reporte específico por su ID.
  Future<ReporteEstudiante?> obtenerReportePorId(String id);

  /// Guarda o actualiza un reporte pedagógico.
  Future<void> guardarReporte(ReporteEstudiante reporte);

  /// Guarda múltiples reportes en bloque (ej. al congelar el período para todo el curso).
  Future<void> guardarReportesEnBloque(List<ReporteEstudiante> reportes);

  /// Elimina un reporte por su ID.
  Future<void> eliminarReporte(String id);

  /// Stream reactivo de los reportes de una clase.
  Stream<List<ReporteEstudiante>> vigilarReportesPorClase(
    String claseId, {
    String? periodo,
  });

  /// Stream reactivo de los reportes de un alumno.
  Stream<List<ReporteEstudiante>> vigilarReportesPorAlumno(String alumnoUid);
}
