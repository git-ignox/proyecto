import 'package:flutter/material.dart';
import '../../datos/fuente_datos_reportes.dart';
import '../../datos/repositorio_evaluaciones.dart';
import '../../datos/repositorio_reportes.dart';
import '../../dominio/analisis/analizador_brechas_evaluacion.dart';
import '../../dominio/analisis/servicio_ia_remediacion.dart';
import '../../dominio/modelos/analisis_brechas.dart';
import '../../dominio/modelos/evaluacion.dart';
import '../../dominio/modelos/reporte_pedagogico.dart';
import '../../dominio/modelos/usuario_app.dart';
import '../reportes/vista_imprimible_reporte.dart';

/// Vista para estudiante y apoderado que muestra notas por evaluación,
/// desglose de rendimiento por tema, el insight de la brecha prioritaria
/// y los reportes pedagógicos oficiales congelados por período.
class SeccionNotasAlumno extends StatefulWidget {
  SeccionNotasAlumno({
    super.key,
    required this.usuario,
    required this.repositorioEvaluaciones,
    RepositorioReportes? repositorioReportes,
    this.analizador = const AnalizadorBrechasEvaluacion(),
    this.servicioIa = const ServicioIaRemediacion(),
  }) : repositorioReportes = repositorioReportes ?? FuenteDatosReportes();

  final UsuarioApp usuario;
  final RepositorioEvaluaciones repositorioEvaluaciones;
  final RepositorioReportes repositorioReportes;
  final AnalizadorBrechasEvaluacion analizador;
  final ServicioIaRemediacion servicioIa;

  @override
  State<SeccionNotasAlumno> createState() => _SeccionNotasAlumnoState();
}

class _SeccionNotasAlumnoState extends State<SeccionNotasAlumno> {
  bool _cargando = true;
  List<NotaEvaluacion> _notas = [];
  List<Evaluacion> _evaluaciones = [];
  AnalisisEstudiante? _analisis;
  List<ReporteEstudiante> _reportesOficiales = [];
  ReporteEstudiante? _reporteSeleccionado;
  int _pestanaSeleccionada = 0; // 0: Calificaciones en vivo, 1: Reportes oficiales

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    final notas = await widget.repositorioEvaluaciones.obtenerNotasPorAlumno(widget.usuario.uid);

    // Obtener evaluaciones referenciadas
    final Set<String> idsEvals = notas.map((n) => n.evaluacionId).toSet();
    final List<Evaluacion> evals = [];
    for (final id in idsEvals) {
      final ev = await widget.repositorioEvaluaciones.obtenerEvaluacionPorId(id);
      if (ev != null) evals.add(ev);
    }

    final analisis = widget.analizador.analizarEstudiante(
      alumnoUid: widget.usuario.uid,
      alumnoNombre: widget.usuario.nombre,
      evaluaciones: evals,
      notas: notas,
    );

    final reportes = await widget.repositorioReportes.obtenerReportesPorAlumno(widget.usuario.uid);

