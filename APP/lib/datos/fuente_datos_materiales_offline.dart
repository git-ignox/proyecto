import 'dart:async';
import '../dominio/modelos/recurso_educativo_offline.dart';
import '../dominio/sincronizacion/calculador_disponibilidad_semana.dart';
import 'repositorio_materiales_offline.dart';

/// Implementación en memoria y reactiva del repositorio de materiales offline,
/// con datos iniciales pedagógicos realistas para pruebas inmediatas y funcionamiento offline.
class FuenteDatosMaterialesOffline implements RepositorioMaterialesOffline {
  FuenteDatosMaterialesOffline({
    List<RecursoEducativoOffline>? materialesIniciales,
    Map<String, TareaSincronizacion>? tareasIniciales,
  }) {
    if (materialesIniciales != null) {
      for (final m in materialesIniciales) {
        _materiales[m.id] = m;
      }
    } else {
      _inicializarDatosPredeterminados();
    }

    if (tareasIniciales != null) {
      _tareas.addAll(tareasIniciales);
    } else {
      _sincronizarTareasIniciales();
    }

    _emitirMateriales();
    _emitirTareas();
  }

  final Map<String, RecursoEducativoOffline> _materiales = {};
  final Map<String, TareaSincronizacion> _tareas = {};

  final StreamController<List<RecursoEducativoOffline>> _materialesController =
      StreamController<List<RecursoEducativoOffline>>.broadcast();

  final StreamController<Map<String, TareaSincronizacion>> _tareasController =
      StreamController<Map<String, TareaSincronizacion>>.broadcast();

  final CalculadorDisponibilidadSemana _calculadorSemana =
      const CalculadorDisponibilidadSemana();

