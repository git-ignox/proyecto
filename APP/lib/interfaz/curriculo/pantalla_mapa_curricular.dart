import 'package:flutter/material.dart';
import '../../datos/repositorio_curriculo.dart';
import '../../datos/repositorio_evaluaciones.dart';
import '../../dominio/analisis/analizador_cobertura_curricular.dart';
import '../../dominio/modelos/clase_escolar.dart';
import '../../dominio/modelos/cobertura_curricular.dart';
import '../../dominio/modelos/curriculo.dart';
import '../evaluaciones/pantalla_evaluaciones_docente.dart';

/// Pantalla interactiva del Mapa Curricular y Triage de Cobertura de la Clase.
/// Distingue entre Brechas de Aprendizaje (<60%) y Brechas de Enseñanza (sin evaluar).
class PantallaMapaCurricular extends StatefulWidget {
  const PantallaMapaCurricular({
    super.key,
    required this.clase,
    required this.repositorioCurriculo,
    required this.repositorioEvaluaciones,
    this.analizador = const AnalizadorCoberturaCurricular(),
  });

  final ClaseEscolar clase;
  final RepositorioCurriculo repositorioCurriculo;
  final RepositorioEvaluaciones repositorioEvaluaciones;
  final AnalizadorCoberturaCurricular analizador;

  @override
  State<PantallaMapaCurricular> createState() => _PantallaMapaCurricularState();
}

