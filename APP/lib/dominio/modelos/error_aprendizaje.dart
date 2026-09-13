/// Categorías taxonómicas de errores comunes cometidos en matemáticas.
enum CategoriaError {
  calculoAritmetico,
  acarreoReagrupacion,
  signoOperacion,
  hechoNumerico,
  procedimientoAlgoritmo,
  precisionRedondeo,
  despejeIncognita,
  comprensionConceptual,
  sintaxisFormato,
  desconocido;

  String get etiqueta {
    switch (this) {
      case CategoriaError.calculoAritmetico:
        return 'Cálculo Aritmético';
      case CategoriaError.acarreoReagrupacion:
        return 'Acarreo o Reagrupación';
      case CategoriaError.signoOperacion:
        return 'Signos / Operación';
      case CategoriaError.hechoNumerico:
        return 'Hecho Numérico / Tablas';
      case CategoriaError.procedimientoAlgoritmo:
        return 'Procedimiento / Pasos';
      case CategoriaError.precisionRedondeo:
        return 'Precisión y Redondeo';
      case CategoriaError.despejeIncognita:
        return 'Despeje de Incógnita';
      case CategoriaError.comprensionConceptual:
        return 'Comprensión Conceptual';
      case CategoriaError.sintaxisFormato:
        return 'Formato o Sintaxis';
      case CategoriaError.desconocido:
        return 'Error General';
    }
  }

  String get icono {
    switch (this) {
      case CategoriaError.calculoAritmetico:
        return '🔢';
      case CategoriaError.acarreoReagrupacion:
        return '🔄';
      case CategoriaError.signoOperacion:
        return '⚖️';
      case CategoriaError.hechoNumerico:
        return '✖️';
      case CategoriaError.procedimientoAlgoritmo:
        return '📋';
      case CategoriaError.precisionRedondeo:
        return '🎯';
      case CategoriaError.despejeIncognita:
        return '❓';
      case CategoriaError.comprensionConceptual:
        return '💡';
      case CategoriaError.sintaxisFormato:
        return '⌨️';
      case CategoriaError.desconocido:
        return '⚠️';
    }
  }
}

/// Nivel de gravedad o criticidad del error para el progreso pedagógico.
enum SeveridadError {
  leve,
  moderada,
  critica;

  String get etiqueta {
    switch (this) {
      case SeveridadError.leve:
        return 'Leve';
      case SeveridadError.moderada:
        return 'Moderada';
      case SeveridadError.critica:
        return 'Crítica';
    }
  }
}

/// Representa un error específico identificado durante la evaluación de un ejercicio.
class ErrorAprendizaje {
  const ErrorAprendizaje({
    required this.id,
    required this.categoria,
    required this.subtipo,
    required this.descripcion,
    required this.sugerenciaPedagogica,
    this.tagsAsociados = const [],
    this.severidad = SeveridadError.moderada,
  });

  /// Identificador único del tipo de error (e.g. 'ERR-ACARREO-01').
  final String id;

  /// Categoría general a la que pertenece el error.
  final CategoriaError categoria;

  /// Subtipo o código específico (e.g. 'olvido_acarreo_decenas', 'inversion_signo_resta').
  final String subtipo;

  /// Explicación clara de qué fallo se detectó en la respuesta del alumno.
  final String descripcion;

  /// Consejo o estrategia didáctica para ayudar al alumno a corregirlo y comprender.
  final String sugerenciaPedagogica;

  /// Conceptos o temas pedagógicos vinculados a este error (e.g. ['acarreo', 'suma']).
  final List<String> tagsAsociados;

  /// Criticidad del error detectado.
  final SeveridadError severidad;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoria': categoria.name,
      'subtipo': subtipo,
      'descripcion': descripcion,
      'sugerenciaPedagogica': sugerenciaPedagogica,
      'tagsAsociados': tagsAsociados,
      'severidad': severidad.name,
    };
  }

  factory ErrorAprendizaje.fromMap(Map<String, dynamic> map) {
    return ErrorAprendizaje(
      id: map['id'] as String? ?? 'ERR-GENERICO',
      categoria: CategoriaError.values.firstWhere(
        (c) => c.name == map['categoria'],
        orElse: () => CategoriaError.desconocido,
      ),
      subtipo: map['subtipo'] as String? ?? 'general',
      descripcion: map['descripcion'] as String? ?? '',
      sugerenciaPedagogica: map['sugerenciaPedagogica'] as String? ?? '',
      tagsAsociados: (map['tagsAsociados'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      severidad: SeveridadError.values.firstWhere(
        (s) => s.name == map['severidad'],
        orElse: () => SeveridadError.moderada,
      ),
    );
  }
}
