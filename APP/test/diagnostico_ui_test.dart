import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/datos/fuente_datos_diagnostico.dart';
import 'package:proyecto/datos/fuente_datos_ejercicios.dart';
import 'package:proyecto/datos/servicio_auth.dart';
import 'package:proyecto/dominio/evaluadores/servicio_evaluacion.dart';
import 'package:proyecto/dominio/modelos/aritmetico.dart';
import 'package:proyecto/dominio/modelos/posicion_curricular.dart';
import 'package:proyecto/dominio/modelos/usuario_app.dart';
import 'package:proyecto/interfaz/pantalla_alumno.dart';
import 'package:proyecto/interfaz/pantalla_profesor.dart';

void main() {
  late FuenteDatosEjercicios repoEjercicios;
  late FuenteDatosDiagnostico repoDiagnostico;
  late ServicioEvaluacion servicioEvaluacion;
  late ServicioAuth servicioAuth;

  setUp(() {
    repoEjercicios = FuenteDatosEjercicios([
      const Aritmetico(
        id: 'SUM-1.1.1',
        posicion: PosicionCurricular(tema: 1, subtema: 1, leccion: 1),
        nivel: 1,
        enunciado: 'Calcula la suma en columna: 125 + 78',
        operacion: OperacionAritmetica.suma,
        operando1: 125,
        operando2: 78,
        disposicion: DisposicionAritmetica.vertical,
        incognita: ElementoIncognita.resultado,
        tags: ['aritmetica', 'suma', 'acarreo'],
        puntos: 10,
      ),
    ]);
    repoDiagnostico = FuenteDatosDiagnostico();
    servicioEvaluacion = ServicioEvaluacion();
    servicioAuth = ServicioAuth(
      usuarioInicial: const UsuarioApp(
        uid: 'alumno-test-uid',
        nombre: 'Estudiante Prueba',
        rol: RolUsuario.alumno,
      ),
    );
  });

  testWidgets('PantallaAlumno muestra diagnóstico de error con chip didáctico y abre panel de áreas de mejora', (tester) async {
    const usuario = UsuarioApp(
      uid: 'alumno-test-uid',
      nombre: 'Estudiante Prueba',
      rol: RolUsuario.alumno,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PantallaAlumno(
          usuario: usuario,
          repositorio: repoEjercicios,
          repositorioDiagnostico: repoDiagnostico,
          servicioEvaluacion: servicioEvaluacion,
          servicioAuth: servicioAuth,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verificar que se renderizan los tags en chips
    expect(find.text('suma'), findsOneWidget);
    expect(find.text('acarreo'), findsOneWidget);

    // 2. Ingresar respuesta errónea por olvido de acarreo (193)
    final campoTexto = find.byType(TextField);
    expect(campoTexto, findsOneWidget);
    await tester.enterText(campoTexto, '193');

    // 3. Presionar botón CALIFICAR
    final botonCalificar = find.text('CALIFICAR RESPUESTA');
    await tester.ensureVisible(botonCalificar);
    await tester.tap(botonCalificar);
    await tester.pumpAndSettle();

    // 4. Verificar que aparece el panel de resultado con diagnóstico pedagógico
    expect(find.textContaining('Diagnóstico del Error'), findsOneWidget);
    expect(find.textContaining('Acarreo o Reagrupación'), findsOneWidget);
    expect(find.textContaining('Consejo Didáctico'), findsOneWidget);

    // 5. Abrir el modal de Diagnóstico y Refuerzo
    final botonDiagnostico = find.byIcon(Icons.analytics_outlined);
    expect(botonDiagnostico, findsOneWidget);
    await tester.tap(botonDiagnostico);
    await tester.pumpAndSettle();

    // 6. Verificar contenido del modal diagnóstico
    expect(find.textContaining('Mi Diagnóstico & Áreas de Mejora'), findsOneWidget);
    expect(find.textContaining('Precisión Global'), findsOneWidget);
    expect(find.textContaining('Errores Más Prominentes'), findsOneWidget);
  });

  testWidgets('PantallaProfesor muestra tags en el catálogo y abre el Monitor Docente de Dificultades', (tester) async {
    const usuarioProfesor = UsuarioApp(
      uid: 'profe-1',
      nombre: 'Profesor Matemáticas',
      rol: RolUsuario.profesor,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PantallaProfesor(
          usuario: usuarioProfesor,
          repositorio: repoEjercicios,
          repositorioDiagnostico: repoDiagnostico,
          servicioEvaluacion: servicioEvaluacion,
          servicioAuth: servicioAuth,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verificar catálogo con tags
    expect(find.text('acarreo'), findsOneWidget);

    // 2. Abrir monitor de dificultades docente
    final botonMonitor = find.byIcon(Icons.insights);
    expect(botonMonitor, findsOneWidget);
    await tester.tap(botonMonitor);
    await tester.pumpAndSettle();

    // 3. Verificar contenido del monitor
    expect(find.text('Monitor Docente de Errores & Dificultades'), findsOneWidget);
    expect(find.text('Intentos Evaluados'), findsOneWidget);
    expect(find.textContaining('Intervención Pedagógica'), findsOneWidget);
  });
}
