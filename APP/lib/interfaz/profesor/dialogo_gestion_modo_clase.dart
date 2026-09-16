import 'dart:async';
import 'package:flutter/material.dart';
import '../../datos/repositorio_clases.dart';
import '../../datos/repositorio_politicas.dart';
import '../../datos/repositorio_sesiones_clase.dart';
import '../../datos/servicio_horarios.dart';
import '../../dominio/modelos/clase_escolar.dart';
import '../../dominio/modelos/permiso_institucional.dart';
import '../../dominio/modelos/sesion_modo_clase.dart';
import '../../dominio/modelos/usuario_app.dart';
import '../comun/widget_codigo_barras.dart';

/// Modal interactivo para que el Docente inicie, supervise y finalice el Modo Clase / Modo Examen.
class DialogoGestionModoClase extends StatefulWidget {
  const DialogoGestionModoClase({
    super.key,
    required this.docente,
    required this.repositorioClases,
    required this.repositorioSesiones,
    required this.repositorioPoliticas,
    required this.servicioHorarios,
  });

  final UsuarioApp docente;
  final RepositorioClases repositorioClases;
  final RepositorioSesionesClase repositorioSesiones;
  final RepositorioPoliticas repositorioPoliticas;
  final ServicioHorarios servicioHorarios;

  @override
  State<DialogoGestionModoClase> createState() => _DialogoGestionModoClaseState();
}

class _DialogoGestionModoClaseState extends State<DialogoGestionModoClase> {
  List<ClaseEscolar> _clases = [];
  ClaseEscolar? _claseSeleccionada;
  SesionModoClase? _sesionActiva;
  bool _cargando = true;

