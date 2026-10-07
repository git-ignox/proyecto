import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design/app_colors.dart';

/// Bloque de acciones rápidas para el alumno con accesos visuales directos
/// a Clases, Exámenes, Calificaciones, Refuerzo y Materiales Offline.
/// Estilo Claude: tarjetas con fondo blanco/pergamino, bordes hairline #E8E6DC,
/// paleta editorial de acentos (salvia, pizarra, terracota, ámbar) y tipografía cuidada.
class WidgetAccionesRapidasAlumno extends StatelessWidget {
  const WidgetAccionesRapidasAlumno({
    super.key,
    required this.onAbrirClases,
    required this.onAbrirExamenes,
    required this.onAbrirCalificaciones,
    required this.onAbrirDiagnostico,
    required this.onAbrirMaterialesOffline,
    this.totalClases = 0,
    this.totalExamenes = 0,
  });

  final VoidCallback onAbrirClases;
  final VoidCallback onAbrirExamenes;
  final VoidCallback onAbrirCalificaciones;
  final VoidCallback onAbrirDiagnostico;
  final VoidCallback onAbrirMaterialesOffline;
  final int totalClases;
  final int totalExamenes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '⚡ Acciones Rápidas',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.claudeTextoPrincipal,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'Tu aula digital',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.claudeTextoSecundario,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final anchoTarjeta = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  _TarjetaAccion(
                    ancho: anchoTarjeta,
                    titulo: 'Mis Clases',
                    subtitulo: totalClases > 0 ? '$totalClases curso(s)' : 'Unirse con código',
                    icono: Icons.class_outlined,
                    colorAcento: AppColors.claudeVerde,
                    colorFondoIcono: const Color(0xFFF0F4EC),
                    badgeTexto: totalClases > 0 ? '$totalClases' : null,
                    onTap: onAbrirClases,
                  ),
                  _TarjetaAccion(
                    ancho: anchoTarjeta,
                    titulo: 'Exámenes',
                    subtitulo: totalExamenes > 0 ? '$totalExamenes asignado(s)' : 'Diagnósticos',
                    icono: Icons.assignment_outlined,
                    colorAcento: AppColors.claudeAzul,
                    colorFondoIcono: const Color(0xFFEEF4FA),
                    badgeTexto: totalExamenes > 0 ? '$totalExamenes' : null,
                    onTap: onAbrirExamenes,
                  ),
                  _TarjetaAccion(
                    ancho: anchoTarjeta,
                    titulo: 'Mis Notas',
                    subtitulo: 'Boletín y brechas',
                    icono: Icons.grading_outlined,
                    colorAcento: AppColors.claudeTerracota,
                    colorFondoIcono: const Color(0xFFFDF4F0),
                    onTap: onAbrirCalificaciones,
                  ),
                  _TarjetaAccion(
                    ancho: anchoTarjeta,
                    titulo: 'Mi Diagnóstico',
                    subtitulo: 'Refuerzo adaptativo',
                    icono: Icons.psychology_outlined,
                    colorAcento: AppColors.claudeAmbar,
                    colorFondoIcono: const Color(0xFFFAF3E8),
                    onTap: onAbrirDiagnostico,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          // Botón ancho para Modo Offline con estilo Claude Oatmeal / Superficie Suave
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAbrirMaterialesOffline,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.claudeSuperficieSuave,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.claudeBorde, width: 1.0),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.claudeBorde, width: 0.8),
                      ),
                      child: Icon(
                        Icons.cloud_done_outlined,
                        color: AppColors.claudeTextoSecundario,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Materiales sin Conexión (Offline)',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.claudeTextoPrincipal,
                            ),
                          ),
                          Text(
                            'Descarga contenidos para practicar sin internet',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.claudeTextoSecundario,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 13,
                      color: AppColors.claudeTextoAtenuado,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaAccion extends StatelessWidget {
  const _TarjetaAccion({
    required this.ancho,
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.colorAcento,
    required this.colorFondoIcono,
    required this.onTap,
    this.badgeTexto,
  });

  final double ancho;
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Color colorAcento;
  final Color colorFondoIcono;
  final VoidCallback onTap;
  final String? badgeTexto;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: ancho,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.claudeBorde, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: colorFondoIcono,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorAcento.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                child: Icon(icono, color: colorAcento, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            titulo,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                              color: AppColors.claudeTextoPrincipal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (badgeTexto != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: colorAcento,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              badgeTexto!,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
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
      ),
    );
  }
}
