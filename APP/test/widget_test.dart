import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/datos/fuente_datos_ejercicios.dart';
import 'package:proyecto/dominio/evaluadores/servicio_evaluacion.dart';
import 'package:proyecto/dominio/modelos/numerico.dart';
import 'package:proyecto/dominio/modelos/posicion_curricular.dart';
import 'package:proyecto/interfaz/pantalla_ejercicios.dart';

void main() {
  testWidgets('PantallaEjercicios muestra estado vacío inicial y permite crear ejercicio', (WidgetTester tester) async {
    final repositorio = FuenteDatosEjercicios([]);
    final servicio = ServicioEvaluacion();

    await tester.pumpWidget(MaterialApp(
      home: PantallaEjercicios(
        repositorio: repositorio,
        servicioEvaluacion: servicio,
      ),
    ));

    await tester.pumpAndSettle();

    // Debe mostrar la pantalla de bienvenida / estado sin ejercicios
    expect(find.text('No hay ejercicios creados aún'), findsOneWidget);
    expect(find.text('GENERAR PREGUNTA DE ARITMÉTICA'), findsOneWidget);
  });

  testWidgets('PantallaEjercicios muestra y califica ejercicio cuando hay datos', (WidgetTester tester) async {
    final repositorio = FuenteDatosEjercicios([
      const Numerico(
        id: '1',
        posicion: PosicionCurricular(tema: 1, subtema: 1, leccion: 1),
        nivel: 1,
        enunciado: '¿Cuánto es 5 / 4?',
        valorEsperado: 1.25,
      ),
    ]);
    final servicio = ServicioEvaluacion();

    await tester.pumpWidget(MaterialApp(
      home: PantallaEjercicios(
        repositorio: repositorio,
        servicioEvaluacion: servicio,
      ),
    ));

    await tester.pumpAndSettle();

    expect(find.textContaining('1.1.1'), findsOneWidget);
    expect(find.text('CALIFICAR RESPUESTA'), findsOneWidget);

    // Escribir respuesta correcta
    await tester.enterText(find.byType(TextField), '1.25');
    await tester.ensureVisible(find.text('CALIFICAR RESPUESTA'));
    await tester.tap(find.text('CALIFICAR RESPUESTA'));
    await tester.pumpAndSettle();

    expect(find.text('¡CORRECTO!'), findsOneWidget);
  });

  testWidgets('PantallaEjercicios renderiza y califica ejercicio aritmético vertical', (WidgetTester tester) async {
    final repositorio = FuenteDatosEjercicios();
    final servicio = ServicioEvaluacion();

    await tester.pumpWidget(MaterialApp(
      home: PantallaEjercicios(
        repositorio: repositorio,
        servicioEvaluacion: servicio,
      ),
    ));

    await tester.pumpAndSettle();

    // El primer ejercicio predeterminado es ARIT-1.1.1 (125 + 78 = 203)
    expect(find.text('125'), findsOneWidget);
    expect(find.text('78'), findsOneWidget);
    expect(find.text('+'), findsOneWidget);

    // Escribir 203 en el campo de respuesta
    await tester.enterText(find.byType(TextField), '203');
    await tester.ensureVisible(find.text('CALIFICAR RESPUESTA'));
    await tester.tap(find.text('CALIFICAR RESPUESTA'));
    await tester.pumpAndSettle();

    expect(find.text('¡CORRECTO!'), findsOneWidget);
  });
}

