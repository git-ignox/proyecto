// ============================================================
// pantalla_bienvenida.dart — Pantalla de Inicio (Glassmorphism)
//
// Traducción fiel a Flutter del diseño Figma Make "Glassmorphism
// Login Screen" con soporte completo para MODO CLARO y MODO OSCURO.
//
// Características:
//   • Modo Oscuro (#0A0804) y Modo Claro (#DCDCE2 platinum)
//   • Orbe luminoso flotante animado por física sinusoidal continua
//   • Halo difuso que reacciona según la paleta del modo
//   • Paneles de vidrio tipo baldosas (Glass Tiles) con:
//       - Esquinas redondeadas (16px) y biseles 3D realistas
//       - Reflejo especular superior/izquierdo y refracción inferior/derecha
//       - Borde interno de espesor y brillo en esquinas
//       - INTERIOR COMPLETAMENTE TRANSPARENTE para dejar ver el orbe
//       - Espaciado entre celdas para definir cada panel de vidrio
//   • Switcher de tema Claro/Oscuro en el header (Sol / Luna)
//   • Texto central rotativo multi-idioma con tipografía impactante
//   • Header con botones en cápsula de vidrio ("Iniciar sesión", "Crear cuenta")
//   • Dropdown flotante glassmorphism con formulario completo y Firebase Auth
// ============================================================

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../datos/servicio_auth.dart';
import '../dominio/modelos/usuario_app.dart';

// ── Lista de saludos ──────────────────────────────────────────────────────────
const _welcomes = [
  'Bienvenido',
  'Welcome',
  'Bienvenue',
  'Willkommen',
  'Benvenuto',
  'Bienvenida',
  '欢迎',
  'いらっしゃいませ',
  'Добро пожаловать',
  'مرحباً',
  'Bem-vindo',
  '환영합니다',
  'Hoş geldiniz',
  'Welkom',
  'Välkommen',
  'Karibu',
];

// ── Pantalla principal ────────────────────────────────────────────────────────

/// Pantalla de inicio con estética glassmorphism, soporte de modo Claro y Oscuro,
/// orbe animado, y paneles de vidrio con bordes biselados transparentes.
class PantallaBienvenida extends StatefulWidget {
  const PantallaBienvenida({super.key, required this.servicioAuth});

  final ServicioAuth servicioAuth;

  @override
  State<PantallaBienvenida> createState() => _PantallaBienvenidaState();
}

