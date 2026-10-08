// ============================================================
// bloque_autenticacion.dart — Bloque de acciones de acceso tipo Claude
//
// Apariencia idéntica a Claude & macOS Glassmorphism:
//   1. Botón Principal: "Iniciar Sesión" — Sólido crema/hueso (#ECE7DE),
//      bordes limpios redondeados (12px), tipografía oscura obsidian (#1E1D1B).
//   2. Acción Secundaria: "Crear Cuenta" — Estilo vidrio oscuro traslúcido
//      con borde hairline sutil y texto claro apergaminado.
//   3. Opciones complementarias: "Continuar con Google" y Acceso rápido.
//
// Flujo integrado de navegación hacia PantallaAutenticacion.
// ============================================================

import 'package:flutter/material.dart';

import '../../../datos/servicio_auth.dart';
import '../../pantalla_autenticacion.dart';
import '../../widgets/claude_auth_components.dart';
import '../tema_cuaderno.dart';

/// Bloque con botones de autenticación con la estética Claude / macOS Glassmorphism.
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
          // 1. Botón Principal: Iniciar Sesión (Sólido crema Claude con texto carbón oscuro)
          _BotonPrincipalAcceso(
            label: 'Iniciar Sesión',
            tema: tema,
            onPressed: alIniciarSesion ?? () => _navegarAAuth(context, modoLogin: true),
          ),
          const SizedBox(height: 12),

          // 2. Acción Secundaria: Crear Cuenta (Vidrio oscuro con borde fino)
          _BotonSecundarioAcceso(
            label: 'Crear Cuenta',
            tema: tema,
            onPressed: alCrearCuenta ?? () => _navegarAAuth(context, modoLogin: false),
          ),
        ],
      ),
    );
  }
}

/// Botón principal con alta jerarquía visual: fondo crema cálido Claude (#ECE7DE)
/// y texto oscuro (#1E1D1B).
class _BotonPrincipalAcceso extends StatelessWidget {
  const _BotonPrincipalAcceso({
    required this.label,
    required this.tema,
    required this.onPressed,
  });

  final String label;
  final TemaCuaderno tema;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ClaudePrimaryButton(
      label: label,
      onPressed: onPressed,
      height: 48,
      borderRadius: 12,
    );
  }
}

/// Botón secundario: vidrio oscuro traslúcido con borde hairline y texto blanco cálido.
class _BotonSecundarioAcceso extends StatelessWidget {
  const _BotonSecundarioAcceso({
    required this.label,
    required this.tema,
    required this.onPressed,
  });

  final String label;
  final TemaCuaderno tema;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ClaudeSecondaryButton(
      label: label,
      onPressed: onPressed,
      height: 48,
      borderRadius: 12,
    );
  }
}
