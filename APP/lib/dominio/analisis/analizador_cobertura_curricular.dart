import '../modelos/cobertura_curricular.dart';
import '../modelos/curriculo.dart';
import '../modelos/evaluacion.dart';

/// Motor analítico para la evaluación de cobertura curricular y detección
/// de brechas de enseñanza (objetivos no evaluados) vs. brechas de aprendizaje (<60% logro).
class AnalizadorCoberturaCurricular {
  const AnalizadorCoberturaCurricular();

  /// Analiza el mapa de cobertura curricular de una clase escolar a partir
  /// de su plan curricular, sus evaluaciones y calificaciones registradas.
  MapaCoberturaCurricular analizarCobertura({
    required PlanCurricular plan,
    required List<Evaluacion> evaluaciones,
    required List<NotaEvaluacion> notas,
    required String claseId,
  }) {
    // Filtrar evaluaciones que pertenezcan a esta clase escolar
    final evalsClase = evaluaciones.where((e) => e.claseId == claseId).toList();
    final notasClase = notas.where((n) => n.claseId == claseId).toList();

    final List<AnalisisUnidadCurricular> unidadesAnalizadas = [];
    final List<AnalisisObjetivoCurricular> todasBrechasEnsenanza = [];
    final List<AnalisisObjetivoCurricular> todasBrechasAprendizaje = [];

    int contadorTotalEvaluados = 0;
    final List<double> porcentajesEvaluadosGlobal = [];

    for (final unidad in plan.unidades) {
      final List<AnalisisObjetivoCurricular> objetivosDeUnidad = [];
      final List<double> porcentajesEvaluadosUnidad = [];

      for (final objetivo in unidad.objetivos) {
        // Regla de vinculación determinista:
        // 1. Vinculación primaria explícita por ID de objetivo.
        // 2. Fallback secundario: coincidencia exacta por código literal (ej. 'OA-01' en temas).
        final evalsAsociadas = evalsClase.where((e) {
          final tieneId = e.objetivoIds.contains(objetivo.id);
          if (tieneId) return true;

          final codigoNorm = objetivo.codigo.toUpperCase().trim();
          final tieneCodigoEnTemas = e.temas.any(
            (tema) => tema.toUpperCase().contains(codigoNorm),
          );
          return tieneCodigoEnTemas;
        }).toList();

        if (evalsAsociadas.isEmpty) {
          // 🟠 BRECHA DE ENSEÑANZA: 0 evaluaciones aplicadas
          final analisisObj = AnalisisObjetivoCurricular(
            objetivo: objetivo,
            cantidadEvaluaciones: 0,
            evaluacionesIds: const [],
            evaluacionesNombres: const [],
            rendimientoPromedio: null,
            promedioNota: null,
            estado: EstadoObjetivoCurricular.noEvaluado,
          );
          objetivosDeUnidad.add(analisisObj);
          todasBrechasEnsenanza.add(analisisObj);
        } else {
          // El objetivo fue evaluado
          contadorTotalEvaluados++;

          final evalsIds = evalsAsociadas.map((e) => e.id).toSet();
          final notasObjetivo = notasClase.where((n) => evalsIds.contains(n.evaluacionId)).toList();

          double? rendimientoPromedio;
          double? notaPromedio;

          if (notasObjetivo.isNotEmpty) {
            final sumaPct = notasObjetivo.fold<double>(0.0, (acc, n) => acc + n.porcentajeLogro);
            final sumaNota = notasObjetivo.fold<double>(0.0, (acc, n) => acc + n.nota);

            rendimientoPromedio = double.parse((sumaPct / notasObjetivo.length).toStringAsFixed(1));
            notaPromedio = double.parse((sumaNota / notasObjetivo.length).toStringAsFixed(1));
            porcentajesEvaluadosUnidad.add(rendimientoPromedio);
            porcentajesEvaluadosGlobal.add(rendimientoPromedio);
          }

          // Criterio pedagógico unificado del sistema: < 60% es riesgo crítico
          final EstadoObjetivoCurricular estado;
          if (rendimientoPromedio != null && rendimientoPromedio < 60.0) {
            estado = EstadoObjetivoCurricular.enRiesgo; // 🔴 BRECHA DE APRENDIZAJE
          } else {
            estado = EstadoObjetivoCurricular.dominado; // 🟢 CONSOLIDADO
          }

          final analisisObj = AnalisisObjetivoCurricular(
            objetivo: objetivo,
            cantidadEvaluaciones: evalsAsociadas.length,
            evaluacionesIds: evalsAsociadas.map((e) => e.id).toList(),
            evaluacionesNombres: evalsAsociadas.map((e) => e.nombre).toList(),
            rendimientoPromedio: rendimientoPromedio,
            promedioNota: notaPromedio,
            estado: estado,
          );

          objetivosDeUnidad.add(analisisObj);
          if (estado == EstadoObjetivoCurricular.enRiesgo) {
            todasBrechasAprendizaje.add(analisisObj);
          }
        }
      }

      final totalObjsUnidad = unidad.objetivos.length;
      final evalsUnidad = objetivosDeUnidad.where((o) => !o.esBrechaEnsenanza).length;
      final pctCoberturaUnidad = totalObjsUnidad > 0
          ? double.parse(((evalsUnidad / totalObjsUnidad) * 100.0).toStringAsFixed(1))
          : 0.0;

      final promDominioUnidad = porcentajesEvaluadosUnidad.isNotEmpty
          ? double.parse((porcentajesEvaluadosUnidad.reduce((a, b) => a + b) /
                  porcentajesEvaluadosUnidad.length)
              .toStringAsFixed(1))
          : null;

      unidadesAnalizadas.add(
        AnalisisUnidadCurricular(
          unidad: unidad,
          totalObjetivos: totalObjsUnidad,
          objetivosEvaluados: evalsUnidad,
          porcentajeCobertura: pctCoberturaUnidad,
          promedioDominio: promDominioUnidad,
          objetivosAnalizados: objetivosDeUnidad,
        ),
      );
    }

    final totalObjsPlan = plan.totalObjetivos;
    final pctCoberturaGlobal = totalObjsPlan > 0
        ? double.parse(((contadorTotalEvaluados / totalObjsPlan) * 100.0).toStringAsFixed(1))
        : 0.0;

    final promDominioGlobal = porcentajesEvaluadosGlobal.isNotEmpty
        ? double.parse((porcentajesEvaluadosGlobal.reduce((a, b) => a + b) /
                porcentajesEvaluadosGlobal.length)
            .toStringAsFixed(1))
        : null;

    return MapaCoberturaCurricular(
      claseId: claseId,
      planCurricular: plan,
      totalObjetivosCurriculo: totalObjsPlan,
      totalObjetivosEvaluados: contadorTotalEvaluados,
      porcentajeCoberturaGlobal: pctCoberturaGlobal,
      promedioDominioGlobal: promDominioGlobal,
      unidades: unidadesAnalizadas,
      brechasEnsenanza: todasBrechasEnsenanza,
      brechasAprendizaje: todasBrechasAprendizaje,
    );
  }
}
