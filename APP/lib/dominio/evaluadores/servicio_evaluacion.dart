import '../modelos/algebraico.dart';
import '../modelos/aritmetico.dart';
import '../modelos/desarrollo.dart';
import '../modelos/ejercicio.dart';
import '../modelos/numerico.dart';
import '../modelos/resultado_evaluacion.dart';
import '../modelos/seleccion_multiple.dart';
import '../modelos/tipo_ejercicio.dart';
import 'evaluador_algebraico.dart';
import 'evaluador_aritmetico.dart';
import 'evaluador_desarrollo.dart';
import 'evaluador_numerico.dart';
import 'evaluador_seleccion_multiple.dart';

/// Servicio central de evaluación y corrección de ejercicios.
/// Soporta modo [offline] (algoritmos matemáticos locales) y [online] (modelo IA).
class ServicioEvaluacion {
  ServicioEvaluacion({
    this.modo = ModoEvaluacion.offline,
    this.evaluadorSeleccionMultiple = const EvaluadorSeleccionMultiple(),
    this.evaluadorNumerico = const EvaluadorNumerico(),
    this.evaluadorAlgebraico = const EvaluadorAlgebraico(),
    this.evaluadorDesarrollo = const EvaluadorDesarrollo(),
    this.evaluadorAritmetico = const EvaluadorAritmetico(),
  });

  /// Modo actual de evaluación (por defecto offline).
  ModoEvaluacion modo;

  final EvaluadorSeleccionMultiple evaluadorSeleccionMultiple;
  final EvaluadorNumerico evaluadorNumerico;
  final EvaluadorAlgebraico evaluadorAlgebraico;
  final EvaluadorDesarrollo evaluadorDesarrollo;
  final EvaluadorAritmetico evaluadorAritmetico;

  /// Evalúa la respuesta de cualquier [ejercicio] despachando al evaluador adecuado.
  Future<ResultadoEvaluacion> evaluar({
    required Ejercicio ejercicio,
    required dynamic respuesta,
  }) async {
    if (modo == ModoEvaluacion.online) {
      return _evaluarOnline(ejercicio, respuesta);
    }
    return _evaluarOffline(ejercicio, respuesta);
  }

  /// Evaluación local instantánea mediante algoritmos nativos.
  ResultadoEvaluacion _evaluarOffline(Ejercicio ejercicio, dynamic respuesta) {
    if (ejercicio is SeleccionMultiple) {
      return evaluadorSeleccionMultiple.evaluar(ejercicio, respuesta);
    } else if (ejercicio is Numerico) {
      return evaluadorNumerico.evaluar(ejercicio, respuesta);
    } else if (ejercicio is Algebraico) {
      return evaluadorAlgebraico.evaluar(ejercicio, respuesta);
    } else if (ejercicio is Desarrollo) {
      return evaluadorDesarrollo.evaluar(ejercicio, respuesta);
    } else if (ejercicio is Aritmetico) {
      return evaluadorAritmetico.evaluar(ejercicio, respuesta);
    }

    throw UnimplementedError(
      'No existe evaluador implementado para el tipo: ${ejercicio.tipo}',
    );
  }

  /// Evaluación mediante servicio remoto o modelo de IA (preparado para conexión).
  Future<ResultadoEvaluacion> _evaluarOnline(
    Ejercicio ejercicio,
    dynamic respuesta,
  ) async {
    // Por ahora realiza evaluación algorítmica local con distintivo de modo online
    final local = _evaluarOffline(ejercicio, respuesta);
    return ResultadoEvaluacion(
      esCorrecto: local.esCorrecto,
      puntaje: local.puntaje,
      retroalimentacion: '[Modo Online IA] ${local.retroalimentacion}',
      errorDetectado: local.errorDetectado,
      similitudLevenshtein: local.similitudLevenshtein,
      similitudJaccard: local.similitudJaccard,
      similitudCoseno: local.similitudCoseno,
      similitudHibrida: local.similitudHibrida,
      palabrasClaveEncontradas: local.palabrasClaveEncontradas,
      palabrasClaveFaltantes: local.palabrasClaveFaltantes,
    );
  }
}

