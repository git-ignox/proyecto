import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/datos/fuente_datos_ejercicios.dart';
import 'package:proyecto/datos/servicio_auth.dart';
import 'package:proyecto/dominio/evaluadores/servicio_evaluacion.dart';
import 'package:proyecto/interfaz/pantalla_autenticacion.dart';
import 'package:proyecto/interfaz/pantalla_bienvenida.dart';
import 'package:proyecto/interfaz/pantalla_profesor.dart';
import 'package:proyecto/main.dart';

void main() {
  testWidgets('Flujo completo de autenticación desde Bienvenida', (WidgetTester tester) async {
    final repositorio = FuenteDatosEjercicios([]);
    final servicioEvaluacion = ServicioEvaluacion();
    final auth = ServicioAuth();

    await tester.pumpWidget(AppMatematicas(
      repositorio: repositorio,
      servicioEvaluacion: servicioEvaluacion,
      servicioAuth: auth,
    ));

    await tester.pumpAndSettle();

    // 1. Debe estar en PantallaBienvenida
    expect(find.byType(PantallaBienvenida), findsOneWidget);

    // 2. Tocar "Iniciar Sesión"
    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pumpAndSettle();

    // 3. Debe estar en PantallaAutenticacion
    expect(find.byType(PantallaAutenticacion), findsOneWidget);

    // 4. Tocar "Docente Demo"
    await tester.ensureVisible(find.text('Docente Demo'));
    await tester.tap(find.text('Docente Demo'));
    await tester.pumpAndSettle();

    // 5. Debe haber navegado a PantallaProfesor y cerrado PantallaAutenticacion
    expect(find.byType(PantallaProfesor), findsOneWidget);
    expect(find.byType(PantallaAutenticacion), findsNothing);
  });

  testWidgets('Flujo de acceso rápido Alumno Invitado', (WidgetTester tester) async {
    final repositorio = FuenteDatosEjercicios([]);
    final servicioEvaluacion = ServicioEvaluacion();
    final auth = ServicioAuth();

    await tester.pumpWidget(AppMatematicas(
      repositorio: repositorio,
      servicioEvaluacion: servicioEvaluacion,
      servicioAuth: auth,
    ));

    await tester.pumpAndSettle();

    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pumpAndSettle();

    expect(find.byType(PantallaAutenticacion), findsOneWidget);

    final botonInvitado = find.text('Entrar como Alumno Invitado (Rápido)');
    await tester.ensureVisible(botonInvitado);
    await tester.tap(botonInvitado);
    await tester.pumpAndSettle();

    expect(find.byType(PantallaAutenticacion), findsNothing);
  });

  testWidgets('Flujo de Crear Cuenta con email y contraseña', (WidgetTester tester) async {
    final repositorio = FuenteDatosEjercicios([]);
    final servicioEvaluacion = ServicioEvaluacion();
    final auth = ServicioAuth();

    await tester.pumpWidget(AppMatematicas(
      repositorio: repositorio,
      servicioEvaluacion: servicioEvaluacion,
      servicioAuth: auth,
    ));

    await tester.pumpAndSettle();

    await tester.tap(find.text('Crear Cuenta'));
    await tester.pumpAndSettle();

    expect(find.byType(PantallaAutenticacion), findsOneWidget);

    // Ingresar datos de registro
    final campos = find.byType(TextField);
    await tester.enterText(campos.at(0), 'Carlos Perez');
    await tester.enterText(campos.at(1), 'carlos@ejemplo.com');
    await tester.enterText(campos.at(2), 'password123');

    // Tocar botón Crear cuenta
    final botonSubmit = find.text('Crear cuenta');
    await tester.ensureVisible(botonSubmit);
    await tester.tap(botonSubmit);
    await tester.pumpAndSettle();

    expect(find.byType(PantallaAutenticacion), findsNothing);
  });

  testWidgets('Flujo de Iniciar Sesión con email y contraseña', (WidgetTester tester) async {
    final repositorio = FuenteDatosEjercicios([]);
    final servicioEvaluacion = ServicioEvaluacion();
    final auth = ServicioAuth();

    await tester.pumpWidget(AppMatematicas(
      repositorio: repositorio,
      servicioEvaluacion: servicioEvaluacion,
      servicioAuth: auth,
    ));

    await tester.pumpAndSettle();

    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pumpAndSettle();

    expect(find.byType(PantallaAutenticacion), findsOneWidget);

    final campos = find.byType(TextField);
    await tester.enterText(campos.at(0), 'estudiante@ejemplo.com');
    await tester.enterText(campos.at(1), 'password123');

    final botonSubmit = find.text('Iniciar sesión');
    await tester.ensureVisible(botonSubmit);
    await tester.tap(botonSubmit);
    await tester.pumpAndSettle();

    expect(find.byType(PantallaAutenticacion), findsNothing);
  });
}