    setState(() {
      _notas = notas;
      _evaluaciones = evals;
      _analisis = analisis;
      _reportesOficiales = reportes;
      if (reportes.isNotEmpty && _reporteSeleccionado == null) {
        _reporteSeleccionado = reportes.first;
      }
      _cargando = false;
    });
  }

  void _abrirGuiaRemediacion(String tema, double? porcentaje) {
    final plan = widget.servicioIa.generarPlanRemediacion(
      tema: tema,
      alumnoNombre: widget.usuario.nombre,
      porcentajeActual: porcentaje,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.psychology, color: Colors.amber, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Asistente Pedagógico • Guía de Refuerzo Personalizada',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber),
                        ),
                        Text(
                          plan.titulo,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Motor determinista basado en reglas cognitivas (100% confiable y sin latencia)',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(height: 24),

              // Explicación guiada
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.amber.shade900, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Cómo superar este tema:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(plan.explicacionConcepto, style: const TextStyle(fontSize: 13, height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Ejercicios Recomendados de Práctica:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              ...plan.ejerciciosPractica.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final ej = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.teal.shade100,
                              child: Text('$idx', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(ej.enunciado, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('💡 Pista: ${ej.pista}', style: TextStyle(fontSize: 11, color: Colors.grey.shade800)),
                              const SizedBox(height: 4),
                              Text('Solución: ${ej.respuestaEsperada}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                              const SizedBox(height: 2),
                              Text('Paso a paso: ${ej.explicacionPasoAPaso}', style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Calificaciones & Aprendizaje', style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Calificaciones en Vivo'),
                  icon: Icon(Icons.analytics_outlined, size: 16),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Boletín por Período'),
                  icon: Icon(Icons.assignment_outlined, size: 16),
                ),
              ],
              selected: {_pestanaSeleccionada},
              onSelectionChanged: (val) {
                setState(() => _pestanaSeleccionada = val.first);
              },
            ),
          ),
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _pestanaSeleccionada == 1
              ? _construirVistaReportesOficiales()
              : _notas.isEmpty
                  ? _construirVistaVacia()
                  : RefreshIndicator(
                      onRefresh: _cargarDatos,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _construirTarjetaResumenAlumno(),
                          const SizedBox(height: 16),
                          _construirInsightBrecha(),
                          const SizedBox(height: 16),
                          _construirRadarTemas(),
                          const SizedBox(height: 16),
                          _construirEvolucionPersonal(),
                          const SizedBox(height: 16),
                          _construirHistorialEvaluaciones(),
                        ],
                      ),
                    ),
    );
  }

  Widget _construirVistaReportesOficiales() {
    if (_reportesOficiales.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.assignment_late_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Sin boletines de período emitidos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tu docente aún no ha emitido el informe congelado de este período escolar. Aquí podrás consultar tus informes oficiales y el comentario pedagógico institucional.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final rep = _reporteSeleccionado ?? _reportesOficiales.first;

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Selector de período si hay varios reportes
          if (_reportesOficiales.length > 1) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _reportesOficiales.map((r) {
                  final seleccionado = r.id == rep.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(r.periodo),
                      selected: seleccionado,
                      selectedColor: Colors.teal.shade100,
                      onSelected: (_) {
                        setState(() => _reporteSeleccionado = r);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Tarjeta de cabecera del reporte oficial
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade800, Colors.indigo.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'Snapshot Oficial • ${rep.periodo}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${rep.fechaGeneracion.day}/${rep.fechaGeneracion.month}/${rep.fechaGeneracion.year}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Promedio Congelado',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              rep.promedioGeneral.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${rep.porcentajeGeneral.toStringAsFixed(0)}% Logro',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (rep.totalTemasEnRiesgo > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade400.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Text(
                          '${rep.totalTemasEnRiesgo} ${rep.totalTemasEnRiesgo == 1 ? 'brecha a nivelar' : 'brechas críticas'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade400.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: const Text(
                          'Dominio Consolidado ✓',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Observaciones cualitativas del docente
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.indigo.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.record_voice_over_outlined, size: 18, color: Colors.indigo.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Retroalimentación del Docente',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  rep.comentarioDocente.trim().isNotEmpty
                      ? rep.comentarioDocente
                      : 'El docente no ha registrado observaciones adicionales para este período.',
                  style: const TextStyle(fontSize: 13.5, height: 1.5, color: Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Temas priorizados pedagógicamente (brechas primero)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Dominios por Tema (Priorizados)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Brechas críticas primero',
                      style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...rep.temasPriorizados.map((tema) {
                  final esBrecha = tema.esBrechaCritica;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: esBrecha ? Colors.red.shade50.withValues(alpha: 0.4) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: esBrecha ? Colors.red.shade200 : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          esBrecha ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                          size: 20,
                          color: esBrecha ? Colors.red.shade700 : Colors.green.shade700,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tema.tema,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: esBrecha ? Colors.red.shade900 : Colors.black87,
                                ),
                              ),
                              Text(
                                '${tema.cantidadEvaluaciones} evaluación(es) • Nota prom.: ${tema.promedioNota.toStringAsFixed(1)}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${tema.porcentajeDominio.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: tema.nivelDominio.color,
                              ),
                            ),
                            if (tema.tendenciaInterPeriodo != TendenciaInterPeriodo.primeraMedicion)
                              Text(
                                tema.tendenciaInterPeriodo.etiqueta,
                                style: TextStyle(fontSize: 10, color: tema.tendenciaInterPeriodo.color),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Botón para ver el boletín imprimible oficial
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => VistaImprimibleReporte(reporte: rep),
                ),
              );
            },
            icon: const Icon(Icons.print_outlined, size: 20),
            label: const Text('Ver e Imprimir Boletín Oficial Completo'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.teal.shade800,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _construirVistaVacia() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Aún no tienes calificaciones registradas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cuando tu docente registre tus pruebas o tareas, aquí verás tus notas detalladas y las áreas que necesitas reforzar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirTarjetaResumenAlumno() {
    final a = _analisis!;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tu Promedio General', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${a.promedioGeneral}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text('${a.porcentajeGeneral.toStringAsFixed(0)}% Logro'),
                        backgroundColor: Colors.teal.shade50,
                        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(height: 40, width: 1, color: Colors.grey.shade300),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Evaluaciones Rendidas', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text(
                      '${a.totalEvaluaciones} Calificaciones',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      '${a.rendimientosPorTema.length} temas evaluados',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirInsightBrecha() {
    final a = _analisis!;
    final peor = a.temaPeorDesempeno;
    final mejor = a.temaMejorDesempeno;

    if (peor == null) return const SizedBox.shrink();

    final esBrechaReal = peor.porcentajeLogro < 70.0;

    return Card(
      elevation: 3,
      color: esBrechaReal ? Colors.orange.shade50 : Colors.teal.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: esBrechaReal ? Colors.orange.shade300 : Colors.teal.shade300,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  esBrechaReal ? Icons.lightbulb : Icons.emoji_events_outlined,
                  color: esBrechaReal ? Colors.orange.shade900 : Colors.teal.shade900,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'INSIGHT PEDAGÓGICO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: esBrechaReal ? Colors.orange.shade900 : Colors.teal.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tu foco prioritario a reforzar: ${peor.tema}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              mejor != null && mejor.tema != peor.tema
                  ? 'Tu promedio general de ${a.promedioGeneral} esconde que dominas "${mejor.tema}" con un ${mejor.porcentajeLogro}%, pero tu rendimiento en "${peor.tema}" es de solo ${peor.porcentajeLogro}%. ¡Reforzar este tema subirá notablemente tus notas!'
                  : 'Tu rendimiento actual en ${peor.tema} es de ${peor.porcentajeLogro}%. Te recomendamos repasar los conceptos fundamentales.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.3),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: Tooltip(
                message:
                    'Asistente pedagógico determinista: genera actividades y explicaciones guiadas según tu brecha detectada (100% confiable)',
                child: ElevatedButton.icon(
                  onPressed: () => _abrirGuiaRemediacion(peor.tema, peor.porcentajeLogro),
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('VER GUÍA CON ASISTENTE PEDAGÓGICO'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: esBrechaReal ? Colors.orange.shade900 : Colors.teal.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirRadarTemas() {
    final a = _analisis!;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pie_chart_outline, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  'Tu Rendimiento por Tema / Contenido',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...a.rendimientosPorTema.values.map((rend) {
              final pct = rend.porcentajeLogro / 100.0;
              final color = rend.nivelDominio.color;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(rend.tema, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Row(
                          children: [
                            Text(
                              '${rend.porcentajeLogro}% (Nota ${rend.promedioNota})',
                              style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            Icon(rend.nivelDominio.icono, size: 16, color: color),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.0, 1.0),
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _construirEvolucionPersonal() {
    final a = _analisis!;
    final temasEvolucion = a.evolucionesPorTema.values.where((e) => e.puntos.length >= 2).toList();
    if (temasEvolucion.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_up, color: Colors.teal),
                SizedBox(width: 8),
                Text('Tu Evolución en el Tiempo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            ...temasEvolucion.map((evo) {
              final signo = evo.variacionPorcentual >= 0 ? '+' : '';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(evo.tema, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: evo.tendencia.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$signo${evo.variacionPorcentual}% • ${evo.tendencia.etiqueta}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: evo.tendencia.color),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _construirHistorialEvaluaciones() {
    final mapaEvals = {for (final e in _evaluaciones) e.id: e};

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history_edu, color: Colors.teal),
                SizedBox(width: 8),
                Text('Historial de Calificaciones', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ..._notas.map((n) {
              final ev = mapaEvals[n.evaluacionId];
              final nombre = ev?.nombre ?? 'Evaluación';
              final tipo = ev?.tipo ?? TipoEvaluacion.examen;
              final notaAprob = ev?.notaAprobatoria ?? 4.0;
              final aprobado = n.nota >= notaAprob;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: aprobado ? Colors.green.shade100 : Colors.red.shade100,
                      child: Text(
                        n.nota.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: aprobado ? Colors.green.shade900 : Colors.red.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(
                            '${tipo.etiqueta} • Logro: ${n.porcentajeLogro.toStringAsFixed(0)}% • Escala máx: ${n.notaMaxima}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                          ),
                          if (n.observaciones != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Nota docente: ${n.observaciones}',
                                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.indigo),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