  void _inicializarDatosPredeterminados() {
    final ahora = DateTime.now();

    // 1. Guía de ejercicios de Matemáticas para mañana (Obligatorio, 2.5 MB)
    final m1 = RecursoEducativoOffline(
      id: 'REC-MAT-01',
      claseId: 'CLASE-DEMO-001',
      materia: 'Matemáticas',
      titulo: 'Guía de Fracciones y Álgebra Básica',
      descripcion: 'Ejercicios prácticos para resolver durante la sesión de mañana.',
      tipoRecurso: TipoRecursoEducativo.pdf,
      remoteUrl: 'https://cdn.escuela.edu/matematica/fracciones_guia.pdf',
      localPath: '/storage/emulated/0/Android/data/app/files/fracciones_guia.pdf',
      tamanoBytes: 2500000, // 2.5 MB
      checksumSha256: 'sha256_mat_01_hash_valido',
      esObligatorio: true,
      esFijado: true, // Intocable
      fechaUsoClase: ahora.add(const Duration(hours: 18)),
      ultimoAcceso: ahora.subtract(const Duration(hours: 2)),
      diasRetencion: 7,
      profesorNombre: 'Docente Demo',
    );

    // 2. Página web empaquetada (MHTML) de Historia para pasado mañana (Obligatorio, 1.8 MB)
    final m2 = RecursoEducativoOffline(
      id: 'REC-HIST-01',
      claseId: 'CLASE-DEMO-001',
      materia: 'Historia',
      titulo: 'Lectura Interactiva: Civilizaciones Precolombinas',
      descripcion: 'Página web interactiva con mapas y líneas de tiempo offline.',
      tipoRecurso: TipoRecursoEducativo.paginaWebMhtml,
      remoteUrl: 'https://cdn.escuela.edu/historia/precolombinas.mhtml',
      localPath: '/storage/emulated/0/Android/data/app/files/precolombinas.mhtml',
      tamanoBytes: 1800000, // 1.8 MB
      checksumSha256: 'sha256_hist_01_hash_valido',
      esObligatorio: true,
      esFijado: false,
      fechaUsoClase: ahora.add(const Duration(hours: 42)),
      ultimoAcceso: null,
      diasRetencion: 7,
      profesorNombre: 'Prof. Carlos Morales',
    );

    // 3. Documento de Ciencias para el viernes (Obligatorio, 3.2 MB)
    final m3 = RecursoEducativoOffline(
      id: 'REC-CIEN-01',
      claseId: 'CLASE-DEMO-001',
      materia: 'Ciencias Naturales',
      titulo: 'Protocolo de Laboratorio: Microscopía',
      descripcion: 'Instrucciones paso a paso para el experimento de células.',
      tipoRecurso: TipoRecursoEducativo.documento,
      remoteUrl: 'https://cdn.escuela.edu/ciencias/microscopia.docx',
      localPath: '/storage/emulated/0/Android/data/app/files/microscopia.docx',
      tamanoBytes: 3200000, // 3.2 MB
      checksumSha256: 'sha256_cien_01_hash_valido',
      esObligatorio: true,
      esFijado: false,
      fechaUsoClase: ahora.add(const Duration(days: 4)),
      ultimoAcceso: null,
      diasRetencion: 7,
      profesorNombre: 'Prof. Elena Ramos',
    );

    // 4. Video complementario de Física (Opcional, 120 MB - archivo pesado pendiente)
    final m4 = RecursoEducativoOffline(
      id: 'REC-FIS-01',
      claseId: 'CLASE-DEMO-001',
      materia: 'Física',
      titulo: 'Simulación Visual: Leyes de Newton',
      descripcion: 'Video explicativo en alta resolución de refuerzo voluntario.',
      tipoRecurso: TipoRecursoEducativo.video,
      remoteUrl: 'https://cdn.escuela.edu/fisica/leyes_newton.mp4',
      localPath: null, // Aún no descargado
      tamanoBytes: 125829120, // 120 MB
      checksumSha256: 'sha256_fis_01_hash_valido',
      esObligatorio: false, // Complementario
      esFijado: false,
      fechaUsoClase: ahora.add(const Duration(days: 5)),
      ultimoAcceso: null,
      diasRetencion: 7,
      profesorNombre: 'Docente Demo',
    );

    // 5. Material antiguo de hace 3 semanas (Ya visto, 85 MB, elegible para desalojo seguro)
    final m5 = RecursoEducativoOffline(
      id: 'REC-ANTIGUO-01',
      claseId: 'CLASE-DEMO-001',
      materia: 'Matemáticas',
      titulo: 'Unidad 1: Repaso Diagnóstico de Aritmética',
      descripcion: 'Fichas de trabajo del primer período lectivo.',
      tipoRecurso: TipoRecursoEducativo.pdf,
      remoteUrl: 'https://cdn.escuela.edu/matematica/repaso_unidad1.pdf',
      localPath: '/storage/emulated/0/Android/data/app/files/repaso_unidad1.pdf',
      tamanoBytes: 89128960, // ~85 MB
      checksumSha256: 'sha256_antiguo_01_hash_valido',
      esObligatorio: true,
      esFijado: false, // No fijado
      fechaUsoClase: ahora.subtract(const Duration(days: 22)),
      ultimoAcceso: ahora.subtract(const Duration(days: 20)),
      diasRetencion: 7,
      profesorNombre: 'Docente Demo',
    );

    _materiales[m1.id] = m1;
    _materiales[m2.id] = m2;
    _materiales[m3.id] = m3;
    _materiales[m4.id] = m4;
    _materiales[m5.id] = m5;
  }

  void _sincronizarTareasIniciales() {
    final ahora = DateTime.now();
    for (final m in _materiales.values) {
      if (m.estaDescargado) {
        _tareas[m.id] = TareaSincronizacion(
          recursoId: m.id,
          estado: EstadoSincronizacion.completado,
          bytesDescargados: m.tamanoBytes,
          totalBytes: m.tamanoBytes,
          fechaActualizacion: ahora,
        );
      } else {
        _tareas[m.id] = TareaSincronizacion(
          recursoId: m.id,
          estado: EstadoSincronizacion.pendiente,
          bytesDescargados: 0,
          totalBytes: m.tamanoBytes,
          fechaActualizacion: ahora,
        );
      }
    }
  }

