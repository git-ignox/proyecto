import '../modelos/ejercicio.dart';
import '../modelos/posicion_curricular.dart';

/// Administrador y organizador de ejercicios matemáticos estructurado
/// en base a los 3 parámetros numéricos: tema, subtema y lección (e.g. 3.2.1).
class OrganizadorEjercicios {
  OrganizadorEjercicios(List<Ejercicio> ejercicios)
      : _ejercicios = List.unmodifiable([...ejercicios]..sort());

  final List<Ejercicio> _ejercicios;

  /// Retorna todos los ejercicios ordenados curricularmente por (tema -> subtema -> leccion).
  List<Ejercicio> get ejerciciosOrdenados => _ejercicios;

  /// Total de ejercicios registrados.
  int get totalEjercicios => _ejercicios.length;

  /// 1. Obtiene la lista ordenada de números de tema disponibles (e.g. [1, 2, 3]).
  List<int> obtenerTemas() {
    final temas = _ejercicios.map((e) => e.tema).toSet().toList()..sort();
    return temas;
  }

  /// 2. Obtiene la lista ordenada de números de subtema dentro de un [tema] dado.
  List<int> obtenerSubtemas(int tema) {
    final subtemas = _ejercicios
        .where((e) => e.tema == tema)
        .map((e) => e.subtema)
        .toSet()
        .toList()
      ..sort();
    return subtemas;
  }

  /// 3. Obtiene la lista ordenada de números de lección dentro de un [tema] y [subtema].
  List<int> obtenerLecciones(int tema, int subtema) {
    final lecciones = _ejercicios
        .where((e) => e.tema == tema && e.subtema == subtema)
        .map((e) => e.leccion)
        .toSet()
        .toList()
      ..sort();
    return lecciones;
  }

  /// Filtra ejercicios pertenecientes a un [tema] específico.
  List<Ejercicio> filtrarPorTema(int tema) {
    return _ejercicios.where((e) => e.tema == tema).toList();
  }

  /// Filtra ejercicios pertenecientes a un [tema] y [subtema] específicos.
  List<Ejercicio> filtrarPorSubtema(int tema, int subtema) {
    return _ejercicios
        .where((e) => e.tema == tema && e.subtema == subtema)
        .toList();
  }

  /// Filtra ejercicios correspondientes a una lección exacta [tema].[subtema].[leccion].
  List<Ejercicio> filtrarPorLeccion(int tema, int subtema, int leccion) {
    return _ejercicios
        .where((e) =>
            e.tema == tema && e.subtema == subtema && e.leccion == leccion)
        .toList();
  }

  /// Busca un ejercicio por su posición curricular (e.g. 3.2.1).
  Ejercicio? buscarPorPosicion(PosicionCurricular posicion) {
    try {
      return _ejercicios.firstWhere((e) => e.posicion == posicion);
    } catch (_) {
      return null;
    }
  }

  /// Busca un ejercicio por su código de posición en texto (e.g. "3.2.1").
  Ejercicio? buscarPorCodigo(String codigo) {
    final posicion = PosicionCurricular.desdeCodigo(codigo);
    return buscarPorPosicion(posicion);
  }

  /// Retorna el siguiente ejercicio en la secuencia curricular.
  Ejercicio? obtenerSiguiente(Ejercicio actual) {
    final indice = _ejercicios.indexWhere((e) => e.id == actual.id);
    if (indice >= 0 && indice < _ejercicios.length - 1) {
      return _ejercicios[indice + 1];
    }
    return null;
  }

  /// Retorna el ejercicio anterior en la secuencia curricular.
  Ejercicio? obtenerAnterior(Ejercicio actual) {
    final indice = _ejercicios.indexWhere((e) => e.id == actual.id);
    if (indice > 0) {
      return _ejercicios[indice - 1];
    }
    return null;
  }

  /// Genera un mapa jerárquico de la estructura curricular:
  /// { tema: { subtema: [leccion1, leccion2, ...] } }
  Map<int, Map<int, List<int>>> obtenerArbolCurricular() {
    final Map<int, Map<int, List<int>>> arbol = {};

    for (final ej in _ejercicios) {
      final t = ej.tema;
      final s = ej.subtema;
      final l = ej.leccion;

      arbol.putIfAbsent(t, () => {});
      arbol[t]!.putIfAbsent(s, () => []);
      if (!arbol[t]![s]!.contains(l)) {
        arbol[t]![s]!.add(l);
        arbol[t]![s]!.sort();
      }
    }

    return arbol;
  }
}

