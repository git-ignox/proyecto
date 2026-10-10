import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../datos/servicio_auth.dart';
import '../dominio/modelos/usuario_app.dart';
import 'design/app_colors.dart';
import 'pantalla_autenticacion.dart';
import 'widgets/claude_auth_components.dart';
import 'widgets/mac_glass_widgets.dart';

/// Pantalla de bienvenida con estética macOS Glassmorphism y diseño Anthropic Claude.
class PantallaBienvenida extends StatefulWidget {
  const PantallaBienvenida({
    super.key,
    required this.servicioAuth,
  });

  final ServicioAuth servicioAuth;

  @override
  State<PantallaBienvenida> createState() => _PantallaBienvenidaState();
}

class _PantallaBienvenidaState extends State<PantallaBienvenida> {
  bool _cargando = false;

  void _navegarAAuth(BuildContext context, {required bool modoLogin}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PantallaAutenticacion(
          servicioAuth: widget.servicioAuth,
          modoLoginInicial: modoLogin,
        ),
      ),
    );
  }

  Future<void> _loginInvitado() async {
    setState(() => _cargando = true);
    try {
      await widget.servicioAuth.iniciarSesionInvitado();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al ingresar como invitado: $e'),
            backgroundColor: const Color(0xFFC15F3C),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _loginDemo(RolUsuario rol) async {
    setState(() => _cargando = true);
    try {
      final email = rol == RolUsuario.profesor
          ? 'docente@colegio.edu'
          : 'direccion@colegio.edu';
      await widget.servicioAuth.iniciarSesionConCorreo(
        email: email,
        password: 'password123',
      );
    } catch (_) {
      // Fallback a invitado si la demo con credenciales falla
      await widget.servicioAuth.iniciarSesionInvitado();
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

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

  Widget _buildDistribucionDesktop() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: _buildVentanaPrincipal(),
        ),
        const SizedBox(width: 32),
        const MacCalendarWidget()
            .animate()
            .fadeIn(duration: 400.ms, delay: 150.ms)
            .slideX(begin: 0.08, end: 0, duration: 400.ms, delay: 150.ms),
      ],
    );
  }

  Widget _buildDistribucionMobile() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: _buildVentanaPrincipal(),
    );
  }

  Widget _buildVentanaPrincipal() {
    return MacGlassContainer(
      borderRadius: 22,
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo e insignia Claude
          Row(
            children: [
              const ClaudeAsteriskLogo(size: 30),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'San Agustín LMS',
                    style: GoogleFonts.lora(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.claudeTextoPrincipal,
                    ),
                  ),
                  Text(
                    'Plataforma Académica de Matemáticas',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.claudeTextoSecundario,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Título principal
          Text(
            'Bienvenido a tu aula virtual',
            style: GoogleFonts.lora(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.claudeTextoPrincipal,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Accede a tus evaluaciones diagnósticas, práctica adaptativa y seguimiento curricular en tiempo real.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.claudeTextoSecundario,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 26),

          // Botón Iniciar Sesión (Sólido Crema)
          ClaudePrimaryButton(
            label: 'Iniciar Sesión',
            isLoading: _cargando,
            onPressed: () => _navegarAAuth(context, modoLogin: true),
          ),
          const SizedBox(height: 12),

          // Botón Crear Cuenta (Vidrio Oscuro)
          ClaudeSecondaryButton(
            label: 'Crear Cuenta',
            icon: Icons.person_add_outlined,
            onPressed: () => _navegarAAuth(context, modoLogin: false),
          ),

          const SizedBox(height: 18),
          const ClaudeDivider(label: 'o'),
          const SizedBox(height: 14),

          // Acceso Rápido como Alumno Invitado
          ClaudeSecondaryButton(
            label: 'Entrar como Alumno Invitado (Rápido)',
            icon: Icons.rocket_launch_outlined,
            accentBorderColor: AppColors.claudeTerracota.withValues(alpha: 0.4),
            onPressed: _cargando ? null : _loginInvitado,
          ),
          const SizedBox(height: 16),

          // Acceso de Demostración
          Center(
            child: Text(
              'Acceso de demostración',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.claudeTextoAtenuado,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: ClaudeSecondaryButton(
                  label: 'Docente Demo',
                  icon: Icons.badge_outlined,
                  height: 40,
                  borderRadius: 10,
                  onPressed: _cargando ? null : () => _loginDemo(RolUsuario.profesor),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClaudeSecondaryButton(
                  label: 'Dirección Demo',
                  icon: Icons.account_balance_outlined,
                  height: 40,
                  borderRadius: 10,
                  onPressed: _cargando ? null : () => _loginDemo(RolUsuario.direccion),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const ClaudeTermsFooter(),
        ],
      ),
    );
  }
}
