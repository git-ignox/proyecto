// ============================================================
// pantalla_autenticacion.dart — Pantalla de Login / Registro
//
// Diseño: Glassmorphism futurista
//   • Fondo: esferas de luz animadas (GlowOrbBackground) +
//            grilla sutil (GridOverlay)
//   • Tarjeta: vidrio esmerilado (GlassCard) crema semi-transparente
//   • Toggle: AnimatedSwitcher fluido entre Login y Registro
//             (sin cambiar de pantalla — animación de fade+slide)
//   • Tipografía: Plus Jakarta Sans (google_fonts)
//   • Microinteracciones: flutter_animate en campos y botones
//
// Lógica Firebase: intacta desde la versión anterior.
//   ServicioAuth se recibe como dependencia; no hay lógica
//   de autenticación en este archivo — solo estado de UI.
//
// Responsive:
//   • maxWidth 440 → funciona en móvil, tablet y desktop
//   • SafeArea + scroll → no se corta en notch ni en desktop pequeño
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../datos/servicio_auth.dart';
import '../dominio/modelos/usuario_app.dart';
import 'auth/widgets/auth_text_field.dart';
import 'auth/widgets/glass_card.dart';
import 'auth/widgets/glow_orb_background.dart';
import 'auth/widgets/grid_overlay.dart';
import 'auth/widgets/primary_glow_button.dart';
import 'auth/widgets/role_selector.dart';
import 'design/app_colors.dart';
import 'design/app_text_styles.dart';

/// Pantalla de inicio de sesión y registro con estética glassmorphism.
/// Preserva toda la lógica de autenticación Firebase del diseño anterior.
class PantallaAutenticacion extends StatefulWidget {
  const PantallaAutenticacion({
    super.key,
    required this.servicioAuth,
  });

  final ServicioAuth servicioAuth;

  @override
  State<PantallaAutenticacion> createState() => _PantallaAutenticacionState();
}

class _PantallaAutenticacionState extends State<PantallaAutenticacion> {
  // ── Estado de UI ──────────────────────────────────────────────────────────
  bool _modoLogin = true;   // true = Login, false = Registro
  bool _cargando = false;
  String? _errorMensaje;

  // ── Formularios ───────────────────────────────────────────────────────────
  final _formLoginKey = GlobalKey<FormState>();
  final _formRegistroKey = GlobalKey<FormState>();

  // ── Controladores Login ───────────────────────────────────────────────────
  final _emailLoginCtrl = TextEditingController();
  final _passwordLoginCtrl = TextEditingController();
  bool _verPasswordLogin = false;

  // ── Controladores Registro ────────────────────────────────────────────────
  final _nombreRegistroCtrl = TextEditingController();
  final _emailRegistroCtrl = TextEditingController();
  final _passwordRegistroCtrl = TextEditingController();
  bool _verPasswordRegistro = false;
  RolUsuario _rolRegistro = RolUsuario.alumno;

  @override
  void dispose() {
    _emailLoginCtrl.dispose();
    _passwordLoginCtrl.dispose();
    _nombreRegistroCtrl.dispose();
    _emailRegistroCtrl.dispose();
    _passwordRegistroCtrl.dispose();
    super.dispose();
  }

