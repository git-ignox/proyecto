import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../dominio/modelos/permiso_institucional.dart';
import '../dominio/modelos/politica_dispositivo.dart';
import '../dominio/modelos/registro_auditoria.dart';
import '../dominio/modelos/sesion_modo_clase.dart';
import '../dominio/modelos/usuario_app.dart';
import 'repositorio_auditoria.dart';
import 'repositorio_politicas.dart';
import 'repositorio_sesiones_clase.dart';
import 'servicio_presencia_dispositivo.dart';

/// Implementación de [RepositorioSesionesClase] con control de autoridad en backend,
/// streams reactivos y persistencia en segundo plano en Cloud Firestore.
class FuenteDatosSesionesClase implements RepositorioSesionesClase {
  FuenteDatosSesionesClase({
    required RepositorioPoliticas repositorioPoliticas,
    required RepositorioAuditoria repositorioAuditoria,
    ServicioPresenciaDispositivo? servicioPresencia,
    FirebaseFirestore? firestore,
  })  : _politicasRepo = repositorioPoliticas,
        _auditoriaRepo = repositorioAuditoria,
        _presenciaServicio = servicioPresencia ?? ServicioPresenciaDispositivo(),
        _customFirestore = firestore {
    _inicializarDatosPredeterminados();
  }

  final RepositorioPoliticas _politicasRepo;
  final RepositorioAuditoria _auditoriaRepo;
  final ServicioPresenciaDispositivo _presenciaServicio;
  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  final Map<String, SesionModoClase> _sesiones = {};
  final StreamController<List<SesionModoClase>> _sesionesStreamController =
      StreamController<List<SesionModoClase>>.broadcast();

