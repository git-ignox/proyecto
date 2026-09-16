import 'dart:async';
import 'package:flutter/material.dart';
import '../../datos/repositorio_auditoria.dart';
import '../../datos/repositorio_sesiones_clase.dart';
import '../../dominio/control_dispositivo/controlador_dispositivo.dart';
import '../../dominio/modelos/registro_auditoria.dart';
import '../../dominio/modelos/sesion_modo_clase.dart';
import '../../dominio/modelos/usuario_app.dart';

/// Widget de supervisión contextual en el dispositivo del estudiante.
/// Aplica la regla fundamental:
/// Si el alumno está en casa (no validado) -> NO se bloquea y se mantiene en Modo Libre.
/// Si está presente en aula -> Se activa la política y se muestran las herramientas autorizadas.
class WidgetSupervisionAula extends StatefulWidget {
  const WidgetSupervisionAula({
    super.key,
    required this.alumno,
    required this.clasesInscritasUids,
    required this.repositorioSesiones,
    required this.repositorioAuditoria,
    this.controladorDispositivo,
  });

  final UsuarioApp alumno;
  final List<String> clasesInscritasUids;
  final RepositorioSesionesClase repositorioSesiones;
  final RepositorioAuditoria repositorioAuditoria;
  final ControladorDispositivo? controladorDispositivo;

  @override
  State<WidgetSupervisionAula> createState() => _WidgetSupervisionAulaState();
}

