import '../modelos/diagnostico_alumno.dart';
import '../modelos/error_aprendizaje.dart';
import '../modelos/intento_evaluacion.dart';

/// Motor analítico que procesa el historial de intentos del estudiante,
/// categoriza los errores, detecta los prominentes y genera el plan de ayuda pedagógica.
class AnalizadorDiagnostico {
  const AnalizadorDiagnostico();

  /// Genera el diagnóstico completo de un alumno a partir de su lista cronológica de [intentos].
  DiagnosticoAlumno analizar({
    required String usuarioUid,
    required List<IntentoEvaluacion> intentos,
  }) {
    if (intentos.isEmpty) {
      return DiagnosticoAlumno.vacio(usuarioUid);
    }

    final total = intentos.length;
    final aciertos = intentos.where((i) => i.esCorrecto).length;
    final errores = total - aciertos;
    final precision = total > 0 ? (aciertos / total) * 100.0 : 100.0;

    final distribucionPorCategoria = <CategoriaError, int>{};
    final distribucionPorTag = <String, int>{};
    final mapaErrores = <String, _AgrupadorError>{};

    for (final intento in intentos) {
      if (!intento.esCorrecto && intento.error != null) {
        final err = intento.error!;

        // Distribución por Categoría
        distribucionPorCategoria[err.categoria] =
            (distribucionPorCategoria[err.categoria] ?? 0) + 1;

        // Distribución por Tags del intento y del error
        final todosLosTags = {...intento.tags, ...err.tagsAsociados};
        for (final tag in todosLosTags) {
          final tagNorm = tag.trim().toLowerCase();
          if (tagNorm.isNotEmpty) {
            distribucionPorTag[tagNorm] = (distribucionPorTag[tagNorm] ?? 0) + 1;
          }
        }

        // Agrupación de errores específicos
        final clave = '${err.categoria.name}:${err.subtipo}';
        if (!mapaErrores.containsKey(clave)) {
          mapaErrores[clave] = _AgrupadorError(
            categoria: err.categoria,
            subtipo: err.subtipo,
            descripcion: err.descripcion,
            sugerenciaDocente: err.sugerenciaPedagogica,
            severidad: err.severidad,
          );
        }
        mapaErrores[clave]!.conteo++;
        mapaErrores[clave]!.tags.addAll(todosLosTags);
      }
    }

    // 1. Detección de Errores Prominentes (ordenados por recurrencia y severidad)
    final erroresProminentes = mapaErrores.values.map((agrupador) {
      return ResumenErrorProminente(
        categoria: agrupador.categoria,
        subtipo: agrupador.subtipo,
        descripcion: agrupador.descripcion,
        conteo: agrupador.conteo,
        tagsRelacionados: agrupador.tags.toList(),
        severidad: agrupador.severidad,
        sugerenciaDocente: agrupador.sugerenciaDocente,
      );
    }).toList()
      ..sort((a, b) {
        final cmpConteo = b.conteo.compareTo(a.conteo);
        if (cmpConteo != 0) return cmpConteo;
        return b.severidad.index.compareTo(a.severidad.index);
      });

    // 2. Detección de Tags Críticos (tags con >= 2 fallos o más prominentes)
    final tagsOrdenados = distribucionPorTag.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final tagsCriticos = tagsOrdenados
        .where((e) => e.value >= 2)
        .map((e) => e.key)
        .toList();

    // Si no hay ninguno con >= 2 pero hay errores, tomar el más frecuente
    if (tagsCriticos.isEmpty && tagsOrdenados.isNotEmpty) {
      tagsCriticos.add(tagsOrdenados.first.key);
    }

    // 3. Generación de Recomendaciones de Ayuda Pedagógica ("En qué se debe de ayudar")
    final recomendaciones = _generarRecomendaciones(
      erroresProminentes: erroresProminentes,
      distribucionPorTag: distribucionPorTag,
      precisionGlobal: precision,
    );

    return DiagnosticoAlumno(
      usuarioUid: usuarioUid,
      totalIntentos: total,
      aciertos: aciertos,
      errores: errores,
      porcentajePrecision: double.parse(precision.toStringAsFixed(1)),
      distribucionPorCategoria: distribucionPorCategoria,
      distribucionPorTag: distribucionPorTag,
      erroresProminentes: erroresProminentes,
      tagsCriticos: tagsCriticos,
      recomendacionesRefuerzo: recomendaciones,
    );
  }

