import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/datos/servicio_presencia_dispositivo.dart';

void main() {
  group('Estrategia de Presencia por QR Dinámico (Fase 8)', () {
    late ServicioPresenciaDispositivo servicio;

    setUp(() {
      servicio = ServicioPresenciaDispositivo();
    });

    test('Token dinámico válido y reciente es aceptado correctamente', () {
      final token = servicio.generarTokenPresencia(
        sesionId: 'SES-100',
        institucionId: 'INST-SAN-MARTIN',
      );

      final tokenSerializado = token.serializar();

      final resultado = servicio.validarTokenQr(
        tokenString: tokenSerializado,
        sesionIdEsperada: 'SES-100',
        institucionIdEsperada: 'INST-SAN-MARTIN',
      );

      expect(resultado.esValido, isTrue);
      expect(resultado.mensaje, contains('confirmada'));
    });

    test('Token expirado (mayor a 90 segundos) es rechazado en backend', () {
      final tokenAntiguo = TokenPresenciaAula(
        sesionId: 'SES-100',
        institucionId: 'INST-SAN-MARTIN',
        timestamp: DateTime.now().subtract(const Duration(seconds: 95)),
        nonce: 'nonce-viejo',
      );

      final resultado = servicio.validarTokenQr(
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

      final resultado = servicio.validarTokenQr(
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

      final resultado = servicio.validarTokenQr(
        tokenString: tokenOtraSesion.serializar(),
        sesionIdEsperada: 'SESION-MATEMATICAS-3B',
        institucionIdEsperada: 'INST-SAN-MARTIN',
      );

      expect(resultado.esValido, isFalse);
      expect(resultado.mensaje, contains('otra clase o sesión'));
    });
  });
}
