import 'package:flutter/material.dart';
import '../../datos/repositorio_reportes.dart';
import '../../dominio/analisis/generador_reportes.dart';
import '../../dominio/modelos/reporte_pedagogico.dart';

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    backgroundColor: Colors.indigo.shade50,
                    child: Text(
                      reporte.alumnoNombre.isNotEmpty
                          ? reporte.alumnoNombre.substring(0, 1).toUpperCase()
                          : 'A',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade800,
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Período: ${reporte.periodo} • Promedio: ${reporte.promedioGeneral.toStringAsFixed(1)} (${reporte.porcentajeGeneral.toStringAsFixed(0)}%)',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Cerrar',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Mini resumen del snapshot pedagógico
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red.shade700),
                              const SizedBox(width: 4),
                              Text(
                                'Brecha prioritaria:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            brecha != null
                                ? '${brecha.tema} (${brecha.porcentajeDominio}%)'
                                : 'Sin brechas críticas',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(height: 30, width: 1, color: Colors.grey.shade300),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle_outline, size: 16, color: Colors.green.shade700),
                              const SizedBox(width: 4),
                              Text(
                                'Mayor fortaleza:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            fortaleza != null
                                ? '${fortaleza.tema} (${fortaleza.porcentajeDominio}%)'
                                : 'No registrada',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
                  const Text(
                    'Observación Pedagógica del Docente',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Tooltip(
                    message:
                        'Asistente pedagógico determinista: analiza brechas y fortalezas curriculares sin latencia ni dependencias externas',
                    child: OutlinedButton.icon(
                      onPressed: _generarBorradorIa,
                      icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.indigo),
                      label: const Text(
                        'Sugerir borrador (Asistente Pedagógico)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        side: BorderSide(color: Colors.indigo.shade200),
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
                    color: Colors.indigo.shade50.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.indigo.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: Colors.indigo.shade700),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Asistente pedagógico determinista: borrador sintetizado a partir del snapshot curricular. Totalmente editable por el docente.',
                          style: TextStyle(fontSize: 11, color: Colors.indigo.shade900),
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
                  decoration: InputDecoration(
                    hintText:
                        'Escribe la retroalimentación pedagógica para el estudiante y sus apoderados...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.indigo, width: 1.8),
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
                      backgroundColor: Colors.indigo,
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
    );
  }
}
