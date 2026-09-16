import 'dart:async';
import 'package:flutter/material.dart';
import '../../datos/repositorio_evaluaciones.dart';
import '../../datos/repositorio_reportes.dart';
import '../../dominio/analisis/generador_reportes.dart';
import '../../dominio/modelos/clase_escolar.dart';
import '../../dominio/modelos/evaluacion.dart';
import '../../dominio/modelos/reporte_pedagogico.dart';
import 'dialogo_editar_reporte.dart';
import 'vista_imprimible_reporte.dart';

/// Pantalla de gestión de reportes pedagógicos a nivel de curso/clase.
/// Ofrece consolidado de la clase, matriz de riesgo multitemático (alumnos con 2+ brechas),
/// generación masiva de snapshots por período y edición de retroalimentación docente.
class PantallaReportesClase extends StatefulWidget {
  PantallaReportesClase({
    super.key,
    this.clase,
    String? claseId,
    String? nombreClase,
    List<Map<String, String>>? alumnos,
    required this.repositorioReportes,
    required this.repositorioEvaluaciones,
  })  : claseId = claseId ?? clase?.id ?? '',
        nombreClase = nombreClase ?? (clase != null ? '${clase.nombre} - ${clase.gradoGrupo}' : ''),
        alumnos = alumnos ??
            (clase != null
                ? clase.alumnosUids
                    .map((uid) => {
                          'uid': uid,
                          'nombre': clase.nombresAlumnos[uid] ?? 'Alumno $uid',
                        })
                    .toList()
                : const []);

  final ClaseEscolar? clase;
  final String claseId;
  final String nombreClase;
  final List<Map<String, String>> alumnos;
  final RepositorioReportes repositorioReportes;
  final RepositorioEvaluaciones repositorioEvaluaciones;

  @override
  State<PantallaReportesClase> createState() => _PantallaReportesClaseState();
}

class _PantallaReportesClaseState extends State<PantallaReportesClase> {
  final List<String> _periodosDisponibles = [
    '1° Trimestre',
    '2° Trimestre',
    '3° Trimestre',
    'Semestre 1',
    'Semestre 2',
  ];

  late String _periodoSeleccionado;
  bool _generandoLote = false;
  String? _regenerandoUid;
  String _filtroRiesgo = 'todos'; // 'todos', 'riesgo', 'sin_brechas'

  StreamSubscription<List<NotaEvaluacion>>? _notasSub;
  List<NotaEvaluacion> _notasClase = [];

  @override
  void initState() {
    super.initState();
    _periodoSeleccionado = _periodosDisponibles.first;
    _iniciarEscuchaNotas();
  }

  @override
  void dispose() {
    _notasSub?.cancel();
    super.dispose();
  }

  void _iniciarEscuchaNotas() {
    _notasSub = widget.repositorioEvaluaciones
        .streamNotasPorClase(widget.claseId)
        .listen((notas) {
      if (mounted) {
        setState(() => _notasClase = notas);
      }
    });
  }

  bool _estaDesactualizado(ReporteEstudiante rep) {
    return GeneradorReportes.esReporteDesactualizado(
      rep,
      _notasClase.where((n) => n.alumnoUid == rep.alumnoUid),
    );
  }

  Future<void> _regenerarReporteAlumno(ReporteEstudiante rep) async {
    setState(() => _regenerandoUid = rep.alumnoUid);

    try {
      final evaluaciones =
          await widget.repositorioEvaluaciones.obtenerEvaluacionesPorClase(widget.claseId);
      final notas =
          await widget.repositorioEvaluaciones.obtenerNotasPorClase(widget.claseId);
      final reportesHistoricos =
          await widget.repositorioReportes.obtenerReportesPorClase(widget.claseId);

      const generador = GeneradorReportes();
      final nuevoReporte = generador.generarReporteEstudiante(
        id: rep.id,
        claseId: widget.claseId,
        periodo: rep.periodo,
        alumnoUid: rep.alumnoUid,
        alumnoNombre: rep.alumnoNombre,
        evaluaciones: evaluaciones,
        notas: notas,
        reportesHistoricos: reportesHistoricos,
        comentarioDocentePersonalizado:
            rep.comentarioDocente.isNotEmpty ? rep.comentarioDocente : null,
      );

      await widget.repositorioReportes.guardarReporte(nuevoReporte);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Reporte de ${rep.alumnoNombre} actualizado y recalculado con éxito!'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al regenerar reporte: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _regenerandoUid = null);
    }
  }

