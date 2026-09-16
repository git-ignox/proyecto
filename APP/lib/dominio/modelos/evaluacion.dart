import 'package:flutter/material.dart';

/// Tipos de evaluación soportados en el sistema educativo.
enum TipoEvaluacion {
  examen,
  tarea,
  quiz,
  proyecto;

  String get etiqueta {
    switch (this) {
      case TipoEvaluacion.examen:
        return 'Examen';
      case TipoEvaluacion.tarea:
        return 'Tarea';
      case TipoEvaluacion.quiz:
        return 'Quiz';
      case TipoEvaluacion.proyecto:
        return 'Proyecto';
    }
  }

  IconData get icono {
    switch (this) {
      case TipoEvaluacion.examen:
        return Icons.assignment_outlined;
      case TipoEvaluacion.tarea:
        return Icons.menu_book_outlined;
      case TipoEvaluacion.quiz:
        return Icons.quiz_outlined;
      case TipoEvaluacion.proyecto:
        return Icons.science_outlined;
    }
  }

  Color get color {
    switch (this) {
      case TipoEvaluacion.examen:
        return Colors.indigo;
      case TipoEvaluacion.tarea:
        return Colors.teal;
      case TipoEvaluacion.quiz:
        return Colors.orange.shade800;
      case TipoEvaluacion.proyecto:
        return Colors.purple;
    }
  }
}

/// Representa una evaluación planificada o realizada en una clase.
class Evaluacion {
  const Evaluacion({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.fecha,
    required this.claseId,
    required this.temas,
    this.objetivoIds = const [],
    this.notaMaxima = 7.0,
    this.notaAprobatoria = 4.0,
    this.descripcion = '',
    required this.fechaCreacion,
  });

  final String id;
  final String nombre;
  final TipoEvaluacion tipo;
  final DateTime fecha;
  final String claseId;

  /// Temas o estándares curriculares evaluados (clave para el triage de brechas).
  final List<String> temas;

  /// IDs estables de objetivos de aprendizaje asociados desde el currículo formal.
  final List<String> objetivoIds;

  /// Nota máxima posible (ej. 7.0 o 10.0).
  final double notaMaxima;

  /// Nota mínima para aprobar.
  final double notaAprobatoria;

  final String descripcion;
  final DateTime fechaCreacion;

