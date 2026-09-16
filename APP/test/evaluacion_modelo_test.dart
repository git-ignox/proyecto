import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/dominio/modelos/evaluacion.dart';

void main() {
  group('Evaluacion & NotaEvaluacion Modelos', () {
    test('Creación y serialización de Evaluacion', () {
      final fecha = DateTime(2026, 9, 1);
      final eval = Evaluacion(
        id: 'EVAL-01',
        nombre: 'Prueba de Diagnóstico',
        tipo: TipoEvaluacion.examen,
        fecha: fecha,
        claseId: 'CLASE-01',
        temas: const ['Álgebra', 'Geometría'],
        notaMaxima: 7.0,
        notaAprobatoria: 4.0,
        descripcion: 'Evaluación inicial del semestre',
        fechaCreacion: fecha,
      );

      expect(eval.nombre, equals('Prueba de Diagnóstico'));
      expect(eval.tipo, equals(TipoEvaluacion.examen));
      expect(eval.temas, containsAll(['Álgebra', 'Geometría']));

      final map = eval.toMap();
      expect(map['id'], equals('EVAL-01'));
      expect(map['tipo'], equals('examen'));
      expect(map['temas'], equals(['Álgebra', 'Geometría']));

      final desdeMap = Evaluacion.fromMap(map);
      expect(desdeMap.id, equals('EVAL-01'));
      expect(desdeMap.nombre, equals('Prueba de Diagnóstico'));
      expect(desdeMap.tipo, equals(TipoEvaluacion.examen));
      expect(desdeMap.temas, containsAll(['Álgebra', 'Geometría']));
    });

    test('Cálculo de porcentaje de logro en NotaEvaluacion', () {
      final nota = NotaEvaluacion(
        id: 'NOTA-01',
        evaluacionId: 'EVAL-01',
        claseId: 'CLASE-01',
        alumnoUid: 'alumno-1',
        alumnoNombre: 'Sofía Valenzuela',
        nota: 5.6,
        notaMaxima: 7.0,
        fechaRegistro: DateTime(2026, 9, 2),
        notasPorTema: const {'Álgebra': 6.5, 'Geometría': 3.5},
      );

      // 5.6 / 7.0 * 100 = 80.0%
      expect(nota.porcentajeLogro, closeTo(80.0, 0.01));
      expect(nota.estaAprobado(4.0), isTrue);
      expect(nota.estaAprobado(6.0), isFalse);

      final map = nota.toMap();
      final desdeMap = NotaEvaluacion.fromMap(map);

      expect(desdeMap.alumnoUid, equals('alumno-1'));
      expect(desdeMap.nota, equals(5.6));
      expect(desdeMap.notasPorTema['Álgebra'], equals(6.5));
      expect(desdeMap.notasPorTema['Geometría'], equals(3.5));
    });
  });
}
