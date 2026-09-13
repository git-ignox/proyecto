import 'package:flutter/material.dart';
import '../datos/repositorio_ejercicios.dart';
import '../dominio/modelos/algebraico.dart';
import '../dominio/modelos/aritmetico.dart';
import '../dominio/modelos/desarrollo.dart';
import '../dominio/modelos/ejercicio.dart';
import '../dominio/modelos/numerico.dart';
import '../dominio/modelos/posicion_curricular.dart';
import '../dominio/modelos/seleccion_multiple.dart';
import '../dominio/modelos/tipo_ejercicio.dart';

/// Formulario para crear un nuevo ejercicio con los 3 parámetros de tema,
/// etiquetas (tags) conceptuales y guardarlo en el catálogo de la aplicación.
class PantallaCrearEjercicio extends StatefulWidget {
  const PantallaCrearEjercicio({
    super.key,
    required this.repositorio,
  });

  final RepositorioEjercicios repositorio;

  @override
  State<PantallaCrearEjercicio> createState() => _PantallaCrearEjercicioState();
}

class _PantallaCrearEjercicioState extends State<PantallaCrearEjercicio> {
  final _formKey = GlobalKey<FormState>();

  // 3 Parámetros numéricos de tema
  final _temaCtrl = TextEditingController(text: '1');
  final _subtemaCtrl = TextEditingController(text: '1');
  final _leccionCtrl = TextEditingController(text: '1');

  // Metadatos
  int _nivel = 1;
  final _puntosCtrl = TextEditingController(text: '10');
  TipoEjercicio _tipoSeleccionado = TipoEjercicio.aritmetico;
  final _enunciadoCtrl = TextEditingController();
  final _pistasCtrl = TextEditingController();
  final _explicacionCtrl = TextEditingController();

  // Tags conceptuales
  final _nuevoTagCtrl = TextEditingController();
  final List<String> _tags = ['aritmetica', 'suma'];
  static const List<String> _tagsSugeridos = [
    'aritmetica',
    'suma',
    'resta',
    'multiplicacion',
    'division',
    'acarreo',
    'reagrupacion',
    'tablas-multiplicar',
    'division-galera',
    'resto',
    'despeje',
    'ecuaciones-casilla',
    'fraccion',
    'signos',
    'algebra',
    'factorizacion',
    'conceptos-clave',
  ];

  // Campos específicos: Aritmética
  OperacionAritmetica _operacionAritmetica = OperacionAritmetica.suma;
  DisposicionAritmetica _disposicionAritmetica = DisposicionAritmetica.vertical;
  ElementoIncognita _incognitaAritmetica = ElementoIncognita.resultado;
  final _operando1Ctrl = TextEditingController(text: '12');
  final _operando2Ctrl = TextEditingController(text: '8');

  // Campos específicos: Numérico
  final _valorEsperadoCtrl = TextEditingController();
  final _toleranciaCtrl = TextEditingController(text: '0.001');
  final _unidadCtrl = TextEditingController();

  // Campos específicos: Algebraico
  final _expresionCanonicaCtrl = TextEditingController();
  final _formasEquivalentesCtrl = TextEditingController();

  // Campos específicos: Desarrollo
  final _solucionModeloCtrl = TextEditingController();
  final _palabrasClaveCtrl = TextEditingController();
  double _umbralSimilitud = 0.60;

  // Campos específicos: Selección Múltiple
  final List<TextEditingController> _opcionesTextoCtrl = [
    TextEditingController(),
    TextEditingController(),
  ];
  int _indiceOpcionCorrecta = 0;

