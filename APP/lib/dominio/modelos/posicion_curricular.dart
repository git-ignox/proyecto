/// Representa la posición curricular jerárquica de un ejercicio basada en 3 parámetros numéricos:
/// 1. [tema]: Número del tema principal (e.g. 3).
/// 2. [subtema]: Número del subtema dentro del tema (e.g. 2).
/// 3. [leccion]: Número de la lección o ejercicio dentro del subtema (e.g. 1).
///
/// Formato de código resultante: "3.2.1".
class PosicionCurricular implements Comparable<PosicionCurricular> {
  const PosicionCurricular({
    required this.tema,
    required this.subtema,
    required this.leccion,
  });

  /// Crea una instancia a partir de un código tipo "3.2.1" o "3.2".
  factory PosicionCurricular.desdeCodigo(String codigo) {
    final partes = codigo.split('.').map((p) => int.tryParse(p.trim()) ?? 1).toList();
    final tema = partes.isNotEmpty ? partes[0] : 1;
    final subtema = partes.length > 1 ? partes[1] : 1;
    final leccion = partes.length > 2 ? partes[2] : 1;

    return PosicionCurricular(
      tema: tema,
      subtema: subtema,
      leccion: leccion,
    );
  }

  /// 1er parámetro: Número de Tema
  final int tema;

  /// 2do parámetro: Número de Subtema
  final int subtema;

  /// 3er parámetro: Número de Lección
  final int leccion;

  /// Retorna la representación en formato de puntos "tema.subtema.leccion" (e.g. "3.2.1").
  String get codigo => '$tema.$subtema.$leccion';

  /// Verifica si esta posición pertenece al tema especificado.
  bool coincideConTema(int temaId) => tema == temaId;

  /// Verifica si esta posición pertenece al tema y subtema especificados.
  bool coincideConSubtema(int temaId, int subtemaId) =>
      tema == temaId && subtema == subtemaId;

  /// Verifica si coincide exactamente en tema, subtema y lección.
  bool coincideConLeccion(int temaId, int subtemaId, int leccionId) =>
      tema == temaId && subtema == subtemaId && leccion == leccionId;

  @override
  int compareTo(PosicionCurricular other) {
    if (tema != other.tema) return tema.compareTo(other.tema);
    if (subtema != other.subtema) return subtema.compareTo(other.subtema);
    return leccion.compareTo(other.leccion);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PosicionCurricular &&
          runtimeType == other.runtimeType &&
          tema == other.tema &&
          subtema == other.subtema &&
          leccion == other.leccion;

  @override
  int get hashCode => Object.hash(tema, subtema, leccion);

  @override
  String toString() => codigo;
}

