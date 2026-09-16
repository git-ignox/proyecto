import 'package:flutter/material.dart';
import '../datos/servicio_auth.dart';
import '../dominio/modelos/usuario_app.dart';

/// Pantalla de inicio de sesión y registro de usuarios con Firebase.
/// Soporta Correo/Contraseña, Google y Acceso Anónimo con selección de rol.
class PantallaAutenticacion extends StatefulWidget {
  const PantallaAutenticacion({
    super.key,
    required this.servicioAuth,
  });

  final ServicioAuth servicioAuth;

  @override
  State<PantallaAutenticacion> createState() => _PantallaAutenticacionState();
}

class _PantallaAutenticacionState extends State<PantallaAutenticacion> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Formularios
  final _formLoginKey = GlobalKey<FormState>();
  final _formRegistroKey = GlobalKey<FormState>();

  // Controladores Login
  final _emailLoginCtrl = TextEditingController();
  final _passwordLoginCtrl = TextEditingController();

  // Controladores Registro
  final _nombreRegistroCtrl = TextEditingController();
  final _emailRegistroCtrl = TextEditingController();
  final _passwordRegistroCtrl = TextEditingController();
  RolUsuario _rolRegistro = RolUsuario.alumno;

  bool _cargando = false;
  String? _errorMensaje;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailLoginCtrl.dispose();
    _passwordLoginCtrl.dispose();
    _nombreRegistroCtrl.dispose();
    _emailRegistroCtrl.dispose();
    _passwordRegistroCtrl.dispose();
    super.dispose();
  }

  Future<void> _ejecutarAccionAuth(Future<void> Function() accion) async {
    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });
    try {
      await accion();
    } catch (e) {
      setState(() {
        _errorMensaje = _formatearError(e.toString());
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMensaje ?? 'Error de autenticación'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  String _formatearError(String error) {
    if (error.contains('GIDClientID') || error.contains('No active configuration')) {
      return 'Google Sign-In en macOS requiere Client ID de OAuth en Info.plist. Puedes usar Correo o Invitado.';
    }
    if (error.contains('user-not-found') || error.contains('wrong-password') || error.contains('invalid-credential')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (error.contains('email-already-in-use')) {
      return 'Ya existe una cuenta con este correo electrónico.';
    }
    if (error.contains('weak-password')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (error.contains('invalid-email')) {
      return 'El formato de correo no es válido.';
    }
    if (error.contains('operation-not-allowed')) {
      return 'Habilita este método en la consola de Firebase Authentication.';
    }
    return error.replaceAll('Exception: ', '').replaceAll('firebase_auth/', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icono y Título
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.calculate, size: 48, color: Colors.indigo),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'App Matemáticas',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const Text(
                      'Plataforma de Aritmética para Alumnos y Profesores',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    // Pestañas Iniciar Sesión / Registro
                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.indigo,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.indigo,
                      indicatorWeight: 3,
                      tabs: const [
                        Tab(text: 'Iniciar Sesión'),
                        Tab(text: 'Crear Cuenta'),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Contenido de Pestañas
                    SizedBox(
                      height: 350,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _construirFormularioLogin(),
                          _construirFormularioRegistro(),
                        ],
                      ),
                    ),

                    if (_cargando) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                    ],

                    const Divider(height: 32),

                    // Botón Google Sign-In
                    OutlinedButton.icon(
                      onPressed: _cargando
                          ? null
                          : () => _ejecutarAccionAuth(() => widget.servicioAuth.loginConGoogle()),
                      icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
                      label: const Text(
                        'Continuar con Google',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Botón Acceso Anónimo Rápido (Alumno Invitado)
                    ElevatedButton.icon(
                      onPressed: _cargando
                          ? null
                          : () => _ejecutarAccionAuth(() => widget.servicioAuth.loginAnonimo()),
                      icon: const Icon(Icons.rocket_launch, size: 20, color: Colors.white),
                      label: const Text(
                        'Entrar como Alumno Invitado (Rápido)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Atajos de demostración rápida para Dirección y Docente
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _cargando
                                ? null
                                : () => _ejecutarAccionAuth(() => widget.servicioAuth.loginDemo(RolUsuario.profesor)),
                            icon: const Icon(Icons.assignment_ind, size: 16),
                            label: const Text('Docente Demo', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _cargando
                                ? null
                                : () => _ejecutarAccionAuth(() => widget.servicioAuth.loginDemo(RolUsuario.direccion)),
                            icon: const Icon(Icons.account_balance, size: 16, color: Colors.white),
                            label: const Text('Dirección Demo', style: TextStyle(fontSize: 12, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey.shade800,
                            ),
                          ),
                        ),
                      ],
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

  Widget _construirFormularioLogin() {
    return Form(
      key: _formLoginKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailLoginCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo Electrónico',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            validator: (v) => (v == null || !v.contains('@')) ? 'Ingresa un correo válido' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordLoginCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: Icon(Icons.lock_outline),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _cargando
                ? null
                : () {
                    if (_formLoginKey.currentState!.validate()) {
                      _ejecutarAccionAuth(() => widget.servicioAuth.loginConEmail(
                            email: _emailLoginCtrl.text,
                            password: _passwordLoginCtrl.text,
                          ));
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('INICIAR SESIÓN', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _construirFormularioRegistro() {
    return Form(
      key: _formRegistroKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: _nombreRegistroCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre Completo',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _emailRegistroCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo Electrónico',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              validator: (v) => (v == null || !v.contains('@')) ? 'Ingresa un correo válido' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _passwordRegistroCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña (mín. 6 letras)',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
            ),
            const SizedBox(height: 12),

            // Selector de Rol (Alumno vs Profesor vs Dirección)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  label: const Text('🎒 Alumno'),
                  selected: _rolRegistro == RolUsuario.alumno,
                  onSelected: (val) => setState(() => _rolRegistro = RolUsuario.alumno),
                ),
                ChoiceChip(
                  label: const Text('👨‍🏫 Profesor'),
                  selected: _rolRegistro == RolUsuario.profesor,
                  onSelected: (val) => setState(() => _rolRegistro = RolUsuario.profesor),
                ),
                ChoiceChip(
                  label: const Text('🏛️ Dirección'),
                  selected: _rolRegistro == RolUsuario.direccion,
                  onSelected: (val) => setState(() => _rolRegistro = RolUsuario.direccion),
                ),
              ],
            ),
            const SizedBox(height: 14),

            ElevatedButton(
              onPressed: _cargando
                  ? null
                  : () {
                      if (_formRegistroKey.currentState!.validate()) {
                        _ejecutarAccionAuth(() => widget.servicioAuth.registroConEmail(
                              email: _emailRegistroCtrl.text,
                              password: _passwordRegistroCtrl.text,
                              nombre: _nombreRegistroCtrl.text,
                              rol: _rolRegistro,
                            ));
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('CREAR CUENTA', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

