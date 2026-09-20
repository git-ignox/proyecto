import 'dart:math';
import '../modelos/recurso_educativo_offline.dart';

/// Excepción lanzada si se intenta forzar una limpieza sin conexión a internet.
class LimpiezaSinInternetException implements Exception {
  final String mensaje;
  const LimpiezaSinInternetException([
    this.mensaje = 'La limpieza de almacenamiento solo puede ejecutarse cuando hay conexión a internet.',
  ]);

  @override
  String toString() => 'LimpiezaSinInternetException: $mensaje';
}

/// Análisis previo de los archivos que calificarían para ser eliminados.
class AnalisisLimpiezaPrevia {
  const AnalisisLimpiezaPrevia({
    required this.candidatos,
    required this.bytesALiberar,
    required this.esLiberacionSignificativa,
    required this.mensajeAlerta,
    required this.hayInternet,
  });

  final List<RecursoEducativoOffline> candidatos;
  final int bytesALiberar;
  final bool esLiberacionSignificativa;
  final String mensajeAlerta;
  final bool hayInternet;

  double get mbALiberar => bytesALiberar / (1024 * 1024);

  String get mbALiberarLegible =>
      '${(bytesALiberar / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Resultado final de la ejecución de una política de limpieza segura.
class ResultadoLimpieza {
  const ResultadoLimpieza({
    required this.exitosa,
    required this.abortadaPorSinInternet,
    required this.requiereConfirmacionPrevia,
    required this.bytesLiberados,
    required this.archivosEliminados,
    required this.mensaje,
  });

  final bool exitosa;
  final bool abortadaPorSinInternet;
  final bool requiereConfirmacionPrevia;
  final int bytesLiberados;
  final List<RecursoEducativoOffline> archivosEliminados;
  final String mensaje;

  factory ResultadoLimpieza.sinInternet() {
    return const ResultadoLimpieza(
      exitosa: false,
      abortadaPorSinInternet: true,
      requiereConfirmacionPrevia: false,
      bytesLiberados: 0,
      archivosEliminados: [],
      mensaje:
          'Limpieza abortada por seguridad: no hay conexión a internet para reponer material si fuese necesario.',
    );
  }

  factory ResultadoLimpieza.requiereConfirmacion({
    required int bytesEstimados,
    required List<RecursoEducativoOffline> candidatos,
    required String mensaje,
  }) {
    return ResultadoLimpieza(
      exitosa: false,
      abortadaPorSinInternet: false,
      requiereConfirmacionPrevia: true,
      bytesLiberados: 0,
      archivosEliminados: candidatos,
      mensaje: mensaje,
    );
  }
}

/// Gestor de retención y limpieza que implementa las 5 Reglas Inviolables:
/// 1. SOLO ejecuta con internet (nunca offline).
/// 2. NUNCA elimina contenido de las próximas 24-48 horas ni clases futuras activas.
/// 3. NUNCA elimina archivos marcados como fijados/intocables (isPinned).
/// 4. Prioriza borrar lo más antiguo y ya visto mediante un algoritmo de scoring.
/// 5. Notifica y requiere confirmación antes de liberar espacio de forma significativa.
class GestorLimpiezaSegura {
  const GestorLimpiezaSegura({
    this.horasVentanaSagrada = 48,
    this.umbralLiberacionSignificativaBytes = 100 * 1024 * 1024, // 100 MB
  });

  /// Ventana de tiempo futura protegida (por defecto 48 horas).
  final int horasVentanaSagrada;

  /// Umbral a partir del cual se considera una liberación masiva que requiere confirmación.
  final int umbralLiberacionSignificativaBytes;

  /// Calcula el puntaje de desalojo (E) para un recurso.
  /// A mayor puntaje E, más idóneo es el recurso para ser desalojado.
  double calcularPuntajeDesalojo(
    RecursoEducativoOffline recurso, {
    required DateTime ahora,
  }) {
    // Si la clase aún no ha ocurrido, no debe tener puntaje positivo de desalojo
    if (recurso.fechaUsoClase.isAfter(ahora)) {
      return -1.0;
    }

    final diasDesdeUso =
        max(0.0, ahora.difference(recurso.fechaUsoClase).inHours / 24.0);

    // Días transcurridos después de la expiración de la retención pedagógica
    final diasPostRetencion = max(0.0, diasDesdeUso - recurso.diasRetencion);

    // Bono de desalojo si el alumno ya abrió el archivo
    final bonoYaVisto = recurso.yaVisto ? 10.0 : 0.0;

    // Pequeño factor por tamaño para favorecer recuperar bloques grandes
    final factorTamano = recurso.tamanoMB * 0.05;

    // E = DíasPostRetención * 2.0 + (YaVisto ? 10 : 0) + TamañoMB * 0.05
    return (diasPostRetencion * 2.0) + bonoYaVisto + factorTamano;
  }