class _WidgetSupervisionAulaState extends State<WidgetSupervisionAula>
    with WidgetsBindingObserver {
  late final ControladorDispositivo _controlador;
  StreamSubscription? _sesionSubscription;
  SesionModoClase? _sesionActiva;
  Timer? _tickerTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controlador = widget.controladorDispositivo ??
        ControladorDispositivo.crearParaPlataformaActual();

    _escucharSesiones();
    _tickerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tickerTimer?.cancel();
    _sesionSubscription?.cancel();
    super.dispose();
  }

  void _escucharSesiones() {
    _sesionSubscription = widget.repositorioSesiones
        .sesionesActivasStream(widget.alumno.institucionId)
        .listen((sesiones) {
      SesionModoClase? match;
      for (final s in sesiones) {
        if (widget.clasesInscritasUids.contains(s.claseId) ||
            s.estudiantesPresentes.containsKey(widget.alumno.uid)) {
          match = s;
          break;
        }
      }
      if (mounted) {
        setState(() => _sesionActiva = match);
      }
    });
  }

  // ===========================================================================
  // DETECCIÓN DE PÉRDIDA DE FOCO DURANTE CLASE / EXAMEN
  // ===========================================================================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_sesionActiva == null) return;

    final estaValidado =
        _sesionActiva!.estudiantesPresentes[widget.alumno.uid]?.estaPresente ?? false;
    final estaLiberado =
        _sesionActiva!.estudiantesPresentes[widget.alumno.uid]?.liberadoPorDocente ?? false;

    if (estaValidado && !estaLiberado) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
        _controlador.registrarPerdidaFoco(motivo: 'El alumno minimizó o cambió de aplicación');
        widget.repositorioAuditoria.registrarEvento(
          tipo: TipoEventoAuditoria.incidenciaDispositivo,
          usuario: widget.alumno,
          cursoId: _sesionActiva!.claseId,
          descripcion: 'Incidencia: El alumno ${widget.alumno.nombre} cambió de aplicación durante ${_sesionActiva!.tipoModo.etiqueta}.',
          detalles: {
            'sesionId': _sesionActiva!.id,
            'alumnoUid': widget.alumno.uid,
            'hora': DateTime.now().toIso8601String(),
          },
        );
      }
    }
  }

  Future<void> _dialogoValidarQr() async {
    if (_sesionActiva == null) return;

    // Simulación y validación del escaneo de QR
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.qr_code_scanner, size: 48, color: Colors.indigo),
        title: const Text('Validar Presencia en Aula'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Clase: ${_sesionActiva!.cursoNombre}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Apunta con la cámara al código QR proyectado por tu profesor para validar que estás en el salón.',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wifi, size: 18, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Red Wi-Fi Institucional detectada: Colegio-SanMartin-WiFi',
                      style: TextStyle(fontSize: 11, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.camera_alt),
            label: const Text('CONFIRMAR ESCANEO'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await widget.repositorioSesiones.registrarPresenciaAlumno(
          sesionId: _sesionActiva!.id,
          alumnoUid: widget.alumno.uid,
          alumnoNombre: widget.alumno.nombre,
          metodo: MetodoPresencia.codigoQr,
          tokenQrString: _sesionActiva!.tokenPresenciaQr,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Presencia confirmada! Modo Clase activo en tu dispositivo.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al validar QR: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sesionActiva == null) {
      return const SizedBox.shrink(); // Sin clases activas
    }

    final registro = _sesionActiva!.estudiantesPresentes[widget.alumno.uid];
    final estaPresente = registro?.estaPresente ?? false;
    final estaLiberado = registro?.liberadoPorDocente ?? false;
    final esExamen = _sesionActiva!.tipoModo == TipoModoClase.examen;
    final suspendidaEmergencia = _sesionActiva!.restriccionesSuspendidasEmergencia;

    // Caso 1: Restricciones suspendidas por emergencia institucional
    if (suspendidaEmergencia) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Emergencia Institucional: Restricciones temporalmente suspendidas por Dirección.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }

    // Caso 2: Alumno NO validado como presente (en su casa / fuera de aula)
    // REGLA FUNDAMENTAL DE PRESENCIA: NO SE BLOQUEA EN CASA
    if (!estaPresente) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blueGrey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.home_outlined, color: Colors.blueGrey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Clase iniciada: ${_sesionActiva!.cursoNombre} (${_sesionActiva!.materia})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Dispositivo Libre', style: TextStyle(fontSize: 11, color: Colors.black87)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'No estás registrado como presente en el salón. Tu dispositivo personal no tiene restricciones aplicadas.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _dialogoValidarQr,
              child: const Row(
                children: [
                  Icon(Icons.qr_code_scanner, size: 16, color: Colors.indigo),
                  SizedBox(width: 4),
                  Text(
                    '¿Estás en el aula? Pulsa aquí para escanear el QR del profesor',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Caso 3: Alumno liberado individualmente por el docente
    if (estaLiberado) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_open, color: Colors.blue),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dispositivo Liberado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                  Text(
                    'El docente te ha concedido excepción individual: ${registro?.motivoLiberacion ?? "Uso libre"}',
                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Caso 4: Alumno PRESENTE en el aula -> POLÍTICA ACTIVA
    final appsPermitidas = _sesionActiva!.politicaAplicada.appsPermitidas;
    final excepcionesVigentes = _sesionActiva!.excepcionesTemporales
        .where((e) => e.estaVigente && (e.alumnoUid == null || e.alumnoUid == widget.alumno.uid))
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: esExamen ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: esExamen ? Colors.red.shade400 : Colors.green.shade600,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    esExamen ? Icons.assignment_late : Icons.verified_user,
                    color: esExamen ? Colors.red.shade800 : Colors.green.shade800,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    esExamen ? 'MODO EXAMEN RIGUROSO ACTIVO' : 'MODO CLASE ACTIVO EN AULA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: esExamen ? Colors.red.shade900 : Colors.green.shade900,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: esExamen ? Colors.red.shade100 : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _sesionActiva!.cursoNombre,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: esExamen ? Colors.red.shade800 : Colors.green.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            esExamen
                ? 'Supervisión activa: Mantén la atención en tu prueba. Las salidas de la aplicación se registrarán en la bitácora.'
                : 'Redes sociales y juegos bloqueados durante la clase. Utilidades educativas autorizadas:',
            style: const TextStyle(fontSize: 11, color: Colors.black87),
          ),

          // Excepciones temporales si las hay
          if (excepcionesVigentes.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...excepcionesVigentes.map((ex) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.alarm_on, size: 14, color: Colors.amber),
                      const SizedBox(width: 6),
                      Text(
                        'Excepción activa: ${ex.appNombre} (Quedan ${ex.segundosRestantes ~/ 60}m ${ex.segundosRestantes % 60}s)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                      ),
                    ],
                  ),
                )),
          ],

          if (!esExamen) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: appsPermitidas.map((a) {
                return Chip(
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  avatar: const Icon(Icons.check, size: 12, color: Colors.green),
                  label: Text(a.nombre, style: const TextStyle(fontSize: 10)),
                  backgroundColor: Colors.white,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
