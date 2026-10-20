import 'package:flutter/material.dart';
import '../../dominio/modelos/curriculo.dart';
import '../design/app_colors.dart';

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
      backgroundColor: AppColors.superficie(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.superficie(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borde(context)),
          boxShadow: AppColors.glowDetras(context),
        ),
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
                        color: AppColors.superficieSuave(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.account_tree_outlined, color: AppColors.claudeTerracota, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Currículo Escolar Formal',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.claudeTerracota),
                          ),
                          Text(
                            widget.plan.nombre,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textoPrincipal(context)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.textoSecundario(context)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Selecciona los objetivos curriculares que medirá esta evaluación. El sistema los vinculará directamente con el mapa de cobertura y triage de brechas:',
                  style: TextStyle(fontSize: 12, color: AppColors.textoSecundario(context)),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: AppColors.borde(context)),

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

                      return Container(
                        decoration: BoxDecoration(
                          color: seleccionadosEnUnidad > 0
                              ? AppColors.claudeTerracota.withValues(alpha: 0.08)
                              : AppColors.superficieSuave(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: seleccionadosEnUnidad > 0 ? AppColors.claudeTerracota.withValues(alpha: 0.4) : AppColors.borde(context),
                            width: seleccionadosEnUnidad > 0 ? 1.5 : 1.0,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ExpansionTile(
                            initiallyExpanded: index == 0 || seleccionadosEnUnidad > 0,
                            shape: const Border(),
                            collapsedShape: const Border(),
                            backgroundColor: Colors.transparent,
                            collapsedBackgroundColor: Colors.transparent,
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.superficie(context),
                              child: Text(
                                '${unidad.numero}',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.claudeTerracota),
                              ),
                            ),
                            title: Text(
                              unidad.nombre,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textoPrincipal(context)),
                            ),
                            subtitle: Text(
                              '${unidad.periodoSugerido} • $seleccionadosEnUnidad/${unidad.totalObjetivos} seleccionados',
                              style: TextStyle(fontSize: 11, color: AppColors.textoSecundario(context)),
                            ),
                            children: unidad.objetivos.map((obj) {
                              final estaSeleccionado = _seleccionadosIds.contains(obj.id);
                              return CheckboxListTile(
                                dense: true,
                                value: estaSeleccionado,
                                activeColor: AppColors.claudeTerracota,
                                checkColor: Colors.white,
                                controlAffinity: ListTileControlAffinity.leading,
                                title: Text(
                                  '${obj.codigo}: ${obj.nombre}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: estaSeleccionado ? FontWeight.bold : FontWeight.normal,
                                    color: estaSeleccionado ? AppColors.claudeTerracota : AppColors.textoPrincipal(context),
                                  ),
                                ),
                                subtitle: obj.descripcion.isNotEmpty
                                    ? Text(
                                        obj.descripcion,
                                        style: TextStyle(fontSize: 11, color: AppColors.textoSecundario(context)),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : null,
                                onChanged: (_) => _alternarObjetivo(obj.id),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Divider(height: 1, color: AppColors.borde(context)),
                const SizedBox(height: 12),

                // Botones inferiores
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_seleccionadosIds.length} objetivos marcados',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textoPrincipal(context)),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textoSecundario(context),
                          ),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _confirmar,
                          icon: const Icon(Icons.check, size: 16),
                          label: Text('Vincular a Evaluación (${_seleccionadosIds.length})'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.claudeTerracota,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      ),
    );
  }
}
