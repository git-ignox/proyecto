import 'package:flutter/material.dart';
import '../../datos/coordinador_sincronizacion_offline.dart';
import '../../dominio/modelos/recurso_educativo_offline.dart';

/// Modal interactivo para visualizar y gestionar los materiales offline,
/// marcar archivos intocables (fijados), simular condiciones de red y
/// ejecutar limpieza segura de almacenamiento.
class HojaGestionMaterialesOffline extends StatefulWidget {
  const HojaGestionMaterialesOffline({
    super.key,
    required this.coordinador,
  });

  final CoordinadorSincronizacionOffline coordinador;

  @override
  State<HojaGestionMaterialesOffline> createState() =>
      _HojaGestionMaterialesOfflineState();
}

class _HojaGestionMaterialesOfflineState
    extends State<HojaGestionMaterialesOffline>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _ejecutandoLimpieza = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Barra superior de arrastre
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Cabecera con título y estado
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.offline_pin_rounded,
                        color: Colors.indigo, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Materiales sin conexión',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Sincronización automática y protección local',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Pestañas
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.indigo,
                labelColor: Colors.indigo,
                unselectedLabelColor: Colors.grey[600],
                tabs: const [
                  Tab(
                    icon: Icon(Icons.menu_book_rounded, size: 18),
                    text: 'Material de la Semana',
                  ),
                  Tab(
                    icon: Icon(Icons.storage_rounded, size: 18),
                    text: 'Espacio y Red',
                  ),
                ],
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _construirListaMateriales(scrollController),
                    _construirGestionEspacioYRed(scrollController),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _construirListaMateriales(ScrollController scrollController) {
    return StreamBuilder<List<RecursoEducativoOffline>>(
      stream: widget.coordinador.repositorio.materialesStream(),
      builder: (context, snapshot) {
        final materiales = snapshot.data ?? [];
        if (materiales.isEmpty) {
          return const Center(
            child: Text('No hay materiales educativos registrados.'),
          );
        }

        return StreamBuilder<Map<String, TareaSincronizacion>>(
          stream: widget.coordinador.repositorio.tareasStream(),
          builder: (context, tareasSnapshot) {
            final tareas = tareasSnapshot.data ?? {};

            return ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: materiales.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final material = materiales[index];
                final tarea = tareas[material.id];
                return _construirItemMaterial(material, tarea);
              },
            );
          },
        );
      },
    );
  }

  Widget _construirItemMaterial(
    RecursoEducativoOffline material,
    TareaSincronizacion? tarea,
  ) {
    final estaListo = material.estaDescargado;
    final esDescargando =
        tarea?.estado == EstadoSincronizacion.descargando;
    final progreso = tarea?.progreso ?? 0.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: estaListo ? Colors.green.shade200 : Colors.grey.shade300,
        ),
      ),
      color: estaListo ? Colors.green.shade50.withValues(alpha: 0.4) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _obtenerIconoTipo(material.tipoRecurso),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              material.titulo,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (material.esObligatorio)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.indigo.shade200),
                              ),
                              child: const Text(
                                'Obligatorio',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.indigo,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${material.materia} • Clase: ${_formatearFecha(material.fechaUsoClase)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tamaño: ${material.tamanoLegible}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                // Botón de Fijar / Marcar Intocable
                IconButton(
                  tooltip: material.esFijado
                      ? 'Archivo intocable (protegido contra limpieza)'
                      : 'Fijar archivo para que nunca sea eliminado',
                  icon: Icon(
                    material.esFijado
                        ? Icons.push_pin_rounded
                        : Icons.push_pin_outlined,
                    color: material.esFijado ? Colors.amber[800] : Colors.grey,
                  ),
                  onPressed: () {
                    widget.coordinador.repositorio.fijarMaterial(
                      material.id,
                      !material.esFijado,
                    );
                  },
                ),
              ],
            ),
            if (esDescargando) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progreso,
                  minHeight: 6,
                  backgroundColor: Colors.indigo.shade50,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.indigo),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Descargando en segundo plano... ${(progreso * 100).round()}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.indigo.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${(tarea!.bytesDescargados / (1024 * 1024)).toStringAsFixed(1)} / ${material.tamanoLegible}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ] else if (estaListo) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Listo para abrir sin internet',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      widget.coordinador.repositorio
                          .registrarVisualizacion(material.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Abriendo "${material.titulo}" localmente...'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 14),
                    label: const Text('Abrir'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ] else if (tarea?.estado == EstadoSincronizacion.pausado) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.pause_circle_outline_rounded,
                      size: 14, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    'En pausa (${_describirCausa(tarea!.causaPausa)})',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _construirGestionEspacioYRed(ScrollController scrollController) {
    final condiciones = widget.coordinador.condiciones;

    return StreamBuilder<List<RecursoEducativoOffline>>(
      stream: widget.coordinador.repositorio.materialesStream(),
      builder: (context, snapshot) {
        final materiales = snapshot.data ?? [];
        final descargados = materiales.where((m) => m.estaDescargado).toList();
        final bytesLocales =
            descargados.fold<int>(0, (acc, m) => acc + m.tamanoBytes);
        final mbLocales = (bytesLocales / (1024 * 1024)).toStringAsFixed(1);

        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            // Sección de Hardware y Red
            Text(
              'Control de Red y Batería',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'El sistema descarga automáticamente solo cuando no consume datos móviles y hay batería suficiente.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    SwitchListTile(
                      dense: true,
                      title: const Text('Conexión WiFi disponible'),
                      subtitle: Text(
                        condiciones.hayWifi
                            ? 'WiFi activo: descargas permitidas'
                            : 'Sin WiFi: descargas automáticas pausadas',
                      ),
                      value: condiciones.hayWifi,
                      onChanged: (val) {
                        setState(() {
                          widget.coordinador.actualizarCondicionesDispositivo(
                            CondicionesDispositivo(
                              hayWifi: val,
                              bateriaPorcentaje: condiciones.bateriaPorcentaje,
                              estaCargando: condiciones.estaCargando,
                            ),
                          );
                        });
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.battery_charging_full_rounded),
                      title: Text('Batería: ${condiciones.bateriaPorcentaje}%'),
                      subtitle: Text(
                        condiciones.bateriaSuficiente
                            ? 'Nivel óptimo para sincronización en background'
                            : 'Nivel bajo: se posponen descargas pesadas',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Sección de Almacenamiento
            Text(
              'Almacenamiento Local de la App',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Espacio actualmente ocupado por materiales educativos: $mbLocales MB (${descargados.length} archivos).',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // Reglas de protección visible
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_rounded,
                      color: Colors.amber.shade900, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Protección Activa de Limpieza Segura',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.amber.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '• Nunca se borra material sin conexión a internet.\n'
                          '• Nunca se borra contenido de las próximas 24-48h.\n'
                          '• Los archivos fijados (📌) son intocables.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Botón de Limpieza Segura Asistida
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _ejecutandoLimpieza ? null : () => _iniciarLimpiezaSegura(materiales),
              icon: _ejecutandoLimpieza
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cleaning_services_rounded),
              label: Text(
                _ejecutandoLimpieza
                    ? 'Evaluando espacio...'
                    : 'Liberar espacio de forma segura',
              ),
            ),

            const SizedBox(height: 12),

            // Botón para sincronizar manualmente
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                await widget.coordinador.procesarColaDescargas();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Comprobación de sincronización ejecutada.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.sync_rounded),
              label: const Text('Comprobar descargas pendientes ahora'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _iniciarLimpiezaSegura(
    List<RecursoEducativoOffline> materiales,
  ) async {
    setState(() => _ejecutandoLimpieza = true);

    try {
      final hayInternet = widget.coordinador.condiciones.hayWifi;
      final analisis = widget.coordinador.gestorLimpieza.evaluarCandidatos(
        recursos: materiales,
        hayInternet: hayInternet,
      );

      if (!analisis.hayInternet) {
        if (!mounted) return;
        _mostrarAlerta(
          titulo: 'Limpieza No Permitida',
          mensaje:
              'La limpieza automática de espacio solo puede ejecutarse cuando hay conexión a internet para evitar que te quedes sin material.',
          icono: Icons.wifi_off_rounded,
          colorIcono: Colors.red,
        );
        return;
      }

      if (analisis.candidatos.isEmpty) {
        if (!mounted) return;
        _mostrarAlerta(
          titulo: 'Almacenamiento Óptimo',
          mensaje:
              'No hay archivos antiguos ni material caducado para desalojar. Todo tu contenido actual corresponde a clases vigentes o está protegido.',
          icono: Icons.check_circle_outline_rounded,
          colorIcono: Colors.green,
        );
        return;
      }

      // Si la liberación es significativa, pedir confirmación previa explícita
      if (analisis.esLiberacionSignificativa) {
        if (!mounted) return;
        final confirmar = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(child: Text('Aviso de Liberación de Espacio')),
              ],
            ),
            content: Text(
              '${analisis.mensajeAlerta}\n\n'
              'Se eliminarán ${analisis.candidatos.length} archivos antiguos ya vistos para recuperar ${analisis.mbALiberarLegible}.\n\n'
              '¿Deseas continuar con la limpieza segura?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Liberar Espacio'),
              ),
            ],
          ),
        );

        if (confirmar != true) {
          return;
        }
      }

      // Ejecutar la purga con confirmación
      final resultado = await widget.coordinador.solicitarLimpiezaSegura(
        hayInternet: hayInternet,
        confirmadoPorUsuario: true,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado.mensaje),
          backgroundColor: Colors.green[800],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _ejecutandoLimpieza = false);
      }
    }
  }

  void _mostrarAlerta({
    required String titulo,
    required String mensaje,
    required IconData icono,
    required Color colorIcono,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(icono, color: colorIcono),
            const SizedBox(width: 8),
            Expanded(child: Text(titulo)),
          ],
        ),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _obtenerIconoTipo(TipoRecursoEducativo tipo) {
    final IconData icono;
    final Color color;

    switch (tipo) {
      case TipoRecursoEducativo.pdf:
        icono = Icons.picture_as_pdf_rounded;
        color = Colors.red.shade700;
        break;
      case TipoRecursoEducativo.paginaWebMhtml:
        icono = Icons.web_rounded;
        color = Colors.blue.shade700;
        break;
      case TipoRecursoEducativo.documento:
        icono = Icons.description_rounded;
        color = Colors.indigo.shade700;
        break;
      case TipoRecursoEducativo.imagen:
        icono = Icons.image_rounded;
        color = Colors.teal.shade700;
        break;
      case TipoRecursoEducativo.video:
        icono = Icons.video_library_rounded;
        color = Colors.deepOrange.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icono, color: color, size: 22),
    );
  }

  String _describirCausa(CausaPausa causa) {
    switch (causa) {
      case CausaPausa.sinWifi:
        return 'esperando WiFi';
      case CausaPausa.bateriaBaja:
        return 'esperando batería';
      case CausaPausa.dispositivoActivo:
        return 'dispositivo en uso';
      case CausaPausa.sinEspacio:
        return 'almacenamiento insuficiente';
      case CausaPausa.pausaManual:
        return 'pausado';
      case CausaPausa.ninguna:
        return 'en espera';
    }
  }

  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diferenciaDias = fecha.difference(ahora).inDays;

    if (diferenciaDias == 0) {
      return 'Hoy (${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')})';
    } else if (diferenciaDias == 1) {
      return 'Mañana (${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')})';
    } else if (diferenciaDias > 1 && diferenciaDias < 7) {
      const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      return '${dias[fecha.weekday - 1]} ${fecha.day}/${fecha.month}';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }
}
