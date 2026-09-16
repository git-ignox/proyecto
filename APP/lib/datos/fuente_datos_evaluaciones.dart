import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../dominio/modelos/evaluacion.dart';
import 'repositorio_evaluaciones.dart';

/// Implementación en memoria con reactividad por Stream y sincronización
/// opcional con Cloud Firestore en colecciones `evaluaciones` y `notas_evaluacion`.
class FuenteDatosEvaluaciones implements RepositorioEvaluaciones {
  FuenteDatosEvaluaciones({FirebaseFirestore? firestore})
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

  final Map<String, Evaluacion> _evaluaciones = {};
  final Map<String, NotaEvaluacion> _notas = {};

  final StreamController<List<Evaluacion>> _evaluacionesStream =
      StreamController<List<Evaluacion>>.broadcast();
  final StreamController<List<NotaEvaluacion>> _notasStream =
      StreamController<List<NotaEvaluacion>>.broadcast();

  void _inicializarDatosPredeterminados() {
    const claseIdDemo = 'CLASE-DEMO-001';

    // 1. Evaluaciones de demostración
    final eval1 = Evaluacion(
      id: 'EVAL-DEMO-01',
      nombre: 'Diagnóstico Unidad 1: Aritmética y Álgebra',
      tipo: TipoEvaluacion.examen,
      fecha: DateTime(2026, 8, 10),
      claseId: claseIdDemo,
      temas: const ['Álgebra', 'Aritmética'],
      objetivoIds: const ['oa-mat-01', 'oa-mat-04'],
      notaMaxima: 7.0,
      notaAprobatoria: 4.0,
      descripcion: 'Evaluación diagnóstica con foco en valor posicional y ecuaciones de primer grado.',
      fechaCreacion: DateTime(2026, 8, 1),
    );

    final eval2 = Evaluacion(
      id: 'EVAL-DEMO-02',
      nombre: 'Quiz Rápido: Despeje y Álgebra',
      tipo: TipoEvaluacion.quiz,
      fecha: DateTime(2026, 8, 25),
      claseId: claseIdDemo,
      temas: const ['Álgebra'],
      objetivoIds: const ['oa-mat-05'],
      notaMaxima: 7.0,
      notaAprobatoria: 4.0,
      descripcion: 'Control formativo breve para verificar avance en despeje de incógnitas.',
      fechaCreacion: DateTime(2026, 8, 20),
    );

    final eval3 = Evaluacion(
      id: 'EVAL-DEMO-03',
      nombre: 'Prueba Unidad 2: Geometría y Áreas',
      tipo: TipoEvaluacion.examen,
      fecha: DateTime(2026, 9, 5),
      claseId: claseIdDemo,
      temas: const ['Geometría'],
      objetivoIds: const ['oa-mat-07'],
      notaMaxima: 7.0,
      notaAprobatoria: 4.0,
      descripcion: 'Cálculo de perímetros y áreas de polígonos regulares y triángulos.',
      fechaCreacion: DateTime(2026, 9, 1),
    );

    _evaluaciones[eval1.id] = eval1;
    _evaluaciones[eval2.id] = eval2;
    _evaluaciones[eval3.id] = eval3;

    // 2. Calificaciones de muestra (ilustran brechas temáticas y evolución)
    // Caso de Sofía: Promedio alto (5.8), domina Álgebra (6.8 -> 7.0), pero reprueba Geometría (3.2)!
    final notasDemo = <NotaEvaluacion>[
      // Sofía Valenzuela
      NotaEvaluacion(
        id: 'NOTA-DEMO-1',
        evaluacionId: eval1.id,
        claseId: claseIdDemo,
        alumnoUid: 'alumno-demo-1',
        alumnoNombre: 'Sofía Valenzuela',
        nota: 6.8,
        notaMaxima: 7.0,
        fechaRegistro: DateTime(2026, 8, 11),
        notasPorTema: const {'Álgebra': 7.0, 'Aritmética': 6.6},
        observaciones: 'Excelente procedimiento algebraico.',
      ),
      NotaEvaluacion(
        id: 'NOTA-DEMO-2',
        evaluacionId: eval2.id,
        claseId: claseIdDemo,
        alumnoUid: 'alumno-demo-1',
        alumnoNombre: 'Sofía Valenzuela',
        nota: 7.0,
        notaMaxima: 7.0,
        fechaRegistro: DateTime(2026, 8, 26),
        notasPorTema: const {'Álgebra': 7.0},
        observaciones: 'Consolidación perfecta en álgebra.',
      ),
      NotaEvaluacion(
        id: 'NOTA-DEMO-3',
        evaluacionId: eval3.id,
        claseId: claseIdDemo,
        alumnoUid: 'alumno-demo-1',
        alumnoNombre: 'Sofía Valenzuela',
        nota: 3.2,
        notaMaxima: 7.0,
        fechaRegistro: DateTime(2026, 9, 6),
        notasPorTema: const {'Geometría': 3.2},
        observaciones: 'Confusión entre fórmula de área y perímetro.',
      ),

      // Mateo Rivas
      NotaEvaluacion(
        id: 'NOTA-DEMO-4',
        evaluacionId: eval1.id,
        claseId: claseIdDemo,
        alumnoUid: 'alumno-demo-2',
        alumnoNombre: 'Mateo Rivas',
        nota: 5.6,
        notaMaxima: 7.0,
        fechaRegistro: DateTime(2026, 8, 11),
        notasPorTema: const {'Álgebra': 5.8, 'Aritmética': 5.4},
      ),
      NotaEvaluacion(
        id: 'NOTA-DEMO-5',
        evaluacionId: eval2.id,
        claseId: claseIdDemo,
        alumnoUid: 'alumno-demo-2',
        alumnoNombre: 'Mateo Rivas',
        nota: 6.4,
        notaMaxima: 7.0,
        fechaRegistro: DateTime(2026, 8, 26),
        notasPorTema: const {'Álgebra': 6.4},
      ),
      NotaEvaluacion(
        id: 'NOTA-DEMO-6',
        evaluacionId: eval3.id,
        claseId: claseIdDemo,
        alumnoUid: 'alumno-demo-2',
        alumnoNombre: 'Mateo Rivas',
        nota: 3.6,
        notaMaxima: 7.0,
        fechaRegistro: DateTime(2026, 9, 6),
        notasPorTema: const {'Geometría': 3.6},
      ),

      // Camila Soto
      NotaEvaluacion(
        id: 'NOTA-DEMO-7',
        evaluacionId: eval1.id,
        claseId: claseIdDemo,
        alumnoUid: 'alumno-demo-3',
        alumnoNombre: 'Camila Soto',
        nota: 6.1,
        notaMaxima: 7.0,
        fechaRegistro: DateTime(2026, 8, 11),
        notasPorTema: const {'Álgebra': 6.5, 'Aritmética': 5.7},
      ),
      NotaEvaluacion(
        id: 'NOTA-DEMO-8',
        evaluacionId: eval2.id,
        claseId: claseIdDemo,
        alumnoUid: 'alumno-demo-3',
        alumnoNombre: 'Camila Soto',
        nota: 6.7,
        notaMaxima: 7.0,
        fechaRegistro: DateTime(2026, 8, 26),
        notasPorTema: const {'Álgebra': 6.7},
      ),
      NotaEvaluacion(
        id: 'NOTA-DEMO-9',
        evaluacionId: eval3.id,
        claseId: claseIdDemo,
        alumnoUid: 'alumno-demo-3',
        alumnoNombre: 'Camila Soto',
        nota: 4.1,
        notaMaxima: 7.0,
        fechaRegistro: DateTime(2026, 9, 6),
        notasPorTema: const {'Geometría': 4.1},
      ),

      // Joaquín Herrera (en EVAL-03 aún no tiene nota cargada -> simula estado "pendiente")
      NotaEvaluacion(
        id: 'NOTA-DEMO-10',
        evaluacionId: eval1.id,
        claseId: claseIdDemo,
        alumnoUid: 'alumno-demo-4',
        alumnoNombre: 'Joaquín Herrera',
        nota: 4.5,
        notaMaxima: 7.0,
        fechaRegistro: DateTime(2026, 8, 11),
        notasPorTema: const {'Álgebra': 4.0, 'Aritmética': 5.0},
      ),
      NotaEvaluacion(
        id: 'NOTA-DEMO-11',
        evaluacionId: eval2.id,
        claseId: claseIdDemo,
        alumnoUid: 'alumno-demo-4',
        alumnoNombre: 'Joaquín Herrera',
        nota: 5.5,
        notaMaxima: 7.0,
        fechaRegistro: DateTime(2026, 8, 26),
        notasPorTema: const {'Álgebra': 5.5},
      ),
    ];

    for (final n in notasDemo) {
      _notas[n.id] = n;
    }

    _emitirCambios();
    _sincronizarDesdeFirestore();
  }

