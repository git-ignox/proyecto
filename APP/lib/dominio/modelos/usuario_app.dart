/// Roles de usuario dentro de la aplicación.
enum RolUsuario {
  alumno,
  profesor;

  String get etiqueta {
    switch (this) {
      case RolUsuario.alumno:
        return 'Alumno 🎒';
      case RolUsuario.profesor:
        return 'Profesor 👨‍🏫';
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
  });

  final String uid;
  final String? email;
  final String nombre;
  final RolUsuario rol;
  final bool esAnonimo;
  final String? fotoUrl;
  final int puntosAcumulados;
  final int ejerciciosResueltos;

  bool get esProfesor => rol == RolUsuario.profesor;
  bool get esAlumno => rol == RolUsuario.alumno;

  UsuarioApp copyWith({
    String? uid,
    String? email,
    String? nombre,
    RolUsuario? rol,
    bool? esAnonimo,
    String? fotoUrl,
    int? puntosAcumulados,
    int? ejerciciosResueltos,
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
    };
  }

  factory UsuarioApp.fromMap(Map<String, dynamic> map, String uid) {
    final rolStr = map['rol'] as String? ?? 'alumno';
    return UsuarioApp(
      uid: uid,
      email: map['email'] as String?,
      nombre: map['nombre'] as String? ?? (map['esAnonimo'] == true ? 'Estudiante Invitado' : 'Usuario'),
      rol: rolStr == 'profesor' ? RolUsuario.profesor : RolUsuario.alumno,
      esAnonimo: map['esAnonimo'] as bool? ?? false,
      fotoUrl: map['fotoUrl'] as String?,
      puntosAcumulados: (map['puntosAcumulados'] as num?)?.toInt() ?? 0,
      ejerciciosResueltos: (map['ejerciciosResueltos'] as num?)?.toInt() ?? 0,
    );
  }
}

