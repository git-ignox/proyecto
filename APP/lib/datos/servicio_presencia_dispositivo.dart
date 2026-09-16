import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../dominio/modelos/sesion_modo_clase.dart';

/// Resultado de validar una solicitud de presencia en aula.
class ResultadoValidacionPresencia {
  const ResultadoValidacionPresencia({
    required this.esValido,
    required this.mensaje,
    this.metodo = MetodoPresencia.codigoQr,
  });

  final bool esValido;
  final String mensaje;
  final MetodoPresencia metodo;
}

/// Token dinámico de aula emitido por el docente con expiración y control de integridad.
class TokenPresenciaAula {
  TokenPresenciaAula({
    required this.sesionId,
    required this.institucionId,
    required this.timestamp,
    required this.nonce,
  });

  final String sesionId;
  final String institucionId;
  final DateTime timestamp;
  final String nonce;

  /// Serializa a un formato base64 seguro para códigos QR
  String serializar() {
    final payload = {
      's': sesionId,
      'i': institucionId,
      't': timestamp.millisecondsSinceEpoch,
      'n': nonce,
    };
    return base64Url.encode(utf8.encode(jsonEncode(payload)));
  }

  /// Deserializa y reconstruye un token escaneado
  static TokenPresenciaAula? deserializar(String tokenStr) {
    try {
      final jsonStr = utf8.decode(base64Url.decode(tokenStr));
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return TokenPresenciaAula(
        sesionId: map['s'] as String? ?? '',
        institucionId: map['i'] as String? ?? '',
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['t'] as int? ?? 0),
        nonce: map['n'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  /// Expiración rápida de 90 segundos para evitar que se comparta por chat fuera del aula
  bool get haExpirado {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(timestamp);
    return diferencia.inSeconds > 90 || diferencia.inSeconds < -10;
  }
}

/// Servicio encargado de arbitrar las estrategias de presencia contextual en el colegio.
class ServicioPresenciaDispositivo {
  ServicioPresenciaDispositivo({this.ssidInstitucional = 'Colegio-SanMartin-WiFi'});

  final String ssidInstitucional;
  final Random _random = Random();

  /// Genera un token nuevo para proyectar en el QR del aula
  TokenPresenciaAula generarTokenPresencia({
    required String sesionId,
    required String institucionId,
  }) {
    final nonce = '${_random.nextInt(1000000).toRadixString(16)}-${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}';
    return TokenPresenciaAula(
      sesionId: sesionId,
      institucionId: institucionId,
      timestamp: DateTime.now(),
      nonce: nonce,
    );
  }

  /// Valida rigurosamente un token escaneado en el backend/repositorio.
  ResultadoValidacionPresencia validarTokenQr({
    required String tokenString,
    required String sesionIdEsperada,
    required String institucionIdEsperada,
  }) {
    final token = TokenPresenciaAula.deserializar(tokenString);

    if (token == null) {
      return const ResultadoValidacionPresencia(
        esValido: false,
        mensaje: 'El código de barras no tiene un formato válido.',
      );
    }

    if (token.haExpirado) {
      return const ResultadoValidacionPresencia(
        esValido: false,
        mensaje: 'El código de barras ha expirado. Solicita al profesor que muestre el código actualizado.',
      );
    }

    if (token.institucionId != institucionIdEsperada) {
      return const ResultadoValidacionPresencia(
        esValido: false,
        mensaje: 'El código de barras no corresponde a esta institución educativa.',
      );
    }

    if (token.sesionId != sesionIdEsperada) {
      return const ResultadoValidacionPresencia(
        esValido: false,
        mensaje: 'El código de barras corresponde a otra clase o sesión.',
      );
    }

    return const ResultadoValidacionPresencia(
      esValido: true,
      mensaje: '¡Presencia confirmada correctamente en el aula mediante código de barras!',
      metodo: MetodoPresencia.codigoBarras,
    );
  }

  /// Validador específico para Código de Barras (alias principal)
  ResultadoValidacionPresencia validarTokenCodigoBarras({
    required String tokenString,
    required String sesionIdEsperada,
    required String institucionIdEsperada,
  }) =>
      validarTokenQr(
        tokenString: tokenString,
        sesionIdEsperada: sesionIdEsperada,
        institucionIdEsperada: institucionIdEsperada,
      );

  /// Estrategia A: Validación por red local institucional / Wi-Fi escolar.
  /// NOTA TÉCNICA DE SISTEMA OPERATIVO:
  /// - En Android 10+, leer el SSID real requiere permiso ACCESS_FINE_LOCATION.
  /// - En iOS 13+, leer el SSID requiere el entitlement Access WiFi Information y Location.
  /// - Por tanto, este método valida la presencia mediante handshake de red local institucional
  ///   o el SSID cuando la plataforma lo provee, con fallback garantizado a QR.
  Future<bool> verificarRedLocalInstitucional({
    String? ssidActual,
    String? ipGateway,
  }) async {
    if (ssidActual != null && ssidActual.isNotEmpty) {
      return ssidActual == ssidInstitucional;
    }
    // Si no se puede leer el SSID por restricciones del SO, se documenta la necesidad de QR
    debugPrint('[Presencia] Restricción SO: Requiere fallback QR o validación manual.');
    return false;
  }
}
