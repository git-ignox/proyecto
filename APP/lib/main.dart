import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'datos/fuente_datos_diagnostico.dart';
import 'datos/fuente_datos_ejercicios.dart';
import 'datos/repositorio_diagnostico.dart';
import 'datos/repositorio_ejercicios.dart';
import 'datos/servicio_auth.dart';
import 'dominio/evaluadores/servicio_evaluacion.dart';
import 'dominio/modelos/usuario_app.dart';
import 'interfaz/pantalla_alumno.dart';
import 'interfaz/pantalla_autenticacion.dart';
import 'interfaz/pantalla_profesor.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Aviso al inicializar Firebase: $e');
  }

  final repositorio = FuenteDatosEjercicios();
  final repositorioDiagnostico = FuenteDatosDiagnostico();
  final servicioEvaluacion = ServicioEvaluacion();
  final servicioAuth = ServicioAuth()..inicializar();

  runApp(AppMatematicas(
    repositorio: repositorio,
    repositorioDiagnostico: repositorioDiagnostico,
    servicioEvaluacion: servicioEvaluacion,
    servicioAuth: servicioAuth,
  ));
}

class AppMatematicas extends StatelessWidget {
  const AppMatematicas({
    super.key,
    required this.repositorio,
    this.repositorioDiagnostico,
    required this.servicioEvaluacion,
    this.servicioAuth,
  });

  final RepositorioEjercicios repositorio;
  final RepositorioDiagnostico? repositorioDiagnostico;
  final ServicioEvaluacion servicioEvaluacion;
  final ServicioAuth? servicioAuth;

  @override
  Widget build(BuildContext context) {
    final auth = servicioAuth ?? ServicioAuth();
    final diagRepo = repositorioDiagnostico ?? FuenteDatosDiagnostico();

    return MaterialApp(
      title: 'App Matemáticas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: StreamBuilder<UsuarioApp?>(
        stream: auth.usuarioStream,
        initialData: auth.usuarioActual,
        builder: (context, snapshot) {
          final usuario = snapshot.data;

          if (usuario == null) {
            return PantallaAutenticacion(servicioAuth: auth);
          }

          if (usuario.rol == RolUsuario.profesor) {
            return PantallaProfesor(
              usuario: usuario,
              repositorio: repositorio,
              repositorioDiagnostico: diagRepo,
              servicioEvaluacion: servicioEvaluacion,
              servicioAuth: auth,
            );
          }

          return PantallaAlumno(
            usuario: usuario,
            repositorio: repositorio,
            repositorioDiagnostico: diagRepo,
            servicioEvaluacion: servicioEvaluacion,
            servicioAuth: auth,
          );
        },
      ),
    );
  }
}
