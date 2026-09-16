import 'package:flutter/material.dart';
import '../../datos/repositorio_auditoria.dart';
import '../../datos/repositorio_clases.dart';
import '../../datos/repositorio_politicas.dart';
import '../../datos/repositorio_sesiones_clase.dart';
import '../../datos/servicio_auth.dart';
import '../../datos/servicio_horarios.dart';
import '../../dominio/modelos/clase_escolar.dart';
import '../../dominio/modelos/horario_escolar.dart';
import '../../dominio/modelos/permiso_institucional.dart';
import '../../dominio/modelos/politica_dispositivo.dart';
import '../../dominio/modelos/registro_auditoria.dart';
import '../../dominio/modelos/sesion_modo_clase.dart';
import '../../dominio/modelos/usuario_app.dart';

/// Panel de Dirección y Administración Institucional.
/// Provee control centralizado de políticas de aula, monitoreo de cumplimiento en vivo,
/// gestión de permisos docentes, supervisión de horarios y botón de emergencia.
class PantallaDireccion extends StatefulWidget {
  const PantallaDireccion({
    super.key,
    required this.usuario,
    required this.servicioAuth,
    required this.repositorioPoliticas,
    required this.repositorioSesiones,
    required this.repositorioAuditoria,
    required this.repositorioClases,
    required this.servicioHorarios,
  });

  final UsuarioApp usuario;
  final ServicioAuth servicioAuth;
  final RepositorioPoliticas repositorioPoliticas;
  final RepositorioSesionesClase repositorioSesiones;
  final RepositorioAuditoria repositorioAuditoria;
  final RepositorioClases repositorioClases;
  final ServicioHorarios servicioHorarios;

  @override
  State<PantallaDireccion> createState() => _PantallaDireccionState();
}

