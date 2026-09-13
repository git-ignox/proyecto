import 'dart:math';
import '../algoritmos/motor_similitud.dart';
import '../modelos/algebraico.dart';
import '../modelos/aritmetico.dart';
import '../modelos/desarrollo.dart';
import '../modelos/error_aprendizaje.dart';
import '../modelos/numerico.dart';
import '../modelos/seleccion_multiple.dart';

/// Clasificador determinista y pedagógico de errores matemáticos.
class ClasificadorErrores {
  const ClasificadorErrores();

  /// Identifica y categoriza el error cometido en un ejercicio [Aritmetico].
  ErrorAprendizaje clasificarAritmetico(Aritmetico ejercicio, dynamic respuesta) {
    final tags = List<String>.from(ejercicio.tags);

    // 1. Respuesta vacía o nula
    if (respuesta == null || (respuesta is String && respuesta.trim().isEmpty)) {
      return ErrorAprendizaje(
        id: 'ERR-SIN-RESPUESTA',
        categoria: CategoriaError.sintaxisFormato,
        subtipo: 'respuesta_vacia',
        descripcion: 'No se ingresó ninguna respuesta.',
        sugerenciaPedagogica: 'Intenta resolver el ejercicio antes de enviar la calificación.',
        tagsAsociados: tags,
        severidad: SeveridadError.leve,
      );
    }

    // 2. Error en incógnita de Operador (+, -, ×, ÷)
    if (ejercicio.incognita == ElementoIncognita.operador) {
      return ErrorAprendizaje(
        id: 'ERR-OPERADOR-INCORRECTO',
        categoria: CategoriaError.signoOperacion,
        subtipo: 'confusion_operador',
        descripcion: 'Se seleccionó una operación diferente a la requerida.',
        sugerenciaPedagogica: 'Observa la relación entre los números dados (${ejercicio.operando1} y ${ejercicio.operando2}) para obtener ${ejercicio.resultadoExacto}.',
        tagsAsociados: [...tags, 'operadores', 'signos'],
        severidad: SeveridadError.moderada,
      );
    }

    // 3. Error en divisiones con cociente y resto
    if (respuesta is Map) {
      final cocienteUsuario = _parsearNumero(respuesta['cociente']);
      final restoUsuario = _parsearNumero(respuesta['resto']);
      final cocienteEsperado = ejercicio.resultadoExacto;
      final restoEsperado = ejercicio.restoEsperado ?? 0;

      final cocienteOk = cocienteUsuario != null && (cocienteUsuario - cocienteEsperado).abs() <= ejercicio.tolerancia;
      final restoOk = restoUsuario != null && (restoUsuario - restoEsperado).abs() <= ejercicio.tolerancia;

      if (cocienteOk && !restoOk) {
        return ErrorAprendizaje(
          id: 'ERR-DIV-RESTO',
          categoria: CategoriaError.procedimientoAlgoritmo,
          subtipo: 'calculo_resto_incorrecto',
          descripcion: 'El cociente ($cocienteEsperado) fue correcto, pero el residuo/resto fue erróneo (esperado $restoEsperado).',
          sugerenciaPedagogica: 'Recuerda: Residuo = Dividendo - (Cociente × Divisor). En este caso: ${ejercicio.operando1} - ($cocienteEsperado × ${ejercicio.operando2}) = $restoEsperado.',
          tagsAsociados: [...tags, 'division-galera', 'resto', 'residuo'],
          severidad: SeveridadError.moderada,
        );
      } else if (!cocienteOk && restoOk) {
        return ErrorAprendizaje(
          id: 'ERR-DIV-COCIENTE',
          categoria: CategoriaError.calculoAritmetico,
          subtipo: 'cociente_incorrecto',
          descripcion: 'El resto fue correcto, pero el cociente fue incorrecto (esperado $cocienteEsperado).',
          sugerenciaPedagogica: 'Revisa cuántas veces cabe exactamente ${ejercicio.operando2} en ${ejercicio.operando1}.',
          tagsAsociados: [...tags, 'division-galera', 'cociente'],
          severidad: SeveridadError.moderada,
        );
      } else {
        return ErrorAprendizaje(
          id: 'ERR-DIV-GLOBAL',
          categoria: CategoriaError.procedimientoAlgoritmo,
          subtipo: 'algoritmo_division_fallido',
          descripcion: 'Fallo general tanto en cociente como en el resto de la división en galera.',
          sugerenciaPedagogica: 'Repasa el algoritmo de división paso a paso: dividir, multiplicar, restar y bajar la cifra siguiente.',
          tagsAsociados: [...tags, 'division-galera', 'procedimiento'],
          severidad: SeveridadError.critica,
        );
      }
    }

    final numIngresado = _parsearNumero(respuesta);
    if (numIngresado == null) {
      return ErrorAprendizaje(
        id: 'ERR-VALOR-NO-NUMERICO',
        categoria: CategoriaError.sintaxisFormato,
        subtipo: 'formato_invalido',
        descripcion: 'El texto ingresado no es un número válido.',
        sugerenciaPedagogica: 'Ingresa únicamente dígitos numéricos (ej. 42 o 3.5).',
        tagsAsociados: tags,
        severidad: SeveridadError.leve,
      );
    }

    final a = ejercicio.operando1;
    final b = ejercicio.operando2;
    final op = ejercicio.operacion;

    // 4. Diagnóstico de Despeje de Incógnita Intermedia
    if (ejercicio.incognita == ElementoIncognita.operando1 ||
        ejercicio.incognita == ElementoIncognita.operando2 ||
        ejercicio.incognita == ElementoIncognita.dividendo ||
        ejercicio.incognita == ElementoIncognita.divisor) {
      
      // En resta: [ ? ] - b = c (minuendo = c + b). Si el alumno hizo c - b:
      if (op == OperacionAritmetica.resta && ejercicio.incognita == ElementoIncognita.operando1) {
        final c = ejercicio.resultadoExacto;
        if ((numIngresado - (c - b)).abs() <= 0.001) {
          return ErrorAprendizaje(
            id: 'ERR-DESPEJE-MINUENDO',
            categoria: CategoriaError.despejeIncognita,
            subtipo: 'resta_en_vez_de_suma_para_minuendo',
            descripcion: 'Para hallar el número inicial (minuendo), restaste en lugar de sumar el resultado con el sustraendo.',
            sugerenciaPedagogica: 'Si ? - $b = $c, entonces ? = $c + $b = ${a.toInt()}. Al despejar, la resta pasa como suma.',
            tagsAsociados: [...tags, 'despeje', 'ecuaciones-casilla', 'minuendo'],
            severidad: SeveridadError.moderada,
          );
        }
      }

      return ErrorAprendizaje(
        id: 'ERR-DESPEJE-CASILLA',
        categoria: CategoriaError.despejeIncognita,
        subtipo: 'error_despeje_operando',
        descripcion: 'Fallo al encontrar el término faltante en la ecuación de casilla.',
        sugerenciaPedagogica: 'Utiliza la operación inversa para despejar la incógnita.',
        tagsAsociados: [...tags, 'despeje', 'ecuaciones-casilla'],
        severidad: SeveridadError.moderada,
      );
    }

    // 5. Diagnóstico de Error de Acarreo / Llevada en Suma (e.g. 125 + 78 = 193 en vez de 203)
    if (op == OperacionAritmetica.suma && a is int && b is int) {
      final sumaSinAcarreo = _calcularSumaSinAcarreo(a, b);
      if (numIngresado == sumaSinAcarreo && sumaSinAcarreo != (a + b)) {
        return ErrorAprendizaje(
          id: 'ERR-ACARREO-SUMA',
          categoria: CategoriaError.acarreoReagrupacion,
          subtipo: 'olvido_acarreo_llevada',
          descripcion: 'Olvidaste sumar las unidades llevadas (acarreo) a la columna de decenas/centenas.',
          sugerenciaPedagogica: 'Al sumar dígitos que dan 10 o más (como ${a % 10} + ${b % 10} = ${(a % 10) + (b % 10)}), anota la unidad y lleva la decena a la siguiente columna a la izquierda.',
          tagsAsociados: [...tags, 'acarreo', 'suma-vertical', 'llevadas'],
          severidad: SeveridadError.moderada,
        );
      }
    }

    // 6. Diagnóstico de Operación Invertida / Signo Contrario
    if (op == OperacionAritmetica.suma && (numIngresado - (a - b)).abs() <= 0.001) {
      return ErrorAprendizaje(
        id: 'ERR-OPERACION-RESTO-EN-VEZ-DE-SUMAR',
        categoria: CategoriaError.signoOperacion,
        subtipo: 'resto_en_lugar_de_sumar',
        descripcion: 'Realizaste una resta en lugar de una suma.',
        sugerenciaPedagogica: 'Presta atención al signo (+). Debes juntar o añadir cantidades, no restarlas.',
        tagsAsociados: [...tags, 'signos', 'suma'],
        severidad: SeveridadError.moderada,
      );
    }
    if (op == OperacionAritmetica.resta && (numIngresado - (a + b)).abs() <= 0.001) {
      return ErrorAprendizaje(
        id: 'ERR-OPERACION-SUMO-EN-VEZ-DE-RESTAR',
        categoria: CategoriaError.signoOperacion,
        subtipo: 'sumo_en_lugar_de_restar',
        descripcion: 'Realizaste una suma en lugar de una resta.',
        sugerenciaPedagogica: 'Presta atención al signo (-). Debes sustraer o quitar la segunda cantidad.',
        tagsAsociados: [...tags, 'signos', 'resta'],
        severidad: SeveridadError.moderada,
      );
    }

    // 7. Diagnóstico de Error en Tablas de Multiplicar
    if (op == OperacionAritmetica.multiplicacion && a is int && b is int) {
      final esperado = a * b;
      // Error cercano en tablas (ej. diferir por a o por b, o error de 1 factor)
      if ((numIngresado - (a * (b - 1))).abs() <= 0.001 ||
          (numIngresado - (a * (b + 1))).abs() <= 0.001 ||
          (numIngresado - ((a - 1) * b)).abs() <= 0.001 ||
          (numIngresado - ((a + 1) * b)).abs() <= 0.001) {
        return ErrorAprendizaje(
          id: 'ERR-TABLAS-MULTIPLICAR',
          categoria: CategoriaError.hechoNumerico,
          subtipo: 'error_tabla_multiplicar',
          descripcion: 'Error de cálculo en la tabla de multiplicar del $a o del $b.',
          sugerenciaPedagogica: 'Repasa la tabla del $a: $a × $b = $esperado. Puedes sumar $a veces el número $b.',
          tagsAsociados: [...tags, 'tablas-multiplicar', 'multiplicacion'],
          severidad: SeveridadError.moderada,
        );
      }
    }

    // 8. Error general de cálculo
    return ErrorAprendizaje(
      id: 'ERR-CALCULO-ARITMETICO',
      categoria: CategoriaError.calculoAritmetico,
      subtipo: 'calculo_incorrecto',
      descripcion: 'El resultado numérico calculado no coincide con la solución exacta.',
      sugerenciaPedagogica: 'Vuelve a repasar cada paso de la operación en columna prestando atención a los cálculos intermedios.',
      tagsAsociados: tags,
      severidad: SeveridadError.moderada,
    );
  }

