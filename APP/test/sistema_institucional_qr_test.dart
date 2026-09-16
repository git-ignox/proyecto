import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/datos/servicio_presencia_dispositivo.dart';
import 'package:proyecto/dominio/modelos/sesion_modo_clase.dart';
import 'package:proyecto/interfaz/comun/widget_codigo_barras.dart';

void main() {
  group('Estrategia de Presencia por Código de Barras Dinámico', () {
    late ServicioPresenciaDispositivo servicio;

    setUp(() {
      servicio = ServicioPresenciaDispositivo();
    });

    test('Token dinámico de código de barras es aceptado correctamente con MetodoPresencia.codigoBarras', () {
      final token = servicio.generarTokenPresencia(
        sesionId: 'SES-100',
        institucionId: 'INST-SAN-MARTIN',
      );

      final tokenSerializado = token.serializar();

      final resultado = servicio.validarTokenCodigoBarras(
        tokenString: tokenSerializado,
        sesionIdEsperada: 'SES-100',
        institucionIdEsperada: 'INST-SAN-MARTIN',
      );

      expect(resultado.esValido, isTrue);
      expect(resultado.metodo, equals(MetodoPresencia.codigoBarras));
      expect(resultado.mensaje, contains('confirmada'));
      expect(resultado.mensaje, contains('código de barras'));
    });

    test('Token expirado (mayor a 90 segundos) es rechazado en backend', () {
      final tokenAntiguo = TokenPresenciaAula(
        sesionId: 'SES-100',
        institucionId: 'INST-SAN-MARTIN',
        timestamp: DateTime.now().subtract(const Duration(seconds: 95)),
        nonce: 'nonce-viejo',
      );

      final resultado = servicio.validarTokenCodigoBarras(
        tokenString: tokenAntiguo.serializar(),
        sesionIdEsperada: 'SES-100',
        institucionIdEsperada: 'INST-SAN-MARTIN',
      );

      expect(resultado.esValido, isFalse);
      expect(resultado.mensaje, contains('expirado'));
    });

    test('Token de otra institución es rechazado tajantemente', () {
      final tokenOtroColegio = servicio.generarTokenPresencia(
        sesionId: 'SES-100',
        institucionId: 'OTRO-COLEGIO-EXTERNO',
      );

      final resultado = servicio.validarTokenCodigoBarras(
        tokenString: tokenOtroColegio.serializar(),
        sesionIdEsperada: 'SES-100',
        institucionIdEsperada: 'INST-SAN-MARTIN',
      );

      expect(resultado.esValido, isFalse);
      expect(resultado.mensaje, contains('no corresponde a esta institución'));
    });

    test('Token de otra sesión o clase es rechazado', () {
      final tokenOtraSesion = servicio.generarTokenPresencia(
        sesionId: 'SESION-HISTORIA-101',
        institucionId: 'INST-SAN-MARTIN',
      );

      final resultado = servicio.validarTokenCodigoBarras(
        tokenString: tokenOtraSesion.serializar(),
        sesionIdEsperada: 'SESION-MATEMATICAS-3B',
        institucionIdEsperada: 'INST-SAN-MARTIN',
      );

      expect(resultado.esValido, isFalse);
      expect(resultado.mensaje, contains('otra clase o sesión'));
    });

    testWidgets('WidgetCodigoBarras renderiza barras y texto legible', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WidgetCodigoBarras(
              codigo: 'BAR-TEST-1234',
            ),
          ),
        ),
      );

      expect(find.byType(WidgetCodigoBarras), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('BAR-TEST-1234'), findsOneWidget);
    });
  });
}
