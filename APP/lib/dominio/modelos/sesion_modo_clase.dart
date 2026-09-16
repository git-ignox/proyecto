import 'politica_dispositivo.dart';

/// Tipo de modalidad pedagógica de la sesión.
enum TipoModoClase {
  clase,
  examen,
  investigacion,
  colaborativo;

  String get etiqueta {
    switch (this) {
      case TipoModoClase.clase:
        return 'Modo Clase 👨‍🏫';
      case TipoModoClase.examen:
        return 'Modo Examen Riguroso 📝';
      case TipoModoClase.investigacion:
        return 'Modo Investigación 🔍';
      case TipoModoClase.colaborativo:
        return 'Modo Colaborativo 👥';
    }
  }
}

/// Estado del ciclo de vida de la sesión.
enum EstadoSesionModo {
  activa,
  finalizada,
  pausada;

  String get etiqueta {
    switch (this) {
      case EstadoSesionModo.activa:
        return 'En Curso 🟢';
      case EstadoSesionModo.finalizada:
        return 'Finalizada ⚪';
      case EstadoSesionModo.pausada:
        return 'Pausada 🟡';
    }
  }
}

/// Método por el cual se constató la presencia del dispositivo en el aula.
enum MetodoPresencia {
  redInstitucionalWifi,
  codigoBarras,
  codigoQr,
  bleCercania,
  manualDocente;

  String get etiqueta {
    switch (this) {
      case MetodoPresencia.redInstitucionalWifi:
        return 'Red Wi-Fi Institucional';
      case MetodoPresencia.codigoBarras:
        return 'Código de Barras Dinámico de Aula';
      case MetodoPresencia.codigoQr:
        return 'Código de Barras / QR de Aula';
      case MetodoPresencia.bleCercania:
        return 'Proximidad BLE';
      case MetodoPresencia.manualDocente:
        return 'Verificación Manual del Docente';
    }
  }
}

/// Registro del estado de presencia y cumplimiento de un alumno en la sesión.
class RegistroPresenciaDispositivo {
  const RegistroPresenciaDispositivo({
    required this.alumnoUid,
    required this.alumnoNombre,
    required this.estaPresente,
    this.cumplePolitica = true,
    this.metodo = MetodoPresencia.manualDocente,
    required this.momentoRegistro,
    this.liberadoPorDocente = false,
    this.motivoLiberacion,
    this.incidenciasFoco = 0,
  });

  final String alumnoUid;
  final String alumnoNombre;
  final bool estaPresente;
  final bool cumplePolitica;
  final MetodoPresencia metodo;
  final DateTime momentoRegistro;
  final bool liberadoPorDocente;
  final String? motivoLiberacion;
  final int incidenciasFoco;

  RegistroPresenciaDispositivo copyWith({
    String? alumnoUid,
    String? alumnoNombre,
    bool? estaPresente,
    bool? cumplePolitica,
    MetodoPresencia? metodo,
    DateTime? momentoRegistro,
    bool? liberadoPorDocente,
    String? motivoLiberacion,
    int? incidenciasFoco,
  }) {
    return RegistroPresenciaDispositivo(
      alumnoUid: alumnoUid ?? this.alumnoUid,
      alumnoNombre: alumnoNombre ?? this.alumnoNombre,
      estaPresente: estaPresente ?? this.estaPresente,
      cumplePolitica: cumplePolitica ?? this.cumplePolitica,
      metodo: metodo ?? this.metodo,
      momentoRegistro: momentoRegistro ?? this.momentoRegistro,
      liberadoPorDocente: liberadoPorDocente ?? this.liberadoPorDocente,
      motivoLiberacion: motivoLiberacion ?? this.motivoLiberacion,
      incidenciasFoco: incidenciasFoco ?? this.incidenciasFoco,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'alumnoUid': alumnoUid,
      'alumnoNombre': alumnoNombre,
      'estaPresente': estaPresente,
      'cumplePolitica': cumplePolitica,
      'metodo': metodo.name,
      'momentoRegistro': momentoRegistro.toIso8601String(),
      'liberadoPorDocente': liberadoPorDocente,
      'motivoLiberacion': motivoLiberacion,
      'incidenciasFoco': incidenciasFoco,
    };
  }

