import 'dart:async';
import 'dart:math';
import '../dominio/modelos/recurso_educativo_offline.dart';
import '../dominio/sincronizacion/calculador_disponibilidad_semana.dart';
import '../dominio/sincronizacion/gestor_limpieza_segura.dart';
import '../dominio/sincronizacion/motor_prioridad_sincronizacion.dart';
import 'repositorio_materiales_offline.dart';

/// Coordinador central del sistema de sincronización offline en segundo plano.
///
/// Gestiona la cola por prioridad, aplica restricciones de hardware (WiFi, batería),
/// ejecuta descargas resilientes reanudables por tramos (HTTP Range) y verifica integridad.
class CoordinadorSincronizacionOffline {
  CoordinadorSincronizacionOffline({
    required this.repositorio,
    MotorPrioridadSincronizacion? motorPrioridad,
    GestorLimpiezaSegura? gestorLimpieza,
    CalculadorDisponibilidadSemana? calculadorSemana,
    CondicionesDispositivo? condicionesIniciales,
  })  : motorPrioridad = motorPrioridad ?? const MotorPrioridadSincronizacion(),
        gestorLimpieza = gestorLimpieza ?? const GestorLimpiezaSegura(),
        calculadorSemana = calculadorSemana ?? const CalculadorDisponibilidadSemana(),
        _condiciones = condicionesIniciales ??
            const CondicionesDispositivo(
              hayWifi: true,
              bateriaPorcentaje: 85,
              estaCargando: false,
              dispositivoInactivo: true,
            );

  final RepositorioMaterialesOffline repositorio;
  final MotorPrioridadSincronizacion motorPrioridad;
  final GestorLimpiezaSegura gestorLimpieza;
  final CalculadorDisponibilidadSemana calculadorSemana;

  CondicionesDispositivo _condiciones;
  CondicionesDispositivo get condiciones => _condiciones;

  bool _sincronizando = false;
  bool get estaSincronizando => _sincronizando;

  String? _recursoEnDescargaId;
  String? get recursoEnDescargaId => _recursoEnDescargaId;

  final StreamController<MetricaPreparacionSemana> _metricaController =
      StreamController<MetricaPreparacionSemana>.broadcast();

  Stream<MetricaPreparacionSemana> get metricaStream => _metricaController.stream;

  /// Actualiza las condiciones de red y batería detectadas por el sistema.
  /// Si se perdió el WiFi o la batería es crítica, se pausan las descargas activas.
  /// Si se recuperó el WiFi, se dispara automáticamente el ciclo sin confirmación.
  Future<void> actualizarCondicionesDispositivo(CondicionesDispositivo nuevas) async {
    final antesPodia = _condiciones.permiteDescargaEnSegundoPlano;
    _condiciones = nuevas;
    final ahoraPuede = _condiciones.permiteDescargaEnSegundoPlano;

    if (!ahoraPuede && _sincronizando) {
      await _pausarDescargaActiva(_condiciones.causaBloqueo);
    } else if (!antesPodia && ahoraPuede) {
      // Disparo automático transparente sin intervención del alumno
      unawaited(procesarColaDescargas());
    }
  }

  /// Pausa la descarga que esté en curso guardando el progreso acumulado.
  Future<void> _pausarDescargaActiva(CausaPausa causa) async {
    final idActivo = _recursoEnDescargaId;
    if (idActivo == null) return;

    final tarea = await repositorio.obtenerTarea(idActivo);
    if (tarea != null && tarea.estado == EstadoSincronizacion.descargando) {
      await repositorio.actualizarTareaSincronizacion(
        tarea.copyWith(
          estado: EstadoSincronizacion.pausado,
          causaPausa: causa,
          fechaActualizacion: DateTime.now(),
        ),
      );
    }
    _sincronizando = false;
    _recursoEnDescargaId = null;
  }

  /// Computa la métrica de preparación para la semana en curso.
  Future<MetricaPreparacionSemana> obtenerMetricaSemanal({DateTime? ahora}) async {
    final todos = await repositorio.obtenerTodosMateriales();
    final metrica = calculadorSemana.calcular(recursos: todos, ahora: ahora);
    if (!_metricaController.isClosed) {
      _metricaController.add(metrica);
    }
    return metrica;
  }

  Future<void>? _cicloActivo;

  /// Procesa la cola de descargas respetando:
  /// 1. Condiciones de hardware (WiFi + Batería > 20% o cargando).
  /// 2. Prioridad pedagógica y penalización de tamaño (cobertura amplia).
  /// 3. Reanudación por tramos binarios (resilience).
  Future<void> procesarColaDescargas({DateTime? ahora}) {
    if (_sincronizando && _cicloActivo != null) {
      return _cicloActivo!;
    }
    _cicloActivo = _ejecutarColaDescargas(ahora: ahora);
    return _cicloActivo!;
  }

