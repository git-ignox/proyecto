import 'dart:math';

/// Tipos de contenidos educativos compartidos por los docentes.
enum TipoRecursoEducativo {
  pdf,
  documento,
  imagen,
  video,
  paginaWebMhtml,
}

/// Estados posibles en el ciclo de vida de la sincronización offline.
enum EstadoSincronizacion {
  pendiente,
  enCola,
  descargando,
  pausado,
  completado,
  errorIntegridad,
  errorRed,
}

/// Razones por las que una descarga puede pausarse automáticamente.
enum CausaPausa {
  ninguna,
  sinWifi,
  bateriaBaja,
  dispositivoActivo,
  sinEspacio,
  pausaManual,
}

/// Representa un material o página web asociada a una clase y fecha lectiva.
class RecursoEducativoOffline {
  const RecursoEducativoOffline({
    required this.id,
    required this.claseId,
    required this.materia,
    required this.titulo,
    required this.descripcion,
    required this.tipoRecurso,
    required this.remoteUrl,
    this.localPath,
    required this.tamanoBytes,
    required this.checksumSha256,
    this.esObligatorio = true,
    this.esFijado = false,
    required this.fechaUsoClase,
    this.ultimoAcceso,
    this.diasRetencion = 7,
    this.profesorNombre = 'Profesor',
  });

  final String id;
  final String claseId;
  final String materia;
  final String titulo;
  final String descripcion;
  final TipoRecursoEducativo tipoRecurso;
  final String remoteUrl;

  /// Ruta local en el sandbox de la app si ya fue descargado y verificado.
  final String? localPath;

  /// Tamaño exacto en bytes del archivo o paquete web MHTML.
  final int tamanoBytes;

  /// Hash criptográfico para garantizar que el archivo descargado no esté corrupto.
  final String checksumSha256;

  /// Si es obligatorio (peso pedagógico alto) o complementario/opcional.
  final bool esObligatorio;

  /// Si el alumno o profesor marcó el material como "Intocable" (inmune a limpieza).
  final bool esFijado;

  /// Fecha y hora de la clase escolar donde se utilizará el material.
  final DateTime fechaUsoClase;

  /// Momento en que el alumno abrió o leyó el recurso localmente (null si no lo ha visto).
  final DateTime? ultimoAcceso;

  /// Días de retención mínima garantizada tras la fecha de clase.
  final int diasRetencion;

  final String profesorNombre;

  /// Tamaño expresado en megabytes (MB) para cálculos de prioridad y UI.
  double get tamanoMB => max(0.1, tamanoBytes / (1024 * 1024));

  /// Representación legible para la UI (ej. "2.4 MB", "450 KB").
  String get tamanoLegible {
    if (tamanoBytes < 1024 * 1024) {
      final kb = (tamanoBytes / 1024).round();
      return '$kb KB';
    }
    final mb = (tamanoBytes / (1024 * 1024)).toStringAsFixed(1);
    return '$mb MB';
  }

  /// Indica si el alumno ya abrió y consumió este material.
  bool get yaVisto => ultimoAcceso != null;

  /// Indica si el archivo ya existe localmente.
  bool get estaDescargado => localPath != null && localPath!.isNotEmpty;

  RecursoEducativoOffline copyWith({
    String? id,
    String? claseId,
    String? materia,
    String? titulo,
    String? descripcion,
    TipoRecursoEducativo? tipoRecurso,
    String? remoteUrl,
    String? localPath,
    int? tamanoBytes,
    String? checksumSha256,
    bool? esObligatorio,
    bool? esFijado,
    DateTime? fechaUsoClase,
    DateTime? ultimoAcceso,
    int? diasRetencion,
    String? profesorNombre,
  }) {
    return RecursoEducativoOffline(
      id: id ?? this.id,
      claseId: claseId ?? this.claseId,
      materia: materia ?? this.materia,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      tipoRecurso: tipoRecurso ?? this.tipoRecurso,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      localPath: localPath ?? this.localPath,
      tamanoBytes: tamanoBytes ?? this.tamanoBytes,
      checksumSha256: checksumSha256 ?? this.checksumSha256,
      esObligatorio: esObligatorio ?? this.esObligatorio,
      esFijado: esFijado ?? this.esFijado,
      fechaUsoClase: fechaUsoClase ?? this.fechaUsoClase,
      ultimoAcceso: ultimoAcceso ?? this.ultimoAcceso,
      diasRetencion: diasRetencion ?? this.diasRetencion,
      profesorNombre: profesorNombre ?? this.profesorNombre,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'claseId': claseId,
      'materia': materia,
      'titulo': titulo,
      'descripcion': descripcion,
      'tipoRecurso': tipoRecurso.name,
      'remoteUrl': remoteUrl,
      'localPath': localPath,
      'tamanoBytes': tamanoBytes,
      'checksumSha256': checksumSha256,
      'esObligatorio': esObligatorio ? 1 : 0,
      'esFijado': esFijado ? 1 : 0,
      'fechaUsoClase': fechaUsoClase.toIso8601String(),
      'ultimoAcceso': ultimoAcceso?.toIso8601String(),
      'diasRetencion': diasRetencion,
      'profesorNombre': profesorNombre,
    };
  }

