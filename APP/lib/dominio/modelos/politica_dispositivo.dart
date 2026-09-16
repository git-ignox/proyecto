/// Nivel jerárquico que emite o modifica una directiva de control.
enum NivelJerarquiaPolitica {
  institucional,
  curso,
  materia,
  docente,
  sesion;

  String get etiqueta {
    switch (this) {
      case NivelJerarquiaPolitica.institucional:
        return 'Directiva Institucional Global 🏛️';
      case NivelJerarquiaPolitica.curso:
        return 'Ajuste por Curso / Grupo 👥';
      case NivelJerarquiaPolitica.materia:
        return 'Excepción Curricular por Materia 📚';
      case NivelJerarquiaPolitica.docente:
        return 'Permiso Concedido al Docente 👨‍🏫';
      case NivelJerarquiaPolitica.sesion:
        return 'Sesión de Aula en Tiempo Real ⏱️';
    }
  }
}

/// Estado de restricción para una aplicación o recurso.
enum EstadoReglaApp {
  permitido,
  bloqueado,
  bloqueadoCritico,
  permitidoTemporalmente,
  excepcionAutorizada;

  String get etiqueta {
    switch (this) {
      case EstadoReglaApp.permitido:
        return 'Permitida';
      case EstadoReglaApp.bloqueado:
        return 'Bloqueada';
      case EstadoReglaApp.bloqueadoCritico:
        return 'Bloqueo Crítico (No anulable)';
      case EstadoReglaApp.permitidoTemporalmente:
        return 'Permitida Temporalmente';
      case EstadoReglaApp.excepcionAutorizada:
        return 'Excepción Individual';
    }
  }
}

/// Categoría temática de aplicaciones.
enum CategoriaApp {
  redesSociales,
  juegos,
  streaming,
  herramientas,
  educativas,
  navegacion,
  comunicacion;

  String get nombreLegible {
    switch (this) {
      case CategoriaApp.redesSociales:
        return 'Redes Sociales';
      case CategoriaApp.juegos:
        return 'Juegos y Ocio';
      case CategoriaApp.streaming:
        return 'Video y Streaming';
      case CategoriaApp.herramientas:
        return 'Herramientas de Utilidad';
      case CategoriaApp.educativas:
        return 'Herramientas Educativas';
      case CategoriaApp.navegacion:
        return 'Navegación Web';
      case CategoriaApp.comunicacion:
        return 'Comunicación y Emergencias';
    }
  }
}

/// Representa una aplicación o recurso regulable en el dispositivo.
class AppRegla {
  const AppRegla({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.identificadorPaquete,
    this.estado = EstadoReglaApp.bloqueado,
    this.esEsencial = false,
    this.iconoNombre = 'apps',
  });

  final String id;
  final String nombre;
  final CategoriaApp categoria;
  final String identificadorPaquete;
  final EstadoReglaApp estado;
  final bool esEsencial;
  final String iconoNombre;

  bool get esPermitida =>
      estado == EstadoReglaApp.permitido ||
      estado == EstadoReglaApp.permitidoTemporalmente ||
      estado == EstadoReglaApp.excepcionAutorizada;

  bool get esBloqueada =>
      estado == EstadoReglaApp.bloqueado ||
      estado == EstadoReglaApp.bloqueadoCritico;

  bool get esBloqueoCritico => estado == EstadoReglaApp.bloqueadoCritico;

  /// Identificador nativo del paquete en Android / bundle ID en iOS
  String? get paqueteAndroid => identificadorPaquete.isNotEmpty ? identificadorPaquete : null;

  AppRegla copyWith({
    String? id,
    String? nombre,
    CategoriaApp? categoria,
    String? identificadorPaquete,
    EstadoReglaApp? estado,
    bool? esEsencial,
    String? iconoNombre,
  }) {
    return AppRegla(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      identificadorPaquete: identificadorPaquete ?? this.identificadorPaquete,
      estado: estado ?? this.estado,
      esEsencial: esEsencial ?? this.esEsencial,
      iconoNombre: iconoNombre ?? this.iconoNombre,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'categoria': categoria.name,
      'identificadorPaquete': identificadorPaquete,
      'estado': estado.name,
      'esEsencial': esEsencial,
      'iconoNombre': iconoNombre,
    };
  }

