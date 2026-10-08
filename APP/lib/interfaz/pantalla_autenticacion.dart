// ============================================================
// pantalla_autenticacion.dart — Pantalla de Login / Registro
//
// Identidad visual: Claude (Anthropic) + macOS Glassmorphism
//   • Fondo: Escritorio macOS texturizado (MacDesktopBackground)
//   • Ventana: Marco de ventana de macOS con Traffic Lights (MacWindowFrame)
//   • Widgets: Calendario, Clima y Batería de macOS en panel lateral (MacWidgetsSidebar)
//   • Botones:
//       - Primario: Sólido crema/hueso (#ECE7DE) con texto carbón (#1E1D1B)
//       - Secundario: Vidrio oscuro con borde hairline ("Continuar con Google")
//   • Tipografía: Lora editorial serif para títulos + Plus Jakarta Sans para controles
//   • Lógica Firebase: 100% intacta y funcional
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../datos/servicio_auth.dart';
import '../dominio/modelos/usuario_app.dart';
import 'auth/widgets/auth_text_field.dart';
import 'auth/widgets/role_selector.dart';
import 'design/app_colors.dart';
import 'widgets/claude_auth_components.dart';
import 'widgets/mac_glass_widgets.dart';

/// Pantalla de autenticación con estética Claude y widgets macOS Glassmorphism.
class PantallaAutenticacion extends StatefulWidget {
  const PantallaAutenticacion({
    super.key,
    required this.servicioAuth,
    this.modoLoginInicial = true,
  });

  final ServicioAuth servicioAuth;
  final bool modoLoginInicial;

  @override
  State<PantallaAutenticacion> createState() => _PantallaAutenticacionState();
}

class _PantallaAutenticacionState extends State<PantallaAutenticacion> {
  // ── Estado de UI ──────────────────────────────────────────────────────────
  late bool _modoLogin; // true = Login, false = Registro
  bool _cargando = false;
  String? _errorMensaje;

  @override
  void initState() {
    super.initState();
    _modoLogin = widget.modoLoginInicial;
  }

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
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      final msg = _formatearError(e.toString());
      setState(() => _errorMensaje = msg);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: const Color(0xFFC15F3C),
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
        error.contains('invalid-credential') ||
        error.contains('INVALID_LOGIN_CREDENTIALS')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (error.contains('email-already-in-use') ||
        error.contains('EMAIL_EXISTS')) {
      return 'Ya existe una cuenta con este correo.';
    }
    if (error.contains('weak-password') ||
        error.contains('WEAK_PASSWORD')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (error.contains('invalid-email') ||
        error.contains('INVALID_EMAIL')) {
      return 'El formato de correo no es válido.';
    }
    if (error.contains('operation-not-allowed') ||
        error.contains('OPERATION_NOT_ALLOWED')) {
      return 'Habilitá este método en la consola de Firebase.';
    }
    if (error.contains('network-request-failed') ||
        error.contains('NETWORK_ERROR') ||
        error.contains('SocketException')) {
      return 'Error de conexión. Verificá tu conexión a internet.';
    }
    if (error.contains('too-many-requests')) {
      return 'Demasiados intentos fallidos. Intenta más tarde.';
    }
    return error
        .replaceAll('Exception: ', '')
        .replaceAll('firebase_auth/', '');
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121110),
      body: MacDesktopBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 860;

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: isWide
                      ? _buildDistribucionDesktop()
                      : _buildDistribucionMobile(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Distribución Desktop: Ventana de macOS en el centro + Widgets macOS a la derecha
  Widget _buildDistribucionDesktop() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Ventana macOS de Autenticación
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: _buildVentanaPrincipal(),
        ),

        const SizedBox(width: 32),

