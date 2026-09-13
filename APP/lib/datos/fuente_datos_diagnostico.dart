import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../dominio/diagnostico/analizador_diagnostico.dart';
import '../dominio/modelos/aritmetico.dart';
import '../dominio/modelos/diagnostico_alumno.dart';
import '../dominio/modelos/examen_diagnostico.dart';
import '../dominio/modelos/intento_evaluacion.dart';
import '../dominio/modelos/posicion_curricular.dart';
import '../dominio/modelos/progreso_examen_alumno.dart';
import '../dominio/modelos/seleccion_multiple.dart';
import 'repositorio_diagnostico.dart';

/// Implementación en memoria con persistencia opcional en Firestore y emisión reactiva por Stream.
class FuenteDatosDiagnostico implements RepositorioDiagnostico {
  FuenteDatosDiagnostico({
    FirebaseFirestore? firestore,
    AnalizadorDiagnostico? analizador,
    List<ExamenDiagnostico>? examenesIniciales,
  })  : _customFirestore = firestore,
        _analizador = analizador ?? const AnalizadorDiagnostico() {
    if (examenesIniciales != null) {
      _examenes.addAll(examenesIniciales);
    } else {
      _cargarExamenPredeterminado();
    }
  }

  final FirebaseFirestore? _customFirestore;
  final AnalizadorDiagnostico _analizador;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  final List<IntentoEvaluacion> _intentos = [];
  final List<ExamenDiagnostico> _examenes = [];
  final List<ProgresoExamenAlumno> _progresos = [];

  final StreamController<Map<String, DiagnosticoAlumno>> _diagnosticoController =
      StreamController<Map<String, DiagnosticoAlumno>>.broadcast();

  void _cargarExamenPredeterminado() {
    _examenes.add(
      ExamenDiagnostico(
        id: 'EXAM-DIAG-01',
        titulo: 'Diagnóstico Inicial de Operaciones Básicas y Aritmética',
        descripcion: 'Evaluación diagnóstica para determinar el dominio en sumas con acarreo, restas, tablas y despeje de casilla.',
        profesorUid: 'profesor_demo',
        profesorNombre: 'Prof. Martínez',
        tagsEvaluados: const ['aritmetica', 'suma', 'acarreo', 'resta', 'tablas-multiplicar', 'despeje'],
        // Variable de avance determinada por el profesor (75% de aciertos mínimos)
        criterioAvance: CriterioAvance.porcentajeAciertosMinimo,
        umbralAvance: 0.75,
        permitirAvanceAutomatico: true,
        temaDestinoAlAvanzar: 'Tema 2: Ecuaciones y Álgebra Intermedia',
        tiempoLimiteMinutos: 30,
        fechaCreacion: DateTime.now(),
        ejercicios: const [
          Aritmetico(
            id: 'DIAG-EJ-1',
            posicion: PosicionCurricular(tema: 1, subtema: 1, leccion: 1),
            nivel: 1,
            enunciado: 'Calcula la suma en columna: 247 + 185',
            operacion: OperacionAritmetica.suma,
            operando1: 247,
            operando2: 185,
            disposicion: DisposicionAritmetica.vertical,
            incognita: ElementoIncognita.resultado,
            tags: ['aritmetica', 'suma', 'acarreo'],
            puntos: 10,
          ),
          Aritmetico(
            id: 'DIAG-EJ-2',
            posicion: PosicionCurricular(tema: 1, subtema: 2, leccion: 1),
            nivel: 1,
            enunciado: 'Resuelve la resta: 150 - 65',
            operacion: OperacionAritmetica.resta,
            operando1: 150,
            operando2: 65,
            disposicion: DisposicionAritmetica.vertical,
            incognita: ElementoIncognita.resultado,
            tags: ['aritmetica', 'resta', 'reagrupacion'],
            puntos: 10,
          ),
          Aritmetico(
            id: 'DIAG-EJ-3',
            posicion: PosicionCurricular(tema: 1, subtema: 3, leccion: 1),
            nivel: 1,
            enunciado: 'Calcula: 8 × 7',
            operacion: OperacionAritmetica.multiplicacion,
            operando1: 8,
            operando2: 7,
            disposicion: DisposicionAritmetica.horizontal,
            incognita: ElementoIncognita.resultado,
            tags: ['aritmetica', 'tablas-multiplicar'],
            puntos: 10,
          ),
          Aritmetico(
            id: 'DIAG-EJ-4',
            posicion: PosicionCurricular(tema: 1, subtema: 4, leccion: 1),
            nivel: 2,
            enunciado: 'Encuentra el valor que falta: ? - 45 = 55',
            operacion: OperacionAritmetica.resta,
            operando1: 100,
            operando2: 45,
            disposicion: DisposicionAritmetica.horizontal,
            incognita: ElementoIncognita.operando1,
            tags: ['despeje', 'ecuaciones-casilla'],
            puntos: 10,
          ),
          SeleccionMultiple(
            id: 'DIAG-EJ-5',
            posicion: PosicionCurricular(tema: 1, subtema: 5, leccion: 1),
            nivel: 1,
            enunciado: '¿Cuál de los siguientes números es primo?',
            tags: ['conceptos-clave', 'primos'],
            puntos: 10,
            opciones: [
              Opcion(id: 'a', texto: '9 (3 × 3)', esCorrecta: false),
              Opcion(id: 'b', texto: '13 (sólo divisible por 1 y 13)', esCorrecta: true),
              Opcion(id: 'c', texto: '15 (3 × 5)', esCorrecta: false),
              Opcion(id: 'd', texto: '21 (3 × 7)', esCorrecta: false),
            ],
          ),
        ],
      ),
    );
  }

