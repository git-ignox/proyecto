import 'package:flutter/material.dart';
import '../datos/repositorio_ejercicios.dart';
import '../dominio/evaluadores/servicio_evaluacion.dart';
import '../dominio/generadores/generador_aritmetica.dart';
import '../dominio/modelos/algebraico.dart';
import '../dominio/modelos/aritmetico.dart';
import '../dominio/modelos/desarrollo.dart';
import '../dominio/modelos/ejercicio.dart';
import '../dominio/modelos/numerico.dart';
import '../dominio/modelos/resultado_evaluacion.dart';
import '../dominio/modelos/seleccion_multiple.dart';
import '../dominio/modelos/tipo_ejercicio.dart';
import 'pantalla_crear_ejercicio.dart';
import 'widgets/widget_aritmetica.dart';

/// Pantalla interactiva para probar y calificar ejercicios matemáticos
/// con soporte para crear nuevos ejercicios dinámicamente.
class PantallaEjercicios extends StatefulWidget {
  const PantallaEjercicios({
    super.key,
    required this.repositorio,
    required this.servicioEvaluacion,
  });

  final RepositorioEjercicios repositorio;
  final ServicioEvaluacion servicioEvaluacion;

  @override
  State<PantallaEjercicios> createState() => _PantallaEjerciciosState();
}

class _PantallaEjerciciosState extends State<PantallaEjercicios> {
  List<Ejercicio> _ejercicios = [];
  int _indiceActual = 0;
  bool _cargando = true;

  final GeneradorAritmetica _generador = GeneradorAritmetica();

  // Estado de respuestas del usuario
  String? _opcionSeleccionadaId;
  final TextEditingController _controladorTexto = TextEditingController();
  final TextEditingController _controladorResto = TextEditingController();

  // Estado de evaluación
  ResultadoEvaluacion? _resultado;
  bool _evaluando = false;

  @override
  void initState() {
    super.initState();
    _cargarEjercicios();
  }

  Future<void> _cargarEjercicios({int? indiceObjetivo}) async {
    setState(() => _cargando = true);
    final lista = await widget.repositorio.obtenerTodos();
    setState(() {
      _ejercicios = lista;
      if (indiceObjetivo != null && indiceObjetivo < _ejercicios.length) {
        _indiceActual = indiceObjetivo;
      } else if (_indiceActual >= _ejercicios.length) {
        _indiceActual = _ejercicios.isNotEmpty ? _ejercicios.length - 1 : 0;
      }
      _cargando = false;
      _limpiarRespuesta();
    });
  }

  void _limpiarRespuesta() {
    _opcionSeleccionadaId = null;
    _controladorTexto.clear();
    _controladorResto.clear();
    _resultado = null;
  }

  void _cambiarEjercicio(int nuevoIndice) {
    if (nuevoIndice >= 0 && nuevoIndice < _ejercicios.length) {
      setState(() {
        _indiceActual = nuevoIndice;
        _limpiarRespuesta();
      });
    }
  }

