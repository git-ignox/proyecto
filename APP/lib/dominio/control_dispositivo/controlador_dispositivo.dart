import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../datos/servicio_mdm_nativo.dart';
import '../modelos/politica_dispositivo.dart';

/// Nivel de capacidad técnica disponible en el dispositivo.
enum NivelCapacidadControl {
  /// Supervisión dentro de la app educativa (Nivel 1):
  /// Entorno pedagógico controlado, bloqueo de navegación interna,
  /// detección de pérdida de foco y herramientas permitidas en pantalla.
  soloApp,

  /// Control a nivel de Sistema Operativo (Nivel 2):
  /// Requiere MDM institucional (Apple School Manager / FamilyControls en iOS,
  /// o Device Owner / Android Enterprise en Android).
  sistemaOperativoNativo,
}

/// Estado actual del bloqueo contextual.
enum EstadoBloqueoDispositivo {
  inactivo,
  activoApp,
  activoSistemaOperativo,
}

/// Contrato base que desacopla la supervisión educativa de las APIs nativas del SO.
abstract class ControladorDispositivo {
  NivelCapacidadControl get nivelCapacidad;
  bool get puedeBloquearAppsExternas;
  String get descripcionCapacidad;
  EstadoBloqueoDispositivo get estadoActual;

  /// Aplica la política resuelta en el dispositivo.
  Future<bool> aplicarPolitica(PoliticaEfectiva politica);

  /// Libera el dispositivo restaurando el uso libre.
  Future<bool> liberarDispositivo();

  /// Registra un evento de pérdida de foco (ej. cuando el alumno sale de la app).
  void registrarPerdidaFoco({required String motivo});

  /// Stream reactivo de incidencias de foco.
  Stream<String> get perdidaFocoStream;

  /// Factory para resolver el controlador según la plataforma y entorno real.
  factory ControladorDispositivo.crearParaPlataformaActual({
    bool forzarSoloApp = false,
  }) {
    if (forzarSoloApp) return ControladorSoloApp();

    if (kIsWeb) {
      return ControladorSoloApp(
        plataformaNombre: 'Navegador Web (Supervisión en pestaña)',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return ControladorAndroid();
      case TargetPlatform.iOS:
        return ControladorIOS();
      default:
        return ControladorSoloApp(
          plataformaNombre: 'Escritorio / Entorno de pruebas',
        );
    }
  }
}

/// Implementación Nivel 1: Supervisión dentro de nuestra aplicación educativa.
/// Funciona de forma universal sin requerir permisos especiales del SO ni MDM.
class ControladorSoloApp implements ControladorDispositivo {
  ControladorSoloApp({this.plataformaNombre = 'App Educativa Supervisada'});

  final String plataformaNombre;
  EstadoBloqueoDispositivo _estado = EstadoBloqueoDispositivo.inactivo;
  final StreamController<String> _perdidaFocoController =
      StreamController<String>.broadcast();

  @override
  NivelCapacidadControl get nivelCapacidad => NivelCapacidadControl.soloApp;

  @override
  bool get puedeBloquearAppsExternas => false;

  @override
  String get descripcionCapacidad =>
      '$plataformaNombre: Control en-app con monitoreo de foco y dock de herramientas permitidas.';

  @override
  EstadoBloqueoDispositivo get estadoActual => _estado;

  @override
  Future<bool> aplicarPolitica(PoliticaEfectiva politica) async {
    _estado = EstadoBloqueoDispositivo.activoApp;
    debugPrint('[ControladorSoloApp] Política activada: ${politica.nombrePolitica}');
    return true;
  }

  @override
  Future<bool> liberarDispositivo() async {
    _estado = EstadoBloqueoDispositivo.inactivo;
    debugPrint('[ControladorSoloApp] Dispositivo liberado.');
    return true;
  }

  @override
  void registrarPerdidaFoco({required String motivo}) {
    if (_estado != EstadoBloqueoDispositivo.inactivo) {
      _perdidaFocoController.add(motivo);
    }
  }