class _PantallaDireccionState extends State<PantallaDireccion>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Estados de datos
  List<SesionModoClase> _sesionesActivas = [];
  List<PoliticaDispositivo> _politicas = [];
  List<RegistroAuditoria> _eventosAuditoria = [];
  List<ClaseEscolar> _clases = [];
  List<BloqueHorario> _horarios = [];
  bool _cargando = true;

  // Docentes demo gestionados en la institución
  late List<UsuarioApp> _docentesInstitucion;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    _docentesInstitucion = [
      const UsuarioApp(
        uid: 'profesor-demo',
        nombre: 'Docente Demo',
        email: 'docente@sanmartin.edu',
        rol: RolUsuario.profesor,
        institucionId: 'INST-SAN-MARTIN',
        permisosEspecificos: [
          PermisoInstitucional.activarModoClase,
          PermisoInstitucional.liberarEstudiante,
        ],
      ),
      const UsuarioApp(
        uid: 'prof-roberto',
        nombre: 'Prof. Roberto Gómez',
        email: 'rgomez@sanmartin.edu',
        rol: RolUsuario.profesor,
        institucionId: 'INST-SAN-MARTIN',
        permisosEspecificos: [
          PermisoInstitucional.activarModoClase,
          PermisoInstitucional.activarModoExamen,
          PermisoInstitucional.permitirAppTemporalmente,
        ],
      ),
    ];

    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    final instId = widget.usuario.institucionId;

    final sesiones =
        await widget.repositorioSesiones.obtenerSesionesActivasPorInstitucion(instId);
    final politicas =
        await widget.repositorioPoliticas.obtenerPoliticasPorInstitucion(instId);
    final auditoria =
        await widget.repositorioAuditoria.obtenerEventosPorInstitucion(instId);
    final horarios = widget.servicioHorarios.obtenerHorariosPorInstitucion(instId);
    final clases =
        await widget.repositorioClases.obtenerClasesPorProfesor('profesor-demo');

    if (mounted) {
      setState(() {
        _sesionesActivas = sesiones;
        _politicas = politicas;
        _eventosAuditoria = auditoria;
        _horarios = horarios;
        _clases = clases;
        _cargando = false;
      });
    }
  }

  // ===========================================================================
  // FASE 13: BOTÓN DE EMERGENCIA INSTITUCIONAL
  // ===========================================================================
  Future<void> _dialogoEmergenciaInstitucional() async {
    final hayEmergenciaActiva = _sesionesActivas.any(
      (s) => s.restriccionesSuspendidasEmergencia,
    );

    if (hayEmergenciaActiva) {
      // Restaurar
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.restart_alt, color: Colors.green, size: 40),
          title: const Text('Restaurar Restricciones Normales'),
          content: const Text(
            '¿Deseas reactivar las políticas y el control de dispositivos en todas las clases activas?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('RESTAURAR REGLAS'),
            ),
          ],
        ),
      );

      if (confirmar == true) {
        await widget.repositorioSesiones.restaurarRestriccionesNormales(
          institucionId: widget.usuario.institucionId,
          direccion: widget.usuario,
        );
        await _cargarDatos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Restricciones normales restauradas correctamente.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } else {
      // Suspender por emergencia
      final motivoCtrl = TextEditingController(text: 'Simulacro / Contingencia edilicia');
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 44),
          title: const Text('EMERGENCIA INSTITUCIONAL'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Esta acción suspenderá INMEDIATAMENTE todos los bloqueos en todos los dispositivos de la institución sin finalizar las sesiones.',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: motivoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Motivo de la Emergencia',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                foregroundColor: Colors.white,
              ),
              child: const Text('ACTIVAR EMERGENCIA'),
            ),
          ],
        ),
      );

      if (confirmar == true) {
        await widget.repositorioSesiones.suspenderRestriccionesEmergencia(
          institucionId: widget.usuario.institucionId,
          direccion: widget.usuario,
          motivo: motivoCtrl.text.trim(),
        );
        await _cargarDatos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('RESTRICCIONES SUSPENDIDAS POR EMERGENCIA.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hayEmergenciaActiva = _sesionesActivas.any(
      (s) => s.restriccionesSuspendidasEmergencia,
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.amber.shade700,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Colegio San Martín de Tours',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Panel de Dirección — ${widget.usuario.nombre}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade300),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Botón de Emergencia Institucional
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton.icon(
              onPressed: _dialogoEmergenciaInstitucional,
              icon: Icon(
                hayEmergenciaActiva ? Icons.restart_alt : Icons.emergency,
                size: 18,
                color: Colors.white,
              ),
              label: Text(
                hayEmergenciaActiva ? 'RESTAURAR REGLAS' : 'EMERGENCIA',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    hayEmergenciaActiva ? Colors.green.shade700 : Colors.red.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar datos',
            onPressed: _cargarDatos,
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Alternar Rol (Demo Rápida: Alumno / Profesor / Dirección)',
            onPressed: () => widget.servicioAuth.alternarRol(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () => widget.servicioAuth.cerrarSesion(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.amberAccent,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amberAccent,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Resumen'),
            Tab(icon: Icon(Icons.security_outlined), text: 'Políticas Apps'),
            Tab(icon: Icon(Icons.school_outlined), text: 'Institución'),
            Tab(icon: Icon(Icons.history_edu_outlined), text: 'Auditoría'),
          ],
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _construirTabResumen(),
                _construirTabPoliticas(),
                _construirTabInstitucion(),
                _construirTabAuditoria(),
              ],
            ),
    );
  }

  // ===========================================================================
  // TAB 1 — RESUMEN EJECUTIVO Y MONITOREO EN VIVO
  // ===========================================================================
  Widget _construirTabResumen() {
    int totalAlumnos = 0;
    for (final c in _clases) {
      totalAlumnos += c.totalAlumnos;
    }
    if (totalAlumnos == 0) totalAlumnos = 4; // Muestra base

    int dispositivosPresentes = 0;
    int dispositivosCumpliendo = 0;
    for (final s in _sesionesActivas) {
      dispositivosPresentes += s.totalPresentes;
      dispositivosCumpliendo += s.totalCumpliendo;
    }

    final double tasaCumplimiento = dispositivosPresentes > 0
        ? (dispositivosCumpliendo / dispositivosPresentes * 100)
        : 100.0;

    final hayEmergencia = _sesionesActivas.any((s) => s.restriccionesSuspendidasEmergencia);

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (hayEmergencia)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade700, width: 2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MODO DE EMERGENCIA INSTITUCIONAL ACTIVO',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        Text(
                          'Todas las políticas de bloqueo están suspendidas provisionalmente en el colegio.',
                          style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Tarjetas KPI
          Row(
            children: [
              Expanded(
                child: _tarjetaKpi(
                  'Estudiantes',
                  '$totalAlumnos',
                  Icons.people_alt_outlined,
                  Colors.blue.shade700,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _tarjetaKpi(
                  'Profesores',
                  '${_docentesInstitucion.length}',
                  Icons.assignment_ind_outlined,
                  Colors.indigo.shade700,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _tarjetaKpi(
                  'Cursos',
                  '${_clases.isNotEmpty ? _clases.length : 2}',
                  Icons.class_outlined,
                  Colors.teal.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _tarjetaKpi(
                  'Modos Activos',
                  '${_sesionesActivas.length}',
                  Icons.play_circle_filled,
                  Colors.green.shade700,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _tarjetaKpi(
                  'Presentes Aula',
                  '$dispositivosPresentes',
                  Icons.phone_android,
                  Colors.orange.shade800,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _tarjetaKpi(
                  'Cumplimiento',
                  '${tasaCumplimiento.toStringAsFixed(0)}%',
                  Icons.verified_user_outlined,
                  Colors.purple.shade700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monitoreo de Clases Activas en Vivo',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              Chip(
                label: Text('${_sesionesActivas.length} clases'),
                backgroundColor: Colors.green.shade50,
                labelStyle: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (_sesionesActivas.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Column(
                children: [
                  Icon(Icons.meeting_room_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('No hay sesiones de Modo Clase en este instante.',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  SizedBox(height: 4),
                  Text(
                    'Los profesores pueden iniciar el Modo Clase desde su panel cuando comience su bloque.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ..._sesionesActivas.map((s) => _tarjetaSesionEnVivo(s)),
        ],
      ),
    );
  }

  Widget _tarjetaKpi(String titulo, String valor, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            titulo,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaSesionEnVivo(SesionModoClase sesion) {
    final duracion = DateTime.now().difference(sesion.horaInicio).inMinutes;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: sesion.tipoModo == TipoModoClase.examen
                            ? Colors.red.shade100
                            : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        sesion.tipoModo.etiqueta,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: sesion.tipoModo == TipoModoClase.examen
                              ? Colors.red.shade800
                              : Colors.green.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Hace $duracion min',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${sesion.cursoNombre} — ${sesion.materia}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Docente: ${sesion.profesorNombre}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _columnaDatoSesion('Dispositivos Presentes', '${sesion.totalPresentes}', Colors.indigo),
                _columnaDatoSesion('En Regla', '${sesion.totalCumpliendo}', Colors.green.shade700),
                _columnaDatoSesion('Excepciones', '${sesion.totalExcepciones}', Colors.orange.shade800),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 16, color: Colors.blueGrey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Política: ${sesion.politicaAplicada.nombre}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _columnaDatoSesion(String etiqueta, String valor, Color color) {
    return Column(
      children: [
        Text(valor, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(etiqueta, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }

  // ===========================================================================
  // TAB 2 — POLÍTICAS DE DISPOSITIVOS (CONTROL DE APPS)
  // ===========================================================================
  Widget _construirTabPoliticas() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Directivas de Aplicaciones',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: _dialogoCrearPolitica,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nueva Política'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._politicas.map((p) => _tarjetaPolitica(p)),
      ],
    );
  }

  Widget _tarjetaPolitica(PoliticaDispositivo politica) {
    final permitidas = politica.appsPermitidas;
    final bloqueadas = politica.appsBloqueadas;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    politica.nombre,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  label: Text(politica.jerarquia.etiqueta),
                  backgroundColor: Colors.blueGrey.shade50,
                  labelStyle: TextStyle(fontSize: 11, color: Colors.blueGrey.shade800),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(politica.descripcion, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            const Divider(height: 20),
            const Text('Aplicaciones Permitidas:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: permitidas.map((a) => Chip(
                avatar: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                label: Text(a.nombre, style: const TextStyle(fontSize: 11)),
                backgroundColor: Colors.green.shade50,
              )).toList(),
            ),
            const SizedBox(height: 10),
            const Text('Aplicaciones Bloqueadas:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: bloqueadas.map((a) => Chip(
                avatar: Icon(
                  a.esBloqueoCritico ? Icons.block : Icons.lock_outline,
                  size: 16,
                  color: Colors.red,
                ),
                label: Text(
                  a.esBloqueoCritico ? '${a.nombre} (Crítico)' : a.nombre,
                  style: const TextStyle(fontSize: 11),
                ),
                backgroundColor: Colors.red.shade50,
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _dialogoCrearPolitica() async {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String plantillaSeleccionada = 'estandar';

    final creado = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Crear Nueva Política'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la Política',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción / Propósito',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Plantilla base:', style: TextStyle(fontWeight: FontWeight.bold)),
                RadioListTile<String>(
                  title: const Text('Modo Clase Estándar'),
                  subtitle: const Text('Calculadora y Cámara permitidas; Redes bloqueadas.'),
                  value: 'estandar',
                  groupValue: plantillaSeleccionada,
                  onChanged: (v) => setDialogState(() => plantillaSeleccionada = v!),
                ),
                RadioListTile<String>(
                  title: const Text('Modo Examen Riguroso'),
                  subtitle: const Text('Todo bloqueado excepto la evaluación.'),
                  value: 'examen',
                  groupValue: plantillaSeleccionada,
                  onChanged: (v) => setDialogState(() => plantillaSeleccionada = v!),
                ),
                RadioListTile<String>(
                  title: const Text('Modo Investigación'),
                  subtitle: const Text('YouTube y buscador educativo habilitados temporalmente.'),
                  value: 'investigacion',
                  groupValue: plantillaSeleccionada,
                  onChanged: (v) => setDialogState(() => plantillaSeleccionada = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nombreCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: const Text('CREAR POLÍTICA'),
            ),
          ],
        ),
      ),
    );

    if (creado == true) {
      PoliticaDispositivo nueva;
      final instId = widget.usuario.institucionId;
      final id = 'POL-${DateTime.now().millisecondsSinceEpoch}';

      if (plantillaSeleccionada == 'examen') {
        nueva = PlantillaPolitica.modoExamenRiguroso(institucionId: instId, id: id).copyWith(
          nombre: nombreCtrl.text.trim(),
          descripcion: descCtrl.text.trim(),
        );
      } else if (plantillaSeleccionada == 'investigacion') {
        nueva = PlantillaPolitica.modoInvestigacion(institucionId: instId, id: id).copyWith(
          nombre: nombreCtrl.text.trim(),
          descripcion: descCtrl.text.trim(),
        );
      } else {
        nueva = PlantillaPolitica.modoClaseEstandar(institucionId: instId, id: id).copyWith(
          nombre: nombreCtrl.text.trim(),
          descripcion: descCtrl.text.trim(),
        );
      }

      await widget.repositorioPoliticas.guardarPolitica(nueva, usuario: widget.usuario);
      await widget.repositorioAuditoria.registrarEvento(
        tipo: TipoEventoAuditoria.cambioPolitica,
        usuario: widget.usuario,
        descripcion: 'Dirección creó la política "${nueva.nombre}".',
      );
      await _cargarDatos();
    }
  }

  // ===========================================================================
  // TAB 3 — GESTIÓN INSTITUCIONAL (PROFESORES, CURSOS, HORARIOS)
  // ===========================================================================
  Widget _construirTabInstitucion() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Equipo Docente y Autorizaciones',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Configura qué profesores pueden activar Modo Examen o conceder excepciones de aplicaciones.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        ..._docentesInstitucion.map((d) => _tarjetaDocente(d)),

        const SizedBox(height: 24),
        const Text(
          'Horarios y Bloques Curriculares',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ..._horarios.map((h) => _tarjetaHorario(h)),
      ],
    );
  }

  Widget _tarjetaDocente(UsuarioApp docente) {
    final tieneExamen = docente.tienePermiso(PermisoInstitucional.activarModoExamen);
    final tieneExcepciones = docente.tienePermiso(PermisoInstitucional.permitirAppTemporalmente);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.indigo.shade100,
                  child: Text(
                    docente.nombre.isNotEmpty ? docente.nombre[0] : 'P',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(docente.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(docente.email ?? 'docente@colegio.edu', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            const Text('Permisos Especiales Concedidos por Dirección:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Activar Modo Examen'),
                  selected: tieneExamen,
                  onSelected: (val) => _alternarPermisoDocente(docente, PermisoInstitucional.activarModoExamen, val),
                ),
                FilterChip(
                  label: const Text('Permitir Apps Temporales (5-20m)'),
                  selected: tieneExcepciones,
                  onSelected: (val) => _alternarPermisoDocente(docente, PermisoInstitucional.permitirAppTemporalmente, val),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _alternarPermisoDocente(UsuarioApp docente, String permiso, bool conceder) async {
    final nuevosPermisos = List<String>.from(docente.permisosEspecificos);
    if (conceder) {
      if (!nuevosPermisos.contains(permiso)) nuevosPermisos.add(permiso);
    } else {
      nuevosPermisos.remove(permiso);
    }

    final indice = _docentesInstitucion.indexWhere((d) => d.uid == docente.uid);
    if (indice != -1) {
      setState(() {
        _docentesInstitucion[indice] = docente.copyWith(permisosEspecificos: nuevosPermisos);
      });

      await widget.repositorioAuditoria.registrarEvento(
        tipo: TipoEventoAuditoria.cambioPermisos,
        usuario: widget.usuario,
        descripcion: 'Dirección ${conceder ? "concedió" : "revocó"} el permiso "${PermisoInstitucional.etiqueta(permiso)}" a ${docente.nombre}.',
        detalles: {'docenteUid': docente.uid, 'permiso': permiso},
      );
    }
  }

  Widget _tarjetaHorario(BloqueHorario horario) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.schedule, color: Colors.indigo),
        ),
        title: Text('${horario.diaLegible}: ${horario.horarioLegible}'),
        subtitle: Text('${horario.cursoNombre} — ${horario.materia} (${horario.aula})\nDocente: ${horario.profesorNombre}'),
      ),
    );
  }

  // ===========================================================================
  // TAB 4 — AUDITORÍA E INCIDENTES
  // ===========================================================================
  Widget _construirTabAuditoria() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Trazabilidad y Eventos Críticos',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _cargarDatos,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_eventosAuditoria.isEmpty)
          const Center(child: Text('No hay eventos auditados registrados.'))
        else
          ..._eventosAuditoria.map((e) => _itemAuditoria(e)),
      ],
    );
  }

  Widget _itemAuditoria(RegistroAuditoria evento) {
    final horaStr =
        '${evento.fecha.hour.toString().padLeft(2, '0')}:${evento.fecha.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueGrey.shade100,
          child: Text(horaStr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        title: Text(
          evento.tipo.etiqueta,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(evento.descripcion, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              'Por: ${evento.usuarioNombre} (${evento.rolUsuario.etiqueta})',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