  /// Construye las recomendaciones concretas y personalizadas de intervención didáctica.
  List<RecomendacionPedagogica> _generarRecomendaciones({
    required List<ResumenErrorProminente> erroresProminentes,
    required Map<String, int> distribucionPorTag,
    required double precisionGlobal,
  }) {
    final recomendaciones = <RecomendacionPedagogica>[];

    for (final err in erroresProminentes) {
      PrioridadAyuda prioridad;
      if (err.conteo >= 3 || err.severidad == SeveridadError.critica) {
        prioridad = PrioridadAyuda.alta;
      } else if (err.conteo == 2) {
        prioridad = PrioridadAyuda.media;
      } else {
        prioridad = PrioridadAyuda.preventiva;
      }

      String titulo;
      String explicacion;
      String accion;

      switch (err.categoria) {
        case CategoriaError.acarreoReagrupacion:
          titulo = 'Refuerzo de Acarreo y Llevadas';
          explicacion = 'Se han detectado ${err.conteo} fallos al reagrupar o sumar el acarreo en las columnas superiores.';
          accion = 'Realizar una serie de 3 sumas en columna de nivel 1 marcando visualmente la cifra que llevas arriba.';
          break;

        case CategoriaError.signoOperacion:
          titulo = 'Atención a Signos y Operaciones Inversas';
          explicacion = 'Se detectó confusión recurrente entre sumar y restar (+ / -) o al cambiar de signo (${err.conteo} veces).';
          accion = 'Revisar la ley de los signos y verificar el símbolo de la operación antes de calcular.';
          break;

        case CategoriaError.hechoNumerico:
          titulo = 'Refuerzo de Tablas de Multiplicar';
          explicacion = 'Hay dificultad en multiplicaciones básicas (${err.conteo} errores registrados).';
          accion = 'Repasar las tablas de multiplicar correspondientes mediante ejercicios cortos en línea horizontal.';
          break;

        case CategoriaError.procedimientoAlgoritmo:
          titulo = 'Pasos del Algoritmo Matemático';
          explicacion = 'Se identificaron omisiones en la secuencia de pasos (ej. cálculo del resto o jerarquía).';
          accion = 'Practicar divisiones en galera paso a paso anotando cociente y residuo de forma estructurada.';
          break;

        case CategoriaError.despejeIncognita:
          titulo = 'Despeje de Ecuaciones de Casilla';
          explicacion = 'Fallo al encontrar operandos intermedios mediante la operación contraria (${err.conteo} fallos).';
          accion = 'Recordar que para despejar el término inicial: Si [ ? ] - b = c, entonces [ ? ] = c + b.';
          break;

        case CategoriaError.comprensionConceptual:
          titulo = 'Comprensión y Conceptos Clave';
          explicacion = 'Se omitieron términos fundamentales en el desarrollo o se seleccionaron distractores conceptuales.';
          accion = 'Leer con calma el problema e identificar las palabras clave antes de escribir el desarrollo.';
          break;

        case CategoriaError.precisionRedondeo:
          titulo = 'Precisión Decimal y Redondeo';
          explicacion = 'Las respuestas estuvieron muy próximas pero fuera de la tolerancia permitida.';
          accion = 'Mantener al menos 3 decimales o conservar las fracciones durante los cálculos intermedios.';
          break;

        default:
          titulo = 'Refuerzo de Cálculo General';
          explicacion = 'Se registraron ${err.conteo} discrepancias en el cálculo final.';
          accion = 'Realizar práctica guiada en el tema con verificación paso a paso.';
          break;
      }

      recomendaciones.add(RecomendacionPedagogica(
        id: 'REC-${err.categoria.name}-${err.subtipo}',
        titulo: titulo,
        explicacion: explicacion,
        prioridad: prioridad,
        tagsParaReforzar: err.tagsRelacionados,
        accionSugerida: accion,
      ));
    }

    // Si la precisión es excelente y no hay errores, recomendación positiva
    if (recomendaciones.isEmpty) {
      recomendaciones.add(const RecomendacionPedagogica(
        id: 'REC-EXCELENCIA',
        titulo: '¡Excelente Dominio Matemático!',
        explicacion: 'No se detectan errores prominentes en el historial reciente.',
        prioridad: PrioridadAyuda.preventiva,
        tagsParaReforzar: ['avanzado', 'retos'],
        accionSugerida: 'Continúa practicando retos de nivel 2 y 3 para seguir subiendo de nivel.',
      ));
    }

    return recomendaciones;
  }
}

class _AgrupadorError {
  _AgrupadorError({
    required this.categoria,
    required this.subtipo,
    required this.descripcion,
    required this.sugerenciaDocente,
    required this.severidad,
  });

  final CategoriaError categoria;
  final String subtipo;
  final String descripcion;
  final String sugerenciaDocente;
  final SeveridadError severidad;
  int conteo = 0;
  final Set<String> tags = {};
}
