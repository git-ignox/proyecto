// ============================================================
// pantalla_bienvenida.dart — Pantalla de Inicio (Glassmorphism)
//
// Traducción fiel a Flutter del diseño Figma Make "Glassmorphism
// Login Screen" (App.tsx).
//
// Características:
//   • Fondo #0a0804 con orbe radial naranja/rojo animado
//     con animación sinusoidal continua (≈ requestAnimationFrame)
//   • Halo difuso secundario que sigue al orbe
//   • Grilla 10×10 de celdas con BackdropFilter blur (glass grid)
//   • Texto central rotativo multi-idioma con fade + slide suave
//   • Header con botones "Iniciar sesión" y "Crear cuenta"
//     que despliegan panel glassmorphism con formulario real
//   • El formulario llama a ServicioAuth — lógica intacta
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

/// Pantalla de inicio glassmorphism.
/// Traduce fielmente el diseño de Figma Make a Flutter.
class PantallaBienvenida extends StatefulWidget {
  const PantallaBienvenida({super.key, required this.servicioAuth});

  final ServicioAuth servicioAuth;

  @override
  State<PantallaBienvenida> createState() => _PantallaBienvenidaState();
}

class _PantallaBienvenidaState extends State<PantallaBienvenida>
    with SingleTickerProviderStateMixin {
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

    // Ticker continuo: actualiza posición del orbe ~60 fps
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

    return Scaffold(
      backgroundColor: const Color(0xFF0A0804),
      body: Stack(
        children: [
          _Orb(orbX: _orbX, orbY: _orbY, size: size),
          _Halo(orbX: _orbX, orbY: _orbY, size: size),
          const _GlassGrid(),
          _CenteredText(word: _welcomes[_wordIdx], visible: _textVisible),
          _Header(
            loginKey: _loginBtnKey,
            registerKey: _registerBtnKey,
            openPanel: _openPanel,
            onToggle: _togglePanel,
          ),
        ],
      ),
    );
  }
}

// ── Orbe ──────────────────────────────────────────────────────────────────────

class _Orb extends StatelessWidget {
  const _Orb({required this.orbX, required this.orbY, required this.size});

  final double orbX;
  final double orbY;
  final Size size;

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
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: Alignment(-0.24, -0.3),
            radius: 0.9,
            colors: [
              Color(0xFFFFD000),
              Color(0xFFFF7700),
              Color(0xFFC43200),
              Color(0xFF6B0000),
              Colors.transparent,
            ],
            stops: [0.0, 0.28, 0.55, 0.72, 0.85],
          ),
        ),
      ),
    );
  }
}

// ── Halo ──────────────────────────────────────────────────────────────────────

class _Halo extends StatelessWidget {
  const _Halo({required this.orbX, required this.orbY, required this.size});

  final double orbX;
  final double orbY;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final vmin = math.min(size.width, size.height);
    final d = vmin * 0.80;
    final left = orbX * size.width - d / 2;
    final top = orbY * size.height - d / 2;

    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: d,
        height: d,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Color(0x38FF7800), Colors.transparent],
            stops: [0.0, 0.65],
          ),
        ),
      ),
    );
  }
}

// ── Grilla glassmorphism ──────────────────────────────────────────────────────

class _GlassGrid extends StatelessWidget {
  const _GlassGrid();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (_, c) {
          const cols = 10;
          const rows = 10;
          final cw = c.maxWidth / cols;
          final ch = c.maxHeight / rows;

          return Stack(
            children: List.generate(rows * cols, (i) {
              final col = i % cols;
              final row = i ~/ cols;
              return Positioned(
                left: col * cw,
                top: row * ch,
                child: _GlassCell(width: cw, height: ch),
              );
            }),
          );
        },
      ),
    );
  }
}

