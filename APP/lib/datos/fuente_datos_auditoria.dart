import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../dominio/modelos/registro_auditoria.dart';
import '../dominio/modelos/usuario_app.dart';
import 'repositorio_auditoria.dart';

/// Implementación de [RepositorioAuditoria] con almacenamiento en memoria y sincronización en Firestore.
class FuenteDatosAuditoria implements RepositorioAuditoria {
  FuenteDatosAuditoria({FirebaseFirestore? firestore})
      : _customFirestore = firestore {
    _inicializarDatosPredeterminados();
  }

  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  final List<RegistroAuditoria> _eventos = [];
  final StreamController<List<RegistroAuditoria>> _controller =
      StreamController<List<RegistroAuditoria>>.broadcast();

  void _inicializarDatosPredeterminados() {
    const instId = 'INST-SAN-MARTIN';

    // Eventos iniciales de muestra para demostración ejecutiva
    _eventos.addAll([
      RegistroAuditoria(
        id: 'AUD-001',
        fecha: DateTime.now().subtract(const Duration(hours: 3)),
        tipo: TipoEventoAuditoria.cambioPolitica,
        usuarioUid: 'dir-01',
        usuarioNombre: 'Lic. María Elena Walsh (Directora)',
        rolUsuario: RolUsuario.direccion,
        institucionId: instId,
        descripcion: 'Creación de la directiva institucional de control de aplicaciones para el semestre.',
        detalles: {'politicaId': 'POL-BASE-INSTITUCIONAL'},
      ),
      RegistroAuditoria(
        id: 'AUD-002',
        fecha: DateTime.now().subtract(const Duration(hours: 2)),
        tipo: TipoEventoAuditoria.cambioPermisos,
        usuarioUid: 'dir-01',
        usuarioNombre: 'Lic. María Elena Walsh (Directora)',
        rolUsuario: RolUsuario.direccion,
        institucionId: instId,
        descripcion: 'Asignación de permiso de Modo Examen y Excepciones Temporales al docente Prof. Roberto Gómez.',
        detalles: {'profesorUid': 'prof-roberto', 'permisos': ['activar_modo_examen', 'permitir_app_temporalmente']},
      ),
    ]);

    _emitirCambios(instId);
  }

  void _emitirCambios(String institucionId) {
    if (!_controller.isClosed) {
      final lista = _eventos
          .where((e) => e.institucionId == institucionId)
          .toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));
      _controller.add(lista);
    }
  }

  @override
  Future<void> registrarEvento({
    required TipoEventoAuditoria tipo,
    required UsuarioApp usuario,
    String? cursoId,
    required String descripcion,
    Map<String, dynamic> detalles = const {},
  }) async {
    final evento = RegistroAuditoria(
      id: 'AUD-${DateTime.now().millisecondsSinceEpoch}',
      fecha: DateTime.now(),
      tipo: tipo,
      usuarioUid: usuario.uid,
      usuarioNombre: usuario.nombre,
      rolUsuario: usuario.rol,
      institucionId: usuario.institucionId,
      cursoId: cursoId,
      descripcion: descripcion,
      detalles: detalles,
    );

    _eventos.insert(0, evento);
    _emitirCambios(usuario.institucionId);

    final fs = _firestore;
    if (fs != null) {
      try {
        await fs
            .collection('auditoria_institucional')
            .doc(evento.id)
            .set(evento.toMap())
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('Aviso persistencia Firestore auditoría: $e');
      }
    }
  }

  @override
  Future<List<RegistroAuditoria>> obtenerEventosPorInstitucion(
    String institucionId, {
    int limite = 50,
  }) async {
    final filtrados = _eventos
        .where((e) => e.institucionId == institucionId)
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    if (filtrados.length > limite) {
      return filtrados.sublist(0, limite);
    }
    return filtrados;
  }

  @override
  Stream<List<RegistroAuditoria>> eventosStream(String institucionId) {
    return _controller.stream;
  }
}
