import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/dominio/evaluadores/evaluador_aritmetico.dart';
import 'package:proyecto/dominio/evaluadores/evaluador_desarrollo.dart';
import 'package:proyecto/dominio/evaluadores/evaluador_numerico.dart';
import 'package:proyecto/dominio/evaluadores/evaluador_seleccion_multiple.dart';
import 'package:proyecto/dominio/modelos/aritmetico.dart';
import 'package:proyecto/dominio/modelos/desarrollo.dart';
import 'package:proyecto/dominio/modelos/error_aprendizaje.dart';
import 'package:proyecto/dominio/modelos/numerico.dart';
import 'package:proyecto/dominio/modelos/posicion_curricular.dart';
import 'package:proyecto/dominio/modelos/seleccion_multiple.dart';

void main() {
  group('ClasificadorErrores - Aritmética y Detección de Patrones', () {
    const evaluadorAritmetico = EvaluadorAritmetico();

    test('Detecta olvido de acarreo/llevada en suma en columna (125 + 78 = 193 en vez de 203)', () {
      const ejSuma = Aritmetico(
        id: 'SUM-01',
        posicion: PosicionCurricular(tema: 1, subtema: 1, leccion: 1),
        nivel: 1,
        enunciado: '125 + 78',
        operacion: OperacionAritmetica.suma,
        operando1: 125,
        operando2: 78,
        tags: ['aritmetica', 'suma', 'acarreo'],
      );

      // Si el alumno suma 5+8=13 (pone 3 pero no lleva 1 a decenas: 2+7=9, 1+0=1 -> 193)
      final resultado = evaluadorAritmetico.evaluar(ejSuma, '193');

      expect(resultado.esCorrecto, isFalse);
      expect(resultado.errorDetectado, isNotNull);
      expect(resultado.errorDetectado!.categoria, equals(CategoriaError.acarreoReagrupacion));
      expect(resultado.errorDetectado!.subtipo, equals('olvido_acarreo_llevada'));
      expect(resultado.errorDetectado!.tagsAsociados, contains('acarreo'));
    });

    test('Detecta operación invertida (hizo resta en vez de suma)', () {
      const ejSuma = Aritmetico(
        id: 'SUM-02',
        posicion: PosicionCurricular(tema: 1, subtema: 1, leccion: 1),
        nivel: 1,
        enunciado: '50 + 20',
        operacion: OperacionAritmetica.suma,
        operando1: 50,
        operando2: 20,
        tags: ['suma'],
      );

      // Alumno ingresa 30 (50 - 20)
      final resultado = evaluadorAritmetico.evaluar(ejSuma, '30');

      expect(resultado.esCorrecto, isFalse);
      expect(resultado.errorDetectado, isNotNull);
      expect(resultado.errorDetectado!.categoria, equals(CategoriaError.signoOperacion));
      expect(resultado.errorDetectado!.subtipo, equals('resto_en_lugar_de_sumar'));
    });

    test('Detecta error en tablas de multiplicar (7 × 8 = 54 o 49 en vez de 56)', () {
      const ejMult = Aritmetico(
        id: 'MULT-01',
        posicion: PosicionCurricular(tema: 1, subtema: 2, leccion: 1),
        nivel: 1,
        enunciado: '7 × 8',
        operacion: OperacionAritmetica.multiplicacion,
        operando1: 7,
        operando2: 8,
        tags: ['multiplicacion', 'tablas-multiplicar'],
      );

      // Alumno ingresa 49 (7 * 7)
      final resultado = evaluadorAritmetico.evaluar(ejMult, '49');

      expect(resultado.esCorrecto, isFalse);
      expect(resultado.errorDetectado, isNotNull);
      expect(resultado.errorDetectado!.categoria, equals(CategoriaError.hechoNumerico));
      expect(resultado.errorDetectado!.subtipo, equals('error_tabla_multiplicar'));
    });

    test('Detecta error de despeje de incógnita en ecuación de casilla (? - 35 = 42)', () {
      const ejDespeje = Aritmetico(
        id: 'DESP-01',
        posicion: PosicionCurricular(tema: 1, subtema: 3, leccion: 1),
        nivel: 2,
        enunciado: '? - 35 = 42',
        operacion: OperacionAritmetica.resta,
        operando1: 77,
        operando2: 35,
        incognita: ElementoIncognita.operando1,
        tags: ['despeje', 'resta'],
      );

      // Si el alumno resta 42 - 35 = 7 en vez de sumar 42 + 35 = 77
      final resultado = evaluadorAritmetico.evaluar(ejDespeje, '7');

      expect(resultado.esCorrecto, isFalse);
      expect(resultado.errorDetectado, isNotNull);
      expect(resultado.errorDetectado!.categoria, equals(CategoriaError.despejeIncognita));
      expect(resultado.errorDetectado!.subtipo, equals('resta_en_vez_de_suma_para_minuendo'));
    });

    test('Detecta error en residuo/resto de división en galera', () {
      const ejDiv = Aritmetico(
        id: 'DIV-01',
        posicion: PosicionCurricular(tema: 1, subtema: 4, leccion: 1),
        nivel: 2,
        enunciado: '127 ÷ 5',
        operacion: OperacionAritmetica.division,
        operando1: 127,
        operando2: 5,
        tags: ['division-galera', 'resto'],
      );

      // Cociente 25 (correcto), pero resto 4 (erróneo, esperado 2)
      final resultado = evaluadorAritmetico.evaluar(ejDiv, {'cociente': '25', 'resto': '4'});

      expect(resultado.esCorrecto, isFalse);
      expect(resultado.errorDetectado, isNotNull);
      expect(resultado.errorDetectado!.categoria, equals(CategoriaError.procedimientoAlgoritmo));
      expect(resultado.errorDetectado!.subtipo, equals('calculo_resto_incorrecto'));
    });
  });

  group('ClasificadorErrores - Numérico, Algebraico, Desarrollo y Selección', () {
    test('Numérico: detecta signo opuesto y error de precisión/redondeo', () {
      const evaluadorNumerico = EvaluadorNumerico();
      const ejNum = Numerico(
        id: 'NUM-01',
        posicion: PosicionCurricular(tema: 2, subtema: 1, leccion: 1),
        nivel: 1,
        enunciado: 'Calcula x',
        valorEsperado: 12.5,
        tolerancia: 0.01,
        tags: ['decimales'],
      );

      // Signo opuesto
      final resSigno = evaluadorNumerico.evaluar(ejNum, '-12.5');
      expect(resSigno.errorDetectado?.categoria, equals(CategoriaError.signoOperacion));
      expect(resSigno.errorDetectado?.subtipo, equals('signo_opuesto'));

      // Error de redondeo (dentro de 15*tol pero fuera de tol)
      final resPrecision = evaluadorNumerico.evaluar(ejNum, '12.55');
      expect(resPrecision.errorDetectado?.categoria, equals(CategoriaError.precisionRedondeo));
    });

    test('Desarrollo: detecta conceptos y palabras clave omitidas', () {
      const evaluadorDesarrollo = EvaluadorDesarrollo();
      const ejDes = Desarrollo(
        id: 'DES-01',
        posicion: PosicionCurricular(tema: 3, subtema: 1, leccion: 1),
        nivel: 2,
        enunciado: 'Explica el cálculo del discriminante',
        solucion: 'El discriminante se calcula como b al cuadrado menos cuatro ac',
        palabrasClave: ['discriminante', 'cuadrado'],
        tags: ['algebra', 'discriminante'],
      );

      final res = evaluadorDesarrollo.evaluar(ejDes, 'La fórmula general usa raíces');
      expect(res.esCorrecto, isFalse);
      expect(res.errorDetectado?.categoria, equals(CategoriaError.comprensionConceptual));
      expect(res.errorDetectado?.subtipo, equals('conceptos_clave_omitidos'));
    });

    test('Selección Múltiple: clasifica distractor', () {
      const evaluadorSM = EvaluadorSeleccionMultiple();
      const ejSM = SeleccionMultiple(
        id: 'SM-01',
        posicion: PosicionCurricular(tema: 4, subtema: 1, leccion: 1),
        nivel: 1,
        enunciado: '¿Cuál es un número primo?',
        opciones: [
          Opcion(id: 'a', texto: '4', esCorrecta: false, retroalimentacion: '4 es divisible por 2.'),
          Opcion(id: 'b', texto: '5', esCorrecta: true),
        ],
        tags: ['primos'],
      );

      final res = evaluadorSM.evaluar(ejSM, 'a');
      expect(res.esCorrecto, isFalse);
      expect(res.errorDetectado?.categoria, equals(CategoriaError.comprensionConceptual));
      expect(res.errorDetectado?.descripcion, contains('4 es divisible por 2'));
    });
  });
}
