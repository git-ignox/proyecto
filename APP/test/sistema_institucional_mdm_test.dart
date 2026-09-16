import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/datos/servicio_mdm_nativo.dart';
import 'package:proyecto/dominio/control_dispositivo/controlador_dispositivo.dart';
import 'package:proyecto/dominio/modelos/politica_dispositivo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Integración Nativa MDM y Modo Kiosco', () {
    const channel = MethodChannel('com.colegiosanmartin.mdm/kiosk');
    final log = <MethodCall>[];

    setUp(() {
      log.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'isDeviceOwner':
            return true;
          case 'startLockTask':
            return true;
          case 'stopLockTask':
            return true;
          case 'setPackageSuspended':
            return true;
          case 'setStatusBarDisabled':
            return true;
          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('ServicioMdmNativo consulta isDeviceOwner e inicia y detiene LockTask', () async {
      final servicio = ServicioMdmNativo(customChannel: channel);

      final isOwner = await servicio.verificarDeviceOwner();
      expect(isOwner, isTrue);

      final kioscoIniciado = await servicio.iniciarModoKiosco(paquetesPermitidos: ['com.puff.proyecto']);
      expect(kioscoIniciado, isTrue);
      expect(servicio.esKioscoActivo, isTrue);

      final paqueteBloqueado = await servicio.bloquearPaquete('com.zhiliaoapp.musically');
      expect(paqueteBloqueado, isTrue);
      expect(servicio.paquetesBloqueados, contains('com.zhiliaoapp.musically'));

      final paqueteDesbloqueado = await servicio.desbloquearPaquete('com.zhiliaoapp.musically');
      expect(paqueteDesbloqueado, isTrue);
      expect(servicio.paquetesBloqueados, isNot(contains('com.zhiliaoapp.musically')));

      final kioscoDetenido = await servicio.detenerModoKiosco();
      expect(kioscoDetenido, isTrue);
      expect(servicio.esKioscoActivo, isFalse);

      expect(log.map((c) => c.method), containsAll([
        'isDeviceOwner',
        'startLockTask',
        'setPackageSuspended',
        'setPackageSuspended',
        'stopLockTask',
      ]));
    });

    test('ControladorAndroid con Device Owner activa LockTask y bloquea apps de la política efectiva', () async {
      final servicio = ServicioMdmNativo(customChannel: channel);
      final controlador = ControladorAndroid(
        tieneDeviceOwner: true,
        servicioMdm: servicio,
      );

      expect(controlador.nivelCapacidad, equals(NivelCapacidadControl.sistemaOperativoNativo));
      expect(controlador.puedeBloquearAppsExternas, isTrue);

      final politica = PlantillaPolitica.modoExamenRiguroso(
        institucionId: 'INST-SAN-MARTIN',
      );

      final efectiva = PoliticaEfectiva(
        nombrePolitica: 'Examen',
        institucionId: 'INST-SAN-MARTIN',
        reglasPorAppId: {for (var a in politica.apps) a.id: a},
      );

      final aplicado = await controlador.aplicarPolitica(efectiva);
      expect(aplicado, isTrue);
      expect(servicio.esKioscoActivo, isTrue);

      // Verificamos que se envió startLockTask
      expect(log.any((c) => c.method == 'startLockTask'), isTrue);

      // Al liberar el dispositivo se detiene LockTask
      final liberado = await controlador.liberarDispositivo();
      expect(liberado, isTrue);
      expect(servicio.esKioscoActivo, isFalse);
      expect(log.any((c) => c.method == 'stopLockTask'), isTrue);
    });

    test('ControladorAndroid sin Device Owner opera en modo soloApp sin invocar LockTask nativo', () async {
      final servicio = ServicioMdmNativo(customChannel: channel);
      final controlador = ControladorAndroid(
        tieneDeviceOwner: false,
        servicioMdm: servicio,
      );

      expect(controlador.nivelCapacidad, equals(NivelCapacidadControl.soloApp));
      expect(controlador.puedeBloquearAppsExternas, isFalse);

      final politica = PlantillaPolitica.modoClaseEstandar(
        institucionId: 'INST-SAN-MARTIN',
      );
      final efectiva = PoliticaEfectiva(
        nombrePolitica: 'Clase',
        institucionId: 'INST-SAN-MARTIN',
        reglasPorAppId: {for (var a in politica.apps) a.id: a},
      );

      await controlador.aplicarPolitica(efectiva);
      // No debe llamar a startLockTask porque no tiene Device Owner
      expect(log.any((c) => c.method == 'startLockTask'), isFalse);
    });

    test('ControladorIOS con Perfil MDM invoca inicio y fin de supervisión en servicio', () async {
      final servicio = ServicioMdmNativo(customChannel: channel);
      final controlador = ControladorIOS(
        tienePerfilMdm: true,
        servicioMdm: servicio,
      );

      expect(controlador.nivelCapacidad, equals(NivelCapacidadControl.sistemaOperativoNativo));
      expect(controlador.puedeBloquearAppsExternas, isTrue);

      final politica = PlantillaPolitica.modoClaseEstandar(
        institucionId: 'INST-SAN-MARTIN',
      );
      final efectiva = PoliticaEfectiva(
        nombrePolitica: 'Clase',
        institucionId: 'INST-SAN-MARTIN',
        reglasPorAppId: {for (var a in politica.apps) a.id: a},
      );

      await controlador.aplicarPolitica(efectiva);
      expect(servicio.esKioscoActivo, isTrue);

      await controlador.liberarDispositivo();
      expect(servicio.esKioscoActivo, isFalse);
    });
  });
}
