import 'dart:math';

/// Algoritmo de similitud Coseno con ponderación TF (Frecuencia de Término) y pesos de dominio matemático.
/// Pondera términos conceptuales y matemáticos sobre conectores gramaticales comunes.
class TfidfCoseno {
  const TfidfCoseno();

  /// Palabras vacías en español que aportan poco valor conceptual.
  static const Set<String> _palabrasVacias = {
    'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas',
    'de', 'del', 'a', 'al', 'en', 'por', 'para', 'con', 'sin',
    'que', 'y', 'e', 'o', 'u', 'es', 'son', 'fue', 'era', 'sea',
    'se', 'su', 'sus', 'lo', 'como', 'pero', 'mas', 'si', 'no',
    'este', 'esta', 'estos', 'estas', 'esto', 'ese', 'esa', 'esos',
  };

  /// Divide el texto en tokens manteniendo variables, números y símbolos matemáticos normalizados.
  List<String> _extraerTokens(String texto) {
    if (texto.trim().isEmpty) return [];

    final normalizado = texto
        .toLowerCase()
        .replaceAllMapped(RegExp(r'([=+\-*/^()√,;:¿?¡!\[\]{}])'), (m) => ' ${m[1]} ')
        .replaceAll(RegExp(r'[¿?¡!;,:"\[\]{}]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return normalizado
        .split(' ')
        .map((t) => t.replaceAll(RegExp(r'^\.|\.$'), ''))
        .where((t) => t.isNotEmpty)
        .toList();
  }

  /// Calcula el vector de frecuencias con pesos de relevancia.
  Map<String, double> _calcularVectorPesos(List<String> tokens) {
    final Map<String, double> vector = {};
    if (tokens.isEmpty) return vector;

    for (final token in tokens) {
      double pesoBase = 1.0;

      if (_palabrasVacias.contains(token)) {
        // Conector común: peso reducido
        pesoBase = 0.2;
      } else if (RegExp(r'[\d=+\-*/^√π]').hasMatch(token)) {
        // Término matemático o numérico: peso aumentado
        pesoBase = 2.5;
      } else if (token.length > 4) {
        // Palabra conceptual larga: peso estándar alto
        pesoBase = 1.8;
      }

      vector[token] = (vector[token] ?? 0.0) + pesoBase;
    }

    return vector;
  }

  /// Calcula la norma euclidiana L2 de un vector de pesos.
  double _calcularNorma(Map<String, double> vector) {
    double sumaCuadrados = 0.0;
    for (final valor in vector.values) {
      sumaCuadrados += valor * valor;
    }
    return sqrt(sumaCuadrados);
  }

  /// Calcula la similitud coseno entre dos textos:
  /// cos(θ) = (u · v) / (||u|| * ||v||)
  double calcularSimilitud(String s1, String s2) {
    final tokens1 = _extraerTokens(s1);
    final tokens2 = _extraerTokens(s2);

    if (tokens1.isEmpty && tokens2.isEmpty) return 1.0;
    if (tokens1.isEmpty || tokens2.isEmpty) return 0.0;

    final vector1 = _calcularVectorPesos(tokens1);
    final vector2 = _calcularVectorPesos(tokens2);

    double productoPunto = 0.0;
    for (final entrada in vector1.entries) {
      final termino = entrada.key;
      final peso1 = entrada.value;
      final peso2 = vector2[termino] ?? 0.0;
      productoPunto += peso1 * peso2;
    }

    final norma1 = _calcularNorma(vector1);
    final norma2 = _calcularNorma(vector2);

    if (norma1 == 0 || norma2 == 0) return 0.0;

    final similitud = productoPunto / (norma1 * norma2);
    return similitud.clamp(0.0, 1.0);
  }
}

