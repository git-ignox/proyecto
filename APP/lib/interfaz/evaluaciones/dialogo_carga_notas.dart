import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../datos/repositorio_evaluaciones.dart';
import '../../dominio/modelos/clase_escolar.dart';
import '../../dominio/modelos/evaluacion.dart';

/// Modal para carga individual, masiva por CSV y edición de notas de una evaluación.
class DialogoCargaNotas extends StatefulWidget {
  const DialogoCargaNotas({
    super.key,
    required this.evaluacion,
    required this.clase,
    required this.repositorioEvaluaciones,
    required this.notasActuales,
    required this.onNotasActualizadas,
  });

  final Evaluacion evaluacion;
  final ClaseEscolar clase;
  final RepositorioEvaluaciones repositorioEvaluaciones;
  final List<NotaEvaluacion> notasActuales;
  final VoidCallback onNotasActualizadas;

  @override
  State<DialogoCargaNotas> createState() => _DialogoCargaNotasState();
}

class _DialogoCargaNotasState extends State<DialogoCargaNotas> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Estado para Carga Individual
  String? _alumnoSeleccionadoUid;
  final TextEditingController _controladorNotaIndividual = TextEditingController();
  final TextEditingController _controladorObsIndividual = TextEditingController();
  final Map<String, TextEditingController> _controladoresTemasIndividual = {};
  bool _guardandoIndividual = false;

  // Estado para Carga Masiva CSV
  final TextEditingController _controladorCsv = TextEditingController();
  List<_FilaCsvPrevia> _filasParseadas = [];
  String? _errorCsv;
  bool _guardandoCsv = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    for (final tema in widget.evaluacion.temas) {
      _controladoresTemasIndividual[tema] = TextEditingController();
    }

    if (widget.clase.alumnosUids.isNotEmpty) {
      _alumnoSeleccionadoUid = widget.clase.alumnosUids.first;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controladorNotaIndividual.dispose();
    _controladorObsIndividual.dispose();
    for (final c in _controladoresTemasIndividual.values) {
      c.dispose();
    }
    _controladorCsv.dispose();
    super.dispose();
  }

  // ─────────────── CARGA INDIVIDUAL ───────────────

  Future<void> _guardarNotaIndividual() async {
    final uid = _alumnoSeleccionadoUid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un estudiante')),
      );
      return;
    }

    final notaValor = double.tryParse(_controladorNotaIndividual.text.trim().replaceAll(',', '.'));
    if (notaValor == null || notaValor < 0 || notaValor > widget.evaluacion.notaMaxima) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ingresa una nota válida entre 0 y ${widget.evaluacion.notaMaxima}')),
      );
      return;
    }

    // Desglose por tema si fue ingresado
    final Map<String, double> notasPorTema = {};
    _controladoresTemasIndividual.forEach((tema, ctrl) {
      final val = double.tryParse(ctrl.text.trim().replaceAll(',', '.'));
      if (val != null) {
        notasPorTema[tema] = val;
      }
    });

    setState(() => _guardandoIndividual = true);

    final nombre = widget.clase.nombresAlumnos[uid] ?? 'Alumno $uid';
    final nota = NotaEvaluacion(
      id: '',
      evaluacionId: widget.evaluacion.id,
      claseId: widget.clase.id,
      alumnoUid: uid,
      alumnoNombre: nombre,
      nota: notaValor,
      notaMaxima: widget.evaluacion.notaMaxima,
      fechaRegistro: DateTime.now(),
      notasPorTema: notasPorTema,
      observaciones: _controladorObsIndividual.text.trim().isNotEmpty
          ? _controladorObsIndividual.text.trim()
          : null,
    );

    await widget.repositorioEvaluaciones.guardarNota(nota);
    widget.onNotasActualizadas();

    if (mounted) {
      setState(() => _guardandoIndividual = false);
      _controladorNotaIndividual.clear();
      _controladorObsIndividual.clear();
      for (final c in _controladoresTemasIndividual.values) {
        c.clear();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nota guardada correctamente para $nombre'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  // ─────────────── CARGA MASIVA CSV ───────────────

  void _copiarPlantillaCsv() {
    final buffer = StringBuffer();
    buffer.writeln('Identificador,Nombre,Nota');

    if (widget.clase.alumnosUids.isEmpty) {
      buffer.writeln('alumno-01,Juan Pérez,6.5');
      buffer.writeln('alumno-02,María Gómez,5.8');
    } else {
      for (final uid in widget.clase.alumnosUids) {
        final nombre = widget.clase.nombresAlumnos[uid] ?? 'Estudiante';
        buffer.writeln('$uid,$nombre,');
      }
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Plantilla CSV copiada al portapapeles con los alumnos de la clase.'),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  void _parsearTextoCsv(String texto) {
    setState(() {
      _errorCsv = null;
      _filasParseadas = [];
    });

    if (texto.trim().isEmpty) return;

    final lineas = texto.split(RegExp(r'\r?\n')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lineas.isEmpty) return;

    final List<_FilaCsvPrevia> resultados = [];

    for (int i = 0; i < lineas.length; i++) {
      final linea = lineas[i];
      // Separador flexible: coma, punto y coma o tabulación
      final partes = linea.contains(';')
          ? linea.split(';')
          : linea.contains('\t')
              ? linea.split('\t')
              : linea.split(',');

      final col1 = partes[0].trim();
      // Omitir cabecera solo si la última columna no es un número
      if (i == 0) {
        final ultimaCol = partes.last.trim();
        final esNumero = double.tryParse(ultimaCol.replaceAll(',', '.')) != null;
        if (!esNumero && (col1.toLowerCase().contains('id') || col1.toLowerCase().contains('nombre') || col1.toLowerCase().contains('alumno') || col1.toLowerCase().contains('nota'))) {
          continue;
        }
      }

      if (partes.length < 2) continue;

      String uid = '';
      String nombre = '';
      double? nota;

      if (partes.length >= 3) {
        // Formato: UID, Nombre, Nota
        uid = partes[0].trim();
        nombre = partes[1].trim();
        nota = double.tryParse(partes[2].trim().replaceAll(',', '.'));
      } else {
        // Formato: Identificador o Nombre, Nota
        final posibleNota = double.tryParse(partes[1].trim().replaceAll(',', '.'));
        nota = posibleNota;
        final identificador = partes[0].trim();

        // Buscar si coincide con UID o nombre en la clase
        if (widget.clase.alumnosUids.contains(identificador)) {
          uid = identificador;
          nombre = widget.clase.nombresAlumnos[uid] ?? identificador;
        } else {
          // Buscar por nombre
          final matchUid = widget.clase.nombresAlumnos.entries
              .cast<MapEntry<String, String>?>()
              .firstWhere(
                (e) => e != null && e.value.toLowerCase().contains(identificador.toLowerCase()),
                orElse: () => null,
              )
              ?.key;
          if (matchUid != null) {
            uid = matchUid;
            nombre = widget.clase.nombresAlumnos[matchUid] ?? identificador;
          } else {
            uid = 'UID-${identificador.hashCode.abs()}';
            nombre = identificador;
          }
        }
      }

      final bool notaValida = nota != null && nota >= 0 && nota <= widget.evaluacion.notaMaxima;

      resultados.add(
        _FilaCsvPrevia(
          lineaNumero: i + 1,
          alumnoUid: uid,
          alumnoNombre: nombre.isNotEmpty ? nombre : 'Estudiante',
          nota: nota,
          esValido: notaValida,
          error: !notaValida
              ? 'Nota inválida (debe ser entre 0 y ${widget.evaluacion.notaMaxima})'
              : null,
        ),
      );
    }

    setState(() {
      _filasParseadas = resultados;
      if (resultados.isEmpty) {
        _errorCsv = 'No se detectaron filas válidas en el texto ingresado.';
      }
    });
  }

  Future<void> _guardarCsv() async {
    final validas = _filasParseadas.where((f) => f.esValido && f.nota != null).toList();
    if (validas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay filas válidas para guardar')),
      );
      return;
    }

    setState(() => _guardandoCsv = true);

    final listaNotas = validas.map((f) => NotaEvaluacion(
      id: '',
      evaluacionId: widget.evaluacion.id,
      claseId: widget.clase.id,
      alumnoUid: f.alumnoUid,
      alumnoNombre: f.alumnoNombre,
      nota: f.nota!,
      notaMaxima: widget.evaluacion.notaMaxima,
      fechaRegistro: DateTime.now(),
    )).toList();

    final cantidad = await widget.repositorioEvaluaciones.guardarNotasEnBloque(listaNotas);
    widget.onNotasActualizadas();

    if (mounted) {
      setState(() {
        _guardandoCsv = false;
        _controladorCsv.clear();
        _filasParseadas.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡$cantidad notas cargadas con éxito en bloque!'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      _tabController.animateTo(2); // Ir a la pestaña de notas cargadas
    }
  }

  // ─────────────── EDICIÓN DE NOTA ERRÓNEA ───────────────

  Future<void> _editarNotaModal(NotaEvaluacion nota) async {
    final ctrl = TextEditingController(text: nota.nota.toString());
    final ctrlObs = TextEditingController(text: nota.observaciones ?? '');

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar Nota: ${nota.alumnoNombre}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evaluación: ${widget.evaluacion.nombre}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Calificación (0 a ${widget.evaluacion.notaMaxima})',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.edit_note),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrlObs,
              decoration: const InputDecoration(
                labelText: 'Observación (opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.comment_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text.trim().replaceAll(',', '.'));
              if (val != null && val >= 0 && val <= widget.evaluacion.notaMaxima) {
                Navigator.pop(ctx, true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Ingresa una nota válida (0 - ${widget.evaluacion.notaMaxima})')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            child: const Text('Guardar Corrección'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final nuevaNota = double.parse(ctrl.text.trim().replaceAll(',', '.'));
      final actualizada = nota.copyWith(
        nota: nuevaNota,
        fechaRegistro: DateTime.now(),
        observaciones: ctrlObs.text.trim().isNotEmpty ? ctrlObs.text.trim() : null,
      );
      await widget.repositorioEvaluaciones.actualizarNota(actualizada);
      widget.onNotasActualizadas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nota de ${nota.alumnoNombre} actualizada a $nuevaNota'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    }
  }

  Future<void> _eliminarNota(NotaEvaluacion nota) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Calificación'),
        content: Text('¿Deseas eliminar la nota de ${nota.alumnoNombre}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (conf == true) {
      await widget.repositorioEvaluaciones.eliminarNota(nota.id);
      widget.onNotasActualizadas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nota eliminada.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 680,
        height: 640,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Cabecera
            Row(
              children: [
                Icon(widget.evaluacion.tipo.icono, color: widget.evaluacion.tipo.color, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.evaluacion.nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Clase: ${widget.clase.nombre} • Escala: 0 a ${widget.evaluacion.notaMaxima}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Tab bar
            TabBar(
              controller: _tabController,
              labelColor: Colors.indigo,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.indigo,
              tabs: [
                const Tab(icon: Icon(Icons.person_outline, size: 20), text: 'Individual'),
                const Tab(icon: Icon(Icons.table_view_outlined, size: 20), text: 'Bloque / CSV'),
                Tab(
                  icon: const Icon(Icons.playlist_add_check, size: 20),
                  text: 'Notas (${widget.notasActuales.length}/${widget.clase.alumnosUids.length})',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Contenido Tabs
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _construirPestanaIndividual(),
                  _construirPestanaCsv(),
                  _construirPestanaNotasExistentes(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirPestanaIndividual() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cargar Nota de Estudiante:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          // Selector de alumno
          DropdownButtonFormField<String>(
            value: _alumnoSeleccionadoUid,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Seleccionar Estudiante',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.school_outlined),
            ),
            items: widget.clase.alumnosUids.map((uid) {
              final nombre = widget.clase.nombresAlumnos[uid] ?? uid;
              final yaTieneNota = widget.notasActuales.any((n) => n.alumnoUid == uid);
              return DropdownMenuItem(
                value: uid,
                child: Row(
                  children: [
                    Expanded(child: Text(nombre)),
                    if (yaTieneNota)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: const Text('Registrada', style: TextStyle(fontSize: 10, color: Colors.green)),
                      ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) => setState(() => _alumnoSeleccionadoUid = val),
          ),
          const SizedBox(height: 14),

          // Calificación global
          TextField(
            controller: _controladorNotaIndividual,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Nota Global (0 a ${widget.evaluacion.notaMaxima})',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.star_outline),
              helperText: 'Ejemplo: 6.5 o 5.8',
            ),
          ),
          const SizedBox(height: 14),

          // Desglose opcional por tema si la evaluación tiene más de 1 tema
          if (widget.evaluacion.temas.length > 1) ...[
            const Text(
              'Desglose por Tema (Opcional - para análisis granular):',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 8),
            ...widget.evaluacion.temas.map((tema) {
              final ctrl = _controladoresTemasIndividual[tema];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: TextField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Nota en tema: $tema',
                    isDense: true,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.label_outline, size: 18),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],

          TextField(
            controller: _controladorObsIndividual,
            decoration: const InputDecoration(
              labelText: 'Observación para el estudiante/apoderado (opcional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.notes),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _guardandoIndividual ? null : _guardarNotaIndividual,
              icon: _guardandoIndividual
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: const Text('GUARDAR CALIFICACIÓN'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirPestanaCsv() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Pega aquí las notas o genera la plantilla con tus alumnos:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _copiarPlantillaCsv,
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copiar Plantilla CSV', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.indigo),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Campo de texto CSV
        Expanded(
          flex: 4,
          child: TextField(
            controller: _controladorCsv,
            maxLines: null,
            expands: true,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Formato aceptado:\nIdentificador,Nombre,Nota\nalumno-01,Sofía Valenzuela,6.8\nalumno-02,Mateo Rivas,5.5\n\n(Acepta comas, punto y coma o tabulaciones)',
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.all(12),
            ),
            onChanged: _parsearTextoCsv,
          ),
        ),
        const SizedBox(height: 8),

        if (_errorCsv != null)
          Text(_errorCsv!, style: const TextStyle(color: Colors.red, fontSize: 12)),

        // Previsualización
        if (_filasParseadas.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Text(
                  'Previsualización: ${_filasParseadas.length} filas detectadas (${_filasParseadas.where((f) => f.esValido).length} válidas)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.separated(
                itemCount: _filasParseadas.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final fila = _filasParseadas[i];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      fila.esValido ? Icons.check_circle : Icons.error_outline,
                      color: fila.esValido ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    title: Text(
                      '${fila.alumnoNombre} (${fila.alumnoUid})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    subtitle: !fila.esValido && fila.error != null
                        ? Text(fila.error!, style: const TextStyle(color: Colors.red, fontSize: 11))
                        : null,
                    trailing: Text(
                      fila.nota != null ? '${fila.nota} / ${widget.evaluacion.notaMaxima}' : 'Sin nota',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: fila.esValido ? Colors.indigo : Colors.red,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _guardandoCsv ? null : _guardarCsv,
              icon: _guardandoCsv
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text('CONFIRMAR Y GUARDAR (${_filasParseadas.where((f) => f.esValido).length} NOTAS)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _construirPestanaNotasExistentes() {
    if (widget.notasActuales.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_late_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            const Text('Aún no hay notas cargadas para esta evaluación.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            const Text('Usa las pestañas superiores para cargar individual o por CSV.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Registradas: ${widget.notasActuales.length} de ${widget.clase.alumnosUids.length}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo),
              ),
              Text(
                'Promedio: ${(widget.notasActuales.fold(0.0, (acc, n) => acc + n.nota) / widget.notasActuales.length).toStringAsFixed(1)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: widget.notasActuales.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final n = widget.notasActuales[i];
              final bool aprobado = n.nota >= widget.evaluacion.notaAprobatoria;
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: aprobado ? Colors.green.shade100 : Colors.red.shade100,
                  child: Text(
                    n.nota.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: aprobado ? Colors.green.shade900 : Colors.red.shade900,
                    ),
                  ),
                ),
                title: Text(n.alumnoNombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Logro: ${n.porcentajeLogro.toStringAsFixed(0)}% • ID: ${n.alumnoUid}', style: const TextStyle(fontSize: 11)),
                    if (n.notasPorTema.isNotEmpty)
                      Text(
                        'Por tema: ${n.notasPorTema.entries.map((e) => "${e.key}: ${e.value}").join(" | ")}',
                        style: TextStyle(fontSize: 10, color: Colors.indigo.shade700),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                      tooltip: 'Editar nota cargada por error',
                      onPressed: () => _editarNotaModal(n),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      tooltip: 'Eliminar nota',
                      onPressed: () => _eliminarNota(n),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilaCsvPrevia {
  const _FilaCsvPrevia({
    required this.lineaNumero,
    required this.alumnoUid,
    required this.alumnoNombre,
    this.nota,
    required this.esValido,
    this.error,
  });

  final int lineaNumero;
  final String alumnoUid;
  final String alumnoNombre;
  final double? nota;
  final bool esValido;
  final String? error;
}
