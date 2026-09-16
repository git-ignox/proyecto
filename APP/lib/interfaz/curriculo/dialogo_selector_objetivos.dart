import 'package:flutter/material.dart';
import '../../dominio/modelos/curriculo.dart';

/// Modal selector de objetivos y estándares curriculares agrupados por unidad.
class DialogoSelectorObjetivos extends StatefulWidget {
  const DialogoSelectorObjetivos({
    super.key,
    required this.plan,
    this.seleccionadosIniciales = const [],
  });

  final PlanCurricular plan;
  final List<String> seleccionadosIniciales;

  @override
  State<DialogoSelectorObjetivos> createState() => _DialogoSelectorObjetivosState();
}

class _DialogoSelectorObjetivosState extends State<DialogoSelectorObjetivos> {
  late final Set<String> _seleccionadosIds;

  @override
  void initState() {
    super.initState();
    _seleccionadosIds = widget.seleccionadosIniciales.toSet();
  }

  void _alternarObjetivo(String id) {
    setState(() {
      if (_seleccionadosIds.contains(id)) {
        _seleccionadosIds.remove(id);
      } else {
        _seleccionadosIds.add(id);
      }
    });
  }

  void _confirmar() {
    final todos = widget.plan.todosLosObjetivos;
    final seleccionados = todos.where((o) => _seleccionadosIds.contains(o.id)).toList();
    Navigator.of(context).pop(seleccionados);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_tree_outlined, color: Colors.indigo, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Currículo Escolar Formal',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo),
                        ),
                        Text(
                          widget.plan.nombre,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Selecciona los objetivos curriculares que medirá esta evaluación. El sistema los vinculará directamente con el mapa de cobertura y triage de brechas:',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),

              // Lista de unidades con acordeón
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: widget.plan.unidades.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, index) {
                    final unidad = widget.plan.unidades[index];
                    final seleccionadosEnUnidad =
                        unidad.objetivos.where((o) => _seleccionadosIds.contains(o.id)).length;

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: seleccionadosEnUnidad > 0 ? Colors.indigo.shade300 : Colors.grey.shade200,
                          width: seleccionadosEnUnidad > 0 ? 1.5 : 1.0,
                        ),
                      ),
                      color: seleccionadosEnUnidad > 0 ? Colors.indigo.shade50.withValues(alpha: 0.3) : Colors.white,
                      child: ExpansionTile(
                        initiallyExpanded: index == 0 || seleccionadosEnUnidad > 0,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.indigo.shade100,
                          child: Text(
                            '${unidad.numero}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo),
                          ),
                        ),
                        title: Text(
                          unidad.nombre,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${unidad.periodoSugerido} • $seleccionadosEnUnidad/${unidad.totalObjetivos} seleccionados',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                        children: unidad.objetivos.map((obj) {
                          final estaSeleccionado = _seleccionadosIds.contains(obj.id);
                          return CheckboxListTile(
                            dense: true,
                            value: estaSeleccionado,
                            activeColor: Colors.indigo,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                              '${obj.codigo}: ${obj.nombre}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: estaSeleccionado ? FontWeight.bold : FontWeight.normal,
                                color: estaSeleccionado ? Colors.indigo.shade900 : Colors.black87,
                              ),
                            ),
                            subtitle: obj.descripcion.isNotEmpty
                                ? Text(
                                    obj.descripcion,
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            onChanged: (_) => _alternarObjetivo(obj.id),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),

              const Divider(height: 1),
              const SizedBox(height: 12),

              // Botones inferiores
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_seleccionadosIds.length} objetivos marcados',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _confirmar,
                        icon: const Icon(Icons.check, size: 16),
                        label: Text('Vincular a Evaluación (${_seleccionadosIds.length})'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
  }
}
