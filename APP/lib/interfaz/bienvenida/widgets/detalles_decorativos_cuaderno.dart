// ============================================================
// detalles_decorativos_cuaderno.dart — Descripción editorial concisa
//
// Muestra únicamente una breve descripción en Times New Roman MT,
// manteniendo la pantalla limpia, sin ruido textual ni sobrecargas.
// ============================================================

import 'package:flutter/material.dart';

import '../tema_cuaderno.dart';
import '../tipografia_cuaderno.dart';

/// Descripción concisa para la pantalla de bienvenida.
class DetallesDecorativosCuaderno extends StatelessWidget {
  const DetallesDecorativosCuaderno({super.key, required this.tema});

  final TemaCuaderno tema;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Text(
        'Plataforma de práctica y aprendizaje matemático.',
        style: TipografiaCuaderno.timesNewRoman(
          color: tema.secondaryText,
          fontSize: 16.0,
          height: 1.45,
        ),
      ),
    );
  }
}