  @override
  void dispose() {
    _temaCtrl.dispose();
    _subtemaCtrl.dispose();
    _leccionCtrl.dispose();
    _puntosCtrl.dispose();
    _enunciadoCtrl.dispose();
    _pistasCtrl.dispose();
    _explicacionCtrl.dispose();
    _nuevoTagCtrl.dispose();
    _operando1Ctrl.dispose();
    _operando2Ctrl.dispose();
    _valorEsperadoCtrl.dispose();
    _toleranciaCtrl.dispose();
    _unidadCtrl.dispose();
    _expresionCanonicaCtrl.dispose();
    _formasEquivalentesCtrl.dispose();
    _solucionModeloCtrl.dispose();
    _palabrasClaveCtrl.dispose();
    for (final c in _opcionesTextoCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  void _agregarTag(String tag) {
    final t = tag.trim().toLowerCase();
    if (t.isNotEmpty && !_tags.contains(t)) {
      setState(() {
        _tags.add(t);
        _nuevoTagCtrl.clear();
      });
    }
  }

  void _eliminarTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _agregarOpcion() {
    setState(() {
      _opcionesTextoCtrl.add(TextEditingController());
    });
  }

  void _eliminarOpcion(int indice) {
    if (_opcionesTextoCtrl.length > 2) {
      setState(() {
        _opcionesTextoCtrl[indice].dispose();
        _opcionesTextoCtrl.removeAt(indice);
        if (_indiceOpcionCorrecta >= _opcionesTextoCtrl.length) {
          _indiceOpcionCorrecta = 0;
        }
      });
    }
  }

  Future<void> _guardarEjercicio() async {
    if (!_formKey.currentState!.validate()) return;

    final tema = int.tryParse(_temaCtrl.text.trim()) ?? 1;
    final subtema = int.tryParse(_subtemaCtrl.text.trim()) ?? 1;
    final leccion = int.tryParse(_leccionCtrl.text.trim()) ?? 1;
    final puntos = int.tryParse(_puntosCtrl.text.trim()) ?? 10;
    final posicion = PosicionCurricular(tema: tema, subtema: subtema, leccion: leccion);
    final id = 'EJC-${posicion.codigo}-${DateTime.now().millisecondsSinceEpoch % 10000}';

    final pistas = _pistasCtrl.text
        .split('\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final tagsFinales = List<String>.from(_tags);

    Ejercicio nuevoEjercicio;

    switch (_tipoSeleccionado) {
      case TipoEjercicio.aritmetico:
        final op1 = num.tryParse(_operando1Ctrl.text.trim().replaceAll(',', '.')) ?? 0;
        final op2 = num.tryParse(_operando2Ctrl.text.trim().replaceAll(',', '.')) ?? 1;

        nuevoEjercicio = Aritmetico(
          id: id,
          posicion: posicion,
          nivel: _nivel,
          enunciado: _enunciadoCtrl.text.trim().isNotEmpty
              ? _enunciadoCtrl.text.trim()
              : 'Calcula o resuelve la siguiente operación aritmética:',
          operacion: _operacionAritmetica,
          operando1: op1,
          operando2: op2,
          disposicion: _disposicionAritmetica,
          incognita: _incognitaAritmetica,
          tags: tagsFinales,
          pistas: pistas,
          explicacion: _explicacionCtrl.text.trim(),
          puntos: puntos,
        );
        break;

      case TipoEjercicio.seleccionMultiple:
        final opciones = <Opcion>[];
        for (int i = 0; i < _opcionesTextoCtrl.length; i++) {
          final idOp = String.fromCharCode(97 + i); // a, b, c, d
          opciones.add(Opcion(
            id: idOp,
            texto: _opcionesTextoCtrl[i].text.trim(),
            esCorrecta: i == _indiceOpcionCorrecta,
          ));
        }
        nuevoEjercicio = SeleccionMultiple(
          id: id,
          posicion: posicion,
          nivel: _nivel,
          enunciado: _enunciadoCtrl.text.trim(),
          opciones: opciones,
          tags: tagsFinales,
          pistas: pistas,
          explicacion: _explicacionCtrl.text.trim(),
          puntos: puntos,
        );
        break;

      case TipoEjercicio.numerico:
        final valor = double.tryParse(_valorEsperadoCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;
        final tol = double.tryParse(_toleranciaCtrl.text.trim().replaceAll(',', '.')) ?? 0.001;
        final unidad = _unidadCtrl.text.trim().isNotEmpty ? _unidadCtrl.text.trim() : null;

        nuevoEjercicio = Numerico(
          id: id,
          posicion: posicion,
          nivel: _nivel,
          enunciado: _enunciadoCtrl.text.trim(),
          valorEsperado: valor,
          tolerancia: tol,
          unidad: unidad,
          tags: tagsFinales,
          pistas: pistas,
          explicacion: _explicacionCtrl.text.trim(),
          puntos: puntos,
        );
        break;

      case TipoEjercicio.algebraico:
        final equivalentes = _formasEquivalentesCtrl.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        nuevoEjercicio = Algebraico(
          id: id,
          posicion: posicion,
          nivel: _nivel,
          enunciado: _enunciadoCtrl.text.trim(),
          expresionCanonica: _expresionCanonicaCtrl.text.trim(),
          formasEquivalentes: equivalentes,
          tags: tagsFinales,
          pistas: pistas,
          explicacion: _explicacionCtrl.text.trim(),
          puntos: puntos,
        );
        break;

      case TipoEjercicio.desarrollo:
        final palabras = _palabrasClaveCtrl.text
            .split(',')
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList();

        nuevoEjercicio = Desarrollo(
          id: id,
          posicion: posicion,
          nivel: _nivel,
          enunciado: _enunciadoCtrl.text.trim(),
          solucion: _solucionModeloCtrl.text.trim(),
          palabrasClave: palabras,
          umbralSimilitud: _umbralSimilitud,
          tags: tagsFinales,
          pistas: pistas,
          explicacion: _explicacionCtrl.text.trim(),
          puntos: puntos,
        );
        break;
    }

    await widget.repositorio.agregarEjercicio(nuevoEjercicio);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Ejercicio guardado en posición ${posicion.codigo} con ${tagsFinales.length} tags!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nuevo Ejercicio'),
        actions: [
          IconButton(
            onPressed: _guardarEjercicio,
            icon: const Icon(Icons.check),
            tooltip: 'Guardar',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Los 3 Parámetros Numéricos de Tema (tema, subtema, leccion)
              Card(
                elevation: 1,
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Organización Curricular (3 Parámetros):',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _temaCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '1. Tema',
                                hintText: 'Ej. 3',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => (v == null || int.tryParse(v) == null) ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _subtemaCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '2. Subtema',
                                hintText: 'Ej. 2',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => (v == null || int.tryParse(v) == null) ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _leccionCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '3. Lección',
                                hintText: 'Ej. 1',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => (v == null || int.tryParse(v) == null) ? 'Requerido' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. Tags Conceptuales
              Card(
                elevation: 1,
                color: Colors.indigo.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.local_offer, size: 18, color: Colors.indigo),
                          SizedBox(width: 6),
                          Text(
                            'Tags & Habilidades Matemáticas:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Los tags permiten al sistema clasificar los errores del alumno y generar refuerzo adaptativo.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),

                      // Tags asignados
                      if (_tags.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _tags.map((t) {
                            return Chip(
                              label: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              backgroundColor: Colors.white,
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () => _eliminarTag(t),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 8),

                      // Campo para escribir tag personalizado
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nuevoTagCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Escribir tag personalizado (ej. fracciones-impropias)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onSubmitted: _agregarTag,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _agregarTag(_nuevoTagCtrl.text),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Añadir'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Sugerencias rápidas
                      const Text('Tags sugeridos para añadir:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: _tagsSugeridos
                            .where((s) => !_tags.contains(s))
                            .take(8)
                            .map((s) => ActionChip(
                                  label: Text('+ $s', style: const TextStyle(fontSize: 11)),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _agregarTag(s),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 3. Tipo de Ejercicio y Dificultad
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<TipoEjercicio>(
                      initialValue: _tipoSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Ejercicio',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: TipoEjercicio.aritmetico,
                          child: Text('Aritmética (Vertical / Galera / Corto)'),
                        ),
                        DropdownMenuItem(
                          value: TipoEjercicio.desarrollo,
                          child: Text('Desarrollo (Similitud)'),
                        ),
                        DropdownMenuItem(
                          value: TipoEjercicio.seleccionMultiple,
                          child: Text('Selección Múltiple'),
                        ),
                        DropdownMenuItem(
                          value: TipoEjercicio.numerico,
                          child: Text('Numérico / Fracción'),
                        ),
                        DropdownMenuItem(
                          value: TipoEjercicio.algebraico,
                          child: Text('Algebraico'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _tipoSeleccionado = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _nivel,
                      decoration: const InputDecoration(
                        labelText: 'Nivel',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Nivel 1 (Fácil)')),
                        DropdownMenuItem(value: 2, child: Text('Nivel 2 (Medio)')),
                        DropdownMenuItem(value: 3, child: Text('Nivel 3 (Difícil)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _nivel = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 4. Enunciado del Ejercicio
              TextFormField(
                controller: _enunciadoCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Enunciado del Problema',
                  hintText: 'Ej. Resuelve detalladamente la ecuación 2x² - 4x - 6 = 0...',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el enunciado' : null,
              ),
              const SizedBox(height: 16),

              // 5. Formulario específico según el tipo
              _construirCamposEspecificos(),
              const SizedBox(height: 16),

              // 6. Pistas y Explicación
              TextFormField(
                controller: _explicacionCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Explicación de la Solución (Opcional)',
                  hintText: 'Pasos o justificación pedagógica...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _pistasCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Pistas (Una por línea, opcional)',
                  hintText: 'Pista 1\nPista 2',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Botón Guardar
              ElevatedButton.icon(
                onPressed: _guardarEjercicio,
                icon: const Icon(Icons.save),
                label: const Text('GUARDAR Y AGREGAR A LA APP', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirCamposEspecificos() {
    switch (_tipoSeleccionado) {
      case TipoEjercicio.aritmetico:
        final op1 = num.tryParse(_operando1Ctrl.text.trim()) ?? 0;
        final op2 = num.tryParse(_operando2Ctrl.text.trim()) ?? 1;

        return Card(
          elevation: 1,
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configuración Aritmética:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Selección de Operación y Disposición
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<OperacionAritmetica>(
                        initialValue: _operacionAritmetica,
                        decoration: const InputDecoration(
                          labelText: 'Operación',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: OperacionAritmetica.suma, child: Text('Suma (+)')),
                          DropdownMenuItem(value: OperacionAritmetica.resta, child: Text('Resta (-)')),
                          DropdownMenuItem(value: OperacionAritmetica.multiplicacion, child: Text('Multiplicación (×)')),
                          DropdownMenuItem(value: OperacionAritmetica.division, child: Text('División (÷ / Galera)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _operacionAritmetica = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<DisposicionAritmetica>(
                        initialValue: _disposicionAritmetica,
                        decoration: const InputDecoration(
                          labelText: 'Formato Visual',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: DisposicionAritmetica.vertical, child: Text('Vertical / Galera')),
                          DropdownMenuItem(value: DisposicionAritmetica.horizontal, child: Text('Corto (Horizontal)')),
                          DropdownMenuItem(value: DisposicionAritmetica.fraccion, child: Text('Fracción (a/b)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _disposicionAritmetica = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Selección de Incógnita
                DropdownButtonFormField<ElementoIncognita>(
                  initialValue: _incognitaAritmetica,
                  decoration: const InputDecoration(
                    labelText: 'Elemento que será la incógnita [ ? ]',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: ElementoIncognita.resultado, child: Text('Resultado (c) [7 + 8 = ?]')),
                    const DropdownMenuItem(value: ElementoIncognita.operando1, child: Text('Primer término (a) [? + 8 = 15]')),
                    const DropdownMenuItem(value: ElementoIncognita.operando2, child: Text('Segundo término (b) [7 + ? = 15]')),
                    const DropdownMenuItem(value: ElementoIncognita.operador, child: Text('Operador [7 ? 8 = 15]')),
                    if (_operacionAritmetica == OperacionAritmetica.division) ...[
                      const DropdownMenuItem(value: ElementoIncognita.cociente, child: Text('Cociente en División')),
                      const DropdownMenuItem(value: ElementoIncognita.resto, child: Text('Resto o Residuo en División')),
                    ],
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _incognitaAritmetica = val);
                  },
                ),
                const SizedBox(height: 8),

                // Operandos a y b
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _operando1Ctrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: _operacionAritmetica == OperacionAritmetica.division ? 'Dividendo (a)' : 'Operando 1 (a)',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _operando2Ctrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: _operacionAritmetica == OperacionAritmetica.division ? 'Divisor (b)' : 'Operando 2 (b)',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Mini vista previa informativa
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.preview, size: 18, color: Colors.indigo),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Operación exacta: $op1 ${_operacionAritmetica.simbolo} $op2 = ${_operacionAritmetica == OperacionAritmetica.division ? (op2 != 0 ? op1 ~/ op2 : 0) : (_operacionAritmetica == OperacionAritmetica.suma ? op1 + op2 : (_operacionAritmetica == OperacionAritmetica.resta ? op1 - op2 : op1 * op2))}',
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

      case TipoEjercicio.desarrollo:
        return Card(
          elevation: 1,
          color: Colors.amber.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configuración de Desarrollo & Similitud:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _solucionModeloCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Solución Modelo / Ejemplo',
                    hintText: 'Escribe la respuesta ideal contra la cual se comparará...',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa la solución modelo' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _palabrasClaveCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Palabras / Fórmulas Clave (separadas por coma)',
                    hintText: 'Ej. discriminante, 64, x = 3, x = -1',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Umbral de Similitud: ${(_umbralSimilitud * 100).toInt()}%'),
                    Expanded(
                      child: Slider(
                        value: _umbralSimilitud,
                        min: 0.30,
                        max: 0.90,
                        divisions: 12,
                        label: '${(_umbralSimilitud * 100).toInt()}%',
                        onChanged: (v) => setState(() => _umbralSimilitud = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

      case TipoEjercicio.seleccionMultiple:
        return Card(
          elevation: 1,
          color: Colors.indigo.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Opciones de Selección:', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: _agregarOpcion,
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar opción'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(_opcionesTextoCtrl.length, (i) {
                  final letra = String.fromCharCode(97 + i); // a, b, c
                  final esCorrecta = _indiceOpcionCorrecta == i;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            esCorrecta ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: esCorrecta ? Colors.indigo : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() => _indiceOpcionCorrecta = i);
                          },
                          tooltip: 'Marcar como correcta',
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _opcionesTextoCtrl[i],
                            decoration: InputDecoration(
                              labelText: 'Opción ($letra)${esCorrecta ? " - Correcta" : ""}',
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                          ),
                        ),
                        if (_opcionesTextoCtrl.length > 2)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _eliminarOpcion(i),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );

      case TipoEjercicio.numerico:
        return Card(
          elevation: 1,
          color: Colors.teal.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Configuración Numérica:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _valorEsperadoCtrl,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: 'Valor Numérico Esperado',
                          hintText: 'Ej. 1.25 o 5/4',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el valor' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _toleranciaCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Tolerancia (±)',
                          hintText: '0.001',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _unidadCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Unidad (Opcional: cm, m/s, etc.)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        );

      case TipoEjercicio.algebraico:
        return Card(
          elevation: 1,
          color: Colors.purple.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Configuración Algebraica:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _expresionCanonicaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Expresión Canónica',
                    hintText: 'Ej. (x-3)(x+3)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _formasEquivalentesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Formas Equivalentes (separadas por coma)',
                    hintText: 'Ej. (x+3)(x-3), (x - 3) * (x + 3)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }
}
