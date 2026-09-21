import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../dominio/modelos/usuario_app.dart';

/// Servicio de gestión de autenticación Firebase y sincronización de roles en Firestore.
class ServicioAuth {
  ServicioAuth({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
    UsuarioApp? usuarioInicial,
  })  : _customAuth = auth,
        _customFirestore = firestore,
        _customGoogleSignIn = googleSignIn,
        _usuarioCache = usuarioInicial;

  final FirebaseAuth? _customAuth;
  final FirebaseFirestore? _customFirestore;
  final GoogleSignIn? _customGoogleSignIn;

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;
  GoogleSignIn get _googleSignIn => _customGoogleSignIn ?? GoogleSignIn();

  UsuarioApp? _usuarioCache;
  final StreamController<UsuarioApp?> _controller = StreamController<UsuarioApp?>.broadcast();

  Stream<UsuarioApp?> get usuarioStream => _controller.stream;
  UsuarioApp? get usuarioActual => _usuarioCache;

  void inicializar() {
    try {
      _auth.authStateChanges().listen((User? user) async {
        if (user == null) {
          _usuarioCache = null;
          _controller.add(null);
        } else {
          await _cargarOcrearPerfilUsuario(user);
        }
      });
    } catch (e) {
      debugPrint('Aviso FirebaseAuth en test/offline: $e');
    }
  }

  /// Carga los datos del usuario desde Firestore o inicializa perfil predeterminado
  Future<void> _cargarOcrearPerfilUsuario(User user, {RolUsuario? rolInicial, String? nombreInicial}) async {
    // 1. Emitir inmediatamente el usuario en memoria para transición instantánea
    final nombre = nombreInicial ?? user.displayName ?? (user.isAnonymous ? 'Estudiante Invitado' : (user.email?.split('@').first ?? 'Usuario'));
    final usuarioLocal = UsuarioApp(
      uid: user.uid,
      email: user.email,
      nombre: nombre,
      rol: rolInicial ?? RolUsuario.alumno,
      esAnonimo: user.isAnonymous,
      fotoUrl: user.photoURL,
    );
    _usuarioCache = usuarioLocal;
    _controller.add(_usuarioCache);

    // 2. En segundo plano sincronizar con Firestore sin bloquear la UI
    try {
      final doc = await _firestore.collection('usuarios').doc(user.uid).get().timeout(const Duration(seconds: 2));
      if (doc.exists && doc.data() != null) {
        _usuarioCache = UsuarioApp.fromMap(doc.data()!, user.uid);
        _controller.add(_usuarioCache);
      } else {
        await _firestore.collection('usuarios').doc(user.uid).set(usuarioLocal.toMap()).timeout(const Duration(seconds: 2));
      }
    } catch (e) {
      debugPrint('Sincronización Firestore en segundo plano (usando perfil local): $e');
    }
  }

  /// Registro con Email y Contraseña
  Future<UsuarioApp> registroConEmail({
    required String email,
    required String password,
    required String nombre,
    required RolUsuario rol,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (cred.user != null) {
        try {
          await cred.user!.updateDisplayName(nombre.trim());
        } catch (_) {}
        await _cargarOcrearPerfilUsuario(cred.user!, rolInicial: rol, nombreInicial: nombre.trim());
        return _usuarioCache!;
      }
    } catch (e) {
      debugPrint('Error en registro Firebase Auth: $e');
      if (e.toString().contains('keychain-error')) {
        final usuario = UsuarioApp(
          uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
          email: email.trim(),
          nombre: nombre.trim(),
          rol: rol,
        );
        _usuarioCache = usuario;
        _controller.add(_usuarioCache);
        return usuario;
      }
      rethrow;
    }
    throw Exception('No se pudo crear la cuenta de usuario');
  }

