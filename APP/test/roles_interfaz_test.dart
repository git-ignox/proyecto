import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/datos/fuente_datos_ejercicios.dart';
import 'package:proyecto/datos/servicio_auth.dart';
import 'package:proyecto/dominio/evaluadores/servicio_evaluacion.dart';
import 'package:proyecto/dominio/modelos/usuario_app.dart';
import 'package:proyecto/interfaz/pantalla_alumno.dart';
import 'package:proyecto/interfaz/pantalla_autenticacion.dart';
import 'package:proyecto/interfaz/pantalla_profesor.dart';
import 'package:proyecto/main.dart';

void main() {
  group('Modelos y Roles de Usuario', () {
    test('Crea UsuarioApp y valida rol de alumno y profesor', () {
      const alumno = UsuarioApp(
        uid: 'user-1',
        email: 'alumno@puff.com',
        nombre: 'Juan Perez',
        rol: RolUsuario.alumno,
        puntosAcumulados: 50,
      );

      expect(alumno.esAlumno, isTrue);
      expect(alumno.esProfesor, isFalse);
      expect(alumno.puntosAcumulados, equals(50));

      final profesor = alumno.copyWith(rol: RolUsuario.profesor);
      expect(profesor.esProfesor, isTrue);
      expect(profesor.esAlumno, isFalse);
    });

    test('Serialización toMap y fromMap de UsuarioApp', () {
      const original = UsuarioApp(
        uid: 'u-123',
        email: 'profe@puff.com',
        nombre: 'Profe Martin',
        rol: RolUsuario.profesor,
        puntosAcumulados: 100,
      );

      final map = original.toMap();
      final restaurado = UsuarioApp.fromMap(map, 'u-123');

      expect(restaurado.uid, equals(original.uid));
      expect(restaurado.nombre, equals(original.nombre));
      expect(restaurado.rol, equals(RolUsuario.profesor));
    });
  });

  group('Interfaz de Autenticación', () {
    testWidgets('Muestra pestañas de Login, Registro, Google y Anónimo', (WidgetTester tester) async {
      final auth = ServicioAuth();

      await tester.pumpWidget(MaterialApp(
        home: PantallaAutenticacion(servicioAuth: auth),
      ));

      await tester.pumpAndSettle();

      expect(find.text('App Matemáticas'), findsOneWidget);
      expect(find.text('Iniciar Sesión'), findsOneWidget);
      expect(find.text('Crear Cuenta'), findsOneWidget);
      expect(find.text('Continuar con Google'), findsOneWidget);
      expect(find.text('Entrar como Alumno Invitado (Rápido)'), findsOneWidget);
    });
  });

  group('Interfaz de Alumno', () {
    testWidgets('Muestra tablero de puntos y permite resolver ejercicio aritmético', (WidgetTester tester) async {
      const usuario = UsuarioApp(
        uid: 'alu-1',
        nombre: 'Estudiante Demo',
        rol: RolUsuario.alumno,
        puntosAcumulados: 40,
      );
      final repositorio = FuenteDatosEjercicios();
      final servicioEvaluacion = ServicioEvaluacion();
      final auth = ServicioAuth();

      await tester.pumpWidget(MaterialApp(
        home: PantallaAlumno(
          usuario: usuario,
          repositorio: repositorio,
          servicioEvaluacion: servicioEvaluacion,
          servicioAuth: auth,
        ),
      ));

      await tester.pumpAndSettle();

      // Debe mostrar el nombre del alumno y sus puntos
      expect(find.text('Estudiante Demo'), findsOneWidget);
      expect(find.text('40 pts'), findsOneWidget);

      // Debe mostrar el ejercicio aritmético inicial (125 + 78)
      expect(find.text('125'), findsOneWidget);
      expect(find.text('78'), findsOneWidget);
      expect(find.text('+'), findsOneWidget);

      // Resolver
      await tester.enterText(find.byType(TextField), '203');
      await tester.ensureVisible(find.text('CALIFICAR RESPUESTA'));
      await tester.tap(find.text('CALIFICAR RESPUESTA'));
      await tester.pumpAndSettle();

      expect(find.text('¡Excelente trabajo!'), findsOneWidget);
    });
  });

  group('Interfaz de Profesor', () {
    testWidgets('Muestra catálogo docente, botón crear ejercicio y generador rápido', (WidgetTester tester) async {
      const usuario = UsuarioApp(
        uid: 'prof-1',
        nombre: 'Prof. Ana',
        rol: RolUsuario.profesor,
      );
      final repositorio = FuenteDatosEjercicios();
      final servicioEvaluacion = ServicioEvaluacion();
      final auth = ServicioAuth();

      await tester.pumpWidget(MaterialApp(
        home: PantallaProfesor(
          usuario: usuario,
          repositorio: repositorio,
          servicioEvaluacion: servicioEvaluacion,
          servicioAuth: auth,
        ),
      ));

      await tester.pumpAndSettle();

      // Debe mostrar cabecera de docente y catálogo
      expect(find.text('Docente: Prof. Ana'), findsOneWidget);
      expect(find.text('Catálogo Curricular de Ejercicios'), findsOneWidget);
      expect(find.text('Crear Ejercicio'), findsOneWidget);

      // Acciones rápidas del docente
      expect(find.text('+3 Sumas Verticales'), findsOneWidget);
      expect(find.text('+3 Divisiones Galera'), findsOneWidget);
    });
  });

  group('AppMatematicas Routing', () {
    testWidgets('Muestra PantallaAutenticacion cuando no hay sesión activa', (WidgetTester tester) async {
      final repositorio = FuenteDatosEjercicios([]);
      final servicio = ServicioEvaluacion();
      final auth = ServicioAuth();

      await tester.pumpWidget(AppMatematicas(
        repositorio: repositorio,
        servicioEvaluacion: servicio,
        servicioAuth: auth,
      ));

      await tester.pumpAndSettle();

      expect(find.text('Iniciar Sesión'), findsOneWidget);
    });
  });
}

