import 'package:flutter/material.dart';
import '../../dominio/modelos/reporte_pedagogico.dart';

/// Vista formal e institucional imprimible / exportable de un reporte pedagógico.
/// Prioriza visualmente las brechas críticas de aprendizaje y resalta la retroalimentación docente.
class VistaImprimibleReporte extends StatelessWidget {
  const VistaImprimibleReporte({
    super.key,
    required this.reporte,
    this.nombreColegio = 'COLEGIO BICENTENARIO SAN AGUSTÍN',
    this.nombreClase = 'Matemáticas 8° Básico A',
  });

  final ReporteEstudiante reporte;
  final String nombreColegio;
  final String nombreClase;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Vista Oficial del Reporte'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Preparando documento para impresión o exportación en PDF para ${reporte.alumnoNombre}...',
                  ),
                  backgroundColor: Colors.indigo,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.print_outlined, size: 18),
            label: const Text('Imprimir / PDF'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.indigo,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 820),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Membrete Institucional
                _construirMembrete(),
                const SizedBox(height: 24),
                const Divider(thickness: 1.5),
                const SizedBox(height: 18),

                // 2. Ficha del Estudiante y Resumen de Desempeño
                _construirFichaEstudiante(),
                const SizedBox(height: 24),

                // 3. Tabla Pedagógica Priorizada (Brechas Primero)
                _construirSeccionTemas(),
                const SizedBox(height: 28),

                // 4. Observaciones y Recomendaciones Pedagógicas del Docente
                _construirSeccionComentario(),
                const SizedBox(height: 40),

                // 5. Espacio de Firmas Formales
                _construirEspacioFirmas(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirMembrete() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.indigo.shade200),
          ),
          child: const Icon(Icons.school, size: 32, color: Colors.indigo),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombreColegio.toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'INFORME PEDAGÓGICO DE APRENDIZAJE Y DOMINIO TEMÁTICO',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Asignatura: $nombreClase • Período Oficial: ${reporte.periodo}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                'ID: ${reporte.id}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Emisión: ${_formatearFecha(reporte.fechaGeneracion)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _construirFichaEstudiante() {
    final enRiesgo = reporte.enRiesgoMultitematico;
    final tieneBrechas = reporte.totalTemasEnRiesgo > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ESTUDIANTE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.8),
                ),
                Text(
                  reporte.alumnoNombre,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  'Identificador: ${reporte.alumnoUid}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PROMEDIO PERÍODO',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.8),
                ),
                Row(
                  children: [
                    Text(
                      reporte.promedioGeneral.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${reporte.porcentajeGeneral.toStringAsFixed(0)}%)',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ESTADO PEDAGÓGICO',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.8),
                ),
                Row(
                  children: [
                    Icon(
                      enRiesgo
                          ? Icons.warning_amber_rounded
                          : (tieneBrechas ? Icons.info_outline : Icons.check_circle_outline),
                      size: 16,
                      color: enRiesgo
                          ? Colors.red.shade700
                          : (tieneBrechas ? Colors.amber.shade800 : Colors.green.shade700),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        enRiesgo
                            ? '${reporte.totalTemasEnRiesgo} brechas (Riesgo alto)'
                            : (tieneBrechas
                                ? '${reporte.totalTemasEnRiesgo} brecha a reforzar'
                                : 'Dominio consolidado'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: enRiesgo
                              ? Colors.red.shade700
                              : (tieneBrechas ? Colors.amber.shade900 : Colors.green.shade800),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirSeccionTemas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'DOMINIO POR TEMA / ESTÁNDAR CURRICULAR',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Colors.black87,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sort, size: 14, color: Colors.amber.shade900),
                  const SizedBox(width: 4),
                  Text(
                    'Priorizado: Brechas críticas primero (<60%)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Encabezado de la tabla
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50.withValues(alpha: 0.7),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: const Row(
            children: [
              Expanded(flex: 4, child: Text('Tema / Estándar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 3, child: Text('% Dominio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 2, child: Text('Nota Prom.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 3, child: Text('Nivel de Logro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 2, child: Text('Tendencia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            ],
          ),
        ),

        // Filas de temas
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
          ),
          child: Column(
            children: reporte.temasPriorizados.asMap().entries.map((entry) {
              final idx = entry.key;
              final tema = entry.value;
              final esUltimo = idx == reporte.temasPriorizados.length - 1;
              final esBrecha = tema.esBrechaCritica;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: esBrecha ? Colors.red.shade50.withValues(alpha: 0.3) : Colors.white,
                  border: esUltimo ? null : Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    // Nombre y aviso de brecha
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          if (esBrecha) ...[
                            Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              tema.tema,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: esBrecha ? FontWeight.bold : FontWeight.w600,
                                color: esBrecha ? Colors.red.shade900 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Barra de progreso y %
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (tema.porcentajeDominio / 100.0).clamp(0.0, 1.0),
                                minHeight: 7,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  tema.nivelDominio.color,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${tema.porcentajeDominio.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: tema.nivelDominio.color,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Nota promedio
                    Expanded(
                      flex: 2,
                      child: Text(
                        tema.promedioNota.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),

                    // Nivel de logro badge
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: tema.nivelDominio.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: tema.nivelDominio.color.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            tema.nivelDominio.etiqueta,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: tema.nivelDominio.color,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Tendencia inter-período
                    Expanded(
                      flex: 2,
                      child: Text(
                        tema.tendenciaInterPeriodo.etiqueta,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: tema.tendenciaInterPeriodo.color,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _construirSeccionComentario() {
    final comentario = reporte.comentarioDocente.trim().isNotEmpty
        ? reporte.comentarioDocente
        : 'Sin observaciones docentes registradas para este período.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rate_review_outlined, size: 18, color: Colors.indigo.shade800),
              const SizedBox(width: 8),
              const Text(
                'OBSERVACIONES Y RECOMENDACIONES PEDAGÓGICAS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comentario,
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirEspacioFirmas() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _firmaBloque('Profesor(a) de Asignatura'),
        _firmaBloque('Firma y Recepción del Apoderado'),
      ],
    );
  }

  Widget _firmaBloque(String titulo) {
    return Column(
      children: [
        Container(
          width: 220,
          height: 1,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 6),
        Text(
          titulo,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }
}