  @override
  Stream<String> get perdidaFocoStream => _perdidaFocoController.stream;
}

/// Implementación para Android.
/// Si está aprovisionada como Device Owner, invoca DevicePolicyManager / LockTask nativo.
/// Si no está aprovisionada, opera transparentemente en Nivel 1 (Supervisión en App).
class ControladorAndroid extends ControladorSoloApp {
  ControladorAndroid({
    this.tieneDeviceOwner = false,
    ServicioMdmNativo? servicioMdm,
  })  : _mdm = servicioMdm ?? ServicioMdmNativo(),
        super(plataformaNombre: 'Android');

  final bool tieneDeviceOwner;
  final ServicioMdmNativo _mdm;
  ServicioMdmNativo get servicioMdm => _mdm;

  @override
  NivelCapacidadControl get nivelCapacidad => tieneDeviceOwner
      ? NivelCapacidadControl.sistemaOperativoNativo
      : NivelCapacidadControl.soloApp;

  @override
  bool get puedeBloquearAppsExternas => tieneDeviceOwner;

  @override
  String get descripcionCapacidad => tieneDeviceOwner
      ? 'Android Device Owner activo: Bloqueo nativo de paquetes por política MDM y LockTask.'
      : 'Android estándar: Supervisión en app y detección de pérdida de foco (Requiere Device Owner para bloqueo a nivel SO).';

  @override
  Future<bool> aplicarPolitica(PoliticaEfectiva politica) async {
    await super.aplicarPolitica(politica);
    if (tieneDeviceOwner) {
      debugPrint('[ControladorAndroid] Activando LockTask y suspendiendo paquetes vía DevicePolicyManager...');
      await _mdm.iniciarModoKiosco();
      for (final app in politica.reglasPorAppId.values) {
        if (!app.esPermitida && app.paqueteAndroid != null) {
          await _mdm.bloquearPaquete(app.paqueteAndroid!);
        }
      }
    }
    return true;
  }

  @override
  Future<bool> liberarDispositivo() async {
    await super.liberarDispositivo();
    if (tieneDeviceOwner) {
      debugPrint('[ControladorAndroid] Liberando LockTask y restaurando paquetes...');
      await _mdm.detenerModoKiosco();
      for (final paquete in List<String>.from(_mdm.paquetesBloqueados)) {
        await _mdm.desbloquearPaquete(paquete);
      }
    }
    return true;
  }
}

/// Implementación para iOS.
/// Si cuenta con perfil MDM / ManagedSettings vinculados, activa el escudo de aplicaciones.
/// Sin dicha configuración, opera limpiamente en Nivel 1 (Supervisión en App).
class ControladorIOS extends ControladorSoloApp {
  ControladorIOS({
    this.tienePerfilMdm = false,
    ServicioMdmNativo? servicioMdm,
  })  : _mdm = servicioMdm ?? ServicioMdmNativo(),
        super(plataformaNombre: 'iOS');

  final bool tienePerfilMdm;
  final ServicioMdmNativo _mdm;
  ServicioMdmNativo get servicioMdm => _mdm;

  @override
  NivelCapacidadControl get nivelCapacidad => tienePerfilMdm
      ? NivelCapacidadControl.sistemaOperativoNativo
      : NivelCapacidadControl.soloApp;

  @override
  bool get puedeBloquearAppsExternas => tienePerfilMdm;

  @override
  String get descripcionCapacidad => tienePerfilMdm
      ? 'iOS ManagedSettings activo: Perfil MDM/Apple School Manager vinculado.'
      : 'iOS estándar: Supervisión en app y detección de minimización (Requiere perfil MDM o ManagedSettings para bloqueo a nivel SO).';

  @override
  Future<bool> aplicarPolitica(PoliticaEfectiva politica) async {
    await super.aplicarPolitica(politica);
    if (tienePerfilMdm) {
      debugPrint('[ControladorIOS] Aplicando ManagedSettingsStore.shield.applications...');
      await _mdm.iniciarModoKiosco();
    }
    return true;
  }

  @override
  Future<bool> liberarDispositivo() async {
    await super.liberarDispositivo();
    if (tienePerfilMdm) {
      debugPrint('[ControladorIOS] Liberando ManagedSettingsStore...');
      await _mdm.detenerModoKiosco();
    }
    return true;
  }
}
