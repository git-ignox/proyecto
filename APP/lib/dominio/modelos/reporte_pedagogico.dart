import 'package:flutter/material.dart';
import 'analisis_brechas.dart';

/// Tendencia de evolución pedagógica de un tema comparando con un período anterior.
enum TendenciaInterPeriodo {
  mejora,
  estable,
  regresion,
  primeraMedicion;

  String get etiqueta {
    switch (this) {
      case TendenciaInterPeriodo.mejora:
        return 'Mejora 📈';
      case TendenciaInterPeriodo.estable:
        return 'Estable ➖';
      case TendenciaInterPeriodo.regresion:
        return 'Descendió 📉';
      case TendenciaInterPeriodo.primeraMedicion:
        return 'Primer registro 📌';
    }
  }

  Color get color {
    switch (this) {
      case TendenciaInterPeriodo.mejora:
        return Colors.green.shade700;
      case TendenciaInterPeriodo.estable:
        return Colors.blue.shade700;
      case TendenciaInterPeriodo.regresion:
        return Colors.red.shade700;
      case TendenciaInterPeriodo.primeraMedicion:
        return Colors.grey.shade700;
    }
  }

  static TendenciaInterPeriodo fromString(String valor) {
    switch (valor) {
      case 'mejora':
        return TendenciaInterPeriodo.mejora;
      case 'estable':
        return TendenciaInterPeriodo.estable;
      case 'regresion':
        return TendenciaInterPeriodo.regresion;
      default:
        return TendenciaInterPeriodo.primeraMedicion;
    }
  }
}

/// Snapshot congelado del dominio de un tema en el momento de generar el reporte.
class SnapshotTemaReporte {
  const SnapshotTemaReporte({
    required this.tema,
    required this.porcentajeDominio,
    required this.promedioNota,
    required this.cantidadEvaluaciones,
    required this.nivelDominio,
    this.porcentajePeriodoAnterior,
    this.tendenciaInterPeriodo = TendenciaInterPeriodo.primeraMedicion,
  });

  final String tema;
  final double porcentajeDominio; // 0.0 a 100.0
  final double promedioNota;
  final int cantidadEvaluaciones;
  final NivelDominio nivelDominio;
  final double? porcentajePeriodoAnterior;
  final TendenciaInterPeriodo tendenciaInterPeriodo;

  bool get esBrechaCritica => nivelDominio == NivelDominio.critico || porcentajeDominio < 60.0;

  Map<String, dynamic> toMap() {
    return {
      'tema': tema,
      'porcentajeDominio': porcentajeDominio,
      'promedioNota': promedioNota,
      'cantidadEvaluaciones': cantidadEvaluaciones,
      'nivelDominio': nivelDominio.name,
      'porcentajePeriodoAnterior': porcentajePeriodoAnterior,
      'tendenciaInterPeriodo': tendenciaInterPeriodo.name,
    };
  }

  factory SnapshotTemaReporte.fromMap(Map<String, dynamic> map) {
    final nivelStr = map['nivelDominio'] as String? ?? 'critico';
    final nivel = NivelDominio.values.firstWhere(
      (n) => n.name == nivelStr,
      orElse: () => NivelDominio.critico,
    );

    return SnapshotTemaReporte(
      tema: map['tema'] as String? ?? '',
      porcentajeDominio: (map['porcentajeDominio'] as num?)?.toDouble() ?? 0.0,
      promedioNota: (map['promedioNota'] as num?)?.toDouble() ?? 0.0,
      cantidadEvaluaciones: (map['cantidadEvaluaciones'] as num?)?.toInt() ?? 0,
      nivelDominio: nivel,
      porcentajePeriodoAnterior: (map['porcentajePeriodoAnterior'] as num?)?.toDouble(),
      tendenciaInterPeriodo: TendenciaInterPeriodo.fromString(
        map['tendenciaInterPeriodo'] as String? ?? 'primeraMedicion',
      ),
    );
  }

  SnapshotTemaReporte copyWith({
    String? tema,
    double? porcentajeDominio,
    double? promedioNota,
    int? cantidadEvaluaciones,
    NivelDominio? nivelDominio,
    double? porcentajePeriodoAnterior,
    TendenciaInterPeriodo? tendenciaInterPeriodo,
  }) {
    return SnapshotTemaReporte(
      tema: tema ?? this.tema,
      porcentajeDominio: porcentajeDominio ?? this.porcentajeDominio,
      promedioNota: promedioNota ?? this.promedioNota,
      cantidadEvaluaciones: cantidadEvaluaciones ?? this.cantidadEvaluaciones,
      nivelDominio: nivelDominio ?? this.nivelDominio,
      porcentajePeriodoAnterior: porcentajePeriodoAnterior ?? this.porcentajePeriodoAnterior,
      tendenciaInterPeriodo: tendenciaInterPeriodo ?? this.tendenciaInterPeriodo,
    );
  }
}

