/// Modelo de un Objetivo o Estándar de Aprendizaje curricular.
class ObjetivoAprendizaje {
  const ObjetivoAprendizaje({
    required this.id,
    required this.unidadId,
    required this.codigo,
    required this.nombre,
    this.descripcion = '',
    this.orden = 1,
  });

  final String id;
  final String unidadId;

  /// Código estandarizado único dentro del currículo (ej. 'OA-01', 'OA-02').
  final String codigo;

  /// Título conciso del objetivo o estándar.
  final String nombre;

  /// Descripción detallada o criterio de logro pedagógico.
  final String descripcion;

  /// Posición u orden dentro de la unidad.
  final int orden;

  /// Etiqueta combinada para visualización clara (ej. "OA-01: Operaciones con números racionales").
  String get etiquetaCompleta => '$codigo: $nombre';

  ObjetivoAprendizaje copyWith({
    String? id,
    String? unidadId,
    String? codigo,
    String? nombre,
    String? descripcion,
    int? orden,
  }) {
    return ObjetivoAprendizaje(
      id: id ?? this.id,
      unidadId: unidadId ?? this.unidadId,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      orden: orden ?? this.orden,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unidadId': unidadId,
      'codigo': codigo,
      'nombre': nombre,
      'descripcion': descripcion,
      'orden': orden,
    };
  }

  factory ObjetivoAprendizaje.fromMap(Map<String, dynamic> map) {
    return ObjetivoAprendizaje(
      id: map['id'] as String? ?? '',
      unidadId: map['unidadId'] as String? ?? '',
      codigo: map['codigo'] as String? ?? '',
      nombre: map['nombre'] as String? ?? '',
      descripcion: map['descripcion'] as String? ?? '',
      orden: (map['orden'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ObjetivoAprendizaje && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Unidad curricular temática que agrupa múltiples objetivos de aprendizaje.
class UnidadCurricular {
  const UnidadCurricular({
    required this.id,
    required this.planCurricularId,
    required this.numero,
    required this.nombre,
    required this.periodoSugerido,
    this.descripcion = '',
    this.objetivos = const [],
  });

  final String id;
  final String planCurricularId;

  /// Número de orden pedagógico (ej. 1, 2, 3).
  final int numero;

  /// Título de la unidad (ej. "Unidad 1: Números y Operaciones").
  final String nombre;

  /// Período sugerido en el año escolar (ej. "Trimestre 1", "Semestre 1").
  final String periodoSugerido;

  final String descripcion;

  /// Objetivos o estándares curriculares correspondientes a esta unidad.
  final List<ObjetivoAprendizaje> objetivos;

  int get totalObjetivos => objetivos.length;

  UnidadCurricular copyWith({
    String? id,
    String? planCurricularId,
    int? numero,
    String? nombre,
    String? periodoSugerido,
    String? descripcion,
    List<ObjetivoAprendizaje>? objetivos,
  }) {
    return UnidadCurricular(
      id: id ?? this.id,
      planCurricularId: planCurricularId ?? this.planCurricularId,
      numero: numero ?? this.numero,
      nombre: nombre ?? this.nombre,
      periodoSugerido: periodoSugerido ?? this.periodoSugerido,
      descripcion: descripcion ?? this.descripcion,
      objetivos: objetivos ?? this.objetivos,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'planCurricularId': planCurricularId,
      'numero': numero,
      'nombre': nombre,
      'periodoSugerido': periodoSugerido,
      'descripcion': descripcion,
      'objetivos': objetivos.map((o) => o.toMap()).toList(),
    };
  }

  factory UnidadCurricular.fromMap(Map<String, dynamic> map) {
    return UnidadCurricular(
      id: map['id'] as String? ?? '',
      planCurricularId: map['planCurricularId'] as String? ?? '',
      numero: (map['numero'] as num?)?.toInt() ?? 1,
      nombre: map['nombre'] as String? ?? '',
      periodoSugerido: map['periodoSugerido'] as String? ?? '',
      descripcion: map['descripcion'] as String? ?? '',
      objetivos: (map['objetivos'] as List<dynamic>?)
              ?.map((item) => ObjetivoAprendizaje.fromMap(Map<String, dynamic>.from(item as Map)))
              .toList() ??
          const [],
    );
  }
}

/// Plan Curricular completo de una asignatura y nivel (ej. "Matemática 8vo Básico").
class PlanCurricular {
  PlanCurricular({
    required this.id,
    required this.nombre,
    required this.area,
    required this.nivelGrado,
    this.descripcion = '',
    this.profesorUid,
    this.unidades = const [],
    DateTime? fechaCreacion,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  final String id;
  final String nombre;
  final String area;
  final String nivelGrado;
  final String descripcion;

  /// Si es nulo, es una plantilla o plan oficial del sistema.
  /// Si tiene UID, fue creado o personalizado por dicho docente.
  final String? profesorUid;

  final List<UnidadCurricular> unidades;
  final DateTime fechaCreacion;

  /// Total acumulado de objetivos de aprendizaje en todo el plan.
  int get totalObjetivos => unidades.fold(0, (acc, u) => acc + u.totalObjetivos);

  /// Lista plana de todos los objetivos del plan.
  List<ObjetivoAprendizaje> get todosLosObjetivos =>
      unidades.expand((u) => u.objetivos).toList();

  /// Busca un objetivo por su id.
  ObjetivoAprendizaje? buscarObjetivoPorId(String id) {
    for (final u in unidades) {
      for (final o in u.objetivos) {
        if (o.id == id) return o;
      }
    }
    return null;
  }

  PlanCurricular copyWith({
    String? id,
    String? nombre,
    String? area,
    String? nivelGrado,
    String? descripcion,
    String? profesorUid,
    List<UnidadCurricular>? unidades,
    DateTime? fechaCreacion,
  }) {
    return PlanCurricular(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      area: area ?? this.area,
      nivelGrado: nivelGrado ?? this.nivelGrado,
      descripcion: descripcion ?? this.descripcion,
      profesorUid: profesorUid ?? this.profesorUid,
      unidades: unidades ?? this.unidades,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'area': area,
      'nivelGrado': nivelGrado,
      'descripcion': descripcion,
      'profesorUid': profesorUid,
      'unidades': unidades.map((u) => u.toMap()).toList(),
      'fechaCreacion': fechaCreacion.toIso8601String(),
    };
  }

  factory PlanCurricular.fromMap(Map<String, dynamic> map) {
    return PlanCurricular(
      id: map['id'] as String? ?? '',
      nombre: map['nombre'] as String? ?? '',
      area: map['area'] as String? ?? '',
      nivelGrado: map['nivelGrado'] as String? ?? '',
      descripcion: map['descripcion'] as String? ?? '',
      profesorUid: map['profesorUid'] as String?,
      unidades: (map['unidades'] as List<dynamic>?)
              ?.map((item) => UnidadCurricular.fromMap(Map<String, dynamic>.from(item as Map)))
              .toList() ??
          const [],
      fechaCreacion: map['fechaCreacion'] != null
          ? DateTime.tryParse(map['fechaCreacion'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
