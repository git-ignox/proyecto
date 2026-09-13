import 'package:flutter/material.dart';
import '../../dominio/modelos/aritmetico.dart';

/// Widget visual unificado para renderizar operaciones aritméticas en:
/// - Formato vertical escolar (columna y galera tradicional de división).
/// - Formato corto horizontal (en línea).
/// - Formato fracción.
class WidgetAritmetica extends StatefulWidget {
  const WidgetAritmetica({
    super.key,
    required this.ejercicio,
    required this.controladorTexto,
    this.controladorResto,
    this.controladorOperador,
    this.onRespuestaCambiada,
  });

  final Aritmetico ejercicio;
  final TextEditingController controladorTexto;
  final TextEditingController? controladorResto;
  final TextEditingController? controladorOperador;
  final VoidCallback? onRespuestaCambiada;

  @override
  State<WidgetAritmetica> createState() => _WidgetAritmeticaState();
}

class _WidgetAritmeticaState extends State<WidgetAritmetica> {
  @override
  Widget build(BuildContext context) {
    final ej = widget.ejercicio;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          children: [
            // Encabezado con etiqueta de modo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.indigo.shade200),
                  ),
                  child: Text(
                    _obtenerEtiquetaModo(ej),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade700,
                    ),
                  ),
                ),
                Text(
                  'Incógnita: ${_nombreIncognita(ej.incognita)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Renderizado del cuerpo según disposición y operación
            Center(
              child: _construirCuerpoOperacion(ej),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  String _obtenerEtiquetaModo(Aritmetico ej) {
    if (ej.disposicion == DisposicionAritmetica.fraccion) return 'Formato Fracción';
    if (ej.disposicion == DisposicionAritmetica.horizontal) return 'Formato Corto';
    return ej.operacion == OperacionAritmetica.division ? 'División Tradicional (Galera)' : 'Formato Vertical';
  }

  String _nombreIncognita(ElementoIncognita inc) {
    switch (inc) {
      case ElementoIncognita.resultado:
        return 'Resultado (c)';
      case ElementoIncognita.operando1:
      case ElementoIncognita.dividendo:
        return 'Primer término (a)';
      case ElementoIncognita.operando2:
      case ElementoIncognita.divisor:
        return 'Segundo término (b)';
      case ElementoIncognita.operador:
        return 'Operador (+, -, ×, ÷)';
      case ElementoIncognita.cociente:
        return 'Cociente (c)';
      case ElementoIncognita.resto:
        return 'Resto (d)';
    }
  }

  Widget _construirCuerpoOperacion(Aritmetico ej) {
    if (ej.disposicion == DisposicionAritmetica.fraccion) {
      return _construirFraccion(ej);
    }

    if (ej.disposicion == DisposicionAritmetica.horizontal) {
      return _construirHorizontal(ej);
    }

    // Formato Vertical
    if (ej.operacion == OperacionAritmetica.division) {
      return _construirDivisionGalera(ej);
    }

    return _construirVerticalEstandar(ej);
  }

  /// 1. Formato Vertical Estándar (Suma, Resta, Multiplicación)
  Widget _construirVerticalEstandar(Aritmetico ej) {
    final aEsIncognita = ej.incognita == ElementoIncognita.operando1;
    final bEsIncognita = ej.incognita == ElementoIncognita.operando2;
    final opEsIncognita = ej.incognita == ElementoIncognita.operador;
    final cEsIncognita = ej.incognita == ElementoIncognita.resultado;

    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Fila 1: Operando 1 (a)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: aEsIncognita
                ? _construirCasillaInput(widget.controladorTexto, ancho: 100)
                : _textoGrande(_formatear(ej.operando1)),
          ),
          const SizedBox(height: 8),

          // Fila 2: Operador + Operando 2 (b)
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              opEsIncognita
                  ? _construirSelectorOperador()
                  : _textoGrande(ej.operacion.simbolo, color: Colors.indigo, esNegrita: true),
              const SizedBox(width: 16),
              bEsIncognita
                  ? _construirCasillaInput(widget.controladorTexto, ancho: 100)
                  : _textoGrande(_formatear(ej.operando2)),
              const SizedBox(width: 8),
            ],
          ),

          // Línea divisoria de la operación
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            height: 3,
            color: Colors.black87,
          ),

          // Fila 3: Resultado (c)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: cEsIncognita
                ? _construirCasillaInput(widget.controladorTexto, ancho: 120, destacado: true)
                : _textoGrande(_formatear(ej.resultadoExacto), color: Colors.teal.shade800),
          ),
        ],
      ),
    );
  }

  /// 2. Formato de División en Galera / Cajón Tradicional
  Widget _construirDivisionGalera(Aritmetico ej) {
    final aEsIncognita = ej.incognita == ElementoIncognita.dividendo || ej.incognita == ElementoIncognita.operando1;
    final bEsIncognita = ej.incognita == ElementoIncognita.divisor || ej.incognita == ElementoIncognita.operando2;
    final cEsIncognita = ej.incognita == ElementoIncognita.cociente || ej.incognita == ElementoIncognita.resultado;
    final dEsIncognita = ej.incognita == ElementoIncognita.resto;

    final tieneResto = ej.restoEsperado != null && ej.restoEsperado! > 0;

    return IntrinsicWidth(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Lado izquierdo: Dividendo (a) arriba y Resto (d) abajo
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: aEsIncognita
                    ? _construirCasillaInput(widget.controladorTexto, ancho: 90)
                    : _textoGrande(_formatear(ej.operando1)),
              ),
              const SizedBox(height: 12),
              // Resto (d)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: dEsIncognita
                    ? _construirCasillaInput(widget.controladorTexto, ancho: 80, etiqueta: 'Resto')
                    : (widget.controladorResto != null && cEsIncognita && tieneResto
                        ? _construirCasillaInput(widget.controladorResto!, ancho: 80, etiqueta: 'Resto')
                        : _textoGrande(
                            ej.restoEsperado != null ? '${ej.restoEsperado}' : '0',
                            color: Colors.purple.shade700,
                            tamano: 22,
                          )),
              ),
            ],
          ),

          // Lado derecho: Galera con divisor (b) arriba y cociente (c) abajo
          Container(
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.black87, width: 3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Divisor (b)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: bEsIncognita
                      ? _construirCasillaInput(widget.controladorTexto, ancho: 80)
                      : _textoGrande(_formatear(ej.operando2)),
                ),
                // Barra horizontal inferior de la galera
                Container(
                  height: 3,
                  width: 120,
                  color: Colors.black87,
                ),
                // Cociente (c)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: cEsIncognita
                      ? _construirCasillaInput(widget.controladorTexto, ancho: 90, destacado: true, etiqueta: 'Cociente')
                      : _textoGrande(_formatear(ej.resultadoExacto), color: Colors.indigo.shade800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Formato Corto / Horizontal (a op b = c)
  Widget _construirHorizontal(Aritmetico ej) {
    final aEsIncognita = ej.incognita == ElementoIncognita.operando1;
    final bEsIncognita = ej.incognita == ElementoIncognita.operando2;
    final opEsIncognita = ej.incognita == ElementoIncognita.operador;
    final cEsIncognita = ej.incognita == ElementoIncognita.resultado || ej.incognita == ElementoIncognita.cociente;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        // a
        aEsIncognita
            ? _construirCasillaInput(widget.controladorTexto, ancho: 80)
            : _textoGrande(_formatear(ej.operando1)),

        // op
        opEsIncognita
            ? _construirSelectorOperador()
            : _textoGrande(ej.operacion.simbolo, color: Colors.indigo, esNegrita: true),

        // b
        bEsIncognita
            ? _construirCasillaInput(widget.controladorTexto, ancho: 80)
            : _textoGrande(_formatear(ej.operando2)),

        // =
        _textoGrande('=', color: Colors.grey.shade700),

        // c
        cEsIncognita
            ? _construirCasillaInput(widget.controladorTexto, ancho: 90, destacado: true)
            : _textoGrande(_formatear(ej.resultadoExacto), color: Colors.teal.shade800),
      ],
    );
  }

  /// 4. Formato Fracción (a / b = c)
  Widget _construirFraccion(Aritmetico ej) {
    final aEsIncognita = ej.incognita == ElementoIncognita.operando1 || ej.incognita == ElementoIncognita.dividendo;
    final bEsIncognita = ej.incognita == ElementoIncognita.operando2 || ej.incognita == ElementoIncognita.divisor;
    final cEsIncognita = ej.incognita == ElementoIncognita.resultado || ej.incognita == ElementoIncognita.cociente;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Fracción (a / b)
        IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Numerador (a)
              aEsIncognita
                  ? _construirCasillaInput(widget.controladorTexto, ancho: 80)
                  : _textoGrande(_formatear(ej.operando1)),
              // Línea de fracción
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                height: 3,
                width: 90,
                color: Colors.black87,
              ),
              // Denominador (b)
              bEsIncognita
                  ? _construirCasillaInput(widget.controladorTexto, ancho: 80)
                  : _textoGrande(_formatear(ej.operando2)),
            ],
          ),
        ),

        const SizedBox(width: 16),
        _textoGrande('=', color: Colors.grey.shade700),
        const SizedBox(width: 16),

        // Resultado (c)
        cEsIncognita
            ? _construirCasillaInput(widget.controladorTexto, ancho: 90, destacado: true)
            : _textoGrande(_formatear(ej.resultadoExacto), color: Colors.teal.shade800),
      ],
    );
  }

  /// Casilla interactiva con diseño estilizado para rellenar la incógnita
  Widget _construirCasillaInput(
    TextEditingController controller, {
    double ancho = 90,
    bool destacado = false,
    String? etiqueta,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (etiqueta != null) ...[
          Text(etiqueta, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          const SizedBox(height: 2),
        ],
        Container(
          width: ancho,
          decoration: BoxDecoration(
            color: destacado ? Colors.amber.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: destacado ? Colors.orange.shade700 : Colors.indigo,
              width: 2,
            ),
          ),
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: Colors.indigo,
            ),
            decoration: const InputDecoration(
              hintText: '?',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            ),
            onChanged: (_) {
              if (widget.onRespuestaCambiada != null) {
                widget.onRespuestaCambiada!();
              }
            },
          ),
        ),
      ],
    );
  }

  /// Selector para cuando la incógnita es el operador aritmético
  Widget _construirSelectorOperador() {
    final opciones = ['+', '-', '×', '÷'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade700, width: 2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: widget.controladorTexto.text.isNotEmpty ? widget.controladorTexto.text : null,
          hint: const Text('?', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.indigo)),
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.indigo),
          items: opciones.map((op) {
            return DropdownMenuItem(
              value: op,
              child: Text(op, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                widget.controladorTexto.text = val;
              });
              if (widget.onRespuestaCambiada != null) {
                widget.onRespuestaCambiada!();
              }
            }
          },
        ),
      ),
    );
  }

  Widget _textoGrande(
    String texto, {
    Color? color,
    double tamano = 28,
    bool esNegrita = false,
  }) {
    return Text(
      texto,
      style: TextStyle(
        fontSize: tamano,
        fontWeight: esNegrita ? FontWeight.bold : FontWeight.w600,
        fontFamily: 'monospace',
        color: color ?? Colors.black87,
      ),
    );
  }

  String _formatear(num n) {
    if (n is int || n == n.roundToDouble()) {
      return n.toInt().toString();
    }
    return n.toString();
  }
}

