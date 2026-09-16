import 'package:flutter/material.dart';
import '../../datos/repositorio_evaluaciones.dart';
import '../../dominio/analisis/analizador_brechas_evaluacion.dart';
import '../../dominio/analisis/servicio_ia_remediacion.dart';
import '../../dominio/modelos/analisis_brechas.dart';
import '../../dominio/modelos/clase_escolar.dart';
import '../../dominio/modelos/evaluacion.dart';

/// Dashboard de Triage Pedagógico y Brechas de Aprendizaje para el Docente.
class PantallaDashboardBrechas extends StatefulWidget {
  const PantallaDashboardBrechas({
    super.key,
    required this.clase,
    required this.repositorioEvaluaciones,
    this.analizador = const AnalizadorBrechasEvaluacion(),
    this.servicioIa = const ServicioIaRemediacion(),
  });

  final ClaseEscolar clase;
  final RepositorioEvaluaciones repositorioEvaluaciones;
  final AnalizadorBrechasEvaluacion analizador;
  final ServicioIaRemediacion servicioIa;

  @override
  State<PantallaDashboardBrechas> createState() => _PantallaDashboardBrechasState();
}

class _PantallaDashboardBrechasState extends State<PantallaDashboardBrechas> {
  bool _cargando = true;
  List<Evaluacion> _evaluaciones = [];
  AnalisisClase? _analisis;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    final evals = await widget.repositorioEvaluaciones.obtenerEvaluacionesPorClase(widget.clase.id);
    final notas = await widget.repositorioEvaluaciones.obtenerNotasPorClase(widget.clase.id);

    final analisis = widget.analizador.analizarClase(
      claseId: widget.clase.id,
      evaluaciones: evals,
      notas: notas,
      nombresAlumnos: widget.clase.nombresAlumnos,
    );

