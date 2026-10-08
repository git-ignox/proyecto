// ============================================================
// claude_auth_components.dart — Componentes con estética oficial de Claude
//
// Incluye:
//   • ClaudeAsteriskLogo: Logo insignia de sol/asterisco en terracota Crail (#D97757)
//   • ClaudePrimaryButton: Botón principal sólido crema/hueso (#ECE7DE) con texto oscuro (#1E1D1B)
//   • ClaudeSecondaryButton: Botón secundario de vidrio oscuro con borde hairline
//   • GoogleBrandIcon: Icono geométrico vectorial oficial de Google multicolor (G)
//   • ClaudeTermsFooter: Texto legal tipo "By continuing, you acknowledge..."
//   • ClaudeFaqAccordion: Acordeón de preguntas frecuentes como en la foto
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Logo geométrico de Claude (Asterisco / Flor de 8 pétalos en Terracota #D97757)
class ClaudeAsteriskLogo extends StatelessWidget {
  const ClaudeAsteriskLogo({
    super.key,
    this.size = 28.0,
    this.color = const Color(0xFFD97757),
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ClaudeAsteriskPainter(color: color),
      ),
    );
  }
}

class _ClaudeAsteriskPainter extends CustomPainter {
  const _ClaudeAsteriskPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final rayWidth = size.width * 0.16;
    final rayLength = size.width * 0.44;

    // Dibuja los 8 rayos con bordes redondeados
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi) / 4;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, -rayLength * 0.5),
          width: rayWidth,
          height: rayLength,
        ),
        Radius.circular(rayWidth / 2),
      );
      canvas.drawRRect(rrect, paint);
      canvas.restore();
    }

    // Círculo central para suavizar las intersecciones
    canvas.drawCircle(center, rayWidth * 0.9, paint);
  }

  @override
  bool shouldRepaint(covariant _ClaudeAsteriskPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Icono vectorial nítido con los 4 colores oficiales de Google
class GoogleBrandIcon extends StatelessWidget {
  const GoogleBrandIcon({super.key, this.size = 18.0});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.22;

    final paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final paintYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // Arcos de los colores de Google
    // Rojo: superior
    canvas.drawArc(rect, -math.pi * 0.75, math.pi * 0.60, false, paintRed);
    // Amarillo: inferior izquierdo
    canvas.drawArc(rect, -math.pi * 0.15 - math.pi, math.pi * 0.45, false, paintYellow);
    // Verde: inferior derecho
    canvas.drawArc(rect, math.pi * 0.25, math.pi * 0.55, false, paintGreen);
    // Azul: arco lateral derecho
    canvas.drawArc(rect, -math.pi * 0.20, math.pi * 0.45, false, paintBlue);

    // Barra horizontal azul del centro de la 'G'
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final barRect = Rect.fromLTWH(
      center.dx - strokeWidth * 0.1,
      center.dy - strokeWidth * 0.5,
      radius,
      strokeWidth,
    );
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Botón Principal Claude: Sólido crema/hueso (#ECE7DE) con texto oscuro (#1E1D1B)
/// Apariencia idéntica a "Continuar con correo electrónico" de las imágenes.
class ClaudePrimaryButton extends StatefulWidget {
  const ClaudePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height = 48.0,
    this.borderRadius = 12.0,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double height;
  final double borderRadius;

  @override
  State<ClaudePrimaryButton> createState() => _ClaudePrimaryButtonState();
}

class _ClaudePrimaryButtonState extends State<ClaudePrimaryButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    // Tono crema sólido de Claude
    const baseCream = Color(0xFFECE7DE);
    const hoverCream = Color(0xFFF6F3EC);
    const darkTextColor = Color(0xFF1E1D1B);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: isEnabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: isEnabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: widget.height,
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(
            _pressed ? 0.985 : 1.0,
            _pressed ? 0.985 : 1.0,
            1.0,
          ),
          decoration: BoxDecoration(
            color: isEnabled
                ? (_hovered ? hoverCream : baseCream)
                : baseCream.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: _hovered && isEnabled && !_pressed
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: darkTextColor,
                    ),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, size: 18, color: darkTextColor),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: GoogleFonts.plusJakartaSans(
                            color: darkTextColor,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
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

/// Botón Secundario Claude: Vidrio oscuro con borde fino y texto claro
/// Apariencia idéntica a "Continuar con Google" / "Continuar con Apple" de las imágenes.
class ClaudeSecondaryButton extends StatefulWidget {
  const ClaudeSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.customLeading,
    this.icon,
    this.height = 48.0,
    this.borderRadius = 12.0,
    this.accentBorderColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? customLeading;
  final IconData? icon;
  final double height;
  final double borderRadius;
  final Color? accentBorderColor;

  @override
  State<ClaudeSecondaryButton> createState() => _ClaudeSecondaryButtonState();
}

class _ClaudeSecondaryButtonState extends State<ClaudeSecondaryButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;

    final baseBg = Colors.white.withValues(alpha: 0.08);
    final hoverBg = Colors.white.withValues(alpha: 0.13);
    final borderColor = widget.accentBorderColor ??
        (_hovered ? Colors.white.withValues(alpha: 0.24) : Colors.white.withValues(alpha: 0.14));

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: isEnabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: isEnabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: widget.height,
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(
            _pressed ? 0.985 : 1.0,
            _pressed ? 0.985 : 1.0,
            1.0,
          ),
          decoration: BoxDecoration(
            color: _hovered ? hoverBg : baseBg,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.customLeading != null) ...[
                    widget.customLeading!,
                    const SizedBox(width: 10),
                  ] else if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: 19,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    widget.label,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                    ),
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

/// Separador "o" sutil con líneas hairline
class ClaudeDivider extends StatelessWidget {
  const ClaudeDivider({super.key, this.label = 'o'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 0.8,
            color: Colors.white.withValues(alpha: 0.14),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.40),
              fontSize: 12.0,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 0.8,
            color: Colors.white.withValues(alpha: 0.14),
          ),
        ),
      ],
    );
  }
}

