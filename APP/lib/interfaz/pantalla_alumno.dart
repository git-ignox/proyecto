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
import '../datos/repositorio_sesiones_clase.dart';
import '../datos/fuente_datos_sesiones_clase.dart';
import '../datos/repositorio_auditoria.dart';
import '../datos/fuente_datos_auditoria.dart';
import '../datos/fuente_datos_politicas.dart';
import 'alumno/widget_supervision_aula.dart';
import '../datos/coordinador_sincronizacion_offline.dart';
import '../datos/fuente_datos_materiales_offline.dart';
import 'offline/widget_tarjeta_disponibilidad_offline.dart';
import 'offline/hoja_gestion_materiales_offline.dart';
import '../dominio/modelos/clase_escolar.dart';
import '../dominio/modelos/diagnostico_alumno.dart';
import 'alumno/widget_acciones_rapidas.dart';
import 'alumno/widget_hero_alumno.dart';
import 'alumno/widget_modulos_aprendizaje.dart';
import 'alumno/widget_resumen_metricas.dart';
import 'alumno/widget_portal_alumno_claude.dart';
import 'design/app_colors.dart';
import 'widgets/claude_auth_components.dart';
import 'widgets/mac_glass_widgets.dart';
import 'package:google_fonts/google_fonts.dart';

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
    RepositorioSesionesClase? repositorioSesiones,
    RepositorioAuditoria? repositorioAuditoria,
    CoordinadorSincronizacionOffline? coordinadorOffline,
  })  : repositorioDiagnostico = repositorioDiagnostico ?? FuenteDatosDiagnostico(),
        repositorioClases = repositorioClases ?? FuenteDatosClases(),
        repositorioEvaluaciones = repositorioEvaluaciones ?? FuenteDatosEvaluaciones(),
        repositorioReportes = repositorioReportes ?? FuenteDatosReportes(),
        repositorioAuditoria = repositorioAuditoria ?? FuenteDatosAuditoria(),
        repositorioSesiones = repositorioSesiones ??
            FuenteDatosSesionesClase(
              repositorioPoliticas: FuenteDatosPoliticas(),
              repositorioAuditoria: repositorioAuditoria ?? FuenteDatosAuditoria(),
            ),
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
  final RepositorioSesionesClase repositorioSesiones;
  final RepositorioAuditoria repositorioAuditoria;
  final CoordinadorSincronizacionOffline coordinadorOffline;

  @override
  State<PantallaAlumno> createState() => _PantallaAlumnoState();
}

class _PantallaAlumnoState extends State<PantallaAlumno> {
  late final CoordinadorSincronizacionOffline _coordinadorOffline;
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

  List<String> _clasesInscritasUids = [];
  int _pestanaActual = 0;
  DiagnosticoAlumno? _diagnostico;
  List<ExamenDiagnostico> _examenes = [];
  List<ClaseEscolar> _clases = [];

  @override
  void initState() {
    super.initState();
    _coordinadorOffline = widget.coordinadorOffline;
    _cargarEjercicios();
    _cargarClasesAlumno();
    _cargarDiagnostico();
    _cargarExamenes();
  }

