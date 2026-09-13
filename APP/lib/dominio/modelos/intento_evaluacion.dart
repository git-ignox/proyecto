import 'error_aprendizaje.dart';
import 'tipo_ejercicio.dart';

/// Representa el registro inmutable de un intento de resolución de un ejercicio por un alumno.
class IntentoEvaluacion {
  const IntentoEvaluacion({
    required this.id,
    required this.usuarioUid,
    required this.ejercicioId,
    required this.codigoTema,
    this.tags = const [],
    required this.tipo,
    required this.esCorrecto,
    required this.puntaje,
    this.error,
    this.respuestaDada,
    required this.fecha,
  });

  /// Identificador único del intento.
  final String id;

  /// UID del alumno que realizó el intento.
  final String usuarioUid;

  /// Identificador del ejercicio evaluado.
  final String ejercicioId;

  /// Posición o código de tema curricular (ej. "1.1.1").
  final String codigoTema;

  /// Etiquetas conceptuales asociadas al ejercicio al momento de resolverlo.
  final List<String> tags;

  /// Tipo de ejercicio resuelto.
  final TipoEjercicio tipo;

  /// Indica si el intento fue aprobado con éxito.
  final bool esCorrecto;

  /// Calificación proporcional obtenida (0.0 a 1.0).
  final double puntaje;

  /// Error de aprendizaje identificado si el intento fue incorrecto.
  final ErrorAprendizaje? error;

  /// Respuesta literal ingresada por el estudiante.
  final dynamic respuestaDada;

  /// Fecha y hora exacta del intento.
  final DateTime fecha;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuarioUid': usuarioUid,
      'ejercicioId': ejercicioId,
      'codigoTema': codigoTema,
      'tags': tags,
      'tipo': tipo.name,
      'esCorrecto': esCorrecto,
      'puntaje': puntaje,
      'error': error?.toMap(),
      'respuestaDada': respuestaDada?.toString(),
      'fecha': fecha.toIso8601String(),
    };
  }

  factory IntentoEvaluacion.fromMap(Map<String, dynamic> map) {
    return IntentoEvaluacion(
      id: map['id'] as String? ?? 'INT-${DateTime.now().millisecondsSinceEpoch}',
      usuarioUid: map['usuarioUid'] as String? ?? '',
      ejercicioId: map['ejercicioId'] as String? ?? '',
      codigoTema: map['codigoTema'] as String? ?? '1.1.1',
      tags: (map['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      tipo: TipoEjercicio.values.firstWhere(
        (t) => t.name == map['tipo'],
        orElse: () => TipoEjercicio.aritmetico,
      ),
      esCorrecto: map['esCorrecto'] as bool? ?? false,
      puntaje: (map['puntaje'] as num?)?.toDouble() ?? 0.0,
      error: map['error'] != null
          ? ErrorAprendizaje.fromMap(Map<String, dynamic>.from(map['error'] as Map))
          : null,
      respuestaDada: map['respuestaDada'],
      fecha: map['fecha'] != null
          ? DateTime.tryParse(map['fecha'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