  /// Evalúa los recursos y determina cuáles son candidatos legales para ser purgados.
  AnalisisLimpiezaPrevia evaluarCandidatos({
    required List<RecursoEducativoOffline> recursos,
    required bool hayInternet,
    DateTime? ahora,
  }) {
    final momento = ahora ?? DateTime.now();
    final limiteVentanaSagrada =
        momento.add(Duration(hours: horasVentanaSagrada));

    if (!hayInternet) {
      return AnalisisLimpiezaPrevia(
        candidatos: const [],
        bytesALiberar: 0,
        esLiberacionSignificativa: false,
        mensajeAlerta:
            'Limpieza deshabilitada: el dispositivo no cuenta con internet.',
        hayInternet: false,
      );
    }

    final candidatos = <RecursoEducativoOffline>[];
    int totalBytes = 0;

    for (final recurso in recursos) {
      // 1. Debe estar descargado localmente
      if (!recurso.estaDescargado) continue;

      // 2. Regla inviolable: si está fijado por el alumno, NUNCA se toca
      if (recurso.esFijado) continue;

      // 3. Regla inviolable: si la clase es en las próximas 24-48h o posterior, blindado
      if (recurso.fechaUsoClase.isBefore(limiteVentanaSagrada) &&
          recurso.fechaUsoClase.isAfter(momento.subtract(const Duration(hours: 1)))) {
        continue;
      }

      // 4. Si la clase aún no ocurre en el futuro, no se borra
      if (recurso.fechaUsoClase.isAfter(momento)) {
        continue;
      }

      // 5. Verificar si ha superado su período de retención garantizada
      final diasDesdeClase =
          momento.difference(recurso.fechaUsoClase).inDays;
      if (diasDesdeClase >= recurso.diasRetencion) {
        candidatos.add(recurso);
        totalBytes += recurso.tamanoBytes;
      }
    }

    // Ordenar candidatos por puntaje de desalojo E descendente (antiguo y ya visto primero)
    candidatos.sort((a, b) {
      final pA = calcularPuntajeDesalojo(a, ahora: momento);
      final pB = calcularPuntajeDesalojo(b, ahora: momento);
      return pB.compareTo(pA);
    });

    final esSignificativa = totalBytes >= umbralLiberacionSignificativaBytes;
    final mbTexto = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
    final mensajeAlerta = esSignificativa
        ? 'Aviso de almacenamiento: se detectaron $mbTexto MB de clases pasadas ya vistas que pueden liberarse sin afectar tus próximas jornadas.'
        : 'Se liberarán $mbTexto MB de material archivado.';

    return AnalisisLimpiezaPrevia(
      candidatos: candidatos,
      bytesALiberar: totalBytes,
      esLiberacionSignificativa: esSignificativa,
      mensajeAlerta: mensajeAlerta,
      hayInternet: true,
    );
  }

  /// Ejecuta la limpieza segura según las reglas.
  /// Si la liberación supera el umbral significativo y [confirmadoPorUsuario] es falso,
  /// se rechaza la purga física y se devuelve un resultado que solicita confirmación.
  ResultadoLimpieza ejecutarLimpieza({
    required List<RecursoEducativoOffline> recursos,
    required bool hayInternet,
    required bool confirmadoPorUsuario,
    int? bytesObjetivo,
    DateTime? ahora,
  }) {
    // REGLA 1: Solo con internet
    if (!hayInternet) {
      return ResultadoLimpieza.sinInternet();
    }

    final analisis = evaluarCandidatos(
      recursos: recursos,
      hayInternet: hayInternet,
      ahora: ahora,
    );

    if (analisis.candidatos.isEmpty) {
      return const ResultadoLimpieza(
        exitosa: true,
        abortadaPorSinInternet: false,
        requiereConfirmacionPrevia: false,
        bytesLiberados: 0,
        archivosEliminados: [],
        mensaje: 'No hay archivos antiguos elegibles para desalojo.',
      );
    }

    // REGLA 5: Avisar antes de liberar de forma significativa
    if (analisis.esLiberacionSignificativa && !confirmadoPorUsuario) {
      return ResultadoLimpieza.requiereConfirmacion(
        bytesEstimados: analisis.bytesALiberar,
        candidatos: analisis.candidatos,
        mensaje: analisis.mensajeAlerta,
      );
    }

    // Proceso de selección de archivos a eliminar hasta alcanzar el objetivo
    final seleccionados = <RecursoEducativoOffline>[];
    int acumulado = 0;

    for (final candidato in analisis.candidatos) {
      seleccionados.add(candidato);
      acumulado += candidato.tamanoBytes;
      if (bytesObjetivo != null && acumulado >= bytesObjetivo) {
        break;
      }
    }

    return ResultadoLimpieza(
      exitosa: true,
      abortadaPorSinInternet: false,
      requiereConfirmacionPrevia: false,
      bytesLiberados: acumulado,
      archivosEliminados: seleccionados,
      mensaje:
          'Se liberaron ${(acumulado / (1024 * 1024)).toStringAsFixed(1)} MB eliminando ${seleccionados.length} archivos antiguos.',
    );
  }
}
