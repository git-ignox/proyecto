import '../dominio/modelos/curriculo.dart';

/// Contrato abstracto para la persistencia y consulta de planes y unidades curriculares.
abstract class RepositorioCurriculo {
  /// Obtiene todos los planes curriculares disponibles (oficiales del sistema y creados por el docente).
  Future<List<PlanCurricular>> obtenerPlanesCurriculares({String? profesorUid});

  /// Busca un plan curricular específico por su ID único.
  Future<PlanCurricular?> obtenerPlanPorId(String id);

  /// Obtiene el plan curricular asignado actualmente a una clase escolar, o null si no tiene.
  Future<PlanCurricular?> obtenerPlanDeClase(String claseId);

  /// Asigna un plan curricular oficial a una clase específica.
  Future<void> asignarPlanAClase(String claseId, String planId);

  /// Guarda o actualiza un plan curricular.
  Future<void> guardarPlanCurricular(PlanCurricular plan);

  /// Elimina un plan curricular por su ID.
  Future<void> eliminarPlanCurricular(String planId);
}