  void _emitirMateriales() {
    if (!_materialesController.isClosed) {
      _materialesController.add(_materiales.values.toList());
    }
  }

  void _emitirTareas() {
    if (!_tareasController.isClosed) {
      _tareasController.add(Map.unmodifiable(_tareas));
    }
  }

  @override
  Future<List<RecursoEducativoOffline>> obtenerTodosMateriales() async {
    return _materiales.values.toList();
  }

  @override
  Future<List<RecursoEducativoOffline>> obtenerMaterialesPorClase(String claseId) async {
    return _materiales.values.where((m) => m.claseId == claseId).toList();
  }

  @override
  Future<List<RecursoEducativoOffline>> obtenerMaterialesSemana({DateTime? ahora}) async {
    return _materiales.values
        .where((m) => _calculadorSemana.estaEnSemana(m, ahora: ahora))
        .toList();
  }

  @override
  Future<RecursoEducativoOffline?> obtenerMaterialPorId(String id) async {
    return _materiales[id];
  }

  @override
  Future<void> guardarMaterial(RecursoEducativoOffline material) async {
    _materiales[material.id] = material;
    if (!_tareas.containsKey(material.id)) {
      _tareas[material.id] = TareaSincronizacion(
        recursoId: material.id,
        estado: material.estaDescargado
            ? EstadoSincronizacion.completado
            : EstadoSincronizacion.pendiente,
        bytesDescargados: material.estaDescargado ? material.tamanoBytes : 0,
        totalBytes: material.tamanoBytes,
        fechaActualizacion: DateTime.now(),
      );
      _emitirTareas();
    }
    _emitirMateriales();
  }

  @override
  Future<void> fijarMaterial(String materialId, bool fijado) async {
    final actual = _materiales[materialId];
    if (actual != null) {
      _materiales[materialId] = actual.copyWith(esFijado: fijado);
      _emitirMateriales();
    }
  }

  @override
  Future<void> registrarVisualizacion(String materialId) async {
    final actual = _materiales[materialId];
    if (actual != null) {
      _materiales[materialId] = actual.copyWith(ultimoAcceso: DateTime.now());
      _emitirMateriales();
    }
  }

  @override
  Future<void> actualizarTareaSincronizacion(TareaSincronizacion tarea) async {
    _tareas[tarea.recursoId] = tarea;

    // Si la tarea se completó, reflejar la ruta local en el recurso si faltaba
    if (tarea.estaCompletada) {
      final actual = _materiales[tarea.recursoId];
      if (actual != null && !actual.estaDescargado) {
        final nombreArchivo = actual.remoteUrl.split('/').last;
        _materiales[tarea.recursoId] = actual.copyWith(
          localPath: '/storage/emulated/0/Android/data/app/files/$nombreArchivo',
        );
        _emitirMateriales();
      }
    }

    _emitirTareas();
  }

  @override
  Future<TareaSincronizacion?> obtenerTarea(String recursoId) async {
    return _tareas[recursoId];
  }

  @override
  Future<void> eliminarArchivoLocal(String materialId) async {
    final actual = _materiales[materialId];
    if (actual != null) {
      _materiales[materialId] = actual.copyWith(localPath: null);
      final tareaActual = _tareas[materialId];
      if (tareaActual != null) {
        _tareas[materialId] = tareaActual.copyWith(
          estado: EstadoSincronizacion.pendiente,
          bytesDescargados: 0,
          causaPausa: CausaPausa.ninguna,
          fechaActualizacion: DateTime.now(),
        );
      }
      _emitirMateriales();
      _emitirTareas();
    }
  }

  @override
  Stream<List<RecursoEducativoOffline>> materialesStream() =>
      _materialesController.stream;

  @override
  Stream<Map<String, TareaSincronizacion>> tareasStream() =>
      _tareasController.stream;

  void dispose() {
    _materialesController.close();
    _tareasController.close();
  }
}
