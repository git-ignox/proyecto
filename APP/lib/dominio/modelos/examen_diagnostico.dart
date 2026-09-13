import 'ejercicio.dart';
import 'error_aprendizaje.dart';

/// Criterios de avance que el profesor puede determinar para el examen diagnóstico.
enum CriterioAvance {
  /// El alumno debe alcanzar un porcentaje mínimo de aciertos (ej. 70%, 80%).
  porcentajeAciertosMinimo,

  /// El alumno debe aprobar sin cometer errores de severidad crítica ni fallos reiterados en tags clave.
  sinErroresCriticos,

  /// El alumno debe alcanzar un puntaje total acumulado específico fijado por el docente.
  puntajeTotalMinimo,

  /// El alumno debe responder el 100% de los ejercicios para que el sistema genere el diagnóstico.
  todosLosEjercicios,

  /// El avance requiere revisión y validación manual directa por parte del profesor.
  aprobacionManualDocente;

  String get etiqueta {
    switch (this) {
      case CriterioAvance.porcentajeAciertosMinimo:
        return 'Porcentaje Mínimo de Aciertos (%)';
      case CriterioAvance.sinErroresCriticos:
        return 'Sin Errores Críticos';
      case CriterioAvance.puntajeTotalMinimo:
        return 'Puntaje Mínimo Requerido';
      case CriterioAvance.todosLosEjercicios:
        return 'Completar Todos los Ejercicios';
      case CriterioAvance.aprobacionManualDocente:
        return 'Autorización Manual del Profesor';
    }
  }

  String get descripcion {
    switch (this) {
      case CriterioAvance.porcentajeAciertosMinimo:
        return 'El estudiante avanza automáticamente si supera el umbral porcentual determinado.';
      case CriterioAvance.sinErroresCriticos:
        return 'El estudiante no debe tener fallas graves en conceptos fundamentales.';
      case CriterioAvance.puntajeTotalMinimo:
        return 'El estudiante debe sumar los puntos requeridos para desbloquear el siguiente tema.';
      case CriterioAvance.todosLosEjercicios:
        return 'El estudiante debe contestar todas las preguntas del examen.';
      case CriterioAvance.aprobacionManualDocente:
        return 'El docente revisará el informe del diagnóstico antes de autorizar el avance.';
    }
  }
}

/// Resultado de la verificación de la variable de avance fijada por el docente.
class ResultadoAvance {
  const ResultadoAvance({
    required this.cumple,
    required this.porcentajeLogrado,
    required this.umbralExigido,
    required this.mensajePedagogico,
    required this.puedeAvanzar,
    this.criterio = CriterioAvance.porcentajeAciertosMinimo,
    this.erroresCriticosDetectados = 0,
  });

  /// Indica si los resultados del alumno satisfacen la condición fijada por el profesor.
  final bool cumple;

  /// Porcentaje de acierto o logro obtenido por el alumno (0.0 a 100.0).
  final double porcentajeLogrado;

  /// Umbral exigido por el profesor (ej. 75.0 para 75% o puntaje).
  final double umbralExigido;

  /// Mensaje explicativo para el alumno y el profesor.
  final String mensajePedagogico;

  /// Si el alumno está habilitado para desbloquear y avanzar al siguiente contenido.
  final bool puedeAvanzar;

  /// Criterio aplicado para la decisión.
  final CriterioAvance criterio;

  /// Número de errores de severidad crítica detectados.
  final int erroresCriticosDetectados;
}

/// Clase de Examen Diagnóstico con variable de avance configurable por el profesor.
/// Permite al docente estructurar una prueba inicial, medir habilidades clave mediante tags
/// y determinar las condiciones cuantitativas y cualitativas que el alumno debe cumplir
/// para avanzar de nivel o tema.
class ExamenDiagnostico {
  const ExamenDiagnostico({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.profesorUid,
    this.profesorNombre = 'Profesor',
    required this.ejercicios,
    this.tagsEvaluados = const [],
    // --- Variables de avance determinadas por el docente ---
    this.criterioAvance = CriterioAvance.porcentajeAciertosMinimo,
    this.umbralAvance = 0.70, // Por defecto 70% o valor numérico según criterio
    this.permitirAvanceAutomatico = true,
    this.temaDestinoAlAvanzar,
    this.maximoIntentos = 1,
    this.tiempoLimiteMinutos,
    this.estaActivo = true,
    required this.fechaCreacion,
  });

