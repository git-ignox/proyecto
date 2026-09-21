import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/datos/coordinador_sincronizacion_offline.dart';
import 'package:proyecto/datos/fuente_datos_materiales_offline.dart';
import 'package:proyecto/dominio/modelos/recurso_educativo_offline.dart';
import 'package:proyecto/dominio/sincronizacion/calculador_disponibilidad_semana.dart';
import 'package:proyecto/interfaz/offline/widget_tarjeta_disponibilidad_offline.dart';

void main() {
  group('Métrica y Widget de Disponibilidad Offline', () {
    late CalculadorDisponibilidadSemana calculador;
    final ahora = DateTime(2026, 9, 21, 8, 0);

    setUp(() {
      calculador = const CalculadorDisponibilidadSemana();
    });

    test('Calcula ponderación exacta: 2 obligatorios listos y 1 opcional pendiente', () {
      // Obligatorio listo (peso 3)
      final r1 = RecursoEducativoOffline(
        id: 'r1',
        claseId: 'c1',
        materia: 'Matemáticas',
        titulo: 'Guía 1',
        descripcion: 'Descargado',
        tipoRecurso: TipoRecursoEducativo.pdf,
        remoteUrl: 'https://cdn.com/1.pdf',
        localPath: '/data/1.pdf',
        tamanoBytes: 1024,
        checksumSha256: 'h1',
        esObligatorio: true,
        fechaUsoClase: ahora.add(const Duration(days: 1)),
      );

      // Obligatorio listo (peso 3)
      final r2 = RecursoEducativoOffline(
        id: 'r2',
        claseId: 'c1',
        materia: 'Matemáticas',
        titulo: 'Guía 2',
        descripcion: 'Descargado',
        tipoRecurso: TipoRecursoEducativo.pdf,
        remoteUrl: 'https://cdn.com/2.pdf',
        localPath: '/data/2.pdf',
        tamanoBytes: 1024,
        checksumSha256: 'h2',
        esObligatorio: true,
        fechaUsoClase: ahora.add(const Duration(days: 2)),
      );

      // Opcional pendiente (peso 1)
      final r3 = RecursoEducativoOffline(
        id: 'r3',
        claseId: 'c1',
        materia: 'Historia',
        titulo: 'Lectura Opcional',
        descripcion: 'Pendiente',
        tipoRecurso: TipoRecursoEducativo.pdf,
        remoteUrl: 'https://cdn.com/3.pdf',
        localPath: null, // No descargado
        tamanoBytes: 1024,
        checksumSha256: 'h3',
        esObligatorio: false,
        fechaUsoClase: ahora.add(const Duration(days: 3)),
      );

      final metrica = calculador.calcular(
        recursos: [r1, r2, r3],
        ahora: ahora,
      );

      // Puntos totales = 3 + 3 + 1 = 7. Puntos obtenidos = 3 + 3 = 6.
      // Porcentaje = 6/7 * 100 = 85.7% -> 86%
      expect(metrica.porcentajeListo, equals(86));
      expect(metrica.totalMaterialesSemana, equals(3));
      expect(metrica.materialesListos, equals(2));
      expect(metrica.totalObligatorios, equals(2));
      expect(metrica.obligatoriosListos, equals(2));
      expect(metrica.desglosePorMateria['Matemáticas'], equals(100.0));
      expect(metrica.desglosePorMateria['Historia'], equals(0.0));
      expect(
        metrica.mensajeResumen,
        equals('86% del material de esta semana está disponible sin internet'),
      );
    });

    testWidgets('WidgetTarjetaDisponibilidadOffline renderiza mensaje y progreso correctamente',
        (tester) async {
      final ahoraTest = DateTime.now();

      // Creamos 1 recurso ya descargado al 100%
      final recursoListo = RecursoEducativoOffline(
        id: 'r-listo',
        claseId: 'c1',
        materia: 'Matemáticas',
        titulo: 'Guía Semana',
        descripcion: 'Listo',
        tipoRecurso: TipoRecursoEducativo.pdf,
        remoteUrl: 'https://cdn.com/listo.pdf',
        localPath: '/data/listo.pdf',
        tamanoBytes: 2048,
        checksumSha256: 'hash_listo',
        esObligatorio: true,
        fechaUsoClase: ahoraTest.add(const Duration(days: 1)),
      );

      final repo = FuenteDatosMaterialesOffline(
        materialesIniciales: [recursoListo],
      );

      final coordinador = CoordinadorSincronizacionOffline(
        repositorio: repo,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WidgetTarjetaDisponibilidadOffline(
              coordinador: coordinador,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Debe mostrar el texto claro del porcentaje
      expect(find.textContaining('100% del material de esta semana está disponible sin internet'),
          findsOneWidget);
      expect(find.text('Disponibilidad sin conexión'), findsOneWidget);
      expect(find.text('WiFi activo'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