class _PantallaBienvenidaState extends State<PantallaBienvenida>
    with SingleTickerProviderStateMixin {
  // ── Modo claro / oscuro ───────────────────────────────────────────────────
  bool _isDarkMode = true;

  // ── Animación orbe ────────────────────────────────────────────────────────
  late final AnimationController _orbController;
  double _orbX = 0.30;
  double _orbY = 0.25;
  double _t = 0.0;

  // ── Texto rotativo ────────────────────────────────────────────────────────
  int _wordIdx = 0;
  bool _textVisible = true;

  // ── Panel de auth ─────────────────────────────────────────────────────────
  String? _openPanel; // null | 'login' | 'register'
  OverlayEntry? _overlayEntry;
  final _loginBtnKey = GlobalKey();
  final _registerBtnKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // Ticker continuo: actualiza posición del orbe (~60 fps)
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onTick);
    _orbController.repeat();

    _startWordRotation();
  }

  void _onTick() {
    _t += 0.008;
    setState(() {
      _orbX = 0.30 + math.sin(_t * 0.7) * 0.28;
      _orbY = 0.25 + math.cos(_t * 0.5) * 0.22;
    });
  }

  void _startWordRotation() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return false;
      setState(() => _textVisible = false);
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return false;
      setState(() {
        _wordIdx = (_wordIdx + 1) % _welcomes.length;
        _textVisible = true;
      });
      return mounted;
    });
  }

  @override
  void dispose() {
    _orbController
      ..removeListener(_onTick)
      ..dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  // ── Toggle tema ───────────────────────────────────────────────────────────
  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    // Si el dropdown está abierto, refrescarlo con el nuevo tema
    if (_openPanel != null) {
      final mode = _openPanel!;
      _closePanel();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openDropdown(mode);
      });
    }
  }

  // ── Toggle panel ──────────────────────────────────────────────────────────
  void _togglePanel(String mode) {
    if (_openPanel == mode) {
      _closePanel();
    } else {
      _closePanel();
      _openDropdown(mode);
    }
  }

  void _closePanel() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _openPanel = null);
  }

  void _openDropdown(String mode) {
    final key = mode == 'login' ? _loginBtnKey : _registerBtnKey;
    final rb = key.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null) return;

    final pos = rb.localToGlobal(Offset.zero);
    final btnSize = rb.size;
    final screenW = MediaQuery.of(context).size.width;

    setState(() => _openPanel = mode);

    _overlayEntry = OverlayEntry(
      builder: (ctx) => GestureDetector(
        onTap: _closePanel,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              top: pos.dy + btnSize.height + 8,
              right: screenW - (pos.dx + btnSize.width),
              child: GestureDetector(
                onTap: () {}, // consume taps dentro del panel
                child: _AuthDropdown(
                  mode: mode,
                  isDark: _isDarkMode,
                  servicioAuth: widget.servicioAuth,
                  onClose: _closePanel,
                )
                    .animate()
                    .fadeIn(duration: 220.ms)
                    .slideY(
                      begin: -0.06,
                      end: 0,
                      duration: 220.ms,
                      curve: Curves.easeOut,
                    ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bgColor = _isDarkMode ? const Color(0xFF0A0804) : const Color(0xFFDCDCE2);

    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        color: bgColor,
        child: Stack(
          children: [
            // 1. Orbe luminoso en movimiento
            _Orb(orbX: _orbX, orbY: _orbY, size: size, isDark: _isDarkMode),

            // 2. Halo suave secundario
            _Halo(orbX: _orbX, orbY: _orbY, size: size, isDark: _isDarkMode),

            // 3. Grilla de paneles de vidrio con bordes biselados e interior transparente
            _GlassGrid(isDark: _isDarkMode),

            // 4. Texto central rotativo multi-idioma
            _CenteredText(
              word: _welcomes[_wordIdx],
              visible: _textVisible,
              isDark: _isDarkMode,
            ),

            // 5. Header superior (Botón tema, Iniciar sesión, Crear cuenta)
            _Header(
              loginKey: _loginBtnKey,
              registerKey: _registerBtnKey,
              openPanel: _openPanel,
              isDark: _isDarkMode,
              onToggleTheme: _toggleTheme,
              onToggle: _togglePanel,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Orbe luminoso ─────────────────────────────────────────────────────────────

class _Orb extends StatelessWidget {
  const _Orb({
    required this.orbX,
    required this.orbY,
    required this.size,
    required this.isDark,
  });

  final double orbX;
  final double orbY;
  final Size size;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final vmin = math.min(size.width, size.height);
    final d = vmin * 0.52;
    final left = orbX * size.width - d / 2;
    final top = orbY * size.height - d / 2;

    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.24, -0.3),
            radius: 0.9,
            colors: isDark
                ? const [
                    Color(0xFFFFD000),
                    Color(0xFFFF7700),
                    Color(0xFFC43200),
                    Color(0xFF6B0000),
                    Colors.transparent,
                  ]
                : const [
                    Color(0xFFFFF275), // Luz cálida intensa central
                    Color(0xFFFFB703), // Ámbar dorado luminoso
                    Color(0xFFFB8500), // Naranja vibrante
                    Color(0xFFE63900), // Acento cálido suave
                    Colors.transparent,
                  ],
            stops: const [0.0, 0.28, 0.55, 0.72, 0.85],
          ),
        ),
      ),
    );
  }
}

// ── Halo difuso ───────────────────────────────────────────────────────────────

class _Halo extends StatelessWidget {
  const _Halo({
    required this.orbX,
    required this.orbY,
    required this.size,
    required this.isDark,
  });

  final double orbX;
  final double orbY;
  final Size size;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final vmin = math.min(size.width, size.height);
    final d = vmin * 0.82;
    final left = orbX * size.width - d / 2;
    final top = orbY * size.height - d / 2;

    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: isDark
                ? const [Color(0x38FF7800), Colors.transparent]
                : const [Color(0x2EFC9F1D), Colors.transparent],
            stops: const [0.0, 0.65],
          ),
        ),
      ),
    );
  }
}

