import 'package:flutter/material.dart';
import '../datos/fuente_datos_clases.dart';
import '../datos/fuente_datos_diagnostico.dart';
import '../datos/fuente_datos_evaluaciones.dart';
import '../datos/fuente_datos_reportes.dart';
import '../datos/repositorio_clases.dart';
import '../datos/repositorio_diagnostico.dart';
import '../datos/repositorio_ejercicios.dart';
import '../datos/repositorio_evaluaciones.dart';
import '../datos/repositorio_reportes.dart';
import '../datos/servicio_auth.dart';
import '../dominio/evaluadores/servicio_evaluacion.dart';
import '../dominio/generadores/generador_aritmetica.dart';
import '../dominio/modelos/aritmetico.dart';
import '../dominio/modelos/ejercicio.dart';
import '../dominio/modelos/error_aprendizaje.dart';
import '../dominio/modelos/examen_diagnostico.dart';
import '../dominio/modelos/intento_evaluacion.dart';
import '../dominio/modelos/progreso_examen_alumno.dart';
import '../dominio/modelos/resultado_evaluacion.dart';
import '../dominio/modelos/seleccion_multiple.dart';
import '../dominio/modelos/usuario_app.dart';
import 'evaluaciones/seccion_notas_alumno.dart';
import 'widgets/widget_aritmetica.dart';

/// Interfaz especializada para el Estudiante / Alumno.
/// Enfocada en resolver problemas, diagnóstico de errores, práctica de refuerzo y exámenes diagnósticos con avance.
class PantallaAlumno extends StatefulWidget {
  PantallaAlumno({
    super.key,
    required this.usuario,
    required this.repositorio,
    required this.servicioEvaluacion,
    required this.servicioAuth,
    RepositorioDiagnostico? repositorioDiagnostico,
    RepositorioClases? repositorioClases,
    RepositorioEvaluaciones? repositorioEvaluaciones,
    RepositorioReportes? repositorioReportes,
  })  : repositorioDiagnostico = repositorioDiagnostico ?? FuenteDatosDiagnostico(),
        repositorioClases = repositorioClases ?? FuenteDatosClases(),
        repositorioEvaluaciones = repositorioEvaluaciones ?? FuenteDatosEvaluaciones(),
        repositorioReportes = repositorioReportes ?? FuenteDatosReportes();

  final UsuarioApp usuario;
  final RepositorioEjercicios repositorio;
  final ServicioEvaluacion servicioEvaluacion;
  final ServicioAuth servicioAuth;
  final RepositorioDiagnostico repositorioDiagnostico;
  final RepositorioClases repositorioClases;
  final RepositorioEvaluaciones repositorioEvaluaciones;
  final RepositorioReportes repositorioReportes;

  @override
  State<PantallaAlumno> createState() => _PantallaAlumnoState();
}

class _PantallaAlumnoState extends State<PantallaAlumno> {
  List<Ejercicio> _ejercicios = [];
  int _indiceActual = 0;
  bool _cargando = true;

  final GeneradorAritmetica _generador = GeneradorAritmetica();

  // Entradas de respuesta
  String? _opcionSeleccionadaId;
  final TextEditingController _controladorTexto = TextEditingController();
  final TextEditingController _controladorResto = TextEditingController();

  ResultadoEvaluacion? _resultado;
  bool _evaluando = false;

  @override
  void initState() {
    super.initState();
    _cargarEjercicios();
  }

  Future<void> _cargarEjercicios({int? indiceObjetivo}) async {
    setState(() => _cargando = true);
    final lista = await widget.repositorio.obtenerTodos();
    setState(() {
      _ejercicios = lista;
      if (indiceObjetivo != null && indiceObjetivo < _ejercicios.length) {
        _indiceActual = indiceObjetivo;
      } else if (_indiceActual >= _ejercicios.length) {
        _indiceActual = _ejercicios.isNotEmpty ? _ejercicios.length - 1 : 0;
      }
      _cargando = false;
      _limpiarRespuesta();
    });
  }

  void _limpiarRespuesta() {
    _opcionSeleccionadaId = null;
    _controladorTexto.clear();
    _controladorResto.clear();
    _resultado = null;
  }