  factory AppRegla.fromMap(Map<String, dynamic> map) {
    return AppRegla(
      id: map['id'] as String? ?? '',
      nombre: map['nombre'] as String? ?? 'App',
      categoria: CategoriaApp.values.firstWhere(
        (c) => c.name == map['categoria'],
        orElse: () => CategoriaApp.herramientas,
      ),
      identificadorPaquete: map['identificadorPaquete'] as String? ?? '',
      estado: EstadoReglaApp.values.firstWhere(
        (e) => e.name == map['estado'],
        orElse: () => EstadoReglaApp.bloqueado,
      ),
      esEsencial: map['esEsencial'] as bool? ?? false,
      iconoNombre: map['iconoNombre'] as String? ?? 'apps',
    );
  }
}

/// Política de control contextual configurada en el sistema.
class PoliticaDispositivo {
  const PoliticaDispositivo({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.institucionId,
    this.cursoId,
    this.materiaId,
    this.jerarquia = NivelJerarquiaPolitica.institucional,
    this.apps = const [],
    this.permiteExcepcionesDocente = true,
    this.permiteModoExamen = true,
    this.esActiva = true,
  });

  final String id;
  final String nombre;
  final String descripcion;
  final String institucionId;
  final String? cursoId;
  final String? materiaId;
  final NivelJerarquiaPolitica jerarquia;
  final List<AppRegla> apps;
  final bool permiteExcepcionesDocente;
  final bool permiteModoExamen;
  final bool esActiva;

  List<AppRegla> get appsPermitidas => apps.where((a) => a.esPermitida).toList();
  List<AppRegla> get appsBloqueadas => apps.where((a) => a.esBloqueada).toList();

  PoliticaDispositivo copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    String? institucionId,
    String? cursoId,
    String? materiaId,
    NivelJerarquiaPolitica? jerarquia,
    List<AppRegla>? apps,
    bool? permiteExcepcionesDocente,
    bool? permiteModoExamen,
    bool? esActiva,
  }) {
    return PoliticaDispositivo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      institucionId: institucionId ?? this.institucionId,
      cursoId: cursoId ?? this.cursoId,
      materiaId: materiaId ?? this.materiaId,
      jerarquia: jerarquia ?? this.jerarquia,
      apps: apps ?? this.apps,
      permiteExcepcionesDocente:
          permiteExcepcionesDocente ?? this.permiteExcepcionesDocente,
      permiteModoExamen: permiteModoExamen ?? this.permiteModoExamen,
      esActiva: esActiva ?? this.esActiva,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'institucionId': institucionId,
      'cursoId': cursoId,
      'materiaId': materiaId,
      'jerarquia': jerarquia.name,
      'apps': apps.map((a) => a.toMap()).toList(),
      'permiteExcepcionesDocente': permiteExcepcionesDocente,
      'permiteModoExamen': permiteModoExamen,
      'esActiva': esActiva,
    };
  }

  factory PoliticaDispositivo.fromMap(Map<String, dynamic> map) {
    return PoliticaDispositivo(
      id: map['id'] as String? ?? '',
      nombre: map['nombre'] as String? ?? 'Política',
      descripcion: map['descripcion'] as String? ?? '',
      institucionId: map['institucionId'] as String? ?? '',
      cursoId: map['cursoId'] as String?,
      materiaId: map['materiaId'] as String?,
      jerarquia: NivelJerarquiaPolitica.values.firstWhere(
        (j) => j.name == map['jerarquia'],
        orElse: () => NivelJerarquiaPolitica.institucional,
      ),
      apps: (map['apps'] as List?)
              ?.map((a) => AppRegla.fromMap(a as Map<String, dynamic>))
              .toList() ??
          [],
      permiteExcepcionesDocente: map['permiteExcepcionesDocente'] as bool? ?? true,
      permiteModoExamen: map['permiteModoExamen'] as bool? ?? true,
      esActiva: map['esActiva'] as bool? ?? true,
    );
  }
}

