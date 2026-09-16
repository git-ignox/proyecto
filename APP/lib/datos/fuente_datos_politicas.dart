import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../dominio/modelos/permiso_institucional.dart';
import '../dominio/modelos/politica_dispositivo.dart';
import '../dominio/modelos/usuario_app.dart';
import 'repositorio_politicas.dart';

/// Implementación del [RepositorioPoliticas] con almacenamiento en memoria,
/// resolución jerárquica instantánea y sincronización en segundo plano con Firestore.
class FuenteDatosPoliticas implements RepositorioPoliticas {
  FuenteDatosPoliticas({FirebaseFirestore? firestore})
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

  final Map<String, PoliticaDispositivo> _politicas = {};
  final StreamController<List<PoliticaDispositivo>> _controller =
      StreamController<List<PoliticaDispositivo>>.broadcast();

  void _inicializarDatosPredeterminados() {
    const instId = 'INST-SAN-MARTIN';

    // 1. Política Global Institucional (Base)
    final baseGlobal = PlantillaPolitica.modoClaseEstandar(
      institucionId: instId,
      id: 'POL-BASE-INSTITUCIONAL',
    );

    // 2. Política para Modo Examen
    final examenGlobal = PlantillaPolitica.modoExamenRiguroso(
      institucionId: instId,
      id: 'POL-EXAMEN-INSTITUCIONAL',
    );

    // 3. Política específica para Curso "3° Básico B" (3B)
    final politica3B = PoliticaDispositivo(
      id: 'POL-CURSO-3B',
      nombre: 'Política Especial 3° Básico B',
      descripcion: 'Refuerzo en aritmética: GeoGebra habilitada para geometría interactiva.',
      institucionId: instId,
      cursoId: 'CLASE-DEMO-3B',
      jerarquia: NivelJerarquiaPolitica.curso,
      apps: PlantillaPolitica.catalogoEstandar.map((a) {
        if (a.id == PlantillaPolitica.appGeoGebra.id) {
          return a.copyWith(estado: EstadoReglaApp.permitido);
        }
        return a;
      }).toList(),
      permiteExcepcionesDocente: true,
      permiteModoExamen: true,
    );

    _politicas[baseGlobal.id] = baseGlobal;
    _politicas[examenGlobal.id] = examenGlobal;
    _politicas[politica3B.id] = politica3B;

    _emitirCambios(instId);
    _sincronizarDesdeFirestore(instId);
  }

  void _emitirCambios(String institucionId) {
    if (!_controller.isClosed) {
      final filtradas = _politicas.values
          .where((p) => p.institucionId == institucionId && p.esActiva)
          .toList();
      _controller.add(filtradas);
    }
  }

