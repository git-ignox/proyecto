// ============================================================
// mac_glass_widgets.dart — Widgets nativos de macOS con Glassmorphism
//
// Incluye:
//   • MacTrafficLights: Botones de control de ventana (Rojo, Amarillo, Verde)
//   • MacCalendarWidget: Widget de calendario de macOS con glassmorphism
//   • MacWeatherWidget: Widget de clima de macOS (Cochabamba 27° soleado)
//   • MacBatteryWidget: Widget de batería y estado de dispositivos (74%)
//   • MacWidgetsSidebar: Barra lateral de widgets de macOS
//   • MacWindowFrame: Contenedor de ventana estilo macOS con blur acrílico y glow posterior
//   • MacDesktopBackground: Fondo texturizado de escritorio macOS adaptativo (noche/día)
// ============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design/app_colors.dart';

/// Botones de control de ventana de macOS (Traffic Lights: Cerrar, Minimizar, Maximizar)
class MacTrafficLights extends StatefulWidget {
  const MacTrafficLights({
    super.key,
    this.onClose,
    this.onMinimize,
    this.onMaximize,
    this.size = 12.0,
    this.spacing = 8.0,
  });

  final VoidCallback? onClose;
  final VoidCallback? onMinimize;
  final VoidCallback? onMaximize;
  final double size;
  final double spacing;

  @override
  State<MacTrafficLights> createState() => _MacTrafficLightsState();
}

class _MacTrafficLightsState extends State<MacTrafficLights> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TrafficDot(
            color: const Color(0xFFFF5F56),
            borderColor: const Color(0xFFE0443E),
            symbol: Icons.close_rounded,
            showSymbol: _hovered,
            size: widget.size,
            onTap: widget.onClose,
          ),
          SizedBox(width: widget.spacing),
          _TrafficDot(
            color: const Color(0xFFFFBD2E),
            borderColor: const Color(0xFFDEA123),
            symbol: Icons.remove_rounded,
            showSymbol: _hovered,
            size: widget.size,
            onTap: widget.onMinimize,
          ),
          SizedBox(width: widget.spacing),
          _TrafficDot(
            color: const Color(0xFF27C93F),
            borderColor: const Color(0xFF1AAB29),
            symbol: Icons.add_rounded,
            showSymbol: _hovered,
            size: widget.size,
            onTap: widget.onMaximize,
          ),
        ],
      ),
    );
  }
}

class _TrafficDot extends StatelessWidget {
  const _TrafficDot({
    required this.color,
    required this.borderColor,
    required this.symbol,
    required this.showSymbol,
    required this.size,
    this.onTap,
  });

  final Color color;
  final Color borderColor;
  final IconData symbol;
  final bool showSymbol;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 2,
              offset: const Offset(0, 0.5),
            ),
          ],
        ),
        child: Center(
          child: showSymbol
              ? Icon(
                  symbol,
                  size: size * 0.7,
                  color: Colors.black.withValues(alpha: 0.65),
                )
              : null,
        ),
      ),
    );
  }
}