  void _cambiarEjercicio(int nuevoIndice) {
    if (nuevoIndice >= 0 && nuevoIndice < _ejercicios.length) {
      setState(() {
        _indiceActual = nuevoIndice;
        _limpiarRespuesta();
      });
    }
  }

  Future<void> _generarPracticaRapida({OperacionAritmetica? op, int nivel = 1}) async {
    final nuevo = _generador.generar(operacion: op, nivel: nivel);
    await widget.repositorio.agregarEjercicio(nuevo);
    await _cargarEjercicios(indiceObjetivo: _ejercicios.length);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Nuevo reto de ${nuevo.operacion.name.toUpperCase()} añadido!'),
          backgroundColor: Colors.teal.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _generarRefuerzoAdaptativo(List<String> tagsCriticos) async {
    final ejercicioRefuerzo = _generador.generarRefuerzoParaTags(tagsCriticos);
    await widget.repositorio.agregarEjercicio(ejercicioRefuerzo);
    await _cargarEjercicios(indiceObjetivo: _ejercicios.length);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🎯 ¡Práctica de Refuerzo generada para tus áreas de mejora!'),
          backgroundColor: Colors.indigo.shade800,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _evaluarRespuesta() async {
    if (_ejercicios.isEmpty) return;
    final ejercicio = _ejercicios[_indiceActual];

    dynamic respuestaUsuario;
    if (ejercicio is SeleccionMultiple) {
      respuestaUsuario = _opcionSeleccionadaId;
    } else if (ejercicio is Aritmetico) {
      if (ejercicio.operacion == OperacionAritmetica.division && _controladorResto.text.trim().isNotEmpty) {
        respuestaUsuario = {
          'cociente': _controladorTexto.text.trim(),
          'resto': _controladorResto.text.trim(),
        };
      } else {
        respuestaUsuario = _controladorTexto.text.trim();
      }
    } else {
      respuestaUsuario = _controladorTexto.text.trim();
    }

    setState(() => _evaluando = true);

    final res = await widget.servicioEvaluacion.evaluar(
      ejercicio: ejercicio,
      respuesta: respuestaUsuario,
    );

    // Registro del intento en el sistema de diagnóstico
    final intento = IntentoEvaluacion(
      id: 'INT-${DateTime.now().millisecondsSinceEpoch}',
      usuarioUid: widget.usuario.uid,
      ejercicioId: ejercicio.id,
      codigoTema: ejercicio.codigoTema,
      tags: ejercicio.tags,
      tipo: ejercicio.tipo,
      esCorrecto: res.esCorrecto,
      puntaje: res.puntaje,
      error: res.errorDetectado,
      respuestaDada: respuestaUsuario,
      fecha: DateTime.now(),
    );

    await widget.repositorioDiagnostico.registrarIntento(intento);

    setState(() {
      _resultado = res;
      _evaluando = false;
    });

    if (res.esCorrecto) {
      await widget.servicioAuth.sumarPuntos(ejercicio.puntos);
    }
  }

  void _mostrarDiagnostico() async {
    final diag = await widget.repositorioDiagnostico.obtenerDiagnostico(widget.usuario.uid);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.analytics_outlined, color: Colors.indigo.shade700, size: 28),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Mi Diagnóstico & Áreas de Mejora',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),

              // Métricas rápidas
              Row(
                children: [
                  Expanded(
                    child: _construirTarjetaMetrica(
                      'Precisión Global',
                      '${diag.porcentajePrecision}%',
                      diag.porcentajePrecision >= 70 ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _construirTarjetaMetrica(
                      'Intentos Totales',
                      '${diag.totalIntentos}',
                      Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _construirTarjetaMetrica(
                      'Errores Detectados',
                      '${diag.errores}',
                      diag.errores > 0 ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Botón de Práctica de Refuerzo Personalizada
              if (diag.tagsCriticos.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _generarRefuerzoAdaptativo(diag.tagsCriticos);
                  },
                  icon: const Icon(Icons.fitness_center),
                  label: const Text('PRACTICAR MIS PUNTOS DÉBILES (REFUERZO)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              const SizedBox(height: 20),

              // Errores Prominentes Detectados
              const Text(
                '🔍 Errores Más Prominentes:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (diag.erroresProminentes.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '¡Excelente! No tienes errores prominentes o recurrentes en tus prácticas.',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...diag.erroresProminentes.map((err) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(err.categoria.icono, style: const TextStyle(fontSize: 20)),
                                    const SizedBox(width: 8),
                                    Text(
                                      err.categoria.etiqueta,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                                Chip(
                                  label: Text('${err.conteo} fallos', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                  backgroundColor: err.conteo >= 3 ? Colors.red.shade700 : Colors.orange.shade700,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(err.descripcion, style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 6),
                            if (err.tagsRelacionados.isNotEmpty)
                              Wrap(
                                spacing: 4,
                                children: err.tagsRelacionados
                                    .map((t) => Chip(
                                          label: Text('#$t', style: const TextStyle(fontSize: 10)),
                                          visualDensity: VisualDensity.compact,
                                          backgroundColor: Colors.grey.shade100,
                                        ))
                                    .toList(),
                              ),
                          ],
                        ),
                      ),
                    )),

              const SizedBox(height: 20),

              // Sección: ¿En qué te debemos ayudar?
              const Text(
                '💡 ¿En qué te debemos de ayudar?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...diag.recomendacionesRefuerzo.map((rec) => Card(
                    color: Colors.indigo.shade50,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.indigo.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  rec.titulo,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.indigo.shade900),
                                ),
                              ),
                              Text(rec.prioridad.etiqueta, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(rec.explicacion, style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    rec.accionSugerida,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarExamenesDiagnostico() async {
    final examenes = await widget.repositorioDiagnostico.obtenerExamenes();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.assignment_outlined, color: Colors.indigo.shade800, size: 28),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Exámenes Diagnósticos de Nivelación',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),

              if (examenes.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('No hay exámenes diagnósticos asignados en este momento.', textAlign: TextAlign.center),
                )
              else
                ...examenes.map((exam) => Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exam.titulo,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(exam.descripcion, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                            const SizedBox(height: 8),

                            // Meta y Variable de Avance Fijada por el Docente
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.indigo.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.flag_outlined, color: Colors.indigo, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Meta de Avance fijada por tu profesor:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo)),
                                        Text(
                                          '${(exam.umbralAvance <= 1.0 ? exam.umbralAvance * 100 : exam.umbralAvance).toInt()}% de aciertos mínimos (${exam.criterioAvance.etiqueta})',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _iniciarExamenDiagnostico(exam);
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('PRESENTAR EXAMEN DIAGNÓSTICO'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo.shade700,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 42),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  void _iniciarExamenDiagnostico(ExamenDiagnostico examen) async {
    if (examen.ejercicios.isEmpty) return;

    int indice = 0;
    int aciertos = 0;
    final Map<String, dynamic> respuestasDadas = {};
    final List<ErrorAprendizaje> erroresDetectados = [];
    double puntajeTotal = 0;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (ctx, setExamState) {
          final ejercicio = examen.ejercicios[indice];
          final textCtrl = TextEditingController();

          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${examen.titulo} (${indice + 1}/${examen.totalPreguntas})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Meta: ${(examen.umbralAvance <= 1.0 ? examen.umbralAvance * 100 : examen.umbralAvance).toInt()}%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: (indice + 1) / examen.totalPreguntas,
                    backgroundColor: Colors.grey.shade200,
                    color: Colors.indigo,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ejercicio.enunciado,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textCtrl,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Escribe tu respuesta...',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dlgCtx),
                child: const Text('Cancelar Examen'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final resp = textCtrl.text.trim();
                  if (resp.isEmpty) return;

                  respuestasDadas[ejercicio.id] = resp;
                  final eval = await widget.servicioEvaluacion.evaluar(
                    ejercicio: ejercicio,
                    respuesta: resp,
                  );

                  if (eval.esCorrecto) {
                    aciertos++;
                    puntajeTotal += ejercicio.puntos;
                  } else if (eval.errorDetectado != null) {
                    erroresDetectados.add(eval.errorDetectado!);
                  }

                  if (indice + 1 < examen.totalPreguntas) {
                    setExamState(() {
                      indice++;
                    });
                  } else {
                    // Finalizó el examen -> Evaluar variable de avance determinada por el docente
                    final veredictoAvance = examen.verificarAvance(
                      aciertos: aciertos,
                      totalRespondidas: examen.totalPreguntas,
                      puntajeObtenido: puntajeTotal,
                      errores: erroresDetectados,
                    );

                    final progreso = ProgresoExamenAlumno(
                      id: 'PROG-${DateTime.now().millisecondsSinceEpoch}',
                      examenId: examen.id,
                      alumnoUid: widget.usuario.uid,
                      alumnoNombre: widget.usuario.nombre.isNotEmpty ? widget.usuario.nombre : 'Alumno',
                      respuestasPorEjercicio: respuestasDadas,
                      aciertos: aciertos,
                      totalEjercicios: examen.totalPreguntas,
                      puntajeTotal: puntajeTotal,
                      errores: erroresDetectados,
                      resultadoAvance: veredictoAvance,
                      estado: veredictoAvance.puedeAvanzar
                          ? EstadoExamenAlumno.aprobadoParaAvanzar
                          : EstadoExamenAlumno.requiereRefuerzo,
                      fechaInicio: DateTime.now(),
                      fechaFinalizacion: DateTime.now(),
                    );

                    await widget.repositorioDiagnostico.registrarProgresoExamen(progreso);

                    if (dlgCtx.mounted) {
                      Navigator.pop(dlgCtx);
                    }
                    if (mounted) {
                      _mostrarResultadoFinalExamen(examen, veredictoAvance, aciertos, puntajeTotal);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                child: Text(indice + 1 == examen.totalPreguntas ? 'Finalizar Examen' : 'Siguiente'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _mostrarResultadoFinalExamen(
    ExamenDiagnostico examen,
    ResultadoAvance veredicto,
    int aciertos,
    double puntajeTotal,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              veredicto.puedeAvanzar ? Icons.verified : Icons.error_outline,
              color: veredicto.puedeAvanzar ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(veredicto.puedeAvanzar ? '¡Diagnóstico Superado!' : 'Diagnóstico Completado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aciertos: $aciertos de ${examen.totalPreguntas} (${veredicto.porcentajeLogrado.toStringAsFixed(1)}%)'),
            Text('Puntos obtenidos: ${puntajeTotal.toStringAsFixed(0)}'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: veredicto.puedeAvanzar ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: veredicto.puedeAvanzar ? Colors.green : Colors.orange),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    veredicto.puedeAvanzar ? '✅ Habilitado para Avanzar' : '⚠️ Refuerzo Recomendado',
                    style: TextStyle(fontWeight: FontWeight.bold, color: veredicto.puedeAvanzar ? Colors.green.shade900 : Colors.orange.shade900),
                  ),
                  const SizedBox(height: 4),
                  Text(veredicto.mensajePedagogico, style: const TextStyle(fontSize: 13)),
                  if (veredicto.puedeAvanzar && examen.temaDestinoAlAvanzar != null) ...[
                    const SizedBox(height: 6),
                    Text('🚀 Desbloqueado: ${examen.temaDestinoAlAvanzar}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  // ─────────────── CLASSROOM ALUMNO ───────────────

  void _mostrarMisClases() async {
    final clases = await widget.repositorioClases.obtenerClasesPorAlumno(widget.usuario.uid);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.class_outlined, color: Colors.green.shade700, size: 28),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Mis Clases',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // Botón unirse con código
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _mostrarDialogoUnirse();
                },
                icon: const Icon(Icons.vpn_key_outlined),
                label: const Text('UNIRSE A UNA CLASE CON CÓDIGO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
              const SizedBox(height: 18),

              const Text('Clases en las que estoy inscrito:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              if (clases.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.school_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 10),
                      Text('No estás inscrito en ninguna clase.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 4),
                      Text(
                        'Pide a tu profesor el código de acceso y únete a tu clase.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else
                ...clases.map((clase) => Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.class_outlined, color: Colors.green.shade700, size: 22),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(clase.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      Text(clase.gradoGrupo, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 16, color: Colors.indigo),
                                const SizedBox(width: 6),
                                Text('Profesor: ${clase.profesorNombre}', style: const TextStyle(fontSize: 13, color: Colors.indigo, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.group_outlined, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text('${clase.totalAlumnos} compañero${clase.totalAlumnos != 1 ? "s" : ""} en clase', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            if (clase.descripcion.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(clase.descripcion, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ],
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _abrirMisCalificaciones();
                                },
                                icon: const Icon(Icons.grading, size: 16),
                                label: const Text('Ver Mis Calificaciones & Brechas', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade800,
                                  foregroundColor: Colors.white,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirMisCalificaciones() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SeccionNotasAlumno(
          usuario: widget.usuario,
          repositorioEvaluaciones: widget.repositorioEvaluaciones,
          repositorioReportes: widget.repositorioReportes,
        ),
      ),
    );
  }

  void _mostrarDialogoUnirse() {
    final codigoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          String? mensajeError;
          bool cargando = false;

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.vpn_key, color: Colors.green),
                SizedBox(width: 8),
                Text('Unirse a una Clase'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ingresa el código de acceso que te proporcionó tu profesor:',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: codigoCtrl,
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 3),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: 'MAT-101',
                    hintStyle: TextStyle(color: Colors.grey.shade300, letterSpacing: 3, fontSize: 22),
                    prefixIcon: const Icon(Icons.vpn_key_outlined),
                    errorText: mensajeError,
                  ),
                ),
                if (cargando)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dlgCtx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: cargando
                    ? null
                    : () async {
                        final codigo = codigoCtrl.text.trim();
                        if (codigo.isEmpty) {
                          setDlgState(() => mensajeError = 'Ingresa un código de acceso');
                          return;
                        }
                        setDlgState(() {
                          cargando = true;
                          mensajeError = null;
                        });

                        final resultado = await widget.repositorioClases.unirseAClase(
                          codigo: codigo,
                          alumnoUid: widget.usuario.uid,
                          alumnoNombre: widget.usuario.nombre.isNotEmpty ? widget.usuario.nombre : 'Alumno',
                        );

                        if (!dlgCtx.mounted) return;

                        if (resultado.exitoso) {
                          Navigator.pop(dlgCtx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(resultado.mensaje),
                                backgroundColor: Colors.green.shade700,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                            // Re-abrir el panel de clases para ver la nueva
                            _mostrarMisClases();
                          }
                        } else {
                          setDlgState(() {
                            cargando = false;
                            mensajeError = resultado.mensaje;
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                child: const Text('Unirse'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _construirTarjetaMetrica(String titulo, String valor, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(valor, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black87)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controladorTexto.dispose();
    _controladorResto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.school_outlined),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.usuario.nombre.isNotEmpty ? widget.usuario.nombre : 'Portal del Alumno',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Botón Mis Clases & Classroom
          IconButton(
            icon: const Icon(Icons.class_outlined, color: Colors.greenAccent),
            tooltip: 'Mis Clases & Unirse con Código',
            onPressed: _mostrarMisClases,
          ),

          // Botón Mis Calificaciones & Brechas
          IconButton(
            icon: const Icon(Icons.grading_outlined, color: Colors.cyanAccent),
            tooltip: 'Mis Calificaciones & Brechas',
            onPressed: _abrirMisCalificaciones,
          ),

          // Botón Exámenes Diagnósticos
          IconButton(
            icon: const Icon(Icons.assignment_outlined, color: Colors.amberAccent),
            tooltip: 'Exámenes Diagnósticos',
            onPressed: _mostrarExamenesDiagnostico,
          ),

          // Botón Diagnóstico y Refuerzo
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Mi Diagnóstico y Refuerzo',
            onPressed: _mostrarDiagnostico,
          ),

          // Puntos del Alumno
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade400,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars, size: 18, color: Colors.indigo),
                const SizedBox(width: 4),
                Text(
                  '${widget.usuario.puntosAcumulados} pts',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 13),
                ),
              ],
            ),
          ),

          // Alternar rol (Atajo de demo)
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Atajo de Demostración: Alternar a modo Profesor (para presentar sin reloguear)',
            onPressed: () => widget.servicioAuth.alternarRol(),
          ),

          // Cerrar sesión
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => widget.servicioAuth.cerrarSesion(),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _ejercicios.isEmpty
              ? _construirEstadoVacio()
              : _construirCuerpoEjercicio(),
    );
  }

  Widget _construirEstadoVacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 72, color: Colors.amber.shade600),
            const SizedBox(height: 16),
            const Text(
              '¡Estás listo para aprender!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aún no hay ejercicios en tu clase. Puedes generar retos de aritmética vertical y galera para comenzar a practicar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _generarPracticaRapida(),
              icon: const Icon(Icons.bolt),
              label: const Text('GENERAR RETO DE ARITMÉTICA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirCuerpoEjercicio() {
    final ejercicio = _ejercicios[_indiceActual];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra de progreso y metadatos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ejercicio ${_indiceActual + 1} de ${_ejercicios.length}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              OutlinedButton.icon(
                onPressed: () => _generarPracticaRapida(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Más retos'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Chip(
                label: Text('Tema: ${ejercicio.codigoTema}'),
                backgroundColor: Colors.blue.shade50,
              ),
              Chip(
                label: Text('Nivel ${ejercicio.nivel}'),
                backgroundColor: Colors.purple.shade50,
              ),
              Chip(
                label: Text('+${ejercicio.puntos} puntos'),
                backgroundColor: Colors.amber.shade100,
                avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
              ),
            ],
          ),
          if (ejercicio.tags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: ejercicio.tags
                  .map((t) => Chip(
                        avatar: const Icon(Icons.local_offer_outlined, size: 14, color: Colors.indigo),
                        label: Text(t, style: const TextStyle(fontSize: 12, color: Colors.indigo)),
                        backgroundColor: Colors.indigo.shade50,
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),

          // Enunciado
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                ejercicio.enunciado,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Widget de Respuesta
          _construirEntradaRespuesta(ejercicio),
          const SizedBox(height: 16),

          // Botón Calificar
          ElevatedButton.icon(
            onPressed: _evaluando ? null : _evaluarRespuesta,
            icon: _evaluando
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check_circle_outline),
            label: const Text('CALIFICAR RESPUESTA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 10),

          // Navegación
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: _indiceActual > 0 ? () => _cambiarEjercicio(_indiceActual - 1) : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Anterior'),
              ),
              OutlinedButton.icon(
                onPressed: _indiceActual < _ejercicios.length - 1 ? () => _cambiarEjercicio(_indiceActual + 1) : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Siguiente'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Panel de Resultados con Diagnóstico de Errores
          if (_resultado != null) _construirPanelResultado(_resultado!),
        ],
      ),
    );
  }

  Widget _construirEntradaRespuesta(Ejercicio ejercicio) {
    if (ejercicio is Aritmetico) {
      return WidgetAritmetica(
        ejercicio: ejercicio,
        controladorTexto: _controladorTexto,
        controladorResto: _controladorResto,
        onRespuestaCambiada: () {
          if (_resultado != null) setState(() => _resultado = null);
        },
      );
    }

    if (ejercicio is SeleccionMultiple) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...ejercicio.opciones.map((op) {
            final estaSeleccionada = _opcionSeleccionadaId == op.id;
            return Card(
              color: estaSeleccionada ? Colors.indigo.shade50 : null,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: estaSeleccionada ? Colors.indigo : Colors.grey.shade300,
                  width: estaSeleccionada ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: Icon(
                  estaSeleccionada ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: estaSeleccionada ? Colors.indigo : Colors.grey,
                ),
                title: Text(op.texto),
                onTap: () {
                  setState(() => _opcionSeleccionadaId = op.id);
                },
              ),
            );
          }),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ingresa tu respuesta:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _controladorTexto,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Tu respuesta...',
          ),
        ),
      ],
    );
  }

  Widget _construirPanelResultado(ResultadoEvaluacion res) {
    final color = res.esCorrecto ? Colors.green : (res.puntaje > 0.0 ? Colors.orange : Colors.red);

    return Card(
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  res.esCorrecto ? Icons.celebration : (res.puntaje > 0 ? Icons.info : Icons.cancel),
                  color: color,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  res.esCorrecto ? '¡Excelente trabajo!' : (res.puntaje > 0 ? 'Casi lo logras' : 'Inténtalo de nuevo'),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
                ),
              ],
            ),
            const Divider(height: 16),
            Text(res.retroalimentacion, style: const TextStyle(fontSize: 15)),

            // Diagnóstico Pedagógico del Error si existe
            if (!res.esCorrecto && res.errorDetectado != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(res.errorDetectado!.categoria.icono, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Diagnóstico del Error: ${res.errorDetectado!.categoria.etiqueta}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            res.errorDetectado!.severidad.etiqueta,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '💡 Consejo Didáctico: ${res.errorDetectado!.sugerenciaPedagogica}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.indigo),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
