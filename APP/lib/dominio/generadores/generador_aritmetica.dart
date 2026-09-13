import 'dart:math';
import '../modelos/aritmetico.dart';
import '../modelos/posicion_curricular.dart';

/// Generador dinámico de preguntas y ejercicios de aritmética básica con etiquetado pedagógico.
class GeneradorAritmetica {
  GeneradorAritmetica({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Genera un ejercicio aritmético configurable según el nivel y operación deseada.
  Aritmetico generar({
    OperacionAritmetica? operacion,
    DisposicionAritmetica? disposicion,
    ElementoIncognita? incognita,
    int nivel = 1,
    PosicionCurricular? posicion,
    List<String>? tagsAdicionales,
  }) {
    final op = operacion ?? OperacionAritmetica.values[_random.nextInt(OperacionAritmetica.values.length)];

    int a = 0;
    int b = 1;

    switch (op) {
      case OperacionAritmetica.suma:
        if (nivel == 1) {
          a = _random.nextInt(9) + 1; // 1..9
          b = _random.nextInt(9) + 1; // 1..9
        } else if (nivel == 2) {
          a = _random.nextInt(90) + 10; // 10..99
          b = _random.nextInt(90) + 10; // 10..99
        } else {
          a = _random.nextInt(900) + 100; // 100..999
          b = _random.nextInt(900) + 100; // 100..999
        }
        break;

      case OperacionAritmetica.resta:
        if (nivel == 1) {
          final n1 = _random.nextInt(9) + 1;
          final n2 = _random.nextInt(9) + 1;
          a = max(n1, n2);
          b = min(n1, n2);
        } else if (nivel == 2) {
          final n1 = _random.nextInt(90) + 10;
          final n2 = _random.nextInt(90) + 10;
          a = max(n1, n2);
          b = min(n1, n2);
        } else {
          final n1 = _random.nextInt(900) + 100;
          final n2 = _random.nextInt(900) + 100;
          a = max(n1, n2);
          b = min(n1, n2);
        }
        break;

      case OperacionAritmetica.multiplicacion:
        if (nivel == 1) {
          a = _random.nextInt(9) + 2; // 2..10
          b = _random.nextInt(9) + 2; // 2..10
        } else if (nivel == 2) {
          a = _random.nextInt(90) + 10; // 10..99
          b = _random.nextInt(9) + 2;  // 2..10
        } else {
          a = _random.nextInt(90) + 10;  // 10..99
          b = _random.nextInt(90) + 10;  // 10..99
        }
        break;

      case OperacionAritmetica.division:
        if (nivel == 1) {
          // Divisiones exactas de tablas del 1 al 10
          final divisor = _random.nextInt(8) + 2; // 2..9
          final cociente = _random.nextInt(8) + 2; // 2..9
          a = divisor * cociente;
          b = divisor;
        } else if (nivel == 2) {
          b = _random.nextInt(8) + 2; // 2..9
          final cociente = _random.nextInt(20) + 10; // 10..29
          final resto = _random.nextInt(b);
          a = (cociente * b) + resto;
        } else {
          b = _random.nextInt(90) + 10; // 10..99
          final cociente = _random.nextInt(50) + 10;
          final resto = _random.nextInt(b);
          a = (cociente * b) + resto;
        }
        break;
    }

    // Elegir disposición si no fue forzada:
    final disp = disposicion ?? (a < 20 && b < 20 && op != OperacionAritmetica.division
        ? (_random.nextBool() ? DisposicionAritmetica.horizontal : DisposicionAritmetica.vertical)
        : (op == OperacionAritmetica.division && _random.nextInt(3) == 0
            ? DisposicionAritmetica.fraccion
            : DisposicionAritmetica.vertical));

    // Elegir incógnita si no fue forzada
    ElementoIncognita inc = incognita ?? ElementoIncognita.resultado;
    if (incognita == null) {
      if (op == OperacionAritmetica.division && disp == DisposicionAritmetica.vertical && (a % b != 0)) {
        inc = ElementoIncognita.cociente;
      } else {
        final r = _random.nextInt(10);
        if (r < 5) {
          inc = ElementoIncognita.resultado;
        } else if (r < 7) {
          inc = ElementoIncognita.operando2;
        } else if (r < 9) {
          inc = ElementoIncognita.operando1;
        } else {
          inc = ElementoIncognita.operador;
        }
      }
    }

    final pos = posicion ?? PosicionCurricular(tema: 1, subtema: op.index + 1, leccion: nivel);
    final id = 'ARIT-${pos.codigo}-${DateTime.now().millisecondsSinceEpoch % 10000}';
    final String enunciado = _crearEnunciado(op, a, b, inc, disp);

    // Detección y asignación automática de Tags
    final tags = <String>{'aritmetica', op.name};
    if (disp == DisposicionAritmetica.vertical) tags.add('vertical');
    if (disp == DisposicionAritmetica.horizontal) tags.add('horizontal');
    if (disp == DisposicionAritmetica.fraccion) tags.add('fraccion');

    if (op == OperacionAritmetica.suma && ((a % 10) + (b % 10) >= 10)) {
      tags.add('acarreo');
      tags.add('reagrupacion');
    }
    if (op == OperacionAritmetica.multiplicacion) {
      tags.add('tablas-multiplicar');
      if (a >= 10 || b >= 10) tags.add('acarreo');
    }
    if (op == OperacionAritmetica.division) {
      tags.add('division-galera');
      if (a % b != 0) tags.add('resto');
    }
    if (inc == ElementoIncognita.operando1 || inc == ElementoIncognita.operando2) {
      tags.add('despeje');
      tags.add('ecuaciones-casilla');
    }
    if (inc == ElementoIncognita.operador) {
      tags.add('signos');
      tags.add('operadores');
    }
    if (tagsAdicionales != null) {
      tags.addAll(tagsAdicionales);
    }

    return Aritmetico(
      id: id,
      posicion: pos,
      nivel: nivel,
      enunciado: enunciado,
      operacion: op,
      operando1: a,
      operando2: b,
      disposicion: disp,
      incognita: inc,
      tags: tags.toList(),
      puntos: nivel * 5 + 5,
      explicacion: 'Operación: $a ${op.simbolo} $b = ${(op == OperacionAritmetica.division ? a ~/ b : null)}',
    );
  }

  /// Genera un ejercicio de refuerzo adaptado exactamente a una lista de [tagsCriticos] donde el alumno falló.
  Aritmetico generarRefuerzoParaTags(List<String> tagsCriticos, {int nivel = 1}) {
    final tagsSet = tagsCriticos.map((t) => t.toLowerCase()).toSet();

    if (tagsSet.contains('acarreo') || tagsSet.contains('reagrupacion')) {
      // Forzar suma vertical con acarreo en unidades
      final a = (_random.nextInt(8) + 1) * 10 + (_random.nextInt(4) + 6); // ej. 37 (unidad >= 6)
      final b = (_random.nextInt(8) + 1) * 10 + (_random.nextInt(4) + 6); // ej. 48 (unidad >= 6)
      return Aritmetico(
        id: 'REF-ACARREO-${DateTime.now().millisecondsSinceEpoch % 10000}',
        posicion: const PosicionCurricular(tema: 1, subtema: 1, leccion: 1),
        nivel: nivel,
        enunciado: 'Práctica de Refuerzo: Suma vertical prestando atención a la cifra que llevas (acarreo):',
        operacion: OperacionAritmetica.suma,
        operando1: a,
        operando2: b,
        disposicion: DisposicionAritmetica.vertical,
        incognita: ElementoIncognita.resultado,
        tags: const ['refuerzo', 'aritmetica', 'suma', 'acarreo', 'vertical'],
        puntos: 15,
        explicacion: 'Suma $a + $b alineando unidades y sumando el acarreo a las decenas.',
      );
    }

    if (tagsSet.contains('tablas-multiplicar') || tagsSet.contains('multiplicacion')) {
      final factor = _random.nextInt(8) + 2; // 2..9
      final num = _random.nextInt(8) + 2;
      return Aritmetico(
        id: 'REF-TABLAS-${DateTime.now().millisecondsSinceEpoch % 10000}',
        posicion: const PosicionCurricular(tema: 1, subtema: 3, leccion: 1),
        nivel: nivel,
        enunciado: 'Práctica de Refuerzo: Repasa la tabla de multiplicar:',
        operacion: OperacionAritmetica.multiplicacion,
        operando1: factor,
        operando2: num,
        disposicion: DisposicionAritmetica.horizontal,
        incognita: ElementoIncognita.resultado,
        tags: const ['refuerzo', 'aritmetica', 'multiplicacion', 'tablas-multiplicar'],
        puntos: 10,
        explicacion: '$factor × $num = ${factor * num}.',
      );
    }

    if (tagsSet.contains('division-galera') || tagsSet.contains('resto') || tagsSet.contains('division')) {
      final divisor = _random.nextInt(7) + 2;
      final cociente = _random.nextInt(9) + 2;
      final resto = _random.nextInt(divisor - 1) + 1; // con resto garantizado
      final dividendo = (divisor * cociente) + resto;
      return Aritmetico(
        id: 'REF-DIV-${DateTime.now().millisecondsSinceEpoch % 10000}',
        posicion: const PosicionCurricular(tema: 1, subtema: 4, leccion: 1),
        nivel: nivel,
        enunciado: 'Práctica de Refuerzo: Realiza la división e introduce el cociente y el residuo:',
        operacion: OperacionAritmetica.division,
        operando1: dividendo,
        operando2: divisor,
        disposicion: DisposicionAritmetica.vertical,
        incognita: ElementoIncognita.cociente,
        tags: const ['refuerzo', 'aritmetica', 'division', 'division-galera', 'resto'],
        puntos: 15,
        explicacion: '$dividendo ÷ $divisor = $cociente con resto $resto ($resto + $cociente × $divisor = $dividendo).',
      );
    }

    if (tagsSet.contains('despeje') || tagsSet.contains('ecuaciones-casilla')) {
      return generar(
        operacion: OperacionAritmetica.resta,
        incognita: ElementoIncognita.operando1,
        disposicion: DisposicionAritmetica.vertical,
        tagsAdicionales: const ['refuerzo', 'despeje', 'ecuaciones-casilla'],
      );
    }

    // Por defecto generar práctica general de nivel
    return generar(nivel: nivel, tagsAdicionales: const ['refuerzo']);
  }

  String _crearEnunciado(
    OperacionAritmetica op,
    int a,
    int b,
    ElementoIncognita inc,
    DisposicionAritmetica disp,
  ) {
    switch (inc) {
      case ElementoIncognita.resultado:
        return 'Calcula el resultado de la siguiente operación:';
      case ElementoIncognita.operando1:
      case ElementoIncognita.dividendo:
        return 'Encuentra el valor faltante inicial para que la operación sea correcta:';
      case ElementoIncognita.operando2:
      case ElementoIncognita.divisor:
        return 'Encuentra el segundo valor faltante para que la operación se cumpla:';
      case ElementoIncognita.operador:
        return 'Determina cuál es el signo de la operación (+, -, ×, ÷) faltante:';
      case ElementoIncognita.cociente:
        return 'Realiza la división e ingresa el cociente:';
      case ElementoIncognita.resto:
        return 'Calcula el resto o residuo de la división:';
    }
  }
}
