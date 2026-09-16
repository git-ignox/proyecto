import '../modelos/evaluacion.dart';
import '../modelos/reporte_pedagogico.dart';
import 'analizador_brechas_evaluacion.dart';

/// Motor generador de reportes pedagógicos.
///
/// Transforma evaluaciones y calificaciones crudas en un snapshot congelado e inmutable,
/// priorizando brechas críticas (<60%) en el tope del informe y calculando tendencias inter-períodos.
class GeneradorReportes {
  const GeneradorReportes({
    this.analizador = const AnalizadorBrechasEvaluacion(),
  });

  final AnalizadorBrechasEvaluacion analizador;

  /// Genera un `ReporteEstudiante` congelado para un alumno en un período escolar específico.
  ReporteEstudiante generarReporteEstudiante({
    required String id,
    required String claseId,
    required String periodo,
    required String alumnoUid,
    required String alumnoNombre,
    required List<Evaluacion> evaluaciones,
    required List<NotaEvaluacion> notas,
    DateTime? fechaGeneracion,
    List<ReporteEstudiante> reportesHistoricos = const [],
    String? comentarioDocentePersonalizado,
  }) {
    final fecha = fechaGeneracion ?? DateTime.now();

    // 1. Reusar el cálculo base del AnalizadorBrechasEvaluacion
    final analisis = analizador.analizarEstudiante(
      alumnoUid: alumnoUid,
      alumnoNombre: alumnoNombre,
      evaluaciones: evaluaciones,
      notas: notas,
    );

    // 2. Buscar reporte anterior del estudiante para comparar tendencias inter-período
    ReporteEstudiante? reporteAnterior;
    final anteriores = reportesHistoricos.where(
      (r) => r.alumnoUid == alumnoUid && r.periodo != periodo && r.fechaGeneracion.isBefore(fecha),
    ).toList();
    if (anteriores.isNotEmpty) {
      anteriores.sort((a, b) => b.fechaGeneracion.compareTo(a.fechaGeneracion));
      reporteAnterior = anteriores.first;
    }

    final mapaAnterior = <String, SnapshotTemaReporte>{};
    if (reporteAnterior != null) {
      for (final t in reporteAnterior.temasPriorizados) {
        mapaAnterior[t.tema] = t;
      }
    }

    // 3. Crear snapshots temáticos y evaluar tendencias
    final List<SnapshotTemaReporte> snapshots = [];

    analisis.rendimientosPorTema.forEach((tema, rend) {
      final snapAnterior = mapaAnterior[tema];
      double? pctAnterior;
      TendenciaInterPeriodo tendencia = TendenciaInterPeriodo.primeraMedicion;

      if (snapAnterior != null) {
        pctAnterior = snapAnterior.porcentajeDominio;
        final variacion = rend.porcentajeLogro - pctAnterior;
        if (variacion >= 5.0) {
          tendencia = TendenciaInterPeriodo.mejora;
        } else if (variacion <= -5.0) {
          tendencia = TendenciaInterPeriodo.regresion;
        } else {
          tendencia = TendenciaInterPeriodo.estable;
        }
      }

      snapshots.add(
        SnapshotTemaReporte(
          tema: tema,
          porcentajeDominio: double.parse(rend.porcentajeLogro.toStringAsFixed(1)),
          promedioNota: double.parse(rend.promedioNota.toStringAsFixed(1)),
          cantidadEvaluaciones: rend.cantidadEvaluaciones,
          nivelDominio: rend.nivelDominio,
          porcentajePeriodoAnterior: pctAnterior != null
              ? double.parse(pctAnterior.toStringAsFixed(1))
              : null,
          tendenciaInterPeriodo: tendencia,
        ),
      );
    });

    // 4. CRITERIO PEDAGÓGICO: Ordenar temas con brechas críticas primero (<60%)
    // y luego en orden ascendente de porcentaje de dominio.
    snapshots.sort((a, b) {
      final aEsBrecha = a.porcentajeDominio < 60.0;
      final bEsBrecha = b.porcentajeDominio < 60.0;

      if (aEsBrecha && !bEsBrecha) return -1;
      if (!aEsBrecha && bEsBrecha) return 1;

      // Si ambos son o no son brecha, ordenar por menor porcentaje primero
      final cmp = a.porcentajeDominio.compareTo(b.porcentajeDominio);
      if (cmp != 0) return cmp;
      return a.tema.compareTo(b.tema);
    });

    // 5. Totalizar temas en riesgo (< 60%)
    final totalTemasEnRiesgo = snapshots.where((t) => t.porcentajeDominio < 60.0).length;

    // 6. Construir reporte preliminar para sugerir comentario si no fue provisto
    final reportePreliminar = ReporteEstudiante(
      id: id,
      claseId: claseId,
      periodo: periodo,
      alumnoUid: alumnoUid,
      alumnoNombre: alumnoNombre,
      fechaGeneracion: fecha,
      promedioGeneral: double.parse(analisis.promedioGeneral.toStringAsFixed(1)),
      porcentajeGeneral: double.parse(analisis.porcentajeGeneral.toStringAsFixed(1)),
      temasPriorizados: snapshots,
      totalTemasEnRiesgo: totalTemasEnRiesgo,
      comentarioDocente: comentarioDocentePersonalizado ?? '',
    );

    final comentarioFinal = (comentarioDocentePersonalizado != null &&
            comentarioDocentePersonalizado.trim().isNotEmpty)
        ? comentarioDocentePersonalizado.trim()
        : generarSugerenciaComentarioDocente(reportePreliminar);

    return reportePreliminar.copyWith(comentarioDocente: comentarioFinal);
  }