  void _emitirCambios() {
    if (!_evaluacionesStream.isClosed) {
      _evaluacionesStream.add(_evaluaciones.values.toList());
    }
    if (!_notasStream.isClosed) {
      _notasStream.add(_notas.values.toList());
    }
  }

  Future<void> _sincronizarDesdeFirestore() async {
    final fs = _firestore;
    if (fs == null) return;
    try {
      final snapEvals = await fs
          .collection('evaluaciones')
          .get()
          .timeout(const Duration(seconds: 3));

      for (final doc in snapEvals.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final eval = Evaluacion.fromMap(data);
        _evaluaciones[eval.id] = eval;
      }

      final snapNotas = await fs
          .collection('notas_evaluacion')
          .get()
          .timeout(const Duration(seconds: 3));

      for (final doc in snapNotas.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final nota = NotaEvaluacion.fromMap(data);
        _notas[nota.id] = nota;
      }

      _emitirCambios();
    } catch (e) {
      debugPrint('Aviso Firestore evaluaciones (modo local activo): $e');
    }
  }

  @override
  Future<List<Evaluacion>> obtenerEvaluacionesPorClase(String claseId) async {
    return _evaluaciones.values
        .where((e) => e.claseId == claseId)
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  @override
  Future<Evaluacion?> obtenerEvaluacionPorId(String id) async {
    return _evaluaciones[id];
  }

  @override
  Future<Evaluacion> crearEvaluacion(Evaluacion evaluacion) async {
    final idGenerado = evaluacion.id.isNotEmpty
        ? evaluacion.id
        : 'EVAL-${DateTime.now().millisecondsSinceEpoch}';
    final nueva = evaluacion.copyWith(id: idGenerado);
    _evaluaciones[nueva.id] = nueva;
    _emitirCambios();

    final fs = _firestore;
    if (fs != null) {
      try {
        await fs
            .collection('evaluaciones')
            .doc(nueva.id)
            .set(nueva.toMap())
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('Aviso al persistir evaluacion en Firestore: $e');
      }
    }

    return nueva;
  }

  @override
  Future<bool> eliminarEvaluacion(String evaluacionId) async {
    final eliminada = _evaluaciones.remove(evaluacionId) != null;
    // Eliminar también notas de esa evaluación
    _notas.removeWhere((_, n) => n.evaluacionId == evaluacionId);
    _emitirCambios();

    final fs = _firestore;
    if (fs != null) {
      try {
        await fs.collection('evaluaciones').doc(evaluacionId).delete();
      } catch (e) {
        debugPrint('Aviso al eliminar evaluacion en Firestore: $e');
      }
    }

    return eliminada;
  }

  @override
  Future<List<NotaEvaluacion>> obtenerNotasPorEvaluacion(String evaluacionId) async {
    return _notas.values
        .where((n) => n.evaluacionId == evaluacionId)
        .toList()
      ..sort((a, b) => a.alumnoNombre.compareTo(b.alumnoNombre));
  }

  @override
  Future<List<NotaEvaluacion>> obtenerNotasPorClase(String claseId) async {
    return _notas.values
        .where((n) => n.claseId == claseId)
        .toList();
  }

  @override
  Future<List<NotaEvaluacion>> obtenerNotasPorAlumno(String alumnoUid) async {
    return _notas.values
        .where((n) => n.alumnoUid == alumnoUid)
        .toList()
      ..sort((a, b) => b.fechaRegistro.compareTo(a.fechaRegistro));
  }

  @override
  Future<NotaEvaluacion> guardarNota(NotaEvaluacion nota) async {
    // Si ya existe nota de este alumno para esta evaluación, actualizarla
    final existente = _notas.values.cast<NotaEvaluacion?>().firstWhere(
          (n) =>
              n?.evaluacionId == nota.evaluacionId &&
              n?.alumnoUid == nota.alumnoUid,
          orElse: () => null,
        );

    final id = existente?.id ??
        (nota.id.isNotEmpty
            ? nota.id
            : 'NOTA-${DateTime.now().millisecondsSinceEpoch}-${nota.alumnoUid.hashCode}');

    final guardada = nota.copyWith(id: id);
    _notas[guardada.id] = guardada;
    _emitirCambios();

    final fs = _firestore;
    if (fs != null) {
      try {
        await fs
            .collection('notas_evaluacion')
            .doc(guardada.id)
            .set(guardada.toMap())
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('Aviso al persistir nota en Firestore: $e');
      }
    }

    return guardada;
  }

  @override
  Future<int> guardarNotasEnBloque(List<NotaEvaluacion> listaNotas) async {
    int guardadas = 0;
    for (final nota in listaNotas) {
      await guardarNota(nota);
      guardadas++;
    }
    return guardadas;
  }

  @override
  Future<bool> actualizarNota(NotaEvaluacion nota) async {
    if (!_notas.containsKey(nota.id)) {
      // Si no tiene ID o no existe, guardar normal
      await guardarNota(nota);
      return true;
    }
    _notas[nota.id] = nota;
    _emitirCambios();

    final fs = _firestore;
    if (fs != null) {
      try {
        await fs
            .collection('notas_evaluacion')
            .doc(nota.id)
            .set(nota.toMap())
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('Aviso al actualizar nota en Firestore: $e');
      }
    }

    return true;
  }

  @override
  Future<bool> eliminarNota(String notaId) async {
    final removida = _notas.remove(notaId) != null;
    _emitirCambios();

    final fs = _firestore;
    if (fs != null) {
      try {
        await fs.collection('notas_evaluacion').doc(notaId).delete();
      } catch (e) {
        debugPrint('Aviso al eliminar nota en Firestore: $e');
      }
    }

    return removida;
  }

  @override
  Stream<List<Evaluacion>> streamEvaluacionesPorClase(String claseId) async* {
    yield _evaluaciones.values.where((e) => e.claseId == claseId).toList();
    yield* _evaluacionesStream.stream
        .map((lista) => lista.where((e) => e.claseId == claseId).toList());
  }

  @override
  Stream<List<NotaEvaluacion>> streamNotasPorClase(String claseId) async* {
    yield _notas.values.where((n) => n.claseId == claseId).toList();
    yield* _notasStream.stream
        .map((lista) => lista.where((n) => n.claseId == claseId).toList());
  }
}
