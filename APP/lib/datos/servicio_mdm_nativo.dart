import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Estado del aprovisionamiento MDM y modo kiosco en el dispositivo.
class EstadoMdmDispositivo {
  const EstadoMdmDispositivo({
    required this.esDeviceOwner,
    required this.esKioscoActivo,
    required this.plataforma,
    this.paquetesBloqueados = const [],
  });

  final bool esDeviceOwner;
  final bool esKioscoActivo;
  final String plataforma;
  final List<String> paquetesBloqueados;

  EstadoMdmDispositivo copyWith({
    bool? esDeviceOwner,
    bool? esKioscoActivo,
    String? plataforma,
    List<String>? paquetesBloqueados,
  }) {
    return EstadoMdmDispositivo(
      esDeviceOwner: esDeviceOwner ?? this.esDeviceOwner,
      esKioscoActivo: esKioscoActivo ?? this.esKioscoActivo,
      plataforma: plataforma ?? this.plataforma,
      paquetesBloqueados: paquetesBloqueados ?? this.paquetesBloqueados,
    );
  }
}

/// Servicio puente que interactúa con las APIs nativas del SO mediante MethodChannel:
/// - Android: DevicePolicyManager (Device Owner), startLockTask(), stopLockTask(), setStatusBarDisabled.
/// - iOS: ManagedSettings / ScreenTime (Apple School Manager / FamilyControls).
class ServicioMdmNativo {
  ServicioMdmNativo({MethodChannel? customChannel})
      : _channel = customChannel ?? const MethodChannel('com.colegiosanmartin.mdm/kiosk');

  final MethodChannel _channel;
  bool _kioscoActivo = false;
  final List<String> _paquetesBloqueados = [];

  bool get esKioscoActivo => _kioscoActivo;
  List<String> get paquetesBloqueados => List.unmodifiable(_paquetesBloqueados);

  /// Consulta si la app está aprovisionada como Device Owner / Managed Profile en el SO.
  Future<bool> verificarDeviceOwner() async {
    if (kIsWeb) return false;
    try {
      final resultado = await _channel.invokeMethod<bool>('isDeviceOwner');
      return resultado ?? false;
    } on MissingPluginException {
      debugPrint('[MDM] Canal nativo no disponible en esta plataforma (fallback a Nivel 1).');
      return false;
    } catch (e) {
      debugPrint('[MDM] Error al consultar Device Owner: $e');
      return false;
    }
  }

  /// Activa el Modo Kiosco físico estricto (LockTask en Android / Single App Mode en iOS).
  Future<bool> iniciarModoKiosco({List<String> paquetesPermitidos = const []}) async {
    if (kIsWeb) {
      _kioscoActivo = true;
      return true;
    }
    try {
      final res = await _channel.invokeMethod<bool>('startLockTask', {
        'allowedPackages': paquetesPermitidos,
      });
      _kioscoActivo = res ?? true;
      return _kioscoActivo;
    } on MissingPluginException {
      debugPrint('[MDM] Modo Kiosco emulado (canal nativo no vinculado).');
      _kioscoActivo = true;
      return true;
    } catch (e) {
      debugPrint('[MDM] Error al iniciar Modo Kiosco: $e');
      _kioscoActivo = false;
      return false;
    }
  }

  /// Detiene el Modo Kiosco físico y devuelve el control al sistema operativo.
  Future<bool> detenerModoKiosco() async {
    if (kIsWeb) {
      _kioscoActivo = false;
      return true;
    }
    try {
      final res = await _channel.invokeMethod<bool>('stopLockTask');
      _kioscoActivo = !(res ?? true);
      return res ?? true;
    } on MissingPluginException {
      _kioscoActivo = false;
      return true;
    } catch (e) {
      debugPrint('[MDM] Error al detener Modo Kiosco: $e');
      _kioscoActivo = false;
      return false;
    }
  }

  /// Suspende o bloquea la ejecución de un paquete externo (ej. redes sociales / juegos).
  Future<bool> bloquearPaquete(String packageName) async {
    if (kIsWeb) {
      if (!_paquetesBloqueados.contains(packageName)) {
        _paquetesBloqueados.add(packageName);
      }
      return true;
    }
    try {
      final res = await _channel.invokeMethod<bool>('setPackageSuspended', {
        'packageName': packageName,
        'suspended': true,
      });
      if (res == true && !_paquetesBloqueados.contains(packageName)) {
        _paquetesBloqueados.add(packageName);
      }
      return res ?? true;
    } on MissingPluginException {
      if (!_paquetesBloqueados.contains(packageName)) {
        _paquetesBloqueados.add(packageName);
      }
      return true;
    } catch (e) {
      debugPrint('[MDM] Error al suspender paquete $packageName: $e');
      return false;
    }
  }

  /// Desbloquea un paquete previamente suspendido.
  Future<bool> desbloquearPaquete(String packageName) async {
    _paquetesBloqueados.remove(packageName);
    if (kIsWeb) return true;
    try {
      final res = await _channel.invokeMethod<bool>('setPackageSuspended', {
        'packageName': packageName,
        'suspended': false,
      });
      return res ?? true;
    } on MissingPluginException {
      return true;
    } catch (e) {
      debugPrint('[MDM] Error al restaurar paquete $packageName: $e');
      return false;
    }
  }

  /// Habilita o deshabilita la barra de estado y notificaciones del sistema.
  Future<bool> configurarBarraDeEstado({required bool deshabilitada}) async {
    if (kIsWeb) return true;
    try {
      final res = await _channel.invokeMethod<bool>('setStatusBarDisabled', {
        'disabled': deshabilitada,
      });
      return res ?? true;
    } on MissingPluginException {
      return true;
    } catch (e) {
      debugPrint('[MDM] Error al configurar barra de estado: $e');
      return false;
    }
  }
}