  // ── Helpers Firebase ──────────────────────────────────────────────────────
  Future<void> _ejecutarAccionAuth(Future<void> Function() accion) async {
    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });
    try {
      await accion();
    } catch (e) {
      final msg = _formatearError(e.toString());
      setState(() => _errorMensaje = msg);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.naranjaOscuro,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _formatearError(String error) {
    if (error.contains('GIDClientID') ||
        error.contains('No active configuration')) {
      return 'Google Sign-In en macOS requiere Client ID de OAuth en Info.plist. Podés usar Correo o Invitado.';
    }
    if (error.contains('MissingPluginException') ||
        error.contains('platform-not-supported')) {
      return 'Método no soportado en este sistema. Usá Correo/Contraseña o Acceso Rápido.';
    }
    if (error.contains('user-not-found') ||
        error.contains('wrong-password') ||
        error.contains('invalid-credential')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (error.contains('email-already-in-use')) {
      return 'Ya existe una cuenta con este correo.';
    }
    if (error.contains('weak-password')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (error.contains('invalid-email')) {
      return 'El formato de correo no es válido.';
    }
    if (error.contains('operation-not-allowed')) {
      return 'Habilitá este método en la consola de Firebase.';
    }
    return error
        .replaceAll('Exception: ', '')
        .replaceAll('firebase_auth/', '');
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoOscuro,
      body: GlowOrbBackground(
        child: GridOverlay(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 32),
                child: ConstrainedBox(
                  // 440px máx → se ve bien en móvil, tablet y desktop
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 28),
                      _buildToggle(),
                      const SizedBox(height: 20),
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // AnimatedSwitcher: cambia entre formularios
                            // sin salir de la pantalla — fade + slide
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              transitionBuilder: (child, anim) {
                                // Desliza hacia arriba al entrar, desaparece al salir
                                final slide = Tween<Offset>(
                                  begin: const Offset(0, 0.08),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                    parent: anim, curve: Curves.easeOut));
                                return FadeTransition(
                                  opacity: anim,
                                  child: SlideTransition(
                                      position: slide, child: child),
                                );
                              },
                              child: _modoLogin
                                  ? _buildFormularioLogin()
                                  : _buildFormularioRegistro(),
                            ),

                            // Error message
                            if (_errorMensaje != null) ...[
                              const SizedBox(height: 12),
                              _buildErrorBanner(_errorMensaje!),
                            ],

                            const SizedBox(height: 24),
                            _buildDivider(),
                            const SizedBox(height: 16),
                            _buildBotonesAlternativos(),
                            const SizedBox(height: 12),
                            _buildBotonesDemo(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      children: [
        // Ícono con gradiente naranja
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [AppColors.naranjaVivo, AppColors.naranjaOscuro],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.glowNaranja,
                blurRadius: 28,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.calculate_rounded,
              size: 36, color: AppColors.crema),
        )
            .animate()
            .scale(
                begin: const Offset(0.7, 0.7),
                duration: 500.ms,
                curve: Curves.elasticOut)
            .fadeIn(duration: 300.ms),

        const SizedBox(height: 16),

        // Nombre de la app con acento naranja en la primera palabra
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.naranjaVivo, AppColors.ambar],
          ).createShader(bounds),
          child: Text(
            'App Matemáticas',
            style: AppTextStyles.display.copyWith(color: Colors.white),
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 150.ms)
            .slideY(begin: -0.1, end: 0, duration: 400.ms, delay: 150.ms),

        const SizedBox(height: 8),

        Text(
          'Plataforma educativa para alumnos, docentes\ny equipos de dirección',
          textAlign: TextAlign.center,
          style: AppTextStyles.subtitle,
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 250.ms),
      ],
    );
  }

  // ── Toggle Login / Registro ───────────────────────────────────────────────
  Widget _buildToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.crema.withAlpha(15),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: AppColors.crema.withAlpha(30),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton('Iniciar sesión', true),
          _buildToggleButton('Crear cuenta', false),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms, delay: 300.ms)
        .slideY(begin: 0.05, end: 0, duration: 350.ms, delay: 300.ms);
  }

  Widget _buildToggleButton(String label, bool isLogin) {
    final isActive = _modoLogin == isLogin;
    return GestureDetector(
      onTap: () {
        if (_modoLogin != isLogin) {
          setState(() {
            _modoLogin = isLogin;
            _errorMensaje = null;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.naranja : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.glowNaranja.withAlpha(120),
                    blurRadius: 12,
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: isActive
              ? AppTextStyles.tabActive
              : AppTextStyles.tabInactive,
        ),
      ),
    );
  }

  // ── Formulario Login ──────────────────────────────────────────────────────
  Widget _buildFormularioLogin() {
    return Form(
      key: _formLoginKey,
      child: Column(
        key: const ValueKey('login'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Bienvenido de nuevo', style: AppTextStyles.title),
          const SizedBox(height: 4),
          Text('Ingresá tus credenciales para continuar',
              style: AppTextStyles.subtitle),
          const SizedBox(height: 24),

          AuthTextField(
            controller: _emailLoginCtrl,
            label: 'Correo electrónico',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || !v.contains('@')) ? 'Ingresá un correo válido' : null,
          ),
          const SizedBox(height: 12),

          AuthTextField(
            controller: _passwordLoginCtrl,
            label: 'Contraseña',
            icon: Icons.lock_outline_rounded,
            obscureText: !_verPasswordLogin,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitLogin(),
            validator: (v) =>
                (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
            suffixIcon: IconButton(
              icon: Icon(
                _verPasswordLogin
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.crema.withAlpha(150),
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _verPasswordLogin = !_verPasswordLogin),
            ),
          ),
          const SizedBox(height: 20),

          PrimaryGlowButton(
            label: 'Iniciar sesión',
            isLoading: _cargando,
            onPressed: _cargando ? null : _submitLogin,
          ),
        ],
      ),
    );
  }

  void _submitLogin() {
    if (_formLoginKey.currentState!.validate()) {
      _ejecutarAccionAuth(() => widget.servicioAuth.loginConEmail(
            email: _emailLoginCtrl.text.trim(),
            password: _passwordLoginCtrl.text,
          ));
    }
  }

  // ── Formulario Registro ───────────────────────────────────────────────────
  Widget _buildFormularioRegistro() {
    return Form(
      key: _formRegistroKey,
      child: Column(
        key: const ValueKey('registro'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Creá tu cuenta', style: AppTextStyles.title),
          const SizedBox(height: 4),
          Text('Completá los datos para registrarte',
              style: AppTextStyles.subtitle),
          const SizedBox(height: 24),

          AuthTextField(
            controller: _nombreRegistroCtrl,
            label: 'Nombre completo',
            icon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Ingresá tu nombre'
                : null,
          ),
          const SizedBox(height: 12),

          AuthTextField(
            controller: _emailRegistroCtrl,
            label: 'Correo electrónico',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || !v.contains('@')) ? 'Ingresá un correo válido' : null,
          ),
          const SizedBox(height: 12),

          AuthTextField(
            controller: _passwordRegistroCtrl,
            label: 'Contraseña (mín. 6 caracteres)',
            icon: Icons.lock_outline_rounded,
            obscureText: !_verPasswordRegistro,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitRegistro(),
            validator: (v) =>
                (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
            suffixIcon: IconButton(
              icon: Icon(
                _verPasswordRegistro
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.crema.withAlpha(150),
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _verPasswordRegistro = !_verPasswordRegistro),
            ),
          ),
          const SizedBox(height: 20),

          RoleSelector(
            selected: _rolRegistro,
            onChanged: (rol) => setState(() => _rolRegistro = rol),
          ),
          const SizedBox(height: 20),

          PrimaryGlowButton(
            label: 'Crear cuenta',
            isLoading: _cargando,
            onPressed: _cargando ? null : _submitRegistro,
          ),
        ],
      ),
    );
  }

  void _submitRegistro() {
    if (_formRegistroKey.currentState!.validate()) {
      _ejecutarAccionAuth(() => widget.servicioAuth.registroConEmail(
            email: _emailRegistroCtrl.text.trim(),
            password: _passwordRegistroCtrl.text,
            nombre: _nombreRegistroCtrl.text.trim(),
            rol: _rolRegistro,
          ));
    }
  }

  // ── Error banner ──────────────────────────────────────────────────────────
  Widget _buildErrorBanner(String mensaje) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.naranjaOscuro.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.naranjaOscuro.withAlpha(80),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.naranjaVivo, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(mensaje, style: AppTextStyles.caption),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 200.ms)
        .shakeX(amount: 4, duration: 300.ms);
  }

  // ── Divisor ───────────────────────────────────────────────────────────────
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.crema.withAlpha(40),
            thickness: 0.5,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('o', style: AppTextStyles.caption),
        ),
        Expanded(
          child: Divider(
            color: AppColors.crema.withAlpha(40),
            thickness: 0.5,
          ),
        ),
      ],
    );
  }

  // ── Botones alternativos (Google + Anónimo) ───────────────────────────────
  Widget _buildBotonesAlternativos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Google
        _GlassOutlineButton(
          icon: Icons.g_mobiledata_rounded,
          label: 'Continuar con Google',
          onPressed: _cargando
              ? null
              : () => _ejecutarAccionAuth(
                    () => widget.servicioAuth.loginConGoogle(),
                  ),
        ),
        const SizedBox(height: 10),

        // Alumno Invitado (acceso rápido)
        _GlassOutlineButton(
          icon: Icons.rocket_launch_outlined,
          label: 'Entrar como Alumno Invitado',
          onPressed: _cargando
              ? null
              : () => _ejecutarAccionAuth(
                    () => widget.servicioAuth.loginAnonimo(),
                  ),
          accentColor: AppColors.ambar,
        ),
      ],
    );
  }

  // ── Botones Demo ──────────────────────────────────────────────────────────
  Widget _buildBotonesDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Acceso de demostración',
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.crema.withAlpha(80),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _DemoChip(
                label: 'Docente Demo',
                icon: Icons.assignment_ind_outlined,
                onTap: _cargando
                    ? null
                    : () => _ejecutarAccionAuth(() =>
                        widget.servicioAuth.loginDemo(RolUsuario.profesor)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DemoChip(
                label: 'Dirección Demo',
                icon: Icons.account_balance_outlined,
                onTap: _cargando
                    ? null
                    : () => _ejecutarAccionAuth(() =>
                        widget.servicioAuth.loginDemo(RolUsuario.direccion)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Subwidgets locales ─────────────────────────────────────────────────────

/// Botón con borde glass para opciones de login secundarias (Google, Invitado).
class _GlassOutlineButton extends StatelessWidget {
  const _GlassOutlineButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.accentColor = AppColors.crema,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.crema.withAlpha(10),
        highlightColor: Colors.transparent,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.crema.withAlpha(10),
            border: Border.all(
              color: AppColors.crema.withAlpha(40),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: accentColor, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.crema.withAlpha(200),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip pequeño de acceso demo. Peso visual mínimo para no competir con el CTA.
class _DemoChip extends StatelessWidget {
  const _DemoChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.crema.withAlpha(8),
          border: Border.all(
            color: AppColors.crema.withAlpha(25),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: AppColors.crema.withAlpha(120)),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.crema.withAlpha(130),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
