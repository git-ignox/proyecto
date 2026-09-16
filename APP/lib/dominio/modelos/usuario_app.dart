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
    this.permisosEspecificos = const [],
  });

  final String uid;
  final String? email;
  final String nombre;
  final RolUsuario rol;
  final bool esAnonimo;
  final String? fotoUrl;
  final int puntosAcumulados;
  final int ejerciciosResueltos;

  /// ID de la institución educativa a la que pertenece el usuario
  final String institucionId;

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
    List<String>? permisosEspecificos,
  }) {
    return UsuarioApp(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      rol: rol ?? this.rol,
      esAnonimo: esAnonimo ?? this.esAnonimo,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      puntosAcumulados: puntosAcumulados ?? this.puntosAcumulados,
      ejerciciosResueltos: ejerciciosResueltos ?? this.ejerciciosResueltos,
      institucionId: institucionId ?? this.institucionId,
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
      institucionId: map['institucionId'] as String? ?? 'INST-SAN-MARTIN',
      permisosEspecificos: permisosRaw,
    );
  }
}
