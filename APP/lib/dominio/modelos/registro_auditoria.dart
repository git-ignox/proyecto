import 'usuario_app.dart';

/// Tipos de eventos auditables con relevancia en seguridad, cumplimiento y gestión pedagógica.
enum TipoEventoAuditoria {
  inicioModoClase,
  finModoClase,
  inicioModoExamen,
  finModoExamen,
  cambioPolitica,
  cambioPermisos,
  excepcionTemporal,
  liberacionEstudiante,
  incidenciaDispositivo,
  activacionEmergencia,
  restauracionEmergencia;

  String get etiqueta {
    switch (this) {
      case TipoEventoAuditoria.inicioModoClase:
        return 'Inicio de Modo Clase';
      case TipoEventoAuditoria.finModoClase:
        return 'Fin de Modo Clase';
      case TipoEventoAuditoria.inicioModoExamen:
        return 'Activación de Modo Examen';
      case TipoEventoAuditoria.finModoExamen:
        return 'Finalización de Modo Examen';
      case TipoEventoAuditoria.cambioPolitica:
        return 'Modificación de Política Institucional';
      case TipoEventoAuditoria.cambioPermisos:
        return 'Actualización de Permisos Docentes';
      case TipoEventoAuditoria.excepcionTemporal:
        return 'Concesión de Excepción Temporal';
      case TipoEventoAuditoria.liberacionEstudiante:
        return 'Liberación de Estudiante';
      case TipoEventoAuditoria.incidenciaDispositivo:
        return 'Incidencia de Foco / Desconexión';
      case TipoEventoAuditoria.activacionEmergencia:
        return 'Suspensión por Emergencia Institucional';
      case TipoEventoAuditoria.restauracionEmergencia:
        return 'Restauración de Restricciones Normales';
    }
  }

  String get iconoNombre {
    switch (this) {
      case TipoEventoAuditoria.inicioModoClase:
        return 'play_arrow';
      case TipoEventoAuditoria.finModoClase:
        return 'stop';
      case TipoEventoAuditoria.inicioModoExamen:
        return 'assignment_late';
      case TipoEventoAuditoria.finModoExamen:
        return 'task_alt';
      case TipoEventoAuditoria.cambioPolitica:
        return 'policy';
      case TipoEventoAuditoria.cambioPermisos:
        return 'vpn_key';
      case TipoEventoAuditoria.excepcionTemporal:
        return 'alarm_add';
      case TipoEventoAuditoria.liberacionEstudiante:
        return 'lock_open';
      case TipoEventoAuditoria.incidenciaDispositivo:
        return 'warning_amber';
      case TipoEventoAuditoria.activacionEmergencia:
        return 'emergency';
      case TipoEventoAuditoria.restauracionEmergencia:
        return 'restart_alt';
    }
  }
}

/// Registro inmutable de auditoría para trazabilidad institucional.
class RegistroAuditoria {
  const RegistroAuditoria({
    required this.id,
    required this.fecha,
    required this.tipo,
    required this.usuarioUid,
    required this.usuarioNombre,
    required this.rolUsuario,
    required this.institucionId,
    this.cursoId,
    required this.descripcion,
    this.detalles = const {},
  });

  final String id;
  final DateTime fecha;
  final TipoEventoAuditoria tipo;
  final String usuarioUid;
  final String usuarioNombre;
  final RolUsuario rolUsuario;
  final String institucionId;
  final String? cursoId;
  final String descripcion;
  final Map<String, dynamic> detalles;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha': fecha.toIso8601String(),
      'tipo': tipo.name,
      'usuarioUid': usuarioUid,
      'usuarioNombre': usuarioNombre,
      'rolUsuario': rolUsuario.name,
      'institucionId': institucionId,
      'cursoId': cursoId,
      'descripcion': descripcion,
      'detalles': detalles,
    };
  }

  factory RegistroAuditoria.fromMap(Map<String, dynamic> map) {
    return RegistroAuditoria(
      id: map['id'] as String? ?? '',
      fecha: DateTime.tryParse(map['fecha'] as String? ?? '') ?? DateTime.now(),
      tipo: TipoEventoAuditoria.values.firstWhere(
        (t) => t.name == map['tipo'],
        orElse: () => TipoEventoAuditoria.inicioModoClase,
      ),
      usuarioUid: map['usuarioUid'] as String? ?? '',
      usuarioNombre: map['usuarioNombre'] as String? ?? 'Usuario',
      rolUsuario: RolUsuario.values.firstWhere(
        (r) => r.name == map['rolUsuario'],
        orElse: () => RolUsuario.profesor,
      ),
      institucionId: map['institucionId'] as String? ?? 'INST-SAN-MARTIN',
      cursoId: map['cursoId'] as String?,
      descripcion: map['descripcion'] as String? ?? '',
      detalles: (map['detalles'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }
}
