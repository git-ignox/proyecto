import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/dominio/analisis/analizador_cobertura_curricular.dart';
import 'package:proyecto/dominio/modelos/cobertura_curricular.dart';
import 'package:proyecto/dominio/modelos/curriculo.dart';
import 'package:proyecto/dominio/modelos/evaluacion.dart';

void main() {
  group('AnalizadorCoberturaCurricular', () {
    const analizador = AnalizadorCoberturaCurricular();

    final plan = PlanCurricular(
      id: 'plan-test',
      nombre: 'Plan Matemática',
      area: 'Matemática',
      nivelGrado: '8vo Básico',
      unidades: const [
        UnidadCurricular(
          id: 'u1',
          planCurricularId: 'plan-test',
          numero: 1,
          nombre: 'Unidad 1',
          periodoSugerido: 'T1',
          objetivos: [
            ObjetivoAprendizaje(id: 'oa-01', unidadId: 'u1', codigo: 'OA-01', nombre: 'Enteros'),
            ObjetivoAprendizaje(id: 'oa-02', unidadId: 'u1', codigo: 'OA-02', nombre: 'Potencias'),
            ObjetivoAprendizaje(id: 'oa-03', unidadId: 'u1', codigo: 'OA-03', nombre: 'Raíces'),
          ],
        ),
      ],
    );

    test('Distingue matemáticamente los 3 estados: Consolidado, Brecha de Aprendizaje y Brecha de Enseñanza', () {
      final evals = [
        // OA-01: Evaluado con notas altas (85%) -> Dominado
        Evaluacion(
          id: 'ev-1',
          nombre: 'Prueba Enteros',
          tipo: TipoEvaluacion.examen,
          fecha: DateTime(2026, 8, 1),
          claseId: 'clase-test',
          temas: const ['OA-01: Enteros'],
          objetivoIds: const ['oa-01'],
          notaMaxima: 7.0,
          notaAprobatoria: 4.0,
          fechaCreacion: DateTime(2026, 8, 1),
        ),
        // OA-02: Evaluado con nota reprobatoria (3.0 / 42.8%) -> Brecha de Aprendizaje (<60%)
        Evaluacion(
          id: 'ev-2',
          nombre: 'Prueba Potencias',
          tipo: TipoEvaluacion.examen,
          fecha: DateTime(2026, 8, 15),
          claseId: 'clase-test',
          temas: const ['OA-02: Potencias'],
          objetivoIds: const ['oa-02'],
          notaMaxima: 7.0,
          notaAprobatoria: 4.0,
          fechaCreacion: DateTime(2026, 8, 15),
        ),
        // OA-03: Sin ninguna evaluación asignada -> Brecha de Enseñanza (0 evaluaciones)
      ];

      final notas = [
        NotaEvaluacion(
          id: 'n1',
          evaluacionId: 'ev-1',
          claseId: 'clase-test',
          alumnoUid: 'a1',
          alumnoNombre: 'Alumno 1',
          nota: 6.0, // 85.7%
          notaMaxima: 7.0,
          fechaRegistro: DateTime(2026, 8, 2),
        ),
        NotaEvaluacion(
          id: 'n2',
          evaluacionId: 'ev-2',
          claseId: 'clase-test',
          alumnoUid: 'a1',
          alumnoNombre: 'Alumno 1',
          nota: 3.0, // 42.8% (<60%)
          notaMaxima: 7.0,
          fechaRegistro: DateTime(2026, 8, 16),
        ),
      ];

      final mapa = analizador.analizarCobertura(
        plan: plan,
        evaluaciones: evals,
        notas: notas,
        claseId: 'clase-test',
      );

      // Verificaciones generales
      expect(mapa.totalObjetivosCurriculo, equals(3));
      expect(mapa.totalObjetivosEvaluados, equals(2));
      expect(mapa.porcentajeCoberturaGlobal, closeTo(66.7, 0.1));

      // Verificación de los 3 estados
      expect(mapa.brechasEnsenanza.length, equals(1));
      expect(mapa.brechasEnsenanza.first.objetivo.id, equals('oa-03'));
      expect(mapa.brechasEnsenanza.first.estado, equals(EstadoObjetivoCurricular.noEvaluado));

      expect(mapa.brechasAprendizaje.length, equals(1));
      expect(mapa.brechasAprendizaje.first.objetivo.id, equals('oa-02'));
      expect(mapa.brechasAprendizaje.first.estado, equals(EstadoObjetivoCurricular.enRiesgo));

      final obj1 = mapa.unidades.first.objetivosAnalizados.firstWhere((o) => o.objetivo.id == 'oa-01');
      expect(obj1.estado, equals(EstadoObjetivoCurricular.dominado));
      expect(obj1.rendimientoPromedio, greaterThanOrEqualTo(60.0));
    });

    test('Macheo dual: reconoce objetivo por ID explícito o por código literal OA-xx en temas', () {
      final evals = [
        // Macheo por fallback de código literal en temas sin objetivoIds explícito
        Evaluacion(
          id: 'ev-legacy',
          nombre: 'Evaluación Anterior',
          tipo: TipoEvaluacion.quiz,
          fecha: DateTime(2026, 8, 1),
          claseId: 'clase-test',
          temas: const ['OA-01'], // Contiene el código literal 'OA-01'
          objetivoIds: const [], // Sin objetivoIds
          notaMaxima: 7.0,
          notaAprobatoria: 4.0,
          fechaCreacion: DateTime(2026, 8, 1),
        ),
      ];

      final notas = [
        NotaEvaluacion(
          id: 'n1',
          evaluacionId: 'ev-legacy',
          claseId: 'clase-test',
          alumnoUid: 'a1',
          alumnoNombre: 'Alumno 1',
          nota: 5.5,
          notaMaxima: 7.0,
          fechaRegistro: DateTime(2026, 8, 2),
        ),
      ];

      final mapa = analizador.analizarCobertura(
        plan: plan,
        evaluaciones: evals,
        notas: notas,
        claseId: 'clase-test',
      );

      final obj1 = mapa.unidades.first.objetivosAnalizados.firstWhere((o) => o.objetivo.id == 'oa-01');
      expect(obj1.cantidadEvaluaciones, equals(1));
      expect(obj1.esBrechaEnsenanza, isFalse);

      // Los otros dos deben permanecer como Brecha de Enseñanza
      final obj2 = mapa.unidades.first.objetivosAnalizados.firstWhere((o) => o.objetivo.id == 'oa-02');
      final obj3 = mapa.unidades.first.objetivosAnalizados.firstWhere((o) => o.objetivo.id == 'oa-03');
      expect(obj2.esBrechaEnsenanza, isTrue);
      expect(obj3.esBrechaEnsenanza, isTrue);
    });
  });
}
