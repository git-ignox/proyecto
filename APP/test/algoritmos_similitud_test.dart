import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/dominio/algoritmos/distancia_levenshtein.dart';
import 'package:proyecto/dominio/algoritmos/motor_similitud.dart';
import 'package:proyecto/dominio/algoritmos/similitud_jaccard.dart';
import 'package:proyecto/dominio/algoritmos/tfidf_coseno.dart';

void main() {
  group('Algoritmo DistanciaLevenshtein', () {
    const levenshtein = DistanciaLevenshtein();

    test('calcula distancia 0 y similitud 1.0 para cadenas idénticas', () {
      expect(levenshtein.calcularDistancia('discriminante', 'discriminante'), equals(0));
      expect(levenshtein.calcularSimilitud('discriminante', 'discriminante'), equals(1.0));
    });

    test('tolera typos comunes en palabras matemáticas', () {
      // "descriminante" vs "discriminante" (1 sustitución)
      final dist = levenshtein.calcularDistancia('descriminante', 'discriminante');
      final sim = levenshtein.calcularSimilitud('descriminante', 'discriminante');
      expect(dist, equals(1));
      expect(sim, greaterThan(0.90));
    });

    test('contieneAproximacion detecta palabras clave con faltas de ortografía leves', () {
      const texto = 'Primero calculamos el descriminante de la ecuacion cuadrática.';
      expect(levenshtein.contieneAproximacion(texto, 'discriminante'), isTrue);
      expect(levenshtein.contieneAproximacion(texto, 'ecuacion'), isTrue);
      expect(levenshtein.contieneAproximacion(texto, 'hipotenusa'), isFalse);
    });
  });

  group('Algoritmo SimilitudJaccard', () {
    const jaccard = SimilitudJaccard();

    test('calcula solapamiento de tokens y n-gramas', () {
      const s1 = 'x = 3 y x = -1';
      const s2 = 'las soluciones son x = 3 y x = -1';
      final simTokens = jaccard.similitudPorTokens(s1, s2);
      expect(simTokens, greaterThan(0.5));

      final simCombinada = jaccard.calcularSimilitud(s1, s2);
      expect(simCombinada, greaterThan(0.5));
    });

    test('devuelve 0.0 para textos sin ningún término en común', () {
      const s1 = 'triangulo rectangulo catetos hipotenusa';
      const s2 = 'derivada integral limite convergencia';
      final sim = jaccard.calcularSimilitud(s1, s2);
      expect(sim, equals(0.0));
    });
  });

  group('Algoritmo TfidfCoseno', () {
    const tfidf = TfidfCoseno();

    test('calcula similitud alta para respuestas con los mismos conceptos clave', () {
      const s1 = 'El discriminante es 64 por lo tanto las raices son 3 y -1';
      const s2 = 'Calculando el discriminante obtenemos 64 dando raices 3 y -1';
      final sim = tfidf.calcularSimilitud(s1, s2);
      expect(sim, greaterThan(0.70));
    });

    test('pondera bajo los conectores comunes frente a los terminos matematicos', () {
      const s1 = 'de la que en por con';
      const s2 = 'discriminante matriz autovalor';
      final sim = tfidf.calcularSimilitud(s1, s2);
      expect(sim, equals(0.0));
    });
  });

  group('MotorSimilitud Híbrido', () {
    const motor = MotorSimilitud();

    test('analiza respuesta completa con alta similitud y detección de palabras clave', () {
      const respuesta = 'Identifico a=2, b=-4, c=-6. El discriminante es 64 y las soluciones son x = 3 y x = -1.';
      const solucion = 'Identificamos los coeficientes a = 2, b = -4, c = -6. Calculamos el discriminante 64. Soluciones x = 3 y x = -1.';
      final claves = ['a = 2', 'discriminante', '64', 'x = 3', 'x = -1'];

      final analisis = motor.analizar(
        respuesta: respuesta,
        solucion: solucion,
        palabrasClave: claves,
      );

      expect(analisis.similitudHibrida, greaterThan(0.75));
      expect(analisis.palabrasClaveFaltantes, isEmpty);
      expect(analisis.porcentajePalabrasClave, equals(1.0));
    });

    test('detecta palabras clave faltantes en respuestas incompletas', () {
      const respuesta = 'Las soluciones son x = 3 y x = -1.';
      const solucion = 'Identificamos los coeficientes a = 2, b = -4, c = -6. Calculamos el discriminante 64. Soluciones x = 3 y x = -1.';
      final claves = ['a = 2', 'discriminante', '64', 'x = 3', 'x = -1'];

      final analisis = motor.analizar(
        respuesta: respuesta,
        solucion: solucion,
        palabrasClave: claves,
      );

      expect(analisis.palabrasClaveEncontradas, contains('x = 3'));
      expect(analisis.palabrasClaveEncontradas, contains('x = -1'));
      expect(analisis.palabrasClaveFaltantes, contains('discriminante'));
      expect(analisis.palabrasClaveFaltantes, contains('64'));
      expect(analisis.porcentajePalabrasClave, lessThan(1.0));
    });
  });
}