  /// Calcula la suma "columna a columna" ignorando a propósito los acarreos para detectar el patrón.
  int _calcularSumaSinAcarreo(int a, int b) {
    String sA = a.toString();
    String sB = b.toString();
    int maxL = max(sA.length, sB.length);
    sA = sA.padLeft(maxL, '0');
    sB = sB.padLeft(maxL, '0');

    String res = '';
    for (int i = 0; i < maxL; i++) {
      int dA = int.parse(sA[i]);
      int dB = int.parse(sB[i]);
      int sumCol = (dA + dB) % 10;
      res += sumCol.toString();
    }
    return int.tryParse(res) ?? (a + b);
  }

  /// Diagnóstico para ejercicios de tipo [Numerico].
  ErrorAprendizaje clasificarNumerico(Numerico ejercicio, dynamic respuesta, double? valorIngresado) {
    final tags = List<String>.from(ejercicio.tags);

    if (valorIngresado == null) {
      return ErrorAprendizaje(
        id: 'ERR-NUM-FORMATO',
        categoria: CategoriaError.sintaxisFormato,
        subtipo: 'numero_no_reconocido',
        descripcion: 'No se pudo interpretar el número o fracción ingresada.',
        sugerenciaPedagogica: 'Utiliza formato decimal con punto o coma (ej. 3.14) o fracción simple (ej. 3/4).',
        tagsAsociados: tags,
        severidad: SeveridadError.leve,
      );
    }

    // Error de signo opuesto
    if ((valorIngresado + ejercicio.valorEsperado).abs() <= ejercicio.tolerancia) {
      return ErrorAprendizaje(
        id: 'ERR-NUM-SIGNO',
        categoria: CategoriaError.signoOperacion,
        subtipo: 'signo_opuesto',
        descripcion: 'El valor tiene la magnitud correcta pero el signo opuesto.',
        sugerenciaPedagogica: 'Revisa la regla de los signos: el resultado debe ser ${ejercicio.valorEsperado > 0 ? "positivo (+)" : "negativo (-)"}.',
        tagsAsociados: [...tags, 'signos'],
        severidad: SeveridadError.moderada,
      );
    }

    // Error de redondeo / aproximación
    final dif = (valorIngresado - ejercicio.valorEsperado).abs();
    if (dif <= ejercicio.tolerancia * 15) {
      return ErrorAprendizaje(
        id: 'ERR-NUM-PRECISION',
        categoria: CategoriaError.precisionRedondeo,
        subtipo: 'error_redondeo_decimal',
        descripcion: 'Tu valor está muy cerca de la respuesta exacta pero excede la tolerancia permitida.',
        sugerenciaPedagogica: 'Revisa el redondeo de los últimos decimales o conserva las fracciones hasta el paso final.',
        tagsAsociados: [...tags, 'redondeo', 'precision-decimal'],
        severidad: SeveridadError.leve,
      );
    }

    return ErrorAprendizaje(
      id: 'ERR-NUM-VALOR-INCORRECTO',
      categoria: CategoriaError.calculoAritmetico,
      subtipo: 'valor_numerico_incorrecto',
      descripcion: 'El valor numérico difiere del valor esperado (${ejercicio.valorEsperado}).',
      sugerenciaPedagogica: 'Verifica los pasos del planteamiento y el cálculo final.',
      tagsAsociados: tags,
      severidad: SeveridadError.moderada,
    );
  }

