import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../dominio/modelos/clase_escolar.dart';
import 'repositorio_clases.dart';

/// Implementación del [RepositorioClases] con almacenamiento en memoria y
/// sincronización en segundo plano con Firestore.
///
/// La colección de Firestore usada es `clases_escolares`.
class FuenteDatosClases implements RepositorioClases {
  FuenteDatosClases({FirebaseFirestore? firestore})
      : _customFirestore = firestore {
    _inicializarDatosPredeterminados();
  }

  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  // Almacenamiento en memoria
  final Map<String, ClaseEscolar> _clases = {};
  final StreamController<List<ClaseEscolar>> _streamController =
      StreamController<List<ClaseEscolar>>.broadcast();

  void _inicializarDatosPredeterminados() {
    // Clase de muestra con código MAT-101
    final claseMuestra = ClaseEscolar(
      id: 'CLASE-DEMO-001',
      codigoAcceso: 'MAT-101',
      nombre: 'Matemáticas 5to Grado A',
      gradoGrupo: '5° Primaria',
      descripcion: 'Curso de matemáticas para quinto grado, grupo A. Incluye aritmética, fracciones y álgebra básica.',
      profesorUid: 'profesor-demo',
      profesorNombre: 'Docente Demo',
      alumnosUids: const [
        'alumno-demo-1',
        'alumno-demo-2',
        'alumno-demo-3',
        'alumno-demo-4',
      ],
      nombresAlumnos: const {
        'alumno-demo-1': 'Sofía Valenzuela',
        'alumno-demo-2': 'Mateo Rivas',
        'alumno-demo-3': 'Camila Soto',
        'alumno-demo-4': 'Joaquín Herrera',
      },
      fechaCreacion: DateTime(2026, 8, 1),
    );
    _clases[claseMuestra.id] = claseMuestra;
    _emitirCambio();
    _sincronizarDesdeFirestore();
  }

  void _emitirCambio() {
    if (!_streamController.isClosed) {
      _streamController.add(_clases.values.toList());
    }
  }