  Future<void> _regenerarReportesDesactualizados(List<ReporteEstudiante> desactualizados) async {
    setState(() => _generandoLote = true);

    try {
      final evaluaciones =
          await widget.repositorioEvaluaciones.obtenerEvaluacionesPorClase(widget.claseId);
      final notas =
          await widget.repositorioEvaluaciones.obtenerNotasPorClase(widget.claseId);
      final reportesHistoricos =
          await widget.repositorioReportes.obtenerReportesPorClase(widget.claseId);

      const generador = GeneradorReportes();
      final nuevos = <ReporteEstudiante>[];

      for (final rep in desactualizados) {
        final nuevo = generador.generarReporteEstudiante(
          id: rep.id,
          claseId: widget.claseId,
          periodo: rep.periodo,
          alumnoUid: rep.alumnoUid,
          alumnoNombre: rep.alumnoNombre,
          evaluaciones: evaluaciones,
          notas: notas,
          reportesHistoricos: reportesHistoricos,
          comentarioDocentePersonalizado:
              rep.comentarioDocente.isNotEmpty ? rep.comentarioDocente : null,
        );
        nuevos.add(nuevo);
      }

      await widget.repositorioReportes.guardarReportesEnBloque(nuevos);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '¡Se actualizaron ${nuevos.length} reporte(s) desactualizado(s) exitosamente!',
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar reportes: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generandoLote = false);
    }
  }

  Future<void> _generarReportesPeriodo() async {
    setState(() => _generandoLote = true);

    try {
      final evaluaciones =
          await widget.repositorioEvaluaciones.obtenerEvaluacionesPorClase(widget.claseId);
      final notas =
          await widget.repositorioEvaluaciones.obtenerNotasPorClase(widget.claseId);
      final reportesHistoricos =
          await widget.repositorioReportes.obtenerReportesPorClase(widget.claseId);

      const generador = GeneradorReportes();
      final nuevosReportes = generador.generarReportesClase(
        claseId: widget.claseId,
        periodo: _periodoSeleccionado,
        alumnos: widget.alumnos,
        evaluaciones: evaluaciones,
        notas: notas,
        reportesHistoricos: reportesHistoricos,
      );

      await widget.repositorioReportes.guardarReportesEnBloque(nuevosReportes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '¡Se generaron exitosamente ${nuevosReportes.length} reportes para "$_periodoSeleccionado"!',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar reportes: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generandoLote = false);
    }
  }

  void _abrirDialogoNuevoPeriodo() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nuevo Período Escolar'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ej. Unidad 1: Fundamentos o Semestre 1',
            labelText: 'Nombre del período',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final texto = controller.text.trim();
              if (texto.isNotEmpty) {
                if (!_periodosDisponibles.contains(texto)) {
                  setState(() {
                    _periodosDisponibles.add(texto);
                    _periodoSeleccionado = texto;
                  });
                } else {
                  setState(() => _periodoSeleccionado = texto);
                }
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _eliminarReporte(ReporteEstudiante reporte) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar Reporte'),
        content: Text(
          '¿Estás seguro de eliminar el reporte de ${reporte.alumnoNombre} para el período "${reporte.periodo}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await widget.repositorioReportes.eliminarReporte(reporte.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reporte eliminado con éxito.'),
                    backgroundColor: Colors.grey,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reportes Pedagógicos por Período',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.nombreClase,
              style: TextStyle(fontSize: 12, color: Colors.indigo.shade100),
            ),
          ],
        ),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<ReporteEstudiante>>(
        stream: widget.repositorioReportes.vigilarReportesPorClase(
          widget.claseId,
          periodo: _periodoSeleccionado,
        ),
        builder: (context, snapshot) {
          final reportes = snapshot.data ?? [];
          final reportesDesactualizados = reportes.where(_estaDesactualizado).toList();

          // Cálculos para la matriz de riesgo del curso
          final totalAlumnos = reportes.length;
          final alumnosSinBrechas =
              reportes.where((r) => r.totalTemasEnRiesgo == 0).length;
          final alumnosUnaBrecha =
              reportes.where((r) => r.totalTemasEnRiesgo == 1).length;
          final alumnosRiesgoMulti =
              reportes.where((r) => r.totalTemasEnRiesgo >= 2).length;

          // Filtrar lista
          final reportesFiltrados = reportes.where((r) {
            if (_filtroRiesgo == 'riesgo') return r.totalTemasEnRiesgo >= 2;
            if (_filtroRiesgo == 'sin_brechas') return r.totalTemasEnRiesgo == 0;
            return true;
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Selector de período y botón de generación
                _construirBarraControl(),
                if (reportesDesactualizados.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _construirAlertaDesactualizados(reportesDesactualizados),
                ],
                const SizedBox(height: 20),

                // 2. Matriz de Riesgo de la Clase (Triage Multitemático)
                if (reportes.isNotEmpty) ...[
                  _construirMatrizRiesgo(
                    total: totalAlumnos,
                    sinBrechas: alumnosSinBrechas,
                    unaBrecha: alumnosUnaBrecha,
                    riesgoMulti: alumnosRiesgoMulti,
                  ),
                  const SizedBox(height: 20),
                ],

                // 3. Encabezado de lista y filtros
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reportes Congelados (${reportesFiltrados.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (reportes.isNotEmpty)
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'todos', label: Text('Todos')),
                          ButtonSegment(
                            value: 'riesgo',
                            label: Text('En Riesgo (2+)'),
                            icon: Icon(Icons.warning_amber_rounded, size: 16),
                          ),
                          ButtonSegment(
                            value: 'sin_brechas',
                            label: Text('Consolidados'),
                            icon: Icon(Icons.check_circle_outline, size: 16),
                          ),
                        ],
                        selected: {_filtroRiesgo},
                        onSelectionChanged: (val) {
                          setState(() => _filtroRiesgo = val.first);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // 4. Lista o Estado Vacío
                if (reportes.isEmpty)
                  _construirEstadoVacio()
                else if (reportesFiltrados.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Text(
                      'No hay estudiantes bajo el filtro "$_filtroRiesgo" en este período.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reportesFiltrados.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final rep = reportesFiltrados[index];
                      return _construirTarjetaReporte(rep);
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _construirBarraControl() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month_outlined, color: Colors.indigo.shade700),
          const SizedBox(width: 10),
          const Text(
            'Período Escolar:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.indigo.shade100),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _periodoSeleccionado,
                items: _periodosDisponibles.map((p) {
                  return DropdownMenuItem(
                    value: p,
                    child: Text(p, style: const TextStyle(fontWeight: FontWeight.w600)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _periodoSeleccionado = val);
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _abrirDialogoNuevoPeriodo,
            icon: const Icon(Icons.add_circle_outline, size: 20),
            tooltip: 'Crear otro período personalizado',
            color: Colors.indigo,
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: _generandoLote ? null : _generarReportesPeriodo,
            icon: _generandoLote
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.published_with_changes, size: 18),
            label: Text(
              _generandoLote ? 'Congelando Snapshots...' : 'Generar Reportes del Período',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.indigo,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirAlertaDesactualizados(List<ReporteEstudiante> desactualizados) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(Icons.sync_problem, color: Colors.amber.shade900, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${desactualizados.length} reporte(s) desactualizado(s)',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
                Text(
                  'Se modificaron calificaciones con posterioridad a la fecha del snapshot. '
                  'Sincroniza para actualizar el análisis curricular.',
                  style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _generandoLote
                ? null
                : () => _regenerarReportesDesactualizados(desactualizados),
            icon: const Icon(Icons.sync, size: 16),
            label: Text('Actualizar (${desactualizados.length})',
                style: const TextStyle(fontSize: 12)),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.amber.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirMatrizRiesgo({
    required int total,
    required int sinBrechas,
    required int unaBrecha,
    required int riesgoMulti,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.dashboard_customize_outlined, size: 18, color: Colors.grey.shade800),
            const SizedBox(width: 8),
            const Text(
              'Consolidado del Curso y Matriz de Riesgo',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _tarjetaMetrica(
                titulo: 'Alumnos Evaluados',
                valor: '$total',
                subtitulo: 'Snapshots congelados',
                color: Colors.indigo,
                icono: Icons.people_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _tarjetaMetrica(
                titulo: 'Sin Brechas',
                valor: '$sinBrechas',
                subtitulo: 'Todos los temas >60%',
                color: Colors.green,
                icono: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _tarjetaMetrica(
                titulo: 'En Seguimiento (1 tema)',
                valor: '$unaBrecha',
                subtitulo: 'Brecha focalizada',
                color: Colors.amber.shade800,
                icono: Icons.info_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _tarjetaMetrica(
                titulo: 'Riesgo Crítico (2+ temas)',
                valor: '$riesgoMulti',
                subtitulo: 'Requiere tutoría urgente',
                color: Colors.red.shade700,
                icono: Icons.warning_amber_rounded,
                resaltado: riesgoMulti > 0,
              ),
            ),
          ],
        ),
        if (riesgoMulti > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.campaign, color: Colors.red.shade800, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Alerta Pedagógica: $riesgoMulti estudiante(s) presentan dos o más brechas curriculares simultáneas en este período. '
                    'Usa el filtro "En Riesgo" para coordinar un plan de nivelación focalizado.',
                    style: TextStyle(fontSize: 12.5, color: Colors.red.shade900, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _tarjetaMetrica({
    required String titulo,
    required String valor,
    required String subtitulo,
    required Color color,
    required IconData icono,
    bool resaltado = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: resaltado ? color : Colors.grey.shade200, width: resaltado ? 1.5 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titulo,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
              ),
              Icon(icono, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            subtitulo,
            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _construirTarjetaReporte(ReporteEstudiante rep) {
    final enRiesgo = rep.enRiesgoMultitematico;
    final tieneBrechas = rep.totalTemasEnRiesgo > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enRiesgo ? Colors.red.shade300 : Colors.grey.shade200,
          width: enRiesgo ? 1.5 : 1,
        ),
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
          // Fila superior: alumno, estado de riesgo y acciones
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: enRiesgo ? Colors.red.shade100 : Colors.indigo.shade50,
                child: Text(
                  rep.alumnoNombre.isNotEmpty ? rep.alumnoNombre[0].toUpperCase() : 'A',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: enRiesgo ? Colors.red.shade800 : Colors.indigo.shade800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          rep.alumnoNombre,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        if (enRiesgo)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning, size: 12, color: Colors.red.shade800),
                                const SizedBox(width: 4),
                                Text(
                                  '${rep.totalTemasEnRiesgo} temas en riesgo',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade800,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (tieneBrechas)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '1 tema a nivelar',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Consolidado',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      'Promedio: ${rep.promedioGeneral.toStringAsFixed(1)} • Logro: ${rep.porcentajeGeneral.toStringAsFixed(0)}% • Período: ${rep.periodo}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    if (_estaDesactualizado(rep)) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.shade400),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.history_toggle_off, size: 13, color: Colors.amber.shade900),
                            const SizedBox(width: 4),
                            Text(
                              'Nota modificada posterior al reporte (Desactualizado)',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _regenerandoUid != null
                                  ? null
                                  : () => _regenerarReporteAlumno(rep),
                              child: Text(
                                'Sincronizar',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.indigo.shade900,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Botones de acción
              IconButton(
                onPressed: _regenerandoUid != null
                    ? null
                    : () => _regenerarReporteAlumno(rep),
                icon: _regenerandoUid == rep.alumnoUid
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.sync,
                        size: 20,
                        color: _estaDesactualizado(rep) ? Colors.amber.shade900 : Colors.indigo,
                      ),
                tooltip: _estaDesactualizado(rep)
                    ? 'Regenerar snapshot (notas desactualizadas)'
                    : 'Regenerar snapshot de este alumno',
              ),
              const SizedBox(width: 4),
              OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => DialogoEditarReporte(
                      reporte: rep,
                      repositorioReportes: widget.repositorioReportes,
                    ),
                  );
                },
                icon: const Icon(Icons.edit_note, size: 16),
                label: const Text('Comentario', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  side: BorderSide(color: Colors.indigo.shade200),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => VistaImprimibleReporte(
                        reporte: rep,
                        nombreClase: widget.nombreClase,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('Ver / Imprimir', style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _eliminarReporte(rep),
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                tooltip: 'Eliminar reporte',
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Lista de temas priorizados (brechas primero)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: rep.temasPriorizados.map((tema) {
              final esBrecha = tema.esBrechaCritica;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: esBrecha ? Colors.red.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: esBrecha ? Colors.red.shade200 : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (esBrecha) ...[
                      Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red.shade700),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      tema.tema,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: esBrecha ? FontWeight.bold : FontWeight.w500,
                        color: esBrecha ? Colors.red.shade900 : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${tema.porcentajeDominio.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: tema.nivelDominio.color,
                      ),
                    ),
                    if (tema.tendenciaInterPeriodo != TendenciaInterPeriodo.primeraMedicion) ...[
                      const SizedBox(width: 4),
                      Text(
                        tema.tendenciaInterPeriodo == TendenciaInterPeriodo.mejora
                            ? '📈'
                            : (tema.tendenciaInterPeriodo == TendenciaInterPeriodo.regresion ? '📉' : '➖'),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),

          // Vista previa del comentario docente
          if (rep.comentarioDocente.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.indigo.shade100),
              ),
              child: Text(
                'Docente: "${rep.comentarioDocente}"',
                style: TextStyle(fontSize: 12, color: Colors.indigo.shade900, fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _construirEstadoVacio() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 40),
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_stories_outlined, size: 36, color: Colors.indigo),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay reportes congelados para "$_periodoSeleccionado"',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Al generar los reportes del período, el sistema calculará automáticamente los dominios por tema a partir de las calificaciones cargadas y congelará un snapshot inmutable para cada estudiante.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _generandoLote ? null : _generarReportesPeriodo,
              icon: const Icon(Icons.published_with_changes, size: 18),
              label: const Text('Generar Reportes Oficiales Ahora'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
