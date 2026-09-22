import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../datos/fuente_datos_clases.dart';
import '../datos/fuente_datos_diagnostico.dart';
import '../datos/repositorio_clases.dart';
import '../datos/repositorio_diagnostico.dart';
import '../datos/repositorio_ejercicios.dart';
import '../datos/servicio_auth.dart';
import '../dominio/diagnostico/analizador_diagnostico.dart';
import '../dominio/evaluadores/servicio_evaluacion.dart';
import '../dominio/generadores/generador_aritmetica.dart';
import '../dominio/modelos/aritmetico.dart';
import '../dominio/modelos/clase_escolar.dart';
import '../dominio/modelos/ejercicio.dart';
import '../dominio/modelos/examen_diagnostico.dart';
import '../dominio/modelos/usuario_app.dart';
import '../datos/fuente_datos_evaluaciones.dart';
import '../datos/fuente_datos_reportes.dart';
import '../datos/fuente_datos_curriculo.dart';
import '../datos/repositorio_curriculo.dart';
import '../datos/repositorio_evaluaciones.dart';
import '../datos/repositorio_reportes.dart';
import 'curriculo/pantalla_mapa_curricular.dart';
import 'evaluaciones/pantalla_dashboard_brechas.dart';
import 'evaluaciones/pantalla_evaluaciones_docente.dart';
import 'pantalla_crear_ejercicio.dart';
import 'pantalla_ejercicios.dart';
import 'reportes/pantalla_reportes_clase.dart';
import '../datos/fuente_datos_politicas.dart';
import '../datos/fuente_datos_sesiones_clase.dart';
import '../datos/fuente_datos_auditoria.dart';
import '../datos/repositorio_politicas.dart';
import '../datos/repositorio_sesiones_clase.dart';
import '../datos/repositorio_auditoria.dart';
import '../datos/servicio_horarios.dart';
import '../dominio/modelos/sesion_modo_clase.dart';
import 'profesor/dialogo_gestion_modo_clase.dart';
import '../datos/coordinador_sincronizacion_offline.dart';
import '../datos/fuente_datos_materiales_offline.dart';
import 'offline/dialogo_compartir_material_docente.dart';

/// Interfaz especializada para el Profesor / Docente.
/// Panel de administración para crear, catalogar, monitorear diagnósticos de errores,
/// y configurar exámenes diagnósticos con variables de avance.
class PantallaProfesor extends StatefulWidget {
  PantallaProfesor({
    super.key,
    required this.usuario,
    required this.repositorio,
    required this.servicioEvaluacion,
    required this.servicioAuth,
    RepositorioDiagnostico? repositorioDiagnostico,
    RepositorioClases? repositorioClases,
    RepositorioEvaluaciones? repositorioEvaluaciones,
    RepositorioReportes? repositorioReportes,
    RepositorioCurriculo? repositorioCurriculo,
    RepositorioPoliticas? repositorioPoliticas,
    RepositorioSesionesClase? repositorioSesiones,
    RepositorioAuditoria? repositorioAuditoria,
    ServicioHorarios? servicioHorarios,
    CoordinadorSincronizacionOffline? coordinadorOffline,
  })  : repositorioDiagnostico = repositorioDiagnostico ?? FuenteDatosDiagnostico(),
        repositorioClases = repositorioClases ?? FuenteDatosClases(),
        repositorioEvaluaciones = repositorioEvaluaciones ?? FuenteDatosEvaluaciones(),
        repositorioReportes = repositorioReportes ?? FuenteDatosReportes(),
        repositorioCurriculo = repositorioCurriculo ?? FuenteDatosCurriculo(),
        repositorioPoliticas = repositorioPoliticas ?? FuenteDatosPoliticas(),
        repositorioAuditoria = repositorioAuditoria ?? FuenteDatosAuditoria(),
        repositorioSesiones = repositorioSesiones ??
            FuenteDatosSesionesClase(
              repositorioPoliticas: repositorioPoliticas ?? FuenteDatosPoliticas(),
              repositorioAuditoria: repositorioAuditoria ?? FuenteDatosAuditoria(),
            ),
        servicioHorarios = servicioHorarios ?? ServicioHorarios(),
        coordinadorOffline = coordinadorOffline ??
            CoordinadorSincronizacionOffline(
              repositorio: FuenteDatosMaterialesOffline(),
            );

  final UsuarioApp usuario;
  final RepositorioEjercicios repositorio;
  final ServicioEvaluacion servicioEvaluacion;
  final ServicioAuth servicioAuth;
  final RepositorioDiagnostico repositorioDiagnostico;
  final RepositorioClases repositorioClases;
  final RepositorioEvaluaciones repositorioEvaluaciones;
  final RepositorioReportes repositorioReportes;
  final RepositorioCurriculo repositorioCurriculo;
  final RepositorioPoliticas repositorioPoliticas;
  final RepositorioSesionesClase repositorioSesiones;
  final RepositorioAuditoria repositorioAuditoria;
  final ServicioHorarios servicioHorarios;
  final CoordinadorSincronizacionOffline coordinadorOffline;

