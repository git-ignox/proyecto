import '../modelos/recurso_educativo_offline.dart';

/// Calcula la disponibilidad offline ponderada de los materiales pedagógicos
/// de la semana lectiva (próximos 7 días móviles).
class CalculadorDisponibilidadSemana {
  const CalculadorDisponibilidadSemana({
    this.pesoObligatorio = 3.0,
    this.pesoOpcional = 1.0,
    this.diasVentana = 7,
  });

  final double pesoObligatorio;
  final double pesoOpcional;
  final int diasVentana;

  /// Determina si un recurso pertenece al rango de la semana actual.
  bool estaEnSemana(RecursoEducativoOffline recurso, {DateTime? ahora}) {
    final inicio = ahora ?? DateTime.now();
    final fin = inicio.add(Duration(days: diasVentana));

    // Incluye recursos de hoy hasta fin de los 7 días
    final inicioDia = DateTime(inicio.year, inicio.month, inicio.day);
    final finDia = DateTime(fin.year, fin.month, fin.day, 23, 59, 59);

    return recurso.fechaUsoClase.isAfter(inicioDia) &&
        recurso.fechaUsoClase.isBefore(finDia);
  }

  /// Computa la métrica detallada de la semana.
  MetricaPreparacionSemana calcular({
    required List<RecursoEducativoOffline> recursos,
    DateTime? ahora,
  }) {
    final referencia = ahora ?? DateTime.now();
    final recursosSemana =
        recursos.where((r) => estaEnSemana(r, ahora: referencia)).toList();

    if (recursosSemana.isEmpty) {
      return const MetricaPreparacionSemana(
        porcentajeListo: 100,
        totalMaterialesSemana: 0,
        materialesListos: 0,
        totalObligatorios: 0,
        obligatoriosListos: 0,
        desglosePorMateria: {},
        bytesTotales: 0,
        bytesDescargados: 0,
      );
    }

    double sumaPuntosObtenidos = 0.0;
    double sumaPuntosTotales = 0.0;
    int totalObligatorios = 0;
    int obligatoriosListos = 0;
    int materialesListos = 0;
    int bytesTotales = 0;
    int bytesDescargados = 0;

    final mapaMateriaTotales = <String, double>{};
    final mapaMateriaObtenidos = <String, double>{};

    for (final recurso in recursosSemana) {
      final peso = recurso.esObligatorio ? pesoObligatorio : pesoOpcional;
      sumaPuntosTotales += peso;
      bytesTotales += recurso.tamanoBytes;

      mapaMateriaTotales[recurso.materia] =
          (mapaMateriaTotales[recurso.materia] ?? 0.0) + peso;

      if (recurso.esObligatorio) {
        totalObligatorios++;
      }

      if (recurso.estaDescargado) {
        sumaPuntosObtenidos += peso;
        materialesListos++;
        bytesDescargados += recurso.tamanoBytes;

        mapaMateriaObtenidos[recurso.materia] =
            (mapaMateriaObtenidos[recurso.materia] ?? 0.0) + peso;

        if (recurso.esObligatorio) {
          obligatoriosListos++;
        }
      }
    }

    final porcentajeGeneral = sumaPuntosTotales > 0
        ? ((sumaPuntosObtenidos / sumaPuntosTotales) * 100).round().clamp(0, 100)
        : 100;

    final desglosePorMateria = <String, double>{};
    for (final materia in mapaMateriaTotales.keys) {
      final tot = mapaMateriaTotales[materia] ?? 1.0;
      final obt = mapaMateriaObtenidos[materia] ?? 0.0;
      desglosePorMateria[materia] =
          tot > 0 ? ((obt / tot) * 100).roundToDouble().clamp(0.0, 100.0) : 100.0;
    }

    return MetricaPreparacionSemana(
      porcentajeListo: porcentajeGeneral,
      totalMaterialesSemana: recursosSemana.length,
      materialesListos: materialesListos,
      totalObligatorios: totalObligatorios,
      obligatoriosListos: obligatoriosListos,
      desglosePorMateria: desglosePorMateria,
      bytesTotales: bytesTotales,
      bytesDescargados: bytesDescargados,
    );
  }
}