        // Barra de widgets de macOS (Calendario, Clima, Batería como en la foto)
        const MacWidgetsSidebar()
            .animate()
            .fadeIn(duration: 400.ms, delay: 150.ms)
            .slideX(begin: 0.08, end: 0, duration: 400.ms, delay: 150.ms),
      ],
    );
  }

  /// Distribución Mobile: Ventana centrada fluida + fila compacta de widgets
  Widget _buildDistribucionMobile() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildVentanaPrincipal(),
          const SizedBox(height: 20),
          // Resumen compacto de widgets de macOS en móvil
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const MacWeatherWidget(ancho: 170),
                const SizedBox(width: 12),
                const MacBatteryWidget(ancho: 170),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Ventana macOS con traffic lights, cabecera de Claude y contenido
  Widget _buildVentanaPrincipal() {
    return MacWindowFrame(
      title: 'Claude',
      anchoMaximo: 440,
      onClose: Navigator.of(context).canPop()
          ? () => Navigator.of(context).pop()
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cabecera Claude: Logo asterisco + Título serif editorial
          _buildClaudeHeader(),
          const SizedBox(height: 18),

          // Selector segmentado Login / Registro
          _buildToggleSegmentado(),
          const SizedBox(height: 20),

          // Contenedor de formulario con fade & slide fluido
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            transitionBuilder: (child, anim) {
              final slide = Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: _modoLogin
                ? _buildFormularioLogin()
                : _buildFormularioRegistro(),
          ),

          // Banner de error (si existe)
          if (_errorMensaje != null) ...[
            const SizedBox(height: 14),
            _buildErrorBanner(_errorMensaje!),
          ],

          const SizedBox(height: 20),
          const ClaudeDivider(label: 'o'),
          const SizedBox(height: 16),

          // Botones alternativos (Google + Invitado)
          _buildBotonesAlternativos(),
          const SizedBox(height: 16),

          // Acceso rápido a perfiles de demostración
          _buildBotonesDemo(),
          const SizedBox(height: 18),

          // Texto legal y de privacidad tipo Claude
          const ClaudeTermsFooter(),
        ],
      ),
    );
  }

  // ── Cabecera Claude ───────────────────────────────────────────────────────
  Widget _buildClaudeHeader() {
    return Column(
      children: [
        // Logo oficial Claude en terracota + App Matemáticas
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ClaudeAsteriskLogo(size: 24)
                .animate()
                .scale(
                  begin: const Offset(0.7, 0.7),
                  duration: 400.ms,
                  curve: Curves.easeOutBack,
                )
                .fadeIn(duration: 300.ms),
            const SizedBox(width: 8),
            Text(
              'App Matemáticas',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFD97757),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Título editorial en serif (Lora) de Claude (de la foto 3 del usuario)
        Text(
          'Pregúntate qué sigue',
          style: GoogleFonts.lora(
            color: const Color(0xFFFAF9F5),
            fontSize: 26,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.3,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Tu compañero de ideas para grandes ambiciones',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ── Selector Segmentado macOS ─────────────────────────────────────────────
  Widget _buildToggleSegmentado() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          Expanded(
            child: _buildPillBoton('Iniciar Sesión', true),
          ),
          Expanded(
            child: _buildPillBoton('Crear Cuenta', false),
          ),
        ],
      ),
    );
  }

  Widget _buildPillBoton(String label, bool isLogin) {
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
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: isActive
                ? const Color(0xFFFAF9F5)
                : Colors.white.withValues(alpha: 0.50),
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ── Formulario Login ──────────────────────────────────────────────────────
  Widget _buildFormularioLogin() {
    return Form(
      key: _formLoginKey,
      child: Column(
        key: const ValueKey('login_form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            controller: _emailLoginCtrl,
            label: 'Ingresa tu correo electrónico',
            icon: Icons.alternate_email_rounded,
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
                color: Colors.white.withValues(alpha: 0.50),
                size: 19,
              ),
              onPressed: () =>
                  setState(() => _verPasswordLogin = !_verPasswordLogin),
            ),
          ),
          const SizedBox(height: 16),

          // Botón Principal: Sólido crema con texto oscuro Claude
          ClaudePrimaryButton(
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
        key: const ValueKey('registro_form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
            label: 'Ingresa tu correo electrónico',
            icon: Icons.alternate_email_rounded,
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
                color: Colors.white.withValues(alpha: 0.50),
                size: 19,
              ),
              onPressed: () =>
                  setState(() => _verPasswordRegistro = !_verPasswordRegistro),
            ),
          ),
          const SizedBox(height: 14),

          RoleSelector(
            selected: _rolRegistro,
            onChanged: (rol) => setState(() => _rolRegistro = rol),
          ),
          const SizedBox(height: 16),

          // Botón Principal: Sólido crema Claude con texto oscuro
          ClaudePrimaryButton(
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

  // ── Botones Alternativos (Google + Invitado) ──────────────────────────────
  Widget _buildBotonesAlternativos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Continuar con Google (con icono oficial vectorial)
        ClaudeSecondaryButton(
          customLeading: const GoogleBrandIcon(size: 18),
          label: 'Continuar con Google',
          onPressed: _cargando
              ? null
              : () => _ejecutarAccionAuth(
                    () => widget.servicioAuth.loginConGoogle(),
                  ),
        ),
        const SizedBox(height: 10),

        // Alumno Invitado (acceso rápido)
        ClaudeSecondaryButton(
          icon: Icons.rocket_launch_outlined,
          label: 'Entrar como Alumno Invitado (Rápido)',
          onPressed: _cargando
              ? null
              : () => _ejecutarAccionAuth(
                    () => widget.servicioAuth.loginAnonimo(),
                  ),
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
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white.withValues(alpha: 0.40),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _DemoGlassChip(
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
              child: _DemoGlassChip(
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

  // ── Banner de error ───────────────────────────────────────────────────────
  Widget _buildErrorBanner(String mensaje) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFC15F3C).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFC15F3C).withValues(alpha: 0.50),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFE27D5B),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFFAF9F5),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 200.ms)
        .shakeX(amount: 3, duration: 300.ms);
  }
}

/// Chip de demostración con borde fino de vidrio
class _DemoGlassChip extends StatelessWidget {
  const _DemoGlassChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: Colors.white.withValues(alpha: 0.60),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.75),
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
