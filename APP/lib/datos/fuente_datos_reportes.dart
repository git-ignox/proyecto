import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../dominio/modelos/analisis_brechas.dart';
import '../dominio/modelos/reporte_pedagogico.dart';
import 'repositorio_reportes.dart';

/// Implementación en memoria con reactividad por Stream y sincronización
/// opcional con Cloud Firestore en la colección `reportes_pedagogicos`.
class FuenteDatosReportes implements RepositorioReportes {
  FuenteDatosReportes({FirebaseFirestore? firestore})
      : _customFirestore = firestore {
    _inicializarDatosPredeterminados();
    _sincronizarDesdeFirestore();
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

  final Map<String, ReporteEstudiante> _reportes = {};

  final StreamController<List<ReporteEstudiante>> _reportesStream =
      StreamController<List<ReporteEstudiante>>.broadcast();

  void _inicializarDatosPredeterminados() {
    const claseIdDemo = 'CLASE-DEMO-001';
    const periodoDemo = '1° Trimestre';
    final fecha = DateTime(2026, 9, 10);

    // 1. Sofía Valenzuela: 1 tema en riesgo (Geometría)
    final rep1 = ReporteEstudiante(
      id: 'REP-DEMO-01',
      claseId: claseIdDemo,
      periodo: periodoDemo,
      alumnoUid: 'alumno-demo-1',
      alumnoNombre: 'Sofía Valenzuela',
      fechaGeneracion: fecha,
      promedioGeneral: 5.6,
      porcentajeGeneral: 80.5,
      totalTemasEnRiesgo: 1,
      comentarioDocente:
          'Sofía muestra un excelente dominio en Aritmética y Álgebra, resolviendo ecuaciones con rapidez. '
          'Sin embargo, presenta dificultades específicas en Geometría para descomponer figuras y calcular áreas compuestas. '
          'Se recomienda reforzar ejercicios visuales y fórmulas geométricas básicas.',
      temasPriorizados: const [
        SnapshotTemaReporte(
          tema: 'Geometría',
          porcentajeDominio: 45.7,
          promedioNota: 3.2,
          cantidadEvaluaciones: 1,
          nivelDominio: NivelDominio.critico,
          tendenciaInterPeriodo: TendenciaInterPeriodo.primeraMedicion,
        ),
        SnapshotTemaReporte(
          tema: 'Álgebra',
          porcentajeDominio: 82.9,
          promedioNota: 5.8,
          cantidadEvaluaciones: 2,
          nivelDominio: NivelDominio.consolidado,
          tendenciaInterPeriodo: TendenciaInterPeriodo.primeraMedicion,
        ),
        SnapshotTemaReporte(
          tema: 'Aritmética',
          porcentajeDominio: 92.9,
          promedioNota: 6.5,
          cantidadEvaluaciones: 1,
          nivelDominio: NivelDominio.consolidado,
          tendenciaInterPeriodo: TendenciaInterPeriodo.primeraMedicion,
        ),
      ],
    );

    // 2. Mateo Rivas: 2 temas en riesgo (Álgebra y Geometría) -> Riesgo multitemático
    final rep2 = ReporteEstudiante(
      id: 'REP-DEMO-02',
      claseId: claseIdDemo,
      periodo: periodoDemo,
      alumnoUid: 'alumno-demo-2',
      alumnoNombre: 'Mateo Rivas',
      fechaGeneracion: fecha,
      promedioGeneral: 4.4,
      porcentajeGeneral: 63.3,
      totalTemasEnRiesgo: 2,
      comentarioDocente:
          'Mateo requiere acompañamiento prioritario en Álgebra (despeje de incógnitas) y en Geometría (perímetros y áreas). '
          'Su base aritmética es adecuada (78.6%), lo que demuestra que tiene potencial de mejora si se fortalecen los pasos de resolución algebraica.',
      temasPriorizados: const [
        SnapshotTemaReporte(
          tema: 'Álgebra',
          porcentajeDominio: 54.3,
          promedioNota: 3.8,
          cantidadEvaluaciones: 2,
          nivelDominio: NivelDominio.critico,
          tendenciaInterPeriodo: TendenciaInterPeriodo.primeraMedicion,
        ),
        SnapshotTemaReporte(
          tema: 'Geometría',
          porcentajeDominio: 57.1,
          promedioNota: 4.0,
          cantidadEvaluaciones: 1,
          nivelDominio: NivelDominio.critico,
          tendenciaInterPeriodo: TendenciaInterPeriodo.primeraMedicion,
        ),
        SnapshotTemaReporte(
          tema: 'Aritmética',
          porcentajeDominio: 78.6,
          promedioNota: 5.5,
          cantidadEvaluaciones: 1,
          nivelDominio: NivelDominio.consolidado,
          tendenciaInterPeriodo: TendenciaInterPeriodo.primeraMedicion,
        ),
      ],
    );

    // 3. Camila Soto: 0 temas en riesgo
    final rep3 = ReporteEstudiante(
      id: 'REP-DEMO-03',
      claseId: claseIdDemo,
      periodo: periodoDemo,
      alumnoUid: 'alumno-demo-3',
      alumnoNombre: 'Camila Soto',
      fechaGeneracion: fecha,
      promedioGeneral: 5.3,
      porcentajeGeneral: 76.2,
      totalTemasEnRiesgo: 0,
      comentarioDocente:
          'Camila mantiene un rendimiento estable y constante en todas las unidades. '
          'Su mayor fortaleza es Aritmética, y continúa progresando positivamente en conceptos algebraicos y geométricos.',
      temasPriorizados: const [
        SnapshotTemaReporte(
          tema: 'Geometría',
          porcentajeDominio: 68.6,
          promedioNota: 4.8,
          cantidadEvaluaciones: 1,
          nivelDominio: NivelDominio.enDesarrollo,
          tendenciaInterPeriodo: TendenciaInterPeriodo.primeraMedicion,
        ),
        SnapshotTemaReporte(
          tema: 'Álgebra',
          porcentajeDominio: 74.3,
          promedioNota: 5.2,
          cantidadEvaluaciones: 2,
          nivelDominio: NivelDominio.enDesarrollo,
          tendenciaInterPeriodo: TendenciaInterPeriodo.primeraMedicion,
        ),
        SnapshotTemaReporte(
          tema: 'Aritmética',
          porcentajeDominio: 85.7,
          promedioNota: 6.0,
          cantidadEvaluaciones: 1,
          nivelDominio: NivelDominio.consolidado,
          tendenciaInterPeriodo: TendenciaInterPeriodo.primeraMedicion,
        ),
      ],
    );

    // 4. Joaquín Herrera: 3 temas en riesgo -> Riesgo multitemático crítico
    final rep4 = ReporteEstudiante(
      id: 'REP-DEMO-04',
      claseId: claseIdDemo,
      periodo: periodoDemo,
      alumnoUid: 'alumno-demo-4',
      alumnoNombre: 'Joaquín Herrera',
      fechaGeneracion: fecha,
      promedioGeneral: 3.5,
      porcentajeGeneral: 50.0,
      totalTemasEnRiesgo: 3,
      comentarioDocente:
          'Joaquín experimenta rezago generalizado en los tres temas evaluados. '
          'Es prioritario programar tutoría individual y coordinar reunión con el apoderado para estructurar un plan de apoyo escolar.',
      temasPriorizados: const [
        SnapshotTemaReporte(
          tema: 'Álgebra',
          porcentajeDominio: 42.9,
          promedioNota: 3.0,
          cantidadEvaluaciones: 2,
          nivelDominio: NivelDominio.critico,
          tendenciaInterPeriodo: TendenciaInterPeriodo.primeraMedicion,
        ),
        SnapshotTemaReporte(
          tema: 'Geometría',
          porcentajeDominio: 50.0,
          promedioNota: 3.5,
          cantidadEvaluaciones: 1,
          nivelDominio: NivelDominio.critico,
          tendenciaInterPeriodo: TendenciaInterPeriodo.primeraMedicion,
        ),
        SnapshotTemaReporte(
          tema: 'Aritmética',
          porcentajeDominio: 57.1,
          promedioNota: 4.0,
          cantidadEvaluaciones: 1,
          nivelDominio: NivelDominio.critico,
          tendenciaInterPeriodo: TendenciaInterPeriodo.primeraMedicion,
        ),
      ],
    );

    _reportes[rep1.id] = rep1;
    _reportes[rep2.id] = rep2;
    _reportes[rep3.id] = rep3;
    _reportes[rep4.id] = rep4;
  }

  void _notificarCambios() {
    if (!_reportesStream.isClosed) {
      _reportesStream.add(_reportes.values.toList());
    }
  }

  Future<void> _sincronizarDesdeFirestore() async {
    final fs = _firestore;
    if (fs == null) return;
    try {
      final snap = await fs
          .collection('reportes_pedagogicos')
          .get()
          .timeout(const Duration(seconds: 3));

      for (final doc in snap.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final reporte = ReporteEstudiante.fromMap(data);
        _reportes[reporte.id] = reporte;
      }
      _notificarCambios();
    } catch (e) {
      debugPrint('Aviso Firestore reportes (modo local activo): $e');
    }
  }

  @override
  Future<List<ReporteEstudiante>> obtenerReportesPorClase(
    String claseId, {
    String? periodo,
  }) async {
    final list = _reportes.values.where((r) => r.claseId == claseId);
    if (periodo != null && periodo.isNotEmpty) {
      return list.where((r) => r.periodo == periodo).toList();
    }
    return list.toList();
  }

  @override
  Future<List<ReporteEstudiante>> obtenerReportesPorAlumno(String alumnoUid) async {
    final list = _reportes.values.where((r) => r.alumnoUid == alumnoUid).toList();
    list.sort((a, b) => b.fechaGeneracion.compareTo(a.fechaGeneracion));
    return list;
  }

  @override
  Future<ReporteEstudiante?> obtenerReportePorId(String id) async {
    return _reportes[id];
  }

  @override
  Future<void> guardarReporte(ReporteEstudiante reporte) async {
    _reportes[reporte.id] = reporte;
    _notificarCambios();

    final fs = _firestore;
    if (fs != null) {
      try {
        await fs
            .collection('reportes_pedagogicos')
            .doc(reporte.id)
            .set(reporte.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Aviso: No se pudo sincronizar reporte en Firestore ($e)');
      }
    }
  }

  @override
  Future<void> guardarReportesEnBloque(List<ReporteEstudiante> reportes) async {
    for (final r in reportes) {
      _reportes[r.id] = r;
    }
    _notificarCambios();

    final fs = _firestore;
    if (fs != null) {
      try {
        final batch = fs.batch();
        for (final r in reportes) {
          final docRef = fs.collection('reportes_pedagogicos').doc(r.id);
          batch.set(docRef, r.toMap(), SetOptions(merge: true));
        }
        await batch.commit();
      } catch (e) {
        debugPrint('Aviso: No se pudo sincronizar lote de reportes en Firestore ($e)');
      }
    }
  }

  @override
  Future<void> eliminarReporte(String id) async {
    _reportes.remove(id);
    _notificarCambios();

    final fs = _firestore;
    if (fs != null) {
      try {
        await fs.collection('reportes_pedagogicos').doc(id).delete();
      } catch (e) {
        debugPrint('Aviso: No se pudo eliminar reporte en Firestore ($e)');
      }
    }
  }

  @override
  Stream<List<ReporteEstudiante>> vigilarReportesPorClase(
    String claseId, {
    String? periodo,
  }) async* {
    var filtrados = _reportes.values.where((r) => r.claseId == claseId);
    if (periodo != null && periodo.isNotEmpty) {
      filtrados = filtrados.where((r) => r.periodo == periodo);
    }
    yield filtrados.toList();
    yield* _reportesStream.stream.map((todos) {
      var f = todos.where((r) => r.claseId == claseId);
      if (periodo != null && periodo.isNotEmpty) {
        f = f.where((r) => r.periodo == periodo);
      }
      return f.toList();
    });
  }

  @override
  Stream<List<ReporteEstudiante>> vigilarReportesPorAlumno(String alumnoUid) async* {
    final filtrados = _reportes.values.where((r) => r.alumnoUid == alumnoUid).toList();
    filtrados.sort((a, b) => b.fechaGeneracion.compareTo(a.fechaGeneracion));
    yield filtrados;
    yield* _reportesStream.stream.map((todos) {
      final f = todos.where((r) => r.alumnoUid == alumnoUid).toList();
      f.sort((a, b) => b.fechaGeneracion.compareTo(a.fechaGeneracion));
      return f;
    });
  }

  void dispose() {
    _reportesStream.close();
  }
}