/// Contenedor base de Glassmorphism estilo macOS con resplandor posterior (glow detrás del widget)
class MacGlassContainer extends StatelessWidget {
  const MacGlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = 18.0,
    this.padding = const EdgeInsets.all(16.0),
    this.blurSigma = 24.0,
    this.backgroundColor,
    this.borderColor,
    this.customGlowColor,
  });

  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double blurSigma;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? customGlowColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(borderRadius);

    final defaultBg = isDark
        ? const Color(0xFF1E1D1B).withValues(alpha: 0.82)
        : const Color(0xFFFFFDF8).withValues(alpha: 0.90);

    final defaultBorder = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : const Color(0x1F1E1D1B);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppColors.glowDetras(
          context,
          color: customGlowColor,
          blur: 38.0,
          spread: 2.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: radius,
              color: backgroundColor ?? defaultBg,
              border: Border.all(
                color: borderColor ?? defaultBorder,
                width: 1.0,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withValues(alpha: 0.09),
                        Colors.white.withValues(alpha: 0.02),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.85),
                        const Color(0xFFF9F6EE).withValues(alpha: 0.65),
                      ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Widget de Calendario de macOS adaptativo
class MacCalendarWidget extends StatelessWidget {
  const MacCalendarWidget({
    super.key,
    this.ancho = 180.0,
  });

  final double ancho;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ahora = DateTime.now();
    final diaActual = ahora.day;

    final diasSemana = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    return MacGlassContainer(
      width: ancho,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'OCTUBRE',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFFD97757),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: diasSemana.map((d) {
              return SizedBox(
                width: 18,
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.45)
                        : Colors.black.withValues(alpha: 0.45),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          _buildCalendarioFilas(diaActual, isDark),
        ],
      ),
    );
  }

  Widget _buildCalendarioFilas(int diaActual, bool isDark) {
    final semanas = [
      [null, null, null, 1, 2, 3, 4],
      [5, 6, 7, 8, 9, 10, 11],
      [12, 13, 14, 15, 16, 17, 18],
      [19, 20, 21, 22, 23, 24, 25],
    ];

    return Column(
      children: semanas.map((semana) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: semana.map((dia) {
              if (dia == null) {
                return const SizedBox(width: 18, height: 18);
              }
              final esHoy = dia == 7 || dia == diaActual;
              return Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: esHoy
                      ? (isDark ? Colors.white : const Color(0xFF1E1D1B))
                      : Colors.transparent,
                ),
                child: Center(
                  child: Text(
                    '$dia',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: esHoy ? FontWeight.w700 : FontWeight.w500,
                      color: esHoy
                          ? (isDark ? const Color(0xFF191817) : Colors.white)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.85)
                              : const Color(0xFF1E1D1B).withValues(alpha: 0.85)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

/// Widget de Clima de macOS adaptativo
class MacWeatherWidget extends StatelessWidget {
  const MacWeatherWidget({
    super.key,
    this.ancho = 180.0,
    this.ciudad = 'Cochabamba',
    this.temperatura = '27°',
    this.condicion = 'Mayormente soleado',
    this.maxima = '28°',
    this.minima = '11°',
  });

  final double ancho;
  final String ciudad;
  final String temperatura;
  final String condicion;
  final String maxima;
  final String minima;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MacGlassContainer(
      width: ancho,
      padding: const EdgeInsets.all(14),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  ciudad,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.90)
                        : const Color(0xFF1E1D1B).withValues(alpha: 0.90),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.north_east_rounded,
                size: 11,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.55)
                    : Colors.black.withValues(alpha: 0.55),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            temperatura,
            style: GoogleFonts.plusJakartaSans(
              color: isDark ? Colors.white : const Color(0xFF1E1D1B),
              fontSize: 34,
              fontWeight: FontWeight.w300,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.wb_sunny_rounded,
                size: 14,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  condicion,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.78)
                        : const Color(0xFF1E1D1B).withValues(alpha: 0.78),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Máx. $maxima  Mín. $minima',
            style: GoogleFonts.plusJakartaSans(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.48)
                  : Colors.black.withValues(alpha: 0.48),
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de Batería y Dispositivos de macOS adaptativo
class MacBatteryWidget extends StatelessWidget {
  const MacBatteryWidget({
    super.key,
    this.ancho = 180.0,
    this.porcentaje = 74,
  });

  final double ancho;
  final int porcentaje;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MacGlassContainer(
      width: ancho,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      borderRadius: 18,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDialPrincipal(isDark),
              _buildDialAccesorio(Icons.watch_rounded, isDark),
              _buildDialAccesorio(Icons.headphones_rounded, isDark),
              _buildDialAccesorio(Icons.phone_iphone_rounded, isDark),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              '$porcentaje%',
              style: GoogleFonts.plusJakartaSans(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.95)
                    : const Color(0xFF1E1D1B).withValues(alpha: 0.95),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialPrincipal(bool isDark) {
    return SizedBox(
      width: 38,
      height: 38,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: porcentaje / 100.0,
            strokeWidth: 3.5,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34C759)),
          ),
          Icon(
            Icons.laptop_mac_rounded,
            size: 16,
            color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1E1D1B),
          ),
        ],
      ),
    );
  }

  Widget _buildDialAccesorio(IconData icono, bool isDark) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.black.withValues(alpha: 0.10),
          width: 2.2,
        ),
      ),
      child: Center(
        child: Icon(
          icono,
          size: 14,
          color: isDark
              ? Colors.white.withValues(alpha: 0.35)
              : Colors.black.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

/// Columna lateral que agrupa los 3 widgets de macOS
class MacWidgetsSidebar extends StatelessWidget {
  const MacWidgetsSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MacCalendarWidget(),
        SizedBox(height: 14),
        MacWeatherWidget(),
        SizedBox(height: 14),
        MacBatteryWidget(),
      ],
    );
  }
}

/// Contenedor de Ventana estilo macOS con resplandor posterior (glow detrás) y soporte día/noche
class MacWindowFrame extends StatelessWidget {
  const MacWindowFrame({
    super.key,
    required this.child,
    this.title,
    this.anchoMaximo = 480.0,
    this.onClose,
    this.onMinimize,
    this.onMaximize,
  });

  final Widget child;
  final String? title;
  final double anchoMaximo;
  final VoidCallback? onClose;
  final VoidCallback? onMinimize;
  final VoidCallback? onMaximize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const radius = BorderRadius.all(Radius.circular(22));

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: anchoMaximo),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: AppColors.glowDetras(
            context,
            blur: 46.0,
            spread: 3.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                color: isDark
                    ? const Color(0xFF1E1D1B).withValues(alpha: 0.82)
                    : const Color(0xFFFFFDF8).withValues(alpha: 0.92),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.16)
                      : const Color(0x1F1E1D1B),
                  width: 1.0,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                          width: 0.8,
                        ),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: MacTrafficLights(
                            onClose: onClose,
                            onMinimize: onMinimize,
                            onMaximize: onMaximize,
                          ),
                        ),
                        if (title != null)
                          Text(
                            title!,
                            style: GoogleFonts.plusJakartaSans(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.65)
                                  : const Color(0xFF1E1D1B).withValues(alpha: 0.65),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                    child: child,
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

/// Fondo de escritorio de macOS adaptativo con textura y gradiente radial cálido
class MacDesktopBackground extends StatelessWidget {
  const MacDesktopBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? const Color(0xFF121110) : const Color(0xFFF9F7F1);
    final haloColors = isDark
        ? const [
            Color(0x28D97757), // Halo terracota Claude en noche
            Color(0x153A2518),
            Color(0x00121110),
          ]
        : const [
            Color(0x1FD97757), // Halo terracota suave en blanco y crema
            Color(0x0FF5EBE1),
            Color(0x00F9F7F1),
          ];

    return Stack(
      children: [
        Positioned.fill(
          child: Container(color: baseColor),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.0, -0.1),
                radius: 0.9,
                colors: haloColors,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _TexturaEscritorioPainter(isDark: isDark),
          ),
        ),
        child,
      ],
    );
  }
}

class _TexturaEscritorioPainter extends CustomPainter {
  const _TexturaEscritorioPainter({this.isDark = true});
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.018)
          : Colors.black.withValues(alpha: 0.022)
      ..strokeWidth = 1.0;

    const paso = 16.0;
    for (double x = -size.height; x < size.width; x += paso) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TexturaEscritorioPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