  /// Inicio de Sesión con Email y Contraseña
  Future<UsuarioApp> loginConEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (cred.user != null) {
        await _cargarOcrearPerfilUsuario(cred.user!);
        return _usuarioCache!;
      }
    } catch (e) {
      debugPrint('Error en login Firebase Auth: $e');
      if (e.toString().contains('keychain-error')) {
        final usuario = UsuarioApp(
          uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
          email: email.trim(),
          nombre: email.split('@').first,
          rol: RolUsuario.alumno,
        );
        _usuarioCache = usuario;
        _controller.add(_usuarioCache);
        return usuario;
      }
      rethrow;
    }
    throw Exception('Error al iniciar sesión');
  }

  /// Inicio de Sesión con Google
  Future<UsuarioApp> loginConGoogle({RolUsuario rol = RolUsuario.alumno}) async {
    try {
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        final cred = await _auth.signInWithPopup(googleProvider);
        if (cred.user != null) {
          await _cargarOcrearPerfilUsuario(cred.user!, rolInicial: rol);
          return _usuarioCache!;
        }
      } else if (defaultTargetPlatform == TargetPlatform.windows) {
        try {
          final googleProvider = GoogleAuthProvider();
          final cred = await _auth.signInWithProvider(googleProvider);
          if (cred.user != null) {
            await _cargarOcrearPerfilUsuario(cred.user!, rolInicial: rol);
            return _usuarioCache!;
          }
        } catch (e) {
          debugPrint('Aviso Google Sign-In en Windows: $e');
          throw Exception('Google Sign-In no está soportado de forma nativa en Windows Desktop. Por favor inicia sesión con Correo o ingresa como Alumno Invitado / Demo.');
        }
      } else {
        try {
          final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
          if (googleUser == null) {
            throw Exception('Inicio de sesión con Google cancelado');
          }

          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          final cred = await _auth.signInWithCredential(credential);
          if (cred.user != null) {
            await _cargarOcrearPerfilUsuario(cred.user!, rolInicial: rol);
            return _usuarioCache!;
          }
        } catch (e) {
          debugPrint('Aviso GoogleSignIn nativo: $e');
          // En escritorio o si el plugin nativo requiere configuración adicional, intentar con GoogleAuthProvider
          final googleProvider = GoogleAuthProvider();
          final cred = await _auth.signInWithProvider(googleProvider);
          if (cred.user != null) {
            await _cargarOcrearPerfilUsuario(cred.user!, rolInicial: rol);
            return _usuarioCache!;
          }
        }
      }
    } catch (e) {
      debugPrint('Error general en loginConGoogle: $e');
      rethrow;
    }
    throw Exception('Error al iniciar sesión con Google');
  }

  /// Inicio de Sesión Anónimo (Acceso de prueba o estudiante invitado)
  Future<UsuarioApp> loginAnonimo({RolUsuario rol = RolUsuario.alumno}) async {
    try {
      final cred = await _auth.signInAnonymously().timeout(const Duration(seconds: 4));
      if (cred.user != null) {
        await _cargarOcrearPerfilUsuario(cred.user!, rolInicial: rol, nombreInicial: 'Estudiante Invitado');
        return _usuarioCache!;
      }
    } catch (e) {
      debugPrint('Aviso FirebaseAuth anonimo (accediendo en modo invitado local): $e');
    }

    // Modo invitado local inmediato
    final invitado = UsuarioApp(
      uid: 'invitado_${DateTime.now().millisecondsSinceEpoch}',
      nombre: 'Estudiante Invitado',
      rol: rol,
      esAnonimo: true,
    );
    _usuarioCache = invitado;
    _controller.add(_usuarioCache);
    return invitado;
  }

  /// Cierre de Sesión
  Future<void> cerrarSesion() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
    _usuarioCache = null;
    _controller.add(null);
  }

  /// Cambia temporal o permanentemente el rol del usuario (cicla entre Alumno, Profesor y Dirección)
  Future<void> alternarRol() async {
    if (_usuarioCache == null) return;
    RolUsuario nuevoRol;
    if (_usuarioCache!.rol == RolUsuario.alumno) {
      nuevoRol = RolUsuario.profesor;
    } else if (_usuarioCache!.rol == RolUsuario.profesor) {
      nuevoRol = RolUsuario.direccion;
    } else {
      nuevoRol = RolUsuario.alumno;
    }
    await cambiarRol(nuevoRol);
  }

  /// Asigna un rol específico al usuario en sesión
  Future<void> cambiarRol(RolUsuario nuevoRol) async {
    if (_usuarioCache == null) return;
    _usuarioCache = _usuarioCache!.copyWith(rol: nuevoRol);
    _controller.add(_usuarioCache);

    try {
      await _firestore.collection('usuarios').doc(_usuarioCache!.uid).update({
        'rol': nuevoRol.name,
      });
    } catch (_) {}
  }

  /// Inicia sesión rápida de demostración para el rol solicitado
  Future<UsuarioApp> loginDemo(RolUsuario rol) async {
    String nombreDemo;
    String uidDemo;
    switch (rol) {
      case RolUsuario.direccion:
        nombreDemo = 'Lic. María Elena Walsh (Directora)';
        uidDemo = 'dir-01';
        break;
      case RolUsuario.profesor:
        nombreDemo = 'Docente Demo';
        uidDemo = 'profesor-demo';
        break;
      case RolUsuario.alumno:
        nombreDemo = 'Sofía Valenzuela';
        uidDemo = 'alumno-demo-1';
        break;
    }

    final usuarioDemo = UsuarioApp(
      uid: uidDemo,
      nombre: nombreDemo,
      rol: rol,
      esAnonimo: true,
      institucionId: 'INST-SAN-MARTIN',
    );

    _usuarioCache = usuarioDemo;
    _controller.add(_usuarioCache);
    return usuarioDemo;
  }

  /// Incrementa los puntos y ejercicios resueltos del alumno
  Future<void> sumarPuntos(int puntos) async {
    if (_usuarioCache == null) return;
    final nuevosPuntos = _usuarioCache!.puntosAcumulados + puntos;
    final nuevosResueltos = _usuarioCache!.ejerciciosResueltos + 1;

    _usuarioCache = _usuarioCache!.copyWith(
      puntosAcumulados: nuevosPuntos,
      ejerciciosResueltos: nuevosResueltos,
    );
    _controller.add(_usuarioCache);

    try {
      await _firestore.collection('usuarios').doc(_usuarioCache!.uid).update({
        'puntosAcumulados': nuevosPuntos,
        'ejerciciosResueltos': nuevosResueltos,
      });
    } catch (_) {}
  }

  void dispose() {
    _controller.close();
  }
}