  void _mostrarMaterialesOffline() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HojaGestionMaterialesOffline(
        coordinador: _coordinadorOffline,
      ),
    );
  }

  String _obtenerIniciales(String nombre) {
    if (nombre.isEmpty) return 'DL';
    final partes = nombre.trim().split(RegExp(r'\s+'));
    if (partes.length == 1) return partes[0].substring(0, 1).toUpperCase();
    return (partes[0][0] + partes[1][0]).toUpperCase();
  }

  void _mostrarDialogoAnuncios() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.claudeSuperficie,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.claudeBorde),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.campaign_rounded, color: Color(0xFF7C3AED), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Anuncios del colegio',
                    style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.claudeTextoPrincipal),
                  ),
                  Text(
                    'Colegio San Agustín • Ciclo 2026',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.claudeTextoSecundario),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _itemAnuncio(
                titulo: '🎉 Semana Aniversario 2026',
                fecha: 'Hoy, 09:30 AM',
                descripcion: 'Las actividades deportivas y científicas inician este viernes. Revisa el cronograma en portería.',
                etiqueta: 'Institucional',
                colorEtiqueta: AppColors.claudeTerracota,
              ),
              const Divider(height: 20, color: AppColors.claudeBorde),
              _itemAnuncio(
                titulo: '📊 Reportes del 3er Bimestre',
                fecha: 'Ayer, 16:00 PM',
                descripcion: 'Los informes de avance pedagógico ya están disponibles en la sección de progreso.',
                etiqueta: 'Académico',
                colorEtiqueta: AppColors.claudeVerde,
              ),
              const Divider(height: 20, color: AppColors.claudeBorde),
              _itemAnuncio(
                titulo: '🔬 Olimpiada de Ciencias y Matemáticas',
                fecha: '05 oct., 2026',
                descripcion: 'Inscripciones abiertas para estudiantes de Secundaria. Consulta con tu profesor.',
                etiqueta: 'Convocatoria',
                colorEtiqueta: AppColors.claudeAzul,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cerrar', style: GoogleFonts.poppins(color: AppColors.claudeTerracota, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _itemAnuncio({
    required String titulo,
    required String fecha,
    required String descripcion,
    required String etiqueta,
    required Color colorEtiqueta,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                titulo,
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.claudeTextoPrincipal),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: colorEtiqueta.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                etiqueta,
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: colorEtiqueta),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(fecha, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.claudeTextoAtenuado)),
        const SizedBox(height: 4),
        Text(descripcion, style: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.claudeTextoSecundario, height: 1.35)),
      ],
    );
  }

  void _mostrarDialogoMensajes() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.claudeSuperficie,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.claudeBorde),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFCCB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF65A30D), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mensajes',
                    style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.claudeTextoPrincipal),
                  ),
                  Text(
                    'Bandeja de mensajes de profesores',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.claudeTextoSecundario),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _itemMensaje('Prof. Claudia Morales', 'Biología', 'Guía de laboratorio subida al aula virtual', 'Hace 2 horas'),
              const Divider(height: 16, color: AppColors.claudeBorde),
              _itemMensaje('Prof. Fernando Soto', 'Matemáticas', '¡Excelente resolución en el cálculo de fracciones!', 'Ayer'),
              const Divider(height: 16, color: AppColors.claudeBorde),
              _itemMensaje('Tutoría Tercero C', 'Tutoría', 'Recordatorio de entrega de materiales para el taller', '3 días atrás'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cerrar', style: GoogleFonts.poppins(color: AppColors.claudeTerracota, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _itemMensaje(String remitente, String materia, String texto, String tiempo) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.claudeTerracotaClaro,
          child: Text(remitente.substring(0, 1), style: const TextStyle(color: AppColors.claudeTerracota, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(remitente, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.claudeTextoPrincipal)),
                  Text(tiempo, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.claudeTextoAtenuado)),
                ],
              ),
              Text(materia, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.claudeTerracota, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(texto, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.claudeTextoSecundario)),
            ],
          ),
        ),
      ],
    );
  }

  void _mostrarDialogoCalendario() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.claudeSuperficie,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.claudeBorde),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_month_outlined, color: Color(0xFFD97706), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calendario Escolar',
                    style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.claudeTextoPrincipal),
                  ),
                  Text(
                    '7° oct., 2026 • Colegio San Agustín',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.claudeTextoSecundario),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.claudeSuperficieSuave,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.claudeBorde),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.today, color: AppColors.claudeTerracota, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Hoy: Miércoles, 7 de octubre de 2026',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.claudeTextoPrincipal),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Próximas fechas del calendario:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.claudeTextoPrincipal),
              ),
              const SizedBox(height: 10),
              _itemEventoCalendario('12 Oct', 'Feriado Nacional - Día del Encuentro'),
              _itemEventoCalendario('18 Oct', 'Examen Diagnóstico Bimestral de Aritmética'),
              _itemEventoCalendario('25 Oct', 'Presentación de Proyectos en Computación ATSA'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cerrar', style: GoogleFonts.poppins(color: AppColors.claudeTerracota, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _itemEventoCalendario(String fecha, String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.claudeTerracotaClaro,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              fecha,
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.claudeTerracota),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              titulo,
              style: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.claudeTextoPrincipal),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoHorarios() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.claudeSuperficie,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.claudeBorde),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4E6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.event_note_outlined, color: Color(0xFFE11D48), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Distribución de las clases',
                    style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.claudeTextoPrincipal),
                  ),
                  Text(
                    'Tercero de Secundaria C • Horario Semanal',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.claudeTextoSecundario),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _filaHorario('08:00 - 09:30', 'Biología', 'Aula 12', const Color(0xFFFCE7F3), const Color(0xFFDB2777)),
              const SizedBox(height: 8),
              _filaHorario('09:45 - 11:15', 'Matemáticas', 'Aula 10', const Color(0xFFFBECE7), AppColors.claudeTerracota),
              const SizedBox(height: 8),
              _filaHorario('11:30 - 13:00', 'Ciencias Sociales', 'Aula 14', const Color(0xFFD1FAE5), const Color(0xFF059669)),
              const SizedBox(height: 8),
              _filaHorario('14:00 - 15:30', 'Computación ATSA', 'Laboratorio Informática', const Color(0xFFFFE4E6), const Color(0xFFDC2626)),
              const SizedBox(height: 8),
              _filaHorario('15:45 - 17:00', 'Arte Diversificado Teatro', 'Auditorio Central', const Color(0xFFE0F2FE), const Color(0xFF0284C7)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cerrar', style: GoogleFonts.poppins(color: AppColors.claudeTerracota, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _filaHorario(String hora, String materia, String aula, Color fondo, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: fondo.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fondo),
      ),
      child: Row(
        children: [
          Text(hora, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.claudeTextoPrincipal)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(materia, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          ),
          Text(aula, style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.claudeTextoSecundario)),
        ],
      ),
    );
  }

  void _mostrarDialogoAsistencia() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.claudeSuperficie,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.claudeBorde),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF9C3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fact_check_outlined, color: Color(0xFFCA8A04), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Asistencia',
                    style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.claudeTextoPrincipal),
                  ),
                  Text(
                    '100% de asistencia regular acumulada',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.claudeTextoSecundario),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: Color(0xFF16A34A), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Asistencia Perfecta', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13.5, color: const Color(0xFF15803D))),
                          Text('0 tardanzas • 0 faltas injustificadas', style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF166534))),
                        ],
                      ),
                    ),
                    Text('100%', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF15803D))),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _itemAsistenciaMateria('Matemáticas', '24/24 sesiones', '100%'),
              _itemAsistenciaMateria('Ciencias Sociales', '22/22 sesiones', '100%'),
              _itemAsistenciaMateria('Biología', '20/20 sesiones', '100%'),
              _itemAsistenciaMateria('Computación ATSA', '18/18 sesiones', '100%'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cerrar', style: GoogleFonts.poppins(color: AppColors.claudeTerracota, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _itemAsistenciaMateria(String materia, String sesiones, String porcentaje) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(materia, style: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.claudeTextoPrincipal)),
          Row(
            children: [
              Text(sesiones, style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.claudeTextoSecundario)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                child: Text(porcentaje, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF15803D))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoPoliticas() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.claudeSuperficie,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.claudeBorde),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFCCFBF1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.verified_user_outlined, color: Color(0xFF0D9488), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Políticas y recursos escolares',
                    style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.claudeTextoPrincipal),
                  ),
                  Text(
                    'Manual de convivencia y biblioteca escolar',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.claudeTextoSecundario),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _itemPolitica('📘 Manual de Convivencia Escolar', 'Reglamento interno sobre puntualidad, respeto mutuo y convivencia escolar.'),
              const Divider(height: 16, color: AppColors.claudeBorde),
              _itemPolitica('🛡️ Uso Responsable de Dispositivos', 'Lineamientos para el uso pedagógico de tablets y ordenadores en el aula.'),
              const Divider(height: 16, color: AppColors.claudeBorde),
              _itemPolitica('💾 Recursos sin Conexión', 'Descarga de cuadernos de trabajo y fichas de ejercicios para estudiar sin internet.'),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _mostrarMaterialesOffline();
                  },
                  icon: const Icon(Icons.download_for_offline_outlined, size: 18),
                  label: const Text('Abrir Gestor de Materiales Offline'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.claudeTerracota,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cerrar', style: GoogleFonts.poppins(color: AppColors.claudeTerracota, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _itemPolitica(String titulo, String subtitulo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.claudeTextoPrincipal)),
        const SizedBox(height: 2),
        Text(subtitulo, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.claudeTextoSecundario, height: 1.35)),
      ],
    );
  }

  Future<void> _cargarDiagnostico() async {
    final diag = await widget.repositorioDiagnostico.obtenerDiagnostico(widget.usuario.uid);
    if (mounted) {
      setState(() => _diagnostico = diag);
    }
  }

  Future<void> _cargarExamenes() async {
    final exams = await widget.repositorioDiagnostico.obtenerExamenes();
    if (mounted) {
      setState(() => _examenes = exams);
    }
  }

  Future<void> _cargarClasesAlumno() async {
    final clases = await widget.repositorioClases.obtenerClasesPorAlumno(widget.usuario.uid);
    if (mounted) {
      setState(() {
        _clases = clases;
        _clasesInscritasUids = clases.map((c) => c.id).toList();
      });
    }
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
    _cargarDiagnostico();
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

    String? mensajeError;
    bool cargando = false;

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
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
    return MacDesktopBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(66),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161514).withValues(alpha: 0.88),
            border: const Border(
              bottom: BorderSide(color: AppColors.claudeBorde, width: 1.0),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: Row(
                children: [
                  // Título de la pantalla
                  Expanded(
                    child: Row(
                      children: [
                        // Título "Inicio - 2026" y "Colegio San Agustín"
                        Flexible(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Inicio - 2026',
                                style: GoogleFonts.lora(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.claudeTextoPrincipal,
                                  letterSpacing: -0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                widget.usuario.institucionId.isNotEmpty ? widget.usuario.institucionId : 'Colegio San Agustín',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.claudeTextoSecundario,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Puntos del alumno (chip terracota / ámbar)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.claudeTerracotaClaro,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.claudeTerracota.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded, size: 15, color: AppColors.claudeTerracota),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.usuario.puntosAcumulados} pts',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: AppColors.claudeTerracota,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Perfil de alumno con dropdown (DL o iniciales)
                  PopupMenuButton<String>(
                    tooltip: 'Menú de Usuario',
                    onSelected: (val) {
                      if (val == 'demo') {
                        widget.servicioAuth.alternarRol();
                      } else if (val == 'logout') {
                        widget.servicioAuth.cerrarSesion();
                      } else if (val == 'diag') {
                        _mostrarDiagnostico();
                      }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.claudeBorde),
                    ),
                    color: AppColors.claudeSuperficie,
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        enabled: false,
                        child: Text(
                          widget.usuario.nombre.isNotEmpty ? widget.usuario.nombre : 'Dotzauer Lafuente, Ignacio',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.claudeTextoPrincipal),
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'diag',
                        child: Row(
                          children: [
                            Icon(Icons.analytics_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Mi Diagnóstico y Refuerzo'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'demo',
                        child: Row(
                          children: [
                            Icon(Icons.swap_horiz, size: 18),
                            SizedBox(width: 8),
                            Text('Alternar a modo Docente (Demo)'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 6.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: const Color(0xFF0E7490),
                            child: Text(
                              _obtenerIniciales(widget.usuario.nombre),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: Text(
                              widget.usuario.nombre.isNotEmpty ? widget.usuario.nombre : 'Dotzauer Lafuente, Ignacio',
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.claudeTextoPrincipal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.claudeTextoSecundario),
                        ],
                      ),
                    ),
                  ),
                  // Botón Diagnóstico y Refuerzo
                  IconButton(
                    icon: const Icon(Icons.analytics_outlined, size: 19),
                    tooltip: 'Mi Diagnóstico y Refuerzo',
                    color: AppColors.claudeTextoSecundario,
                    visualDensity: VisualDensity.compact,
                    onPressed: _mostrarDiagnostico,
                  ),
                  // Botón Calendario
                  IconButton(
                    icon: const Icon(Icons.calendar_today_outlined, size: 19),
                    tooltip: 'Calendario Escolar',
                    color: AppColors.claudeTextoSecundario,
                    visualDensity: VisualDensity.compact,
                    onPressed: _mostrarDialogoCalendario,
                  ),
                  // Botón Campana con Badge "8"
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none_outlined, size: 21),
                        tooltip: 'Notificaciones y Avisos',
                        color: AppColors.claudeTextoSecundario,
                        visualDensity: VisualDensity.compact,
                        onPressed: _mostrarDialogoAnuncios,
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE11D48),
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            '8',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _construirCuerpoSegunPestana(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161514).withValues(alpha: 0.88),
          border: const Border(
            top: BorderSide(color: AppColors.claudeBorde, width: 1.0),
          ),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          indicatorColor: AppColors.claudeTerracotaClaro,
          selectedIndex: _pestanaActual,
          onDestinationSelected: (idx) => setState(() => _pestanaActual = idx),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.claudeTerracota),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.edit_note_outlined),
              selectedIcon: Icon(Icons.edit_note, color: AppColors.claudeTerracota),
              label: 'Práctica',
            ),
            NavigationDestination(
              icon: Icon(Icons.class_outlined),
              selectedIcon: Icon(Icons.class_, color: AppColors.claudeTerracota),
              label: 'Mis Clases',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment, color: AppColors.claudeTerracota),
              label: 'Evaluaciones',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights, color: AppColors.claudeTerracota),
              label: 'Diagnóstico',
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _construirCuerpoSegunPestana() {
    switch (_pestanaActual) {
      case 0:
        return _construirVistaInicio();
      case 1:
        return _construirVistaPractica();
      case 2:
        return _construirVistaMisClases();
      case 3:
        return _construirVistaEvaluaciones();
      case 4:
        return _construirVistaDiagnostico();
      default:
        return _construirVistaInicio();
    }
  }

  Widget _construirVistaInicio() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WidgetSupervisionAula(
            alumno: widget.usuario,
            clasesInscritasUids: _clasesInscritasUids,
            repositorioSesiones: widget.repositorioSesiones,
            repositorioAuditoria: widget.repositorioAuditoria,
          ),
          WidgetPortalAlumnoClaude(
            usuario: widget.usuario,
            clases: _clases,
            examenes: _examenes,
            diagnostico: _diagnostico,
            onAbrirClases: () => setState(() => _pestanaActual = 2),
            onAbrirExamenes: _mostrarExamenesDiagnostico,
            onAbrirCalificaciones: _abrirMisCalificaciones,
            onAbrirDiagnostico: () => setState(() => _pestanaActual = 4),
            onAbrirMaterialesOffline: _mostrarMaterialesOffline,
            onVerCalendario: _mostrarDialogoCalendario,
            onVerHorarios: _mostrarDialogoHorarios,
            onVerAnuncios: _mostrarDialogoAnuncios,
            onVerMensajes: _mostrarDialogoMensajes,
            onVerAsistencia: _mostrarDialogoAsistencia,
            onVerPoliticas: _mostrarDialogoPoliticas,
            onMiraLoQueSigue: () => setState(() => _pestanaActual = 1),
            onSeleccionarClase: (c) {
              setState(() => _pestanaActual = 2);
            },
          ),
          WidgetTarjetaDisponibilidadOffline(
            coordinador: _coordinadorOffline,
          ),
          WidgetHeroAlumno(
            usuario: widget.usuario,
            precisionGlobal: _diagnostico?.porcentajePrecision,
            onVerDiagnostico: () => setState(() => _pestanaActual = 4),
          ),
          WidgetAccionesRapidasAlumno(
            onAbrirClases: () => setState(() => _pestanaActual = 2),
            onAbrirExamenes: _mostrarExamenesDiagnostico,
            onAbrirCalificaciones: _abrirMisCalificaciones,
            onAbrirDiagnostico: () => setState(() => _pestanaActual = 4),
            onAbrirMaterialesOffline: _mostrarMaterialesOffline,
            totalClases: _clases.length,
            totalExamenes: _examenes.length,
          ),
          if (_cargando)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: AppColors.claudeTerracota),
              ),
            )
          else if (_ejercicios.isEmpty)
            _construirEstadoVacio()
          else
            _construirTarjetaRetoDestacado(),
          WidgetModulosAprendizajeAlumno(
            onIniciarModulo: (op, nivel) => _generarPracticaRapida(op: op, nivel: nivel),
          ),
          if (_diagnostico != null)
            WidgetResumenMetricasAlumno(
              diagnostico: _diagnostico!,
              onVerDetalles: () => setState(() => _pestanaActual = 4),
              onPracticarRefuerzo: _generarRefuerzoAdaptativo,
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _construirTarjetaRetoDestacado() {
    final ejercicio = _ejercicios[_indiceActual];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.claudeBorde, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.claudeTerracotaClaro,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.bolt, color: AppColors.claudeTerracota, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Reto Matemático de Hoy (${_indiceActual + 1}/${_ejercicios.length})',
                        style: GoogleFonts.lora(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.claudeTextoPrincipal),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _pestanaActual = 1),
                icon: const Icon(Icons.open_in_new, size: 14, color: AppColors.claudeTerracota),
                label: Text('Lienzo Completo', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.claudeTerracota, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              Chip(
                label: Text('Tema: ${ejercicio.codigoTema}', style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.claudeTextoPrincipal)),
                backgroundColor: AppColors.claudeSuperficieSuave,
                side: const BorderSide(color: AppColors.claudeBorde),
                visualDensity: VisualDensity.compact,
              ),
              Chip(
                label: Text('Nivel ${ejercicio.nivel}', style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.claudeTextoPrincipal)),
                backgroundColor: AppColors.claudeSuperficieSuave,
                side: const BorderSide(color: AppColors.claudeBorde),
                visualDensity: VisualDensity.compact,
              ),
              Chip(
                label: Text('+${ejercicio.puntos} puntos', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFFB45309))),
                backgroundColor: const Color(0xFFFEF3C7),
                side: const BorderSide(color: Color(0xFFFDE68A)),
                avatar: const Icon(Icons.star, size: 14, color: Color(0xFFD97706)),
                visualDensity: VisualDensity.compact,
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
                        avatar: const Icon(Icons.local_offer_outlined, size: 13, color: AppColors.claudeTerracota),
                        label: Text(t, style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.claudeTerracotaOscuro)),
                        backgroundColor: AppColors.claudeTerracotaClaro,
                        side: BorderSide(color: AppColors.claudeTerracota.withValues(alpha: 0.2)),
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 14),
          Card(
            elevation: 0,
            color: AppColors.claudeSuperficieSuave,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.claudeBorde),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                ejercicio.enunciado,
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.claudeTextoPrincipal, height: 1.45),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _construirEntradaRespuesta(ejercicio),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _evaluando ? null : _evaluarRespuesta,
            icon: _evaluando
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_outline),
            label: Text('CALIFICAR RESPUESTA', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: AppColors.claudeTerracota,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: _indiceActual > 0 ? () => _cambiarEjercicio(_indiceActual - 1) : null,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Anterior'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.claudeTextoPrincipal,
                  side: const BorderSide(color: AppColors.claudeBorde),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _indiceActual < _ejercicios.length - 1 ? () => _cambiarEjercicio(_indiceActual + 1) : null,
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Siguiente'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.claudeTextoPrincipal,
                  side: const BorderSide(color: AppColors.claudeBorde),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
          if (_resultado != null) ...[
            const SizedBox(height: 12),
            _construirPanelResultado(_resultado!),
          ],
        ],
      ),
    );
  }

  Widget _construirVistaPractica() {
    return Column(
      children: [
        WidgetSupervisionAula(
          alumno: widget.usuario,
          clasesInscritasUids: _clasesInscritasUids,
          repositorioSesiones: widget.repositorioSesiones,
          repositorioAuditoria: widget.repositorioAuditoria,
        ),
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : _ejercicios.isEmpty
                  ? _construirEstadoVacio()
                  : _construirCuerpoEjercicio(),
        ),
      ],
    );
  }

  Widget _construirVistaMisClases() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WidgetSupervisionAula(
            alumno: widget.usuario,
            clasesInscritasUids: _clasesInscritasUids,
            repositorioSesiones: widget.repositorioSesiones,
            repositorioAuditoria: widget.repositorioAuditoria,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🏫 Mis Clases Inscritas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _mostrarDialogoUnirse,
                icon: const Icon(Icons.vpn_key_outlined, size: 16),
                label: const Text('Unirse con Código'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_clases.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.school_outlined, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    'Aún no estás inscrito en ninguna clase.',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pide el código de acceso a tu docente (ej. MAT-101) para comenzar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _mostrarDialogoUnirse,
                    icon: const Icon(Icons.add),
                    label: const Text('INGRESAR CÓDIGO DE CLASE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._clases.map((clase) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.class_outlined, color: Colors.green.shade700, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    clase.nombre,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    clase.gradoGrupo,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 16, color: Colors.indigo),
                            const SizedBox(width: 6),
                            Text('Profesor: ${clase.profesorNombre}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.people_outline, size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text('${clase.totalAlumnos} alumnos en el curso', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                          ],
                        ),
                        if (clase.descripcion.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(clase.descripcion, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _abrirMisCalificaciones,
                            icon: const Icon(Icons.grading, size: 16),
                            label: const Text('Ver Mis Notas & Brechas de Aprendizaje'),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          const SizedBox(height: 16),
          Card(
            color: Colors.blueGrey.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: Icon(Icons.cloud_done_outlined, color: Colors.blueGrey.shade700, size: 28),
              title: const Text('Materiales Descargados (Offline)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Accede a guías y fichas sin conexión'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _mostrarMaterialesOffline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirVistaEvaluaciones() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WidgetSupervisionAula(
            alumno: widget.usuario,
            clasesInscritasUids: _clasesInscritasUids,
            repositorioSesiones: widget.repositorioSesiones,
            repositorioAuditoria: widget.repositorioAuditoria,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade700, Colors.teal.shade500],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.grading, color: Colors.white, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Boletín de Calificaciones',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Revisa tus notas y análisis de brechas pedagógicas',
                        style: TextStyle(color: Colors.teal.shade100, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _abrirMisCalificaciones,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.teal.shade900,
                  ),
                  child: const Text('Ver Notas'),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📝 Exámenes Diagnósticos de Nivelación',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_browser_outlined),
                tooltip: 'Abrir en hoja deslizable',
                onPressed: _mostrarExamenesDiagnostico,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Diseñados por tus profesores para verificar tu avance y habilitar nuevos temas',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          if (_examenes.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Text(
                'No tienes exámenes diagnósticos pendientes en este momento.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ..._examenes.map((exam) => Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.titulo,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(exam.descripcion, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                        const SizedBox(height: 10),
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
                                child: Text(
                                  'Meta: ${(exam.umbralAvance <= 1.0 ? exam.umbralAvance * 100 : exam.umbralAvance).toInt()}% de aciertos mínimos (${exam.criterioAvance.etiqueta})',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.indigo),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _iniciarExamenDiagnostico(exam),
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
    );
  }

  Widget _construirVistaDiagnostico() {
    return FutureBuilder<DiagnosticoAlumno>(
      future: widget.repositorioDiagnostico.obtenerDiagnostico(widget.usuario.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final diag = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WidgetSupervisionAula(
                alumno: widget.usuario,
                clasesInscritasUids: _clasesInscritasUids,
                repositorioSesiones: widget.repositorioSesiones,
                repositorioAuditoria: widget.repositorioAuditoria,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.insights, color: Colors.indigo.shade700, size: 26),
                  const SizedBox(width: 8),
                  const Text(
                    'Mi Diagnóstico Pedagógico',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 14),
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
              const SizedBox(height: 16),
              if (diag.tagsCriticos.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => _generarRefuerzoAdaptativo(diag.tagsCriticos),
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
        );
      },
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
