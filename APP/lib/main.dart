import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'datos/fuente_datos_auditoria.dart';
import 'datos/fuente_datos_clases.dart';
import 'datos/fuente_datos_curriculo.dart';
import 'datos/fuente_datos_diagnostico.dart';
import 'datos/fuente_datos_ejercicios.dart';
import 'datos/fuente_datos_evaluaciones.dart';
import 'datos/fuente_datos_politicas.dart';
import 'datos/fuente_datos_reportes.dart';
import 'datos/fuente_datos_sesiones_clase.dart';
import 'datos/repositorio_auditoria.dart';
import 'datos/repositorio_clases.dart';
import 'datos/repositorio_curriculo.dart';
import 'datos/repositorio_diagnostico.dart';
import 'datos/repositorio_ejercicios.dart';
import 'datos/repositorio_evaluaciones.dart';
import 'datos/repositorio_politicas.dart';
import 'datos/repositorio_reportes.dart';
import 'datos/repositorio_sesiones_clase.dart';
import 'datos/servicio_auth.dart';
import 'datos/servicio_horarios.dart';
import 'dominio/evaluadores/servicio_evaluacion.dart';
import 'dominio/modelos/usuario_app.dart';
import 'interfaz/direccion/pantalla_direccion.dart';
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
  final repositorioClases = FuenteDatosClases();
  final repositorioEvaluaciones = FuenteDatosEvaluaciones();
  final repositorioReportes = FuenteDatosReportes();
  final repositorioCurriculo = FuenteDatosCurriculo();
  final repositorioPoliticas = FuenteDatosPoliticas();
  final repositorioAuditoria = FuenteDatosAuditoria();
  final repositorioSesiones = FuenteDatosSesionesClase(
    repositorioPoliticas: repositorioPoliticas,
    repositorioAuditoria: repositorioAuditoria,
  );
  final servicioHorarios = ServicioHorarios();
  final servicioEvaluacion = ServicioEvaluacion();
  final servicioAuth = ServicioAuth()..inicializar();

  runApp(AppMatematicas(
    repositorio: repositorio,
    repositorioDiagnostico: repositorioDiagnostico,
    repositorioClases: repositorioClases,
    repositorioEvaluaciones: repositorioEvaluaciones,
    repositorioReportes: repositorioReportes,
    repositorioCurriculo: repositorioCurriculo,
    repositorioPoliticas: repositorioPoliticas,
    repositorioSesiones: repositorioSesiones,
    repositorioAuditoria: repositorioAuditoria,
    servicioHorarios: servicioHorarios,
    servicioEvaluacion: servicioEvaluacion,
    servicioAuth: servicioAuth,
  ));
}

class AppMatematicas extends StatelessWidget {
  const AppMatematicas({
    super.key,
    required this.repositorio,
    this.repositorioDiagnostico,
    this.repositorioClases,
    this.repositorioEvaluaciones,
    this.repositorioReportes,
    this.repositorioCurriculo,
    this.repositorioPoliticas,
    this.repositorioSesiones,
    this.repositorioAuditoria,
    this.servicioHorarios,
    required this.servicioEvaluacion,
    this.servicioAuth,
  });

  final RepositorioEjercicios repositorio;
  final RepositorioDiagnostico? repositorioDiagnostico;
  final RepositorioClases? repositorioClases;
  final RepositorioEvaluaciones? repositorioEvaluaciones;
  final RepositorioReportes? repositorioReportes;
  final RepositorioCurriculo? repositorioCurriculo;
  final RepositorioPoliticas? repositorioPoliticas;
  final RepositorioSesionesClase? repositorioSesiones;
  final RepositorioAuditoria? repositorioAuditoria;
  final ServicioHorarios? servicioHorarios;
  final ServicioEvaluacion servicioEvaluacion;
  final ServicioAuth? servicioAuth;

  @override
  Widget build(BuildContext context) {
    final auth = servicioAuth ?? ServicioAuth();
    final diagRepo = repositorioDiagnostico ?? FuenteDatosDiagnostico();
    final clasesRepo = repositorioClases ?? FuenteDatosClases();
    final evalRepo = repositorioEvaluaciones ?? FuenteDatosEvaluaciones();
    final reportesRepo = repositorioReportes ?? FuenteDatosReportes();
    final curriculoRepo = repositorioCurriculo ?? FuenteDatosCurriculo();
    final politicasRepo = repositorioPoliticas ?? FuenteDatosPoliticas();
    final auditoriaRepo = repositorioAuditoria ?? FuenteDatosAuditoria();
    final sesionesRepo = repositorioSesiones ??
        FuenteDatosSesionesClase(
          repositorioPoliticas: politicasRepo,
          repositorioAuditoria: auditoriaRepo,
        );
    final horariosServicio = servicioHorarios ?? ServicioHorarios();

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

          if (usuario.rol == RolUsuario.direccion) {
            return PantallaDireccion(
              usuario: usuario,
              servicioAuth: auth,
              repositorioPoliticas: politicasRepo,
              repositorioSesiones: sesionesRepo,
              repositorioAuditoria: auditoriaRepo,
              repositorioClases: clasesRepo,
              servicioHorarios: horariosServicio,
            );
          }

          if (usuario.rol == RolUsuario.profesor) {
            return PantallaProfesor(
              usuario: usuario,
              repositorio: repositorio,
              repositorioDiagnostico: diagRepo,
              repositorioClases: clasesRepo,
              repositorioEvaluaciones: evalRepo,
              repositorioReportes: reportesRepo,
              repositorioCurriculo: curriculoRepo,
              repositorioPoliticas: politicasRepo,
              repositorioSesiones: sesionesRepo,
              repositorioAuditoria: auditoriaRepo,
              servicioHorarios: horariosServicio,
              servicioEvaluacion: servicioEvaluacion,
              servicioAuth: auth,
            );
          }

          return PantallaAlumno(
            usuario: usuario,
            repositorio: repositorio,
            repositorioDiagnostico: diagRepo,
            repositorioClases: clasesRepo,
            repositorioEvaluaciones: evalRepo,
            repositorioReportes: reportesRepo,
            repositorioSesiones: sesionesRepo,
            repositorioAuditoria: auditoriaRepo,
            servicioEvaluacion: servicioEvaluacion,
            servicioAuth: auth,
          );
        },
      ),
    );
  }
}
