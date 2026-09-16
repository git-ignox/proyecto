import '../dominio/modelos/politica_dispositivo.dart';
import '../dominio/modelos/sesion_modo_clase.dart';
import '../dominio/modelos/usuario_app.dart';

/// Contrato para el ciclo de vida de las sesiones de Modo Clase y Modo Examen.
abstract interface class RepositorioSesionesClase {
  /// Inicia una nueva sesión de Modo Clase o Examen validando permisos en backend.
  Future<SesionModoClase> iniciarSesion({
    required String claseId,
    required String cursoNombre,
    required String materia,
    required UsuarioApp docente,
    required TipoModoClase tipoModo,
    PoliticaDispositivo? politicaPersonalizada,
  });

  /// Obtiene la sesión actualmente activa para una clase escolar.
  Future<SesionModoClase?> obtenerSesionActivaPorClase(String claseId);

  /// Obtiene la sesión activa de un profesor (si tiene una en curso).
  Future<SesionModoClase?> obtenerSesionActivaPorProfesor(String profesorUid);

  /// Obtiene todas las sesiones activas de una institución (para el dashboard de Dirección).
  Future<List<SesionModoClase>> obtenerSesionesActivasPorInstitucion(String institucionId);

  /// Registra la presencia de un alumno en el aula mediante QR, Wi-Fi o validación docente.
  Future<bool> registrarPresenciaAlumno({
    required String sesionId,
    required String alumnoUid,
    required String alumnoNombre,
    required MetodoPresencia metodo,
    String? tokenQrString,
  });

  /// Concede una excepción temporal para usar una app durante N minutos.
  Future<void> concederExcepcionTemporal({
    required String sesionId,
    required UsuarioApp docente,
    required String appId,
    required String appNombre,
    String? alumnoUid,
    required int minutos,
    required String motivo,
  });

  /// Libera individualmente a un estudiante por contingencia o término de actividad.
  Future<void> liberarEstudiante({
    required String sesionId,
    required UsuarioApp docente,
    required String alumnoUid,
    required String motivo,
  });

  /// Finaliza formalmente la sesión de Modo Clase / Examen.
  Future<void> finalizarSesion({
    required String sesionId,
    required UsuarioApp docente,
  });

  /// FASE 13: Botón de Emergencia Institucional (Solo Dirección).
  /// Suspende todas las restricciones en curso sin destruir las sesiones pedagógicas.
  Future<void> suspenderRestriccionesEmergencia({
    required String institucionId,
    required UsuarioApp direccion,
    required String motivo,
  });

  /// Restaura las restricciones normales tras superar la emergencia.
  Future<void> restaurarRestriccionesNormales({
    required String institucionId,
    required UsuarioApp direccion,
  });

  /// Rota y actualiza el token QR dinámico de la sesión.
  Future<String> rotarTokenPresencia(String sesionId);

  /// Stream reactivo de todas las sesiones activas de la institución.
  Stream<List<SesionModoClase>> sesionesActivasStream(String institucionId);

  /// Stream reactivo de la sesión de una clase específica.
  Stream<SesionModoClase?> sesionClaseStream(String claseId);
}
