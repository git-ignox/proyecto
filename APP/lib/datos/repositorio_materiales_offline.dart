import '../dominio/modelos/recurso_educativo_offline.dart';

/// Contrato para el repositorio de almacenamiento y sincronización de recursos offline.
abstract interface class RepositorioMaterialesOffline {
  /// Devuelve todos los materiales registrados en el sistema para las clases suscritas.
  Future<List<RecursoEducativoOffline>> obtenerTodosMateriales();

  /// Devuelve los materiales correspondientes a una clase escolar específica.
  Future<List<RecursoEducativoOffline>> obtenerMaterialesPorClase(String claseId);

  /// Devuelve los materiales de las clases de la semana (próximos 7 días).
  Future<List<RecursoEducativoOffline>> obtenerMaterialesSemana({DateTime? ahora});

  /// Busca un recurso por su identificador único.
  Future<RecursoEducativoOffline?> obtenerMaterialPorId(String id);

  /// Agrega o actualiza un material compartido por un profesor.
  Future<void> guardarMaterial(RecursoEducativoOffline material);

  /// Marca o desmarca un archivo como "Fijado / Intocable" por el alumno.
  Future<void> fijarMaterial(String materialId, bool fijado);

  /// Registra que el alumno abrió o consumió el material, marcando el timestamp de visualización.
  Future<void> registrarVisualizacion(String materialId);

  /// Actualiza o registra el estado de descarga de un recurso.
  Future<void> actualizarTareaSincronizacion(TareaSincronizacion tarea);

  /// Obtiene la tarea actual de sincronización de un recurso.
  Future<TareaSincronizacion?> obtenerTarea(String recursoId);

  /// Elimina el archivo local de la caché (manteniendo el metadato del recurso).
  Future<void> eliminarArchivoLocal(String materialId);

  /// Stream reactivo con la lista completa de recursos offline.
  Stream<List<RecursoEducativoOffline>> materialesStream();

  /// Stream reactivo con el mapa de tareas de sincronización (recursoId -> Tarea).
  Stream<Map<String, TareaSincronizacion>> tareasStream();
}