  @override
  State<PantallaProfesor> createState() => _PantallaProfesorState();
}

class _PantallaProfesorState extends State<PantallaProfesor> {
  late final CoordinadorSincronizacionOffline _coordinadorOffline;
  List<Ejercicio> _ejercicios = [];
  bool _cargando = true;
  final GeneradorAritmetica _generador = GeneradorAritmetica();

  @override
  void initState() {
    super.initState();
    _coordinadorOffline = widget.coordinadorOffline;
    _cargarEjercicios();
  }

  Future<void> _cargarEjercicios() async {
    setState(() => _cargando = true);
    final lista = await widget.repositorio.obtenerTodos();
    setState(() {
      _ejercicios = lista;
      _cargando = false;
    });
  }

  Future<void> _abrirCrearEjercicio() async {
    final creado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PantallaCrearEjercicio(repositorio: widget.repositorio),
      ),
    );
    if (creado == true) {
      await _cargarEjercicios();
    }
  }

  Future<void> _eliminarEjercicio(Ejercicio ejercicio) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Ejercicio'),
        content: Text('¿Estás seguro de eliminar el ejercicio ${ejercicio.codigoTema} (${ejercicio.enunciado})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await widget.repositorio.eliminarEjercicio(ejercicio.id);
      await _cargarEjercicios();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ejercicio eliminado del catálogo')),
        );
      }
    }
  }

  void _probarModoAlumno() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PantallaEjercicios(
          repositorio: widget.repositorio,
          servicioEvaluacion: widget.servicioEvaluacion,
        ),
      ),
    );
  }

  Future<void> _generarLotePreguntas(OperacionAritmetica op, int cantidad) async {
    for (int i = 0; i < cantidad; i++) {
      final ej = _generador.generar(operacion: op, nivel: (i % 3) + 1);
      await widget.repositorio.agregarEjercicio(ej);
    }
    await _cargarEjercicios();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Se han generado $cantidad ejercicios de ${op.name.toUpperCase()}!'),
          backgroundColor: Colors.indigo,
        ),
      );
    }
  }

  Future<void> _generarRefuerzoGrupal(List<String> tagsCriticos) async {
    if (tagsCriticos.isEmpty) return;
    for (int i = 0; i < 3; i++) {
      final ej = _generador.generarRefuerzoParaTags(tagsCriticos, nivel: (i % 2) + 1);
      await widget.repositorio.agregarEjercicio(ej);
    }
    await _cargarEjercicios();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Se agregaron 3 ejercicios de refuerzo adaptativo al catálogo!'),
          backgroundColor: Colors.teal,
        ),
      );
    }
  }

  void _mostrarDiagnosticoDocente() async {
    final intentos = await widget.repositorioDiagnostico.obtenerTodosLosIntentos();
    const analizador = AnalizadorDiagnostico();
    final diag = analizador.analizar(usuarioUid: 'global_clase', intentos: intentos);

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
                        Icon(Icons.psychology_outlined, color: Colors.indigo.shade800, size: 28),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Monitor Docente de Errores & Dificultades',
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

              // Resumen General de la Clase
              Row(
                children: [
                  Expanded(
                    child: _construirTarjetaMetrica(
                      'Intentos Evaluados',
                      '${diag.totalIntentos}',
                      Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _construirTarjetaMetrica(
                      'Aciertos',
                      '${diag.aciertos}',
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _construirTarjetaMetrica(
                      'Tasa de Fallo',
                      diag.totalIntentos > 0
                          ? '${(100 - diag.porcentajePrecision).toStringAsFixed(1)}%'
                          : '0%',
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tags Críticos de la Clase
              const Text(
                '🏷️ Tags & Conceptos Más Fallados:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (diag.distribucionPorTag.isEmpty)
                const Text('No hay registros suficientes para calcular tags críticos.', style: TextStyle(color: Colors.grey))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: diag.distribucionPorTag.entries.map((entry) {
                    final esCritico = entry.value >= 2;
                    return Chip(
                      avatar: Icon(Icons.tag, size: 14, color: esCritico ? Colors.red : Colors.orange),
                      label: Text('${entry.key}: ${entry.value} errores', style: TextStyle(fontSize: 12, fontWeight: esCritico ? FontWeight.bold : FontWeight.normal)),
                      backgroundColor: esCritico ? Colors.red.shade50 : Colors.orange.shade50,
                      side: BorderSide(color: esCritico ? Colors.red.shade200 : Colors.orange.shade200),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),

              // Botón de intervención grupal
              if (diag.tagsCriticos.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _generarRefuerzoGrupal(diag.tagsCriticos);
                  },
                  icon: const Icon(Icons.add_task),
                  label: const Text('GENERAR 3 EJERCICIOS DE REFUERZO PARA LA CLASE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              const SizedBox(height: 20),

              // Ranking de Errores Prominentes
              const Text(
                '📊 Errores Prominentes Clasificados:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (diag.erroresProminentes.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('No se registran patrones de error en los intentos actuales.'),
                )
              else
                ...diag.erroresProminentes.map((err) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Text(err.categoria.icono, style: const TextStyle(fontSize: 24)),
                        title: Text(
                          '${err.categoria.etiqueta}: ${err.subtipo}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: Text(err.descripcion, style: const TextStyle(fontSize: 12)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${err.conteo} fallos',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900, fontSize: 11),
                          ),
                        ),
                      ),
                    )),
              const SizedBox(height: 20),

              // Recomendaciones Pedagógicas para el Docente
              const Text(
                '🎓 Guía de Intervención Pedagógica para el Docente:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...diag.recomendacionesRefuerzo.map((rec) => Card(
                    color: Colors.indigo.shade50,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(rec.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(rec.prioridad.etiqueta, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(rec.explicacion, style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 6),
                          Text('👉 Sugerencia Didáctica: ${rec.accionSugerida}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.indigo)),
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

  void _mostrarGestorExamenes() async {
    final examenes = await widget.repositorioDiagnostico.obtenerExamenes();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
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
                          Icon(Icons.fact_check_outlined, color: Colors.indigo.shade800, size: 28),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Gestor de Exámenes Diagnósticos & Avance',
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

                ElevatedButton.icon(
                  onPressed: () => _abrirFormularioNuevoExamen(ctx),
                  icon: const Icon(Icons.add),
                  label: const Text('DISEÑAR NUEVO EXAMEN DIAGNÓSTICO'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Exámenes Configurados por el Docente:',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                if (examenes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No hay exámenes diagnósticos creados.', textAlign: TextAlign.center),
                  )
                else
                  ...examenes.map((exam) => Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                                      exam.titulo,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.indigo.shade200),
                                    ),
                                    child: Text(
                                      '${exam.totalPreguntas} preguntas',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(exam.descripcion, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                              const Divider(height: 16),

                              // Caja de la Variable de Avance del Profesor
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.teal.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.rule, size: 16, color: Colors.teal),
                                        const SizedBox(width: 6),
                                        const Text('Variable de Avance Docente:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.teal)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('• Criterio: ${exam.criterioAvance.etiqueta}', style: const TextStyle(fontSize: 12)),
                                    Text('• Umbral Exigido: ${(exam.umbralAvance <= 1.0 ? exam.umbralAvance * 100 : exam.umbralAvance).toInt()}% para avanzar', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    Text('• Desbloqueo Automático: ${exam.permitirAvanceAutomatico ? "Sí (Inmediato)" : "No (Requiere revisión)"}', style: const TextStyle(fontSize: 12)),
                                    if (exam.temaDestinoAlAvanzar != null)
                                      Text('• Destino al Aprobar: ${exam.temaDestinoAlAvanzar}', style: const TextStyle(fontSize: 12, color: Colors.indigo)),
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
      ),
    );
  }

  void _abrirFormularioNuevoExamen(BuildContext contextPadre) {
    final tituloCtrl = TextEditingController(text: 'Diagnóstico Curricular Especial');
    final descCtrl = TextEditingController(text: 'Evaluación de nivelación y avance.');
    final temaDestinoCtrl = TextEditingController(text: 'Tema 2: Álgebra');
    CriterioAvance criterio = CriterioAvance.porcentajeAciertosMinimo;
    double umbral = 0.70; // 70%
    bool autoAvance = true;
    final List<Ejercicio> ejerciciosSeleccionados = List.from(_ejercicios.take(4));

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Nuevo Examen Diagnóstico'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: tituloCtrl,
                    decoration: const InputDecoration(labelText: 'Título del Examen', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Descripción / Instrucciones', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),

                  // Variable de Avance Configurable
                  const Text('⚙️ Configuración de la Variable de Avance:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<CriterioAvance>(
                    initialValue: criterio,
                    decoration: const InputDecoration(labelText: 'Criterio de Avance', border: OutlineInputBorder()),
                    items: CriterioAvance.values.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c.etiqueta, style: const TextStyle(fontSize: 12)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDlgState(() => criterio = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('Umbral de Avance: ${(umbral * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Expanded(
                        child: Slider(
                          value: umbral,
                          min: 0.50,
                          max: 1.00,
                          divisions: 10,
                          label: '${(umbral * 100).toInt()}%',
                          onChanged: (v) => setDlgState(() => umbral = v),
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    title: const Text('Permitir Avance Automático', style: TextStyle(fontSize: 13)),
                    subtitle: const Text('Desbloquea el tema destino si el alumno supera el umbral', style: TextStyle(fontSize: 11)),
                    value: autoAvance,
                    onChanged: (v) => setDlgState(() => autoAvance = v),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  TextField(
                    controller: temaDestinoCtrl,
                    decoration: const InputDecoration(labelText: 'Tema Desbloqueado al Superar', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),

                  Text('Ejercicios incluidos: ${ejerciciosSeleccionados.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (tituloCtrl.text.trim().isEmpty) return;

                final nuevoExamen = ExamenDiagnostico(
                  id: 'EXAM-${DateTime.now().millisecondsSinceEpoch}',
                  titulo: tituloCtrl.text.trim(),
                  descripcion: descCtrl.text.trim(),
                  profesorUid: widget.usuario.uid,
                  profesorNombre: widget.usuario.nombre.isNotEmpty ? widget.usuario.nombre : 'Profesor',
                  ejercicios: ejerciciosSeleccionados,
                  tagsEvaluados: ejerciciosSeleccionados.expand((e) => e.tags).toSet().toList(),
                  criterioAvance: criterio,
                  umbralAvance: umbral,
                  permitirAvanceAutomatico: autoAvance,
                  temaDestinoAlAvanzar: temaDestinoCtrl.text.trim().isNotEmpty ? temaDestinoCtrl.text.trim() : null,
                  fechaCreacion: DateTime.now(),
                );

                await widget.repositorioDiagnostico.guardarExamen(nuevoExamen);
                if (dlgCtx.mounted) {
                  Navigator.pop(dlgCtx);
                }
                if (contextPadre.mounted) {
                  Navigator.pop(contextPadre);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('¡Examen "${nuevoExamen.titulo}" guardado con umbral del ${(umbral * 100).toInt()}%!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              child: const Text('Guardar Examen'),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────── CLASSROOM ───────────────

  void _mostrarGestorClassroom() async {
    final clases = await widget.repositorioClases.obtenerClasesPorProfesor(widget.usuario.uid);
    if (!mounted) return;

    String? filtroInstitucion;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final clasesFiltradas = filtroInstitucion == null
              ? clases
              : clases.where((c) => c.institucionId == filtroInstitucion).toList();

          // Obtener conjunto de instituciones representadas
          final institucionesDisponibles = <String>{
            ...widget.usuario.todasLasInstituciones,
            ...clases.map((c) => c.institucionId),
          }.toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.88,
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
                                'Mis Clases & Classroom',
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
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _abrirFormularioNuevaClase();
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('CREAR NUEVA CLASE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filtro por Institución si hay múltiples
                  if (institucionesDisponibles.length > 1) ...[
                    Row(
                      children: [
                        const Icon(Icons.filter_alt_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Filtrar por Institución:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: Text('Todas (${clases.length})'),
                            selected: filtroInstitucion == null,
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() => filtroInstitucion = null);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          ...institucionesDisponibles.map((inst) {
                            final totalEnInst = clases.where((c) => c.institucionId == inst).length;
                            final nombreCorto = inst == 'INST-SAN-MARTIN'
                                ? 'San Martín'
                                : (inst == 'INST-BELGRANO' ? 'Belgrano' : inst);
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text('$nombreCorto ($totalEnInst)'),
                                selected: filtroInstitucion == inst,
                                onSelected: (selected) {
                                  setModalState(() {
                                    filtroInstitucion = selected ? inst : null;
                                  });
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  Text(
                    filtroInstitucion == null
                        ? 'Tus Clases Escolares (Todas las Instituciones):'
                        : 'Clases en $filtroInstitucion:',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (clasesFiltradas.isEmpty)
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
                          Text('No se encontraron clases en esta institución.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                          SizedBox(height: 4),
                          Text(
                            'Crea una clase para esta institución y comparte el código con tus alumnos.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  else
                    ...clasesFiltradas.map((c) => _construirTarjetaClaseProfesor(c, ctx)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _construirTarjetaClaseProfesor(ClaseEscolar clase, BuildContext sheetCtx) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(clase.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(clase.gradoGrupo, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.indigo.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.account_balance, size: 10, color: Colors.indigo.shade700),
                                const SizedBox(width: 3),
                                Text(
                                  clase.institucionId == 'INST-SAN-MARTIN'
                                      ? 'San Martín'
                                      : (clase.institucionId == 'INST-BELGRANO'
                                          ? 'Belgrano'
                                          : clase.institucionId),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 20),
                  tooltip: 'Eliminar clase',
                  onPressed: () async {
                    if (!sheetCtx.mounted) return;
                    final confirmar = await showDialog<bool>(
                      context: sheetCtx,
                      builder: (d) => AlertDialog(
                        title: const Text('Eliminar Clase'),
                        content: Text('¿Eliminar "${clase.nombre}"? Los alumnos perderán el acceso.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(d, true),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    );
                    if (confirmar == true) {
                      await widget.repositorioClases.eliminarClase(clase.id);
                      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                      if (mounted) _mostrarGestorClassroom();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade300, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Código para Alumnos:', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          clase.codigoAcceso,
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green.shade900, letterSpacing: 2),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_outlined, color: Colors.green),
                    tooltip: 'Copiar código',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: clase.codigoAcceso));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Código "${clase.codigoAcceso}" copiado'),
                          backgroundColor: Colors.green.shade700,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.group_outlined, size: 16, color: Colors.indigo.shade700),
                    const SizedBox(width: 6),
                    Text(
                      '${clase.totalAlumnos} alumno${clase.totalAlumnos != 1 ? "s" : ""} inscrito${clase.totalAlumnos != 1 ? "s" : ""}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.indigo.shade700),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _abrirDialogoInscribirAlumno(clase, sheetCtx),
                  icon: const Icon(Icons.person_add_alt_1, size: 16),
                  label: const Text('Inscribir Alumno', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: Colors.indigo.shade800,
                  ),
                ),
              ],
            ),
            if (clase.nombresAlumnos.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: clase.nombresAlumnos.entries
                    .map((entry) => InputChip(
                          avatar: const Icon(Icons.person_outline, size: 14),
                          label: Text(entry.value, style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: Colors.blue.shade50,
                          tooltip: 'Toca para editar nombre / Cruz para desmatricular',
                          onPressed: () => _editarNombreAlumno(clase, entry.key, entry.value, sheetCtx),
                          onDeleted: () => _eliminarAlumnoDeClase(clase, entry.key, entry.value, sheetCtx),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PantallaEvaluacionesDocente(
                            clase: clase,
                            repositorioEvaluaciones: widget.repositorioEvaluaciones,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.assignment_turned_in_outlined, size: 16),
                    label: const Text('Evaluaciones & Notas', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PantallaDashboardBrechas(
                            clase: clase,
                            repositorioEvaluaciones: widget.repositorioEvaluaciones,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.insights, size: 16),
                    label: const Text('Triage Brechas', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.indigo,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PantallaReportesClase(
                        clase: clase,
                        repositorioReportes: widget.repositorioReportes,
                        repositorioEvaluaciones: widget.repositorioEvaluaciones,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.auto_stories_outlined, size: 16),
                label: const Text(
                  'Reportes Pedagógicos por Período (Snapshots)',
                  style: TextStyle(fontSize: 12),
                ),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  DialogoCompartirMaterialDocente.mostrar(
                    context: sheetCtx,
                    claseId: clase.id,
                    profesorNombre: widget.usuario.nombre,
                    coordinador: _coordinadorOffline,
                    materiaPredeterminada: clase.nombre,
                  );
                },
                icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                label: const Text(
                  'Compartir Material / Web Offline para la Clase',
                  style: TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.teal.shade800,
                  side: BorderSide(color: Colors.teal.shade300),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirDialogoInscribirAlumno(ClaseEscolar clase, BuildContext sheetCtx) async {
    final ctrl = TextEditingController();
    final nombre = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_add, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Inscribir Alumno'),
          ],
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre y apellido del alumno',
            hintText: 'Ej. Valentina Castro',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(d, ctrl.text.trim()),
            child: const Text('Inscribir'),
          ),
        ],
      ),
    );

    if (nombre != null && nombre.isNotEmpty) {
      await widget.repositorioClases.inscribirAlumnoDirecto(
        claseId: clase.id,
        alumnoNombre: nombre,
      );
      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
      if (mounted) _mostrarGestorClassroom();
    }
  }

  Future<void> _editarNombreAlumno(
    ClaseEscolar clase,
    String alumnoUid,
    String nombreActual,
    BuildContext sheetCtx,
  ) async {
    final ctrl = TextEditingController(text: nombreActual);
    final nuevoNombre = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Editar Nombre de Alumno'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre del alumno',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(d, ctrl.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (nuevoNombre != null && nuevoNombre.isNotEmpty && nuevoNombre != nombreActual) {
      await widget.repositorioClases.actualizarNombreAlumno(
        claseId: clase.id,
        alumnoUid: alumnoUid,
        nuevoNombre: nuevoNombre,
      );
      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
      if (mounted) _mostrarGestorClassroom();
    }
  }

  Future<void> _eliminarAlumnoDeClase(
    ClaseEscolar clase,
    String alumnoUid,
    String alumnoNombre,
    BuildContext sheetCtx,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Desmatricular Alumno'),
        content: Text('¿Deseas remover a $alumnoNombre de la clase "${clase.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await widget.repositorioClases.salirDeClase(claseId: clase.id, alumnoUid: alumnoUid);
      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
      if (mounted) _mostrarGestorClassroom();
    }
  }

  void _abrirSelectorEvaluacionesDocente() async {
    final clases = await widget.repositorioClases.obtenerClasesPorProfesor(widget.usuario.uid);
    if (!mounted) return;

    if (clases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero crea una clase escolar para gestionar evaluaciones.')),
      );
      _mostrarGestorClassroom();
      return;
    }

    if (clases.length == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PantallaEvaluacionesDocente(
            clase: clases.first,
            repositorioEvaluaciones: widget.repositorioEvaluaciones,
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona una Clase para Evaluaciones & Triage:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...clases.map((c) => ListTile(
                  leading: const Icon(Icons.class_outlined, color: Colors.indigo),
                  title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${c.gradoGrupo} • ${c.alumnosUids.length} alumnos'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PantallaEvaluacionesDocente(
                          clase: c,
                          repositorioEvaluaciones: widget.repositorioEvaluaciones,
                        ),
                      ),
                    );
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _abrirSelectorReportesDocente() async {
    final clases = await widget.repositorioClases.obtenerClasesPorProfesor(widget.usuario.uid);
    if (!mounted) return;

    if (clases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero crea una clase escolar para gestionar reportes pedagógicos.')),
      );
      _mostrarGestorClassroom();
      return;
    }

    if (clases.length == 1) {
      final c = clases.first;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PantallaReportesClase(
            clase: c,
            repositorioReportes: widget.repositorioReportes,
            repositorioEvaluaciones: widget.repositorioEvaluaciones,
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona una Clase para Ver/Generar Reportes:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...clases.map((c) => ListTile(
                  leading: const Icon(Icons.auto_stories_outlined, color: Colors.indigo),
                  title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${c.gradoGrupo} • ${c.alumnosUids.length} alumnos'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PantallaReportesClase(
                          clase: c,
                          repositorioReportes: widget.repositorioReportes,
                          repositorioEvaluaciones: widget.repositorioEvaluaciones,
                        ),
                      ),
                    );
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _abrirSelectorMapaCurricularDocente() async {
    final clases = await widget.repositorioClases.obtenerClasesPorProfesor(widget.usuario.uid);
    if (!mounted) return;

    if (clases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero crea una clase escolar para acceder a la planificación curricular.')),
      );
      _mostrarGestorClassroom();
      return;
    }

    if (clases.length == 1) {
      final c = clases.first;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PantallaMapaCurricular(
            clase: c,
            repositorioCurriculo: widget.repositorioCurriculo,
            repositorioEvaluaciones: widget.repositorioEvaluaciones,
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona una Clase para Ver su Mapa Curricular:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...clases.map((c) => ListTile(
                  leading: const Icon(Icons.account_tree_outlined, color: Colors.indigo),
                  title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${c.gradoGrupo} • ${c.alumnosUids.length} alumnos'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PantallaMapaCurricular(
                          clase: c,
                          repositorioCurriculo: widget.repositorioCurriculo,
                          repositorioEvaluaciones: widget.repositorioEvaluaciones,
                        ),
                      ),
                    );
                  },
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirFormularioNuevaClase() async {
    final nombreCtrl = TextEditingController(text: 'Matemáticas');
    final gradoCtrl = TextEditingController(text: '5° Primaria');
    final descCtrl = TextEditingController(text: 'Clase de matemáticas del ciclo escolar.');
    final prefijoCtrl = TextEditingController();
    String instSeleccionada = widget.usuario.institucionId;
    final todasInsts = widget.usuario.todasLasInstituciones;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (dCtx, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.class_outlined, color: Colors.green),
              SizedBox(width: 8),
              Text('Nueva Clase Escolar'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: instSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Institución Educativa',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_balance),
                    ),
                    items: todasInsts.map((inst) {
                      final nombreInst = inst == 'INST-SAN-MARTIN'
                          ? 'Colegio San Martín'
                          : (inst == 'INST-BELGRANO' ? 'Instituto Belgrano' : inst);
                      return DropdownMenuItem(
                        value: inst,
                        child: Text('$nombreInst ($inst)', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDlgState(() => instSeleccionada = val);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la Clase',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.school),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: gradoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Grado / Grupo',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.grade),
                      hintText: 'Ej: 5° Primaria, 3° Sec Grupo B',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Descripción del Curso', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: prefijoCtrl,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 3,
                    decoration: const InputDecoration(
                      labelText: 'Prefijo del Código (Opcional)',
                      border: OutlineInputBorder(),
                      hintText: 'Ej: MAT, FIS, ESP',
                      helperText: 'Se generará automáticamente si lo dejas vacío',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.green),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Se generará un código único (ej. MAT-7429) para compartir con tus alumnos.',
                            style: TextStyle(fontSize: 11, color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dlgCtx, false), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () => Navigator.pop(dlgCtx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
              child: const Text('Crear Clase'),
            ),
          ],
        ),
      ),
    );

    if (confirmar != true || !mounted) return;
    if (nombreCtrl.text.trim().isEmpty) return;

    final prefijo = prefijoCtrl.text.trim().toUpperCase();
    final clase = await widget.repositorioClases.crearClase(
      nombre: nombreCtrl.text.trim(),
      gradoGrupo: gradoCtrl.text.trim(),
      descripcion: descCtrl.text.trim(),
      profesorUid: widget.usuario.uid,
      profesorNombre: widget.usuario.nombre.isNotEmpty ? widget.usuario.nombre : 'Profesor',
      institucionId: instSeleccionada,
      prefijoCodigo: prefijo.isEmpty ? null : prefijo,
    );

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('¡Clase Creada!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(clase.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            const Text('Comparte este código con tus alumnos:', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: clase.codigoAcceso));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Código copiado'), duration: Duration(seconds: 1)),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      clase.codigoAcceso,
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.green.shade900, letterSpacing: 3),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.copy, color: Colors.green, size: 22),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text('Toca el código para copiarlo', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
            child: const Text('Entendido'),
          ),
        ],
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

  void _mostrarSelectorInstitucionDocente() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final todas = widget.usuario.todasLasInstituciones;
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance, color: Colors.indigo, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Instituciones del Docente',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Selecciona tu institución activa para crear clases y sesiones contextuales.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const Divider(height: 24),
              ...todas.map((inst) {
                final esActiva = inst == widget.usuario.institucionId;
                final nombreInst = inst == 'INST-SAN-MARTIN'
                    ? 'Colegio San Martín'
                    : (inst == 'INST-BELGRANO' ? 'Instituto Belgrano' : inst);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: esActiva ? Colors.indigo : Colors.grey.shade200,
                    foregroundColor: esActiva ? Colors.white : Colors.black87,
                    child: const Icon(Icons.school, size: 18),
                  ),
                  title: Text(nombreInst, style: TextStyle(fontWeight: esActiva ? FontWeight.bold : FontWeight.normal)),
                  subtitle: Text(inst),
                  trailing: esActiva
                      ? const Chip(
                          label: Text('Activa', style: TextStyle(color: Colors.white, fontSize: 11)),
                          backgroundColor: Colors.indigo,
                        )
                      : null,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await widget.servicioAuth.cambiarInstitucionActiva(inst);
                    if (mounted) setState(() {});
                  },
                );
              }),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final ctrl = TextEditingController();
                  final nuevaInst = await showDialog<String>(
                    context: context,
                    builder: (d) => AlertDialog(
                      title: const Text('Asociar Nueva Institución'),
                      content: TextField(
                        controller: ctrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Código de Institución',
                          hintText: 'Ej: INST-SARMIENTO',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancelar')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(d, ctrl.text.trim()),
                          child: const Text('Agregar'),
                        ),
                      ],
                    ),
                  );
                  if (nuevaInst != null && nuevaInst.isNotEmpty) {
                    await widget.servicioAuth.agregarInstitucion(nuevaInst);
                    if (mounted) setState(() {});
                  }
                },
                icon: const Icon(Icons.add_business),
                label: const Text('Asociar otra institución educativa'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _abrirGestionModoClase() async {
    await showDialog(
      context: context,
      builder: (_) => DialogoGestionModoClase(
        docente: widget.usuario,
        repositorioClases: widget.repositorioClases,
        repositorioSesiones: widget.repositorioSesiones,
        repositorioPoliticas: widget.repositorioPoliticas,
        servicioHorarios: widget.servicioHorarios,
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.assignment_ind_outlined),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Docente: ${widget.usuario.nombre.isNotEmpty ? widget.usuario.nombre : "Profesor"}',
                    style: const TextStyle(fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  InkWell(
                    onTap: _mostrarSelectorInstitucionDocente,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.account_balance, size: 12, color: Colors.lightGreenAccent),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            widget.usuario.institucionId == 'INST-SAN-MARTIN'
                                ? 'Colegio San Martín'
                                : (widget.usuario.institucionId == 'INST-BELGRANO'
                                    ? 'Instituto Belgrano'
                                    : widget.usuario.institucionId),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.lightGreenAccent,
                              decoration: TextDecoration.underline,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 14, color: Colors.lightGreenAccent),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cast_for_education, color: Colors.lightGreenAccent),
            tooltip: 'Iniciar / Gestionar Modo Clase & Examen',
            onPressed: _abrirGestionModoClase,
          ),
          IconButton(
            icon: const Icon(Icons.class_outlined, color: Colors.greenAccent),
            tooltip: 'Gestionar Clases & Classroom',
            onPressed: _mostrarGestorClassroom,
          ),
          IconButton(
            icon: const Icon(Icons.assignment_turned_in_outlined, color: Colors.orangeAccent),
            tooltip: 'Evaluaciones, Notas & Triage de Brechas',
            onPressed: _abrirSelectorEvaluacionesDocente,
          ),
          IconButton(
            icon: const Icon(Icons.auto_stories_outlined, color: Colors.purpleAccent),
            tooltip: 'Reportes Pedagógicos por Período',
            onPressed: _abrirSelectorReportesDocente,
          ),
          IconButton(
            icon: const Icon(Icons.account_tree_outlined, color: Colors.tealAccent),
            tooltip: 'Planificación & Mapa Curricular',
            onPressed: _abrirSelectorMapaCurricularDocente,
          ),
          IconButton(
            icon: const Icon(Icons.fact_check_outlined, color: Colors.amberAccent),
            tooltip: 'Exámenes Diagnósticos & Avance',
            onPressed: _mostrarGestorExamenes,
          ),
          IconButton(
            icon: const Icon(Icons.insights, color: Colors.cyanAccent),
            tooltip: 'Monitor de Diagnóstico y Errores',
            onPressed: _mostrarDiagnosticoDocente,
          ),
          IconButton(
            icon: const Icon(Icons.play_circle_fill, color: Colors.amber),
            tooltip: 'Vista de prueba de ejercicios',
            onPressed: _probarModoAlumno,
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Atajo de Demostración: Alternar a modo Alumno (para presentar sin reloguear)',
            onPressed: () => widget.servicioAuth.alternarRol(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => widget.servicioAuth.cerrarSesion(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirCrearEjercicio,
        icon: const Icon(Icons.add),
        label: const Text('Crear Ejercicio'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BANNER PROMINENTE: [ INICIAR MODO CLASE ]
                  FutureBuilder<SesionModoClase?>(
                    future: widget.repositorioSesiones.obtenerSesionActivaPorProfesor(widget.usuario.uid),
                    builder: (context, snapshot) {
                      final sesion = snapshot.data;
                      final estaActiva = sesion != null;
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 16),
                        color: estaActiva ? Colors.green.shade50 : Colors.indigo.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: estaActiva ? Colors.green.shade600 : Colors.indigo.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: estaActiva ? Colors.green.shade600 : Colors.indigo.shade700,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  estaActiva ? Icons.cast_connected : Icons.cast_for_education,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      estaActiva
                                          ? 'MODO CLASE EN VIVO — ${sesion.cursoNombre}'
                                          : 'CONTROL CONTEXTUAL DE AULA',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: estaActiva ? Colors.green.shade900 : Colors.indigo.shade900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      estaActiva
                                          ? '${sesion.totalPresentes} dispositivos presentes en regla. Pulsa para QR o excepciones.'
                                          : 'Activa la supervisión de dispositivos para los alumnos presentes en el salón.',
                                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: _abrirGestionModoClase,
                                icon: Icon(estaActiva ? Icons.dashboard : Icons.play_arrow),
                                label: Text(
                                  estaActiva ? 'GESTIONAR' : 'INICIAR MODO CLASE',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: estaActiva ? Colors.green.shade700 : Colors.indigo.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  // Tarjeta de Resumen Docente
                  Card(
                    color: Colors.indigo.shade50,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.auto_stories, color: Colors.indigo, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Catálogo Curricular de Ejercicios',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_ejercicios.length} ejercicios disponibles para los alumnos',
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Acciones rápidas del docente
                  const Text('Generador Rápido de Contenido:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.add, color: Colors.blue),
                          label: const Text('+3 Sumas Verticales'),
                          onPressed: () => _generarLotePreguntas(OperacionAritmetica.suma, 3),
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          avatar: const Icon(Icons.remove, color: Colors.orange),
                          label: const Text('+3 Restas en Columna'),
                          onPressed: () => _generarLotePreguntas(OperacionAritmetica.resta, 3),
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          avatar: const Icon(Icons.close, color: Colors.green),
                          label: const Text('+3 Multiplicaciones'),
                          onPressed: () => _generarLotePreguntas(OperacionAritmetica.multiplicacion, 3),
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          avatar: const Icon(Icons.safety_divider, color: Colors.purple),
                          label: const Text('+3 Divisiones Galera'),
                          onPressed: () => _generarLotePreguntas(OperacionAritmetica.division, 3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Lista de Ejercicios
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Lista de Ejercicios Configurados:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      TextButton.icon(
                        onPressed: _abrirCrearEjercicio,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Nuevo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_ejercicios.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('No hay ejercicios creados en el catálogo'),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _abrirCrearEjercicio,
                              icon: const Icon(Icons.add),
                              label: const Text('Crear Primer Ejercicio'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._ejercicios.map((ej) => _construirTarjetaEjercicio(ej)),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _construirTarjetaEjercicio(Ejercicio ej) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.indigo.shade100,
                foregroundColor: Colors.indigo,
                child: Text(ej.codigoTema, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              title: Text(
                ej.enunciado,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Wrap(
                  spacing: 6,
                  children: [
                    Text('Tipo: ${ej.tipo.name}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('• Nivel ${ej.nivel}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('• ${ej.puntos} pts', style: const TextStyle(fontSize: 12, color: Colors.amber)),
                  ],
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Eliminar del catálogo',
                onPressed: () => _eliminarEjercicio(ej),
              ),
            ),
            if (ej.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: ej.tags
                      .map((t) => Chip(
                            avatar: const Icon(Icons.local_offer_outlined, size: 12, color: Colors.indigo),
                            label: Text(t, style: const TextStyle(fontSize: 11, color: Colors.indigo)),
                            backgroundColor: Colors.indigo.shade50,
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