  // --- Implementación de Intentos y Diagnósticos ---

  @override
  Future<void> registrarIntento(IntentoEvaluacion intento) async {
    _intentos.add(intento);
    _notificarCambio(intento.usuarioUid);

    try {
      await _firestore
          .collection('intentos_evaluacion')
          .doc(intento.id)
          .set(intento.toMap())
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('Aviso Firestore intentos (modo local activo): $e');
    }
  }

  @override
  Future<List<IntentoEvaluacion>> obtenerIntentosPorUsuario(String usuarioUid) async {
    return _intentos.where((i) => i.usuarioUid == usuarioUid).toList();
  }

  @override
  Future<DiagnosticoAlumno> obtenerDiagnostico(String usuarioUid) async {
    final intentosUsuario = _intentos.where((i) => i.usuarioUid == usuarioUid).toList();
    return _analizador.analizar(
      usuarioUid: usuarioUid,
      intentos: intentosUsuario,
    );
  }

  @override
  Future<List<IntentoEvaluacion>> obtenerTodosLosIntentos() async {
    return List.unmodifiable(_intentos);
  }

  @override
  Stream<DiagnosticoAlumno> diagnosticoStream(String usuarioUid) {
    return _diagnosticoController.stream.map((mapa) {
      if (mapa.containsKey(usuarioUid)) {
        return mapa[usuarioUid]!;
      }
      final intentos = _intentos.where((i) => i.usuarioUid == usuarioUid).toList();
      return _analizador.analizar(usuarioUid: usuarioUid, intentos: intentos);
    });
  }

  void _notificarCambio(String usuarioUid) {
    final intentosUsuario = _intentos.where((i) => i.usuarioUid == usuarioUid).toList();
    final diag = _analizador.analizar(
      usuarioUid: usuarioUid,
      intentos: intentosUsuario,
    );
    _diagnosticoController.add({usuarioUid: diag});
  }

  // --- Implementación de Exámenes Diagnósticos y Avance ---

  @override
  Future<void> guardarExamen(ExamenDiagnostico examen) async {
    final index = _examenes.indexWhere((e) => e.id == examen.id);
    if (index >= 0) {
      _examenes[index] = examen;
    } else {
      _examenes.add(examen);
    }

    try {
      await _firestore
          .collection('examenes_diagnostico')
          .doc(examen.id)
          .set(examen.toMap())
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('Aviso Firestore examenes (modo local activo): $e');
    }
  }

  @override
  Future<List<ExamenDiagnostico>> obtenerExamenes() async {
    return List.unmodifiable(_examenes);
  }

  @override
  Future<ExamenDiagnostico?> obtenerExamenPorId(String id) async {
    try {
      return _examenes.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> eliminarExamen(String id) async {
    _examenes.removeWhere((e) => e.id == id);
    try {
      await _firestore.collection('examenes_diagnostico').doc(id).delete().timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('Aviso Firestore eliminar examen: $e');
    }
  }

  @override
  Future<void> registrarProgresoExamen(ProgresoExamenAlumno progreso) async {
    final index = _progresos.indexWhere((p) => p.id == progreso.id || (p.examenId == progreso.examenId && p.alumnoUid == progreso.alumnoUid));
    if (index >= 0) {
      _progresos[index] = progreso;
    } else {
      _progresos.add(progreso);
    }

    try {
      await _firestore
          .collection('progresos_examen')
          .doc(progreso.id)
          .set(progreso.toMap())
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('Aviso Firestore progresos (modo local activo): $e');
    }
  }

  @override
  Future<List<ProgresoExamenAlumno>> obtenerProgresosDeExamen(String examenId) async {
    return _progresos.where((p) => p.examenId == examenId).toList();
  }

  @override
  Future<ProgresoExamenAlumno?> obtenerProgresoAlumno(String examenId, String alumnoUid) async {
    try {
      return _progresos.firstWhere((p) => p.examenId == examenId && p.alumnoUid == alumnoUid);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> limpiar() async {
    _intentos.clear();
    _examenes.clear();
    _progresos.clear();
  }

  void dispose() {
    _diagnosticoController.close();
  }
}
