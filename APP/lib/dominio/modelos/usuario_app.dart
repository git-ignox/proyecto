import 'permiso_institucional.dart';

/// Roles de usuario dentro de la aplicación.
enum RolUsuario {
  alumno,
  profesor,
  direccion;

  String get etiqueta {
    switch (this) {
      case RolUsuario.alumno:
        return 'Alumno 🎒';
      case RolUsuario.profesor:
        return 'Profesor 👨‍🏫';
      case RolUsuario.direccion:
        return 'Dirección 🏛️';
    }
  }
}

/// Modelo que representa un usuario autenticado en la aplicación.
class UsuarioApp {
  const UsuarioApp({
    required this.uid,
    this.email,
    required this.nombre,
    required this.rol,
    this.esAnonimo = false,
    this.fotoUrl,
    this.puntosAcumulados = 0,
    this.ejerciciosResueltos = 0,
    this.institucionId = 'INST-SAN-MARTIN',
    List<String>? institucionesIds,
    this.permisosEspecificos = const [],
  }) : institucionesIds = institucionesIds ?? const ['INST-SAN-MARTIN'];

  final String uid;
  final String? email;
  final String nombre;
  final RolUsuario rol;
  final bool esAnonimo;
  final String? fotoUrl;
  final int puntosAcumulados;
  final int ejerciciosResueltos;

  /// ID de la institución educativa activa o primaria a la que pertenece el usuario
  final String institucionId;

  /// Lista de IDs de todas las instituciones educativas a las que pertenece el usuario
  final List<String> institucionesIds;

  /// Devuelve la lista unificada sin duplicados de todas las instituciones del usuario
  List<String> get todasLasInstituciones {
    final conjunto = <String>{institucionId, ...institucionesIds};
    return conjunto.toList();
  }

  /// Verifica si el usuario pertenece a una institución específica
  bool perteneceAInstitucion(String id) {
    return institucionId == id || institucionesIds.contains(id);
  }

  /// Permisos explícitos asignados adicionalmente a los de su rol base
  final List<String> permisosEspecificos;

  bool get esProfesor => rol == RolUsuario.profesor;
  bool get esAlumno => rol == RolUsuario.alumno;
  bool get esDireccion => rol == RolUsuario.direccion;

  /// Verifica si el usuario cuenta con una capacidad determinada
  bool tienePermiso(String permiso) => PermisoInstitucional.tienePermiso(this, permiso);

  UsuarioApp copyWith({
    String? uid,
    String? email,
    String? nombre,
    RolUsuario? rol,
    bool? esAnonimo,
    String? fotoUrl,
    int? puntosAcumulados,
    int? ejerciciosResueltos,
    String? institucionId,
    List<String>? institucionesIds,
    List<String>? permisosEspecificos,
  }) {
    final nuevaInstId = institucionId ?? this.institucionId;
    final nuevasInsts = institucionesIds ?? this.institucionesIds;
    // Asegurar que la institución activa esté en la lista de instituciones
    final listaAsegurada = <String>{nuevaInstId, ...nuevasInsts}.toList();

    return UsuarioApp(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      rol: rol ?? this.rol,
      esAnonimo: esAnonimo ?? this.esAnonimo,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      puntosAcumulados: puntosAcumulados ?? this.puntosAcumulados,
      ejerciciosResueltos: ejerciciosResueltos ?? this.ejerciciosResueltos,
      institucionId: nuevaInstId,
      institucionesIds: listaAsegurada,
      permisosEspecificos: permisosEspecificos ?? this.permisosEspecificos,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'nombre': nombre,
      'rol': rol.name,
      'esAnonimo': esAnonimo,
      'fotoUrl': fotoUrl,
      'puntosAcumulados': puntosAcumulados,
      'ejerciciosResueltos': ejerciciosResueltos,
      'institucionId': institucionId,
      'institucionesIds': todasLasInstituciones,
      'permisosEspecificos': permisosEspecificos,
    };
  }

  factory UsuarioApp.fromMap(Map<String, dynamic> map, String uid) {
    final rolStr = map['rol'] as String? ?? 'alumno';
    RolUsuario rolResuelto;
    if (rolStr == 'direccion') {
      rolResuelto = RolUsuario.direccion;
    } else if (rolStr == 'profesor') {
      rolResuelto = RolUsuario.profesor;
    } else {
      rolResuelto = RolUsuario.alumno;
    }

    final instId = map['institucionId'] as String? ?? 'INST-SAN-MARTIN';
    final institucionesRaw = (map['institucionesIds'] as List?)?.cast<String>();
    final listaInsts = institucionesRaw != null && institucionesRaw.isNotEmpty
        ? <String>{instId, ...institucionesRaw}.toList()
        : [instId];

    final permisosRaw = (map['permisosEspecificos'] as List?)?.cast<String>() ?? [];

    return UsuarioApp(
      uid: uid,
      email: map['email'] as String?,
      nombre: map['nombre'] as String? ??
          (map['esAnonimo'] == true ? 'Estudiante Invitado' : 'Usuario'),
      rol: rolResuelto,
      esAnonimo: map['esAnonimo'] as bool? ?? false,
      fotoUrl: map['fotoUrl'] as String?,
      puntosAcumulados: (map['puntosAcumulados'] as num?)?.toInt() ?? 0,
      ejerciciosResueltos: (map['ejerciciosResueltos'] as num?)?.toInt() ?? 0,
      institucionId: instId,
      institucionesIds: listaInsts,
      permisosEspecificos: permisosRaw,
    );
  }
}