  Future<void> _sincronizarDesdeFirestore(String institucionId) async {
    final fs = _firestore;
    if (fs == null) return;
    try {
      final snapshot = await fs
          .collection('politicas_dispositivos')
          .where('institucionId', isEqualTo: institucionId)
          .get()
          .timeout(const Duration(seconds: 3));

      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final p = PoliticaDispositivo.fromMap(data);
        _politicas[p.id] = p;
      }
      _emitirCambios(institucionId);
    } catch (e) {
      debugPrint('Aviso Firestore políticas (usando almacenamiento local): $e');
    }
  }

  @override
  Future<List<PoliticaDispositivo>> obtenerPoliticasPorInstitucion(
      String institucionId) async {
    return _politicas.values
        .where((p) => p.institucionId == institucionId && p.esActiva)
        .toList();
  }

  @override
  Future<PoliticaDispositivo?> obtenerPoliticaPorId(String id) async {
    return _politicas[id];
  }

  @override
  Future<void> guardarPolitica(
    PoliticaDispositivo politica, {
    required UsuarioApp usuario,
  }) async {
    // VALIDACIÓN DE AUTORIDAD EN BACKEND
    final puedeAdministrar = usuario.esDireccion ||
        usuario.tienePermiso(PermisoInstitucional.administrarInstitucion);

    if (!puedeAdministrar) {
      throw Exception('Permiso denegado: Solo Dirección puede modificar políticas institucionales.');
    }

    _politicas[politica.id] = politica;
    _emitirCambios(politica.institucionId);

    final fs = _firestore;
    if (fs != null) {
      try {
        await fs
            .collection('politicas_dispositivos')
            .doc(politica.id)
            .set(politica.toMap())
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('Aviso persistencia Firestore política: $e');
      }
    }
  }

  @override
  Future<void> eliminarPolitica(String id, {required UsuarioApp usuario}) async {
    // VALIDACIÓN DE AUTORIDAD EN BACKEND
    if (!usuario.esDireccion) {
      throw Exception('Permiso denegado: Solo Dirección puede eliminar políticas.');
    }

    final p = _politicas[id];
    if (p != null) {
      _politicas.remove(id);
      _emitirCambios(p.institucionId);

      final fs = _firestore;
      if (fs != null) {
        try {
          await fs.collection('politicas_dispositivos').doc(id).delete();
        } catch (_) {}
      }
    }
  }

  // ===========================================================================
  // FASE 4: MOTOR DE RESOLUCIÓN JERÁRQUICA DE POLÍTICAS
  // Institución -> Curso -> Materia -> Docente
  // ===========================================================================
  @override
  PoliticaEfectiva resolverPoliticaEfectiva({
    required String institucionId,
    String? cursoId,
    String? materia,
    UsuarioApp? docente,
  }) {
    // 1. BASE INSTITUCIONAL
    PoliticaDispositivo? base = _politicas.values.firstWhere(
      (p) =>
          p.institucionId == institucionId &&
          p.jerarquia == NivelJerarquiaPolitica.institucional &&
          p.esActiva,
      orElse: () => PlantillaPolitica.modoClaseEstandar(institucionId: institucionId),
    );

    // Mapa base de reglas consolidadas por App ID
    final Map<String, AppRegla> reglasResueltas = {};
    for (final app in base.apps) {
      reglasResueltas[app.id] = app;
    }

    // Identificar bloqueos críticos institucionales (inviolables)
    final Set<String> bloqueosCriticosInstitucionales = base.apps
        .where((a) => a.estado == EstadoReglaApp.bloqueadoCritico)
        .map((a) => a.id)
        .toSet();

    // ¿Tiene el docente autorización explícita para omitir bloqueos críticos?
    final bool puedeOmitirCriticos = docente != null &&
        docente.tienePermiso(PermisoInstitucional.omitirPoliticaInstitucional);

    // 2. CAPA POR CURSO / GRUPO
    if (cursoId != null) {
      final politicaCurso = _politicas.values.firstWhere(
        (p) => p.cursoId == cursoId && p.esActiva,
        orElse: () => base,
      );

      if (politicaCurso.id != base.id) {
        for (final appCurso in politicaCurso.apps) {
          final esCritica = bloqueosCriticosInstitucionales.contains(appCurso.id);
          // Si es crítica institucional y el curso intenta permitirla, se ignora salvo autorización
          if (esCritica && appCurso.esPermitida && !puedeOmitirCriticos) {
            continue;
          }
          reglasResueltas[appCurso.id] = appCurso;
        }
      }
    }

    // 3. CAPA POR MATERIA (Excepciones curriculares)
    if (materia != null) {
      final materiaNorm = materia.toLowerCase();
      if (materiaNorm.contains('mate') || materiaNorm.contains('álgebra')) {
        // En matemáticas se garantiza calculadora y geogebra
        if (reglasResueltas.containsKey(PlantillaPolitica.appCalculadora.id)) {
          reglasResueltas[PlantillaPolitica.appCalculadora.id] =
              reglasResueltas[PlantillaPolitica.appCalculadora.id]!
                  .copyWith(estado: EstadoReglaApp.permitido);
        }
        if (reglasResueltas.containsKey(PlantillaPolitica.appGeoGebra.id)) {
          reglasResueltas[PlantillaPolitica.appGeoGebra.id] =
              reglasResueltas[PlantillaPolitica.appGeoGebra.id]!
                  .copyWith(estado: EstadoReglaApp.permitido);
        }
      } else if (materiaNorm.contains('lengua') || materiaNorm.contains('inglés')) {
        if (reglasResueltas.containsKey(PlantillaPolitica.appDiccionario.id)) {
          reglasResueltas[PlantillaPolitica.appDiccionario.id] =
              reglasResueltas[PlantillaPolitica.appDiccionario.id]!
                  .copyWith(estado: EstadoReglaApp.permitido);
        }
      } else if (materiaNorm.contains('arte') || materiaNorm.contains('tecnol')) {
        if (reglasResueltas.containsKey(PlantillaPolitica.appCamara.id)) {
          reglasResueltas[PlantillaPolitica.appCamara.id] =
              reglasResueltas[PlantillaPolitica.appCamara.id]!
                  .copyWith(estado: EstadoReglaApp.permitido);
        }
      }
    }

    return PoliticaEfectiva(
      nombrePolitica: 'Efectiva: ${base.nombre}',
      institucionId: institucionId,
      reglasPorAppId: reglasResueltas,
      permiteModoExamen: base.permiteModoExamen,
      permiteExcepcionesDocente: base.permiteExcepcionesDocente,
    );
  }

  @override
  Stream<List<PoliticaDispositivo>> politicasStream(String institucionId) {
    return _controller.stream;
  }
}
