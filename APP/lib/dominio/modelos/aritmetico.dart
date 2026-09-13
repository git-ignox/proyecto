import 'ejercicio.dart';
import 'tipo_ejercicio.dart';

/// Operaciones aritméticas básicas soportadas.
enum OperacionAritmetica {
  suma,
  resta,
  multiplicacion,
  division;

  String get simbolo {
    switch (this) {
      case OperacionAritmetica.suma:
        return '+';
      case OperacionAritmetica.resta:
        return '-';
      case OperacionAritmetica.multiplicacion:
        return '×';
      case OperacionAritmetica.division:
        return '÷';
    }
  }

  String get simboloDivisionGalera => '|';
}

/// Disposición visual de la operación en pantalla.
enum DisposicionAritmetica {
  /// Disposición vertical tradicional en columna o división en galera.
  vertical,

  /// Disposición corta en una sola línea (ej. 7 × 8 = 56).
  horizontal,

  /// Disposición de fracción matemática (a / b).
  fraccion,
}

/// Parte de la operación que constituye la incógnita a resolver por el usuario.
enum ElementoIncognita {
  /// El resultado final c (ej. 7 + 8 = [ ? ] o c en división).
  resultado,

  /// El primer número a (ej. [ ? ] + 8 = 15).
  operando1,

  /// El segundo número b (ej. 7 + [ ? ] = 15).
  operando2,

  /// El operador aritmético (ej. 7 [ ? ] 8 = 15 -> '+').
  operador,

  /// En división tradicional: el cociente c.
  cociente,

  /// En división tradicional: el resto o residuo d.
  resto,

  /// En división tradicional: el dividendo a.
  dividendo,

  /// En división tradicional: el divisor b.
  divisor,
}

/// Ejercicio de aritmética básica visual.
class Aritmetico extends Ejercicio {
  const Aritmetico({
    required super.id,
    required super.posicion,
    required super.nivel,
    required super.enunciado,
    required this.operacion,
    required this.operando1,
    required this.operando2,
    this.disposicion = DisposicionAritmetica.vertical,
    this.incognita = ElementoIncognita.resultado,
    this.resultadoCalculado,
    this.restoCalculado,
    this.tolerancia = 0.0001,
    super.tags,
    super.pistas,
    super.explicacion,
    super.puntos = 10,
  });

  /// Tipo de operación: suma, resta, multiplicación o división.
  final OperacionAritmetica operacion;

  /// Primer operando o dividendo (a).
  final num operando1;

  /// Segundo operando o divisor (b).
  final num operando2;

  /// Disposición visual: vertical (columna/galera), horizontal (en línea) o fracción.
  final DisposicionAritmetica disposicion;

  /// Elemento que actúa como incógnita a rellenar por el alumno.
  final ElementoIncognita incognita;

  /// Resultado esperado predefinido (si es null se calcula matemáticamente).
  final num? resultadoCalculado;

  /// Resto o residuo esperado en divisiones con resto.
  final int? restoCalculado;

  /// Tolerancia permitida para comparaciones numéricas.
  final double tolerancia;

  @override
  TipoEjercicio get tipo => TipoEjercicio.aritmetico;

  /// Obtiene el resultado matemático exacto de la operación.
  num get resultadoExacto {
    if (resultadoCalculado != null) return resultadoCalculado!;
    switch (operacion) {
      case OperacionAritmetica.suma:
        return operando1 + operando2;
      case OperacionAritmetica.resta:
        return operando1 - operando2;
      case OperacionAritmetica.multiplicacion:
        return operando1 * operando2;
      case OperacionAritmetica.division:
        if (operando2 == 0) return 0;
        // Si tiene resto entero esperado, el cociente es entero
        if (restoEsperado != null || (operando1 is int && operando2 is int)) {
          return (operando1 ~/ operando2);
        }
        return operando1 / operando2;
    }
  }

  /// Obtiene el resto exacto si es división entera.
  int? get restoEsperado {
    if (restoCalculado != null) return restoCalculado;
    if (operacion == OperacionAritmetica.division && operando1 is int && operando2 is int && operando2 != 0) {
      return (operando1 as int) % (operando2 as int);
    }
    return null;
  }

  /// Devuelve la respuesta correcta en formato String según el elemento incógnita.
  String get respuestaCorrectaTexto {
    switch (incognita) {
      case ElementoIncognita.operando1:
      case ElementoIncognita.dividendo:
        return _formatearNumero(operando1);
      case ElementoIncognita.operando2:
      case ElementoIncognita.divisor:
        return _formatearNumero(operando2);
      case ElementoIncognita.operador:
        return operacion.simbolo;
      case ElementoIncognita.cociente:
      case ElementoIncognita.resultado:
        return _formatearNumero(resultadoExacto);
      case ElementoIncognita.resto:
        return (restoEsperado ?? 0).toString();
    }
  }

  String _formatearNumero(num n) {
    if (n is int || n == n.roundToDouble()) {
      return n.toInt().toString();
    }
    return n.toString();
  }
}

