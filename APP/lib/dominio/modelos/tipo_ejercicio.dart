/// Tipos de ejercicios soportados por la aplicación.
enum TipoEjercicio {
  seleccionMultiple,
  numerico,
  algebraico,
  desarrollo,
  aritmetico,
}

/// Modo de evaluación del sistema:
/// - [offline]: Evaluación local mediante algoritmos matemáticos y de similitud.
/// - [online]: Preparado para evaluar mediante un modelo de IA o servicio remoto.
enum ModoEvaluacion {
  offline,
  online,
}

