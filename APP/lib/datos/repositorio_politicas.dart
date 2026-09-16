import '../dominio/modelos/politica_dispositivo.dart';
import '../dominio/modelos/usuario_app.dart';

/// Contrato para la administración y resolución jerárquica de políticas de dispositivos.
abstract interface class RepositorioPoliticas {
  /// Obtiene todas las políticas registradas en la institución.
  Future<List<PoliticaDispositivo>> obtenerPoliticasPorInstitucion(String institucionId);

  /// Obtiene una política específica por su ID.
  Future<PoliticaDispositivo?> obtenerPoliticaPorId(String id);

  /// Crea o actualiza una política (Valida permisos en backend).
  Future<void> guardarPolitica(
    PoliticaDispositivo politica, {
    required UsuarioApp usuario,
  });

  /// Elimina una política (Requiere permiso de Dirección).
  Future<void> eliminarPolitica(
    String id, {
    required UsuarioApp usuario,
  });

  /// Resuelve la política efectiva aplicando la cascada de jerarquía:
  /// Institución -> Curso -> Materia -> Docente.
  /// REGLA: Los bloqueos críticos institucionales son inviolables salvo autorización explícita.
  PoliticaEfectiva resolverPoliticaEfectiva({
    required String institucionId,
    String? cursoId,
    String? materia,
    UsuarioApp? docente,
  });

  /// Stream reactivo de políticas de la institución.
  Stream<List<PoliticaDispositivo>> politicasStream(String institucionId);
}
