import 'package:flutter/material.dart';
import '../../dominio/modelos/diagnostico_alumno.dart';
import '../design/app_colors.dart';

/// Tarjeta de resumen de rendimiento y salud académica del alumno,
/// mostrando precisión, total de retos resueltos y acceso inmediato a refuerzo.
class WidgetResumenMetricasAlumno extends StatelessWidget {
  const WidgetResumenMetricasAlumno({
    super.key,
    required this.diagnostico,
    required this.onVerDetalles,
    required this.onPracticarRefuerzo,
  });

  final DiagnosticoAlumno diagnostico;
  final VoidCallback onVerDetalles;
  final void Function(List<String> tagsCriticos) onPracticarRefuerzo;

  @override
  Widget build(BuildContext context) {
    final tieneErrores = diagnostico.tagsCriticos.isNotEmpty || diagnostico.erroresProminentes.isNotEmpty;
    final precision = diagnostico.porcentajePrecision;
    final colorPrecision = precision >= 75
        ? Colors.teal
        : (precision >= 50 ? Colors.orange : Colors.red);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.superficie(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde(context), width: 1.2),
        boxShadow: AppColors.glowDetras(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.insights, color: AppColors.claudeTerracota, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Mi Rendimiento Pedagógico',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textoPrincipal(context),
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: onVerDetalles,
                icon: const Icon(Icons.arrow_forward, size: 14),
                label: const Text('Ver Todo', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.claudeTerracota,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Precisión
              Expanded(
                child: _MetricaItem(
                  valor: '${precision.toStringAsFixed(0)}%',
                  etiqueta: 'Precisión',
                  color: colorPrecision,
                  icono: Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 8),
              // Intentos
              Expanded(
                child: _MetricaItem(
                  valor: '${diagnostico.totalIntentos}',
                  etiqueta: 'Ejercicios',
                  color: AppColors.claudeTerracota,
                  icono: Icons.fitness_center_outlined,
                ),
              ),
              const SizedBox(width: 8),
              // Aciertos
              Expanded(
                child: _MetricaItem(
                  valor: '${diagnostico.aciertos}',
                  etiqueta: 'Aciertos',
                  color: Colors.green.shade400,
                  icono: Icons.star_border,
                ),
              ),
            ],
          ),
          if (tieneErrores) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.esOscuro(context) ? const Color(0xFF2E2214) : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withValues(alpha: AppColors.esOscuro(context) ? 0.35 : 0.4)),
                boxShadow: AppColors.glowDetras(context, color: Colors.amber, intensidad: 0.12),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.amber.shade400, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tienes áreas de oportunidad detectadas: ${diagnostico.tagsCriticos.take(2).join(", ")}',
                      style: TextStyle(fontSize: 12, color: Colors.amber.shade300, fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => onPracticarRefuerzo(diagnostico.tagsCriticos),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.claudeTerracota,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    child: const Text('Reforzar', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricaItem extends StatelessWidget {
  const _MetricaItem({
    required this.valor,
    required this.etiqueta,
    required this.color,
    required this.icono,
  });

  final String valor;
  final String etiqueta;
  final Color color;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icono, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            etiqueta,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textoSecundario(context),
            ),
          ),
        ],
      ),
    );
  }
}