class _PantallaMapaCurricularState extends State<PantallaMapaCurricular> {
  bool _cargando = true;
  PlanCurricular? _plan;
  MapaCoberturaCurricular? _mapa;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);

    // 1. Obtener el plan curricular asignado a la clase
    PlanCurricular? plan = await widget.repositorioCurriculo.obtenerPlanDeClase(widget.clase.id);
    if (plan == null && widget.clase.planCurricularId != null) {
      plan = await widget.repositorioCurriculo.obtenerPlanPorId(widget.clase.planCurricularId!);
    }

    // 2. Obtener evaluaciones y notas de la clase
    final evals = await widget.repositorioEvaluaciones.obtenerEvaluacionesPorClase(widget.clase.id);
    final notas = await widget.repositorioEvaluaciones.obtenerNotasPorClase(widget.clase.id);

    MapaCoberturaCurricular? mapa;
    if (plan != null) {
      mapa = widget.analizador.analizarCobertura(
        plan: plan,
        evaluaciones: evals,
        notas: notas,
        claseId: widget.clase.id,
      );
    }

    setState(() {
      _plan = plan;
      _mapa = mapa;
      _cargando = false;
    });
  }

  Future<void> _asignarCurriculoOficialDemo() async {
    setState(() => _cargando = true);
    // Asignar el plan sembrado 'plan-mat-8vo'
    await widget.repositorioCurriculo.asignarPlanAClase(widget.clase.id, 'plan-mat-8vo');
    await _cargarDatos();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Currículo oficial de Matemática 8vo Básico asignado con éxito!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _planificarEvaluacionParaObjetivo(ObjetivoAprendizaje obj) async {
    // Deep-link: navegar a PantallaEvaluacionesDocente preseleccionando este objetivo
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaEvaluacionesDocente(
          clase: widget.clase,
          repositorioEvaluaciones: widget.repositorioEvaluaciones,
          repositorioCurriculo: widget.repositorioCurriculo,
          objetivoPreseleccionado: obj,
        ),
      ),
    );
    // Al regresar, refrescar el mapa para ver la actualización del estado
    _cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa Curricular • ${widget.clase.nombre}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar mapa',
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _plan == null
              ? _construirEstadoVacioSinPlan()
              : _construirContenidoMapa(),
    );
  }

  /// Estado Vacío explícito para clases sin currículo asignado
  Widget _construirEstadoVacioSinPlan() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_tree_outlined, size: 64, color: Colors.indigo),
              ),
              const SizedBox(height: 24),
              const Text(
                'Sin Currículo Oficial Asignado',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'A diferencia de Google Classroom (que solo admite etiquetas de texto libre), este sistema estructura tus materias en unidades y objetivos estandarizados para auditar la cobertura pedagógica real.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _asignarCurriculoOficialDemo,
                icon: const Icon(Icons.assignment_add),
                label: const Text('Asignar Currículo Oficial (Matemática 8vo Básico)'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirContenidoMapa() {
    final mapa = _mapa!;
    final plan = _plan!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Tarjeta de Encabezado del Plan
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.schema_outlined, color: Colors.indigo, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  plan.nivelGrado,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo.shade900),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${plan.unidades.length} Unidades • ${plan.totalObjetivos} Objetivos',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            plan.nombre,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Barra de Cobertura Global
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cobertura de Enseñanza Global:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${mapa.porcentajeCoberturaGlobal}% (${mapa.totalObjetivosEvaluados}/${mapa.totalObjetivosCurriculo} evaluados)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.indigo.shade800),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: mapa.totalObjetivosCurriculo > 0
                        ? (mapa.totalObjetivosEvaluados / mapa.totalObjetivosCurriculo).clamp(0.0, 1.0)
                        : 0.0,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // 2. Tarjetas KPI de Triage Curricular
        Row(
          children: [
            // Brechas de Enseñanza (Naranja)
            Expanded(
              child: Card(
                elevation: 1,
                color: Colors.orange.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.orange.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.hourglass_empty_rounded, size: 16, color: Colors.orange.shade900),
                          const SizedBox(width: 6),
                          Text(
                            'Brechas Enseñanza',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${mapa.brechasEnsenanza.length}',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                      ),
                      Text(
                        'Objetivos sin evaluar',
                        style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Brechas de Aprendizaje (Rojo)
            Expanded(
              child: Card(
                elevation: 1,
                color: Colors.red.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.red.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red.shade900),
                          const SizedBox(width: 6),
                          Text(
                            'Brechas Aprendizaje',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${mapa.brechasAprendizaje.length}',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                      ),
                      Text(
                        'Evaluados con <60%',
                        style: TextStyle(fontSize: 11, color: Colors.red.shade800),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Dominio Promedio (Verde / Teal)
            Expanded(
              child: Card(
                elevation: 1,
                color: Colors.teal.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.teal.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle_outline, size: 16, color: Colors.teal.shade900),
                          const SizedBox(width: 6),
                          Text(
                            'Logro en lo Evaluado',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        mapa.promedioDominioGlobal != null ? '${mapa.promedioDominioGlobal}%' : 'N/A',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                      ),
                      Text(
                        'Promedio de notas',
                        style: TextStyle(fontSize: 11, color: Colors.teal.shade800),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Barra explicativa de leyenda para el jurado
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _construirItemLeyenda(Colors.green.shade700, '🟢 Consolidado (≥60%)'),
              _construirItemLeyenda(Colors.red.shade700, '🔴 Brecha Aprendizaje (<60%)'),
              _construirItemLeyenda(Colors.orange.shade800, '🟠 Brecha Enseñanza (0 evals)'),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 3. Desglose jerárquico por Unidades
        ...mapa.unidades.map((u) => _construirTarjetaUnidad(u)),
      ],
    );
  }

  Widget _construirItemLeyenda(Color color, String etiqueta) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(etiqueta, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _construirTarjetaUnidad(AnalisisUnidadCurricular unidadAnalizada) {
    final u = unidadAnalizada.unidad;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade50,
          child: Text(
            '${u.numero}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
        ),
        title: Text(
          u.nombre,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Text('${u.periodoSugerido} • ', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text(
                '${unidadAnalizada.porcentajeCobertura}% cobertura',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: unidadAnalizada.porcentajeCobertura == 100.0 ? Colors.green.shade800 : Colors.indigo.shade800,
                ),
              ),
              if (unidadAnalizada.promedioDominio != null) ...[
                Text(' • Logro: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Text(
                  '${unidadAnalizada.promedioDominio}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: unidadAnalizada.promedioDominio! >= 60 ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
              ],
            ],
          ),
        ),
        children: [
          const Divider(height: 1),
          ...unidadAnalizada.objetivosAnalizados.map((objAnalizado) {
            final obj = objAnalizado.objetivo;
            final estado = objAnalizado.estado;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ícono de estado
                  Icon(estado.icono, color: estado.color, size: 22),
                  const SizedBox(width: 12),

                  // Información del objetivo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: estado.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                obj.codigo,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: estado.color),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                obj.nombre,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        if (obj.descripcion.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            obj.descripcion,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 6),

                        // Diagnóstico & Evaluaciones vinculadas
                        if (objAnalizado.esBrechaEnsenanza)
                          Row(
                            children: [
                              Text(
                                'Sin evaluaciones aplicadas en el período',
                                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.orange.shade900),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Text(
                                '${objAnalizado.cantidadEvaluaciones} eval(s) • Promedio: ${objAnalizado.promedioNota ?? 0} (${objAnalizado.rendimientoPromedio ?? 0}%)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: objAnalizado.esBrechaAprendizaje ? Colors.red.shade800 : Colors.green.shade800,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // Botón de acción directa (Deep-link) cuando es Brecha de Enseñanza
                  if (objAnalizado.esBrechaEnsenanza)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: OutlinedButton.icon(
                        onPressed: () => _planificarEvaluacionParaObjetivo(obj),
                        icon: const Icon(Icons.add_task, size: 14),
                        label: const Text('Planificar', style: TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange.shade900,
                          side: BorderSide(color: Colors.orange.shade300),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