/// Resultado unificado y consolidado que recibe el dispositivo del alumno.
class PoliticaEfectiva {
  const PoliticaEfectiva({
    required this.nombrePolitica,
    required this.institucionId,
    required this.reglasPorAppId,
    this.permiteModoExamen = true,
    this.permiteExcepcionesDocente = true,
  });

  final String nombrePolitica;
  final String institucionId;
  final Map<String, AppRegla> reglasPorAppId;
  final bool permiteModoExamen;
  final bool permiteExcepcionesDocente;

  List<AppRegla> get todasLasReglas => reglasPorAppId.values.toList();
  List<AppRegla> get permitidas =>
      reglasPorAppId.values.where((r) => r.esPermitida).toList();
  List<AppRegla> get bloqueadas =>
      reglasPorAppId.values.where((r) => r.esBloqueada).toList();

  bool esAppPermitida(String appId) {
    final regla = reglasPorAppId[appId];
    return regla?.esPermitida ?? false;
  }

  bool esBloqueoCritico(String appId) {
    final regla = reglasPorAppId[appId];
    return regla?.esBloqueoCritico ?? false;
  }

  /// Aplica una excepción temporal a una aplicación.
  PoliticaEfectiva conExcepcionTemporal(String appId) {
    if (!reglasPorAppId.containsKey(appId)) return this;
    final reglaOriginal = reglasPorAppId[appId]!;
    // Si la directiva es crítica y el docente no tiene anulación, no se modifica
    if (reglaOriginal.esBloqueoCritico) return this;

    final nuevasReglas = Map<String, AppRegla>.from(reglasPorAppId);
    nuevasReglas[appId] = reglaOriginal.copyWith(
      estado: EstadoReglaApp.permitidoTemporalmente,
    );
    return PoliticaEfectiva(
      nombrePolitica: '$nombrePolitica (Con Excepción Temporal)',
      institucionId: institucionId,
      reglasPorAppId: nuevasReglas,
      permiteModoExamen: permiteModoExamen,
      permiteExcepcionesDocente: permiteExcepcionesDocente,
    );
  }
}

/// Catálogo de plantillas predefinidas listas para aplicar.
class PlantillaPolitica {
  static const AppRegla appCalculadora = AppRegla(
    id: 'app_calculadora',
    nombre: 'Calculadora',
    categoria: CategoriaApp.herramientas,
    identificadorPaquete: 'com.apple.calculator / com.google.android.calculator',
    estado: EstadoReglaApp.permitido,
    esEsencial: true,
    iconoNombre: 'calculate',
  );

  static const AppRegla appCamara = AppRegla(
    id: 'app_camara',
    nombre: 'Cámara (para evidencias)',
    categoria: CategoriaApp.herramientas,
    identificadorPaquete: 'com.apple.camera / com.google.android.GoogleCamera',
    estado: EstadoReglaApp.permitido,
    iconoNombre: 'camera_alt',
  );

  static const AppRegla appDiccionario = AppRegla(
    id: 'app_diccionario',
    nombre: 'Diccionario y Glosario',
    categoria: CategoriaApp.educativas,
    identificadorPaquete: 'edu.institucion.diccionario',
    estado: EstadoReglaApp.permitido,
    iconoNombre: 'menu_book',
  );

  static const AppRegla appInstitucional = AppRegla(
    id: 'app_institucional',
    nombre: 'Plataforma del Colegio',
    categoria: CategoriaApp.educativas,
    identificadorPaquete: 'cl.colegio.plataforma',
    estado: EstadoReglaApp.permitido,
    esEsencial: true,
    iconoNombre: 'school',
  );

  static const AppRegla appGeoGebra = AppRegla(
    id: 'app_geogebra',
    nombre: 'GeoGebra Matemáticas',
    categoria: CategoriaApp.educativas,
    identificadorPaquete: 'org.geogebra.android',
    estado: EstadoReglaApp.permitido,
    iconoNombre: 'functions',
  );

