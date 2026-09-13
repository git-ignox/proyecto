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
import 'pantalla_crear_ejercicio.dart';
import 'pantalla_ejercicios.dart';

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
  })  : repositorioDiagnostico = repositorioDiagnostico ?? FuenteDatosDiagnostico(),
        repositorioClases = repositorioClases ?? FuenteDatosClases();

  final UsuarioApp usuario;
  final RepositorioEjercicios repositorio;
  final ServicioEvaluacion servicioEvaluacion;
  final ServicioAuth servicioAuth;
  final RepositorioDiagnostico repositorioDiagnostico;
  final RepositorioClases repositorioClases;

  @override
  State<PantallaProfesor> createState() => _PantallaProfesorState();
}

class _PantallaProfesorState extends State<PantallaProfesor> {
  List<Ejercicio> _ejercicios = [];
  bool _cargando = true;
  final GeneradorAritmetica _generador = GeneradorAritmetica();

  @override
  void initState() {
    super.initState();
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
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
              const SizedBox(height: 18),
              const Text('Tus Clases Escolares:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
                      Text('Aún no has creado ninguna clase.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 4),
                      Text(
                        'Crea tu primera clase y comparte el código único con tus alumnos.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else
                ...clases.map((c) => _construirTarjetaClaseProfesor(c, ctx)),
            ],
          ),
        ),
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
                      Text(clase.gradoGrupo, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
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
              children: [
                Icon(Icons.group_outlined, size: 16, color: Colors.indigo.shade700),
                const SizedBox(width: 6),
                Text(
                  '${clase.totalAlumnos} alumno${clase.totalAlumnos != 1 ? "s" : ""} inscrito${clase.totalAlumnos != 1 ? "s" : ""}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.indigo.shade700),
                ),
              ],
            ),
            if (clase.nombresAlumnos.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: clase.nombresAlumnos.values
                    .map((nombre) => Chip(
                          avatar: const Icon(Icons.person_outline, size: 14),
                          label: Text(nombre, style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: Colors.blue.shade50,
                        ))
                    .toList(),
              ),
            ],
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

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
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
              child: Text(
                'Docente: ${widget.usuario.nombre.isNotEmpty ? widget.usuario.nombre : "Profesor"}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.class_outlined, color: Colors.greenAccent),
            tooltip: 'Gestionar Clases & Classroom',
            onPressed: _mostrarGestorClassroom,
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
            tooltip: 'Cambiar a modo Alumno',
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
