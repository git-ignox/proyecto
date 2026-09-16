import 'package:flutter/material.dart';
import 'curriculo.dart';

/// Estado pedagógico de un objetivo o estándar curricular en una clase escolar.
enum EstadoObjetivoCurricular {
  /// No se ha aplicado ninguna evaluación para este objetivo en el período escolar.
  /// Constituye una BRECHA DE ENSEÑANZA / COBERTURA.
  noEvaluado,

  /// Se ha evaluado, pero el logro colectivo promedio es inferior al 60%.
  /// Constituye una BRECHA DE APRENDIZAJE.
  enRiesgo,

  /// Se ha evaluado con un logro colectivo promedio igual o superior al 60%.
  dominado;

  String get etiqueta {
    switch (this) {
      case EstadoObjetivoCurricular.noEvaluado:
        return 'Brecha de Enseñanza (Sin evaluar)';
      case EstadoObjetivoCurricular.enRiesgo:
        return 'Brecha de Aprendizaje (<60%)';
      case EstadoObjetivoCurricular.dominado:
        return 'Consolidado';
    }
  }

  Color get color {
    switch (this) {
      case EstadoObjetivoCurricular.noEvaluado:
        return Colors.orange.shade800;
      case EstadoObjetivoCurricular.enRiesgo:
        return Colors.red.shade700;
      case EstadoObjetivoCurricular.dominado:
        return Colors.green.shade700;
    }
  }

  IconData get icono {
    switch (this) {
      case EstadoObjetivoCurricular.noEvaluado:
        return Icons.hourglass_empty_rounded;
      case EstadoObjetivoCurricular.enRiesgo:
        return Icons.warning_amber_rounded;
      case EstadoObjetivoCurricular.dominado:
        return Icons.check_circle_outline_rounded;
    }
  }
}

/// Diagnóstico analítico de un objetivo curricular individual dentro de la clase.
class AnalisisObjetivoCurricular {
  const AnalisisObjetivoCurricular({
    required this.objetivo,
    required this.cantidadEvaluaciones,
    this.evaluacionesIds = const [],
    this.evaluacionesNombres = const [],
    this.rendimientoPromedio,
    this.promedioNota,
    required this.estado,
  });

  final ObjetivoAprendizaje objetivo;
  final int cantidadEvaluaciones;
  final List<String> evaluacionesIds;
  final List<String> evaluacionesNombres;

  /// Porcentaje de logro promedio de la clase (0.0 - 100.0), o null si no fue evaluado.
  final double? rendimientoPromedio;

  /// Nota promedio de la clase, o null si no fue evaluado.
  final double? promedioNota;

  final EstadoObjetivoCurricular estado;

  bool get esBrechaEnsenanza => estado == EstadoObjetivoCurricular.noEvaluado;
  bool get esBrechaAprendizaje => estado == EstadoObjetivoCurricular.enRiesgo;
  bool get estaDominado => estado == EstadoObjetivoCurricular.dominado;
}

/// Diagnóstico analítico de una unidad curricular con métricas de cobertura y dominio.
class AnalisisUnidadCurricular {
  const AnalisisUnidadCurricular({
    required this.unidad,
    required this.totalObjetivos,
    required this.objetivosEvaluados,
    required this.porcentajeCobertura,
    this.promedioDominio,
    required this.objetivosAnalizados,
  });

  final UnidadCurricular unidad;
  final int totalObjetivos;
  final int objetivosEvaluados;

  /// % de objetivos de la unidad con al menos una evaluación realizada.
  final double porcentajeCobertura;

  /// Promedio de logro (%) considerando los objetivos que sí fueron evaluados.
  final double? promedioDominio;

  final List<AnalisisObjetivoCurricular> objetivosAnalizados;

  int get totalBrechasEnsenanza =>
      objetivosAnalizados.where((o) => o.esBrechaEnsenanza).length;

  int get totalBrechasAprendizaje =>
      objetivosAnalizados.where((o) => o.esBrechaAprendizaje).length;
}

/// Mapa integral de cobertura curricular de una clase escolar.
class MapaCoberturaCurricular {
  const MapaCoberturaCurricular({
    required this.claseId,
    required this.planCurricular,
    required this.totalObjetivosCurriculo,
    required this.totalObjetivosEvaluados,
    required this.porcentajeCoberturaGlobal,
    this.promedioDominioGlobal,
    required this.unidades,
    required this.brechasEnsenanza,
    required this.brechasAprendizaje,
  });

  final String claseId;
  final PlanCurricular planCurricular;

  final int totalObjetivosCurriculo;
  final int totalObjetivosEvaluados;

  /// Cobertura de enseñanza global: (total evaluados / total del currículo) * 100
  final double porcentajeCoberturaGlobal;

  /// Dominio promedio de la clase sobre los objetivos evaluados
  final double? promedioDominioGlobal;

  final List<AnalisisUnidadCurricular> unidades;

  /// Lista consolidada de objetivos nunca evaluados (Brechas de Enseñanza)
  final List<AnalisisObjetivoCurricular> brechasEnsenanza;

  /// Lista consolidada de objetivos evaluados con rendimiento < 60% (Brechas de Aprendizaje)
  final List<AnalisisObjetivoCurricular> brechasAprendizaje;

  bool get tieneBrechasEnsenanza => brechasEnsenanza.isNotEmpty;
  bool get tieneBrechasAprendizaje => brechasAprendizaje.isNotEmpty;
}
