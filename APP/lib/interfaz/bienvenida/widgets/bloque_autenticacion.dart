// ============================================================
// bloque_autenticacion.dart — Botones con panel flotante tipo Claude
//
// Comportamiento:
//   • Dos botones: "Iniciar Sesión" y "Crear Cuenta"
//   • Al tocar un botón, aparece un panel flotante (Overlay) debajo
//     de los botones — sin mover el contenido de arriba
//   • El panel contiene el formulario completo con auth directa
//   • Botón "Continuar con Google" dentro del formulario
//   • Estética minimalista tipo Claude: campos limpios, bordes sutiles,
//     fondo tipo papel, sin colores agresivos salvo el CTA
//   • Solo un panel abierto a la vez; cerrar al tocar fuera
// ============================================================

import 'package:flutter/material.dart';

import '../../../datos/servicio_auth.dart';
import '../../../dominio/modelos/usuario_app.dart';
import '../tema_cuaderno.dart';
import '../tipografia_cuaderno.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Widget público principal
// ─────────────────────────────────────────────────────────────────────────────

/// Dos botones con panel flotante de formulario. No navega a otra pantalla.
class BloqueAutenticacion extends StatefulWidget {
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

  @override
  State<BloqueAutenticacion> createState() => _BloqueAutenticacionState();
}

class _BloqueAutenticacionState extends State<BloqueAutenticacion> {
  // null = ninguno activo
  bool? _panelAbierto; // true = login, false = registro

  // Keys para medir posición de los botones
  final _keyLogin = GlobalKey();
  final _keyRegistro = GlobalKey();

  OverlayEntry? _overlayEntry;