  final String id;
  final String titulo;
  final String descripcion;
  final String profesorUid;
  final String profesorNombre;
  final List<Ejercicio> ejercicios;
  final List<String> tagsEvaluados;

  /// Modalidad o criterio de avance determinado por el profesor.
  final CriterioAvance criterioAvance;

  /// Valor umbral de avance determinado por el profesor (ej. 0.75 para 75% o 80 puntos).
  final double umbralAvance;

  /// Si el sistema desbloquea automáticamente el siguiente contenido al cumplir el umbral.
  final bool permitirAvanceAutomatico;

  /// Código o nombre del tema curricular desbloqueado al superar el examen.
  final String? temaDestinoAlAvanzar;

  /// Número máximo de intentos permitidos (null para ilimitados).
  final int? maximoIntentos;

  /// Tiempo límite en minutos (opcional).
  final int? tiempoLimiteMinutos;

  /// Si el examen está publicado y disponible para los alumnos.
  final bool estaActivo;

  /// Fecha de diseño del examen.
  final DateTime fechaCreacion;

  /// Total de ejercicios configurados en el examen.
  int get totalPreguntas => ejercicios.length;

  /// Puntaje total máximo alcanzable en el examen.
  int get puntajeTotalMaximo => ejercicios.fold(0, (sum, e) => sum + e.puntos);

  /// Evalúa el desempeño del alumno contra la variable de avance determinada por el profesor.
  ResultadoAvance verificarAvance({
    required int aciertos,
    required int totalRespondidas,
    required double puntajeObtenido,
    List<ErrorAprendizaje> errores = const [],
  }) {
    if (totalPreguntas == 0) {
      return const ResultadoAvance(
        cumple: true,
        porcentajeLogrado: 100.0,
        umbralExigido: 0.0,
        mensajePedagogico: 'Examen sin ejercicios configurados.',
        puedeAvanzar: true,
      );
    }

    final porcentajeAciertos = totalPreguntas > 0 ? (aciertos / totalPreguntas) * 100.0 : 0.0;
    final porcentajeRespondido = totalPreguntas > 0 ? (totalRespondidas / totalPreguntas) * 100.0 : 0.0;
    final erroresCriticos = errores.where((e) => e.severidad == SeveridadError.critica).length;

    bool cumple = false;
    String mensaje = '';
    final umbralPorcentaje = umbralAvance <= 1.0 ? umbralAvance * 100.0 : umbralAvance;

    switch (criterioAvance) {
      case CriterioAvance.porcentajeAciertosMinimo:
        cumple = porcentajeAciertos >= umbralPorcentaje;
        if (cumple) {
          mensaje = '¡Excelente! Has alcanzado ${porcentajeAciertos.toStringAsFixed(1)}%, superando la meta de ${umbralPorcentaje.toStringAsFixed(0)}% fijada por tu profesor.';
        } else {
          mensaje = 'Obtuviste ${porcentajeAciertos.toStringAsFixed(1)}%. Necesitas al menos ${umbralPorcentaje.toStringAsFixed(0)}% de aciertos para avanzar.';
        }
        break;

      case CriterioAvance.sinErroresCriticos:
        cumple = erroresCriticos == 0 && porcentajeAciertos >= 50.0;
        if (cumple) {
          mensaje = '¡Cumplido! No se detectaron errores críticos en conceptos fundamentales.';
        } else {
          mensaje = 'Se detectaron $erroresCriticos errores conceptuales críticos. Se requiere sesión de refuerzo antes de avanzar.';
        }
        break;

      case CriterioAvance.puntajeTotalMinimo:
        cumple = puntajeObtenido >= umbralAvance;
        if (cumple) {
          mensaje = '¡Logrado! Obtuviste ${puntajeObtenido.toStringAsFixed(0)} puntos, alcanzando el puntaje mínimo de ${umbralAvance.toStringAsFixed(0)} fijado por el docente.';
        } else {
          mensaje = 'Obtuviste ${puntajeObtenido.toStringAsFixed(0)} puntos de un mínimo de ${umbralAvance.toStringAsFixed(0)} puntos requeridos.';
        }
        break;

      case CriterioAvance.todosLosEjercicios:
        cumple = totalRespondidas >= totalPreguntas;
        if (cumple) {
          mensaje = 'Has completado el 100% de los ejercicios del diagnóstico.';
        } else {
          mensaje = 'Has completado $totalRespondidas de $totalPreguntas preguntas (${porcentajeRespondido.toStringAsFixed(0)}%).';
        }
        break;

      case CriterioAvance.aprobacionManualDocente:
        cumple = porcentajeAciertos >= umbralPorcentaje;
        mensaje = 'Examen completado (${porcentajeAciertos.toStringAsFixed(1)}%). Pendiente de revisión y confirmación del profesor.';
        break;
    }

    final puedeAvanzar = cumple && (permitirAvanceAutomatico || criterioAvance != CriterioAvance.aprobacionManualDocente);

    return ResultadoAvance(
      cumple: cumple,
      porcentajeLogrado: porcentajeAciertos,
      umbralExigido: umbralPorcentaje,
      mensajePedagogico: mensaje,
      puedeAvanzar: puedeAvanzar,
      criterio: criterioAvance,
      erroresCriticosDetectados: erroresCriticos,
    );
  }

