/// Representa un bloque de horario lectivo en la institución educativa.
/// IMPORTANTE: El horario SOLO identifica el contexto pedagógico (materia, curso, aula).
/// NUNCA debe utilizarse como condición suficiente para bloquear un dispositivo sin presencia.
class BloqueHorario {
  const BloqueHorario({
    required this.id,
    required this.institucionId,
    required this.cursoId,
    required this.cursoNombre,
    required this.materia,
    required this.aula,
    required this.profesorUid,
    required this.profesorNombre,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
  });

  final String id;
  final String institucionId;
  final String cursoId;
  final String cursoNombre;
  final String materia;
  final String aula;
  final String profesorUid;
  final String profesorNombre;

  /// Día de la semana (1 = Lunes, 2 = Martes, ..., 5 = Viernes, 6 = Sábado, 7 = Domingo)
  final int diaSemana;

  /// Hora de inicio en formato 'HH:mm' (ej. '08:00')
  final String horaInicio;

  /// Hora de término en formato 'HH:mm' (ej. '09:30')
  final String horaFin;

  String get horarioLegible => '$horaInicio - $horaFin';

  String get diaLegible {
    switch (diaSemana) {
      case DateTime.monday:
        return 'Lunes';
      case DateTime.tuesday:
        return 'Martes';
      case DateTime.wednesday:
        return 'Miércoles';
      case DateTime.thursday:
        return 'Jueves';
      case DateTime.friday:
        return 'Viernes';
      case DateTime.saturday:
        return 'Sábado';
      case DateTime.sunday:
        return 'Domingo';
      default:
        return 'Día $diaSemana';
    }
  }

  /// Verifica si la fecha y hora proporcionadas caen dentro de este bloque.
  bool coincideConMomento(DateTime momento) {
    if (momento.weekday != diaSemana) return false;

    final minutosMomento = momento.hour * 60 + momento.minute;
    final minutosInicio = _parsearMinutos(horaInicio);
    final minutosFin = _parsearMinutos(horaFin);

    return minutosMomento >= minutosInicio && minutosMomento <= minutosFin;
  }

  static int _parsearMinutos(String horaStr) {
    final partes = horaStr.split(':');
    if (partes.length < 2) return 0;
    final h = int.tryParse(partes[0]) ?? 0;
    final m = int.tryParse(partes[1]) ?? 0;
    return h * 60 + m;
  }

  BloqueHorario copyWith({
    String? id,
    String? institucionId,
    String? cursoId,
    String? cursoNombre,
    String? materia,
    String? aula,
    String? profesorUid,
    String? profesorNombre,
    int? diaSemana,
    String? horaInicio,
    String? horaFin,
  }) {
    return BloqueHorario(
      id: id ?? this.id,
      institucionId: institucionId ?? this.institucionId,
      cursoId: cursoId ?? this.cursoId,
      cursoNombre: cursoNombre ?? this.cursoNombre,
      materia: materia ?? this.materia,
      aula: aula ?? this.aula,
      profesorUid: profesorUid ?? this.profesorUid,
      profesorNombre: profesorNombre ?? this.profesorNombre,
      diaSemana: diaSemana ?? this.diaSemana,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'institucionId': institucionId,
      'cursoId': cursoId,
      'cursoNombre': cursoNombre,
      'materia': materia,
      'aula': aula,
      'profesorUid': profesorUid,
      'profesorNombre': profesorNombre,
      'diaSemana': diaSemana,
      'horaInicio': horaInicio,
      'horaFin': horaFin,
    };
  }

  factory BloqueHorario.fromMap(Map<String, dynamic> map) {
    return BloqueHorario(
      id: map['id'] as String? ?? '',
      institucionId: map['institucionId'] as String? ?? 'INST-SAN-MARTIN',
      cursoId: map['cursoId'] as String? ?? '',
      cursoNombre: map['cursoNombre'] as String? ?? '',
      materia: map['materia'] as String? ?? 'Matemáticas',
      aula: map['aula'] as String? ?? 'Aula 1',
      profesorUid: map['profesorUid'] as String? ?? '',
      profesorNombre: map['profesorNombre'] as String? ?? 'Profesor',
      diaSemana: (map['diaSemana'] as num?)?.toInt() ?? 1,
      horaInicio: map['horaInicio'] as String? ?? '08:00',
      horaFin: map['horaFin'] as String? ?? '09:30',
    );
  }
}
