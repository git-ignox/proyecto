import '../modelos/analisis_brechas.dart';
import '../modelos/evaluacion.dart';

/// Motor analítico para detección de brechas pedagógicas, triage grupal
/// y seguimiento evolutivo del rendimiento por tema.
class AnalizadorBrechasEvaluacion {
  const AnalizadorBrechasEvaluacion();

  /// Analiza el perfil individual de un estudiante a partir de sus evaluaciones y notas.
  AnalisisEstudiante analizarEstudiante({
    required String alumnoUid,
    required String alumnoNombre,
    required List<Evaluacion> evaluaciones,
    required List<NotaEvaluacion> notas,
  }) {
    final mapaEvaluaciones = {for (final e in evaluaciones) e.id: e};
    final notasAlumno = notas.where((n) => n.alumnoUid == alumnoUid).toList();

    if (notasAlumno.isEmpty) {
      return AnalisisEstudiante(
        alumnoUid: alumnoUid,
        alumnoNombre: alumnoNombre,
        promedioGeneral: 0.0,
        porcentajeGeneral: 0.0,
        totalEvaluaciones: 0,
        rendimientosPorTema: const {},
        evolucionesPorTema: const {},
      );
    }

    // Promedio general global
    final sumaNotas = notasAlumno.fold<double>(0.0, (acc, n) => acc + n.nota);
    final promedioGeneral = sumaNotas / notasAlumno.length;
    final sumaPorcentajes = notasAlumno.fold<double>(0.0, (acc, n) => acc + n.porcentajeLogro);
    final porcentajeGeneral = sumaPorcentajes / notasAlumno.length;

    // Desglose por tema
    final Map<String, List<_NotaTemaItem>> notasPorTema = {};

    for (final nota in notasAlumno) {
      final eval = mapaEvaluaciones[nota.evaluacionId];
      if (eval == null) continue;

      if (nota.notasPorTema.isNotEmpty) {
        // Desglose granular por tema proporcionado en la nota
        nota.notasPorTema.forEach((tema, notaTema) {
          final pctTema = eval.notaMaxima > 0 ? (notaTema / eval.notaMaxima) * 100.0 : 0.0;
          notasPorTema.putIfAbsent(tema, () => []).add(
            _NotaTemaItem(
              evaluacionId: eval.id,
              evaluacionNombre: eval.nombre,
              fecha: eval.fecha,
              nota: notaTema,
              notaMaxima: eval.notaMaxima,
              porcentajeLogro: pctTema.clamp(0.0, 100.0),
            ),
          );
        });
      } else {
        // Asignar la nota de la evaluación a todos los temas etiquetados en la evaluación
        for (final tema in eval.temas) {
          notasPorTema.putIfAbsent(tema, () => []).add(
            _NotaTemaItem(
              evaluacionId: eval.id,
              evaluacionNombre: eval.nombre,
              fecha: eval.fecha,
              nota: nota.nota,
              notaMaxima: nota.notaMaxima,
              porcentajeLogro: nota.porcentajeLogro,
            ),
          );
        }
      }
    }

    final Map<String, RendimientoTema> rendimientos = {};
    final Map<String, EvolucionTema> evoluciones = {};

    notasPorTema.forEach((tema, items) {
      // Orden cronológico
      items.sort((a, b) => a.fecha.compareTo(b.fecha));

      final double sumaPcts = items.fold(0.0, (acc, it) => acc + it.porcentajeLogro);
      final double promPct = sumaPcts / items.length;
      final double sumaN = items.fold(0.0, (acc, it) => acc + it.nota);
      final double promNota = sumaN / items.length;

      rendimientos[tema] = RendimientoTema(
        tema: tema,
        cantidadEvaluaciones: items.length,
        porcentajeLogro: double.parse(promPct.toStringAsFixed(1)),
        promedioNota: double.parse(promNota.toStringAsFixed(1)),
      );

      // Evolución temporal
      final puntos = items.map((it) => PuntoEvolucion(
        evaluacionId: it.evaluacionId,
        evaluacionNombre: it.evaluacionNombre,
        fecha: it.fecha,
        porcentajeLogro: it.porcentajeLogro,
        nota: it.nota,
        notaMaxima: it.notaMaxima,
      )).toList();

      final variacion = puntos.length > 1
          ? puntos.last.porcentajeLogro - puntos.first.porcentajeLogro
          : 0.0;

      TendenciaEvolucion tendencia;
      if (puntos.length <= 1) {
        tendencia = TendenciaEvolucion.primeraMedicion;
      } else if (variacion > 5.0) {
        tendencia = TendenciaEvolucion.mejora;
      } else if (variacion < -5.0) {
        tendencia = TendenciaEvolucion.regresion;
      } else {
        tendencia = TendenciaEvolucion.estable;
      }

      evoluciones[tema] = EvolucionTema(
        tema: tema,
        puntos: puntos,
        variacionPorcentual: double.parse(variacion.toStringAsFixed(1)),
        tendencia: tendencia,
      );
    });

    // Determinar mejor y peor tema
    RendimientoTema? peorTema;
    RendimientoTema? mejorTema;

    if (rendimientos.isNotEmpty) {
      final ordenados = rendimientos.values.toList()
        ..sort((a, b) => a.porcentajeLogro.compareTo(b.porcentajeLogro));
      peorTema = ordenados.first;
      mejorTema = ordenados.last;
    }

    return AnalisisEstudiante(
      alumnoUid: alumnoUid,
      alumnoNombre: alumnoNombre,
      promedioGeneral: double.parse(promedioGeneral.toStringAsFixed(1)),
      porcentajeGeneral: double.parse(porcentajeGeneral.toStringAsFixed(1)),
      totalEvaluaciones: notasAlumno.length,
      rendimientosPorTema: rendimientos,
      temaPeorDesempeno: peorTema,
      temaMejorDesempeno: mejorTema,
      evolucionesPorTema: evoluciones,
    );
  }

