import 'dart:math';

/// Resultado de intentar unirse a una clase con un código de acceso.
class ResultadoUnionClase {
  const ResultadoUnionClase({
    required this.exitoso,
    required this.mensaje,
    this.clase,
  });

  final bool exitoso;
  final String mensaje;
  final ClaseEscolar? clase;
}

/// Modelo que representa una clase o aula escolar virtual.
///
/// El [codigoAcceso] es un código único alfanumérico (ej. MAT-7429) que el
/// profesor comparte con sus alumnos para que se matriculen.
class ClaseEscolar {
  const ClaseEscolar({
    required this.id,
    required this.codigoAcceso,
    required this.nombre,
    required this.gradoGrupo,
    required this.descripcion,
    required this.profesorUid,
    required this.profesorNombre,
    this.planCurricularId,
    this.alumnosUids = const [],
    this.nombresAlumnos = const {},
    required this.fechaCreacion,
    this.estaActiva = true,
  });

  final String id;

  /// Código único de acceso para la clase (ej. MAT-7429).
  /// Es insensible a mayúsculas y se usa para que los alumnos se matriculen.
  final String codigoAcceso;

  final String nombre;
  final String gradoGrupo;
  final String descripcion;
  final String profesorUid;
  final String profesorNombre;

  /// ID del Plan Curricular oficial asignado a esta clase (opcional).
  final String? planCurricularId;

  /// UIDs de los alumnos inscritos en esta clase.
  final List<String> alumnosUids;

  /// Mapa de uid -> nombre de los alumnos matriculados.
  final Map<String, String> nombresAlumnos;

  final DateTime fechaCreacion;
  final bool estaActiva;

  int get totalAlumnos => alumnosUids.length;

  bool alumnoEstaInscrito(String uid) => alumnosUids.contains(uid);

  /// Genera un código único alfanumérico de 3 letras + 4 dígitos.
  /// Por ejemplo: MAT-7429, FIS-3812, QUI-5901.
  static String generarCodigoUnico([String? prefijo]) {
    final random = Random();
    final letras = prefijo ?? _generarPrefijo(random);
    final numero = 1000 + random.nextInt(8999);
    return '$letras-$numero';
  }

  static String _generarPrefijo(Random random) {
    const vocales = 'AEIOU';
    const consonantes = 'BCDFGHJKLMNPQRSTVWXYZ';
    final c1 = consonantes[random.nextInt(consonantes.length)];
    final v1 = vocales[random.nextInt(vocales.length)];
    final c2 = consonantes[random.nextInt(consonantes.length)];
    return '$c1$v1$c2';
  }

  /// Normaliza el código de acceso para comparar (mayúsculas, sin espacios, sin guiones).
  static String normalizarCodigo(String codigo) {
    return codigo.trim().toUpperCase().replaceAll(' ', '').replaceAll('-', '');
  }

  /// Verifica si dos códigos coinciden (insensible a mayúsculas/minúsculas y espacios).
  bool coincideCodigo(String codigoIngresado) {
    final normalIngresado = normalizarCodigo(codigoIngresado);
    final normalPropio = normalizarCodigo(codigoAcceso);
    return normalIngresado == normalPropio;
  }

  ClaseEscolar copyWith({
    String? id,
    String? codigoAcceso,
    String? nombre,
    String? gradoGrupo,
    String? descripcion,
    String? profesorUid,
    String? profesorNombre,
    String? planCurricularId,
    List<String>? alumnosUids,
    Map<String, String>? nombresAlumnos,
    DateTime? fechaCreacion,
    bool? estaActiva,
  }) {
    return ClaseEscolar(
      id: id ?? this.id,
      codigoAcceso: codigoAcceso ?? this.codigoAcceso,
      nombre: nombre ?? this.nombre,
      gradoGrupo: gradoGrupo ?? this.gradoGrupo,
      descripcion: descripcion ?? this.descripcion,
      profesorUid: profesorUid ?? this.profesorUid,
      profesorNombre: profesorNombre ?? this.profesorNombre,
      planCurricularId: planCurricularId ?? this.planCurricularId,
      alumnosUids: alumnosUids ?? this.alumnosUids,
      nombresAlumnos: nombresAlumnos ?? this.nombresAlumnos,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      estaActiva: estaActiva ?? this.estaActiva,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigoAcceso': codigoAcceso,
      'nombre': nombre,
      'gradoGrupo': gradoGrupo,
      'descripcion': descripcion,
      'profesorUid': profesorUid,
      'profesorNombre': profesorNombre,
      'planCurricularId': planCurricularId,
      'alumnosUids': alumnosUids,
      'nombresAlumnos': nombresAlumnos,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'estaActiva': estaActiva,
    };
  }

  factory ClaseEscolar.fromMap(Map<String, dynamic> map) {
    final alumnosUids = (map['alumnosUids'] as List?)?.cast<String>() ?? [];
    final nombresRaw = (map['nombresAlumnos'] as Map?)?.cast<String, String>() ?? {};

    return ClaseEscolar(
      id: map['id'] as String? ?? '',
      codigoAcceso: map['codigoAcceso'] as String? ?? '',
      nombre: map['nombre'] as String? ?? 'Clase sin nombre',
      gradoGrupo: map['gradoGrupo'] as String? ?? '',
      descripcion: map['descripcion'] as String? ?? '',
      profesorUid: map['profesorUid'] as String? ?? '',
      profesorNombre: map['profesorNombre'] as String? ?? 'Profesor',
      planCurricularId: map['planCurricularId'] as String?,
      alumnosUids: alumnosUids,
      nombresAlumnos: nombresRaw,
      fechaCreacion: DateTime.tryParse(map['fechaCreacion'] as String? ?? '') ?? DateTime.now(),
      estaActiva: map['estaActiva'] as bool? ?? true,
    );
  }
}