  Future<void> _abrirCrearEjercicio() async {
    final creado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PantallaCrearEjercicio(repositorio: widget.repositorio),
      ),
    );

    if (creado == true) {
      await _cargarEjercicios(indiceObjetivo: _ejercicios.length);
    }
  }

  Future<void> _eliminarEjercicioActual() async {
    if (_ejercicios.isEmpty) return;
    final ejercicio = _ejercicios[_indiceActual];

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Ejercicio'),
        content: Text('¿Deseas eliminar el ejercicio ${ejercicio.codigoTema}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await widget.repositorio.eliminarEjercicio(ejercicio.id);
      await _cargarEjercicios();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ejercicio eliminado')),
        );
      }
    }
  }

  Future<void> _generarAritmeticaRapida({OperacionAritmetica? op, int nivel = 1}) async {
    final nuevo = _generador.generar(operacion: op, nivel: nivel);
    await widget.repositorio.agregarEjercicio(nuevo);
    await _cargarEjercicios(indiceObjetivo: _ejercicios.length);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Generada pregunta de ${nuevo.operacion.name.toUpperCase()} (Nivel $nivel)!'),
          backgroundColor: Colors.indigo,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _mostrarDialogoGenerador() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Generar Pregunta de Aritmética',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Elige la operación que deseas practicar:', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.add_circle, color: Colors.blue),
                  label: const Text('Suma (+)'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _generarAritmeticaRapida(op: OperacionAritmetica.suma);
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.remove_circle, color: Colors.orange),
                  label: const Text('Resta (-)'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _generarAritmeticaRapida(op: OperacionAritmetica.resta);
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.cancel, color: Colors.green),
                  label: const Text('Multiplicación (×)'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _generarAritmeticaRapida(op: OperacionAritmetica.multiplicacion);
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.safety_divider, color: Colors.purple),
                  label: const Text('División (Galera)'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _generarAritmeticaRapida(op: OperacionAritmetica.division);
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.casino, color: Colors.red),
                  label: const Text('¡Aleatoria Sorpresa!'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _generarAritmeticaRapida();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _evaluarRespuesta() async {
    if (_ejercicios.isEmpty) return;
    final ejercicio = _ejercicios[_indiceActual];

    dynamic respuestaUsuario;
    if (ejercicio is SeleccionMultiple) {
      respuestaUsuario = _opcionSeleccionadaId;
    } else if (ejercicio is Aritmetico) {
      if (ejercicio.operacion == OperacionAritmetica.division &&
          _controladorResto.text.trim().isNotEmpty) {
        respuestaUsuario = {
          'cociente': _controladorTexto.text.trim(),
          'resto': _controladorResto.text.trim(),
        };
      } else {
        respuestaUsuario = _controladorTexto.text.trim();
      }
    } else {
      respuestaUsuario = _controladorTexto.text;
    }

    setState(() => _evaluando = true);

    final res = await widget.servicioEvaluacion.evaluar(
      ejercicio: ejercicio,
      respuesta: respuestaUsuario,
    );

    setState(() {
      _resultado = res;
      _evaluando = false;
    });
  }

  void _alternarModoEvaluacion() {
    setState(() {
      widget.servicioEvaluacion.modo =
          widget.servicioEvaluacion.modo == ModoEvaluacion.offline
              ? ModoEvaluacion.online
              : ModoEvaluacion.offline;
    });
  }

  @override
  void dispose() {
    _controladorTexto.dispose();
    _controladorResto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final modo = widget.servicioEvaluacion.modo;

    // Estado cuando no hay ejercicios en la app
    if (_ejercicios.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('App Matemáticas'),
          actions: [
            _construirBotonModo(modo),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calculate_outlined, size: 72, color: Colors.indigo.shade300),
                const SizedBox(height: 16),
                const Text(
                  'No hay ejercicios creados aún',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Genera una pregunta de aritmética en formato vertical/galera o crea un ejercicio personalizado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _generarAritmeticaRapida(),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('GENERAR PREGUNTA DE ARITMÉTICA'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _abrirCrearEjercicio,
                  icon: const Icon(Icons.add),
                  label: const Text('Crear Ejercicio Manual'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final ejercicio = _ejercicios[_indiceActual];

    return Scaffold(
      appBar: AppBar(
        title: Text('Ejercicio ${_indiceActual + 1} de ${_ejercicios.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.indigo),
            tooltip: 'Generar práctica aritmética rápida',
            onPressed: _mostrarDialogoGenerador,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Eliminar ejercicio',
            onPressed: _eliminarEjercicioActual,
          ),
          _construirBotonModo(modo),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirCrearEjercicio,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Ejercicio'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Metadatos del ejercicio con los 3 parámetros numéricos (Tema, Subtema, Lección)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(
                  label: Text('Tema: ${ejercicio.tema} | Subtema: ${ejercicio.subtema} | Lección: ${ejercicio.leccion} (${ejercicio.codigoTema})'),
                  backgroundColor: Colors.blue.shade100,
                  avatar: const Icon(Icons.account_tree_outlined, size: 18),
                ),
                Chip(
                  label: Text('Nivel ${ejercicio.nivel}'),
                  backgroundColor: Colors.purple.shade100,
                ),
                Chip(
                  label: Text(ejercicio.tipo.name),
                  backgroundColor: Colors.teal.shade100,
                ),
                Chip(
                  label: Text('${ejercicio.puntos} pts'),
                  backgroundColor: Colors.amber.shade100,
                ),
              ],
            ),
            if (ejercicio.tags.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: ejercicio.tags
                    .map((t) => Chip(
                          avatar: const Icon(Icons.local_offer_outlined, size: 14, color: Colors.indigo),
                          label: Text(t, style: const TextStyle(fontSize: 12, color: Colors.indigo)),
                          backgroundColor: Colors.indigo.shade50,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),

            // Enunciado
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enunciado:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ejercicio.enunciado,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Entrada de respuesta según el tipo de ejercicio
            _construirEntradaRespuesta(ejercicio),
            const SizedBox(height: 16),

            // Botón de acción Calificar
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _evaluando ? null : _evaluarRespuesta,
                    icon: _evaluando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: const Text('CALIFICAR RESPUESTA', style: TextStyle(fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Botones de navegación
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: _indiceActual > 0
                      ? () => _cambiarEjercicio(_indiceActual - 1)
                      : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Anterior'),
                ),
                OutlinedButton.icon(
                  onPressed: _indiceActual < _ejercicios.length - 1
                      ? () => _cambiarEjercicio(_indiceActual + 1)
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Siguiente'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Panel de resultados de la evaluación algorítmica
            if (_resultado != null) _construirPanelResultado(_resultado!),
            const SizedBox(height: 60), // Espacio para el FloatingActionButton
          ],
        ),
      ),
    );
  }

  Widget _construirBotonModo(ModoEvaluacion modo) {
    return TextButton.icon(
      onPressed: _alternarModoEvaluacion,
      icon: Icon(
        modo == ModoEvaluacion.offline ? Icons.cloud_off : Icons.cloud_done,
        color: modo == ModoEvaluacion.offline ? Colors.orange : Colors.green,
      ),
      label: Text(
        modo == ModoEvaluacion.offline ? 'OFFLINE' : 'ONLINE',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: modo == ModoEvaluacion.offline ? Colors.orange : Colors.green,
        ),
      ),
    );
  }

  /// Construye el widget de entrada según el tipo de ejercicio
  Widget _construirEntradaRespuesta(Ejercicio ejercicio) {
    if (ejercicio is Aritmetico) {
      return WidgetAritmetica(
        ejercicio: ejercicio,
        controladorTexto: _controladorTexto,
        controladorResto: _controladorResto,
        onRespuestaCambiada: () {
          if (_resultado != null) setState(() => _resultado = null);
        },
      );
    }

    if (ejercicio is SeleccionMultiple) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Selecciona una opción:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...ejercicio.opciones.map((op) {
            final estaSeleccionada = _opcionSeleccionadaId == op.id;
            return Card(
              color: estaSeleccionada ? Colors.indigo.shade50 : null,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: estaSeleccionada ? Colors.indigo : Colors.grey.shade300,
                  width: estaSeleccionada ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: Icon(
                  estaSeleccionada ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: estaSeleccionada ? Colors.indigo : Colors.grey,
                ),
                title: Text(op.texto),
                onTap: () {
                  setState(() => _opcionSeleccionadaId = op.id);
                },
              ),
            );
          }),
        ],
      );
    }

    if (ejercicio is Numerico || ejercicio is Algebraico) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ejercicio is Numerico
                ? 'Ingresa el valor numérico (ej. 1.25 o 5/4):'
                : 'Ingresa la expresión simplificada (ej. (x-3)(x+3)):',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controladorTexto,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Tu respuesta...',
            ),
          ),
        ],
      );
    }

    if (ejercicio is Desarrollo) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Escribe tu procedimiento o desarrollo:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controladorTexto,
            maxLines: 5,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Escribe paso a paso tu solución...',
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  /// Construye el panel con el desglose de métricas algorítmicas y retroalimentación
  Widget _construirPanelResultado(ResultadoEvaluacion res) {
    final color = res.esCorrecto ? Colors.green : (res.puntaje > 0.0 ? Colors.orange : Colors.red);

    return Card(
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  res.esCorrecto ? Icons.check_circle : (res.puntaje > 0 ? Icons.info : Icons.cancel),
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(
                  res.esCorrecto ? '¡CORRECTO!' : (res.puntaje > 0 ? 'PARCIALMENTE CORRECTO' : 'INCORRECTO'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                const Spacer(),
                Text(
                  'Puntaje: ${(res.puntaje * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Text(
              res.retroalimentacion,
              style: const TextStyle(fontSize: 15),
            ),
            if (res.similitudHibrida > 0) ...[
              const SizedBox(height: 12),
              const Text(
                'Métricas del Motor de Similitud:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text('• Similitud Híbrida Global: ${(res.similitudHibrida * 100).toStringAsFixed(1)}%'),
              Text('• Levenshtein (distancia de edición): ${(res.similitudLevenshtein * 100).toStringAsFixed(1)}%'),
              Text('• Jaccard (tokens y n-gramas): ${(res.similitudJaccard * 100).toStringAsFixed(1)}%'),
              Text('• Coseno TF-IDF (relevancia semántica): ${(res.similitudCoseno * 100).toStringAsFixed(1)}%'),
            ],
            if (res.palabrasClaveEncontradas.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '✓ Conceptos detectados: ${res.palabrasClaveEncontradas.join(", ")}',
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
              ),
            ],
            if (res.palabrasClaveFaltantes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '✗ Conceptos faltantes: ${res.palabrasClaveFaltantes.join(", ")}',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
              ),
            ],
            if (!res.esCorrecto && res.errorDetectado != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(res.errorDetectado!.categoria.icono, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Diagnóstico del Error: ${res.errorDetectado!.categoria.etiqueta}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            res.errorDetectado!.severidad.etiqueta,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '💡 Consejo Didáctico: ${res.errorDetectado!.sugerenciaPedagogica}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.indigo),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