  /// Analiza el perfil colectivo de una clase para triage y detección de brechas grupales.
  AnalisisClase analizarClase({
    required String claseId,
    required List<Evaluacion> evaluaciones,
    required List<NotaEvaluacion> notas,
    required Map<String, String> nombresAlumnos,
  }) {
    final evalsClase = evaluaciones.where((e) => e.claseId == claseId).toList();
    final notasClase = notas.where((n) => n.claseId == claseId).toList();

    if (notasClase.isEmpty) {
      return AnalisisClase(
        claseId: claseId,
        totalAlumnos: nombresAlumnos.length,
        totalEvaluaciones: evalsClase.length,
        promedioClase: 0.0,
        porcentajeClase: 0.0,
        rendimientosPorTema: const {},
        alumnosEnRiesgoPorTema: const {},
        recomendacionDocente: 'Aún no se han registrado notas para esta clase.',
        evolucionesPorTema: const {},
      );
    }

    final double sumaNotas = notasClase.fold(0.0, (acc, n) => acc + n.nota);
    final double promedioClase = sumaNotas / notasClase.length;
    final double sumaPcts = notasClase.fold(0.0, (acc, n) => acc + n.porcentajeLogro);
    final double porcentajeClase = sumaPcts / notasClase.length;

    // Obtener todos los alumnos únicos con notas
    final uidsAlumnos = notasClase.map((n) => n.alumnoUid).toSet();
    final totalAlumnosCalculado = uidsAlumnos.length > nombresAlumnos.length
        ? uidsAlumnos.length
        : nombresAlumnos.length;

    // Analizar cada estudiante individualmente para construir la matriz de temas
    final List<AnalisisEstudiante> analisisAlumnos = [];
    for (final uid in uidsAlumnos) {
      final nombre = nombresAlumnos[uid] ??
          notasClase.firstWhere((n) => n.alumnoUid == uid).alumnoNombre;
      analisisAlumnos.add(
        analizarEstudiante(
          alumnoUid: uid,
          alumnoNombre: nombre,
          evaluaciones: evalsClase,
          notas: notasClase,
        ),
      );
    }

    // Consolidar rendimiento grupal por tema
    final Map<String, List<double>> pctsPorTema = {};
    final Map<String, List<double>> notasPorTema = {};
    final Map<String, List<AlumnoRiesgo>> alumnosRiesgo = {};
    final Map<String, List<PuntoEvolucion>> puntosColectivosTema = {};

    // Histórico por evaluación para evolución colectiva
    for (final eval in evalsClase) {
      final notasEval = notasClase.where((n) => n.evaluacionId == eval.id).toList();
      if (notasEval.isEmpty) continue;

      final double promEvalPct =
          notasEval.fold(0.0, (acc, n) => acc + n.porcentajeLogro) / notasEval.length;
      final double promEvalNota =
          notasEval.fold(0.0, (acc, n) => acc + n.nota) / notasEval.length;

      for (final tema in eval.temas) {
        puntosColectivosTema.putIfAbsent(tema, () => []).add(
          PuntoEvolucion(
            evaluacionId: eval.id,
            evaluacionNombre: eval.nombre,
            fecha: eval.fecha,
            porcentajeLogro: double.parse(promEvalPct.toStringAsFixed(1)),
            nota: double.parse(promEvalNota.toStringAsFixed(1)),
            notaMaxima: eval.notaMaxima,
          ),
        );
      }
    }

    for (final alumno in analisisAlumnos) {
      alumno.rendimientosPorTema.forEach((tema, rend) {
        pctsPorTema.putIfAbsent(tema, () => []).add(rend.porcentajeLogro);
        notasPorTema.putIfAbsent(tema, () => []).add(rend.promedioNota);

        // Si el alumno tiene menos de 60% en el tema, se clasifica en riesgo
        if (rend.porcentajeLogro < 60.0) {
          alumnosRiesgo.putIfAbsent(tema, () => []).add(
            AlumnoRiesgo(
              alumnoUid: alumno.alumnoUid,
              alumnoNombre: alumno.alumnoNombre,
              porcentajeLogroTema: rend.porcentajeLogro,
              promedioNotaTema: rend.promedioNota,
            ),
          );
        }
      });
    }

    final Map<String, RendimientoTema> rendimientosColectivos = {};
    final Map<String, EvolucionTema> evolucionesColectivas = {};

    pctsPorTema.forEach((tema, listaPcts) {
      final double promPct = listaPcts.fold(0.0, (acc, p) => acc + p) / listaPcts.length;
      final double promNota =
          notasPorTema[tema]!.fold(0.0, (acc, n) => acc + n) / notasPorTema[tema]!.length;

      rendimientosColectivos[tema] = RendimientoTema(
        tema: tema,
        cantidadEvaluaciones: evalsClase.where((e) => e.temas.contains(tema)).length,
        porcentajeLogro: double.parse(promPct.toStringAsFixed(1)),
        promedioNota: double.parse(promNota.toStringAsFixed(1)),
      );

      // Evolución colectiva del tema
      final puntos = puntosColectivosTema[tema] ?? [];
      puntos.sort((a, b) => a.fecha.compareTo(b.fecha));

      final variacion = puntos.length > 1
          ? puntos.last.porcentajeLogro - puntos.first.porcentajeLogro
          : 0.0;

      TendenciaEvolucion tendencia;
      if (puntos.length <= 1) {
        tendencia = TendenciaEvolucion.primeraMedicion;
      } else if (variacion > 5.0) {
        tendencia = TendenciaEvolucion.mejora;
      } else if (variacion < -5.0) {
        tendencia = TendenciaEvolucion.regresion;
      } else {
        tendencia = TendenciaEvolucion.estable;
      }

      evolucionesColectivas[tema] = EvolucionTema(
        tema: tema,
        puntos: puntos,
        variacionPorcentual: double.parse(variacion.toStringAsFixed(1)),
        tendencia: tendencia,
      );
    });

    // Identificar peor tema colectivo
    RendimientoTema? peorTemaColectivo;
    if (rendimientosColectivos.isNotEmpty) {
      final ordenados = rendimientosColectivos.values.toList()
        ..sort((a, b) => a.porcentajeLogro.compareTo(b.porcentajeLogro));
      peorTemaColectivo = ordenados.first;
    }

    // Generar recomendación docente pedagógica
    String recomendacion;
    if (peorTemaColectivo != null) {
      final enRiesgo = alumnosRiesgo[peorTemaColectivo.tema]?.length ?? 0;
      if (peorTemaColectivo.porcentajeLogro < 60.0) {
        recomendacion =
            'Prioridad urgente de refuerzo: "${peorTemaColectivo.tema}". El grupo promedia solo un ${peorTemaColectivo.porcentajeLogro}% de logro y cuenta con $enRiesgo estudiante(s) con brechas críticas. Se sugiere dedicar los primeros 25 minutos de la próxima clase a modelado guiado y resolución de dudas.';
      } else if (peorTemaColectivo.porcentajeLogro <= 75.0) {
        recomendacion =
            'Foco preventivo: "${peorTemaColectivo.tema}" está en desarrollo colectivo (${peorTemaColectivo.porcentajeLogro}%). Reforzar con 2 o 3 ejercicios prácticos de aplicación en parejas antes de avanzar a la siguiente unidad.';
      } else {
        recomendacion =
            'Rendimiento colectivo sólido: Todos los temas superan el 75% de logro. El curso está preparado para abordar contenidos de mayor complejidad curricular.';
      }
    } else {
      recomendacion = 'Continúa registrando evaluaciones para consolidar el diagnóstico de brechas.';
    }

    return AnalisisClase(
      claseId: claseId,
      totalAlumnos: totalAlumnosCalculado,
      totalEvaluaciones: evalsClase.length,
      promedioClase: double.parse(promedioClase.toStringAsFixed(1)),
      porcentajeClase: double.parse(porcentajeClase.toStringAsFixed(1)),
      rendimientosPorTema: rendimientosColectivos,
      temaPeorDesempenoColectivo: peorTemaColectivo,
      alumnosEnRiesgoPorTema: alumnosRiesgo,
      recomendacionDocente: recomendacion,
      evolucionesPorTema: evolucionesColectivas,
    );
  }
}

class _NotaTemaItem {
  const _NotaTemaItem({
    required this.evaluacionId,
    required this.evaluacionNombre,
    required this.fecha,
    required this.nota,
    required this.notaMaxima,
    required this.porcentajeLogro,
  });

  final String evaluacionId;
  final String evaluacionNombre;
  final DateTime fecha;
  final double nota;
  final double notaMaxima;
  final double porcentajeLogro;
}
