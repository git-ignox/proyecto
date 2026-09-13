import '../dominio/modelos/ejercicio.dart';
import '../dominio/modelos/posicion_curricular.dart';

/// Contrato del repositorio para consultar, crear y gestionar ejercicios matemáticos.
abstract class RepositorioEjercicios {
  /// Obtiene la lista completa de ejercicios disponibles.
  Future<List<Ejercicio>> obtenerTodos();

  /// Busca un ejercicio por su identificador único.
  Future<Ejercicio?> obtenerPorId(String id);

  /// Busca un ejercicio por su posición curricular (tema, subtema, leccion).
  Future<Ejercicio?> obtenerPorPosicion(PosicionCurricular posicion);

  /// Filtra ejercicios por número de tema (1er parámetro).
  Future<List<Ejercicio>> obtenerPorTema(int tema);

  /// Filtra ejercicios por número de tema y subtema (1er y 2do parámetro).
  Future<List<Ejercicio>> obtenerPorSubtema(int tema, int subtema);

  /// Filtra ejercicios por lección exacta (tema, subtema, leccion).
  Future<List<Ejercicio>> obtenerPorLeccion(int tema, int subtema, int leccion);

  /// Agrega un nuevo ejercicio al catálogo.
  Future<void> agregarEjercicio(Ejercicio ejercicio);

  /// Elimina un ejercicio por su identificador.
  Future<void> eliminarEjercicio(String id);

  /// Limpia todos los ejercicios.
  Future<void> limpiar();
}
