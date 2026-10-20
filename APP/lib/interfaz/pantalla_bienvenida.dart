import 'package:flutter/material.dart';

import '../datos/servicio_auth.dart';
import 'bienvenida/modelo_saludo_bienvenida.dart';
import 'bienvenida/tema_cuaderno.dart';
import 'bienvenida/widgets/bloque_autenticacion.dart';
import 'bienvenida/widgets/detalles_decorativos_cuaderno.dart';
import 'bienvenida/widgets/texto_bienvenida_rotativo.dart';
import 'design/app_colors.dart';
import 'widgets/mac_glass_widgets.dart';

/// Pantalla de bienvenida con estética macOS glassmorphism adaptativa (modo claro y oscuro).
class PantallaBienvenida extends StatelessWidget {
  const PantallaBienvenida({
    super.key,
    required this.servicioAuth,
    this.catalogoSaludos = CatalogoSaludosBienvenida.listaPorDefecto,
  });

  final ServicioAuth servicioAuth;
  final List<SaludoBienvenida> catalogoSaludos;

  @override
  Widget build(BuildContext context) {
    final tema = TemaCuaderno.of(context);

    return Scaffold(
      backgroundColor: AppColors.fondo(context),
      body: MacDesktopBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 768;

              final double leftPadding = isDesktop ? 88.0 : 32.0;
              final double rightPadding = isDesktop ? 54.0 : 24.0;
              final double verticalPadding = isDesktop ? 48.0 : 24.0;

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  leftPadding,
                  verticalPadding,
                  rightPadding,
                  verticalPadding,
                ),
                child: isDesktop
                    ? _buildDistribucionDesktop(context, tema)
                    : _buildDistribucionMobile(context, tema),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Distribución Desktop (2 columnas con balance editorial y abundante espacio negativo)
  Widget _buildDistribucionDesktop(BuildContext context, TemaCuaderno tema) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Columna izquierda: Título rotativo + Descripción concisa
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextoBienvenidaRotativo(tema: tema, saludos: catalogoSaludos),
                const SizedBox(height: 16),
                DetallesDecorativosCuaderno(tema: tema),
              ],
            ),
          ),
        ),

        const SizedBox(width: 48),

        // Columna derecha: Bloque de autenticación con glow glass posterior
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: MacGlassContainer(
            borderRadius: 22,
            padding: const EdgeInsets.all(26),
            child: BloqueAutenticacion(
              tema: tema,
              servicioAuth: servicioAuth,
              anchoMaximo: 340,
            ),
          ),
        ),
      ],
    );
  }

  /// Distribución Mobile (Columna única con scroll seguro)
  Widget _buildDistribucionMobile(BuildContext context, TemaCuaderno tema) {
    return LayoutBuilder(
      builder: (context, viewportConstraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: viewportConstraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  TextoBienvenidaRotativo(tema: tema, saludos: catalogoSaludos),
                  const SizedBox(height: 14),
                  DetallesDecorativosCuaderno(tema: tema),
                  const Spacer(),
                  const SizedBox(height: 32),
                  // Panel de acceso con glow glass posterior
                  MacGlassContainer(
                    borderRadius: 22,
                    padding: const EdgeInsets.all(22),
                    child: BloqueAutenticacion(
                      tema: tema,
                      servicioAuth: servicioAuth,
                      anchoMaximo: double.infinity,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


