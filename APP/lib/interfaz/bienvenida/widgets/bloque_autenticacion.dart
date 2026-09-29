// ============================================================
// bloque_autenticacion.dart — Bloque de acciones de acceso
//
// Jerarquía visual clara:
//   1. Botón Principal: "Iniciar Sesión" — Naranja sólido (#F28C28),
//      bordes limpios (no píldora gigante), contraste accesible.
//   2. Acción Secundaria: "Crear Cuenta" — Estilo secundario refinado,
//      borde fino y tipografía nítida.
//
// Integración directa con el flujo de navegación hacia PantallaAutenticacion.
// ============================================================

import 'package:flutter/material.dart';

import '../../../datos/servicio_auth.dart';
import '../../pantalla_autenticacion.dart';
import '../tema_cuaderno.dart';
import '../tipografia_cuaderno.dart';

/// Bloque con botones de autenticación con jerarquía visual cuidada y estética editorial.
class BloqueAutenticacion extends StatelessWidget {
  const BloqueAutenticacion({
    super.key,
    required this.tema,
    required this.servicioAuth,
    this.anchoMaximo = 340.0,
    this.alIniciarSesion,
    this.alCrearCuenta,
  });

  final TemaCuaderno tema;
  final ServicioAuth servicioAuth;
  final double anchoMaximo;
  final VoidCallback? alIniciarSesion;
  final VoidCallback? alCrearCuenta;

  void _navegarAAuth(BuildContext context, {required bool modoLogin}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PantallaAutenticacion(
          servicioAuth: servicioAuth,
          modoLoginInicial: modoLogin,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: anchoMaximo),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Botón Principal: Iniciar Sesión (Dominante, naranja, bordes limpios)
          _BotonPrincipalAcceso(
            label: 'Iniciar Sesión',
            tema: tema,
            onPressed:
                alIniciarSesion ??
                () => _navegarAAuth(context, modoLogin: true),
          ),
          const SizedBox(height: 12),

          // 2. Acción Secundaria: Crear Cuenta (Subordinada visualmente, borde fino)
          _BotonSecundarioAcceso(
            label: 'Crear Cuenta',
            tema: tema,
            onPressed:
                alCrearCuenta ?? () => _navegarAAuth(context, modoLogin: false),
          ),
        ],
      ),
    );
  }
}

/// Botón principal con alta jerarquía visual, fondo naranja y bordes rectangulares suaves.
class _BotonPrincipalAcceso extends StatefulWidget {
  const _BotonPrincipalAcceso({
    required this.label,
    required this.tema,
    required this.onPressed,
  });

  final String label;
  final TemaCuaderno tema;
  final VoidCallback onPressed;

  @override
  State<_BotonPrincipalAcceso> createState() => _BotonPrincipalAccesoState();
}

class _BotonPrincipalAccesoState extends State<_BotonPrincipalAcceso> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.tema.primaryButton,
            borderRadius: BorderRadius.circular(
              6,
            ), // Estética moderna, bordes firmes
            boxShadow: _hovered && !_pressed
                ? [
                    BoxShadow(
                      color: widget.tema.primaryButton.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : const [],
          ),
          transform: Matrix4.diagonal3Values(
            _pressed ? 0.985 : 1.0,
            _pressed ? 0.985 : 1.0,
            1.0,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Impact',
                      fontFamilyFallback: const [
                        'Anton',
                        'Trebuchet MS',
                        'sans-serif',
                      ],
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: widget.tema.primaryButtonText,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: widget.tema.primaryButtonText,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón secundario con menor jerarquía visual, fondo transparente y borde delgado.
class _BotonSecundarioAcceso extends StatefulWidget {
  const _BotonSecundarioAcceso({
    required this.label,
    required this.tema,
    required this.onPressed,
  });

  final String label;
  final TemaCuaderno tema;
  final VoidCallback onPressed;

  @override
  State<_BotonSecundarioAcceso> createState() => _BotonSecundarioAccesoState();
}

class _BotonSecundarioAccesoState extends State<_BotonSecundarioAcceso> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 46),
          side: BorderSide(
            color: _hovered
                ? widget.tema.primaryButton
                : widget.tema.secondaryButtonBorder,
            width: 1.2,
          ),
          backgroundColor: _hovered
              ? widget.tema.primaryButton.withValues(alpha: 0.08)
              : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: widget.onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.label,
              style: TipografiaCuaderno.timesNewRoman(
                color: widget.tema.secondaryButtonText,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