  Evaluacion copyWith({
    String? id,
    String? nombre,
    TipoEvaluacion? tipo,
    DateTime? fecha,
    String? claseId,
    List<String>? temas,
    List<String>? objetivoIds,
    double? notaMaxima,
    double? notaAprobatoria,
    String? descripcion,
    DateTime? fechaCreacion,
  }) {
    return Evaluacion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      fecha: fecha ?? this.fecha,
      claseId: claseId ?? this.claseId,
      temas: temas ?? this.temas,
      objetivoIds: objetivoIds ?? this.objetivoIds,
      notaMaxima: notaMaxima ?? this.notaMaxima,
      notaAprobatoria: notaAprobatoria ?? this.notaAprobatoria,
      descripcion: descripcion ?? this.descripcion,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'tipo': tipo.name,
      'fecha': fecha.toIso8601String(),
      'claseId': claseId,
      'temas': temas,
      'objetivoIds': objetivoIds,
      'notaMaxima': notaMaxima,
      'notaAprobatoria': notaAprobatoria,
      'descripcion': descripcion,
      'fechaCreacion': fechaCreacion.toIso8601String(),
    };
  }

  factory Evaluacion.fromMap(Map<String, dynamic> map, [String? idFallback]) {
    final tipoStr = map['tipo'] as String? ?? 'examen';
    final tipo = TipoEvaluacion.values.firstWhere(
      (t) => t.name == tipoStr,
      orElse: () => TipoEvaluacion.examen,
    );

    return Evaluacion(
      id: map['id'] as String? ?? idFallback ?? '',
      nombre: map['nombre'] as String? ?? '',
      tipo: tipo,
      fecha: map['fecha'] != null
          ? DateTime.tryParse(map['fecha'] as String) ?? DateTime.now()
          : DateTime.now(),
      claseId: map['claseId'] as String? ?? '',
      temas: (map['temas'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      objetivoIds: (map['objetivoIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      notaMaxima: (map['notaMaxima'] as num?)?.toDouble() ?? 7.0,
      notaAprobatoria: (map['notaAprobatoria'] as num?)?.toDouble() ?? 4.0,
      descripcion: map['descripcion'] as String? ?? '',
      fechaCreacion: map['fechaCreacion'] != null
          ? DateTime.tryParse(map['fechaCreacion'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Registro individual de calificación de un estudiante en una evaluación.
class NotaEvaluacion {
  const NotaEvaluacion({
    required this.id,
    required this.evaluacionId,
    required this.claseId,
    required this.alumnoUid,
    required this.alumnoNombre,
    required this.nota,
    this.notaMaxima = 7.0,
    required this.fechaRegistro,
    this.notasPorTema = const {},
    this.observaciones,
  });

  final String id;
  final String evaluacionId;
  final String claseId;
  final String alumnoUid;
  final String alumnoNombre;

  /// Calificación numérica global obtenida.
  final double nota;

  /// Calificación máxima posible de la prueba.
  final double notaMaxima;

  final DateTime fechaRegistro;

  /// Desglose opcional por tema si la evaluación desglosa notas por ítem/estándar.
  /// Mapa de: { 'Álgebra': 6.5, 'Geometría': 3.2 }
  final Map<String, double> notasPorTema;

  final String? observaciones;

  /// Porcentaje de logro obtenido (entre 0.0 y 100.0).
  double get porcentajeLogro {
    if (notaMaxima <= 0) return 0.0;
    final pct = (nota / notaMaxima) * 100.0;
    return pct.clamp(0.0, 100.0);
  }

  bool estaAprobado(double notaAprobatoria) => nota >= notaAprobatoria;

  NotaEvaluacion copyWith({
    String? id,
    String? evaluacionId,
    String? claseId,
    String? alumnoUid,
    String? alumnoNombre,
    double? nota,
    double? notaMaxima,
    DateTime? fechaRegistro,
    Map<String, double>? notasPorTema,
    String? observaciones,
  }) {
    return NotaEvaluacion(
      id: id ?? this.id,
      evaluacionId: evaluacionId ?? this.evaluacionId,
      claseId: claseId ?? this.claseId,
      alumnoUid: alumnoUid ?? this.alumnoUid,
      alumnoNombre: alumnoNombre ?? this.alumnoNombre,
      nota: nota ?? this.nota,
      notaMaxima: notaMaxima ?? this.notaMaxima,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      notasPorTema: notasPorTema ?? this.notasPorTema,
      observaciones: observaciones ?? this.observaciones,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'evaluacionId': evaluacionId,
      'claseId': claseId,
      'alumnoUid': alumnoUid,
      'alumnoNombre': alumnoNombre,
      'nota': nota,
      'notaMaxima': notaMaxima,
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'notasPorTema': notasPorTema,
      'observaciones': observaciones,
    };
  }

  factory NotaEvaluacion.fromMap(Map<String, dynamic> map, [String? idFallback]) {
    final notasTemaRaw = map['notasPorTema'] as Map<String, dynamic>? ?? {};
    final notasTemaParsed = notasTemaRaw.map((k, v) => MapEntry(k, (v as num).toDouble()));

    return NotaEvaluacion(
      id: map['id'] as String? ?? idFallback ?? '',
      evaluacionId: map['evaluacionId'] as String? ?? '',
      claseId: map['claseId'] as String? ?? '',
      alumnoUid: map['alumnoUid'] as String? ?? '',
      alumnoNombre: map['alumnoNombre'] as String? ?? 'Alumno',
      nota: (map['nota'] as num?)?.toDouble() ?? 0.0,
      notaMaxima: (map['notaMaxima'] as num?)?.toDouble() ?? 7.0,
      fechaRegistro: map['fechaRegistro'] != null
          ? DateTime.tryParse(map['fechaRegistro'] as String) ?? DateTime.now()
          : DateTime.now(),
      notasPorTema: notasTemaParsed,
      observaciones: map['observaciones'] as String?,
    );
  }
}
