import '../diagnostico/clasificador_errores.dart';
import '../modelos/aritmetico.dart';
import '../modelos/resultado_evaluacion.dart';

/// Evaluador especializado en operaciones aritméticas básicas y ecuaciones de casilla.
class EvaluadorAritmetico {
  const EvaluadorAritmetico({
    this.clasificador = const ClasificadorErrores(),
  });

  final ClasificadorErrores clasificador;

  ResultadoEvaluacion evaluar(Aritmetico ejercicio, dynamic respuesta) {
    if (respuesta == null || (respuesta is String && respuesta.trim().isEmpty)) {
      final err = clasificador.clasificarAritmetico(ejercicio, respuesta);
      return ResultadoEvaluacion(
        esCorrecto: false,
        puntaje: 0.0,
        retroalimentacion: 'Debes ingresar una respuesta para calificar.',
        errorDetectado: err,
      );
    }

    // Evaluación para incógnita de Operador (+, -, ×, ÷)
    if (ejercicio.incognita == ElementoIncognita.operador) {
      final respTexto = respuesta.toString().trim();
      final esCorrecto = _normalizarOperador(respTexto) == _normalizarOperador(ejercicio.operacion.simbolo);
      final err = esCorrecto ? null : clasificador.clasificarAritmetico(ejercicio, respuesta);
      return ResultadoEvaluacion(
        esCorrecto: esCorrecto,
        puntaje: esCorrecto ? 1.0 : 0.0,
        retroalimentacion: esCorrecto
            ? '¡Excelente! La operación correcta es "${ejercicio.operacion.simbolo}".'
            : 'Incorrecto. La operación requerida era "${ejercicio.operacion.simbolo}" para que ${ejercicio.operando1} ${ejercicio.operacion.simbolo} ${ejercicio.operando2} = ${ejercicio.resultadoExacto}.',
        errorDetectado: err,
      );
    }

    // Evaluación cuando la respuesta es un Map con cociente y resto en divisiones
    if (respuesta is Map) {
      final cocienteUsuario = _parsearNumero(respuesta['cociente']);
      final restoUsuario = _parsearNumero(respuesta['resto']);

      final cocienteEsperado = ejercicio.resultadoExacto;
      final restoEsperado = ejercicio.restoEsperado ?? 0;

      final cocienteOk = cocienteUsuario != null && (cocienteUsuario - cocienteEsperado).abs() <= ejercicio.tolerancia;
      final restoOk = restoUsuario != null && (restoUsuario - restoEsperado).abs() <= ejercicio.tolerancia;

      if (cocienteOk && restoOk) {
        return ResultadoEvaluacion(
          esCorrecto: true,
          puntaje: 1.0,
          retroalimentacion: '¡Excelente! Cociente: $cocienteEsperado, Resto: $restoEsperado. ($restoEsperado + $cocienteEsperado × ${ejercicio.operando2} = ${ejercicio.operando1}).',
        );
      } else {
        final err = clasificador.clasificarAritmetico(ejercicio, respuesta);
        if (cocienteOk || restoOk) {
          return ResultadoEvaluacion(
            esCorrecto: false,
            puntaje: 0.5,
            retroalimentacion: cocienteOk
                ? 'Cociente correcto ($cocienteEsperado), pero el resto esperado era $restoEsperado.'
                : 'Resto correcto ($restoEsperado), pero el cociente esperado era $cocienteEsperado.',
            errorDetectado: err,
          );
        } else {
          return ResultadoEvaluacion(
            esCorrecto: false,
            puntaje: 0.0,
            retroalimentacion: 'Incorrecto. Para ${ejercicio.operando1} ÷ ${ejercicio.operando2}: Cociente = $cocienteEsperado, Resto = $restoEsperado.',
            errorDetectado: err,
          );
        }
      }
    }

    // Evaluación numérica estándar para cualquier incógnita (operando1, operando2, resultado, cociente, resto)
    final numIngresado = _parsearNumero(respuesta);
    if (numIngresado == null) {
      final err = clasificador.clasificarAritmetico(ejercicio, respuesta);
      return ResultadoEvaluacion(
        esCorrecto: false,
        puntaje: 0.0,
        retroalimentacion: 'Ingresa un valor numérico válido (ej. 42 o -5).',
        errorDetectado: err,
      );
    }

    final esperadoStr = ejercicio.respuestaCorrectaTexto;
    final esperadoNum = double.tryParse(esperadoStr);

    bool esCorrecto = false;
    if (esperadoNum != null) {
      esCorrecto = (numIngresado - esperadoNum).abs() <= ejercicio.tolerancia;
    } else {
      esCorrecto = numIngresado.toString() == esperadoStr;
    }

    final err = esCorrecto ? null : clasificador.clasificarAritmetico(ejercicio, respuesta);
    final explicacionPedagogica = _generarExplicacion(ejercicio, esCorrecto);

    return ResultadoEvaluacion(
      esCorrecto: esCorrecto,
      puntaje: esCorrecto ? 1.0 : 0.0,
      retroalimentacion: explicacionPedagogica,
      errorDetectado: err,
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

  String _normalizarOperador(String op) {
    final limpio = op.trim().toLowerCase();
    if (limpio == '*' || limpio == 'x' || limpio == '·' || limpio == '×') return '×';
    if (limpio == '/' || limpio == '÷' || limpio == ':') return '÷';
    if (limpio == '+') return '+';
    if (limpio == '-') return '-';
    return limpio;
  }

  String _generarExplicacion(Aritmetico ejercicio, bool correcto) {
    final opSimbolo = ejercicio.operacion.simbolo;
    final a = ejercicio.operando1;
    final b = ejercicio.operando2;
    final c = ejercicio.resultadoExacto;

    if (correcto) {
      switch (ejercicio.incognita) {
        case ElementoIncognita.resultado:
        case ElementoIncognita.cociente:
          return '¡Correcto! $a $opSimbolo $b = $c.';
        case ElementoIncognita.operando1:
        case ElementoIncognita.dividendo:
          return '¡Correcto! La incógnita es $a ($a $opSimbolo $b = $c).';
        case ElementoIncognita.operando2:
        case ElementoIncognita.divisor:
          return '¡Correcto! La incógnita es $b ($a $opSimbolo $b = $c).';
        case ElementoIncognita.resto:
          return '¡Correcto! El resto es ${ejercicio.restoEsperado}.';
        case ElementoIncognita.operador:
          return '¡Correcto! La operación es $opSimbolo.';
      }
    }

    // Explicación cuando es incorrecto
    switch (ejercicio.incognita) {
      case ElementoIncognita.resultado:
      case ElementoIncognita.cociente:
        return 'Incorrecto. $a $opSimbolo $b = $c. (Tu respuesta no coincide con el resultado exacto).';
      case ElementoIncognita.operando1:
      case ElementoIncognita.dividendo:
        return 'Incorrecto. El número inicial faltante era $a, ya que $a $opSimbolo $b = $c.';
      case ElementoIncognita.operando2:
      case ElementoIncognita.divisor:
        return 'Incorrecto. El segundo número faltante era $b, ya que $a $opSimbolo $b = $c.';
      case ElementoIncognita.resto:
        return 'Incorrecto. El resto esperado para $a ÷ $b era ${ejercicio.restoEsperado}.';
      case ElementoIncognita.operador:
        return 'Incorrecto. El operador correcto es $opSimbolo.';
    }
  }
}
