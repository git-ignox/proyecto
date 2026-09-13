import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/dominio/evaluadores/evaluador_algebraico.dart';
import 'package:proyecto/dominio/evaluadores/evaluador_desarrollo.dart';
import 'package:proyecto/dominio/evaluadores/evaluador_numerico.dart';
import 'package:proyecto/dominio/evaluadores/evaluador_seleccion_multiple.dart';
import 'package:proyecto/dominio/evaluadores/servicio_evaluacion.dart';
import 'package:proyecto/dominio/modelos/algebraico.dart';
import 'package:proyecto/dominio/modelos/desarrollo.dart';
import 'package:proyecto/dominio/modelos/numerico.dart';
import 'package:proyecto/dominio/modelos/posicion_curricular.dart';
import 'package:proyecto/dominio/modelos/seleccion_multiple.dart';
import 'package:proyecto/dominio/modelos/tipo_ejercicio.dart';

void main() {
  group('EvaluadorSeleccionMultiple', () {
    const evaluador = EvaluadorSeleccionMultiple();
    const ejercicio = SeleccionMultiple(
      id: 'SM-1',
      posicion: PosicionCurricular(tema: 1, subtema: 1, leccion: 1),
      nivel: 1,
      enunciado: '¿Cuánto es 2 + 2?',
      opciones: [
        Opcion(id: 'a', texto: '4', esCorrecta: true),
        Opcion(id: 'b', texto: '5', esCorrecta: false),
      ],
    );

    test('califica como correcto cuando se elige la opción adecuada', () {
      final res = evaluador.evaluar(ejercicio, 'a');
      expect(res.esCorrecto, isTrue);
      expect(res.puntaje, equals(1.0));
    });

    test('califica como incorrecto cuando se elige una opción equivocada', () {
      final res = evaluador.evaluar(ejercicio, 'b');
      expect(res.esCorrecto, isFalse);
      expect(res.puntaje, equals(0.0));
    });

    test('maneja selección vacía correctamente', () {
      final res = evaluador.evaluar(ejercicio, null);
      expect(res.esCorrecto, isFalse);
    });
  });

  group('EvaluadorNumerico', () {
    const evaluador = EvaluadorNumerico();
    const ejercicio = Numerico(
      id: 'NUM-1',
      posicion: PosicionCurricular(tema: 2, subtema: 1, leccion: 1),
      nivel: 1,
      enunciado: 'Calcula 5 / 4',
      valorEsperado: 1.25,
      tolerancia: 0.01,
    );

    test('acepta valor decimal con punto', () {
      final res = evaluador.evaluar(ejercicio, '1.25');
      expect(res.esCorrecto, isTrue);
      expect(res.puntaje, equals(1.0));
    });

    test('acepta valor decimal con coma', () {
      final res = evaluador.evaluar(ejercicio, '1,25');
      expect(res.esCorrecto, isTrue);
      expect(res.puntaje, equals(1.0));
    });

    test('acepta entrada en formato de fracción equivalente', () {
      final res = evaluador.evaluar(ejercicio, '5/4');
      expect(res.esCorrecto, isTrue);
      expect(res.puntaje, equals(1.0));
    });

    test('rechaza valores fuera del margen de tolerancia', () {
      final res = evaluador.evaluar(ejercicio, '2.0');
      expect(res.esCorrecto, isFalse);
      expect(res.puntaje, equals(0.0));
    });
  });

  group('EvaluadorAlgebraico', () {
    const evaluador = EvaluadorAlgebraico();
    const ejercicio = Algebraico(
      id: 'ALG-1',
      posicion: PosicionCurricular(tema: 2, subtema: 2, leccion: 1),
      nivel: 2,
      enunciado: 'Factoriza x² - 9',
      expresionCanonica: '(x-3)(x+3)',
      formasEquivalentes: ['(x+3)(x-3)'],
    );

    test('valida la forma canónica exacta', () {
      final res = evaluador.evaluar(ejercicio, '(x-3)(x+3)');
      expect(res.esCorrecto, isTrue);
    });

    test('valida formas con espacios u orden equivalente', () {
      final res = evaluador.evaluar(ejercicio, '(x + 3) * (x - 3)');
      expect(res.esCorrecto, isTrue);
    });

    test('rechaza expresiones algebraicas incorrectas', () {
      final res = evaluador.evaluar(ejercicio, '(x-9)(x+1)');
      expect(res.esCorrecto, isFalse);
    });
  });

  group('EvaluadorDesarrollo', () {
    const evaluador = EvaluadorDesarrollo();
    const ejercicio = Desarrollo(
      id: 'DES-1',
      posicion: PosicionCurricular(tema: 3, subtema: 2, leccion: 1),
      nivel: 2,
      enunciado: 'Resuelve 2x² - 4x - 6 = 0',
      solucion: 'Identificamos los coeficientes a = 2, b = -4, c = -6. Calculamos el discriminante 64. Las soluciones son x = 3 y x = -1.',
      palabrasClave: ['a = 2', 'discriminante', '64', 'x = 3', 'x = -1'],
      umbralSimilitud: 0.60,
    );

    test('otorga puntaje alto a una respuesta completa y bien desarrollada', () {
      const respuesta = 'Identifico a=2, b=-4, c=-6. El discriminante es 64 y las soluciones son x = 3 y x = -1.';
      final res = evaluador.evaluar(ejercicio, respuesta);

      expect(res.esCorrecto, isTrue);
      expect(res.puntaje, greaterThanOrEqualTo(0.80));
      expect(res.similitudHibrida, greaterThan(0.70));
    });

    test('tolera errores tipográficos menores gracias a Levenshtein', () {
      // "descriminante" con typo
      const respuestaConTypo = 'Identifico a=2, b=-4, c=-6. El descriminante es 64 y las soluciones son x = 3 y x = -1.';
      final res = evaluador.evaluar(ejercicio, respuestaConTypo);

      expect(res.esCorrecto, isTrue);
      expect(res.palabrasClaveEncontradas, contains('discriminante'));
    });

    test('otorga puntaje parcial y advierte de conceptos faltantes en respuesta incompleta', () {
      const respuestaCorta = 'Las soluciones son x = 3 y x = -1.';
      final res = evaluador.evaluar(ejercicio, respuestaCorta);

      expect(res.palabrasClaveFaltantes, contains('discriminante'));
      expect(res.palabrasClaveFaltantes, contains('64'));
      expect(res.retroalimentacion, contains('Te faltó'));
    });
  });

  group('ServicioEvaluacion (Orquestador Offline / Online)', () {
    test('evalúa en modo offline por defecto y permite cambiar a online', () async {
      final servicio = ServicioEvaluacion();
      expect(servicio.modo, equals(ModoEvaluacion.offline));

      const ejercicio = Numerico(
        id: 'NUM-1',
        posicion: PosicionCurricular(tema: 1, subtema: 1, leccion: 1),
        nivel: 1,
        enunciado: '2 + 2',
        valorEsperado: 4.0,
      );

      final resOffline = await servicio.evaluar(ejercicio: ejercicio, respuesta: '4');
      expect(resOffline.esCorrecto, isTrue);
      expect(resOffline.retroalimentacion.contains('[Modo Online IA]'), isFalse);

      servicio.modo = ModoEvaluacion.online;
      final resOnline = await servicio.evaluar(ejercicio: ejercicio, respuesta: '4');
      expect(resOnline.esCorrecto, isTrue);
      expect(resOnline.retroalimentacion, contains('[Modo Online IA]'));
    });
  });
}
