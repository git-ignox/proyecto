import 'dart:math';
import 'package:flutter/material.dart';
import '../../datos/coordinador_sincronizacion_offline.dart';
import '../../dominio/modelos/recurso_educativo_offline.dart';

/// Diálogo para que el docente comparta un nuevo archivo o página web (MHTML),
/// especificando la fecha de uso, obligatoriedad y tamaño.
/// Esto encola automáticamente la descarga en segundo plano de los alumnos matriculados.
class DialogoCompartirMaterialDocente extends StatefulWidget {
  const DialogoCompartirMaterialDocente({
    super.key,
    required this.claseId,
    required this.profesorNombre,
    required this.coordinador,
    this.materiaPredeterminada,
  });

  final String claseId;
  final String profesorNombre;
  final CoordinadorSincronizacionOffline coordinador;
  final String? materiaPredeterminada;

  static Future<bool?> mostrar({
    required BuildContext context,
    required String claseId,
    required String profesorNombre,
    required CoordinadorSincronizacionOffline coordinador,
    String? materiaPredeterminada,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => DialogoCompartirMaterialDocente(
        claseId: claseId,
        profesorNombre: profesorNombre,
        coordinador: coordinador,
        materiaPredeterminada: materiaPredeterminada,
      ),
    );
  }

  @override
  State<DialogoCompartirMaterialDocente> createState() =>
      _DialogoCompartirMaterialDocenteState();
}

class _DialogoCompartirMaterialDocenteState
    extends State<DialogoCompartirMaterialDocente> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _tituloController;
  late final TextEditingController _materiaController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _urlController;
  late final TextEditingController _tamanoMbController;

  TipoRecursoEducativo _tipoSeleccionado = TipoRecursoEducativo.pdf;
  bool _esObligatorio = true;
  DateTime _fechaClase = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _horaClase = const TimeOfDay(hour: 9, minute: 0);
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController();
    _materiaController =
        TextEditingController(text: widget.materiaPredeterminada ?? 'Matemáticas');
    _descripcionController = TextEditingController();
    _urlController = TextEditingController(
      text: 'https://cdn.escuela.edu/materiales/guia_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    _tamanoMbController = TextEditingController(text: '3.5');
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _materiaController.dispose();
    _descripcionController.dispose();
    _urlController.dispose();
    _tamanoMbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fechaHoraCompleta = DateTime(
      _fechaClase.year,
      _fechaClase.month,
      _fechaClase.day,
      _horaClase.hour,
      _horaClase.minute,
    );

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.cloud_upload_rounded, color: Colors.indigo),
          SizedBox(width: 8),
          Expanded(child: Text('Compartir Material para Clase')),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'El material se descargará automáticamente de fondo en los dispositivos de los alumnos cuando tengan WiFi y batería suficiente.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tituloController,
                  decoration: const InputDecoration(
                    labelText: 'Título del material o guía',
                    hintText: 'Ej. Guía 4: Resolución de Ecuaciones',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Ingresa un título'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _materiaController,
                        decoration: const InputDecoration(
                          labelText: 'Asignatura / Materia',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.school_rounded),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Ingresa la asignatura'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<TipoRecursoEducativo>(
                        initialValue: _tipoSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Recurso',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: TipoRecursoEducativo.pdf,
                            child: Text('Documento PDF'),
                          ),
                          DropdownMenuItem(
                            value: TipoRecursoEducativo.paginaWebMhtml,
                            child: Text('Página Web (MHTML)'),
                          ),
                          DropdownMenuItem(
                            value: TipoRecursoEducativo.documento,
                            child: Text('Documento Office'),
                          ),
                          DropdownMenuItem(
                            value: TipoRecursoEducativo.imagen,
                            child: Text('Imagen / Esquema'),
                          ),
                          DropdownMenuItem(
                            value: TipoRecursoEducativo.video,
                            child: Text('Video Explicativo'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _tipoSeleccionado = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _tamanoMbController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Tamaño aprox. (MB)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.sd_storage_rounded),
                        ),
                        validator: (val) {
                          final numVal = double.tryParse(val ?? '');
                          if (numVal == null || numVal <= 0) {
                            return 'Inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _seleccionarFechaYHora,
                        icon: const Icon(Icons.calendar_today_rounded, size: 18),
                        label: Text(
                          '${_fechaClase.day}/${_fechaClase.month} ${_horaClase.format(context)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descripcionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Instrucciones pedagógicas',
                    hintText: 'Leer páginas 1 a 5 antes del inicio de clase.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Material obligatorio para la clase'),
                  subtitle: const Text(
                    'Tendrá mayor prioridad en la cola de descarga automática del alumno.',
                  ),
                  value: _esObligatorio,
                  onChanged: (val) => setState(() => _esObligatorio = val),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _guardando ? null : () => _guardarMaterial(fechaHoraCompleta),
          icon: _guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check_rounded),
          label: const Text('Compartir y Sincronizar'),
        ),
      ],
    );
  }

  Future<void> _seleccionarFechaYHora() async {
    final nuevaFecha = await showDatePicker(
      context: context,
      initialDate: _fechaClase,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (nuevaFecha == null || !mounted) return;

    final nuevaHora = await showTimePicker(
      context: context,
      initialTime: _horaClase,
    );
    if (nuevaHora == null || !mounted) return;

    setState(() {
      _fechaClase = nuevaFecha;
      _horaClase = nuevaHora;
    });
  }

  Future<void> _guardarMaterial(DateTime fechaHoraClase) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final tamanoMb = double.tryParse(_tamanoMbController.text.trim()) ?? 1.0;
      final tamanoBytes = (tamanoMb * 1024 * 1024).round();
      final idUnico =
          'MAT-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';

      final nuevoMaterial = RecursoEducativoOffline(
        id: idUnico,
        claseId: widget.claseId,
        materia: _materiaController.text.trim(),
        titulo: _tituloController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        tipoRecurso: _tipoSeleccionado,
        remoteUrl: _urlController.text.trim(),
        tamanoBytes: tamanoBytes,
        checksumSha256: 'sha256_${idUnico.toLowerCase()}',
        esObligatorio: _esObligatorio,
        esFijado: false,
        fechaUsoClase: fechaHoraClase,
        profesorNombre: widget.profesorNombre,
      );

      await widget.coordinador.repositorio.guardarMaterial(nuevoMaterial);

      // Si las condiciones lo permiten, comenzar descarga en background de inmediato
      if (widget.coordinador.condiciones.permiteDescargaEnSegundoPlano) {
        widget.coordinador.procesarColaDescargas();
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }
}