  factory RecursoEducativoOffline.fromMap(Map<String, dynamic> map) {
    return RecursoEducativoOffline(
      id: map['id'] as String,
      claseId: map['claseId'] as String,
      materia: map['materia'] as String,
      titulo: map['titulo'] as String,
      descripcion: map['descripcion'] as String,
      tipoRecurso: TipoRecursoEducativo.values.firstWhere(
        (t) => t.name == map['tipoRecurso'],
        orElse: () => TipoRecursoEducativo.pdf,
      ),
      remoteUrl: map['remoteUrl'] as String,
      localPath: map['localPath'] as String?,
      tamanoBytes: map['tamanoBytes'] as int,
      checksumSha256: map['checksumSha256'] as String,
      esObligatorio: (map['esObligatorio'] as int? ?? 1) == 1,
      esFijado: (map['esFijado'] as int? ?? 0) == 1,
      fechaUsoClase: DateTime.parse(map['fechaUsoClase'] as String),
      ultimoAcceso: map['ultimoAcceso'] != null
          ? DateTime.parse(map['ultimoAcceso'] as String)
          : null,
      diasRetencion: map['diasRetencion'] as int? ?? 7,
      profesorNombre: map['profesorNombre'] as String? ?? 'Profesor',
    );
  }
}

/// Estado de la descarga de un recurso, incluyendo soporte de tramos continuos.
class TareaSincronizacion {
  const TareaSincronizacion({
    required this.recursoId,
    required this.estado,
    this.causaPausa = CausaPausa.ninguna,
    this.bytesDescargados = 0,
    required this.totalBytes,
    this.reintentos = 0,
    this.ultimoError,
    required this.fechaActualizacion,
  });

  final String recursoId;
  final EstadoSincronizacion estado;
  final CausaPausa causaPausa;
  final int bytesDescargados;
  final int totalBytes;
  final int reintentos;
  final String? ultimoError;
  final DateTime fechaActualizacion;

  double get progreso =>
      totalBytes > 0 ? (bytesDescargados / totalBytes).clamp(0.0, 1.0) : 0.0;

  int get porcentajeProgreso => (progreso * 100).round();

  bool get estaCompletada => estado == EstadoSincronizacion.completado;

  TareaSincronizacion copyWith({
    String? recursoId,
    EstadoSincronizacion? estado,
    CausaPausa? causaPausa,
    int? bytesDescargados,
    int? totalBytes,
    int? reintentos,
    String? ultimoError,
    DateTime? fechaActualizacion,
  }) {
    return TareaSincronizacion(
      recursoId: recursoId ?? this.recursoId,
      estado: estado ?? this.estado,
      causaPausa: causaPausa ?? this.causaPausa,
      bytesDescargados: bytesDescargados ?? this.bytesDescargados,
      totalBytes: totalBytes ?? this.totalBytes,
      reintentos: reintentos ?? this.reintentos,
      ultimoError: ultimoError ?? this.ultimoError,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}

/// Telemetría del dispositivo para permitir o pausar descargas en segundo plano.
class CondicionesDispositivo {
  const CondicionesDispositivo({
    required this.hayWifi,
    required this.bateriaPorcentaje,
    required this.estaCargando,
    this.dispositivoInactivo = true,
    this.espacioLibreBytes = 1024 * 1024 * 1024 * 2, // 2 GB por defecto
  });

  final bool hayWifi;
  final int bateriaPorcentaje;
  final bool estaCargando;
  final bool dispositivoInactivo;
  final int espacioLibreBytes;

  /// La batería se considera suficiente si supera el 20% o si está conectado a la corriente.
  bool get bateriaSuficiente => estaCargando || bateriaPorcentaje >= 20;

  /// Determina si las condiciones de hardware permiten iniciar/continuar descargas transparentes.
  bool get permiteDescargaEnSegundoPlano => hayWifi && bateriaSuficiente;

  /// Describe de manera amigable por qué no se puede descargar en background si procede.
  CausaPausa get causaBloqueo {
    if (!hayWifi) return CausaPausa.sinWifi;
    if (!bateriaSuficiente) return CausaPausa.bateriaBaja;
    return CausaPausa.ninguna;
  }
}

/// Métrica de disponibilidad offline para el estudiante.
class MetricaPreparacionSemana {
  const MetricaPreparacionSemana({
    required this.porcentajeListo,
    required this.totalMaterialesSemana,
    required this.materialesListos,
    required this.totalObligatorios,
    required this.obligatoriosListos,
    required this.desglosePorMateria,
    required this.bytesTotales,
    required this.bytesDescargados,
  });

  final int porcentajeListo;
  final int totalMaterialesSemana;
  final int materialesListos;
  final int totalObligatorios;
  final int obligatoriosListos;
  final Map<String, double> desglosePorMateria;
  final int bytesTotales;
  final int bytesDescargados;

  String get mensajeResumen =>
      '$porcentajeListo% del material de esta semana está disponible sin internet';

  bool get todoListo => porcentajeListo >= 100;
}
