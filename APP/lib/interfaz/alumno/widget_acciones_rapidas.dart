import 'package:flutter/material.dart';

/// Bloque de acciones rápidas para el alumno con accesos visuales directos
/// a Clases, Exámenes, Calificaciones, Refuerzo y Materiales Offline.
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
              const Text(
                '⚡ Acciones Rápidas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.1,
                ),
              ),
              Text(
                'Tu aula digital',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
                    colorFondo: const Color(0xFFE8F5E9),
                    colorIcono: Colors.green.shade700,
                    colorBorde: Colors.green.shade200,
                    badgeTexto: totalClases > 0 ? '$totalClases' : null,
                    onTap: onAbrirClases,
                  ),
                  _TarjetaAccion(
                    ancho: anchoTarjeta,
                    titulo: 'Exámenes',
                    subtitulo: totalExamenes > 0 ? '$totalExamenes asignado(s)' : 'Diagnósticos',
                    icono: Icons.assignment_outlined,
                    colorFondo: const Color(0xFFFFF8E1),
                    colorIcono: Colors.amber.shade800,
                    colorBorde: Colors.amber.shade300,
                    badgeTexto: totalExamenes > 0 ? '$totalExamenes' : null,
                    onTap: onAbrirExamenes,
                  ),
                  _TarjetaAccion(
                    ancho: anchoTarjeta,
                    titulo: 'Mis Notas',
                    subtitulo: 'Boletín y brechas',
                    icono: Icons.grading_outlined,
                    colorFondo: const Color(0xFFE0F7FA),
                    colorIcono: Colors.teal.shade700,
                    colorBorde: Colors.teal.shade200,
                    onTap: onAbrirCalificaciones,
                  ),
                  _TarjetaAccion(
                    ancho: anchoTarjeta,
                    titulo: 'Mi Diagnóstico',
                    subtitulo: 'Refuerzo adaptativo',
                    icono: Icons.psychology_outlined,
                    colorFondo: const Color(0xFFEDE7F6),
                    colorIcono: Colors.deepPurple.shade700,
                    colorBorde: Colors.deepPurple.shade200,
                    onTap: onAbrirDiagnostico,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          // Botón ancho para Modo Offline
          InkWell(
            onTap: onAbrirMaterialesOffline,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueGrey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_done_outlined, color: Colors.blueGrey.shade700, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Materiales sin Conexión (Offline)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.blueGrey.shade900,
                          ),
                        ),
                        Text(
                          'Descarga contenidos para practicar sin internet',
                          style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade700),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blueGrey),
                ],
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
    required this.colorFondo,
    required this.colorIcono,
    required this.colorBorde,
    required this.onTap,
    this.badgeTexto,
  });

  final double ancho;
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Color colorFondo;
  final Color colorIcono;
  final Color colorBorde;
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorFondo,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorBorde, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorIcono.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icono, color: colorIcono, size: 22),
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
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.grey.shade900,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (badgeTexto != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: colorIcono,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              badgeTexto!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
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
