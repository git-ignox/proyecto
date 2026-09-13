import 'error_aprendizaje.dart';

/// Nivel de urgencia o prioridad de intervención pedagógica.
enum PrioridadAyuda {
  alta,
  media,
  preventiva;

  String get etiqueta {
    switch (this) {
      case PrioridadAyuda.alta:
        return 'Urgencia Alta 🔴';
      case PrioridadAyuda.media:
        return 'Atención Media 🟡';
      case PrioridadAyuda.preventiva:
        return 'Preventiva / Refuerzo 🟢';
    }
  }
}

/// Resumen estadístico de un error recurrente o destacado en el alumno.
class ResumenErrorProminente {
  const ResumenErrorProminente({
    required this.categoria,
    required this.subtipo,
    required this.descripcion,
    required this.conteo,
    this.tagsRelacionados = const [],
    this.severidad = SeveridadError.moderada,
    this.sugerenciaDocente = '',
  });

  final CategoriaError categoria;
  final String subtipo;
  final String descripcion;
  final int conteo;
  final List<String> tagsRelacionados;
  final SeveridadError severidad;
  final String sugerenciaDocente;
}

/// Recomendación pedagógica generada automáticamente indicando en qué se debe ayudar al estudiante.
class RecomendacionPedagogica {
  const RecomendacionPedagogica({
    required this.id,
    required this.titulo,
    required this.explicacion,
    required this.prioridad,
    required this.tagsParaReforzar,
    required this.accionSugerida,
  });

  final String id;
  final String titulo;
  final String explicacion;
  final PrioridadAyuda prioridad;
  final List<String> tagsParaReforzar;
  final String accionSugerida;
}

/// Diagnóstico pedagógico global del alumno computado a partir de su historial de intentos.
class DiagnosticoAlumno {
  const DiagnosticoAlumno({
    required this.usuarioUid,
    required this.totalIntentos,
    required this.aciertos,
    required this.errores,
    required this.porcentajePrecision,
    this.distribucionPorCategoria = const {},
    this.distribucionPorTag = const {},
    this.erroresProminentes = const [],
    this.tagsCriticos = const [],
    this.recomendacionesRefuerzo = const [],
  });

  final String usuarioUid;
  final int totalIntentos;
  final int aciertos;
  final int errores;
  final double porcentajePrecision; // 0.0 a 100.0
  final Map<CategoriaError, int> distribucionPorCategoria;
  final Map<String, int> distribucionPorTag;
  final List<ResumenErrorProminente> erroresProminentes;
  final List<String> tagsCriticos;
  final List<RecomendacionPedagogica> recomendacionesRefuerzo;

  bool get requiereAtencion => tagsCriticos.isNotEmpty || erroresProminentes.isNotEmpty;

  factory DiagnosticoAlumno.vacio(String uid) {
    return DiagnosticoAlumno(
      usuarioUid: uid,
      totalIntentos: 0,
      aciertos: 0,
      errores: 0,
      porcentajePrecision: 100.0,
      distribucionPorCategoria: {},
      distribucionPorTag: {},
      erroresProminentes: [],
      tagsCriticos: [],
      recomendacionesRefuerzo: [],
    );
  }
}
