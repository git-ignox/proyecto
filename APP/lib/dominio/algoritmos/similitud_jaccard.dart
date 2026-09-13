/// Algoritmo de similitud de Jaccard a nivel de tokens y n-gramas.
/// Mide el solapamiento de conjuntos: |A ∩ B| / |A ∪ B|.
class SimilitudJaccard {
  const SimilitudJaccard();

  /// Normaliza y separa operadores matemáticos para que "a=2" y "a = 2" sean equivalentes.
  String _normalizarTexto(String texto) {
    return texto
        .toLowerCase()
        .replaceAllMapped(RegExp(r'([=+\-*/^()√,;:¿?¡!\[\]{}])'), (m) => ' ${m[1]} ')
        .replaceAll(RegExp(r'[.,;:¿?¡!()\[\]{}]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Divide el texto en tokens significativos (palabras, operadores y números).
  Set<String> tokenizar(String texto) {
    final normalizado = _normalizarTexto(texto);
    if (normalizado.isEmpty) return {};
    return normalizado.split(' ').where((t) => t.isNotEmpty).toSet();
  }

  /// Genera n-gramas de caracteres (shingles) para capturar subestructuras matemáticas
  /// (e.g. "x^2", "2x+", "+3").
  Set<String> generarNgramas(String texto, {int n = 3}) {
    final limpio = texto.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    if (limpio.length < n) return limpio.isNotEmpty ? {limpio} : {};

    final Set<String> ngramas = {};
    for (int i = 0; i <= limpio.length - n; i++) {
      ngramas.add(limpio.substring(i, i + n));
    }
    return ngramas;
  }

  /// Calcula la similitud de Jaccard entre dos conjuntos genéricos.
  double _calcularSolapamiento<T>(Set<T> conjuntoA, Set<T> conjuntoB) {
    if (conjuntoA.isEmpty && conjuntoB.isEmpty) return 1.0;
    if (conjuntoA.isEmpty || conjuntoB.isEmpty) return 0.0;

    final interseccion = conjuntoA.intersection(conjuntoB).length;
    final union = conjuntoA.union(conjuntoB).length;

    if (union == 0) return 0.0;
    return (interseccion / union).clamp(0.0, 1.0);
  }

  /// Similitud de Jaccard basada en tokens/palabras.
  double similitudPorTokens(String s1, String s2) {
    final tokensA = tokenizar(s1);
    final tokensB = tokenizar(s2);
    return _calcularSolapamiento(tokensA, tokensB);
  }

  /// Similitud de Jaccard basada en n-gramas de caracteres.
  double similitudPorNgramas(String s1, String s2, {int n = 3}) {
    final ngramasA = generarNgramas(s1, n: n);
    final ngramasB = generarNgramas(s2, n: n);
    return _calcularSolapamiento(ngramasA, ngramasB);
  }

  /// Similitud combinada (70% tokens + 30% n-gramas de caracteres).
  double calcularSimilitud(String s1, String s2) {
    final simTokens = similitudPorTokens(s1, s2);
    final simNgramas = similitudPorNgramas(s1, s2);
    return (0.7 * simTokens + 0.3 * simNgramas).clamp(0.0, 1.0);
  }
}

