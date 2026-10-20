import 'package:flutter/material.dart';
import '../../datos/repositorio_reportes.dart';
import '../../dominio/analisis/generador_reportes.dart';
import '../../dominio/modelos/reporte_pedagogico.dart';
import '../design/app_colors.dart';

/// Diálogo modal para editar el comentario cualitativo del docente en un reporte escolar,
/// con asistencia del Asistente Pedagógico determinista para sugerir borradores estructurados.
class DialogoEditarReporte extends StatefulWidget {
  const DialogoEditarReporte({
    super.key,
    required this.reporte,
    required this.repositorioReportes,
    this.onReporteActualizado,
  });

  final ReporteEstudiante reporte;
  final RepositorioReportes repositorioReportes;
  final VoidCallback? onReporteActualizado;

  @override
  State<DialogoEditarReporte> createState() => _DialogoEditarReporteState();
}

class _DialogoEditarReporteState extends State<DialogoEditarReporte> {
  late final TextEditingController _comentarioController;
  bool _guardando = false;
  bool _mostrandoEspacioIa = false;

  @override
  void initState() {
    super.initState();
    _comentarioController = TextEditingController(text: widget.reporte.comentarioDocente);
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final reporteActualizado = widget.reporte.copyWith(
        comentarioDocente: _comentarioController.text.trim(),
      );
      await widget.repositorioReportes.guardarReporte(reporteActualizado);

      if (mounted) {
        widget.onReporteActualizado?.call();
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comentario pedagógico guardado con éxito.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _generarBorradorIa() {
    // Generador determinista de borrador estructurado (Asistente Pedagógico basado en reglas)
    const generador = GeneradorReportes();
    final borrador = generador.generarSugerenciaComentarioDocente(widget.reporte);

    setState(() {
      _comentarioController.text = borrador;
      _mostrandoEspacioIa = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Borrador del Asistente Pedagógico generado a partir del snapshot de temas.'),
        backgroundColor: Colors.indigo,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reporte = widget.reporte;
    final brecha = reporte.brechaPrincipal;
    final fortaleza = reporte.fortalezaPrincipal;

    return Dialog(
      backgroundColor: AppColors.superficie(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.superficie(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borde(context)),
          boxShadow: AppColors.glowDetras(context),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.superficieSuave(context),
                      child: Text(
                        reporte.alumnoNombre.isNotEmpty
                            ? reporte.alumnoNombre.substring(0, 1).toUpperCase()
                            : 'A',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.claudeTerracota,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reporte.alumnoNombre,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textoPrincipal(context),
                            ),
                          ),
                          Text(
                            'Período: ${reporte.periodo} • Promedio: ${reporte.promedioGeneral.toStringAsFixed(1)} (${reporte.porcentajeGeneral.toStringAsFixed(0)}%)',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textoSecundario(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: AppColors.textoSecundario(context)),
                      tooltip: 'Cerrar',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(height: 1, color: AppColors.borde(context)),
                const SizedBox(height: 14),

                // Mini resumen del snapshot pedagógico
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.superficieSuave(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borde(context)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red.shade400),
                                const SizedBox(width: 4),
                                Text(
                                  'Brecha prioritaria:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade400,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              brecha != null
                                  ? '${brecha.tema} (${brecha.porcentajeDominio}%)'
                                  : 'Sin brechas críticas',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textoPrincipal(context)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(height: 30, width: 1, color: AppColors.borde(context)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle_outline, size: 16, color: Colors.green.shade400),
                                const SizedBox(width: 4),
                                Text(
                                  'Mayor fortaleza:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade400,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              fortaleza != null
                                  ? '${fortaleza.tema} (${fortaleza.porcentajeDominio}%)'
                                  : 'No registrada',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textoPrincipal(context)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Botón del Asistente Pedagógico (generación determinista / preparado para LLM)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Observación Pedagógica del Docente',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textoPrincipal(context),
                      ),
                    ),
                    Tooltip(
                      message:
                          'Asistente pedagógico determinista: analiza brechas y fortalezas curriculares sin latencia ni dependencias externas',
                      child: OutlinedButton.icon(
                        onPressed: _generarBorradorIa,
                        icon: Icon(Icons.auto_awesome, size: 16, color: AppColors.claudeTerracota),
                        label: Text(
                          'Sugerir borrador (Asistente Pedagógico)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.claudeTerracota),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.claudeTerracota,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          side: BorderSide(color: AppColors.claudeTerracota.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),

                if (_mostrandoEspacioIa) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.superficieSuave(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borde(context)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: AppColors.claudeTerracota),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Asistente pedagógico determinista: borrador sintetizado a partir del snapshot curricular. Totalmente editable por el docente.',
                            style: TextStyle(fontSize: 11, color: AppColors.claudeTerracota),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // Área de texto editable
                Expanded(
                  child: TextFormField(
                    controller: _comentarioController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: TextStyle(color: AppColors.textoPrincipal(context), fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.superficieSuave(context),
                      hintText:
                          'Escribe la retroalimentación pedagógica para el estudiante y sus apoderados...',
                      hintStyle: TextStyle(color: AppColors.textoSecundario(context).withValues(alpha: 0.6), fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.borde(context)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.borde(context)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.claudeTerracota, width: 1.8),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Barra de acciones inferiores
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _guardando ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textoSecundario(context),
                      ),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: _guardando ? null : _guardar,
                      icon: _guardando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: Text(_guardando ? 'Guardando...' : 'Guardar Comentario'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.claudeTerracota,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