  /// Diagnóstico para ejercicios de tipo [Algebraico].
  ErrorAprendizaje clasificarAlgebraico(Algebraico ejercicio, String entradaNorm, String canonicaNorm) {
    final tags = List<String>.from(ejercicio.tags);

    return ErrorAprendizaje(
      id: 'ERR-ALG-EXPRESION',
      categoria: CategoriaError.comprensionConceptual,
      subtipo: 'expresion_algebraica_discrepante',
      descripcion: 'La expresión algebraica simplificada no coincide con la forma canónica esperada: ${ejercicio.expresionCanonica}.',
      sugerenciaPedagogica: 'Aplica factorización o reducción de términos semejantes paso a paso respetando la propiedad distributiva y los signos.',
      tagsAsociados: [...tags, 'algebra', 'factorizacion', 'simplificacion'],
      severidad: SeveridadError.moderada,
    );
  }

  /// Diagnóstico para respuestas de tipo [Desarrollo] con análisis de similitud.
  ErrorAprendizaje clasificarDesarrollo(Desarrollo ejercicio, AnalisisSimilitud analisis) {
    final tags = List<String>.from(ejercicio.tags);

    if (analisis.palabrasClaveFaltantes.isNotEmpty) {
      return ErrorAprendizaje(
        id: 'ERR-DES-CONCEPTOS-FALTANTES',
        categoria: CategoriaError.comprensionConceptual,
        subtipo: 'conceptos_clave_omitidos',
        descripcion: 'Faltaron conceptos indispensables en el desarrollo: ${analisis.palabrasClaveFaltantes.join(", ")}.',
        sugerenciaPedagogica: 'Asegúrate de explicar y calcular explícitamente: ${analisis.palabrasClaveFaltantes.join(", ")}.',
        tagsAsociados: [...tags, 'desarrollo', 'conceptos-clave'],
        severidad: SeveridadError.moderada,
      );
    }

    return ErrorAprendizaje(
      id: 'ERR-DES-SIMILITUD-BAJA',
      categoria: CategoriaError.procedimientoAlgoritmo,
      subtipo: 'procedimiento_incompleto',
      descripcion: 'El procedimiento o justificación se aleja de la solución modelo estructurada.',
      sugerenciaPedagogica: 'Escribe de forma detallada y ordenada cada paso matemático del razonamiento.',
      tagsAsociados: [...tags, 'procedimiento', 'desarrollo'],
      severidad: SeveridadError.moderada,
    );
  }