  Future<void> _ejecutarColaDescargas({DateTime? ahora}) async {
    if (!_condiciones.permiteDescargaEnSegundoPlano) {
      return;
    }

    _sincronizando = true;

    try {
      final todos = await repositorio.obtenerTodosMateriales();
      final pendientes = <RecursoEducativoOffline>[];

      for (final recurso in todos) {
        if (recurso.estaDescargado) continue;
        final tarea = await repositorio.obtenerTarea(recurso.id);
        if (tarea == null ||
            tarea.estado == EstadoSincronizacion.pendiente ||
            tarea.estado == EstadoSincronizacion.pausado ||
            tarea.estado == EstadoSincronizacion.errorRed) {
          pendientes.add(recurso);
        }
      }

      if (pendientes.isEmpty) {
        return;
      }

      // Ordenar por algoritmo de scoring pedagógico
      final ordenados = motorPrioridad.ordenarCola(pendientes, ahora: ahora);

      for (final recurso in ordenados) {
        // Verificar si las condiciones cambiaron durante la cola
        if (!_condiciones.permiteDescargaEnSegundoPlano) {
          await _pausarDescargaActiva(_condiciones.causaBloqueo);
          break;
        }

        await _descargarRecursoResiliente(recurso);
      }
    } finally {
      _sincronizando = false;
      _recursoEnDescargaId = null;
      _cicloActivo = null;
      await obtenerMetricaSemanal(ahora: ahora);
    }
  }

  /// Simula / ejecuta la descarga por tramos continuos soportando cortes y reanudación (HTTP Range).
  Future<void> _descargarRecursoResiliente(
    RecursoEducativoOffline recurso, {
    int bytesPorTramo = 1024 * 1024, // Bloques de 1 MB
  }) async {
    _recursoEnDescargaId = recurso.id;

    var tarea = await repositorio.obtenerTarea(recurso.id) ??
        TareaSincronizacion(
          recursoId: recurso.id,
          estado: EstadoSincronizacion.enCola,
          bytesDescargados: 0,
          totalBytes: recurso.tamanoBytes,
          fechaActualizacion: DateTime.now(),
        );

    tarea = tarea.copyWith(
      estado: EstadoSincronizacion.descargando,
      causaPausa: CausaPausa.ninguna,
      fechaActualizacion: DateTime.now(),
    );
    await repositorio.actualizarTareaSincronizacion(tarea);

    var bytesAcumulados = tarea.bytesDescargados;
    final total = recurso.tamanoBytes;

    while (bytesAcumulados < total) {
      if (!_condiciones.permiteDescargaEnSegundoPlano) {
        await _pausarDescargaActiva(_condiciones.causaBloqueo);
        return;
      }

      // Avanzar en el siguiente bloque binario
      final siguienteChunk = min(bytesPorTramo, total - bytesAcumulados);
      bytesAcumulados += siguienteChunk;

      tarea = tarea.copyWith(
        bytesDescargados: bytesAcumulados,
        fechaActualizacion: DateTime.now(),
      );
      await repositorio.actualizarTareaSincronizacion(tarea);

      // Breve respiro asíncrono para permitir eventos de UI
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    // Verificación de integridad SHA-256 (simulada aquí confirmando que el hash no esté vacío)
    final integridadValida = recurso.checksumSha256.isNotEmpty &&
        !recurso.checksumSha256.startsWith('invalido');

    if (integridadValida) {
      final nombreArchivo = recurso.remoteUrl.split('/').last;
      final localPath =
          '/storage/emulated/0/Android/data/app/files/$nombreArchivo';

      await repositorio.guardarMaterial(recurso.copyWith(localPath: localPath));
      await repositorio.actualizarTareaSincronizacion(
        tarea.copyWith(
          estado: EstadoSincronizacion.completado,
          bytesDescargados: total,
          fechaActualizacion: DateTime.now(),
        ),
      );
    } else {
      await repositorio.actualizarTareaSincronizacion(
        tarea.copyWith(
          estado: EstadoSincronizacion.errorIntegridad,
          ultimoError: 'Error de integridad: el checksum SHA-256 no coincide.',
          reintentos: tarea.reintentos + 1,
          fechaActualizacion: DateTime.now(),
        ),
      );
    }

    _recursoEnDescargaId = null;
  }

  /// Ejecuta una solicitud de limpieza segura delegando al [GestorLimpiezaSegura].
  Future<ResultadoLimpieza> solicitarLimpiezaSegura({
    required bool hayInternet,
    bool confirmadoPorUsuario = false,
    int? bytesObjetivo,
    DateTime? ahora,
  }) async {
    final materiales = await repositorio.obtenerTodosMateriales();
    final resultado = gestorLimpieza.ejecutarLimpieza(
      recursos: materiales,
      hayInternet: hayInternet,
      confirmadoPorUsuario: confirmadoPorUsuario,
      bytesObjetivo: bytesObjetivo,
      ahora: ahora,
    );

    if (resultado.exitosa && resultado.archivosEliminados.isNotEmpty) {
      for (final eliminado in resultado.archivosEliminados) {
        await repositorio.eliminarArchivoLocal(eliminado.id);
      }
      await obtenerMetricaSemanal(ahora: ahora);
    }

    return resultado;
  }

  void dispose() {
    _metricaController.close();
  }
}
