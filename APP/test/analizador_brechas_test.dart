import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/dominio/analisis/analizador_brechas_evaluacion.dart';
import 'package:proyecto/dominio/modelos/analisis_brechas.dart';
import 'package:proyecto/dominio/modelos/evaluacion.dart';

void main() {
  group('AnalizadorBrechasEvaluacion', () {
    const analizador = AnalizadorBrechasEvaluacion();
    const claseId = 'CLASE-001';

    final eval1 = Evaluacion(
      id: 'EVAL-1',
      nombre: 'Prueba Álgebra 1',
      tipo: TipoEvaluacion.examen,
      fecha: DateTime(2026, 8, 10),
      claseId: claseId,
      temas: const ['Álgebra'],
      notaMaxima: 7.0,
      fechaCreacion: DateTime(2026, 8, 1),
    );

    final eval2 = Evaluacion(
      id: 'EVAL-2',
      nombre: 'Prueba Álgebra 2',
      tipo: TipoEvaluacion.quiz,
      fecha: DateTime(2026, 8, 25),
      claseId: claseId,
      temas: const ['Álgebra'],
      notaMaxima: 7.0,
      fechaCreacion: DateTime(2026, 8, 20),
    );

    final eval3 = Evaluacion(
      id: 'EVAL-3',
      nombre: 'Prueba Geometría',
      tipo: TipoEvaluacion.examen,
      fecha: DateTime(2026, 9, 5),
      claseId: claseId,
      temas: const ['Geometría'],
      notaMaxima: 7.0,
      fechaCreacion: DateTime(2026, 9, 1),
    );

    test('Detección de brecha oculta bajo un promedio general aprobatorio', () {
      // Caso Sofía: Promedio general alto (~5.8/7.0), domina Álgebra (6.8 y 7.0) pero reprueba Geometría (3.2)
      final notasSofia = [
        NotaEvaluacion(
          id: 'N-1',
          evaluacionId: eval1.id,
          claseId: claseId,
          alumnoUid: 'sofia-1',
          alumnoNombre: 'Sofía Valenzuela',
          nota: 5.0,
          notaMaxima: 7.0,
          fechaRegistro: DateTime(2026, 8, 11),
        ),
        NotaEvaluacion(
          id: 'N-2',
          evaluacionId: eval2.id,
          claseId: claseId,
          alumnoUid: 'sofia-1',
          alumnoNombre: 'Sofía Valenzuela',
          nota: 7.0,
          notaMaxima: 7.0,
          fechaRegistro: DateTime(2026, 8, 26),
        ),
        NotaEvaluacion(
          id: 'N-3',
          evaluacionId: eval3.id,
          claseId: claseId,
          alumnoUid: 'sofia-1',
          alumnoNombre: 'Sofía Valenzuela',
          nota: 3.2,
          notaMaxima: 7.0,
          fechaRegistro: DateTime(2026, 9, 6),
        ),
      ];

      final analisis = analizador.analizarEstudiante(
        alumnoUid: 'sofia-1',
        alumnoNombre: 'Sofía Valenzuela',
        evaluaciones: [eval1, eval2, eval3],
        notas: notasSofia,
      );

      // Promedio general (5.0 + 7.0 + 3.2)/3 = 5.1
      expect(analisis.promedioGeneral, equals(5.1));
      expect(analisis.porcentajeGeneral, greaterThan(70.0));

      // Desglose por tema:
      expect(analisis.rendimientosPorTema.containsKey('Álgebra'), isTrue);
      expect(analisis.rendimientosPorTema.containsKey('Geometría'), isTrue);

      final rendAlgebra = analisis.rendimientosPorTema['Álgebra']!;
      final rendGeometria = analisis.rendimientosPorTema['Geometría']!;

      expect(rendAlgebra.porcentajeLogro, greaterThan(80.0));
      expect(rendAlgebra.nivelDominio, equals(NivelDominio.consolidado));

      // Geometría 3.2/7.0 = 45.7% -> Brecha crítica
      expect(rendGeometria.porcentajeLogro, lessThan(50.0));
      expect(rendGeometria.nivelDominio, equals(NivelDominio.critico));

      // El tema de peor desempeño detectado es inequívocamente Geometría
      expect(analisis.temaPeorDesempeno?.tema, equals('Geometría'));
      expect(analisis.temaMejorDesempeno?.tema, equals('Álgebra'));

      // Evolución temporal en Álgebra (subió de 6.8 a 7.0 -> Tendencia de mejora)
      final evoAlgebra = analisis.evolucionesPorTema['Álgebra']!;
      expect(evoAlgebra.puntos.length, equals(2));
      expect(evoAlgebra.tendencia, equals(TendenciaEvolucion.mejora));
    });

    test('Análisis de clase: peor desempeño colectivo, alumnos en riesgo y recomendación', () {
      final notasClase = [
        // Sofía
        NotaEvaluacion(
          id: 'N-1',
          evaluacionId: eval1.id,
          claseId: claseId,
          alumnoUid: 'sofia-1',
          alumnoNombre: 'Sofía Valenzuela',
          nota: 6.8,
          notaMaxima: 7.0,
          fechaRegistro: DateTime(2026, 8, 11),
        ),
        NotaEvaluacion(
          id: 'N-2',
          evaluacionId: eval3.id,
          claseId: claseId,
          alumnoUid: 'sofia-1',
          alumnoNombre: 'Sofía Valenzuela',
          nota: 3.2,
          notaMaxima: 7.0,
          fechaRegistro: DateTime(2026, 9, 6),
        ),
        // Mateo
        NotaEvaluacion(
          id: 'N-3',
          evaluacionId: eval1.id,
          claseId: claseId,
          alumnoUid: 'mateo-2',
          alumnoNombre: 'Mateo Rivas',
          nota: 6.0,
          notaMaxima: 7.0,
          fechaRegistro: DateTime(2026, 8, 11),
        ),
        NotaEvaluacion(
          id: 'N-4',
          evaluacionId: eval3.id,
          claseId: claseId,
          alumnoUid: 'mateo-2',
          alumnoNombre: 'Mateo Rivas',
          nota: 3.5,
          notaMaxima: 7.0,
          fechaRegistro: DateTime(2026, 9, 6),
        ),
      ];

      final analisisClase = analizador.analizarClase(
        claseId: claseId,
        evaluaciones: [eval1, eval3],
        notas: notasClase,
        nombresAlumnos: {
          'sofia-1': 'Sofía Valenzuela',
          'mateo-2': 'Mateo Rivas',
        },
      );

      expect(analisisClase.totalEvaluaciones, equals(2));
      expect(analisisClase.totalAlumnos, equals(2));

      // Peor tema colectivo debe ser Geometría
      expect(analisisClase.temaPeorDesempenoColectivo?.tema, equals('Geometría'));
      expect(analisisClase.temaPeorDesempenoColectivo?.porcentajeLogro, lessThan(50.0));

      // Ambos estudiantes deben figurar en la lista de riesgo de Geometría
      final enRiesgoGeometria = analisisClase.alumnosEnRiesgoPorTema['Geometría']!;
      expect(enRiesgoGeometria.length, equals(2));
      expect(enRiesgoGeometria.map((a) => a.alumnoUid), containsAll(['sofia-1', 'mateo-2']));

      // En Álgebra no hay estudiantes en riesgo
      final enRiesgoAlgebra = analisisClase.alumnosEnRiesgoPorTema['Álgebra'] ?? [];
      expect(enRiesgoAlgebra, isEmpty);

      // Recomendación docente debe indicar prioridad en Geometría
      expect(analisisClase.recomendacionDocente, contains('Geometría'));
    });
  });
}