  /// Diagnóstico para ejercicios de tipo [SeleccionMultiple].
  ErrorAprendizaje clasificarSeleccionMultiple(SeleccionMultiple ejercicio, List<String> seleccionados) {
    final tags = List<String>.from(ejercicio.tags);

    if (seleccionados.isEmpty) {
      return ErrorAprendizaje(
        id: 'ERR-SM-SIN-SELECCION',
        categoria: CategoriaError.sintaxisFormato,
        subtipo: 'sin_opcion_seleccionada',
        descripcion: 'No seleccionaste ninguna alternativa.',
        sugerenciaPedagogica: 'Elige una de las opciones disponibles antes de calificar.',
        tagsAsociados: tags,
        severidad: SeveridadError.leve,
      );
    }

    // Buscar si la opción elegida tiene retroalimentación específica
    String descripcion = 'Se eligió una opción incorrecta (distractor).';
    if (seleccionados.length == 1) {
      final opcion = ejercicio.opciones.firstWhere(
        (o) => o.id == seleccionados.first,
        orElse: () => const Opcion(id: '', texto: '', esCorrecta: false),
      );
      if (opcion.retroalimentacion != null && opcion.retroalimentacion!.isNotEmpty) {
        descripcion = opcion.retroalimentacion!;
      }
    }

    return ErrorAprendizaje(
      id: 'ERR-SM-DISTRACTOR',
      categoria: CategoriaError.comprensionConceptual,
      subtipo: 'opcion_distractor_seleccionada',
      descripcion: descripcion,
      sugerenciaPedagogica: 'Descarta las alternativas que no cumplan con las propiedades matemáticas del enunciado.',
      tagsAsociados: [...tags, 'seleccion-multiple'],
      severidad: SeveridadError.moderada,
    );
  }

  double? _parsearNumero(dynamic val) {
    if (val == null) return null;
    final str = val.toString().trim().replaceAll(',', '.');
    if (str.contains('/')) {
      final partes = str.split('/');
      if (partes.length == 2) {
        final num = double.tryParse(partes[0].trim());
        final den = double.tryParse(partes[1].trim());
        if (num != null && den != null && den != 0) {
          return num / den;
        }
      }
    }
    return double.tryParse(str);
  }
}