  void _abrirPanel(bool esLogin) {
    // Si el mismo panel está abierto, lo cerramos
    if (_panelAbierto == esLogin) {
      _cerrarPanel();
      return;
    }

    _cerrarPanel(notifyState: false);
    setState(() => _panelAbierto = esLogin);

    // Calculamos la posición del botón en pantalla
    final key = esLogin ? _keyLogin : _keyRegistro;
    final renderBox =
        key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenSize = MediaQuery.sizeOf(context);
    final panelAncho = (widget.anchoMaximo).clamp(0.0, screenSize.width - 32);

    _overlayEntry = OverlayEntry(
      builder: (ctx) => _PanelFlotante(
        tema: widget.tema,
        esLogin: esLogin,
        servicioAuth: widget.servicioAuth,
        anchoPanel: panelAncho,
        // Posicionamos debajo del botón
        top: offset.dy + size.height + 6,
        left: offset.dx.clamp(16.0, screenSize.width - panelAncho - 16),
        onCerrar: _cerrarPanel,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _cerrarPanel({bool notifyState = true}) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (notifyState && mounted) setState(() => _panelAbierto = null);
  }

  @override
  void dispose() {
    _cerrarPanel(notifyState: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.anchoMaximo),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Botón Iniciar Sesión ────────────────────────────────────────
          _BtnAcceso(
            key: _keyLogin,
            label: 'Iniciar Sesión',
            tema: widget.tema,
            esPrincipal: true,
            activo: _panelAbierto == true,
            onPressed: () => _abrirPanel(true),
          ),

          const SizedBox(height: 10),

          // ── Botón Crear Cuenta ──────────────────────────────────────────
          _BtnAcceso(
            key: _keyRegistro,
            label: 'Crear Cuenta',
            tema: widget.tema,
            esPrincipal: false,
            activo: _panelAbierto == false,
            onPressed: () => _abrirPanel(false),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Botón de acceso (desencadena el panel)
// ─────────────────────────────────────────────────────────────────────────────

class _BtnAcceso extends StatefulWidget {
  const _BtnAcceso({
    super.key,
    required this.label,
    required this.tema,
    required this.esPrincipal,
    required this.activo,
    required this.onPressed,
  });

  final String label;
  final TemaCuaderno tema;
  final bool esPrincipal;
  final bool activo;
  final VoidCallback onPressed;

  @override
  State<_BtnAcceso> createState() => _BtnAccesoState();
}

class _BtnAccesoState extends State<_BtnAcceso> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.activo || _hovered;

    Color bg;
    Color textColor;
    Border? border;

    if (widget.esPrincipal) {
      // Botón primario: fondo sólido naranja → crema cuando activo, tinta oscura
      bg = widget.tema.primaryButton;
      textColor = widget.tema.primaryButtonText;
    } else {
      // Botón secundario: sin fondo, borde fino
      bg = isActive
          ? widget.tema.primaryButton.withValues(alpha: 0.10)
          : Colors.transparent;
      textColor = widget.tema.secondaryButtonText;
      border = Border.all(
        color: isActive
            ? widget.tema.primaryButton.withValues(alpha: 0.55)
            : widget.tema.secondaryButtonBorder,
        width: 1.1,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(7),
            border: border,
            boxShadow: widget.esPrincipal && isActive
                ? [
                    BoxShadow(
                      color: widget.tema.primaryButton.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Impact',
                  fontFamilyFallback: const [
                    'Anton',
                    'Trebuchet MS',
                    'sans-serif',
                  ],
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(width: 6),
              AnimatedRotation(
                duration: const Duration(milliseconds: 200),
                turns: widget.activo ? 0.5 : 0.0,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: textColor.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Panel flotante (Overlay) con formulario completo — estética Claude
// ─────────────────────────────────────────────────────────────────────────────

class _PanelFlotante extends StatefulWidget {
  const _PanelFlotante({
    required this.tema,
    required this.esLogin,
    required this.servicioAuth,
    required this.anchoPanel,
    required this.top,
    required this.left,
    required this.onCerrar,
  });

  final TemaCuaderno tema;
  final bool esLogin;
  final ServicioAuth servicioAuth;
  final double anchoPanel;
  final double top;
  final double left;
  final VoidCallback onCerrar;

  @override
  State<_PanelFlotante> createState() => _PanelFlotanteState();
}

class _PanelFlotanteState extends State<_PanelFlotante>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Formulario Login
  final _formLoginKey = GlobalKey<FormState>();
  final _emailLoginCtrl = TextEditingController();
  final _passLoginCtrl = TextEditingController();
  bool _verPassLogin = false;

  // Formulario Registro
  final _formRegKey = GlobalKey<FormState>();
  final _nombreRegCtrl = TextEditingController();
  final _emailRegCtrl = TextEditingController();
  final _passRegCtrl = TextEditingController();
  bool _verPassReg = false;
  RolUsuario _rolReg = RolUsuario.alumno;

  // Estado general
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _emailLoginCtrl.dispose();
    _passLoginCtrl.dispose();
    _nombreRegCtrl.dispose();
    _emailRegCtrl.dispose();
    _passRegCtrl.dispose();
    super.dispose();
  }

  Future<void> _ejecutar(Future<void> Function() accion) async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await accion();
      widget.onCerrar();
    } catch (e) {
      setState(() => _error = _formatear(e.toString()));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _formatear(String e) {
    if (e.contains('user-not-found') ||
        e.contains('wrong-password') ||
        e.contains('invalid-credential')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (e.contains('email-already-in-use')) { return 'Ya existe una cuenta con este correo.'; }
    if (e.contains('weak-password')) { return 'La contraseña debe tener al menos 6 caracteres.'; }
    if (e.contains('invalid-email')) { return 'El formato de correo no es válido.'; }
    if (e.contains('GIDClientID') || e.contains('No active configuration')) {
      return 'Google requiere configuración adicional. Usá correo/contraseña.';
    }
    if (e.contains('cancelado')) { return 'Inicio con Google cancelado.'; }
    return e.replaceAll('Exception: ', '').replaceAll('firebase_auth/', '');
  }

  // ── Colores del panel según tema ──────────────────────────────────────────
  Color get _panelBg =>
      widget.tema.isDark ? const Color(0xFF1C1C1C) : const Color(0xFFFAF6ED);
  Color get _panelBorder =>
      widget.tema.isDark ? const Color(0xFF2E2E2E) : const Color(0xFFDDD6C8);
  Color get _inputBg =>
      widget.tema.isDark ? const Color(0xFF252525) : const Color(0xFFF2EDE0);
  Color get _inputBorder =>
      widget.tema.isDark ? const Color(0xFF3A3A3A) : const Color(0xFFCEC8BB);
  Color get _labelColor => widget.tema.secondaryText;
  Color get _textColor => widget.tema.primaryText;
  Color get _placeholderColor =>
      widget.tema.isDark ? const Color(0xFF666666) : const Color(0xFFAAAAAA);
  Color get _dividerColor =>
      widget.tema.isDark ? const Color(0xFF2E2E2E) : const Color(0xFFDDD6C8);
  Color get _googleBg =>
      widget.tema.isDark ? const Color(0xFF252525) : Colors.white;
  Color get _googleBorder =>
      widget.tema.isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD0CAC0);

  @override
  Widget build(BuildContext context) {
    // Tocar fuera cierra el panel
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onCerrar,
      child: Stack(
        children: [
          Positioned(
            top: widget.top,
            left: widget.left,
            width: widget.anchoPanel,
            child: GestureDetector(
              // Evita que el tap dentro del panel cierre el overlay
              onTap: () {},
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _panelBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _panelBorder, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: widget.tema.isDark ? 0.50 : 0.14,
                            ),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: widget.esLogin
                          ? _buildFormLogin()
                          : _buildFormRegistro(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Formulario Login ─────────────────────────────────────────────────────
  Widget _buildFormLogin() {
    return Form(
      key: _formLoginKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _titulo('Iniciar Sesión'),
          const SizedBox(height: 16),
          _campo(
            ctrl: _emailLoginCtrl,
            label: 'Correo electrónico',
            hint: 'tu@correo.com',
            icon: Icons.alternate_email_rounded,
            tipo: TextInputType.emailAddress,
            accion: TextInputAction.next,
            validar: (v) =>
                (v == null || !v.contains('@')) ? 'Correo inválido' : null,
          ),
          const SizedBox(height: 10),
          _campo(
            ctrl: _passLoginCtrl,
            label: 'Contraseña',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscure: !_verPassLogin,
            accion: TextInputAction.done,
            sufijo: _iconoOjo(
              ver: _verPassLogin,
              onTap: () => setState(() => _verPassLogin = !_verPassLogin),
            ),
            validar: (v) =>
                (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
            onSubmit: (_) => _submitLogin(),
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[_bannerError(_error!), const SizedBox(height: 12)],
          _btnPrimario(
            label: 'Entrar',
            cargando: _cargando,
            onTap: _submitLogin,
          ),
          const SizedBox(height: 12),
          _divider(),
          const SizedBox(height: 12),
          _btnGoogle(),
        ],
      ),
    );
  }

  void _submitLogin() {
    if (_formLoginKey.currentState!.validate()) {
      _ejecutar(() => widget.servicioAuth.loginConEmail(
            email: _emailLoginCtrl.text.trim(),
            password: _passLoginCtrl.text,
          ));
    }
  }

  // ─── Formulario Registro ──────────────────────────────────────────────────
  Widget _buildFormRegistro() {
    return Form(
      key: _formRegKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _titulo('Crear Cuenta'),
          const SizedBox(height: 16),
          _campo(
            ctrl: _nombreRegCtrl,
            label: 'Nombre completo',
            hint: 'Tu nombre',
            icon: Icons.person_outline_rounded,
            accion: TextInputAction.next,
            validar: (v) =>
                (v == null || v.trim().isEmpty) ? 'Ingresá tu nombre' : null,
          ),
          const SizedBox(height: 10),
          _campo(
            ctrl: _emailRegCtrl,
            label: 'Correo electrónico',
            hint: 'tu@correo.com',
            icon: Icons.alternate_email_rounded,
            tipo: TextInputType.emailAddress,
            accion: TextInputAction.next,
            validar: (v) =>
                (v == null || !v.contains('@')) ? 'Correo inválido' : null,
          ),
          const SizedBox(height: 10),
          _campo(
            ctrl: _passRegCtrl,
            label: 'Contraseña',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscure: !_verPassReg,
            accion: TextInputAction.done,
            sufijo: _iconoOjo(
              ver: _verPassReg,
              onTap: () => setState(() => _verPassReg = !_verPassReg),
            ),
            validar: (v) =>
                (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
            onSubmit: (_) => _submitRegistro(),
          ),
          const SizedBox(height: 12),
          _selectorRol(),
          const SizedBox(height: 16),
          if (_error != null) ...[_bannerError(_error!), const SizedBox(height: 12)],
          _btnPrimario(
            label: 'Crear cuenta',
            cargando: _cargando,
            onTap: _submitRegistro,
          ),
          const SizedBox(height: 12),
          _divider(),
          const SizedBox(height: 12),
          _btnGoogle(),
        ],
      ),
    );
  }

  void _submitRegistro() {
    if (_formRegKey.currentState!.validate()) {
      _ejecutar(() => widget.servicioAuth.registroConEmail(
            email: _emailRegCtrl.text.trim(),
            password: _passRegCtrl.text,
            nombre: _nombreRegCtrl.text.trim(),
            rol: _rolReg,
          ));
    }
  }

  // ─── Subwidgets de UI ─────────────────────────────────────────────────────

  Widget _titulo(String texto) {
    return Text(
      texto,
      style: TipografiaCuaderno.timesNewRoman(
        color: _textColor,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );
  }

  Widget _campo({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validar,
    TextInputType tipo = TextInputType.text,
    TextInputAction accion = TextInputAction.next,
    bool obscure = false,
    Widget? sufijo,
    void Function(String)? onSubmit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TipografiaCuaderno.timesNewRoman(
            color: _labelColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.2,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: ctrl,
          keyboardType: tipo,
          textInputAction: accion,
          obscureText: obscure,
          onFieldSubmitted: onSubmit,
          validator: validar,
          style: TipografiaCuaderno.timesNewRoman(
            color: _textColor,
            fontSize: 14,
            height: 1.4,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TipografiaCuaderno.timesNewRoman(
              color: _placeholderColor,
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, size: 16, color: _placeholderColor),
            suffixIcon: sufijo,
            filled: true,
            fillColor: _inputBg,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: BorderSide(color: _inputBorder, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: BorderSide(color: _inputBorder, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: BorderSide(
                color: widget.tema.primaryButton,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: const BorderSide(color: Color(0xFFD9534F), width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: const BorderSide(color: Color(0xFFD9534F), width: 1.5),
            ),
            errorStyle: TipografiaCuaderno.timesNewRoman(
              color: const Color(0xFFD9534F),
              fontSize: 11,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _iconoOjo({required bool ver, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          ver ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 16,
          color: _placeholderColor,
        ),
      ),
    );
  }

  Widget _selectorRol() {
    final roles = [
      (RolUsuario.alumno, 'Alumno', Icons.school_outlined),
      (RolUsuario.profesor, 'Docente', Icons.assignment_ind_outlined),
      (RolUsuario.direccion, 'Dirección', Icons.account_balance_outlined),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rol',
          style: TipografiaCuaderno.timesNewRoman(
            color: _labelColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.2,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: roles.map((r) {
            final (rol, nombre, icono) = r;
            final sel = _rolReg == rol;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _rolReg = rol),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  margin: EdgeInsets.only(
                    right: rol != RolUsuario.direccion ? 6 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: sel
                        ? widget.tema.primaryButton.withValues(alpha: 0.15)
                        : _inputBg,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: sel
                          ? widget.tema.primaryButton
                          : _inputBorder,
                      width: sel ? 1.4 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        icono,
                        size: 14,
                        color: sel
                            ? widget.tema.primaryButton
                            : _placeholderColor,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        nombre,
                        style: TipografiaCuaderno.timesNewRoman(
                          color: sel ? widget.tema.primaryButton : _labelColor,
                          fontSize: 10.5,
                          fontWeight:
                              sel ? FontWeight.w700 : FontWeight.w400,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _btnPrimario({
    required String label,
    required bool cargando,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: cargando ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cargando
              ? widget.tema.primaryButton.withValues(alpha: 0.6)
              : widget.tema.primaryButton,
          borderRadius: BorderRadius.circular(7),
        ),
        child: cargando
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: widget.tema.primaryButtonText,
                ),
              )
            : Text(
                label,
                style: TipografiaCuaderno.timesNewRoman(
                  color: widget.tema.primaryButtonText,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
      ),
    );
  }

  Widget _divider() {
    return Row(
      children: [
        Expanded(child: Divider(color: _dividerColor, thickness: 1, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'o',
            style: TipografiaCuaderno.timesNewRoman(
              color: _placeholderColor,
              fontSize: 12,
              height: 1,
            ),
          ),
        ),
        Expanded(child: Divider(color: _dividerColor, thickness: 1, height: 1)),
      ],
    );
  }

  Widget _btnGoogle() {
    return _BtnGoogleAnim(
      bg: _googleBg,
      border: _googleBorder,
      textColor: _textColor,
      cargando: _cargando,
      onTap: () => _ejecutar(() => widget.servicioAuth.loginConGoogle()),
    );
  }

  Widget _bannerError(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFD9534F).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: const Color(0xFFD9534F).withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFD9534F), size: 15),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              msg,
              style: TipografiaCuaderno.timesNewRoman(
                color: const Color(0xFFD9534F),
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Botón Google con animación hover
// ─────────────────────────────────────────────────────────────────────────────

class _BtnGoogleAnim extends StatefulWidget {
  const _BtnGoogleAnim({
    required this.bg,
    required this.border,
    required this.textColor,
    required this.cargando,
    required this.onTap,
  });

  final Color bg;
  final Color border;
  final Color textColor;
  final bool cargando;
  final VoidCallback onTap;

  @override
  State<_BtnGoogleAnim> createState() => _BtnGoogleAnimState();
}

class _BtnGoogleAnimState extends State<_BtnGoogleAnim> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.cargando ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovered
                ? widget.bg.withValues(alpha: 0.85)
                : widget.bg,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: widget.border, width: 1),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo G de Google (SVG inline usando texto estilizado)
              _GoogleIcon(size: 17),
              const SizedBox(width: 8),
              Text(
                'Continuar con Google',
                style: TextStyle(
                  fontFamily: 'Trebuchet MS',
                  fontFamilyFallback: const ['Arial', 'sans-serif'],
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: widget.textColor,
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

/// Ícono G de Google dibujado con CustomPainter (sin dependencias externas).
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleIconPainter(),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final cx = r;
    final cy = r;

    final paint = Paint()..style = PaintingStyle.fill;

    // Cuadrantes de colores Google
    // Rojo (arriba-izq), Azul (arriba-der), Amarillo (abajo-izq), Verde (abajo-der)
    final sectors = [
      (const Color(0xFFEA4335), 0.0),   // rojo
      (const Color(0xFF4285F4), 0.25),  // azul (incompleto — dejamos hueco)
      (const Color(0xFFFBBC05), 0.5),   // amarillo
      (const Color(0xFF34A853), 0.75),  // verde
    ];

    final double sw = size.width * 0.38;

    for (final (color, startFrac) in sectors) {
      paint.color = color;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startFrac * 2 * 3.14159,
        0.5 * 3.14159, // 90°
        true,
        paint,
      );
    }

    // Barra horizontal derecha ("lengüeta" del G)
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - sw * 0.40, r, sw * 0.80),
      paint,
    );

    // Círculo blanco central para crear el "hueco" del G
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.60, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
