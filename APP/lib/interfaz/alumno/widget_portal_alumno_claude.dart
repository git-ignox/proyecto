import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../dominio/modelos/clase_escolar.dart';
import '../../dominio/modelos/diagnostico_alumno.dart';
import '../../dominio/modelos/examen_diagnostico.dart';
import '../../dominio/modelos/usuario_app.dart';
import '../design/app_colors.dart';
import '../widgets/claude_auth_components.dart';

/// Portal Principal del Alumno con estética inspirada en Anthropic Claude.
///
/// Reproduce con precisión editorial la pantalla institucional del alumno:
///  • Encabezado con marca y selectores de perfil y notificaciones.
///  • Cuadrícula de 8 accesos rápidos (Anuncios, Mensajes, Calendario, Reportes,
///    Libro de notas, Distribución de clases, Asistencia, Políticas).
///  • Sección 'Mis Clases' con monogramas de materias y filtro de grado.
///  • Panel lateral con 'Eventos' y 'Tareas y plazos' con pestañas y botón 'Mira lo que sigue'.
class WidgetPortalAlumnoClaude extends StatefulWidget {
  const WidgetPortalAlumnoClaude({
    super.key,
    required this.usuario,
    this.clases = const [],
    this.examenes = const [],
    this.diagnostico,
    required this.onAbrirClases,
    required this.onAbrirExamenes,
    required this.onAbrirCalificaciones,
    required this.onAbrirDiagnostico,
    required this.onAbrirMaterialesOffline,
    required this.onVerCalendario,
    required this.onVerHorarios,
    required this.onVerAnuncios,
    required this.onVerMensajes,
    required this.onVerAsistencia,
    required this.onVerPoliticas,
    required this.onMiraLoQueSigue,
    this.onSeleccionarClase,
  });

  final UsuarioApp usuario;
  final List<ClaseEscolar> clases;
  final List<ExamenDiagnostico> examenes;
  final DiagnosticoAlumno? diagnostico;

  final VoidCallback onAbrirClases;
  final VoidCallback onAbrirExamenes;
  final VoidCallback onAbrirCalificaciones;
  final VoidCallback onAbrirDiagnostico;
  final VoidCallback onAbrirMaterialesOffline;
  final VoidCallback onVerCalendario;
  final VoidCallback onVerHorarios;
  final VoidCallback onVerAnuncios;
  final VoidCallback onVerMensajes;
  final VoidCallback onVerAsistencia;
  final VoidCallback onVerPoliticas;
  final VoidCallback onMiraLoQueSigue;
  final ValueChanged<ClaseEscolar>? onSeleccionarClase;

  @override
  State<WidgetPortalAlumnoClaude> createState() => _WidgetPortalAlumnoClaudeState();
}