  Future<void> _sincronizarDesdeFirestore() async {
    final fs = _firestore;
    if (fs == null) return;
    try {
      final snapshot = await fs
          .collection('clases_escolares')
          .get()
          .timeout(const Duration(seconds: 3));

      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final clase = ClaseEscolar.fromMap(data);
        _clases[clase.id] = clase;
      }
      _emitirCambio();
    } catch (e) {
      debugPrint('Aviso Firestore clases (modo local activo): $e');
    }
  }

  Future<void> _persistirEnFirestore(ClaseEscolar clase) async {
    final fs = _firestore;
    if (fs == null) return;
    try {
      await fs
          .collection('clases_escolares')
          .doc(clase.id)
          .set(clase.toMap())
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Aviso Firestore al guardar clase: $e');
    }
  }

  @override
  Future<ClaseEscolar> crearClase({
    required String nombre,
    required String gradoGrupo,
    required String descripcion,
    required String profesorUid,
    required String profesorNombre,
    String? prefijoCodigo,
  }) async {
    // Generar código único que no colisione con existentes
    String codigo;
    int intentos = 0;
    do {
      codigo = ClaseEscolar.generarCodigoUnico(prefijoCodigo);
      intentos++;
    } while (_clases.values.any((c) => c.coincideCodigo(codigo)) && intentos < 20);

    final clase = ClaseEscolar(
      id: 'CLASE-${DateTime.now().millisecondsSinceEpoch}',
      codigoAcceso: codigo,
      nombre: nombre,
      gradoGrupo: gradoGrupo,
      descripcion: descripcion,
      profesorUid: profesorUid,
      profesorNombre: profesorNombre,
      fechaCreacion: DateTime.now(),
    );

    _clases[clase.id] = clase;
    _emitirCambio();
    _persistirEnFirestore(clase);
    return clase;
  }

  @override
  Future<List<ClaseEscolar>> obtenerClasesPorProfesor(String profesorUid) async {
    return _clases.values
        .where((c) => c.profesorUid == profesorUid)
        .toList()
      ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
  }

  @override
  Future<List<ClaseEscolar>> obtenerClasesPorAlumno(String alumnoUid) async {
    return _clases.values
        .where((c) => c.alumnoEstaInscrito(alumnoUid))
        .toList()
      ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
  }

  @override
  Future<ClaseEscolar?> obtenerClasePorCodigo(String codigo) async {
    try {
      return _clases.values.firstWhere(
        (c) => c.coincideCodigo(codigo),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ClaseEscolar?> obtenerClasePorId(String id) async {
    return _clases[id];
  }

  @override
  Future<ResultadoUnionClase> unirseAClase({
    required String codigo,
    required String alumnoUid,
    required String alumnoNombre,
  }) async {
    if (codigo.trim().isEmpty) {
      return const ResultadoUnionClase(
        exitoso: false,
        mensaje: 'Por favor ingresa un código de acceso válido.',
      );
    }

    final clase = await obtenerClasePorCodigo(codigo);

    if (clase == null) {
      return const ResultadoUnionClase(
        exitoso: false,
        mensaje: 'El código ingresado no corresponde a ninguna clase activa. Verifica que el código sea correcto.',
      );
    }

    if (!clase.estaActiva) {
      return ResultadoUnionClase(
        exitoso: false,
        mensaje: 'La clase "${clase.nombre}" ya no está activa. Contacta a tu profesor.',
      );
    }

    if (clase.alumnoEstaInscrito(alumnoUid)) {
      return ResultadoUnionClase(
        exitoso: false,
        mensaje: 'Ya estás inscrito en la clase "${clase.nombre}" con el profesor ${clase.profesorNombre}.',
        clase: clase,
      );
    }

    // Inscribir al alumno
    final nuevosUids = [...clase.alumnosUids, alumnoUid];
    final nuevosNombres = Map<String, String>.from(clase.nombresAlumnos)..[alumnoUid] = alumnoNombre;
    final claseActualizada = clase.copyWith(
      alumnosUids: nuevosUids,
      nombresAlumnos: nuevosNombres,
    );

    _clases[claseActualizada.id] = claseActualizada;
    _emitirCambio();
    _persistirEnFirestore(claseActualizada);

    return ResultadoUnionClase(
      exitoso: true,
      mensaje: '¡Te has unido exitosamente a "${clase.nombre}"! Tu profesor es ${clase.profesorNombre}.',
      clase: claseActualizada,
    );
  }

  @override
  Future<void> salirDeClase({
    required String claseId,
    required String alumnoUid,
  }) async {
    final clase = _clases[claseId];
    if (clase == null) return;

    final nuevosUids = clase.alumnosUids.where((uid) => uid != alumnoUid).toList();
    final nuevosNombres = Map<String, String>.from(clase.nombresAlumnos)..remove(alumnoUid);
    final claseActualizada = clase.copyWith(
      alumnosUids: nuevosUids,
      nombresAlumnos: nuevosNombres,
    );

    _clases[claseActualizada.id] = claseActualizada;
    _emitirCambio();
    _persistirEnFirestore(claseActualizada);
  }

  @override
  Future<ClaseEscolar?> inscribirAlumnoDirecto({
    required String claseId,
    required String alumnoNombre,
    String? alumnoUid,
  }) async {
    final clase = _clases[claseId];
    if (clase == null) return null;

    final uid = alumnoUid ??
        'manual-${DateTime.now().millisecondsSinceEpoch}-${alumnoNombre.toLowerCase().replaceAll(' ', '_')}';

    if (clase.alumnoEstaInscrito(uid)) return clase;

    final nuevosUids = [...clase.alumnosUids, uid];
    final nuevosNombres = Map<String, String>.from(clase.nombresAlumnos)..[uid] = alumnoNombre;
    final actualizada = clase.copyWith(
      alumnosUids: nuevosUids,
      nombresAlumnos: nuevosNombres,
    );

    _clases[actualizada.id] = actualizada;
    _emitirCambio();
    _persistirEnFirestore(actualizada);
    return actualizada;
  }

  @override
  Future<ClaseEscolar?> actualizarNombreAlumno({
    required String claseId,
    required String alumnoUid,
    required String nuevoNombre,
  }) async {
    final clase = _clases[claseId];
    if (clase == null) return null;

    if (!clase.nombresAlumnos.containsKey(alumnoUid)) return clase;

    final nuevosNombres = Map<String, String>.from(clase.nombresAlumnos)..[alumnoUid] = nuevoNombre;
    final actualizada = clase.copyWith(nombresAlumnos: nuevosNombres);

    _clases[actualizada.id] = actualizada;
    _emitirCambio();
    _persistirEnFirestore(actualizada);
    return actualizada;
  }

  @override
  Future<void> eliminarClase(String claseId) async {
    _clases.remove(claseId);
    _emitirCambio();
    final fs = _firestore;
    if (fs == null) return;
    try {
      await fs
          .collection('clases_escolares')
          .doc(claseId)
          .delete()
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Aviso Firestore al eliminar clase: $e');
    }
  }

  @override
  Stream<List<ClaseEscolar>> clasesProfesorStream(String profesorUid) {
    return _streamController.stream.map(
      (clases) => clases.where((c) => c.profesorUid == profesorUid).toList()
        ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion)),
    );
  }

  @override
  Stream<List<ClaseEscolar>> clasesAlumnoStream(String alumnoUid) {
    return _streamController.stream.map(
      (clases) => clases.where((c) => c.alumnoEstaInscrito(alumnoUid)).toList()
        ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion)),
    );
  }
}