/// Reporte pedagógico oficial congelado para un estudiante en un período específico.
class ReporteEstudiante {
  const ReporteEstudiante({
    required this.id,
    required this.claseId,
    required this.periodo,
    required this.alumnoUid,
    required this.alumnoNombre,
    required this.fechaGeneracion,
    required this.promedioGeneral,
    required this.porcentajeGeneral,
    required this.temasPriorizados,
    required this.totalTemasEnRiesgo,
    this.comentarioDocente = '',
  });

  final String id;
  final String claseId;
  final String periodo; // Ej: "1° Trimestre", "2° Trimestre"
  final String alumnoUid;
  final String alumnoNombre;
  final DateTime fechaGeneracion;
  final double promedioGeneral;
  final double porcentajeGeneral;

  /// Temas ordenados con criterio pedagógico: primero brechas críticas (<60%) en orden ascendente
  final List<SnapshotTemaReporte> temasPriorizados;

  /// Conteo de temas bajo 60%
  final int totalTemasEnRiesgo;

  /// Comentario cualitativo del docente
  final String comentarioDocente;

  /// Determina si el alumno está en riesgo crítico general (2 o más temas en riesgo)
  bool get enRiesgoMultitematico => totalTemasEnRiesgo >= 2;

  /// Tema de menor rendimiento en el período
  SnapshotTemaReporte? get brechaPrincipal =>
      temasPriorizados.isNotEmpty ? temasPriorizados.first : null;

  /// Tema de mayor rendimiento en el período
  SnapshotTemaReporte? get fortalezaPrincipal {
    if (temasPriorizados.isEmpty) return null;
    return temasPriorizados.reduce(
      (a, b) => a.porcentajeDominio >= b.porcentajeDominio ? a : b,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'claseId': claseId,
      'periodo': periodo,
      'alumnoUid': alumnoUid,
      'alumnoNombre': alumnoNombre,
      'fechaGeneracion': fechaGeneracion.toIso8601String(),
      'promedioGeneral': promedioGeneral,
      'porcentajeGeneral': porcentajeGeneral,
      'temasPriorizados': temasPriorizados.map((t) => t.toMap()).toList(),
      'totalTemasEnRiesgo': totalTemasEnRiesgo,
      'comentarioDocente': comentarioDocente,
    };
  }

  factory ReporteEstudiante.fromMap(Map<String, dynamic> map) {
    final temasRaw = map['temasPriorizados'] as List<dynamic>? ?? [];
    final temas = temasRaw
        .map((t) => SnapshotTemaReporte.fromMap(t as Map<String, dynamic>))
        .toList();

    return ReporteEstudiante(
      id: map['id'] as String? ?? '',
      claseId: map['claseId'] as String? ?? '',
      periodo: map['periodo'] as String? ?? '',
      alumnoUid: map['alumnoUid'] as String? ?? '',
      alumnoNombre: map['alumnoNombre'] as String? ?? '',
      fechaGeneracion: map['fechaGeneracion'] != null
          ? DateTime.tryParse(map['fechaGeneracion'].toString()) ?? DateTime.now()
          : DateTime.now(),
      promedioGeneral: (map['promedioGeneral'] as num?)?.toDouble() ?? 0.0,
      porcentajeGeneral: (map['porcentajeGeneral'] as num?)?.toDouble() ?? 0.0,
      temasPriorizados: temas,
      totalTemasEnRiesgo: (map['totalTemasEnRiesgo'] as num?)?.toInt() ?? 0,
      comentarioDocente: map['comentarioDocente'] as String? ?? '',
    );
  }

  ReporteEstudiante copyWith({
    String? id,
    String? claseId,
    String? periodo,
    String? alumnoUid,
    String? alumnoNombre,
    DateTime? fechaGeneracion,
    double? promedioGeneral,
    double? porcentajeGeneral,
    List<SnapshotTemaReporte>? temasPriorizados,
    int? totalTemasEnRiesgo,
    String? comentarioDocente,
  }) {
    return ReporteEstudiante(
      id: id ?? this.id,
      claseId: claseId ?? this.claseId,
      periodo: periodo ?? this.periodo,
      alumnoUid: alumnoUid ?? this.alumnoUid,
      alumnoNombre: alumnoNombre ?? this.alumnoNombre,
      fechaGeneracion: fechaGeneracion ?? this.fechaGeneracion,
      promedioGeneral: promedioGeneral ?? this.promedioGeneral,
      porcentajeGeneral: porcentajeGeneral ?? this.porcentajeGeneral,
      temasPriorizados: temasPriorizados ?? this.temasPriorizados,
      totalTemasEnRiesgo: totalTemasEnRiesgo ?? this.totalTemasEnRiesgo,
      comentarioDocente: comentarioDocente ?? this.comentarioDocente,
    );
  }
}
