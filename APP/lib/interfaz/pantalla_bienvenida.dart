// ============================================================
// pantalla_bienvenida.dart — Pantalla de Bienvenida / Inicio
//
// Estética: Cuaderno físico moderno reinterpretado digitalmente
//   • Tipografía Impact para títulos de alto impacto visual
//   • Tipografía Times New Roman MT para descripción editorial concisa
//   • Paleta cromática: Crema (#F7F0DF), Naranja (#F28C28), Negro (#171717) y Rojo (#D9534F)
//   • Fondo tipo hoja de cuaderno con líneas horizontales tenues y margen rojo
//   • Cero círculos decorativos innecesarios
//   • Título rotativo multi-idioma con transición suave
//   • Bloque de acceso limpio: Iniciar Sesión vs Crear Cuenta
//   • Responsive fluido (Desktop a 2 columnas, Mobile en columna única)
//   • Detección automática de tema claro/oscuro del sistema
// ============================================================

import 'package:flutter/material.dart';

import '../datos/servicio_auth.dart';
import 'bienvenida/modelo_saludo_bienvenida.dart';
import 'bienvenida/tema_cuaderno.dart';
import 'bienvenida/widgets/bloque_autenticacion.dart';
import 'bienvenida/widgets/detalles_decorativos_cuaderno.dart';
import 'bienvenida/widgets/fondo_cuaderno.dart';
import 'bienvenida/widgets/texto_bienvenida_rotativo.dart';

/// Pantalla de bienvenida con identidad visual de cuaderno escolar / editorial moderno.
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

              // En móvil dejamos espacio después de la línea roja (44px) + margen
              // En desktop dejamos espacio después de la línea roja (68px) + margen
              final double leftPadding = isDesktop ? 96.0 : 64.0;
              final double rightPadding = isDesktop ? 64.0 : 28.0;
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

  /// Distribución Desktop / Pantallas amplias (2 columnas con abundante espacio negativo)
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

  /// Distribución Mobile / Pantallas compactas (Columna única fluida con scroll de seguridad)
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
