import 'package:flutter/material.dart';
import '../../datos/fuente_datos_curriculo.dart';
import '../../datos/repositorio_curriculo.dart';
import '../../datos/repositorio_evaluaciones.dart';
import '../../dominio/modelos/clase_escolar.dart';
import '../../dominio/modelos/curriculo.dart';
import '../../dominio/modelos/evaluacion.dart';
import '../curriculo/dialogo_selector_objetivos.dart';
import '../curriculo/pantalla_mapa_curricular.dart';
import 'dialogo_carga_notas.dart';
import 'pantalla_dashboard_brechas.dart';

/// Pantalla docente para gestionar evaluaciones de una clase escolar,
/// visualizar el estado de corrección (notas pendientes) y acceder al triage de brechas.
class PantallaEvaluacionesDocente extends StatefulWidget {
  PantallaEvaluacionesDocente({
    super.key,
    required this.clase,
    required this.repositorioEvaluaciones,
    RepositorioCurriculo? repositorioCurriculo,
    this.objetivoPreseleccionado,
  }) : repositorioCurriculo = repositorioCurriculo ?? FuenteDatosCurriculo();

  final ClaseEscolar clase;
  final RepositorioEvaluaciones repositorioEvaluaciones;
  final RepositorioCurriculo repositorioCurriculo;
  final ObjetivoAprendizaje? objetivoPreseleccionado;

  @override
  State<PantallaEvaluacionesDocente> createState() => _PantallaEvaluacionesDocenteState();
}

class _PantallaEvaluacionesDocenteState extends State<PantallaEvaluacionesDocente> {
  bool _cargando = true;
  List<Evaluacion> _evaluaciones = [];
  Map<String, List<NotaEvaluacion>> _notasPorEvaluacion = {};