  factory RegistroPresenciaDispositivo.fromMap(Map<String, dynamic> map) {
    return RegistroPresenciaDispositivo(
      alumnoUid: map['alumnoUid'] as String? ?? '',
      alumnoNombre: map['alumnoNombre'] as String? ?? 'Alumno',
      estaPresente: map['estaPresente'] as bool? ?? false,
      cumplePolitica: map['cumplePolitica'] as bool? ?? true,
      metodo: MetodoPresencia.values.firstWhere(
        (m) => m.name == map['metodo'],
        orElse: () => MetodoPresencia.manualDocente,
      ),
      momentoRegistro: DateTime.tryParse(map['momentoRegistro'] as String? ?? '') ??
          DateTime.now(),
      liberadoPorDocente: map['liberadoPorDocente'] as bool? ?? false,
      motivoLiberacion: map['motivoLiberacion'] as String?,
      incidenciasFoco: (map['incidenciasFoco'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Excepción temporal concedida a una aplicación durante la clase (ej. 5, 10 o 20 min).
class ExcepcionTemporalApp {
  const ExcepcionTemporalApp({
    required this.id,
    required this.appId,
    required this.appNombre,
    this.alumnoUid,
    required this.minutosValidez,
    required this.horaInicio,
    required this.horaExpiracion,
    required this.motivo,
    required this.autorizadoPorUid,
  });

  final String id;
  final String appId;
  final String appNombre;

  /// Si es null, aplica a todo el grupo presente
  final String? alumnoUid;

  final int minutosValidez;
  final DateTime horaInicio;
  final DateTime horaExpiracion;
  final String motivo;
  final String autorizadoPorUid;

  bool get estaVigente => DateTime.now().isBefore(horaExpiracion);

  int get segundosRestantes {
    final diff = horaExpiracion.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'appId': appId,
      'appNombre': appNombre,
      'alumnoUid': alumnoUid,
      'minutosValidez': minutosValidez,
      'horaInicio': horaInicio.toIso8601String(),
      'horaExpiracion': horaExpiracion.toIso8601String(),
      'motivo': motivo,
      'autorizadoPorUid': autorizadoPorUid,
    };
  }

  factory ExcepcionTemporalApp.fromMap(Map<String, dynamic> map) {
    return ExcepcionTemporalApp(
      id: map['id'] as String? ?? '',
      appId: map['appId'] as String? ?? '',
      appNombre: map['appNombre'] as String? ?? 'App',
      alumnoUid: map['alumnoUid'] as String?,
      minutosValidez: (map['minutosValidez'] as num?)?.toInt() ?? 10,
      horaInicio: DateTime.tryParse(map['horaInicio'] as String? ?? '') ??
          DateTime.now(),
      horaExpiracion:
          DateTime.tryParse(map['horaExpiracion'] as String? ?? '') ??
              DateTime.now().add(const Duration(minutes: 10)),
      motivo: map['motivo'] as String? ?? 'Actividad autorizada',
      autorizadoPorUid: map['autorizadoPorUid'] as String? ?? '',
    );
  }
}

/// Representa una sesión activa de Modo Clase o Modo Examen.
class SesionModoClase {
  const SesionModoClase({
    required this.id,
    required this.claseId,
    required this.cursoNombre,
    required this.materia,
    required this.profesorUid,
    required this.profesorNombre,
    required this.institucionId,
    this.tipoModo = TipoModoClase.clase,
    this.estado = EstadoSesionModo.activa,
    required this.horaInicio,
    this.horaFin,
    required this.politicaAplicada,
    required this.tokenPresenciaQr,
    required this.timestampToken,
    this.estudiantesPresentes = const {},
    this.excepcionesTemporales = const [],
    this.restriccionesSuspendidasEmergencia = false,
  });

  final String id;
  final String claseId;
  final String cursoNombre;
  final String materia;
  final String profesorUid;
  final String profesorNombre;
  final String institucionId;
  final TipoModoClase tipoModo;
  final EstadoSesionModo estado;
  final DateTime horaInicio;
  final DateTime? horaFin;
  final PoliticaDispositivo politicaAplicada;

  /// Token de presencia rotativo para escanear con Código de Barras
  final String tokenPresenciaQr;
  String get tokenPresenciaCodigoBarras => tokenPresenciaQr;
  final DateTime timestampToken;

  /// Mapa de alumnoUid -> RegistroPresenciaDispositivo
  final Map<String, RegistroPresenciaDispositivo> estudiantesPresentes;

  /// Excepciones temporales concedidas en esta clase
  final List<ExcepcionTemporalApp> excepcionesTemporales;

  /// Bandera de emergencia institucional
  final bool restriccionesSuspendidasEmergencia;

  int get totalPresentes =>
      estudiantesPresentes.values.where((e) => e.estaPresente).length;

  int get totalCumpliendo => estudiantesPresentes.values
      .where((e) => e.estaPresente && e.cumplePolitica && !e.liberadoPorDocente)
      .length;

  int get totalExcepciones => excepcionesTemporales.where((e) => e.estaVigente).length +
      estudiantesPresentes.values.where((e) => e.liberadoPorDocente).length;

  // ===========================================================================
  // REGLA FUNDAMENTAL DE PRESENCIA (FASE 7)
  // HORARIO + ACTIVACIÓN DEL PROFESOR + PRESENCIA DEL DISPOSITIVO
  // ===========================================================================

  /// Determina categóricamente si el dispositivo de un alumno debe recibir la política de bloqueo.
  /// Si el alumno está en su casa o no tiene presencia validada, NUNCA se bloquea.
  bool puedeAplicarPoliticaA(String alumnoUid, List<String> alumnosInscritosEnClase) {
    // 1. Debe pertenecer a este curso
    if (!alumnosInscritosEnClase.contains(alumnoUid)) return false;

    // 2. La sesión debe estar activa
    if (estado != EstadoSesionModo.activa) return false;

    // 3. No deben estar suspendidas las restricciones por emergencia
    if (restriccionesSuspendidasEmergencia) return false;

    // 4. El dispositivo DEBE tener presencia validada en el aula
    final registro = estudiantesPresentes[alumnoUid];
    if (registro == null || !registro.estaPresente) {
      return false; // Alumno ausente / enfermo en casa -> NO BLOQUEAR
    }

    // 5. El profesor no debe haber liberado individualmente al estudiante
    if (registro.liberadoPorDocente) return false;

    return true;
  }

  /// Verifica si una aplicación cuenta con una excepción temporal activa para el alumno.
  bool tieneExcepcionTemporal(String appId, String alumnoUid) {
    for (final ex in excepcionesTemporales) {
      if (ex.appId == appId && ex.estaVigente) {
        if (ex.alumnoUid == null || ex.alumnoUid == alumnoUid) {
          return true;
        }
      }
    }
    return false;
  }

  SesionModoClase copyWith({
    String? id,
    String? claseId,
    String? cursoNombre,
    String? materia,
    String? profesorUid,
    String? profesorNombre,
    String? institucionId,
    TipoModoClase? tipoModo,
    EstadoSesionModo? estado,
    DateTime? horaInicio,
    DateTime? horaFin,
    PoliticaDispositivo? politicaAplicada,
    String? tokenPresenciaQr,
    DateTime? timestampToken,
    Map<String, RegistroPresenciaDispositivo>? estudiantesPresentes,
    List<ExcepcionTemporalApp>? excepcionesTemporales,
    bool? restriccionesSuspendidasEmergencia,
  }) {
    return SesionModoClase(
      id: id ?? this.id,
      claseId: claseId ?? this.claseId,
      cursoNombre: cursoNombre ?? this.cursoNombre,
      materia: materia ?? this.materia,
      profesorUid: profesorUid ?? this.profesorUid,
      profesorNombre: profesorNombre ?? this.profesorNombre,
      institucionId: institucionId ?? this.institucionId,
      tipoModo: tipoModo ?? this.tipoModo,
      estado: estado ?? this.estado,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
      politicaAplicada: politicaAplicada ?? this.politicaAplicada,
      tokenPresenciaQr: tokenPresenciaQr ?? this.tokenPresenciaQr,
      timestampToken: timestampToken ?? this.timestampToken,
      estudiantesPresentes: estudiantesPresentes ?? this.estudiantesPresentes,
      excepcionesTemporales:
          excepcionesTemporales ?? this.excepcionesTemporales,
      restriccionesSuspendidasEmergencia:
          restriccionesSuspendidasEmergencia ??
              this.restriccionesSuspendidasEmergencia,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'claseId': claseId,
      'cursoNombre': cursoNombre,
      'materia': materia,
      'profesorUid': profesorUid,
      'profesorNombre': profesorNombre,
      'institucionId': institucionId,
      'tipoModo': tipoModo.name,
      'estado': estado.name,
      'horaInicio': horaInicio.toIso8601String(),
      'horaFin': horaFin?.toIso8601String(),
      'politicaAplicada': politicaAplicada.toMap(),
      'tokenPresenciaQr': tokenPresenciaQr,
      'timestampToken': timestampToken.toIso8601String(),
      'estudiantesPresentes': estudiantesPresentes.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      'excepcionesTemporales':
          excepcionesTemporales.map((e) => e.toMap()).toList(),
      'restriccionesSuspendidasEmergencia':
          restriccionesSuspendidasEmergencia,
    };
  }

  factory SesionModoClase.fromMap(Map<String, dynamic> map) {
    final mapaEstudiantesRaw =
        (map['estudiantesPresentes'] as Map?)?.cast<String, dynamic>() ?? {};
    final estudiantesPresentes = mapaEstudiantesRaw.map(
      (key, value) => MapEntry(
        key,
        RegistroPresenciaDispositivo.fromMap(
          (value as Map).cast<String, dynamic>(),
        ),
      ),
    );

    final listaExcepcionesRaw =
        (map['excepcionesTemporales'] as List?) ?? [];
    final excepciones = listaExcepcionesRaw
        .map((e) => ExcepcionTemporalApp.fromMap((e as Map).cast<String, dynamic>()))
        .toList();

    return SesionModoClase(
      id: map['id'] as String? ?? '',
      claseId: map['claseId'] as String? ?? '',
      cursoNombre: map['cursoNombre'] as String? ?? 'Clase',
      materia: map['materia'] as String? ?? 'Matemáticas',
      profesorUid: map['profesorUid'] as String? ?? '',
      profesorNombre: map['profesorNombre'] as String? ?? 'Profesor',
      institucionId: map['institucionId'] as String? ?? 'INST-SAN-MARTIN',
      tipoModo: TipoModoClase.values.firstWhere(
        (t) => t.name == map['tipoModo'],
        orElse: () => TipoModoClase.clase,
      ),
      estado: EstadoSesionModo.values.firstWhere(
        (e) => e.name == map['estado'],
        orElse: () => EstadoSesionModo.activa,
      ),
      horaInicio: DateTime.tryParse(map['horaInicio'] as String? ?? '') ??
          DateTime.now(),
      horaFin: DateTime.tryParse(map['horaFin'] as String? ?? ''),
      politicaAplicada: PoliticaDispositivo.fromMap(
        (map['politicaAplicada'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
      tokenPresenciaQr: map['tokenPresenciaQr'] as String? ?? '',
      timestampToken: DateTime.tryParse(map['timestampToken'] as String? ?? '') ??
          DateTime.now(),
      estudiantesPresentes: estudiantesPresentes,
      excepcionesTemporales: excepciones,
      restriccionesSuspendidasEmergencia:
          map['restriccionesSuspendidasEmergencia'] as bool? ?? false,
    );
  }
}
