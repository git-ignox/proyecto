import 'dart:async';
import '../dominio/modelos/horario_escolar.dart';
import '../dominio/modelos/permiso_institucional.dart';
import '../dominio/modelos/usuario_app.dart';

/// Servicio para la consulta y administración de horarios escolares institucionales.
/// Ayuda al docente a identificar el contexto de la clase actual (curso, materia, aula).
class ServicioHorarios {
  ServicioHorarios() {
    _inicializarDatosPredeterminados();
  }

  final Map<String, BloqueHorario> _horarios = {};
  final StreamController<List<BloqueHorario>> _controller =
      StreamController<List<BloqueHorario>>.broadcast();

  void _inicializarDatosPredeterminados() {
    const instId = 'INST-SAN-MARTIN';

    final bloques = [
      // Lunes a Viernes - 3° Básico B (Matemáticas con Prof. Roberto Gómez)
      BloqueHorario(
        id: 'HOR-3B-MAT-LUN',
        institucionId: instId,
        cursoId: 'CLASE-DEMO-001',
        cursoNombre: '3° Básico B',
        materia: 'Matemáticas',
        aula: 'Aula 3B',
        profesorUid: 'profesor-demo',
        profesorNombre: 'Docente Demo',
        diaSemana: DateTime.monday,
        horaInicio: '08:00',
        horaFin: '09:30',
      ),
      BloqueHorario(
        id: 'HOR-3B-MAT-MIE',
        institucionId: instId,
        cursoId: 'CLASE-DEMO-001',
        cursoNombre: '3° Básico B',
        materia: 'Matemáticas',
        aula: 'Aula 3B',
        profesorUid: 'profesor-demo',
        profesorNombre: 'Docente Demo',
        diaSemana: DateTime.wednesday,
        horaInicio: '08:00',
        horaFin: '09:30',
      ),
      BloqueHorario(
        id: 'HOR-5A-MAT-MAR',
        institucionId: instId,
        cursoId: 'CLASE-DEMO-5A',
        cursoNombre: '5° Primaria A',
        materia: 'Geometría y Álgebra',
        aula: 'Laboratorio 1',
        profesorUid: 'prof-roberto',
        profesorNombre: 'Prof. Roberto Gómez',
        diaSemana: DateTime.tuesday,
        horaInicio: '10:00',
        horaFin: '11:30',
      ),
    ];

    for (final b in bloques) {
      _horarios[b.id] = b;
    }
    _emitirCambios(instId);
  }

  void _emitirCambios(String institucionId) {
    if (!_controller.isClosed) {
      final lista = _horarios.values
          .where((h) => h.institucionId == institucionId)
          .toList();
      _controller.add(lista);
    }
  }

  List<BloqueHorario> obtenerHorariosPorInstitucion(String institucionId) {
    return _horarios.values
        .where((h) => h.institucionId == institucionId)
        .toList();
  }

  List<BloqueHorario> obtenerHorariosPorCurso(String cursoId) {
    return _horarios.values.where((h) => h.cursoId == cursoId).toList();
  }

  List<BloqueHorario> obtenerHorariosPorProfesor(String profesorUid) {
    return _horarios.values.where((h) => h.profesorUid == profesorUid).toList();
  }

  /// Identifica la clase escolar que corresponde en este instante para un curso o profesor.
  BloqueHorario? obtenerClaseActualPorProfesor(String profesorUid, {DateTime? momento}) {
    final ahora = momento ?? DateTime.now();
    for (final b in _horarios.values) {
      if (b.profesorUid == profesorUid && b.coincideConMomento(ahora)) {
        return b;
      }
    }
    return null;
  }

  Future<void> guardarHorario(
    BloqueHorario horario, {
    required UsuarioApp usuario,
  }) async {
    final puedeAdministrar = usuario.esDireccion ||
        usuario.tienePermiso(PermisoInstitucional.administrarInstitucion);

    if (!puedeAdministrar) {
      throw Exception('Permiso denegado: Solo Dirección puede modificar horarios.');
    }

    _horarios[horario.id] = horario;
    _emitirCambios(horario.institucionId);
  }

  Future<void> eliminarHorario(String id, {required UsuarioApp usuario}) async {
    if (!usuario.esDireccion) {
      throw Exception('Permiso denegado: Solo Dirección puede eliminar bloques horarios.');
    }
    final h = _horarios.remove(id);
    if (h != null) {
      _emitirCambios(h.institucionId);
    }
  }

  Stream<List<BloqueHorario>> horariosStream(String institucionId) {
    return _controller.stream;
  }
}
