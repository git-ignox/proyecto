import 'package:flutter/material.dart';

/// Nivel de dominio pedagógico alcanzado en un tema.
enum NivelDominio {
  critico,       // < 60%
  enDesarrollo,  // 60% - 75%
  consolidado;   // > 75%

  String get etiqueta {
    switch (this) {
      case NivelDominio.critico:
        return 'Brecha Crítica';
      case NivelDominio.enDesarrollo:
        return 'En Desarrollo';
      case NivelDominio.consolidado:
        return 'Consolidado';
    }
  }

  Color get color {
    switch (this) {
      case NivelDominio.critico:
        return Colors.red.shade700;
      case NivelDominio.enDesarrollo:
        return Colors.amber.shade800;
      case NivelDominio.consolidado:
        return Colors.green.shade700;
    }
  }

  IconData get icono {
    switch (this) {
      case NivelDominio.critico:
        return Icons.warning_amber_rounded;
      case NivelDominio.enDesarrollo:
        return Icons.trending_up;
      case NivelDominio.consolidado:
        return Icons.check_circle_outline;
    }
  }
}

/// Tendencia de desempeño temporal para un tema evaluado múltiples veces.
enum TendenciaEvolucion {
  mejora,
  estable,
  regresion,
  primeraMedicion;

  String get etiqueta {
    switch (this) {
      case TendenciaEvolucion.mejora:
        return 'Mejora notable 📈';
      case TendenciaEvolucion.estable:
        return 'Rendimiento estable ➖';
      case TendenciaEvolucion.regresion:
        return 'Descendió / Requiere apoyo 📉';
      case TendenciaEvolucion.primeraMedicion:
        return 'Medición inicial 📌';
    }
  }

  Color get color {
    switch (this) {
      case TendenciaEvolucion.mejora:
        return Colors.green.shade700;
      case TendenciaEvolucion.estable:
        return Colors.blue.shade700;
      case TendenciaEvolucion.regresion:
        return Colors.red.shade700;
      case TendenciaEvolucion.primeraMedicion:
        return Colors.grey.shade700;
    }
  }
}

/// Rendimiento consolidado de un estudiante o clase en un tema específico.
class RendimientoTema {
  const RendimientoTema({
    required this.tema,
    required this.cantidadEvaluaciones,
    required this.porcentajeLogro,
    required this.promedioNota,
    this.notaMaximaPromedio = 7.0,
  });

  final String tema;
  final int cantidadEvaluaciones;
  final double porcentajeLogro; // 0.0 a 100.0
  final double promedioNota;
  final double notaMaximaPromedio;

  NivelDominio get nivelDominio {
    if (porcentajeLogro < 60.0) return NivelDominio.critico;
    if (porcentajeLogro <= 75.0) return NivelDominio.enDesarrollo;
    return NivelDominio.consolidado;
  }
}

/// Registro de una evaluación en una fecha específica para calcular evolución.
class PuntoEvolucion {
  const PuntoEvolucion({
    required this.evaluacionId,
    required this.evaluacionNombre,
    required this.fecha,
    required this.porcentajeLogro,
    required this.nota,
    this.notaMaxima = 7.0,
  });

  final String evaluacionId;
  final String evaluacionNombre;
  final DateTime fecha;
  final double porcentajeLogro;
  final double nota;
  final double notaMaxima;
}

/// Evolución temporal del desempeño en un tema a lo largo de varias evaluaciones.
class EvolucionTema {
  const EvolucionTema({
    required this.tema,
    required this.puntos,
    required this.variacionPorcentual,
    required this.tendencia,
  });

  final String tema;
  final List<PuntoEvolucion> puntos;
  final double variacionPorcentual; // Diferencia entre la última y la primera/previa
  final TendenciaEvolucion tendencia;

  PuntoEvolucion? get primerPunto => puntos.isNotEmpty ? puntos.first : null;
  PuntoEvolucion? get ultimoPunto => puntos.isNotEmpty ? puntos.last : null;
}

/// Perfil de análisis de un estudiante.
class AnalisisEstudiante {
  const AnalisisEstudiante({
    required this.alumnoUid,
    required this.alumnoNombre,
    required this.promedioGeneral,
    required this.porcentajeGeneral,
    required this.totalEvaluaciones,
    required this.rendimientosPorTema,
    this.temaPeorDesempeno,
    this.temaMejorDesempeno,
    required this.evolucionesPorTema,
  });

  final String alumnoUid;
  final String alumnoNombre;
  final double promedioGeneral;
  final double porcentajeGeneral;
  final int totalEvaluaciones;

  /// Mapa de tema -> RendimientoTema
  final Map<String, RendimientoTema> rendimientosPorTema;

  /// Tema de menor rendimiento (el foco principal de brecha a resolver)
  final RendimientoTema? temaPeorDesempeno;

  /// Tema de mayor rendimiento (fortaleza del alumno)
  final RendimientoTema? temaMejorDesempeno;

  /// Histórico y tendencia temporal por cada tema
  final Map<String, EvolucionTema> evolucionesPorTema;
}

/// Estudiante identificado en riesgo en un tema específico dentro de la clase.
class AlumnoRiesgo {
  const AlumnoRiesgo({
    required this.alumnoUid,
    required this.alumnoNombre,
    required this.porcentajeLogroTema,
    required this.promedioNotaTema,
  });

  final String alumnoUid;
  final String alumnoNombre;
  final double porcentajeLogroTema;
  final double promedioNotaTema;
}

/// Perfil de análisis colectivo de una clase.
class AnalisisClase {
  const AnalisisClase({
    required this.claseId,
    required this.totalAlumnos,
    required this.totalEvaluaciones,
    required this.promedioClase,
    required this.porcentajeClase,
    required this.rendimientosPorTema,
    this.temaPeorDesempenoColectivo,
    required this.alumnosEnRiesgoPorTema,
    required this.recomendacionDocente,
    required this.evolucionesPorTema,
  });

  final String claseId;
  final int totalAlumnos;
  final int totalEvaluaciones;
  final double promedioClase;
  final double porcentajeClase;

  /// Mapa de tema -> Rendimiento colectivo de la clase
  final Map<String, RendimientoTema> rendimientosPorTema;

  /// El tema colectivo más débil de la clase (para reforzar en la próxima clase)
  final RendimientoTema? temaPeorDesempenoColectivo;

  /// Mapa de tema -> lista de alumnos que están bajo 60% en ese tema
  final Map<String, List<AlumnoRiesgo>> alumnosEnRiesgoPorTema;

  /// Sugerencia pedagógica directa para el docente
  final String recomendacionDocente;

  /// Evolución del grupo por cada tema
  final Map<String, EvolucionTema> evolucionesPorTema;
}