  // Bloqueadas críticas
  static const AppRegla appTikTok = AppRegla(
    id: 'app_tiktok',
    nombre: 'TikTok',
    categoria: CategoriaApp.redesSociales,
    identificadorPaquete: 'com.zhiliaoapp.musically',
    estado: EstadoReglaApp.bloqueadoCritico,
    iconoNombre: 'music_video',
  );

  static const AppRegla appInstagram = AppRegla(
    id: 'app_instagram',
    nombre: 'Instagram',
    categoria: CategoriaApp.redesSociales,
    identificadorPaquete: 'com.instagram.android',
    estado: EstadoReglaApp.bloqueadoCritico,
    iconoNombre: 'photo_camera_back',
  );

  static const AppRegla appJuegos = AppRegla(
    id: 'app_juegos',
    nombre: 'Juegos y Entretenimiento',
    categoria: CategoriaApp.juegos,
    identificadorPaquete: 'games.*',
    estado: EstadoReglaApp.bloqueadoCritico,
    iconoNombre: 'sports_esports',
  );

  static const AppRegla appYouTube = AppRegla(
    id: 'app_youtube',
    nombre: 'YouTube Streaming',
    categoria: CategoriaApp.streaming,
    identificadorPaquete: 'com.google.android.youtube',
    estado: EstadoReglaApp.bloqueado,
    iconoNombre: 'smart_display',
  );

  /// Catálogo estándar con las apps base
  static List<AppRegla> get catalogoEstandar => [
        appCalculadora,
        appCamara,
        appDiccionario,
        appInstitucional,
        appGeoGebra,
        appTikTok,
        appInstagram,
        appJuegos,
        appYouTube,
      ];

  /// Plantilla: Modo Clase Estándar
  static PoliticaDispositivo modoClaseEstandar({
    required String institucionId,
    String id = 'POL-ESTANDAR-GLOBAL',
  }) {
    return PoliticaDispositivo(
      id: id,
      nombre: 'Modo Clase Estándar Institucional',
      descripcion:
          'Permite utilidades educativas esenciales (Calculadora, Diccionario, Cámara, App Institucional) y bloquea redes sociales, juegos y streaming.',
      institucionId: institucionId,
      jerarquia: NivelJerarquiaPolitica.institucional,
      apps: catalogoEstandar,
      permiteExcepcionesDocente: true,
      permiteModoExamen: true,
    );
  }

  /// Plantilla: Modo Examen Riguroso
  static PoliticaDispositivo modoExamenRiguroso({
    required String institucionId,
    String id = 'POL-EXAMEN-RIGUROSO',
  }) {
    final appsExamen = catalogoEstandar.map((a) {
      if (a.id == appInstitucional.id) {
        return a.copyWith(estado: EstadoReglaApp.permitido);
      }
      return a.copyWith(estado: EstadoReglaApp.bloqueadoCritico);
    }).toList();

    return PoliticaDispositivo(
      id: id,
      nombre: 'Modo Examen Riguroso',
      descripcion:
          'Restricción máxima: Solo la prueba activa en pantalla. Todo el resto de herramientas bloqueadas sin excepción.',
      institucionId: institucionId,
      jerarquia: NivelJerarquiaPolitica.institucional,
      apps: appsExamen,
      permiteExcepcionesDocente: false,
      permiteModoExamen: true,
    );
  }

  /// Plantilla: Modo Investigación & Biblioteca
  static PoliticaDispositivo modoInvestigacion({
    required String institucionId,
    String id = 'POL-INVESTIGACION',
  }) {
    final appsInvestigacion = catalogoEstandar.map((a) {
      if (a.id == appYouTube.id) {
        return a.copyWith(estado: EstadoReglaApp.permitidoTemporalmente);
      }
      return a;
    }).toList();

    return PoliticaDispositivo(
      id: id,
      nombre: 'Modo Investigación Guiada',
      descripcion:
          'Habilita consultas educativas y visualización temporal de recursos multimedia, manteniendo bloqueadas las redes sociales.',
      institucionId: institucionId,
      jerarquia: NivelJerarquiaPolitica.institucional,
      apps: appsInvestigacion,
      permiteExcepcionesDocente: true,
      permiteModoExamen: false,
    );
  }
}