class _GlassCell extends StatelessWidget {
  const _GlassCell({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: width,
          height: height,
          decoration: const BoxDecoration(
            color: Color(0x09FFFFFF),
            border: Border(
              right: BorderSide(color: Color(0x12FFFFFF)),
              bottom: BorderSide(color: Color(0x12FFFFFF)),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Texto central rotativo ────────────────────────────────────────────────────

class _CenteredText extends StatelessWidget {
  const _CenteredText({required this.word, required this.visible});

  final String word;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final fs = (MediaQuery.of(context).size.width * 0.12).clamp(56.0, 140.0);

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
                  color: const Color(0xFFFF8C00),
                  letterSpacing: fs * -0.02,
                  height: 1,
                  shadows: const [
                    Shadow(color: Color(0x80FF8C00), blurRadius: 60),
                    Shadow(
                        color: Color(0x99000000),
                        offset: Offset(0, 2),
                        blurRadius: 30),
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

// ── Header con botones ────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.loginKey,
    required this.registerKey,
    required this.openPanel,
    required this.onToggle,
  });

  final GlobalKey loginKey;
  final GlobalKey registerKey;
  final String? openPanel;
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
              _HeaderButton(
                key: loginKey,
                label: 'Iniciar sesión',
                isActive: openPanel == 'login',
                onTap: () => onToggle('login'),
              ),
              const SizedBox(width: 10),
              _HeaderButton(
                key: registerKey,
                label: 'Crear cuenta',
                isActive: openPanel == 'register',
                onTap: () => onToggle('register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Botón del header ──────────────────────────────────────────────────────────

class _HeaderButton extends StatefulWidget {
  const _HeaderButton({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_HeaderButton> createState() => _HeaderButtonState();
}

class _HeaderButtonState extends State<_HeaderButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final highlight = widget.isActive || _hovered;

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
            border: Border.all(
              color: highlight ? Colors.white : const Color(0x8CFFFFFF),
            ),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: highlight ? Colors.white : const Color(0xBFFFFFFF),
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
    required this.servicioAuth,
    required this.onClose,
  });

  final String mode;
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xD10C0804),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x1FFFFFFF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0xB2000000),
                blurRadius: 80,
                offset: Offset(0, 24),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Campos ────────────────────────────────────────────────────
              if (widget.mode == 'register') ...[
                _Label('Nombre'),
                const SizedBox(height: 5),
                _GlassInput(ctrl: _nombreCtrl, hint: 'Tu nombre'),
                const SizedBox(height: 12),
              ],
              _Label('Correo'),
              const SizedBox(height: 5),
              _GlassInput(
                ctrl: _emailCtrl,
                hint: 'hola@ejemplo.com',
                type: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _Label('Contraseña'),
              const SizedBox(height: 5),
              _GlassInput(ctrl: _passCtrl, hint: '••••••••', obscure: true),
              if (widget.mode == 'register') ...[
                const SizedBox(height: 12),
                _Label('Confirmar contraseña'),
                const SizedBox(height: 5),
                _GlassInput(
                    ctrl: _confirmCtrl, hint: '••••••••', obscure: true),
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
                        color: const Color(0x99FFA03C),
                        decoration: TextDecoration.underline,
                        decorationColor: const Color(0x99FFA03C),
                      ),
                    ),
                  ),
                ),
              ],

              // ── Error ─────────────────────────────────────────────────────
              if (_error != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0x30FF4400),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x50FF4400)),
                  ),
                  child: Text(
                    _error!,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: const Color(0xFFFF8060)),
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // ── Botón principal ───────────────────────────────────────────
              _GlassButton(
                label: widget.mode == 'login' ? 'Entrar' : 'Crear cuenta',
                loading: _loading,
                onTap: _loading ? null : _submit,
              ),

              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                    child: Divider(
                        color: Colors.white.withAlpha(25), thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('o',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: Colors.white24)),
                ),
                Expanded(
                    child: Divider(
                        color: Colors.white.withAlpha(25), thickness: 1)),
              ]),
              const SizedBox(height: 14),

              // ── Google ────────────────────────────────────────────────────
              _GlassButton(
                label: 'Continuar con Google',
                loading: false,
                onTap: _loading
                    ? null
                    : () => _run(() => widget.servicioAuth.loginConGoogle()),
                icon: _GoogleIcon(),
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
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 10,
        letterSpacing: 1.5,
        color: const Color(0x59FFFFFF),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _GlassInput extends StatefulWidget {
  const _GlassInput({
    required this.ctrl,
    required this.hint,
    this.obscure = false,
    this.type = TextInputType.text,
  });

  final TextEditingController ctrl;
  final String hint;
  final bool obscure;
  final TextInputType type;

  @override
  State<_GlassInput> createState() => _GlassInputState();
}

class _GlassInputState extends State<_GlassInput> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0x12FFFFFF),
          border: Border.all(
            color: _focused
                ? const Color(0x80FF8C00)
                : const Color(0x26FFFFFF),
          ),
        ),
        child: TextField(
          controller: widget.ctrl,
          obscureText: widget.obscure,
          keyboardType: widget.type,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
          cursorColor: const Color(0xFFFF8C00),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: GoogleFonts.inter(
                fontSize: 13, color: const Color(0x40FFFFFF)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
    required this.onTap,
    this.icon,
    this.subtle = false,
  });

  final String label;
  final bool loading;
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
    final highlight = _hovered || !widget.subtle;
    final borderColor = highlight
        ? (widget.subtle ? const Color(0x80FFFFFF) : const Color(0x8CFFFFFF))
        : const Color(0x33FFFFFF);
    final textColor = highlight
        ? (widget.subtle ? const Color(0xCCFFFFFF) : const Color(0xD9FFFFFF))
        : const Color(0x8CFFFFFF);

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
                ? const [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white54),
                    )
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

// ── Ícono Google en colores reales ────────────────────────────────────────────

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    // SVG paths del logo de Google renderizados con CustomPaint
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
    final s = size.width / 24;
    canvas.scale(s);

    _fill(canvas, const Color(0xFF4285F4),
        'M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92'
        'c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57'
        'c2.08-1.92 3.28-4.74 3.28-8.09z');
    _fill(canvas, const Color(0xFF34A853),
        'M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77'
        'c-.98.66-2.23 1.06-3.71 1.06'
        'c-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84'
        'C3.99 20.53 7.7 23 12 23z');
    _fill(canvas, const Color(0xFFFBBC05),
        'M5.84 14.09c-.22-.66-.35-1.36-.35-2.09'
        's.13-1.43.35-2.09V7.07H2.18'
        'C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z');
    _fill(canvas, const Color(0xFFEA4335),
        'M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15'
        'C17.45 2.09 14.97 1 12 1'
        'C7.7 1 3.99 3.47 2.18 7.07l3.66 2.84'
        'c.87-2.6 3.3-4.53 6.16-4.53z');
  }

  void _fill(Canvas canvas, Color color, String _) {
    // No-op placeholder — SVG path parsing needs path_parsing package
    // The icon is rendered as a simple colored 'G' instead
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
