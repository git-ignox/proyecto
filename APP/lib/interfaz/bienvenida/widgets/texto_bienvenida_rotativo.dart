// ============================================================
// texto_bienvenida_rotativo.dart — Título Impact rotativo multi-idioma
//
// Características:
//   • Tipografía Impact dominante con mayúsculas condensadas
//   • Ciclo automático entre idiomas con catálogo desacoplado
//   • Transición elegante: fade sutil + micro-desplazamiento vertical
//   • Respeto riguroso de accesibilidad (reduce-motion / disableAnimations)
//   • Control de ciclo con Timer cancelado de forma segura en dispose()
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';

import '../modelo_saludo_bienvenida.dart';
import '../tema_cuaderno.dart';
import '../tipografia_cuaderno.dart';

/// Componente que muestra el título de bienvenida ciclando suavemente entre idiomas.
class TextoBienvenidaRotativo extends StatefulWidget {
  const TextoBienvenidaRotativo({
    super.key,
    required this.tema,
    this.saludos = CatalogoSaludosBienvenida.listaPorDefecto,
    this.intervaloRotacion = const Duration(milliseconds: 3200),
    this.duracionTransicion = const Duration(milliseconds: 360),
    this.alCambiarIdioma,
  });

  final TemaCuaderno tema;
  final List<SaludoBienvenida> saludos;
  final Duration intervaloRotacion;
  final Duration duracionTransicion;
  final ValueChanged<SaludoBienvenida>? alCambiarIdioma;

  @override
  State<TextoBienvenidaRotativo> createState() =>
      _TextoBienvenidaRotativoState();
}

class _TextoBienvenidaRotativoState extends State<TextoBienvenidaRotativo>
    with SingleTickerProviderStateMixin {
  int _indiceActual = 0;
  Timer? _temporizador;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: widget.duracionTransicion,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // Desplazamiento vertical muy ligero (6% de la altura del texto) para sensación editorial
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animController,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    _animController.value = 1.0;
    _iniciarCiclo();
  }

  void _iniciarCiclo() {
    if (widget.saludos.length <= 1) return;

    _temporizador?.cancel();
    _temporizador = Timer.periodic(widget.intervaloRotacion, (_) {
      _avanzarSiguiente();
    });
  }

  Future<void> _avanzarSiguiente() async {
    if (!mounted || widget.saludos.isEmpty) return;

    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    if (reduceMotion) {
      setState(() {
        _indiceActual = (_indiceActual + 1) % widget.saludos.length;
      });
      widget.alCambiarIdioma?.call(widget.saludos[_indiceActual]);
      return;
    }

    // Salida suave (fade-out + leve subida)
    await _animController.reverse();
    if (!mounted) return;

    setState(() {
      _indiceActual = (_indiceActual + 1) % widget.saludos.length;
    });
    widget.alCambiarIdioma?.call(widget.saludos[_indiceActual]);

    // Entrada suave (fade-in + llegada a posición neutral)
    if (mounted) {
      await _animController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant TextoBienvenidaRotativo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.intervaloRotacion != widget.intervaloRotacion ||
        oldWidget.saludos != widget.saludos) {
      _iniciarCiclo();
    }
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.saludos.isEmpty) return const SizedBox.shrink();

    final saludo = widget.saludos[_indiceActual];
    final screenWidth = MediaQuery.of(context).size.width;

    // Tamaño de fuente escalado con límites cómodos y responsivos
    // En móviles: ~48-64px, en escritorio: ~72-96px
    final double tamanoFuente = screenWidth < 480
        ? 46.0
        : screenWidth < 768
        ? 58.0
        : screenWidth < 1200
        ? 74.0
        : 88.0;

    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final widgetTexto = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        saludo.texto,
        maxLines: 1,
        style: TipografiaCuaderno.impact(
          color: widget.tema.primaryText,
          fontSize: tamanoFuente,
        ),
      ),
    );

    if (reduceMotion) {
      return widgetTexto;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widgetTexto),
    );
  }
}