  /// Serialización a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'profesorUid': profesorUid,
      'profesorNombre': profesorNombre,
      'tagsEvaluados': tagsEvaluados,
      'criterioAvance': criterioAvance.name,
      'umbralAvance': umbralAvance,
      'permitirAvanceAutomatico': permitirAvanceAutomatico,
      'temaDestinoAlAvanzar': temaDestinoAlAvanzar,
      'maximoIntentos': maximoIntentos,
      'tiempoLimiteMinutos': tiempoLimiteMinutos,
      'estaActivo': estaActivo,
      'fechaCreacion': fechaCreacion.toIso8601String(),
    };
  }

  /// Deserialización desde Map (junto con la lista de ejercicios recuperados)
  factory ExamenDiagnostico.fromMap(Map<String, dynamic> map, {List<Ejercicio> ejercicios = const []}) {
    return ExamenDiagnostico(
      id: map['id'] as String? ?? '',
      titulo: map['titulo'] as String? ?? 'Examen Diagnóstico',
      descripcion: map['descripcion'] as String? ?? '',
      profesorUid: map['profesorUid'] as String? ?? '',
      profesorNombre: map['profesorNombre'] as String? ?? 'Profesor',
      ejercicios: ejercicios,
      tagsEvaluados: List<String>.from(map['tagsEvaluados'] as List? ?? []),
      criterioAvance: CriterioAvance.values.firstWhere(
        (c) => c.name == map['criterioAvance'],
        orElse: () => CriterioAvance.porcentajeAciertosMinimo,
      ),
      umbralAvance: (map['umbralAvance'] as num?)?.toDouble() ?? 0.70,
      permitirAvanceAutomatico: map['permitirAvanceAutomatico'] as bool? ?? true,
      temaDestinoAlAvanzar: map['temaDestinoAlAvanzar'] as String?,
      maximoIntentos: map['maximoIntentos'] as int?,
      tiempoLimiteMinutos: map['tiempoLimiteMinutos'] as int?,
      estaActivo: map['estaActivo'] as bool? ?? true,
      fechaCreacion: map['fechaCreacion'] != null
          ? DateTime.tryParse(map['fechaCreacion'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
