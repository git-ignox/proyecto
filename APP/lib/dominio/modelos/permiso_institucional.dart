import 'usuario_app.dart';

/// Catálogo centralizado de permisos institucionales del sistema educativo.
/// Los permisos deben validarse tanto en la UI (para UX) como en repositorios/servicios (backend/autoridad).
class PermisoInstitucional {
  // Constantes de permisos
  static const String activarModoClase = 'activar_modo_clase';
  static const String activarModoExamen = 'activar_modo_examen';
  static const String liberarEstudiante = 'liberar_estudiante';
  static const String permitirAppTemporalmente = 'permitir_app_temporalmente';
  static const String modificarContenido = 'modificar_contenido';
  static const String administrarCurso = 'administrar_curso';
  static const String verReportes = 'ver_reportes';
  static const String administrarInstitucion = 'administrar_institucion';
  static const String omitirPoliticaInstitucional = 'omitir_politica_institucional';
  static const String suspenderEmergencia = 'suspender_emergencia';

  /// Todos los permisos existentes en el sistema
  static const List<String> todosLosPermisos = [
    activarModoClase,
    activarModoExamen,
    liberarEstudiante,
    permitirAppTemporalmente,
    modificarContenido,
    administrarCurso,
    verReportes,
    administrarInstitucion,
    omitirPoliticaInstitucional,
    suspenderEmergencia,
  ];

  /// Nombre amigable de cada permiso para la UI
  static String etiqueta(String permiso) {
    switch (permiso) {
      case activarModoClase:
        return 'Iniciar Modo Clase';
      case activarModoExamen:
        return 'Activar Modo Examen Riguroso';
      case liberarEstudiante:
        return 'Liberar Estudiante Individual';
      case permitirAppTemporalmente:
        return 'Conceder Excepción Temporal de App (5-20m)';
      case modificarContenido:
        return 'Crear y Modificar Contenido Educativo';
      case administrarCurso:
        return 'Administrar Alumnos y Cursos';
      case verReportes:
        return 'Ver Métricas y Reportes';
      case administrarInstitucion:
        return 'Administrar Institución y Políticas';
      case omitirPoliticaInstitucional:
        return 'Omitir Bloqueos Críticos Institucionales';
      case suspenderEmergencia:
        return 'Activar Botón de Emergencia Institucional';
      default:
        return permiso;
    }
  }

  /// Explicación pedagógica y técnica del permiso
  static String descripcion(String permiso) {
    switch (permiso) {
      case activarModoClase:
        return 'Permite poner en marcha el Modo Clase en los cursos asignados.';
      case activarModoExamen:
        return 'Permite bloquear el dispositivo exclusivamente en la evaluación sin utilidades.';
      case liberarEstudiante:
        return 'Permite desactivar la supervisión para un alumno puntual por contingencia.';
      case permitirAppTemporalmente:
        return 'Permite otorgar acceso a apps externas (ej. YouTube, GeoGebra) por tiempo acotado.';
      case modificarContenido:
        return 'Permite crear nuevos ejercicios y evaluaciones pedagógicas.';
      case administrarCurso:
        return 'Permite matricular alumnos y gestionar las clases.';
      case verReportes:
        return 'Permite consultar las estadísticas de cumplimiento y brechas de aprendizaje.';
      case administrarInstitucion:
        return 'Acceso completo a la configuración del colegio, profesores y horarios.';
      case omitirPoliticaInstitucional:
        return 'Habilita levantar bloqueos estrictos definidos por Dirección.';
      case suspenderEmergencia:
        return 'Facultad de suspender todas las restricciones del colegio ante emergencias.';
      default:
        return '';
    }
  }

  /// Permisos por defecto según el rol del usuario
  static List<String> permisosPorDefecto(RolUsuario rol) {
    switch (rol) {
      case RolUsuario.direccion:
        return List.from(todosLosPermisos);
      case RolUsuario.profesor:
        return [
          activarModoClase,
          liberarEstudiante,
          administrarCurso,
          modificarContenido,
          verReportes,
        ];
      case RolUsuario.alumno:
        return const [];
    }
  }

  /// Validador de autoridad: comprueba si el usuario tiene la capacidad solicitada.
  static bool tienePermiso(UsuarioApp usuario, String permiso) {
    // Dirección tiene acceso total
    if (usuario.rol == RolUsuario.direccion) return true;

    // Los alumnos nunca tienen permisos de gestión o control
    if (usuario.rol == RolUsuario.alumno) return false;

    // Verificar si está en sus permisos por defecto
    final porDefecto = permisosPorDefecto(usuario.rol);
    if (porDefecto.contains(permiso)) return true;

    // Verificar si Dirección le concedió este permiso específico
    return usuario.permisosEspecificos.contains(permiso);
  }
}