  TipoModoClase _tipoSeleccionado = TipoModoClase.clase;
  bool _confirmacionExamen = false;
  Timer? _tickerTimer;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _tickerTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && _sesionActiva != null) {
        _actualizarSesion();
      }
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    final listaClases =
        await widget.repositorioClases.obtenerClasesPorProfesor(widget.docente.uid);
    final sesion =
        await widget.repositorioSesiones.obtenerSesionActivaPorProfesor(widget.docente.uid);

    if (mounted) {
      setState(() {
        _clases = listaClases;
        if (_clases.isNotEmpty) {
          _claseSeleccionada = _clases.first;
        }
        _sesionActiva = sesion;
        _cargando = false;
      });
    }
  }

  Future<void> _actualizarSesion() async {
    if (_sesionActiva == null) return;
    final sesion = await widget.repositorioSesiones
        .obtenerSesionActivaPorClase(_sesionActiva!.claseId);
    if (mounted) {
      setState(() => _sesionActiva = sesion);
    }
  }

  Future<void> _iniciarModo() async {
    if (_claseSeleccionada == null) return;

    if (_tipoSeleccionado == TipoModoClase.examen) {
      if (!widget.docente.tienePermiso(PermisoInstitucional.activarModoExamen)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No tienes permiso de Dirección para activar Modo Examen.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (!_confirmacionExamen) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes marcar la casilla de confirmación para el Modo Examen.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    try {
      final nuevaSesion = await widget.repositorioSesiones.iniciarSesion(
        claseId: _claseSeleccionada!.id,
        cursoNombre: _claseSeleccionada!.nombre,
        materia: 'Matemáticas',
        docente: widget.docente,
        tipoModo: _tipoSeleccionado,
      );

      setState(() => _sesionActiva = nuevaSesion);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _finalizarModo() async {
    if (_sesionActiva == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalizar Modo Clase'),
        content: const Text(
          '¿Deseas finalizar la sesión? Se registrará la hora de fin y se liberarán los dispositivos presentes.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('FINALIZAR SESIÓN'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await widget.repositorioSesiones.finalizarSesion(
        sesionId: _sesionActiva!.id,
        docente: widget.docente,
      );
      if (mounted) {
        setState(() => _sesionActiva = null);
        Navigator.pop(context);
      }
    }
  }

  Future<void> _concederExcepcionDialog() async {
    if (_sesionActiva == null) return;
    if (!widget.docente.tienePermiso(PermisoInstitucional.permitirAppTemporalmente)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dirección no te ha otorgado permiso para excepciones temporales.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String appElegida = 'app_youtube';
    String appNombre = 'YouTube Educativo';
    int minutos = 10;
    final motivoCtrl = TextEditingController(text: 'Visualización de video explicativo');

    final conceder = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text('Permitir App Temporalmente'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Selecciona la herramienta a habilitar:', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: appElegida,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'app_youtube', child: Text('YouTube Educativo')),
                  DropdownMenuItem(value: 'app_geogebra', child: Text('GeoGebra Calculadora Gráfica')),
                  DropdownMenuItem(value: 'app_camara', child: Text('Cámara de Fotos')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDState(() {
                      appElegida = val;
                      appNombre = val == 'app_youtube'
                          ? 'YouTube Educativo'
                          : (val == 'app_geogebra' ? 'GeoGebra' : 'Cámara');
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              const Text('Duración de la excepción:', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [5, 10, 20].map((m) {
                  return ChoiceChip(
                    label: Text('$m min'),
                    selected: minutos == m,
                    onSelected: (val) => setDState(() => minutos = m),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: motivoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Motivo pedagógico',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('AUTORIZAR'),
            ),
          ],
        ),
      ),
    );

    if (conceder == true) {
      await widget.repositorioSesiones.concederExcepcionTemporal(
        sesionId: _sesionActiva!.id,
        docente: widget.docente,
        appId: appElegida,
        appNombre: appNombre,
        minutos: minutos,
        motivo: motivoCtrl.text.trim(),
      );
      await _actualizarSesion();
    }
  }

  Future<void> _marcarPresenteManual(String alumnoUid, String alumnoNombre) async {
    if (_sesionActiva == null) return;
    await widget.repositorioSesiones.registrarPresenciaAlumno(
      sesionId: _sesionActiva!.id,
      alumnoUid: alumnoUid,
      alumnoNombre: alumnoNombre,
      metodo: MetodoPresencia.manualDocente,
    );
    await _actualizarSesion();
  }

  Future<void> _liberarEstudiante(String alumnoUid) async {
    if (_sesionActiva == null) return;
    await widget.repositorioSesiones.liberarEstudiante(
      sesionId: _sesionActiva!.id,
      docente: widget.docente,
      alumnoUid: alumnoUid,
      motivo: 'Permiso otorgado por docente en aula',
    );
    await _actualizarSesion();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 580,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        padding: const EdgeInsets.all(20),
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _sesionActiva != null
                ? _construirPanelSesionActiva()
                : _construirFormularioLanzamiento(),
      ),
    );
  }

  // ===========================================================================
  // VISTA 1: FORMULARIO DE INICIO DE MODO CLASE / EXAMEN
  // ===========================================================================
  Widget _construirFormularioLanzamiento() {
    final tieneExamen = widget.docente.tienePermiso(PermisoInstitucional.activarModoExamen);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle),
                child: const Icon(Icons.cast_for_education, color: Colors.green, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Iniciar Modo Clase / Examen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Supervisión contextual de aula para alumnos presentes', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(height: 24),

          const Text('1. Seleccionar Clase o Curso:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          if (_clases.isEmpty)
            const Text('No tienes clases asignadas. Crea una clase primero.', style: TextStyle(color: Colors.red))
          else
            DropdownButtonFormField<ClaseEscolar>(
              value: _claseSeleccionada,
              decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              items: _clases.map((c) => DropdownMenuItem(value: c, child: Text('${c.nombre} (${c.gradoGrupo})'))).toList(),
              onChanged: (val) => setState(() => _claseSeleccionada = val),
            ),

          const SizedBox(height: 16),
          const Text('2. Tipo de Modalidad:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school, size: 16),
                      SizedBox(width: 6),
                      Text('Modo Clase'),
                    ],
                  ),
                  selected: _tipoSeleccionado == TipoModoClase.clase,
                  onSelected: (val) => setState(() => _tipoSeleccionado = TipoModoClase.clase),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_late, size: 16),
                      SizedBox(width: 6),
                      Text('Modo Examen'),
                    ],
                  ),
                  selected: _tipoSeleccionado == TipoModoClase.examen,
                  onSelected: (val) => setState(() => _tipoSeleccionado = TipoModoClase.examen),
                ),
              ),
            ],
          ),

          if (_tipoSeleccionado == TipoModoClase.examen) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tieneExamen ? Colors.amber.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tieneExamen ? Colors.amber.shade300 : Colors.red.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(tieneExamen ? Icons.verified : Icons.lock, color: tieneExamen ? Colors.amber.shade800 : Colors.red, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        tieneExamen ? 'Autorización Confirmada por Dirección' : 'Sin Autorización para Examen',
                        style: TextStyle(fontWeight: FontWeight.bold, color: tieneExamen ? Colors.amber.shade900 : Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tieneExamen
                        ? 'En Modo Examen, todas las utilidades y apps secundarias se bloquean estrictamente, focalizando al estudiante únicamente en la prueba.'
                        : 'No tienes el permiso institucional "activar_modo_examen". Solicítalo a Dirección.',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (tieneExamen) ...[
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Confirmo que deseo aplicar las restricciones de examen ahora.', style: TextStyle(fontSize: 12)),
                      value: _confirmacionExamen,
                      onChanged: (v) => setState(() => _confirmacionExamen = v ?? false),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          // Resumen de la Regla Fundamental
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blueGrey, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'REGLA DE AULA: Solo los alumnos presentes en el colegio recibirán la política. Si un alumno está enfermo en su casa, su dispositivo no se bloqueará.',
                    style: TextStyle(fontSize: 11, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _iniciarModo,
            icon: const Icon(Icons.play_arrow),
            label: Text(
              _tipoSeleccionado == TipoModoClase.examen ? 'ACTIVAR MODO EXAMEN' : 'INICIAR MODO CLASE',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _tipoSeleccionado == TipoModoClase.examen ? Colors.red.shade800 : Colors.green.shade700,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // VISTA 2: PANEL DE SESIÓN ACTIVA EN VIVO (QR, PRESENTES, EXCEPCIONES)
  // ===========================================================================
  Widget _construirPanelSesionActiva() {
    final sesion = _sesionActiva!;
    final presentesCount = sesion.totalPresentes;

    // Lista de alumnos de la clase actual
    final claseActual = _clases.firstWhere(
      (c) => c.id == sesion.claseId,
      orElse: () => ClaseEscolar(
        id: sesion.claseId,
        codigoAcceso: 'CLASE',
        nombre: sesion.cursoNombre,
        gradoGrupo: '3B',
        descripcion: '',
        profesorUid: widget.docente.uid,
        profesorNombre: widget.docente.nombre,
        fechaCreacion: DateTime.now(),
        alumnosUids: const ['alumno-demo-1', 'alumno-demo-2', 'alumno-demo-3', 'alumno-demo-4'],
        nombresAlumnos: const {
          'alumno-demo-1': 'Sofía Valenzuela',
          'alumno-demo-2': 'Mateo Rivas',
          'alumno-demo-3': 'Camila Soto',
          'alumno-demo-4': 'Joaquín Herrera',
        },
      ),
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Encabezado en vivo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${sesion.tipoModo.etiqueta} EN VIVO',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                  ),
                ],
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          Text('${sesion.cursoNombre} — ${sesion.materia}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const Divider(height: 16),

          // Tarjeta del Código de Barras Dinámico
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.indigo.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WidgetCodigoBarras(
                      codigo: sesion.tokenPresenciaCodigoBarras,
                      ancho: 170,
                      alto: 54,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.barcode_reader, size: 16, color: Colors.indigo),
                              SizedBox(width: 4),
                              Text(
                                'Código de Barras de Presencia',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Los alumnos escanean este código con su dispositivo para validar presencia en el aula.',
                            style: TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton.icon(
                                onPressed: () async {
                                  await widget.repositorioSesiones.rotarTokenPresencia(sesion.id);
                                  await _actualizarSesion();
                                },
                                icon: const Icon(Icons.refresh, size: 14),
                                label: const Text('Actualizar (90s)', style: TextStyle(fontSize: 11)),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          // Botones de acción rápida: Permitir app y Finalizar
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _concederExcepcionDialog,
                  icon: const Icon(Icons.alarm_add, size: 18),
                  label: const Text('Permitir App (5-20m)', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _finalizarModo,
                icon: const Icon(Icons.stop, size: 18),
                label: const Text('Finalizar Clase', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Alumnos de la Clase ($presentesCount/${claseActual.alumnosUids.length} presentes):',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Chip(
                label: Text('${sesion.totalCumpliendo} en regla'),
                backgroundColor: Colors.green.shade50,
                labelStyle: TextStyle(fontSize: 10, color: Colors.green.shade800, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Lista de alumnos con su estado de presencia
          ...claseActual.alumnosUids.map((alumnoUid) {
            final nombre = claseActual.nombresAlumnos[alumnoUid] ?? 'Alumno';
            final registro = sesion.estudiantesPresentes[alumnoUid];
            final estaPresente = registro?.estaPresente ?? false;
            final estaLiberado = registro?.liberadoPorDocente ?? false;

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: estaPresente
                    ? (estaLiberado ? Colors.blue.shade50 : Colors.green.shade50)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: estaPresente
                      ? (estaLiberado ? Colors.blue.shade200 : Colors.green.shade300)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    estaPresente
                        ? (estaLiberado ? Icons.lock_open : Icons.check_circle)
                        : Icons.home_outlined,
                    color: estaPresente
                        ? (estaLiberado ? Colors.blue : Colors.green)
                        : Colors.grey.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(
                          estaPresente
                              ? (estaLiberado ? 'Liberado individualmente' : 'Presente en aula — Política aplicada')
                              : 'Fuera de aula / En casa (Dispositivo libre - No bloqueado)',
                          style: TextStyle(
                            fontSize: 10,
                            color: estaPresente ? Colors.black87 : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!estaPresente)
                    TextButton(
                      onPressed: () => _marcarPresenteManual(alumnoUid, nombre),
                      child: const Text('Presente', style: TextStyle(fontSize: 11)),
                    )
                  else if (!estaLiberado)
                    TextButton(
                      onPressed: () => _liberarEstudiante(alumnoUid),
                      child: const Text('Liberar', style: TextStyle(fontSize: 11, color: Colors.orange)),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