// ── Grilla glassmorphism con baldosas biseladas ────────────────────────────────

class _GlassGrid extends StatelessWidget {
  const _GlassGrid({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (_, c) {
          // Cantidad dinámica de columnas/filas para que las baldosas tengan
          // tamaño táctil prominente (~110-140px) como en la captura
          final cols = (c.maxWidth / 120).round().clamp(4, 9);
          final rows = (c.maxHeight / 120).round().clamp(4, 9);
          final cw = c.maxWidth / cols;
          final ch = c.maxHeight / rows;

          return Stack(
            children: List.generate(rows * cols, (i) {
              final col = i % cols;
              final row = i ~/ cols;
              return Positioned(
                left: col * cw,
                top: row * ch,
                width: cw,
                height: ch,
                child: _GlassCell(isDark: isDark),
              );
            }),
          );
        },
      ),
    );
  }
}

// ── Celda de vidrio individual con bordes biselados e interior transparente ────

class _GlassCell extends StatelessWidget {
  const _GlassCell({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Espaciado entre paneles de vidrio para resaltar las ranuras y bordes 3D
      padding: const EdgeInsets.all(3.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: CustomPaint(
            painter: _GlassTilePainter(isDark: isDark, radius: 16.0),
            // Asegura que el interior sea 100% transparente:
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Pintor de bordes biselados y reflejos 3D para paneles de vidrio ────────────

class _GlassTilePainter extends CustomPainter {
  final bool isDark;
  final double radius;

  _GlassTilePainter({required this.isDark, this.radius = 16.0});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // 1. Sombra exterior para relieve de baldosas de vidrio
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.50)
        : Colors.black.withValues(alpha: 0.08);

    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 3.5);
    canvas.drawRRect(rrect, shadowPaint);

    // 2. Borde exterior biselado:
    //    Superior/izquierdo: brillo especular intenso
    //    Inferior/derecho: refracción oscura
    final outerGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              Colors.white.withValues(alpha: 0.65), // Brillo blanco en esquina superior
              const Color(0x60FFA03C),              // Tinte ámbar de reflexión
              const Color(0x18FFFFFF),              // Lateral translúcido
              Colors.black.withValues(alpha: 0.60), // Refracción inferior derecha
            ]
          : [
              Colors.white.withValues(alpha: 0.95), // Reflejo blanco nítido
              Colors.white.withValues(alpha: 0.55), // Borde reflectante claro
              const Color(0x12000000),              // Fondo sutil
              Colors.black.withValues(alpha: 0.22), // Sombra de refracción
            ],
      stops: const [0.0, 0.25, 0.60, 1.0],
    );

    final outerStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..shader = outerGradient.createShader(rect);

    canvas.drawRRect(rrect, outerStrokePaint);

    // 3. Borde interior secundario (espesor del vidrio):
    final innerRect = rect.deflate(1.8);
    final innerRRect = RRect.fromRectAndRadius(
      innerRect,
      Radius.circular(math.max(0, radius - 1.8)),
    );

    final innerGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              Colors.white.withValues(alpha: 0.35),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.40),
            ]
          : [
              Colors.white.withValues(alpha: 0.80),
              Colors.white.withValues(alpha: 0.15),
              Colors.black.withValues(alpha: 0.12),
            ],
      stops: const [0.0, 0.45, 1.0],
    );

    final innerStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = innerGradient.createShader(innerRect);

    canvas.drawRRect(innerRRect, innerStrokePaint);

    // 4. Destello especular brillante en la curvatura de la esquina superior izquierda
    final glintPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.85)
          : Colors.white;

    final arcPath = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius - 1.2),
        math.pi,
        math.pi / 2,
      );
    canvas.drawPath(arcPath, glintPaint);
  }

  @override
  bool shouldRepaint(covariant _GlassTilePainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.radius != radius;
}

// ── Texto central rotativo ────────────────────────────────────────────────────

class _CenteredText extends StatelessWidget {
  const _CenteredText({
    required this.word,
    required this.visible,
    required this.isDark,
  });