    setState(() {
      _evaluaciones = evals;
      _analisis = analisis;
      _cargando = false;
    });
  }

  void _mostrarPlanRemediacionIa(String tema, {double? porcentaje}) {
    final plan = widget.servicioIa.generarPlanRemediacion(
      tema: tema,
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
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.indigo, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Asistente Pedagógico • Remediación de Brechas',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo),
                        ),
                        Text(
                          plan.titulo,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Motor experto determinista basado en reglas cognitivas (100% confiable y sin latencia)',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(height: 24),

              // Tarjeta de diagnóstico de la brecha
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.troubleshoot, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Diagnóstico del Error Frecuente',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(plan.diagnosticoBrecha, style: TextStyle(fontSize: 13, color: Colors.red.shade900)),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Explicación conceptual
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.amber.shade900, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Explicación Sintética & Modelado Guiado',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(plan.explicacionConcepto, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Tip pedagógico
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.tips_and_updates, color: Colors.blue.shade800, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        plan.tipPedagogico,
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade900, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              const Text(
                'Ejercicios de Práctica Guiada Recomendados:',
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
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.indigo.shade100,
                              child: Text('$idx', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)),
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
                              Text('Pista: ${ej.pista}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                              const SizedBox(height: 4),
                              Text('Respuesta: ${ej.respuestaEsperada}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard de Brechas (Triage)', style: TextStyle(fontSize: 16)),
            Text(widget.clase.nombre, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar análisis',
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _analisis == null || _evaluaciones.isEmpty
              ? _construirVistaVacia()
              : RefreshIndicator(
                  onRefresh: _cargarDatos,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _construirTarjetaResumenClase(),
                      const SizedBox(height: 16),
                      _construirTarjetaAlertaTemaCritico(),
                      const SizedBox(height: 16),
                      _construirDesgloseRendimientoPorTema(),
                      const SizedBox(height: 16),
                      _construirEvolucionTemporal(),
                      const SizedBox(height: 16),
                      _construirMatrizTriageAlumnos(),
                    ],
                  ),
                ),
    );
  }

  Widget _construirVistaVacia() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No hay suficientes evaluaciones o notas registradas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea evaluaciones etiquetadas con temas y registra notas para activar el motor de triage y brechas de aprendizaje.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirTarjetaResumenClase() {
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
                  Text('Promedio General del Aula', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${a.promedioClase}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text('${a.porcentajeClase.toStringAsFixed(0)}% Logro'),
                        backgroundColor: Colors.indigo.shade50,
                        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo),
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
                padding: const EdgeInsets.only(left: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Muestra Evaluada', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text(
                      '${a.totalEvaluaciones} Evaluaciones',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '${a.totalAlumnos} Estudiantes analizados',
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

  Widget _construirTarjetaAlertaTemaCritico() {
    final a = _analisis!;
    final peorTema = a.temaPeorDesempenoColectivo;

    if (peorTema == null) return const SizedBox.shrink();

    return Card(
      elevation: 3,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade300, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade800, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TEMA CON PEOR DESEMPEÑO COLECTIVO',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      Text(
                        '${peorTema.tema} (${peorTema.porcentajeLogro}% de logro grupal)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.directions_run, color: Colors.indigo.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      a.recomendacionDocente,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade900, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: Tooltip(
                message:
                    'Asistente pedagógico determinista: genera actividades y mnemotecnias según el error cognitivo detectado (100% confiable y sin latencia)',
                child: ElevatedButton.icon(
                  onPressed: () => _mostrarPlanRemediacionIa(peorTema.tema, porcentaje: peorTema.porcentajeLogro),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('GENERAR PLAN CON ASISTENTE PEDAGÓGICO'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirDesgloseRendimientoPorTema() {
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
                Icon(Icons.bar_chart, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Desempeño Colectivo por Tema / Estándar',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...a.rendimientosPorTema.values.map((rend) {
              final pct = rend.porcentajeLogro / 100.0;
              final color = rend.nivelDominio.color;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          rend.tema,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Row(
                          children: [
                            Text(
                              '${rend.porcentajeLogro}% (Nota ${rend.promedioNota})',
                              style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
                            ),
                            const SizedBox(width: 6),
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

  Widget _construirEvolucionTemporal() {
    final a = _analisis!;
    final temasConEvolucion = a.evolucionesPorTema.values
        .where((e) => e.puntos.length >= 2)
        .toList();

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
                Icon(Icons.show_chart, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Evolución Temporal en el Tiempo (Tendencia)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Seguimiento de temas evaluados en más de una ocasión:',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),

            if (temasConEvolucion.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.grey),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Aún no hay temas evaluados en múltiples fechas para graficar evolución.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...temasConEvolucion.map((evo) {
                final signo = evo.variacionPorcentual >= 0 ? '+' : '';
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                      const SizedBox(height: 8),
                      // Puntos cronológicos
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: evo.puntos.asMap().entries.map((entry) {
                          final i = entry.key;
                          final pt = entry.value;
                          final esUltimo = i == evo.puntos.length - 1;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(
                                label: Text(
                                  '${pt.evaluacionNombre.split(":").first}: ${pt.porcentajeLogro}% (Nota ${pt.nota})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: esUltimo ? FontWeight.bold : FontWeight.normal,
                                    color: esUltimo ? Colors.indigo.shade900 : Colors.black87,
                                  ),
                                ),
                                backgroundColor: esUltimo ? Colors.indigo.shade100 : Colors.white,
                                side: BorderSide(color: Colors.grey.shade300),
                                visualDensity: VisualDensity.compact,
                              ),
                              if (i < evo.puntos.length - 1)
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                                  child: Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                                ),
                            ],
                          );
                        }).toList(),
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

  Widget _construirMatrizTriageAlumnos() {
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
                Icon(Icons.group_outlined, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Matriz de Triage: Estudiantes en Riesgo por Tema',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Alumnos que registran un logro inferior al 60% en cada tema evaluado:',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),

            ...a.rendimientosPorTema.keys.map((tema) {
              final enRiesgo = a.alumnosEnRiesgoPorTema[tema] ?? [];
              return Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: enRiesgo.isNotEmpty ? Colors.red.shade100 : Colors.green.shade100,
                    child: Text(
                      '${enRiesgo.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: enRiesgo.isNotEmpty ? Colors.red.shade900 : Colors.green.shade900,
                      ),
                    ),
                  ),
                  title: Text(tema, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text(
                    enRiesgo.isNotEmpty
                        ? '${enRiesgo.length} estudiante(s) con brecha detectada'
                        : 'Sin estudiantes en riesgo crítico',
                    style: TextStyle(fontSize: 11, color: enRiesgo.isNotEmpty ? Colors.red.shade700 : Colors.green.shade700),
                  ),
                  children: enRiesgo.isEmpty
                      ? [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8.0),
                            child: Text('¡Excelente! Ningún alumno se encuentra en riesgo en este tema.', style: TextStyle(fontSize: 12, color: Colors.green)),
                          ),
                        ]
                      : enRiesgo.map((al) {
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.person_outline, size: 18, color: Colors.red),
                            title: Text(al.alumnoNombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            trailing: Text(
                              '${al.porcentajeLogroTema}% • Nota ${al.promedioNotaTema}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 12),
                            ),
                          );
                        }).toList(),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
