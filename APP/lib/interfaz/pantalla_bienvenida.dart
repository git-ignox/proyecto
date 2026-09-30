// ============================================================
// pantalla_bienvenida.dart — Pantalla de Bienvenida / Inicio
//
// Layout unificado: Row en toda resolución
//   • Izquierda: Título rotativo + descripción (alineados al top)
//   • Derecha:   Botones de acceso uno al lado del otro (alineados al top)
//   • En pantallas muy estrechas (< 480px) colapsa a columna
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
              // Pantallas muy estrechas (< 480px) usan columna, el resto fila
              final usarFila = constraints.maxWidth >= 480;

              final double leftPadding = usarFila ? 72.0 : 52.0;
              final double rightPadding = usarFila ? 32.0 : 20.0;
              final double topPadding = 28.0;
              final double bottomPadding = 20.0;

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  leftPadding,
                  topPadding,
                  rightPadding,
                  bottomPadding,
                ),
                child: usarFila
                    ? _buildFila(tema)
                    : _buildColumna(tema),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Layout en fila: texto izquierda ↔ botones derecha, ambos alineados al top.
  Widget _buildFila(TemaCuaderno tema) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // ← alineación al top
      children: [
        // ── Columna izquierda: Título + descripción ──────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextoBienvenidaRotativo(tema: tema, saludos: catalogoSaludos),
              const SizedBox(height: 14),
              DetallesDecorativosCuaderno(tema: tema),
            ],
          ),
        ),

        const SizedBox(width: 32),

        // ── Derecha: Botones lado a lado, pegados al top ─────────────────
        BloqueAutenticacion(
          tema: tema,
          servicioAuth: servicioAuth,
          anchoMaximo: 340,
        ),
      ],
    );
  }

  /// Layout en columna para pantallas muy estrechas.
  Widget _buildColumna(TemaCuaderno tema) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextoBienvenidaRotativo(tema: tema, saludos: catalogoSaludos),
          const SizedBox(height: 14),
          DetallesDecorativosCuaderno(tema: tema),
          const SizedBox(height: 28),
          BloqueAutenticacion(
            tema: tema,
            servicioAuth: servicioAuth,
            anchoMaximo: double.infinity,
          ),
        ],
      ),
    );
  }
}