  /// Genera reportes en lote para todos los alumnos de una clase en el período dado.
  List<ReporteEstudiante> generarReportesClase({
    required String claseId,
    required String periodo,
    required List<Map<String, String>> alumnos, // [{'uid': '...', 'nombre': '...'}]
    required List<Evaluacion> evaluaciones,
    required List<NotaEvaluacion> notas,
    DateTime? fechaGeneracion,
    List<ReporteEstudiante> reportesHistoricos = const [],
  }) {
    final reportes = <ReporteEstudiante>[];
    final evalsClase = evaluaciones.where((e) => e.claseId == claseId).toList();

    for (final alumno in alumnos) {
      final uid = alumno['uid'] ?? '';
      final nombre = alumno['nombre'] ?? '';
      if (uid.isEmpty) continue;

      final idReporte = 'REP-$claseId-$periodo-$uid'
          .replaceAll(' ', '_')
          .replaceAll('°', '');

      final reporte = generarReporteEstudiante(
        id: idReporte,
        claseId: claseId,
        periodo: periodo,
        alumnoUid: uid,
        alumnoNombre: nombre,
        evaluaciones: evalsClase,
        notas: notas,
        fechaGeneracion: fechaGeneracion,
        reportesHistoricos: reportesHistoricos,
      );

      reportes.add(reporte);
    }

    return reportes;
  }

  /// Genera un borrador pedagógico conciso basado exclusivamente en el snapshot de dominios.
  /// No realiza llamadas externas; utiliza heurísticas directas sobre brechas y fortalezas.
  String generarSugerenciaComentarioDocente(ReporteEstudiante reporte) {
    if (reporte.temasPriorizados.isEmpty) {
      return 'Sin evaluaciones registradas en este período escolar.';
    }

    final brecha = reporte.brechaPrincipal;
    final fortaleza = reporte.fortalezaPrincipal;

    final tieneBrechas = reporte.totalTemasEnRiesgo > 0;
    final buffers = <String>[];

    if (tieneBrechas) {
      if (reporte.totalTemasEnRiesgo >= 2) {
        buffers.add(
          '${reporte.alumnoNombre} presenta necesidades de reforzamiento prioritario en ${reporte.totalTemasEnRiesgo} temas curriculares, '
          'especialmente en ${brecha?.tema ?? 'el área principal'} (${brecha?.porcentajeDominio ?? 0}% de logro).',
        );
      } else {
        buffers.add(
          'Se observa un rendimiento con buen potencial, requiriendo atención pedagógica focalizada en ${brecha?.tema ?? 'su tema crítico'} '
          '(${brecha?.porcentajeDominio ?? 0}% de logro) para nivelar sus aprendizajes.',
        );
      }

      if (fortaleza != null && fortaleza.tema != brecha?.tema && fortaleza.porcentajeDominio >= 70.0) {
        buffers.add(
          'Destaca positivamente en ${fortaleza.tema} con un ${fortaleza.porcentajeDominio}% de dominio, '
          'base sobre la cual se sugiere anclar los nuevos conceptos.',
        );
      }

      buffers.add('Se recomienda trabajo guiado y práctica continua.');
    } else {
      buffers.add(
        '${reporte.alumnoNombre} demuestra un desempeño consolidado y equilibrado en todos los temas del período escolar.',
      );
      if (fortaleza != null) {
        buffers.add(
          'Su mayor fortaleza se evidencia en ${fortaleza.tema} (${fortaleza.porcentajeDominio}% de logro).',
        );
      }
      buffers.add('Se sugiere incentivar nuevos desafíos de profundización.');
    }

    return buffers.join(' ');
  }

  /// Verifica si un reporte pedagógico está desactualizado respecto a las notas registradas
  /// para el alumno (por ejemplo, si alguna nota fue registrada o modificada con fecha posterior
  /// a la fecha de generación del reporte).
  static bool esReporteDesactualizado(
    ReporteEstudiante reporte,
    Iterable<NotaEvaluacion> notasAlumno,
  ) {
    return notasAlumno.any((n) => n.fechaRegistro.isAfter(reporte.fechaGeneracion));
  }
}