  void _inicializarDatosPredeterminados() {
    // Sesión de demostración activa en el curso 3B de Matemáticas
    final tokenObj = _presenciaServicio.generarTokenPresencia(
      sesionId: 'SESION-DEMO-3B',
      institucionId: 'INST-SAN-MARTIN',
    );

    final politicaBase = PlantillaPolitica.modoClaseEstandar(
      institucionId: 'INST-SAN-MARTIN',
      id: 'POL-SESION-3B',
    );

    // Alumnos presentes y 1 alumno ausente (para verificar la regla fundamental)
    final mapaPresentes = <String, RegistroPresenciaDispositivo>{
      'alumno-demo-1': RegistroPresenciaDispositivo(
        alumnoUid: 'alumno-demo-1',
        alumnoNombre: 'Sofía Valenzuela',
        estaPresente: true,
        cumplePolitica: true,
        metodo: MetodoPresencia.codigoQr,
        momentoRegistro: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
      'alumno-demo-2': RegistroPresenciaDispositivo(
        alumnoUid: 'alumno-demo-2',
        alumnoNombre: 'Mateo Rivas',
        estaPresente: true,
        cumplePolitica: true,
        metodo: MetodoPresencia.redInstitucionalWifi,
        momentoRegistro: DateTime.now().subtract(const Duration(minutes: 24)),
      ),
      'alumno-demo-3': RegistroPresenciaDispositivo(
        alumnoUid: 'alumno-demo-3',
        alumnoNombre: 'Camila Soto',
        estaPresente: true,
        cumplePolitica: true,
        metodo: MetodoPresencia.manualDocente,
        momentoRegistro: DateTime.now().subtract(const Duration(minutes: 20)),
      ),
      // Alumno Joaquín Herrera está en su casa (enfermo): NO está presente
      'alumno-demo-4': RegistroPresenciaDispositivo(
        alumnoUid: 'alumno-demo-4',
        alumnoNombre: 'Joaquín Herrera',
        estaPresente: false, // NO PRESENTE EN AULA
        cumplePolitica: true,
        metodo: MetodoPresencia.manualDocente,
        momentoRegistro: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    };

    final sesionDemo = SesionModoClase(
      id: 'SESION-DEMO-3B',
      claseId: 'CLASE-DEMO-001',
      cursoNombre: '3° Básico B',
      materia: 'Matemáticas',
      profesorUid: 'profesor-demo',
      profesorNombre: 'Docente Demo',
      institucionId: 'INST-SAN-MARTIN',
      tipoModo: TipoModoClase.clase,
      estado: EstadoSesionModo.activa,
      horaInicio: DateTime.now().subtract(const Duration(minutes: 25)),
      politicaAplicada: politicaBase,
      tokenPresenciaQr: tokenObj.serializar(),
      timestampToken: tokenObj.timestamp,
      estudiantesPresentes: mapaPresentes,
    );

    _sesiones[sesionDemo.id] = sesionDemo;
    _emitirCambios('INST-SAN-MARTIN');
  }

  void _emitirCambios(String institucionId) {
    if (!_sesionesStreamController.isClosed) {
      final activas = _sesiones.values
          .where((s) => s.institucionId == institucionId && s.estado == EstadoSesionModo.activa)
          .toList();
      _sesionesStreamController.add(activas);
    }
  }

  @override
  Future<SesionModoClase> iniciarSesion({
    required String claseId,
    required String cursoNombre,
    required String materia,
    required UsuarioApp docente,
    required TipoModoClase tipoModo,
    PoliticaDispositivo? politicaPersonalizada,
  }) async {
    // 1. VALIDACIÓN DE AUTORIDAD EN BACKEND
    if (tipoModo == TipoModoClase.examen) {
      if (!docente.tienePermiso(PermisoInstitucional.activarModoExamen)) {
        throw Exception(
          'Autorización denegada: El profesor no cuenta con el permiso "activar_modo_examen" otorgado por Dirección.',
        );
      }
    } else {
      if (!docente.tienePermiso(PermisoInstitucional.activarModoClase)) {
        throw Exception(
          'Autorización denegada: El usuario no tiene permisos para iniciar Modo Clase.',
        );
      }
    }

    final sesionId = 'SESION-${DateTime.now().millisecondsSinceEpoch}';

    // 2. Resuelve la política según la jerarquía institucional
    final PoliticaDispositivo politicaEfectiva = politicaPersonalizada ??
        (tipoModo == TipoModoClase.examen
            ? PlantillaPolitica.modoExamenRiguroso(institucionId: docente.institucionId)
            : PlantillaPolitica.modoClaseEstandar(institucionId: docente.institucionId));

    // 3. Genera token seguro inicial de presencia
    final token = _presenciaServicio.generarTokenPresencia(
      sesionId: sesionId,
      institucionId: docente.institucionId,
    );

    final nuevaSesion = SesionModoClase(
      id: sesionId,
      claseId: claseId,
      cursoNombre: cursoNombre,
      materia: materia,
      profesorUid: docente.uid,
      profesorNombre: docente.nombre,
      institucionId: docente.institucionId,
      tipoModo: tipoModo,
      estado: EstadoSesionModo.activa,
      horaInicio: DateTime.now(),
      politicaAplicada: politicaEfectiva,
      tokenPresenciaQr: token.serializar(),
      timestampToken: token.timestamp,
    );

    _sesiones[sesionId] = nuevaSesion;
    _emitirCambios(docente.institucionId);

    // 4. Registro inmutable en auditoría
    await _auditoriaRepo.registrarEvento(
      tipo: tipoModo == TipoModoClase.examen
          ? TipoEventoAuditoria.inicioModoExamen
          : TipoEventoAuditoria.inicioModoClase,
      usuario: docente,
      cursoId: claseId,
      descripcion: 'El docente ${docente.nombre} inició ${tipoModo.etiqueta} en $cursoNombre ($materia).',
      detalles: {
        'sesionId': sesionId,
        'politica': politicaEfectiva.nombre,
        'tipoModo': tipoModo.name,
      },
    );

    final fs = _firestore;
    if (fs != null) {
      try {
        await fs
            .collection('sesiones_modo_clase')
            .doc(sesionId)
            .set(nuevaSesion.toMap())
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('Aviso persistencia Firestore sesión: $e');
      }
    }

    return nuevaSesion;
  }

  @override
  Future<SesionModoClase?> obtenerSesionActivaPorClase(String claseId) async {
    return _sesiones.values.cast<SesionModoClase?>().firstWhere(
          (s) => s?.claseId == claseId && s?.estado == EstadoSesionModo.activa,
          orElse: () => null,
        );
  }

  @override
  Future<SesionModoClase?> obtenerSesionActivaPorProfesor(String profesorUid) async {
    return _sesiones.values.cast<SesionModoClase?>().firstWhere(
          (s) => s?.profesorUid == profesorUid && s?.estado == EstadoSesionModo.activa,
          orElse: () => null,
        );
  }

  @override
  Future<List<SesionModoClase>> obtenerSesionesActivasPorInstitucion(
      String institucionId) async {
    return _sesiones.values
        .where((s) => s.institucionId == institucionId && s.estado == EstadoSesionModo.activa)
        .toList();
  }

  @override
  Future<bool> registrarPresenciaAlumno({
    required String sesionId,
    required String alumnoUid,
    required String alumnoNombre,
    required MetodoPresencia metodo,
    String? tokenQrString,
  }) async {
    final sesion = _sesiones[sesionId];
    if (sesion == null || sesion.estado != EstadoSesionModo.activa) {
      return false;
    }

    // Si la validación es por QR, verificar token en backend
    if (metodo == MetodoPresencia.codigoQr) {
      if (tokenQrString == null) return false;
      final resultado = _presenciaServicio.validarTokenQr(
        tokenString: tokenQrString,
        sesionIdEsperada: sesion.id,
        institucionIdEsperada: sesion.institucionId,
      );
      if (!resultado.esValido) {
        throw Exception(resultado.mensaje);
      }
    }

    final mapa = Map<String, RegistroPresenciaDispositivo>.from(sesion.estudiantesPresentes);
    mapa[alumnoUid] = RegistroPresenciaDispositivo(
      alumnoUid: alumnoUid,
      alumnoNombre: alumnoNombre,
      estaPresente: true,
      cumplePolitica: true,
      metodo: metodo,
      momentoRegistro: DateTime.now(),
    );

    final actualizada = sesion.copyWith(estudiantesPresentes: mapa);
    _sesiones[sesionId] = actualizada;
    _emitirCambios(sesion.institucionId);

    return true;
  }

  @override
  Future<void> concederExcepcionTemporal({
    required String sesionId,
    required UsuarioApp docente,
    required String appId,
    required String appNombre,
    String? alumnoUid,
    required int minutos,
    required String motivo,
  }) async {
    // 1. VALIDACIÓN DE AUTORIDAD EN BACKEND
    if (!docente.tienePermiso(PermisoInstitucional.permitirAppTemporalmente)) {
      throw Exception('Autorización denegada: No cuentas con el permiso para conceder excepciones temporales.');
    }

    final sesion = _sesiones[sesionId];
    if (sesion == null) throw Exception('Sesión no encontrada');

    final ahora = DateTime.now();
    final excepcion = ExcepcionTemporalApp(
      id: 'EX-${ahora.millisecondsSinceEpoch}',
      appId: appId,
      appNombre: appNombre,
      alumnoUid: alumnoUid,
      minutosValidez: minutos,
      horaInicio: ahora,
      horaExpiracion: ahora.add(Duration(minutes: minutos)),
      motivo: motivo,
      autorizadoPorUid: docente.uid,
    );

    final lista = List<ExcepcionTemporalApp>.from(sesion.excepcionesTemporales)..add(excepcion);
    final actualizada = sesion.copyWith(excepcionesTemporales: lista);
    _sesiones[sesionId] = actualizada;
    _emitirCambios(sesion.institucionId);

    // Auditoría
    await _auditoriaRepo.registrarEvento(
      tipo: TipoEventoAuditoria.excepcionTemporal,
      usuario: docente,
      cursoId: sesion.claseId,
      descripcion: 'El docente concedió excepción temporal de $minutos min para "$appNombre". Motivo: $motivo.',
      detalles: {
        'sesionId': sesionId,
        'appId': appId,
        'minutos': minutos,
        'alumnoUid': alumnoUid ?? 'Todo el grupo',
      },
    );
  }

  @override
  Future<void> liberarEstudiante({
    required String sesionId,
    required UsuarioApp docente,
    required String alumnoUid,
    required String motivo,
  }) async {
    // 1. VALIDACIÓN DE AUTORIDAD
    if (!docente.tienePermiso(PermisoInstitucional.liberarEstudiante)) {
      throw Exception('Autorización denegada: No cuentas con el permiso para liberar estudiantes.');
    }

    final sesion = _sesiones[sesionId];
    if (sesion == null) return;

    final mapa = Map<String, RegistroPresenciaDispositivo>.from(sesion.estudiantesPresentes);
    final actual = mapa[alumnoUid];
    if (actual != null) {
      mapa[alumnoUid] = actual.copyWith(
        liberadoPorDocente: true,
        motivoLiberacion: motivo,
      );
      final actualizada = sesion.copyWith(estudiantesPresentes: mapa);
      _sesiones[sesionId] = actualizada;
      _emitirCambios(sesion.institucionId);

      await _auditoriaRepo.registrarEvento(
        tipo: TipoEventoAuditoria.liberacionEstudiante,
        usuario: docente,
        cursoId: sesion.claseId,
        descripcion: 'Estudiante ${actual.alumnoNombre} fue liberado de las restricciones. Motivo: $motivo.',
        detalles: {'sesionId': sesionId, 'alumnoUid': alumnoUid},
      );
    }
  }

  @override
  Future<void> finalizarSesion({
    required String sesionId,
    required UsuarioApp docente,
  }) async {
    final sesion = _sesiones[sesionId];
    if (sesion == null) return;

    final finalizada = sesion.copyWith(
      estado: EstadoSesionModo.finalizada,
      horaFin: DateTime.now(),
    );
    _sesiones[sesionId] = finalizada;
    _emitirCambios(sesion.institucionId);

    await _auditoriaRepo.registrarEvento(
      tipo: sesion.tipoModo == TipoModoClase.examen
          ? TipoEventoAuditoria.finModoExamen
          : TipoEventoAuditoria.finModoClase,
      usuario: docente,
      cursoId: sesion.claseId,
      descripcion: 'El docente finalizó la sesión ${sesion.tipoModo.etiqueta} en ${sesion.cursoNombre}.',
      detalles: {
        'sesionId': sesionId,
        'duracionMinutos': DateTime.now().difference(sesion.horaInicio).inMinutes,
      },
    );
  }

  // ===========================================================================
  // FASE 13: BOTÓN DE EMERGENCIA INSTITUCIONAL
  // ===========================================================================
  @override
  Future<void> suspenderRestriccionesEmergencia({
    required String institucionId,
    required UsuarioApp direccion,
    required String motivo,
  }) async {
    if (!direccion.esDireccion &&
        !direccion.tienePermiso(PermisoInstitucional.suspenderEmergencia)) {
      throw Exception('Autorización denegada: Solo Dirección puede activar el Botón de Emergencia.');
    }

    for (final key in _sesiones.keys) {
      if (_sesiones[key]!.institucionId == institucionId) {
        _sesiones[key] = _sesiones[key]!.copyWith(
          restriccionesSuspendidasEmergencia: true,
        );
      }
    }
    _emitirCambios(institucionId);

    await _auditoriaRepo.registrarEvento(
      tipo: TipoEventoAuditoria.activacionEmergencia,
      usuario: direccion,
      descripcion: 'EMERGENCIA INSTITUCIONAL ACTIVADA: Restricciones de dispositivos suspendidas. Motivo: $motivo.',
      detalles: {'motivo': motivo},
    );
  }

  @override
  Future<void> restaurarRestriccionesNormales({
    required String institucionId,
    required UsuarioApp direccion,
  }) async {
    if (!direccion.esDireccion) {
      throw Exception('Autorización denegada: Solo Dirección puede restaurar restricciones.');
    }

    for (final key in _sesiones.keys) {
      if (_sesiones[key]!.institucionId == institucionId) {
        _sesiones[key] = _sesiones[key]!.copyWith(
          restriccionesSuspendidasEmergencia: false,
        );
      }
    }
    _emitirCambios(institucionId);

    await _auditoriaRepo.registrarEvento(
      tipo: TipoEventoAuditoria.restauracionEmergencia,
      usuario: direccion,
      descripcion: 'Restricciones institucionales normales restauradas por Dirección.',
    );
  }

  @override
  Future<String> rotarTokenPresencia(String sesionId) async {
    final sesion = _sesiones[sesionId];
    if (sesion == null) return '';

    final nuevoToken = _presenciaServicio.generarTokenPresencia(
      sesionId: sesionId,
      institucionId: sesion.institucionId,
    );

    final serializado = nuevoToken.serializar();
    _sesiones[sesionId] = sesion.copyWith(
      tokenPresenciaQr: serializado,
      timestampToken: nuevoToken.timestamp,
    );
    _emitirCambios(sesion.institucionId);
    return serializado;
  }

  @override
  Stream<List<SesionModoClase>> sesionesActivasStream(String institucionId) {
    return _sesionesStreamController.stream;
  }

  @override
  Stream<SesionModoClase?> sesionClaseStream(String claseId) {
    return _sesionesStreamController.stream.map((lista) {
      return lista.cast<SesionModoClase?>().firstWhere(
            (s) => s?.claseId == claseId && s?.estado == EstadoSesionModo.activa,
            orElse: () => null,
          );
    });
  }
}
