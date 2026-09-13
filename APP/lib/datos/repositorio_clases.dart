import '../dominio/modelos/clase_escolar.dart';

/// Contrato de la fuente de datos para el sistema de Classroom.
abstract interface class RepositorioClases {
  /// Crea una nueva clase y la persiste.
  Future<ClaseEscolar> crearClase({
    required String nombre,
    required String gradoGrupo,
    required String descripcion,
    required String profesorUid,
    required String profesorNombre,
    String? prefijoCodigo,
  });

  /// Devuelve todas las clases donde el profesor es dueño.
  Future<List<ClaseEscolar>> obtenerClasesPorProfesor(String profesorUid);

  /// Devuelve todas las clases donde el alumno está matriculado.
  Future<List<ClaseEscolar>> obtenerClasesPorAlumno(String alumnoUid);

  /// Busca una clase por su código de acceso (insensible a mayúsculas).
  Future<ClaseEscolar?> obtenerClasePorCodigo(String codigo);

  /// Busca una clase por su ID único.
  Future<ClaseEscolar?> obtenerClasePorId(String id);

  /// Intenta unir al alumno a la clase correspondiente al [codigo].
  /// Devuelve un [ResultadoUnionClase] con el resultado y mensaje pedagógico.
  Future<ResultadoUnionClase> unirseAClase({
    required String codigo,
    required String alumnoUid,
    required String alumnoNombre,
  });

  /// Elimina al alumno de la clase indicada.
  Future<void> salirDeClase({
    required String claseId,
    required String alumnoUid,
  });

  /// Elimina la clase completa (solo el profesor que la creó puede hacerlo).
  Future<void> eliminarClase(String claseId);

  /// Stream reactivo de las clases del profesor.
  Stream<List<ClaseEscolar>> clasesProfesorStream(String profesorUid);

  /// Stream reactivo de las clases del alumno.
  Stream<List<ClaseEscolar>> clasesAlumnoStream(String alumnoUid);
}
