import 'dart:math';

/// Algoritmo de distancia de edición de Levenshtein y cálculo de similitud.
/// Útil para tolerar errores tipográficos (typos) en palabras y términos matemáticos.
class DistanciaLevenshtein {
  const DistanciaLevenshtein();

  /// Calcula la cantidad mínima de inserciones, eliminaciones o sustituciones
  /// necesarias para transformar [s1] en [s2].
  int calcularDistancia(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final a = s1.toLowerCase();
    final b = s2.toLowerCase();

    List<int> anterior = List<int>.generate(b.length + 1, (i) => i);
    List<int> actual = List<int>.filled(b.length + 1, 0);

    for (int i = 0; i < a.length; i++) {
      actual[0] = i + 1;
      for (int j = 0; j < b.length; j++) {
        final costo = (a[i] == b[j]) ? 0 : 1;
        actual[j + 1] = min(
          min(actual[j] + 1, anterior[j + 1] + 1),
          anterior[j] + costo,
        );
      }
      for (int j = 0; j <= b.length; j++) {
        anterior[j] = actual[j];
      }
    }

    return anterior[b.length];
  }

  /// Calcula la similitud normalizada entre 0.0 (totalmente diferente) y 1.0 (idéntico).
  double calcularSimilitud(String s1, String s2) {
    final t1 = s1.trim().toLowerCase();
    final t2 = s2.trim().toLowerCase();

    if (t1 == t2) return 1.0;
    if (t1.isEmpty || t2.isEmpty) return 0.0;

    final longitudMaxima = max(t1.length, t2.length);
    final distancia = calcularDistancia(t1, t2);

    final similitud = 1.0 - (distancia / longitudMaxima);
    return similitud.clamp(0.0, 1.0);
  }

  /// Evalúa si [texto] contiene una aproximación difusa (fuzzy) de [palabraClave],
  /// tolerando pequeños errores de tipeo (e.g. "descriminante" -> "discriminante").
  bool contieneAproximacion(String texto, String palabraClave, {double umbral = 0.75}) {
    final textoNorm = texto.toLowerCase();
    final claveNorm = palabraClave.toLowerCase().trim();

    if (textoNorm.contains(claveNorm)) return true;

    // Si la clave tiene varias palabras, buscar si están todas o la frase completa
    final tokensTexto = textoNorm.split(RegExp(r'[\s,.;:()=]+')).where((t) => t.isNotEmpty);
    final tokensClave = claveNorm.split(RegExp(r'[\s,.;:()=]+')).where((t) => t.isNotEmpty).toList();

    if (tokensClave.isEmpty) return false;

    // Si es un token único
    if (tokensClave.length == 1) {
      final objetivo = tokensClave.first;
      for (final t in tokensTexto) {
        if (calcularSimilitud(t, objetivo) >= umbral) {
          return true;
        }
      }
      return false;
    }

    // Para frases compuestas de varias palabras clave, verificar presencia de la mayoría
    int coincidencias = 0;
    for (final objetivo in tokensClave) {
      bool encontrada = false;
      for (final t in tokensTexto) {
        if (calcularSimilitud(t, objetivo) >= umbral) {
          encontrada = true;
          break;
        }
      }
      if (encontrada) coincidencias++;
    }

    return (coincidencias / tokensClave.length) >= umbral;
  }
}

