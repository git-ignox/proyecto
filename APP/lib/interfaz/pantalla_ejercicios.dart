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
import 'design/app_colors.dart';
import 'pantalla_crear_ejercicio.dart';
import 'widgets/mac_glass_widgets.dart';
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
      backgroundColor: AppColors.claudeSuperficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.claudeBorde),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Generar Pregunta de Aritmética',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.claudeTextoPrincipal),
            ),
            const SizedBox(height: 12),
            const Text(
              'Elige la operación que deseas practicar:',
              style: TextStyle(color: AppColors.claudeTextoSecundario),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.add_circle, color: Colors.blueAccent),
                  label: const Text('Suma (+)'),
                  backgroundColor: AppColors.claudeSuperficieSuave,
                  side: const BorderSide(color: AppColors.claudeBorde),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _generarAritmeticaRapida(op: OperacionAritmetica.suma);
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.remove_circle, color: Colors.orangeAccent),
                  label: const Text('Resta (-)'),
                  backgroundColor: AppColors.claudeSuperficieSuave,
                  side: const BorderSide(color: AppColors.claudeBorde),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _generarAritmeticaRapida(op: OperacionAritmetica.resta);
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.cancel, color: Colors.greenAccent),
                  label: const Text('Multiplicación (×)'),
                  backgroundColor: AppColors.claudeSuperficieSuave,
                  side: const BorderSide(color: AppColors.claudeBorde),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _generarAritmeticaRapida(op: OperacionAritmetica.multiplicacion);
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.safety_divider, color: Colors.purpleAccent),
                  label: const Text('División (Galera)'),
                  backgroundColor: AppColors.claudeSuperficieSuave,
                  side: const BorderSide(color: AppColors.claudeBorde),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _generarAritmeticaRapida(op: OperacionAritmetica.division);
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.casino, color: Colors.redAccent),
                  label: const Text('¡Aleatoria Sorpresa!'),
                  backgroundColor: AppColors.claudeSuperficieSuave,
                  side: const BorderSide(color: AppColors.claudeBorde),
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
          backgroundColor: const Color(0xFF161514).withValues(alpha: 0.88),
          surfaceTintColor: Colors.transparent,
          shape: const Border(bottom: BorderSide(color: AppColors.claudeBorde, width: 1)),
          title: const Text('App Matemáticas', style: TextStyle(color: AppColors.claudeTextoPrincipal, fontWeight: FontWeight.bold)),
          actions: [
            _construirBotonModo(modo),
          ],
        ),
        body: MacDesktopBackground(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calculate_outlined, size: 72, color: AppColors.claudeTerracota),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay ejercicios creados aún',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.claudeTextoPrincipal),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Genera una pregunta de aritmética en formato vertical/galera o crea un ejercicio personalizado.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.claudeTextoSecundario),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _generarAritmeticaRapida(),
                    icon: const Icon(Icons.auto_awesome, color: Color(0xFF1E1D1B)),
                    label: const Text('GENERAR PREGUNTA DE ARITMÉTICA', style: TextStyle(color: Color(0xFF1E1D1B), fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFECE7DE),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _abrirCrearEjercicio,
                    icon: const Icon(Icons.add, color: AppColors.claudeTextoPrincipal),
                    label: const Text('Crear Ejercicio Manual', style: TextStyle(color: AppColors.claudeTextoPrincipal)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.claudeBorde),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final ejercicio = _ejercicios[_indiceActual];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF161514).withValues(alpha: 0.88),
        surfaceTintColor: Colors.transparent,
        shape: const Border(bottom: BorderSide(color: AppColors.claudeBorde, width: 1)),
        title: Text(
          'Ejercicio ${_indiceActual + 1} de ${_ejercicios.length}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.claudeTextoPrincipal),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: AppColors.claudeTerracota),
            tooltip: 'Generar práctica aritmética rápida',
            onPressed: _mostrarDialogoGenerador,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
            tooltip: 'Eliminar ejercicio',
            onPressed: _eliminarEjercicioActual,
          ),
          _construirBotonModo(modo),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirCrearEjercicio,
        icon: const Icon(Icons.add, color: Color(0xFF1E1D1B)),
        label: const Text('Nuevo Ejercicio', style: TextStyle(color: Color(0xFF1E1D1B), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFECE7DE),
      ),
      body: MacDesktopBackground(
        child: SingleChildScrollView(
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
                    label: Text(
                      'Tema: ${ejercicio.tema} | Subtema: ${ejercicio.subtema} | Lección: ${ejercicio.leccion} (${ejercicio.codigoTema})',
                      style: const TextStyle(fontSize: 12, color: AppColors.claudeTextoPrincipal),
                    ),
                    backgroundColor: AppColors.claudeSuperficieSuave,
                    side: const BorderSide(color: AppColors.claudeBorde),
                    avatar: const Icon(Icons.account_tree_outlined, size: 18, color: AppColors.claudeTerracota),
                  ),
                  Chip(
                    label: Text('Nivel ${ejercicio.nivel}', style: const TextStyle(fontSize: 12, color: AppColors.claudeTextoPrincipal)),
                    backgroundColor: AppColors.claudeSuperficieSuave,
                    side: const BorderSide(color: AppColors.claudeBorde),
                  ),
                  Chip(
                    label: Text(ejercicio.tipo.name, style: const TextStyle(fontSize: 12, color: AppColors.claudeTextoPrincipal)),
                    backgroundColor: AppColors.claudeSuperficieSuave,
                    side: const BorderSide(color: AppColors.claudeBorde),
                  ),
                  Chip(
                    label: Text('${ejercicio.puntos} pts', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                    backgroundColor: AppColors.claudeSuperficieSuave,
                    side: const BorderSide(color: AppColors.claudeBorde),
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
                            avatar: const Icon(Icons.local_offer_outlined, size: 14, color: AppColors.claudeTerracota),
                            label: Text(t, style: const TextStyle(fontSize: 12, color: AppColors.claudeTerracota)),
                            backgroundColor: AppColors.claudeSuperficieSuave,
                            side: const BorderSide(color: AppColors.claudeBorde),
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 12),

              // Enunciado
              Container(
                decoration: BoxDecoration(
                  color: AppColors.claudeSuperficie.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.claudeBorde),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enunciado:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.claudeTextoPrincipal),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ejercicio.enunciado,
                      style: const TextStyle(fontSize: 16, color: AppColors.claudeTextoPrincipal),
                    ),
                  ],
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
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E1D1B)),
                            )
                          : const Icon(Icons.check_circle_outline, color: Color(0xFF1E1D1B)),
                      label: const Text(
                        'CALIFICAR RESPUESTA',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E1D1B)),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFFECE7DE),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    icon: const Icon(Icons.arrow_back, color: AppColors.claudeTextoPrincipal),
                    label: const Text('Anterior', style: TextStyle(color: AppColors.claudeTextoPrincipal)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.claudeBorde),
                      backgroundColor: AppColors.claudeSuperficieSuave.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _indiceActual < _ejercicios.length - 1
                        ? () => _cambiarEjercicio(_indiceActual + 1)
                        : null,
                    icon: const Icon(Icons.arrow_forward, color: AppColors.claudeTextoPrincipal),
                    label: const Text('Siguiente', style: TextStyle(color: AppColors.claudeTextoPrincipal)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.claudeBorde),
                      backgroundColor: AppColors.claudeSuperficieSuave.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
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
      ),
    );
  }

  Widget _construirBotonModo(ModoEvaluacion modo) {
    return TextButton.icon(
      onPressed: _alternarModoEvaluacion,
      icon: Icon(
        modo == ModoEvaluacion.offline ? Icons.cloud_off : Icons.cloud_done,
        color: modo == ModoEvaluacion.offline ? Colors.orangeAccent : const Color(0xFF68D391),
      ),
      label: Text(
        modo == ModoEvaluacion.offline ? 'OFFLINE' : 'ONLINE',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: modo == ModoEvaluacion.offline ? Colors.orangeAccent : const Color(0xFF68D391),
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
          const Text('Selecciona una opción:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.claudeTextoPrincipal)),
          const SizedBox(height: 8),
          ...ejercicio.opciones.map((op) {
            final estaSeleccionada = _opcionSeleccionadaId == op.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: estaSeleccionada
                    ? AppColors.claudeTerracota.withValues(alpha: 0.15)
                    : AppColors.claudeSuperficie.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: estaSeleccionada ? AppColors.claudeTerracota : AppColors.claudeBorde,
                  width: estaSeleccionada ? 1.8 : 1,
                ),
              ),
              child: ListTile(
                leading: Icon(
                  estaSeleccionada ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: estaSeleccionada ? AppColors.claudeTerracota : AppColors.claudeTextoSecundario,
                ),
                title: Text(op.texto, style: const TextStyle(color: AppColors.claudeTextoPrincipal)),
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
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.claudeTextoPrincipal),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controladorTexto,
            style: const TextStyle(color: AppColors.claudeTextoPrincipal),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.claudeSuperficieSuave,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.claudeBorde),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.claudeBorde),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.claudeTerracota, width: 1.8),
              ),
              hintText: 'Tu respuesta...',
              hintStyle: const TextStyle(color: AppColors.claudeTextoSecundario),
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
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.claudeTextoPrincipal),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controladorTexto,
            maxLines: 5,
            style: const TextStyle(color: AppColors.claudeTextoPrincipal),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.claudeSuperficieSuave,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.claudeBorde),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.claudeBorde),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.claudeTerracota, width: 1.8),
              ),
              hintText: 'Escribe paso a paso tu solución...',
              hintStyle: const TextStyle(color: AppColors.claudeTextoSecundario),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  /// Construye el panel con el desglose de métricas algorítmicas y retroalimentación
  Widget _construirPanelResultado(ResultadoEvaluacion res) {
    final color = res.esCorrecto ? const Color(0xFF68D391) : (res.puntaje > 0.0 ? Colors.orangeAccent : Colors.redAccent);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.claudeSuperficie.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18.0),
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
          const Divider(height: 20, color: AppColors.claudeBorde),
          Text(
            res.retroalimentacion,
            style: const TextStyle(fontSize: 15, color: AppColors.claudeTextoPrincipal),
          ),
          if (res.similitudHibrida > 0) ...[
            const SizedBox(height: 12),
            const Text(
              'Métricas del Motor de Similitud:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.claudeTextoPrincipal),
            ),
            const SizedBox(height: 6),
            Text('• Similitud Híbrida Global: ${(res.similitudHibrida * 100).toStringAsFixed(1)}%', style: const TextStyle(color: AppColors.claudeTextoSecundario)),
            Text('• Levenshtein (distancia de edición): ${(res.similitudLevenshtein * 100).toStringAsFixed(1)}%', style: const TextStyle(color: AppColors.claudeTextoSecundario)),
            Text('• Jaccard (tokens y n-gramas): ${(res.similitudJaccard * 100).toStringAsFixed(1)}%', style: const TextStyle(color: AppColors.claudeTextoSecundario)),
            Text('• Coseno TF-IDF (relevancia semántica): ${(res.similitudCoseno * 100).toStringAsFixed(1)}%', style: const TextStyle(color: AppColors.claudeTextoSecundario)),
          ],
          if (res.palabrasClaveEncontradas.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '✓ Conceptos detectados: ${res.palabrasClaveEncontradas.join(", ")}',
              style: const TextStyle(color: Color(0xFF68D391), fontWeight: FontWeight.w500),
            ),
          ],
          if (res.palabrasClaveFaltantes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '✗ Conceptos faltantes: ${res.palabrasClaveFaltantes.join(", ")}',
              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500),
            ),
          ],
          if (!res.esCorrecto && res.errorDetectado != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.claudeSuperficieSuave,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
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
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.claudeTerracota.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          res.errorDetectado!.severidad.etiqueta,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.claudeTerracota),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '💡 Consejo Didáctico: ${res.errorDetectado!.sugerenciaPedagogica}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.claudeTextoPrincipal),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