  final String word;
  final bool visible;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final fs = (MediaQuery.of(context).size.width * 0.12).clamp(56.0, 140.0);
    final textColor = isDark ? const Color(0xFFFF8C00) : const Color(0xFFE65100);

    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 350),
            opacity: visible ? 1.0 : 0.0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 350),
              offset: visible ? Offset.zero : const Offset(0, 0.06),
              child: Text(
                word,
                style: TextStyle(
                  fontFamily: 'Impact',
                  fontSize: fs,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: fs * -0.02,
                  height: 1,
                  shadows: isDark
                      ? const [
                          Shadow(color: Color(0x80FF8C00), blurRadius: 60),
                          Shadow(
                            color: Color(0x99000000),
                            offset: Offset(0, 2),
                            blurRadius: 30,
                          ),
                        ]
                      : const [
                          Shadow(color: Color(0x50FF8C00), blurRadius: 40),
                          Shadow(
                            color: Color(0x20000000),
                            offset: Offset(0, 2),
                            blurRadius: 15,
                          ),
                        ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header con botones de acción y alternador de tema ─────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.loginKey,
    required this.registerKey,
    required this.openPanel,
    required this.isDark,
    required this.onToggleTheme,
    required this.onToggle,
  });

  final GlobalKey loginKey;
  final GlobalKey registerKey;
  final String? openPanel;
  final bool isDark;
  final VoidCallback onToggleTheme;
  final void Function(String) onToggle;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Botón selector de Modo Claro / Modo Oscuro
              _ThemeToggleButton(
                isDark: isDark,
                onToggle: onToggleTheme,
              ),
              const SizedBox(width: 12),

              // Botón Iniciar sesión
              _HeaderButton(
                key: loginKey,
                label: 'Iniciar sesión',
                isActive: openPanel == 'login',
                isDark: isDark,
                onTap: () => onToggle('login'),
              ),
              const SizedBox(width: 10),

              // Botón Crear cuenta
              _HeaderButton(
                key: registerKey,
                label: 'Crear cuenta',
                isActive: openPanel == 'register',
                isDark: isDark,
                onTap: () => onToggle('register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Botón Switcher de Modo Claro / Oscuro ─────────────────────────────────────

class _ThemeToggleButton extends StatefulWidget {
  const _ThemeToggleButton({
    required this.isDark,
    required this.onToggle,
  });

  final bool isDark;
  final VoidCallback onToggle;

  @override
  State<_ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<_ThemeToggleButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isDark
        ? (_hovered ? Colors.white : const Color(0x66FFFFFF))
        : (_hovered ? const Color(0xFF1E1B18) : const Color(0x401E1B18));

    final iconColor = widget.isDark
        ? (_hovered ? const Color(0xFFFFB703) : const Color(0xD9FFFFFF))
        : (_hovered ? const Color(0xFFDB4406) : const Color(0xCC1E1B18));

    final bgColor = widget.isDark
        ? (_hovered ? const Color(0x1AFFFFFF) : const Color(0x0DFFFFFF))
        : (_hovered ? const Color(0x18000000) : const Color(0x0A000000));

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: widget.isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
        child: GestureDetector(
          onTap: widget.onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
              border: Border.all(color: borderColor),
            ),
            child: Icon(
              widget.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 18,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Botón cápsula del header ──────────────────────────────────────────────────

class _HeaderButton extends StatefulWidget {
  const _HeaderButton({
    super.key,
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_HeaderButton> createState() => _HeaderButtonState();
}

class _HeaderButtonState extends State<_HeaderButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final highlight = widget.isActive || _hovered;

    final borderColor = widget.isDark
        ? (highlight ? Colors.white : const Color(0x8CFFFFFF))
        : (highlight ? const Color(0xFF1E1B18) : const Color(0x4D1E1B18));

    final textColor = widget.isDark
        ? (highlight ? Colors.white : const Color(0xBFFFFFFF))
        : (highlight ? const Color(0xFF1E1B18) : const Color(0x991E1B18));

    final bgColor = widget.isDark
        ? (highlight ? const Color(0x1AFFFFFF) : Colors.transparent)
        : (highlight ? const Color(0x14000000) : Colors.transparent);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: bgColor,
            border: Border.all(color: borderColor),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: textColor,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Dropdown de autenticación ─────────────────────────────────────────────────

class _AuthDropdown extends StatefulWidget {
  const _AuthDropdown({
    required this.mode,
    required this.isDark,
    required this.servicioAuth,
    required this.onClose,
  });

  final String mode;
  final bool isDark;
  final ServicioAuth servicioAuth;
  final VoidCallback onClose;

  @override
  State<_AuthDropdown> createState() => _AuthDropdownState();
}

class _AuthDropdownState extends State<_AuthDropdown> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nombreCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() fn) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await fn();
      widget.onClose();
    } catch (e) {
      setState(() => _error = _fmt(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(String e) {
    if (e.contains('user-not-found') ||
        e.contains('wrong-password') ||
        e.contains('invalid-credential')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (e.contains('email-already-in-use')) {
      return 'Ya existe una cuenta con este correo.';
    }
    if (e.contains('weak-password')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (e.contains('invalid-email')) return 'El formato de correo no es válido.';
    return e.replaceAll('Exception: ', '').replaceAll('firebase_auth/', '');
  }

  void _submit() {
    if (widget.mode == 'login') {
      _run(() => widget.servicioAuth.loginConEmail(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
          ));
    } else {
      if (_passCtrl.text != _confirmCtrl.text) {
        setState(() => _error = 'Las contraseñas no coinciden.');
        return;
      }
      _run(() => widget.servicioAuth.registroConEmail(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
            nombre: _nombreCtrl.text.trim(),
            rol: RolUsuario.alumno,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    final panelBg = isDark
        ? const Color(0xD10C0804)
        : const Color(0xEEF8F7F5);

    final panelBorder = isDark
        ? const Color(0x1FFFFFFF)
        : const Color(0x26000000);

    final panelShadow = isDark
        ? const Color(0xB2000000)
        : const Color(0x26000000);

    final dividerColor = isDark
        ? Colors.white.withAlpha(25)
        : const Color(0x20000000);

    final dividerTextColor = isDark
        ? Colors.white24
        : const Color(0x601E1B18);

    final forgotPassColor = isDark
        ? const Color(0x99FFA03C)
        : const Color(0xFFC43800);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: panelBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: panelBorder),
            boxShadow: [
              BoxShadow(
                color: panelShadow,
                blurRadius: 70,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Campos ────────────────────────────────────────────────────
              if (widget.mode == 'register') ...[
                _Label('Nombre', isDark: isDark),
                const SizedBox(height: 5),
                _GlassInput(ctrl: _nombreCtrl, hint: 'Tu nombre', isDark: isDark),
                const SizedBox(height: 12),
              ],
              _Label('Correo', isDark: isDark),
              const SizedBox(height: 5),
              _GlassInput(
                ctrl: _emailCtrl,
                hint: 'hola@ejemplo.com',
                type: TextInputType.emailAddress,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _Label('Contraseña', isDark: isDark),
              const SizedBox(height: 5),
              _GlassInput(
                ctrl: _passCtrl,
                hint: '••••••••',
                obscure: true,
                isDark: isDark,
              ),
              if (widget.mode == 'register') ...[
                const SizedBox(height: 12),
                _Label('Confirmar contraseña', isDark: isDark),
                const SizedBox(height: 5),
                _GlassInput(
                  ctrl: _confirmCtrl,
                  hint: '••••••••',
                  obscure: true,
                  isDark: isDark,
                ),
              ],

              // ── Olvidé contraseña ─────────────────────────────────────────
              if (widget.mode == 'login') ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {},
                    child: Text(
                      '¿Olvidaste tu contraseña?',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: forgotPassColor,
                        decoration: TextDecoration.underline,
                        decorationColor: forgotPassColor,
                      ),
                    ),
                  ),
                ),
              ],

              // ── Error ─────────────────────────────────────────────────────
              if (_error != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0x30FF4400),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x50FF4400)),
                  ),
                  child: Text(
                    _error!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark ? const Color(0xFFFF8060) : const Color(0xFFC62828),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // ── Botón principal ───────────────────────────────────────────
              _GlassButton(
                label: widget.mode == 'login' ? 'Entrar' : 'Crear cuenta',
                loading: _loading,
                isDark: isDark,
                onTap: _loading ? null : _submit,
              ),

              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: Divider(color: dividerColor, thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('o', style: GoogleFonts.inter(fontSize: 11, color: dividerTextColor)),
                ),
                Expanded(child: Divider(color: dividerColor, thickness: 1)),
              ]),
              const SizedBox(height: 14),

              // ── Botón Google ──────────────────────────────────────────────
              _GlassButton(
                label: 'Continuar con Google',
                loading: false,
                isDark: isDark,
                onTap: _loading
                    ? null
                    : () => _run(() => widget.servicioAuth.loginConGoogle()),
                icon: const _GoogleIcon(),
                subtle: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Subwidgets del dropdown ───────────────────────────────────────────────────

class _Label extends StatelessWidget {
  const _Label(this.text, {required this.isDark});
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 10,
        letterSpacing: 1.5,
        color: isDark ? const Color(0x59FFFFFF) : const Color(0x8C1E1B18),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _GlassInput extends StatefulWidget {
  const _GlassInput({
    required this.ctrl,
    required this.hint,
    required this.isDark,
    this.obscure = false,
    this.type = TextInputType.text,
  });

  final TextEditingController ctrl;
  final String hint;
  final bool isDark;
  final bool obscure;
  final TextInputType type;

  @override
  State<_GlassInput> createState() => _GlassInputState();
}

class _GlassInputState extends State<_GlassInput> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    final bgColor = isDark
        ? const Color(0x12FFFFFF)
        : const Color(0x0A000000);

    final borderColor = _focused
        ? (isDark ? const Color(0x80FF8C00) : const Color(0xFFDB4406))
        : (isDark ? const Color(0x26FFFFFF) : const Color(0x20000000));

    final textColor = isDark ? Colors.white : const Color(0xFF1E1B18);
    final hintColor = isDark ? const Color(0x40FFFFFF) : const Color(0x591E1B18);

    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: bgColor,
          border: Border.all(color: borderColor),
        ),
        child: TextField(
          controller: widget.ctrl,
          obscureText: widget.obscure,
          keyboardType: widget.type,
          style: GoogleFonts.inter(fontSize: 13, color: textColor),
          cursorColor: isDark ? const Color(0xFFFF8C00) : const Color(0xFFDB4406),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: GoogleFonts.inter(fontSize: 13, color: hintColor),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatefulWidget {
  const _GlassButton({
    required this.label,
    required this.loading,
    required this.isDark,
    required this.onTap,
    this.icon,
    this.subtle = false,
  });

  final String label;
  final bool loading;
  final bool isDark;
  final VoidCallback? onTap;
  final Widget? icon;
  final bool subtle;

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final highlight = _hovered || !widget.subtle;

    final borderColor = isDark
        ? (highlight
            ? (widget.subtle ? const Color(0x80FFFFFF) : const Color(0x8CFFFFFF))
            : const Color(0x33FFFFFF))
        : (highlight
            ? (widget.subtle ? const Color(0xFF1E1B18) : const Color(0xFFDB4406))
            : const Color(0x28000000));

    final textColor = isDark
        ? (highlight
            ? (widget.subtle ? const Color(0xCCFFFFFF) : const Color(0xD9FFFFFF))
            : const Color(0x8CFFFFFF))
        : (highlight
            ? (widget.subtle ? const Color(0xFF1E1B18) : const Color(0xFFDB4406))
            : const Color(0x8C1E1B18));

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.loading
                ? [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? Colors.white54 : const Color(0xFFDB4406),
                      ),
                    ),
                  ]
                : [
                    if (widget.icon != null) ...[
                      widget.icon!,
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}

// ── Ícono Google en 4 colores vectoriales ─────────────────────────────────────

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 15,
      height: 15,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeW = size.width * 0.22;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeW / 2);

    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.butt;

    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.butt;

    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.butt;

    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.butt;

    // Arcos del logo 'G'
    canvas.drawArc(rect, -math.pi * 0.80, math.pi * 0.55, false, redPaint);
    canvas.drawArc(rect, -math.pi * 1.35, math.pi * 0.55, false, yellowPaint);
    canvas.drawArc(rect, -math.pi * 1.90, math.pi * 0.55, false, greenPaint);
    canvas.drawArc(rect, -math.pi * 0.25, math.pi * 0.35, false, bluePaint);

    // Barra horizontal del 'G'
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.butt;

    canvas.drawLine(
      Offset(center.dx - 1, center.dy),
      Offset(size.width - strokeW / 4, center.dy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
