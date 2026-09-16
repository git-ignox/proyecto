import '../dominio/modelos/registro_auditoria.dart';
import '../dominio/modelos/usuario_app.dart';

/// Contrato para el registro inmutable y consulta de auditoría institucional.
abstract interface class RepositorioAuditoria {
  /// Registra un evento de seguridad, control o cambio administrativo.
  Future<void> registrarEvento({
    required TipoEventoAuditoria tipo,
    required UsuarioApp usuario,
    String? cursoId,
    required String descripcion,
    Map<String, dynamic> detalles = const {},
  });

  /// Obtiene los eventos recientes ordenados cronológicamente descendente.
  Future<List<RegistroAuditoria>> obtenerEventosPorInstitucion(
    String institucionId, {
    int limite = 50,
  });

  /// Stream reactivo de auditoría para el dashboard de Dirección.
  Stream<List<RegistroAuditoria>> eventosStream(String institucionId);
}
