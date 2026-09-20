import 'dart:math';
import '../modelos/recurso_educativo_offline.dart';

/// Desglose de puntuación de prioridad para auditoría y visualización.
class PuntajePrioridad {
  const PuntajePrioridad({
    required this.recursoId,
    required this.puntajeTotal,
    required this.pesoRequerido,
    required this.pesoTemporal,
    required this.penalizacionTamano,
    required this.horasHastaClase,
  });

  final String recursoId;
  final double puntajeTotal;
  final double pesoRequerido;
  final double pesoTemporal;
  final double penalizacionTamano;
  final double horasHastaClase;

  @override
  String toString() =>
      'PuntajePrioridad(id: $recursoId, P: ${puntajeTotal.toStringAsFixed(2)}, Wreq: $pesoRequerido, Wtime: $pesoTemporal, S_pen: ${penalizacionTamano.toStringAsFixed(2)})';
}

/// Motor encargado de calcular la prioridad pedagógica y técnica de descargas.
///
/// Implementa la función de scoring:
/// P = (W_req * W_time) / (S ^ alpha)
///
/// Diseñado para favorecer una cobertura amplia en conexiones inestables:
/// asegura guías de estudio y páginas de próximas clases antes de descargar
/// videos pesados de clases lejanas.
class MotorPrioridadSincronizacion {
  const MotorPrioridadSincronizacion({
    this.alpha = 0.5,
    this.pesoObligatorio = 3.0,
    this.pesoOpcional = 1.0,
  });

  /// Exponente de escala de tamaño. Un valor de 0.5 (raíz cuadrada) modera
  /// el impacto sin castigar injustamente archivos educativos legítimos.
  final double alpha;

  final double pesoObligatorio;
  final double pesoOpcional;

  /// Calcula el puntaje de prioridad de un recurso respecto a un momento de referencia [ahora].
  PuntajePrioridad calcularPuntaje(
    RecursoEducativoOffline recurso, {
    DateTime? ahora,
  }) {
    final referencia = ahora ?? DateTime.now();
    final diferenciaHoras =
        recurso.fechaUsoClase.difference(referencia).inMinutes / 60.0;

    // 1. Factor de Obligatoriedad (W_req)
    final wReq = recurso.esObligatorio ? pesoObligatorio : pesoOpcional;

    // 2. Factor de Urgencia Temporal (W_time)
    final double wTime;
    if (diferenciaHoras <= 24 && diferenciaHoras >= 0) {
      // Clase hoy o mañana: prioridad máxima
      wTime = 100.0;
    } else if (diferenciaHoras < 0) {
      // Clase ya pasada: baja urgencia pedagógica
      wTime = 5.0;
    } else if (diferenciaHoras <= 72) {
      // Próximos 3 días
      wTime = 50.0;
    } else if (diferenciaHoras <= 168) {
      // Próxima semana (4-7 días)
      wTime = 25.0;
    } else {
      // Clases futuras distantes
      wTime = 10.0;
    }

    // 3. Penalización por tamaño (S ^ alpha)
    // Se establece un tamaño mínimo de 0.5 MB para evitar divisiones anómalas
    final tamanoMB = max(0.5, recurso.tamanoMB);
    final penalizacionTamano = pow(tamanoMB, alpha).toDouble();

    // P = (W_req * W_time) / (S ^ alpha)
    final puntajeTotal = (wReq * wTime) / penalizacionTamano;

    return PuntajePrioridad(
      recursoId: recurso.id,
      puntajeTotal: puntajeTotal,
      pesoRequerido: wReq,
      pesoTemporal: wTime,
      penalizacionTamano: penalizacionTamano,
      horasHastaClase: diferenciaHoras,
    );
  }

  /// Ordena una lista de recursos pendientes en orden descendente de prioridad.
  List<RecursoEducativoOffline> ordenarCola(
    List<RecursoEducativoOffline> recursos, {
    DateTime? ahora,
  }) {
    final copia = List<RecursoEducativoOffline>.from(recursos);
    final mapaPuntajes = <String, double>{};

    for (final r in copia) {
      mapaPuntajes[r.id] = calcularPuntaje(r, ahora: ahora).puntajeTotal;
    }

    copia.sort((a, b) {
      final pA = mapaPuntajes[a.id] ?? 0.0;
      final pB = mapaPuntajes[b.id] ?? 0.0;
      return pB.compareTo(pA); // Mayor prioridad primero
    });

    return copia;
  }
}
