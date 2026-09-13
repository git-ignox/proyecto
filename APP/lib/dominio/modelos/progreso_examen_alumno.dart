import 'error_aprendizaje.dart';
import 'examen_diagnostico.dart';

/// Estados posibles del examen diagnóstico para un alumno.
enum EstadoExamenAlumno {
  noIniciado,
  enProgreso,
  completado,
  aprobadoParaAvanzar,
  requiereRefuerzo;

  String get etiqueta {
    switch (this) {
      case EstadoExamenAlumno.noIniciado:
        return 'No Iniciado ⚪';
      case EstadoExamenAlumno.enProgreso:
        return 'En Progreso 🔵';
      case EstadoExamenAlumno.completado:
        return 'Completado 🟣';
      case EstadoExamenAlumno.aprobadoParaAvanzar:
        return 'Aprobado para Avanzar 🟢';
      case EstadoExamenAlumno.requiereRefuerzo:
        return 'Requiere Refuerzo 🟡';
    }
  }
}

/// Registro del progreso y calificación de un estudiante en un examen diagnóstico específico.
class ProgresoExamenAlumno {
  const ProgresoExamenAlumno({
    required this.id,
    required this.examenId,
    required this.alumnoUid,
    this.alumnoNombre = 'Alumno',
    this.respuestasPorEjercicio = const {},
    this.aciertos = 0,
    this.totalEjercicios = 0,
    this.puntajeTotal = 0.0,
    this.errores = const [],
    this.resultadoAvance,
    this.estado = EstadoExamenAlumno.noIniciado,
    this.autorizadoPorDocente = false,
    required this.fechaInicio,
    this.fechaFinalizacion,
  });

  final String id;
  final String examenId;
  final String alumnoUid;
  final String alumnoNombre;

  /// Mapa de respuestas dadas por el alumno por ID de ejercicio.
  final Map<String, dynamic> respuestasPorEjercicio;

  /// Número de ejercicios resueltos correctamente.
  final int aciertos;

  /// Número total de ejercicios en el examen.
  final int totalEjercicios;

  /// Puntaje acumulado en puntos.
  final double puntajeTotal;

  /// Lista de errores pedagógicos identificados.
  final List<ErrorAprendizaje> errores;

  /// Evaluación del avance de acuerdo a la variable fijada por el docente.
  final ResultadoAvance? resultadoAvance;

  /// Estado actual del examen.
  final EstadoExamenAlumno estado;

  /// Si el profesor autorizó el avance manualmente (para criterio de aprobación docente).
  final bool autorizadoPorDocente;

  /// Fecha en la que inició el examen.
  final DateTime fechaInicio;

  /// Fecha en la que entregó o finalizó el examen.
  final DateTime? fechaFinalizacion;

  /// Porcentaje de completitud del examen (0.0 a 100.0).
  double get porcentajeAvance {
    if (totalEjercicios == 0) return 0.0;
    return (respuestasPorEjercicio.length / totalEjercicios) * 100.0;
  }

  /// Porcentaje de aciertos (0.0 a 100.0).
  double get porcentajePrecision {
    if (totalEjercicios == 0) return 0.0;
    return (aciertos / totalEjercicios) * 100.0;
  }

  /// Indica si el alumno cumple con la variable de avance del docente.
  bool get puedeAvanzar => resultadoAvance?.puedeAvanzar ?? autorizadoPorDocente;

  /// Serialización a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'examenId': examenId,
      'alumnoUid': alumnoUid,
      'alumnoNombre': alumnoNombre,
      'respuestasPorEjercicio': respuestasPorEjercicio,
      'aciertos': aciertos,
      'totalEjercicios': totalEjercicios,
      'puntajeTotal': puntajeTotal,
      'errores': errores.map((e) => e.toMap()).toList(),
      'estado': estado.name,
      'autorizadoPorDocente': autorizadoPorDocente,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFinalizacion': fechaFinalizacion?.toIso8601String(),
    };
  }

  /// Deserialización desde Map
  factory ProgresoExamenAlumno.fromMap(Map<String, dynamic> map) {
    return ProgresoExamenAlumno(
      id: map['id'] as String? ?? '',
      examenId: map['examenId'] as String? ?? '',
      alumnoUid: map['alumnoUid'] as String? ?? '',
      alumnoNombre: map['alumnoNombre'] as String? ?? 'Alumno',
      respuestasPorEjercicio: Map<String, dynamic>.from(map['respuestasPorEjercicio'] as Map? ?? {}),
      aciertos: map['aciertos'] as int? ?? 0,
      totalEjercicios: map['totalEjercicios'] as int? ?? 0,
      puntajeTotal: (map['puntajeTotal'] as num?)?.toDouble() ?? 0.0,
      errores: (map['errores'] as List?)
              ?.map((e) => ErrorAprendizaje.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      estado: EstadoExamenAlumno.values.firstWhere(
        (e) => e.name == map['estado'],
        orElse: () => EstadoExamenAlumno.noIniciado,
      ),
      autorizadoPorDocente: map['autorizadoPorDocente'] as bool? ?? false,
      fechaInicio: map['fechaInicio'] != null
          ? DateTime.tryParse(map['fechaInicio'] as String) ?? DateTime.now()
          : DateTime.now(),
      fechaFinalizacion: map['fechaFinalizacion'] != null
          ? DateTime.tryParse(map['fechaFinalizacion'] as String)
          : null,
    );
  }
}