class _WidgetPortalAlumnoClaudeState extends State<WidgetPortalAlumnoClaude> {
  int _pestanaTareasIndex = 0; // 0: Próximos, 1: Vencido, 2: Sin fecha (42), 3: No entregado (20)
  int _filtroClasesIndex = 0; // 0: Todas, 1: Secundaria C, 2: Ciencias, 3: Artes y Tec

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final esPantallaAncha = constraints.maxWidth >= 900;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (esPantallaAncha)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Columna izquierda: 8 accesos y Mis Clases
                    Expanded(
                      flex: 62,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _construirGrillaAccesos(esPantallaAncha: true),
                          const SizedBox(height: 24),
                          _construirSeccionMisClases(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Columna derecha: Eventos y Tareas y plazos
                    Expanded(
                      flex: 38,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _construirTarjetaEventos(),
                          const SizedBox(height: 16),
                          _construirTarjetaTareasPlazos(),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _construirGrillaAccesos(esPantallaAncha: false),
                    const SizedBox(height: 20),
                    _construirTarjetaEventos(),
                    const SizedBox(height: 16),
                    _construirTarjetaTareasPlazos(),
                    const SizedBox(height: 24),
                    _construirSeccionMisClases(),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 1. Grilla de 8 accesos rápidos (Estética Claude)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _construirGrillaAccesos({required bool esPantallaAncha}) {
    final items = [
      _DatoAcceso(
        titulo: 'Anuncios del colegio',
        icono: Icons.campaign_rounded,
        colorFondoIcono: const Color(0xFFF3E8FF),
        colorIcono: const Color(0xFF7C3AED),
        badgeTexto: '9',
        onTap: widget.onVerAnuncios,
      ),
      _DatoAcceso(
        titulo: 'Mensajes',
        icono: Icons.chat_bubble_outline_rounded,
        colorFondoIcono: const Color(0xFFECFCCB),
        colorIcono: const Color(0xFF65A30D),
        onTap: widget.onVerMensajes,
      ),
      _DatoAcceso(
        titulo: 'Calendario',
        subtitulo: '7° oct., 2026',
        icono: Icons.calendar_month_outlined,
        colorFondoIcono: const Color(0xFFFEF3C7),
        colorIcono: const Color(0xFFD97706),
        onTap: widget.onVerCalendario,
      ),
      _DatoAcceso(
        titulo: 'Reportes de progreso',
        subtitulo: '1 informe',
        icono: Icons.assignment_outlined,
        colorFondoIcono: const Color(0xFFD1FAE5),
        colorIcono: const Color(0xFF059669),
        onTap: widget.onAbrirExamenes,
      ),
      _DatoAcceso(
        titulo: 'Libro de notas',
        icono: Icons.insert_chart_outlined_rounded,
        colorFondoIcono: const Color(0xFFE0F2FE),
        colorIcono: const Color(0xFF0284C7),
        onTap: widget.onAbrirCalificaciones,
      ),
      _DatoAcceso(
        titulo: 'Distribución de las clases',
        icono: Icons.event_note_outlined,
        colorFondoIcono: const Color(0xFFFFE4E6),
        colorIcono: const Color(0xFFE11D48),
        onTap: widget.onVerHorarios,
      ),
      _DatoAcceso(
        titulo: 'Asistencia',
        subtitulo: '100%',
        icono: Icons.fact_check_outlined,
        colorFondoIcono: const Color(0xFFFEF9C3),
        colorIcono: const Color(0xFFCA8A04),
        onTap: widget.onVerAsistencia,
      ),
      _DatoAcceso(
        titulo: 'Políticas y recursos escolares',
        icono: Icons.verified_user_outlined,
        colorFondoIcono: const Color(0xFFCCFBF1),
        colorIcono: const Color(0xFF0D9488),
        onTap: widget.onVerPoliticas,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final anchoCol = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            return SizedBox(
              width: anchoCol,
              child: _TarjetaAccesoClaude(item: item),
            );
          }).toList(),
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 2. Sección "Mis Clases"
  // ──────────────────────────────────────────────────────────────────────────
  Widget _construirSeccionMisClases() {
    // Materias por defecto que reflejan fielmente la imagen del portal escolar
    final clasesPortal = [
      _DatoClase(
        codigo: 'AD',
        colorBadgeFondo: const Color(0xFFE0F2FE),
        colorBadgeTexto: const Color(0xFF0284C7),
        titulo: 'Arte Diversificado Teatro',
        subtitulo: 'Arte Diversificado Teatro de Tercero de Secundaria C',
        categoria: 'Artes',
      ),
      _DatoClase(
        codigo: 'B',
        colorBadgeFondo: const Color(0xFFFCE7F3),
        colorBadgeTexto: const Color(0xFFDB2777),
        titulo: 'Biologia',
        subtitulo: 'Biologia de Tercero de Secundaria C',
        categoria: 'Ciencias',
      ),
      _DatoClase(
        codigo: 'CS',
        colorBadgeFondo: const Color(0xFFD1FAE5),
        colorBadgeTexto: const Color(0xFF059669),
        titulo: 'Ciencias Sociales',
        subtitulo: 'Ciencias Sociales de Tercero de Secundaria C',
        categoria: 'Ciencias',
      ),
      _DatoClase(
        codigo: 'CA',
        colorBadgeFondo: const Color(0xFFFFE4E6),
        colorBadgeTexto: const Color(0xFFDC2626),
        titulo: 'Computacion ATSA',
        subtitulo: 'Computacion ATSA de Tercero de Secundaria C',
        categoria: 'Tecnología',
      ),
    ];

    // Integrar también las clases reales en las que el alumno esté matriculado
    for (final c in widget.clases) {
      if (!clasesPortal.any((item) => item.titulo.toLowerCase() == c.nombre.toLowerCase())) {
        final codigo = c.nombre.length >= 2 ? c.nombre.substring(0, 2).toUpperCase() : 'MA';
        clasesPortal.add(
          _DatoClase(
            codigo: codigo,
            colorBadgeFondo: const Color(0xFFFBECE7),
            colorBadgeTexto: AppColors.claudeTerracota,
            titulo: c.nombre,
            subtitulo: '${c.nombre} • Prof: ${c.profesorNombre.isNotEmpty ? c.profesorNombre : "Docente"}',
            claseReal: c,
          ),
        );
      }
    }

    final clasesFiltradas = switch (_filtroClasesIndex) {
      1 => clasesPortal.where((c) => c.subtitulo.contains('Secundaria C')).toList(),
      2 => clasesPortal.where((c) => c.categoria == 'Ciencias').toList(),
      3 => clasesPortal.where((c) => c.categoria == 'Artes' || c.categoria == 'Tecnología').toList(),
      _ => clasesPortal,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado de la sección
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mis Clases',
              style: GoogleFonts.lora(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.claudeTextoPrincipal,
                letterSpacing: -0.2,
              ),
            ),
            // Filtro estilo Claude
            PopupMenuButton<int>(
              tooltip: 'Filtrar clases',
              initialValue: _filtroClasesIndex,
              onSelected: (val) => setState(() => _filtroClasesIndex = val),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.claudeBorde),
              ),
              color: AppColors.claudeSuperficie,
              elevation: 4,
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 0, child: Text('Todas las clases')),
                const PopupMenuItem(value: 1, child: Text('Tercero de Secundaria C')),
                const PopupMenuItem(value: 2, child: Text('Área de Ciencias')),
                const PopupMenuItem(value: 3, child: Text('Artes y Computación')),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.claudeSuperficie,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.claudeBorde, width: 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.filter_alt_outlined, size: 15, color: AppColors.claudeTextoSecundario),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: const BoxDecoration(
                        color: Color(0xFF141413),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_filtroClasesIndex == 0 ? 1 : _filtroClasesIndex}',
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.claudeTextoSecundario),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Grid de clases
        LayoutBuilder(
          builder: (context, constraints) {
            final anchoCol = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: clasesFiltradas.map((c) {
                return SizedBox(
                  width: anchoCol,
                  child: _TarjetaClaseClaude(
                    dato: c,
                    onTap: () {
                      if (c.claseReal != null && widget.onSeleccionarClase != null) {
                        widget.onSeleccionarClase!(c.claseReal!);
                      } else {
                        widget.onAbrirClases();
                      }
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 3. Panel Lateral: Eventos
  // ──────────────────────────────────────────────────────────────────────────
  Widget _construirTarjetaEventos() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.claudeSuperficie.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.claudeBorde, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Eventos',
                  style: GoogleFonts.lora(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.claudeTextoPrincipal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: widget.onVerCalendario,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Ver calendario',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.claudeTerracota,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'No hay próximos eventos en los próximos 7 días',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.claudeTextoSecundario,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 4. Panel Lateral: Tareas y plazos
  // ──────────────────────────────────────────────────────────────────────────
  Widget _construirTarjetaTareasPlazos() {
    final pestanas = [
      'Próximos',
      'Vencido',
      'Sin fecha de entrega (42)',
      'No entregado (20)',
    ];

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.claudeSuperficie.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.claudeBorde, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Tareas y plazos',
                  style: GoogleFonts.lora(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.claudeTextoPrincipal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: widget.onAbrirExamenes,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Ver todo(s)',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.claudeTerracota,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Barra horizontal de pestañas
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(pestanas.length, (idx) {
                final activa = _pestanaTareasIndex == idx;
                return Padding(
                  padding: const EdgeInsets.only(right: 14.0),
                  child: InkWell(
                    onTap: () => setState(() => _pestanaTareasIndex = idx),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            pestanas[idx],
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: activa ? FontWeight.w600 : FontWeight.w400,
                              color: activa ? AppColors.claudeTextoPrincipal : AppColors.claudeTextoSecundario,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 2,
                            width: activa ? 36 : 0,
                            color: activa ? AppColors.claudeTerracota : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const Divider(height: 1, color: AppColors.claudeBorde),
          const SizedBox(height: 24),

          // Cuerpo de la pestaña activa
          _construirContenidoPestanaTareas(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _construirContenidoPestanaTareas() {
    switch (_pestanaTareasIndex) {
      case 0: // Próximos
        return Column(
          children: [
            const Text(
              '👀',
              style: TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 12),
            Text(
              'No tienes ninguna tarea pendiente desde hace 30 días, ¡pero no te quedes sin tu tarea atrasada!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: AppColors.claudeTextoSecundario,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton(
                onPressed: widget.onMiraLoQueSigue,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.claudeTextoPrincipal,
                  backgroundColor: AppColors.claudeSuperficieSuave,
                  side: const BorderSide(color: AppColors.claudeBorde, width: 1.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text(
                  'Mira lo que sigue',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.claudeTextoPrincipal,
                  ),
                ),
              ),
            ),
          ],
        );
      case 2: // Sin fecha de entrega (42)
        return Column(
          children: [
            const Icon(Icons.assignment_turned_in_outlined, size: 36, color: AppColors.claudeTerracota),
            const SizedBox(height: 8),
            Text(
              '42 actividades de refuerzo y práctica disponibles sin límite de tiempo.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.claudeTextoSecundario,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: widget.onMiraLoQueSigue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.claudeTerracota,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: const Text('Comenzar Práctica'),
            ),
          ],
        );
      case 1: // Vencido
      case 3: // No entregado
      default:
        return Column(
          children: [
            const Icon(Icons.check_circle_outline, size: 36, color: AppColors.claudeVerde),
            const SizedBox(height: 8),
            Text(
              '¡Excelente trabajo! No registras tareas pendientes en esta sección.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.claudeTextoSecundario,
              ),
            ),
          ],
        );
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Modelos de datos para el Portal
// ──────────────────────────────────────────────────────────────────────────
class _DatoAcceso {
  const _DatoAcceso({
    required this.titulo,
    this.subtitulo,
    required this.icono,
    required this.colorFondoIcono,
    required this.colorIcono,
    this.badgeTexto,
    required this.onTap,
  });

  final String titulo;
  final String? subtitulo;
  final IconData icono;
  final Color colorFondoIcono;
  final Color colorIcono;
  final String? badgeTexto;
  final VoidCallback onTap;
}

class _DatoClase {
  const _DatoClase({
    required this.codigo,
    required this.colorBadgeFondo,
    required this.colorBadgeTexto,
    required this.titulo,
    required this.subtitulo,
    this.categoria = 'General',
    this.claseReal,
  });

  final String codigo;
  final Color colorBadgeFondo;
  final Color colorBadgeTexto;
  final String titulo;
  final String subtitulo;
  final String categoria;
  final ClaseEscolar? claseReal;
}

// ──────────────────────────────────────────────────────────────────────────
// Widget de Tarjeta de Acceso (Claude Style)
// ──────────────────────────────────────────────────────────────────────────
class _TarjetaAccesoClaude extends StatelessWidget {
  const _TarjetaAccesoClaude({required this.item});

  final _DatoAcceso item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.claudeSuperficie.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.claudeBorde, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Contenedor suave de icono con sombra táctil suave
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: item.colorFondoIcono,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: item.colorIcono.withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        item.icono,
                        color: item.colorIcono,
                        size: 24,
                      ),
                    ),
                  ),
                  if (item.badgeTexto != null)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE11D48),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          item.badgeTexto!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              // Texto de la tarjeta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.titulo,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.claudeTextoPrincipal,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.subtitulo != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitulo!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.claudeTextoSecundario,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Widget de Tarjeta de Clase (Claude Style)
// ──────────────────────────────────────────────────────────────────────────
class _TarjetaClaseClaude extends StatelessWidget {
  const _TarjetaClaseClaude({
    required this.dato,
    required this.onTap,
  });

  final _DatoClase dato;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.claudeSuperficie.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.claudeBorde, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Monograma
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: dato.colorBadgeFondo,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    dato.codigo,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: dato.colorBadgeTexto,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Título y descripción
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dato.titulo,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.claudeTextoPrincipal,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dato.subtitulo,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: AppColors.claudeTextoSecundario,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
