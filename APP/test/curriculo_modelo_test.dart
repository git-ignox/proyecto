import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/dominio/modelos/curriculo.dart';
import 'package:proyecto/dominio/modelos/evaluacion.dart';

void main() {
  group('Modelos Curriculares (Plan, Unidad, Objetivo)', () {
    test('ObjetivoAprendizaje serializa y deserializa correctamente', () {
      const obj = ObjetivoAprendizaje(
        id: 'oa-01',
        unidadId: 'uni-01',
        codigo: 'OA-01',
        nombre: 'Operaciones con enteros',
        descripcion: 'Cálculo aritmético de enteros',
        orden: 1,
      );

      final map = obj.toMap();
      final objReconstruido = ObjetivoAprendizaje.fromMap(map);

      expect(objReconstruido.id, equals('oa-01'));
      expect(objReconstruido.codigo, equals('OA-01'));
      expect(objReconstruido.nombre, equals('Operaciones con enteros'));
      expect(objReconstruido.etiquetaCompleta, equals('OA-01: Operaciones con enteros'));
    });

    test('PlanCurricular calcula conteos agregados de unidades y objetivos', () {
      final plan = PlanCurricular(
        id: 'plan-test',
        nombre: 'Matemática Test',
        area: 'Matemática',
        nivelGrado: '8vo',
        fechaCreacion: DateTime(2026, 1, 1),
        unidades: [
          const UnidadCurricular(
            id: 'u1',
            planCurricularId: 'plan-test',
            numero: 1,
            nombre: 'Unidad 1',
            periodoSugerido: 'T1',
            objetivos: [
              ObjetivoAprendizaje(id: 'oa1', unidadId: 'u1', codigo: 'OA-01', nombre: 'Obj 1'),
              ObjetivoAprendizaje(id: 'oa2', unidadId: 'u1', codigo: 'OA-02', nombre: 'Obj 2'),
            ],
          ),
          const UnidadCurricular(
            id: 'u2',
            planCurricularId: 'plan-test',
            numero: 2,
            nombre: 'Unidad 2',
            periodoSugerido: 'T2',
            objetivos: [
              ObjetivoAprendizaje(id: 'oa3', unidadId: 'u2', codigo: 'OA-03', nombre: 'Obj 3'),
            ],
          ),
        ],
      );

      expect(plan.unidades.length, equals(2));
      expect(plan.totalObjetivos, equals(3));
      expect(plan.todosLosObjetivos.length, equals(3));
      expect(plan.buscarObjetivoPorId('oa2')?.nombre, equals('Obj 2'));
      expect(plan.buscarObjetivoPorId('inexistente'), isNull);
    });

    test('Puente de compatibilidad en Evaluacion: vinculación de objetivoIds y temas', () {
      const obj = ObjetivoAprendizaje(
        id: 'oa-mat-05',
        unidadId: 'uni-02',
        codigo: 'OA-05',
        nombre: 'Ecuaciones lineales',
      );

      // Simular auto-relleno al seleccionar el objetivo
      final eval = Evaluacion(
        id: 'eval-101',
        nombre: 'Control Álgebra',
        tipo: TipoEvaluacion.quiz,
        fecha: DateTime(2026, 9, 1),
        claseId: 'clase-1',
        temas: [obj.etiquetaCompleta],
        objetivoIds: [obj.id],
        fechaCreacion: DateTime(2026, 9, 1),
      );

      expect(eval.objetivoIds, contains('oa-mat-05'));
      expect(eval.temas, contains('OA-05: Ecuaciones lineales'));

      // Verificar serialización
      final map = eval.toMap();
      final evalReconst = Evaluacion.fromMap(map);

      expect(evalReconst.objetivoIds, contains('oa-mat-05'));
      expect(evalReconst.temas, contains('OA-05: Ecuaciones lineales'));
    });
  });
}