/// Pie legal discreto: "By continuing, you acknowledge..."
class ClaudeTermsFooter extends StatelessWidget {
  const ClaudeTermsFooter({
    super.key,
    this.text = 'Al continuar, aceptas la Política de Privacidad y Términos de Servicio.',
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.plusJakartaSans(
        color: Colors.white.withValues(alpha: 0.45),
        fontSize: 11.0,
        height: 1.35,
      ),
    );
  }
}

/// Acordeón de Preguntas Frecuentes estilo Claude (como en la foto 2 del usuario)
class ClaudeFaqAccordion extends StatefulWidget {
  const ClaudeFaqAccordion({super.key});

  @override
  State<ClaudeFaqAccordion> createState() => _ClaudeFaqAccordionState();
}

class _ClaudeFaqAccordionState extends State<ClaudeFaqAccordion> {
  int? _abiertoIndex;

  final _preguntas = const [
    (
      titulo: '¿Cómo funciona el acceso para alumnos y docentes?',
      detalle:
          'Los alumnos pueden practicar y rendir evaluaciones diagnósticas adaptativas, mientras que los docentes supervisan el progreso del aula en tiempo real.',
    ),
    (
      titulo: '¿Funciona sin conexión a internet?',
      detalle:
          'Sí, la plataforma cuenta con soporte offline completo para materiales y prácticas semanales con sincronización automática al conectarse.',
    ),
    (
      titulo: '¿Qué credenciales puedo usar para ingresar?',
      detalle:
          'Podés ingresar con tu correo y contraseña registrados, mediante Google Sign-In, o utilizar el acceso rápido de demostración.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preguntas frecuentes',
          style: GoogleFonts.lora(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_preguntas.length, (i) {
          final item = _preguntas[i];
          final estaAbierto = _abiertoIndex == i;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.8,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() {
                _abiertoIndex = estaAbierto ? null : i;
              }),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.titulo,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(
                          estaAbierto ? Icons.remove : Icons.add,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ],
                    ),
                    if (estaAbierto) ...[
                      const SizedBox(height: 8),
                      Text(
                        item.detalle,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withValues(alpha: 0.60),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
