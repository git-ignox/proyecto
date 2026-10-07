// ============================================================
// pantalla_bienvenida.dart — Pantalla de Bienvenida / Inicio
//
// Identidad visual: Claude / Anthropic
//   • Paleta cálida: Terracota (#D97757), pergamino (#FAF9F5 / #F7F0DF)
//   • Tipografía editorial: Lora / Times serif para bienvenida y Poppins para botones
//   • Líneas tenues y márgenes equilibrados
//   • Responsive fluido: Desktop a 2 columnas, Mobile en columna fluida
// ============================================================

import 'package:flutter/material.dart';

import '../datos/servicio_auth.dart';
import 'bienvenida/modelo_saludo_bienvenida.dart';
import 'bienvenida/tema_cuaderno.dart';
import 'bienvenida/widgets/bloque_autenticacion.dart';
import 'bienvenida/widgets/detalles_decorativos_cuaderno.dart';
import 'bienvenida/widgets/fondo_cuaderno.dart';
import 'bienvenida/widgets/texto_bienvenida_rotativo.dart';

/// Pantalla de bienvenida con estética Claude / editorial cálida.
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
      backgroundColor: tema.background,
      body: FondoCuaderno(
        tema: tema,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 768;

              final double leftPadding = isDesktop ? 88.0 : 54.0;
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
                    ? _buildDistribucionDesktop(tema)
                    : _buildDistribucionMobile(tema),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Distribución Desktop (2 columnas con balance editorial y abundante espacio negativo)
  Widget _buildDistribucionDesktop(TemaCuaderno tema) {
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

        // Columna derecha: Bloque de autenticación
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: BloqueAutenticacion(
            tema: tema,
            servicioAuth: servicioAuth,
            anchoMaximo: 320,
          ),
        ),
      ],
    );
  }

  /// Distribución Mobile (Columna única con scroll seguro)
  Widget _buildDistribucionMobile(TemaCuaderno tema) {
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
                  BloqueAutenticacion(
                    tema: tema,
                    servicioAuth: servicioAuth,
                    anchoMaximo: double.infinity,
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
