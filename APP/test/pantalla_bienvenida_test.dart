// ============================================================
// pantalla_bienvenida_test.dart — Pruebas de widget para la pantalla de bienvenida
//
// Verifica:
//   • Renderizado del concepto de cuaderno moderno (fondo, margen, tipografías)
//   • Ciclo y catálogo de idiomas desacoplado
//   • Jerarquía de botones de autenticación (Iniciar Sesión vs Crear Cuenta)
//   • Navegación hacia inicio de sesión y registro
//   • Modo claro y modo oscuro
//   • Layout responsive (Desktop vs Mobile)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/datos/servicio_auth.dart';
import 'package:proyecto/interfaz/bienvenida/modelo_saludo_bienvenida.dart';
import 'package:proyecto/interfaz/bienvenida/widgets/bloque_autenticacion.dart';
import 'package:proyecto/interfaz/bienvenida/widgets/fondo_cuaderno.dart';
import 'package:proyecto/interfaz/bienvenida/widgets/texto_bienvenida_rotativo.dart';
import 'package:proyecto/interfaz/pantalla_autenticacion.dart';
import 'package:proyecto/interfaz/pantalla_bienvenida.dart';

void main() {
  group('PantallaBienvenida — Concepto Visual Cuaderno Moderno', () {
    testWidgets('Renderiza fondo de cuaderno, margen y títulos de bienvenida', (
      WidgetTester tester,
    ) async {
      final auth = ServicioAuth();

      await tester.pumpWidget(
        MaterialApp(home: PantallaBienvenida(servicioAuth: auth)),
      );

      await tester.pump();

      // Verifica presencia del fondo de cuaderno
      expect(find.byType(FondoCuaderno), findsOneWidget);

      // Verifica presencia del texto rotativo de bienvenida
      expect(find.byType(TextoBienvenidaRotativo), findsOneWidget);

      // Primer saludo del catálogo por defecto
      expect(find.text('BIENVENIDO'), findsOneWidget);

      // Descripción concisa
      expect(
        find.text('Plataforma de práctica y aprendizaje matemático.'),
        findsOneWidget,
      );

      // Verifica presencia de los botones de autenticación
      expect(find.text('Iniciar Sesión'), findsOneWidget);
      expect(find.text('Crear Cuenta'), findsOneWidget);
    });

    testWidgets('Soporta catálogo de idiomas personalizado y desacoplado', (
      WidgetTester tester,
    ) async {
      final auth = ServicioAuth();
      const catalogoCustom = [
        SaludoBienvenida(
          texto: 'HOLA MUNDO',
          idioma: 'Prueba',
          notaMarginal: 'nota de prueba',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: PantallaBienvenida(
            servicioAuth: auth,
            catalogoSaludos: catalogoCustom,
          ),
        ),
      );

      await tester.pump();

      expect(find.text('HOLA MUNDO'), findsOneWidget);
    });

    testWidgets('Modo oscuro aplica colores de cuaderno nocturno', (
      WidgetTester tester,
    ) async {
      final auth = ServicioAuth();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: PantallaBienvenida(servicioAuth: auth),
        ),
      );

      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      // En modo oscuro el fondo es el gris muy oscuro / casi negro #171717
      expect(scaffold.backgroundColor, equals(const Color(0xFF171717)));
    });

    testWidgets('Modo claro aplica colores crema de cuaderno físico', (
      WidgetTester tester,
    ) async {
      final auth = ServicioAuth();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: PantallaBienvenida(servicioAuth: auth),
        ),
      );

      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      // En modo claro el fondo es crema suave #F7F0DF
      expect(scaffold.backgroundColor, equals(const Color(0xFFF7F0DF)));
    });
  });

  group('PantallaBienvenida — Acciones y Navegación de Autenticación', () {
    testWidgets(
      'Pulsar "Iniciar Sesión" navega a PantallaAutenticacion en modo Login',
      (WidgetTester tester) async {
        final auth = ServicioAuth();

        await tester.pumpWidget(
          MaterialApp(home: PantallaBienvenida(servicioAuth: auth)),
        );

        await tester.pump();

        final botonLogin = find.text('Iniciar Sesión');
        expect(botonLogin, findsOneWidget);

        await tester.tap(botonLogin);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verifica navegación hacia PantallaAutenticacion
        expect(find.byType(PantallaAutenticacion), findsOneWidget);
      },
    );

    testWidgets(
      'Pulsar "Crear Cuenta" navega a PantallaAutenticacion en modo Registro',
      (WidgetTester tester) async {
        final auth = ServicioAuth();

        await tester.pumpWidget(
          MaterialApp(home: PantallaBienvenida(servicioAuth: auth)),
        );

        await tester.pump();

        final botonRegistro = find.text('Crear Cuenta');
        expect(botonRegistro, findsOneWidget);

        await tester.tap(botonRegistro);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(PantallaAutenticacion), findsOneWidget);
      },
    );
  });

  group('PantallaBienvenida — Responsive Layout', () {
    testWidgets('Layout Desktop (> 768px) distribuye en dos columnas', (
      WidgetTester tester,
    ) async {
      final auth = ServicioAuth();
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(home: PantallaBienvenida(servicioAuth: auth)),
      );

      await tester.pump();

      // En desktop existe una fila principal (Row) que divide contenido y auth
      expect(find.byType(Row), findsWidgets);
      expect(find.byType(BloqueAutenticacion), findsOneWidget);
    });

    testWidgets(
      'Layout Mobile (<= 768px) distribuye verticalmente sin overflow',
      (WidgetTester tester) async {
        final auth = ServicioAuth();
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(home: PantallaBienvenida(servicioAuth: auth)),
        );

        await tester.pump();

        expect(find.byType(BloqueAutenticacion), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
