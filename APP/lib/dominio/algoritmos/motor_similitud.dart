import 'distancia_levenshtein.dart';
import 'similitud_jaccard.dart';
import 'tfidf_coseno.dart';

/// Resultado del análisis multidimensional del motor de similitud.
class AnalisisSimilitud {
  const AnalisisSimilitud({
    required this.similitudLevenshtein,
    required this.similitudJaccard,
    required this.similitudCoseno,
    required this.similitudHibrida,
    required this.palabrasClaveEncontradas,
    required this.palabrasClaveFaltantes,
  });

  final double similitudLevenshtein;
  final double similitudJaccard;
  final double similitudCoseno;
  final double similitudHibrida;
  final List<String> palabrasClaveEncontradas;
  final List<String> palabrasClaveFaltantes;

  /// Proporción de palabras clave encontradas (0.0 a 1.0).
  double get porcentajePalabrasClave {
    final total = palabrasClaveEncontradas.length + palabrasClaveFaltantes.length;
    if (total == 0) return 1.0;
    return palabrasClaveEncontradas.length / total;
  }
}

/// Motor de similitud híbrido para evaluar respuestas matemáticas abiertas.
/// Combina Levenshtein (tolerancia a typos), Jaccard (coincidencia de tokens)
/// y TF-IDF / Coseno (relevancia semántica).
class MotorSimilitud {
  const MotorSimilitud({
    this.pesoLevenshtein = 0.10,
    this.pesoJaccard = 0.45,
    this.pesoCoseno = 0.45,
    this.levenshtein = const DistanciaLevenshtein(),
    this.jaccard = const SimilitudJaccard(),
    this.tfidfCoseno = const TfidfCoseno(),
  });

  final double pesoLevenshtein;
  final double pesoJaccard;
  final double pesoCoseno;

  final DistanciaLevenshtein levenshtein;
  final SimilitudJaccard jaccard;
  final TfidfCoseno tfidfCoseno;

  /// Analiza una [respuesta] de estudiante comparándola contra la [solucion] modelo
  /// y verificando la presencia de [palabrasClave].
  AnalisisSimilitud analizar({
    required String respuesta,
    required String solucion,
    List<String> palabrasClave = const [],
  }) {
    // 1. Similitud por Levenshtein (distancia de edición y typos)
    final simLev = levenshtein.calcularSimilitud(respuesta, solucion);

    // 2. Similitud por Jaccard (conjuntos de tokens y n-gramas)
    final simJac = jaccard.calcularSimilitud(respuesta, solucion);

    // 3. Similitud por Coseno con ponderación TF-IDF
    final simCos = tfidfCoseno.calcularSimilitud(respuesta, solucion);

    // 4. Combinación ponderada
    final simHibrida = (pesoLevenshtein * simLev +
            pesoJaccard * simJac +
            pesoCoseno * simCos)
        .clamp(0.0, 1.0);

    // 5. Verificación difusa de palabras clave
    final List<String> encontradas = [];
    final List<String> faltantes = [];

    for (final clave in palabrasClave) {
      if (levenshtein.contieneAproximacion(respuesta, clave)) {
        encontradas.add(clave);
      } else {
        faltantes.add(clave);
      }
    }

    return AnalisisSimilitud(
      similitudLevenshtein: simLev,
      similitudJaccard: simJac,
      similitudCoseno: simCos,
      similitudHibrida: simHibrida,
      palabrasClaveEncontradas: encontradas,
      palabrasClaveFaltantes: faltantes,
    );
  }
}