  @override
  void initState() {
    super.initState();
    _cargarEvaluacionesYNotas();
    if (widget.objetivoPreseleccionado != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _abrirCrearEvaluacion(objetivoPreseleccionado: widget.objetivoPreseleccionado);
      });
    }
  }

  void _abrirMapaCurricular() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaMapaCurricular(
          clase: widget.clase,
          repositorioCurriculo: widget.repositorioCurriculo,
          repositorioEvaluaciones: widget.repositorioEvaluaciones,
        ),
      ),
    );
    _cargarEvaluacionesYNotas();
  }

  Future<void> _cargarEvaluacionesYNotas() async {
    setState(() => _cargando = true);
    final evals = await widget.repositorioEvaluaciones.obtenerEvaluacionesPorClase(widget.clase.id);
    final Map<String, List<NotaEvaluacion>> notasMap = {};

    for (final eval in evals) {
      final notas = await widget.repositorioEvaluaciones.obtenerNotasPorEvaluacion(eval.id);
      notasMap[eval.id] = notas;
    }

    setState(() {
      _evaluaciones = evals;
      _notasPorEvaluacion = notasMap;
      _cargando = false;
    });
  }

  Future<void> _abrirCrearEvaluacion({ObjetivoAprendizaje? objetivoPreseleccionado}) async {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final temaInputCtrl = TextEditingController();
    final maxNotaCtrl = TextEditingController(text: '7.0');
    final aprobatoriaCtrl = TextEditingController(text: '4.0');
    TipoEvaluacion tipoSeleccionado = TipoEvaluacion.examen;
    DateTime fechaSeleccionada = DateTime.now();

    final List<String> temasSeleccionados = [];
    final List<String> objetivosIdsSeleccionados = [];

    if (objetivoPreseleccionado != null) {
      objetivosIdsSeleccionados.add(objetivoPreseleccionado.id);
      temasSeleccionados.add(objetivoPreseleccionado.etiquetaCompleta);
      nombreCtrl.text = 'Evaluación: ${objetivoPreseleccionado.codigo}';
    } else {
      temasSeleccionados.add('Álgebra');
    }

    final creada = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_task, color: Colors.indigo),
              SizedBox(width: 8),
              Text('Nueva Evaluación'),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la evaluación',
                      hintText: 'Ej. Control 1: Ecuaciones y Álgebra',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tipo de evaluación
                  DropdownButtonFormField<TipoEvaluacion>(
                    value: tipoSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Evaluación',
                      border: OutlineInputBorder(),
                    ),
                    items: TipoEvaluacion.values.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Row(
                          children: [
                            Icon(t.icono, color: t.color, size: 20),
                            const SizedBox(width: 8),
                            Text(t.etiqueta),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => tipoSeleccionado = v);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Fecha
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Fecha: ${fechaSeleccionada.day}/${fechaSeleccionada.month}/${fechaSeleccionada.year}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.calendar_month, color: Colors.indigo),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: fechaSeleccionada,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setModalState(() => fechaSeleccionada = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // BOTÓN PRIMARIO: Selector de Currículo Formal
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: FilledButton.tonalIcon(
                      onPressed: () async {
                        final plan = await widget.repositorioCurriculo.obtenerPlanDeClase(widget.clase.id) ??
                            await widget.repositorioCurriculo.obtenerPlanPorId('plan-mat-8vo');
                        if (plan == null) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('No hay currículo disponible para asignar a esta clase.')),
                            );
                          }
                          return;
                        }
                        if (ctx.mounted) {
                          final seleccionados = await showDialog<List<ObjetivoAprendizaje>>(
                            context: ctx,
                            builder: (_) => DialogoSelectorObjetivos(
                              plan: plan,
                              seleccionadosIniciales: objetivosIdsSeleccionados,
                            ),
                          );
                          if (seleccionados != null) {
                            setModalState(() {
                              for (final obj in seleccionados) {
                                if (!objetivosIdsSeleccionados.contains(obj.id)) {
                                  objetivosIdsSeleccionados.add(obj.id);
                                }
                                if (!temasSeleccionados.contains(obj.etiquetaCompleta)) {
                                  temasSeleccionados.add(obj.etiquetaCompleta);
                                }
                              }
                            });
                          }
                        }
                      },
                      icon: const Icon(Icons.account_tree_outlined, size: 18),
                      label: const Text('🎯 Seleccionar desde Currículo Escolar'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.indigo.shade50,
                        foregroundColor: Colors.indigo.shade900,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),

                  // Temas / Estándares Seleccionados
                  const Text(
                    'Objetivos y Estándares Vinculados:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  if (temasSeleccionados.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.amber.shade900),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Selecciona al menos un objetivo del currículo para alimentar el mapa de cobertura y triage.',
                              style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        ...temasSeleccionados.map((tema) => Chip(
                              label: Text(tema, style: const TextStyle(fontSize: 12)),
                              onDeleted: () {
                                setModalState(() {
                                  temasSeleccionados.remove(tema);
                                  objetivosIdsSeleccionados.removeWhere((id) => tema.contains(id));
                                });
                              },
                              deleteIconColor: Colors.red,
                              backgroundColor: Colors.indigo.shade50,
                              visualDensity: VisualDensity.compact,
                            )),
                      ],
                    ),
                  const SizedBox(height: 10),

                  // Sección secundaria plegable para texto libre
                  Theme(
                    data: Theme.of(ctx).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      dense: true,
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: EdgeInsets.zero,
                      title: Text(
                        '+ Agregar tema manual fuera de currículo (opcional)',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                      ),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: temaInputCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'Tema libre (ej. Repaso general)...',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                onSubmitted: (txt) {
                                  if (txt.trim().isNotEmpty && !temasSeleccionados.contains(txt.trim())) {
                                    setModalState(() {
                                      temasSeleccionados.add(txt.trim());
                                      temaInputCtrl.clear();
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              icon: const Icon(Icons.add, size: 20),
                              onPressed: () {
                                final txt = temaInputCtrl.text.trim();
                                if (txt.isNotEmpty && !temasSeleccionados.contains(txt)) {
                                  setModalState(() {
                                    temasSeleccionados.add(txt);
                                    temaInputCtrl.clear();
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Escala
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: maxNotaCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Nota Máxima',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: aprobatoriaCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Aprobatoria',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Descripción / Instrucciones (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (nombreCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Ingresa el nombre de la evaluación')),
                  );
                  return;
                }
                if (temasSeleccionados.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Agrega al menos un tema u objetivo para habilitar el análisis de brechas')),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );

    if (creada == true) {
      final nueva = Evaluacion(
        id: '',
        nombre: nombreCtrl.text.trim(),
        tipo: tipoSeleccionado,
        fecha: fechaSeleccionada,
        claseId: widget.clase.id,
        temas: temasSeleccionados,
        objetivoIds: objetivosIdsSeleccionados,
        notaMaxima: double.tryParse(maxNotaCtrl.text.replaceAll(',', '.')) ?? 7.0,
        notaAprobatoria: double.tryParse(aprobatoriaCtrl.text.replaceAll(',', '.')) ?? 4.0,
        descripcion: descCtrl.text.trim(),
        fechaCreacion: DateTime.now(),
      );

      await widget.repositorioEvaluaciones.crearEvaluacion(nueva);
      await _cargarEvaluacionesYNotas();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Evaluación "${nueva.nombre}" creada con éxito'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    }
  }

  void _abrirCargaNotas(Evaluacion eval) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DialogoCargaNotas(
        evaluacion: eval,
        clase: widget.clase,
        repositorioEvaluaciones: widget.repositorioEvaluaciones,
        notasActuales: _notasPorEvaluacion[eval.id] ?? [],
        onNotasActualizadas: _cargarEvaluacionesYNotas,
      ),
    );
  }

  Future<void> _eliminarEvaluacion(Evaluacion eval) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Evaluación'),
        content: Text('¿Deseas eliminar "${eval.nombre}"? Se borrarán también las notas cargadas asociadas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (conf == true) {
      await widget.repositorioEvaluaciones.eliminarEvaluacion(eval.id);
      await _cargarEvaluacionesYNotas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evaluación eliminada.')),
        );
      }
    }
  }

  void _abrirDashboardBrechas() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PantallaDashboardBrechas(
          clase: widget.clase,
          repositorioEvaluaciones: widget.repositorioEvaluaciones,
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
            const Text('Evaluaciones & Calificaciones', style: TextStyle(fontSize: 16)),
            Text('${widget.clase.nombre} (${widget.clase.gradoGrupo})', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree_outlined, color: Colors.amberAccent),
            tooltip: 'Mapa Curricular & Cobertura',
            onPressed: _abrirMapaCurricular,
          ),
          IconButton(
            icon: const Icon(Icons.insights, color: Colors.cyanAccent),
            tooltip: 'Ver Dashboard de Brechas (Triage)',
            onPressed: _abrirDashboardBrechas,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarEvaluacionesYNotas,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirCrearEvaluacion,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Evaluación'),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _evaluaciones.isEmpty
              ? _construirEstadoVacio()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Tarjeta de acceso al Mapa Curricular
                    Card(
                      elevation: 2,
                      color: Colors.amber.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.account_tree_outlined, color: Colors.amber, size: 24),
                        ),
                        title: const Text('Mapa Curricular & Cobertura', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Audita objetivos cubiertos vs. brechas de enseñanza y aprendizaje.'),
                        trailing: ElevatedButton.icon(
                          onPressed: _abrirMapaCurricular,
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: const Text('Ver Mapa'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade900,
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Tarjeta de acceso al dashboard de brechas
                    Card(
                      elevation: 2,
                      color: Colors.indigo.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.insights, color: Colors.indigo, size: 24),
                        ),
                        title: const Text('Dashboard de Brechas & Triage', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Detecta el peor tema colectivo, alumnos en riesgo y planes del Asistente Pedagógico.'),
                        trailing: ElevatedButton.icon(
                          onPressed: _abrirDashboardBrechas,
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: const Text('Abrir Triage'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Evaluaciones de la Clase (${_evaluaciones.length}):',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          '${widget.clase.alumnosUids.length} alumnos matriculados',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ..._evaluaciones.map((eval) => _construirTarjetaEvaluacion(eval)),
                  ],
                ),
    );
  }

  Widget _construirEstadoVacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No hay evaluaciones creadas para esta clase',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea exámenes, tareas o quizes y etiquétalos con temas para comenzar el seguimiento de notas y detección de brechas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _abrirCrearEvaluacion,
              icon: const Icon(Icons.add),
              label: const Text('Crear Primera Evaluación'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirTarjetaEvaluacion(Evaluacion eval) {
    final notas = _notasPorEvaluacion[eval.id] ?? [];
    final totalAlumnos = widget.clase.alumnosUids.length;
    final totalCargadas = notas.length;
    final pendientes = totalAlumnos > totalCargadas ? totalAlumnos - totalCargadas : 0;
    final pctCarga = totalAlumnos > 0 ? (totalCargadas / totalAlumnos).clamp(0.0, 1.0) : 0.0;

    Color estadoColor;
    String estadoTexto;
    if (totalAlumnos == 0) {
      estadoColor = Colors.grey;
      estadoTexto = 'Sin alumnos matriculados';
    } else if (totalCargadas >= totalAlumnos) {
      estadoColor = Colors.green.shade700;
      estadoTexto = 'Completada ($totalCargadas/$totalAlumnos)';
    } else if (totalCargadas > 0) {
      estadoColor = Colors.orange.shade800;
      estadoTexto = '$totalCargadas/$totalAlumnos cargadas ($pendientes pendientes)';
    } else {
      estadoColor = Colors.red.shade700;
      estadoTexto = 'Pendiente ($pendientes notas por cargar)';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila superior: Tipo y Fecha
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: eval.tipo.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(eval.tipo.icono, size: 14, color: eval.tipo.color),
                          const SizedBox(width: 4),
                          Text(
                            eval.tipo.etiqueta,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: eval.tipo.color),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${eval.fecha.day}/${eval.fecha.month}/${eval.fecha.year}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                // Badge de estado de notas
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: estadoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: estadoColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        totalCargadas >= totalAlumnos && totalAlumnos > 0
                            ? Icons.check_circle
                            : Icons.access_time_filled,
                        size: 13,
                        color: estadoColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        estadoTexto,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: estadoColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Nombre y descripción
            Text(
              eval.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (eval.descripcion.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                eval.descripcion,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
            const SizedBox(height: 10),

            // Chips de temas evaluados
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: eval.temas.map((tema) {
                return Chip(
                  label: Text(tema),
                  backgroundColor: Colors.grey.shade100,
                  side: BorderSide(color: Colors.grey.shade300),
                  visualDensity: VisualDensity.compact,
                  labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Barra de progreso de notas cargadas
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pctCarga,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(estadoColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _eliminarEvaluacion(eval),
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  label: const Text('Eliminar', style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => _abrirCargaNotas(eval),
                  icon: const Icon(Icons.edit_note, size: 16),
                  label: Text(totalCargadas > 0 ? 'Ver / Editar Notas' : 'Cargar Notas'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: Colors.indigo,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _abrirCargaNotas(eval),
                  icon: const Icon(Icons.upload_file, size: 16),
                  label: const Text('Cargar CSV / Bloque'),
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
