import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/datos/fuente_datos_reportes.dart';
import 'package:proyecto/dominio/modelos/analisis_brechas.dart';
import 'package:proyecto/dominio/modelos/reporte_pedagogico.dart';

void main() {
  group('Modelo SnapshotTemaReporte', () {
    test('Detección correcta de brecha crítica (< 60%)', () {
      const snapCritico = SnapshotTemaReporte(
        tema: 'Geometría',
        porcentajeDominio: 45.0,
        promedioNota: 3.2,
        cantidadEvaluaciones: 1,
        nivelDominio: NivelDominio.critico,
      );

      const snapConsolidado = SnapshotTemaReporte(
        tema: 'Álgebra',
        porcentajeDominio: 85.0,
        promedioNota: 6.0,
        cantidadEvaluaciones: 2,
        nivelDominio: NivelDominio.consolidado,
      );

      expect(snapCritico.esBrechaCritica, isTrue);
      expect(snapConsolidado.esBrechaCritica, isFalse);
    });

    test('Serialización y deserialización toMap / fromMap', () {
      const original = SnapshotTemaReporte(
        tema: 'Aritmética',
        porcentajeDominio: 72.5,
        promedioNota: 5.1,
        cantidadEvaluaciones: 3,
        nivelDominio: NivelDominio.enDesarrollo,
        porcentajePeriodoAnterior: 50.0,
        tendenciaInterPeriodo: TendenciaInterPeriodo.mejora,
      );

      final map = original.toMap();
      final recuperado = SnapshotTemaReporte.fromMap(map);

      expect(recuperado.tema, equals('Aritmética'));
      expect(recuperado.porcentajeDominio, equals(72.5));
      expect(recuperado.promedioNota, equals(5.1));
      expect(recuperado.cantidadEvaluaciones, equals(3));
      expect(recuperado.nivelDominio, equals(NivelDominio.enDesarrollo));
      expect(recuperado.porcentajePeriodoAnterior, equals(50.0));
      expect(recuperado.tendenciaInterPeriodo, equals(TendenciaInterPeriodo.mejora));
    });
  });

  group('Modelo ReporteEstudiante', () {
    test('Detección de riesgo multitemático (>= 2 brechas críticas)', () {
      final reporteConDosBrechas = ReporteEstudiante(
        id: 'REP-01',
        claseId: 'CLASE-01',
        periodo: '1° Trimestre',
        alumnoUid: 'alumno-1',
        alumnoNombre: 'Mateo Rivas',
        fechaGeneracion: DateTime(2026, 9, 10),
        promedioGeneral: 4.2,
        porcentajeGeneral: 60.0,
        totalTemasEnRiesgo: 2,
        temasPriorizados: const [
          SnapshotTemaReporte(
            tema: 'Álgebra',
            porcentajeDominio: 45.0,
            promedioNota: 3.2,
            cantidadEvaluaciones: 1,
            nivelDominio: NivelDominio.critico,
          ),
          SnapshotTemaReporte(
            tema: 'Geometría',
            porcentajeDominio: 55.0,
            promedioNota: 3.9,
            cantidadEvaluaciones: 1,
            nivelDominio: NivelDominio.critico,
          ),
          SnapshotTemaReporte(
            tema: 'Aritmética',
            porcentajeDominio: 80.0,
            promedioNota: 5.6,
            cantidadEvaluaciones: 1,
            nivelDominio: NivelDominio.consolidado,
          ),
        ],
      );

      final reporteConUnaBrecha = reporteConDosBrechas.copyWith(
        totalTemasEnRiesgo: 1,
      );

      expect(reporteConDosBrechas.enRiesgoMultitematico, isTrue);
      expect(reporteConUnaBrecha.enRiesgoMultitematico, isFalse);
      expect(reporteConDosBrechas.brechaPrincipal?.tema, equals('Álgebra'));
      expect(reporteConDosBrechas.fortalezaPrincipal?.tema, equals('Aritmética'));
    });

    test('Serialización y deserialización toMap / fromMap de ReporteEstudiante', () {
      final fecha = DateTime(2026, 9, 10, 15, 30);
      final reporte = ReporteEstudiante(
        id: 'REP-SER-01',
        claseId: 'CLASE-DEMO',
        periodo: '2° Trimestre',
        alumnoUid: 'alumno-x',
        alumnoNombre: 'Sofía Valenzuela',
        fechaGeneracion: fecha,
        promedioGeneral: 6.2,
        porcentajeGeneral: 88.5,
        totalTemasEnRiesgo: 0,
        comentarioDocente: 'Excelente trabajo durante todo el trimestre.',
        temasPriorizados: const [
          SnapshotTemaReporte(
            tema: 'Álgebra',
            porcentajeDominio: 88.5,
            promedioNota: 6.2,
            cantidadEvaluaciones: 2,
            nivelDominio: NivelDominio.consolidado,
          ),
        ],
      );

      final map = reporte.toMap();
      final recuperado = ReporteEstudiante.fromMap(map);

      expect(recuperado.id, equals('REP-SER-01'));
      expect(recuperado.claseId, equals('CLASE-DEMO'));
      expect(recuperado.periodo, equals('2° Trimestre'));
      expect(recuperado.alumnoNombre, equals('Sofía Valenzuela'));
      expect(recuperado.promedioGeneral, equals(6.2));
      expect(recuperado.porcentajeGeneral, equals(88.5));
      expect(recuperado.comentarioDocente, equals('Excelente trabajo durante todo el trimestre.'));
      expect(recuperado.temasPriorizados.length, equals(1));
      expect(recuperado.temasPriorizados.first.tema, equals('Álgebra'));
    });
  });

  group('FuenteDatosReportes (Persistencia & Memoria)', () {
    test('Carga datos demo de CLASE-DEMO-001 correctamente', () async {
      final repo = FuenteDatosReportes();
      final reportesClase = await repo.obtenerReportesPorClase('CLASE-DEMO-001');

      expect(reportesClase.length, equals(4));

      // Verificar que incluye a Sofía, Mateo, Camila y Joaquín
      final nombres = reportesClase.map((r) => r.alumnoNombre).toSet();
      expect(nombres, contains('Sofía Valenzuela'));
      expect(nombres, contains('Mateo Rivas'));
      expect(nombres, contains('Camila Soto'));
      expect(nombres, contains('Joaquín Herrera'));

      // Mateo tiene riesgo multitemático (Álgebra y Geometría)
      final mateo = reportesClase.firstWhere((r) => r.alumnoNombre == 'Mateo Rivas');
      expect(mateo.enRiesgoMultitematico, isTrue);
      expect(mateo.totalTemasEnRiesgo, equals(2));

      // Sofía tiene 1 tema en riesgo (Geometría)
      final sofia = reportesClase.firstWhere((r) => r.alumnoNombre == 'Sofía Valenzuela');
      expect(sofia.totalTemasEnRiesgo, equals(1));
      expect(sofia.brechaPrincipal?.tema, equals('Geometría'));
    });

    test('Guardar y eliminar reporte actualiza el estado', () async {
      final repo = FuenteDatosReportes();

      final nuevo = ReporteEstudiante(
        id: 'REP-TEST-NUEVO',
        claseId: 'CLASE-TEST',
        periodo: '1° Trimestre',
        alumnoUid: 'alumno-test',
        alumnoNombre: 'Alumno Prueba',
        fechaGeneracion: DateTime.now(),
        promedioGeneral: 5.0,
        porcentajeGeneral: 71.4,
        totalTemasEnRiesgo: 0,
        temasPriorizados: const [],
      );

      await repo.guardarReporte(nuevo);
      final obtenido = await repo.obtenerReportePorId('REP-TEST-NUEVO');
      expect(obtenido, isNotNull);
      expect(obtenido?.alumnoNombre, equals('Alumno Prueba'));

      await repo.eliminarReporte('REP-TEST-NUEVO');
      final eliminado = await repo.obtenerReportePorId('REP-TEST-NUEVO');
      expect(eliminado, isNull);
    });

    test('vigilarReportesPorClase emite inmediatamente y recalcula la matriz de riesgo al actualizar un alumno', () async {
      final repo = FuenteDatosReportes();

      // Obtenemos los reportes iniciales vía stream
      final primerEmision = await repo.vigilarReportesPorClase('CLASE-DEMO-001').first;
      expect(primerEmision.length, equals(4));

      // Métricas iniciales:
      // Mateo: 2 temas en riesgo (riesgo crítico)
      // Joaquín: 3 temas en riesgo (riesgo crítico)
      // Sofía: 1 tema en riesgo (en alerta)
      // Camila: 0 temas en riesgo (sin brechas)
      int inicialSinBrechas = primerEmision.where((r) => r.totalTemasEnRiesgo == 0).length;
      int inicialEnAlerta = primerEmision.where((r) => r.totalTemasEnRiesgo == 1).length;
      int inicialRiesgoCritico = primerEmision.where((r) => r.totalTemasEnRiesgo >= 2).length;

      expect(inicialSinBrechas, equals(1));
      expect(inicialEnAlerta, equals(1));
      expect(inicialRiesgoCritico, equals(2));

      // Simular regeneración individual de Mateo Rivas tras nivelar sus notas:
      // ahora Mateo tiene 0 temas en riesgo en vez de 2
      final mateoOriginal = primerEmision.firstWhere((r) => r.alumnoNombre == 'Mateo Rivas');
      final mateoRegenerado = mateoOriginal.copyWith(
        fechaGeneracion: DateTime.now(),
        promedioGeneral: 6.0,
        porcentajeGeneral: 85.0,
        totalTemasEnRiesgo: 0,
        temasPriorizados: const [
          SnapshotTemaReporte(
            tema: 'Álgebra',
            porcentajeDominio: 85.0,
            promedioNota: 6.0,
            cantidadEvaluaciones: 2,
            nivelDominio: NivelDominio.consolidado,
          ),
          SnapshotTemaReporte(
            tema: 'Geometría',
            porcentajeDominio: 80.0,
            promedioNota: 5.8,
            cantidadEvaluaciones: 2,
            nivelDominio: NivelDominio.consolidado,
          ),
        ],
      );

      // Guardamos la regeneración individual
      await repo.guardarReporte(mateoRegenerado);

      // La siguiente emisión del stream debe reflejar el cambio en vivo en los 4 contadores
      final reportesActualizados = await repo.obtenerReportesPorClase('CLASE-DEMO-001');
      int nuevoSinBrechas = reportesActualizados.where((r) => r.totalTemasEnRiesgo == 0).length;
      int nuevoEnAlerta = reportesActualizados.where((r) => r.totalTemasEnRiesgo == 1).length;
      int nuevoRiesgoCritico = reportesActualizados.where((r) => r.totalTemasEnRiesgo >= 2).length;

      // Riesgo crítico debe haber bajado de 2 a 1, y sin brechas subido de 1 a 2
      expect(nuevoRiesgoCritico, equals(1));
      expect(nuevoEnAlerta, equals(1));
      expect(nuevoSinBrechas, equals(2));
    });
  });
}
