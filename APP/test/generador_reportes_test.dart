import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/dominio/analisis/generador_reportes.dart';
import 'package:proyecto/dominio/modelos/analisis_brechas.dart';
import 'package:proyecto/dominio/modelos/evaluacion.dart';
import 'package:proyecto/dominio/modelos/reporte_pedagogico.dart';

void main() {
  group('GeneradorReportes', () {
    const generador = GeneradorReportes();

    final evals = [
      Evaluacion(
        id: 'EVAL-1',
        nombre: 'Prueba Álgebra',
        tipo: TipoEvaluacion.examen,
        fecha: DateTime(2026, 8, 1),
        claseId: 'CLASE-1',
        temas: const ['Álgebra'],
        notaMaxima: 7.0,
        notaAprobatoria: 4.0,
        fechaCreacion: DateTime(2026, 8, 1),
      ),
      Evaluacion(
        id: 'EVAL-2',
        nombre: 'Prueba Geometría',
        tipo: TipoEvaluacion.examen,
        fecha: DateTime(2026, 8, 15),
        claseId: 'CLASE-1',
        temas: const ['Geometría'],
        notaMaxima: 7.0,
        notaAprobatoria: 4.0,
        fechaCreacion: DateTime(2026, 8, 1),
      ),
      Evaluacion(
        id: 'EVAL-3',
        nombre: 'Control Aritmética',
        tipo: TipoEvaluacion.quiz,
        fecha: DateTime(2026, 8, 25),
        claseId: 'CLASE-1',
        temas: const ['Aritmética'],
        notaMaxima: 7.0,
        notaAprobatoria: 4.0,
        fechaCreacion: DateTime(2026, 8, 1),
      ),
    ];

    test('Ordenamiento pedagógico: brechas críticas (<60%) van primero', () {
      // Estudiante con:
      // - Álgebra: 6.5 / 7.0 (92.9% -> consolidado)
      // - Geometría: 3.0 / 7.0 (42.9% -> crítico)
      // - Aritmética: 5.0 / 7.0 (71.4% -> enDesarrollo)
      final notas = [
        NotaEvaluacion(
          id: 'N-1',
          evaluacionId: 'EVAL-1',
          claseId: 'CLASE-1',
          alumnoUid: 'alumno-1',
          alumnoNombre: 'Sofía',
          nota: 6.5,
          fechaRegistro: DateTime(2026, 8, 1),
        ),
        NotaEvaluacion(
          id: 'N-2',
          evaluacionId: 'EVAL-2',
          claseId: 'CLASE-1',
          alumnoUid: 'alumno-1',
          alumnoNombre: 'Sofía',
          nota: 3.0,
          fechaRegistro: DateTime(2026, 8, 15),
        ),
        NotaEvaluacion(
          id: 'N-3',
          evaluacionId: 'EVAL-3',
          claseId: 'CLASE-1',
          alumnoUid: 'alumno-1',
          alumnoNombre: 'Sofía',
          nota: 5.0,
          fechaRegistro: DateTime(2026, 8, 25),
        ),
      ];

      final reporte = generador.generarReporteEstudiante(
        id: 'REP-SOFIA-T1',
        claseId: 'CLASE-1',
        periodo: '1° Trimestre',
        alumnoUid: 'alumno-1',
        alumnoNombre: 'Sofía',
        evaluaciones: evals,
        notas: notas,
      );

      // Verificaciones principales
      expect(reporte.totalTemasEnRiesgo, equals(1));
      expect(reporte.temasPriorizados.length, equals(3));

      // ¡EL PRIMER TEMA DEBE SER LA BRECHA CRÍTICA (<60%)!
      expect(reporte.temasPriorizados.first.tema, equals('Geometría'));
      expect(reporte.temasPriorizados.first.porcentajeDominio, closeTo(42.9, 0.1));
      expect(reporte.temasPriorizados.first.nivelDominio, equals(NivelDominio.critico));

      // El segundo tema debe ser el que está en desarrollo
      expect(reporte.temasPriorizados[1].tema, equals('Aritmética'));
      expect(reporte.temasPriorizados[1].porcentajeDominio, closeTo(71.4, 0.1));

      // El último tema debe ser el consolidado
      expect(reporte.temasPriorizados.last.tema, equals('Álgebra'));
      expect(reporte.temasPriorizados.last.porcentajeDominio, closeTo(92.9, 0.1));
    });

    test('Cálculo de tendencias inter-períodos comparando con reporte previo', () {
      // Reporte previo (1° Trimestre):
      // - Álgebra: 40.0%
      // - Geometría: 80.0%
      final reporteAnterior = ReporteEstudiante(
        id: 'REP-T1',
        claseId: 'CLASE-1',
        periodo: '1° Trimestre',
        alumnoUid: 'alumno-1',
        alumnoNombre: 'Sofía',
        fechaGeneracion: DateTime(2026, 5, 1),
        promedioGeneral: 4.2,
        porcentajeGeneral: 60.0,
        totalTemasEnRiesgo: 1,
        temasPriorizados: const [
          SnapshotTemaReporte(
            tema: 'Álgebra',
            porcentajeDominio: 40.0,
            promedioNota: 2.8,
            cantidadEvaluaciones: 1,
            nivelDominio: NivelDominio.critico,
          ),
          SnapshotTemaReporte(
            tema: 'Geometría',
            porcentajeDominio: 80.0,
            promedioNota: 5.6,
            cantidadEvaluaciones: 1,
            nivelDominio: NivelDominio.consolidado,
          ),
        ],
      );

      // En el 2° Trimestre:
      // - Álgebra subió a 70.0% (+30% -> Mejora)
      // - Geometría bajó a 55.0% (-25% -> Regresión)
      final notasT2 = [
        NotaEvaluacion(
          id: 'NT2-1',
          evaluacionId: 'EVAL-1',
          claseId: 'CLASE-1',
          alumnoUid: 'alumno-1',
          alumnoNombre: 'Sofía',
          nota: 4.9,
          fechaRegistro: DateTime(2026, 9, 1),
        ),
        NotaEvaluacion(
          id: 'NT2-2',
          evaluacionId: 'EVAL-2',
          claseId: 'CLASE-1',
          alumnoUid: 'alumno-1',
          alumnoNombre: 'Sofía',
          nota: 3.85,
          fechaRegistro: DateTime(2026, 9, 1),
        ),
      ];

      final reporteT2 = generador.generarReporteEstudiante(
        id: 'REP-T2',
        claseId: 'CLASE-1',
        periodo: '2° Trimestre',
        alumnoUid: 'alumno-1',
        alumnoNombre: 'Sofía',
        fechaGeneracion: DateTime(2026, 9, 1),
        evaluaciones: evals,
        notas: notasT2,
        reportesHistoricos: [reporteAnterior],
      );

      // Geometría es ahora brecha crítica (<60%), debe figurar primero
      final snapGeometria = reporteT2.temasPriorizados.firstWhere((t) => t.tema == 'Geometría');
      expect(snapGeometria.porcentajePeriodoAnterior, equals(80.0));
      expect(snapGeometria.tendenciaInterPeriodo, equals(TendenciaInterPeriodo.regresion));

      // Álgebra mejoró
      final snapAlgebra = reporteT2.temasPriorizados.firstWhere((t) => t.tema == 'Álgebra');
      expect(snapAlgebra.porcentajePeriodoAnterior, equals(40.0));
      expect(snapAlgebra.tendenciaInterPeriodo, equals(TendenciaInterPeriodo.mejora));
    });

    test('Generación de reportes en lote para una clase y detección de riesgo multitemático', () {
      final alumnos = [
        {'uid': 'a1', 'nombre': 'Estudiante En Riesgo Multi'},
        {'uid': 'a2', 'nombre': 'Estudiante Consolidado'},
      ];

      final notas = [
        // a1 falla en Álgebra y Geometría (<60%)
        NotaEvaluacion(id: 'na-1', evaluacionId: 'EVAL-1', claseId: 'CLASE-1', alumnoUid: 'a1', alumnoNombre: '', nota: 2.8, fechaRegistro: DateTime(2026, 8, 1)),
        NotaEvaluacion(id: 'na-2', evaluacionId: 'EVAL-2', claseId: 'CLASE-1', alumnoUid: 'a1', alumnoNombre: '', nota: 3.5, fechaRegistro: DateTime(2026, 8, 15)),
        // a2 aprueba todo
        NotaEvaluacion(id: 'na-3', evaluacionId: 'EVAL-1', claseId: 'CLASE-1', alumnoUid: 'a2', alumnoNombre: '', nota: 6.3, fechaRegistro: DateTime(2026, 8, 1)),
        NotaEvaluacion(id: 'na-4', evaluacionId: 'EVAL-2', claseId: 'CLASE-1', alumnoUid: 'a2', alumnoNombre: '', nota: 5.6, fechaRegistro: DateTime(2026, 8, 15)),
      ];

      final reportes = generador.generarReportesClase(
        claseId: 'CLASE-1',
        periodo: '1° Trimestre',
        alumnos: alumnos,
        evaluaciones: evals,
        notas: notas,
      );

      expect(reportes.length, equals(2));

      final repA1 = reportes.firstWhere((r) => r.alumnoUid == 'a1');
      final repA2 = reportes.firstWhere((r) => r.alumnoUid == 'a2');

      expect(repA1.enRiesgoMultitematico, isTrue);
      expect(repA1.totalTemasEnRiesgo, equals(2));

      expect(repA2.enRiesgoMultitematico, isFalse);
      expect(repA2.totalTemasEnRiesgo, equals(0));
    });

    test('Generación de sugerencia de comentario cualitativo', () {
      final reporte = ReporteEstudiante(
        id: 'REP-TEST',
        claseId: 'C1',
        periodo: '1° Trimestre',
        alumnoUid: 'a1',
        alumnoNombre: 'Sofía',
        fechaGeneracion: DateTime.now(),
        promedioGeneral: 5.4,
        porcentajeGeneral: 77.1,
        totalTemasEnRiesgo: 1,
        temasPriorizados: const [
          SnapshotTemaReporte(
            tema: 'Geometría',
            porcentajeDominio: 45.0,
            promedioNota: 3.2,
            cantidadEvaluaciones: 1,
            nivelDominio: NivelDominio.critico,
          ),
          SnapshotTemaReporte(
            tema: 'Álgebra',
            porcentajeDominio: 85.0,
            promedioNota: 6.0,
            cantidadEvaluaciones: 1,
            nivelDominio: NivelDominio.consolidado,
          ),
        ],
      );

      final comentario = generador.generarSugerenciaComentarioDocente(reporte);

      expect(comentario, contains('Geometría'));
      expect(comentario, contains('45'));
      expect(comentario, contains('Álgebra'));
      expect(comentario, contains('85'));
    });

    test('Detección de desactualización (staleness) cuando se edita o registra una nota posteriormente', () {
      final fechaBase = DateTime(2026, 9, 1, 10, 0);

      final reporte = ReporteEstudiante(
        id: 'REP-STALE-TEST',
        claseId: 'CLASE-1',
        periodo: '1° Trimestre',
        alumnoUid: 'alumno-1',
        alumnoNombre: 'Sofía Valenzuela',
        fechaGeneracion: fechaBase,
        promedioGeneral: 6.0,
        porcentajeGeneral: 85.0,
        totalTemasEnRiesgo: 0,
        temasPriorizados: const [],
      );

      // 1. Notas registradas ANTES de la generación del reporte -> NO desactualizado
      final notasPrevias = [
        NotaEvaluacion(
          id: 'N-PREVIA',
          evaluacionId: 'EVAL-1',
          claseId: 'CLASE-1',
          alumnoUid: 'alumno-1',
          alumnoNombre: 'Sofía Valenzuela',
          nota: 6.0,
          fechaRegistro: fechaBase.subtract(const Duration(hours: 1)),
        ),
      ];
      expect(GeneradorReportes.esReporteDesactualizado(reporte, notasPrevias), isFalse);

      // 2. Nota editada/registrada DESPUÉS de la generación del reporte -> SÍ desactualizado
      final notasConEdicionPosterior = [
        NotaEvaluacion(
          id: 'N-POSTERIOR',
          evaluacionId: 'EVAL-1',
          claseId: 'CLASE-1',
          alumnoUid: 'alumno-1',
          alumnoNombre: 'Sofía Valenzuela',
          nota: 3.5, // Docente rectificó la nota a la baja
          fechaRegistro: fechaBase.add(const Duration(minutes: 5)),
        ),
      ];
      expect(GeneradorReportes.esReporteDesactualizado(reporte, notasConEdicionPosterior), isTrue);
    });

    test('Regeneración individual de reporte preserva el comentario personalizado del docente y actualiza fecha', () {
      final fechaRegeneracion = DateTime(2026, 9, 1, 12, 0);

      const comentarioDocente = 'Comentario manual escrito previamente por el profesor.';

      final notasActualizadas = [
        NotaEvaluacion(
          id: 'N-1',
          evaluacionId: 'EVAL-1',
          claseId: 'CLASE-1',
          alumnoUid: 'alumno-1',
          alumnoNombre: 'Sofía',
          nota: 3.0, // Nota rectificada a la baja en Álgebra
          fechaRegistro: DateTime(2026, 9, 1, 11, 0),
        ),
      ];

      final reporteRegenerado = generador.generarReporteEstudiante(
        id: 'REP-ORIGINAL',
        claseId: 'CLASE-1',
        periodo: '1° Trimestre',
        alumnoUid: 'alumno-1',
        alumnoNombre: 'Sofía',
        evaluaciones: evals,
        notas: notasActualizadas,
        fechaGeneracion: fechaRegeneracion,
        comentarioDocentePersonalizado: comentarioDocente,
      );

      expect(reporteRegenerado.id, equals('REP-ORIGINAL'));
      expect(reporteRegenerado.fechaGeneracion, equals(fechaRegeneracion));
      expect(reporteRegenerado.comentarioDocente, equals(comentarioDocente));
      expect(reporteRegenerado.totalTemasEnRiesgo, equals(1));
      expect(reporteRegenerado.temasPriorizados.first.tema, equals('Álgebra'));

      // Ahora el reporte regenerado ya no está desactualizado respecto a la nota rectificada
      expect(GeneradorReportes.esReporteDesactualizado(reporteRegenerado, notasActualizadas), isFalse);
    });
  });
}
