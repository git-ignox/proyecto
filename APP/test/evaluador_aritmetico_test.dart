import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/dominio/evaluadores/evaluador_aritmetico.dart';
import 'package:proyecto/dominio/evaluadores/servicio_evaluacion.dart';
import 'package:proyecto/dominio/generadores/generador_aritmetica.dart';
import 'package:proyecto/dominio/modelos/aritmetico.dart';
import 'package:proyecto/dominio/modelos/posicion_curricular.dart';

void main() {
  group('EvaluadorAritmetico - Operaciones y Formatos', () {
    const evaluador = EvaluadorAritmetico();

    test('Evalúa suma vertical con resultado como incógnita', () {
      const ej = Aritmetico(
        id: 'A-SUMA',
        posicion: PosicionCurricular(tema: 1, subtema: 1, leccion: 1),
        nivel: 1,
        enunciado: 'Suma en columna',
        operacion: OperacionAritmetica.suma,
        operando1: 125,
        operando2: 78,
        disposicion: DisposicionAritmetica.vertical,
        incognita: ElementoIncognita.resultado,
      );

      final resCorrecto = evaluador.evaluar(ej, '203');
      expect(resCorrecto.esCorrecto, isTrue);
      expect(resCorrecto.puntaje, equals(1.0));

      final resIncorrecto = evaluador.evaluar(ej, '200');
      expect(resIncorrecto.esCorrecto, isFalse);
      expect(resIncorrecto.puntaje, equals(0.0));
    });

    test('Evalúa multiplicación corta con segundo operando como incógnita (7 × ? = 56)', () {
      const ej = Aritmetico(
        id: 'A-MULT',
        posicion: PosicionCurricular(tema: 1, subtema: 2, leccion: 1),
        nivel: 1,
        enunciado: 'Completa la multiplicación',
        operacion: OperacionAritmetica.multiplicacion,
        operando1: 7,
        operando2: 8,
        disposicion: DisposicionAritmetica.horizontal,
        incognita: ElementoIncognita.operando2,
      );

      final resCorrecto = evaluador.evaluar(ej, '8');
      expect(resCorrecto.esCorrecto, isTrue);

      final resIncorrecto = evaluador.evaluar(ej, '9');
      expect(resIncorrecto.esCorrecto, isFalse);
    });

    test('Evalúa incógnita en primer término (? - 35 = 42)', () {
      const ej = Aritmetico(
        id: 'A-RESTA',
        posicion: PosicionCurricular(tema: 1, subtema: 3, leccion: 1),
        nivel: 2,
        enunciado: 'Encuentra el minuendo',
        operacion: OperacionAritmetica.resta,
        operando1: 77,
        operando2: 35,
        incognita: ElementoIncognita.operando1,
      );

      final resCorrecto = evaluador.evaluar(ej, '77');
      expect(resCorrecto.esCorrecto, isTrue);

      final resIncorrecto = evaluador.evaluar(ej, '70');
      expect(resIncorrecto.esCorrecto, isFalse);
    });

    test('Evalúa incógnita en operador (7 ? 8 = 56)', () {
      const ej = Aritmetico(
        id: 'A-OP',
        posicion: PosicionCurricular(tema: 1, subtema: 4, leccion: 1),
        nivel: 1,
        enunciado: 'Descubre el operador',
        operacion: OperacionAritmetica.multiplicacion,
        operando1: 7,
        operando2: 8,
        incognita: ElementoIncognita.operador,
      );

      expect(evaluador.evaluar(ej, '×').esCorrecto, isTrue);
      expect(evaluador.evaluar(ej, '*').esCorrecto, isTrue);
      expect(evaluador.evaluar(ej, 'x').esCorrecto, isTrue);
      expect(evaluador.evaluar(ej, '+').esCorrecto, isFalse);
    });

    test('Evalúa división en galera con cociente y resto', () {
      const ej = Aritmetico(
        id: 'A-DIV',
        posicion: PosicionCurricular(tema: 1, subtema: 5, leccion: 1),
        nivel: 2,
        enunciado: 'División en galera',
        operacion: OperacionAritmetica.division,
        operando1: 128,
        operando2: 5,
        disposicion: DisposicionAritmetica.vertical,
        incognita: ElementoIncognita.cociente,
      );

      // Cociente = 25, Resto = 3
      final resAmbosCorrectos = evaluador.evaluar(ej, {'cociente': '25', 'resto': '3'});
      expect(resAmbosCorrectos.esCorrecto, isTrue);
      expect(resAmbosCorrectos.puntaje, equals(1.0));

      final resSoloCociente = evaluador.evaluar(ej, {'cociente': '25', 'resto': '0'});
      expect(resSoloCociente.esCorrecto, isFalse);
      expect(resSoloCociente.puntaje, equals(0.5));
    });

    test('Evalúa formato de fracción (18 / 6 = 3)', () {
      const ej = Aritmetico(
        id: 'A-FRAC',
        posicion: PosicionCurricular(tema: 1, subtema: 6, leccion: 1),
        nivel: 1,
        enunciado: 'Fracción',
        operacion: OperacionAritmetica.division,
        operando1: 18,
        operando2: 6,
        disposicion: DisposicionAritmetica.fraccion,
        incognita: ElementoIncognita.resultado,
      );

      expect(evaluador.evaluar(ej, '3').esCorrecto, isTrue);
      expect(evaluador.evaluar(ej, '6/2').esCorrecto, isTrue);
      expect(evaluador.evaluar(ej, '4').esCorrecto, isFalse);
    });
  });

  group('GeneradorAritmetica', () {
    final generador = GeneradorAritmetica();

    test('Genera ejercicios de suma válidos', () {
      final ej = generador.generar(operacion: OperacionAritmetica.suma, nivel: 1);
      expect(ej.operacion, equals(OperacionAritmetica.suma));
      expect(ej.resultadoExacto, equals(ej.operando1 + ej.operando2));
    });

    test('Genera divisiones exactas en nivel 1', () {
      final ej = generador.generar(operacion: OperacionAritmetica.division, nivel: 1);
      expect(ej.operando1 % ej.operando2, equals(0));
    });

    test('Despacho a través de ServicioEvaluacion', () async {
      final servicio = ServicioEvaluacion();
      const ej = Aritmetico(
        id: 'SERV-1',
        posicion: PosicionCurricular(tema: 1, subtema: 1, leccion: 1),
        nivel: 1,
        enunciado: 'Test servicio',
        operacion: OperacionAritmetica.suma,
        operando1: 10,
        operando2: 5,
      );

      final res = await servicio.evaluar(ejercicio: ej, respuesta: '15');
      expect(res.esCorrecto, isTrue);
    });
  });
}

