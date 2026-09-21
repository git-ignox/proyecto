import 'package:flutter/material.dart';
import '../../datos/coordinador_sincronizacion_offline.dart';
import '../../dominio/modelos/recurso_educativo_offline.dart';
import 'hoja_gestion_materiales_offline.dart';

/// Tarjeta principal de disponibilidad offline para la pantalla del alumno.
/// Muestra de forma simple y no técnica el porcentaje del material de la semana
/// que ya está listo para ser utilizado sin internet.
class WidgetTarjetaDisponibilidadOffline extends StatelessWidget {
  const WidgetTarjetaDisponibilidadOffline({
    super.key,
    required this.coordinador,
    this.alPresionarVerDetalles,
  });

  final CoordinadorSincronizacionOffline coordinador;
  final VoidCallback? alPresionarVerDetalles;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MetricaPreparacionSemana>(
      future: coordinador.obtenerMetricaSemanal(),
      builder: (context, snapshot) {
        return StreamBuilder<MetricaPreparacionSemana>(
          stream: coordinador.metricaStream,
          initialData: snapshot.data,
          builder: (context, metricaSnapshot) {
            final metrica = metricaSnapshot.data;
            if (metrica == null) {
              return const SizedBox.shrink();
            }

            final porcentaje = metrica.porcentajeListo;
            final colorTema = _obtenerColorPorcentaje(porcentaje);
            final condiciones = coordinador.condiciones;

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorTema.withValues(alpha: 0.3)),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (alPresionarVerDetalles != null) {
                    alPresionarVerDetalles!();
                  } else {
                    _abrirDetalle(context);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorTema.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              porcentaje >= 90
                                  ? Icons.offline_pin_rounded
                                  : Icons.cloud_sync_rounded,
                              color: colorTema,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Disponibilidad sin conexión',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  metrica.mensajeResumen,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (porcentaje / 100.0).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(colorTema),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${metrica.materialesListos} de ${metrica.totalMaterialesSemana} archivos listos',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                          Row(
                            children: [
                              Icon(
                                condiciones.hayWifi
                                    ? Icons.wifi_rounded
                                    : Icons.wifi_off_rounded,
                                size: 14,
                                color: condiciones.hayWifi
                                    ? Colors.green[700]
                                    : Colors.orange[800],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                condiciones.hayWifi
                                    ? 'WiFi activo'
                                    : 'Pausado (esperando WiFi)',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: condiciones.hayWifi
                                          ? Colors.green[800]
                                          : Colors.orange[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _abrirDetalle(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HojaGestionMaterialesOffline(
        coordinador: coordinador,
      ),
    );
  }

  Color _obtenerColorPorcentaje(int porcentaje) {
    if (porcentaje >= 90) return Colors.green[700]!;
    if (porcentaje >= 60) return Colors.orange[700]!;
    return Colors.red[700]!;
  }
}
