import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/dominio/modelos/recurso_educativo_offline.dart';
import 'package:proyecto/dominio/sincronizacion/gestor_limpieza_segura.dart';

void main() {
  group('GestorLimpiezaSegura (Las 5 Leyes Inviolables de Retención)', () {
    late GestorLimpiezaSegura gestor;
    final ahora = DateTime(2026, 9, 21, 10, 0);

    setUp(() {
      gestor = const GestorLimpiezaSegura(
        horasVentanaSagrada: 48,
        umbralLiberacionSignificativaBytes: 50 * 1024 * 1024, // 50 MB para tests
      );
    });

    test('REGLA 1: Aborta determinísticamente si no hay internet (cero archivos borrados)', () {
      final materialAntiguo = RecursoEducativoOffline(
        id: 'antiguo-1',
        claseId: 'c1',
        materia: 'Historia',
        titulo: 'Guía Pasada',
        descripcion: 'Antigua',
        tipoRecurso: TipoRecursoEducativo.pdf,
        remoteUrl: 'https://cdn.com/a.pdf',
        localPath: '/data/a.pdf',
        tamanoBytes: 10 * 1024 * 1024,
        checksumSha256: 'h1',
        esObligatorio: true,
        fechaUsoClase: ahora.subtract(const Duration(days: 30)),
        ultimoAcceso: ahora.subtract(const Duration(days: 28)),
        diasRetencion: 7,
      );

      final resultado = gestor.ejecutarLimpieza(
        recursos: [materialAntiguo],
        hayInternet: false, // SIN INTERNET
        confirmadoPorUsuario: true,
        ahora: ahora,
      );

      expect(resultado.exitosa, isFalse);
      expect(resultado.abortadaPorSinInternet, isTrue);
      expect(resultado.bytesLiberados, equals(0));
      expect(resultado.archivosEliminados, isEmpty);
    });

    test('REGLA 2: NUNCA elimina contenido de las próximas 24-48 horas ni clases de hoy', () {
      final materialHoy = RecursoEducativoOffline(
        id: 'mat-hoy',
        claseId: 'c1',
        materia: 'Matemáticas',
        titulo: 'Guía de Hoy',
        descripcion: 'Para hoy',
        tipoRecurso: TipoRecursoEducativo.pdf,
        remoteUrl: 'https://cdn.com/hoy.pdf',
        localPath: '/data/hoy.pdf',
        tamanoBytes: 2 * 1024 * 1024,
        checksumSha256: 'h_hoy',
        esObligatorio: true,
        fechaUsoClase: ahora.add(const Duration(hours: 4)), // En 4 horas
        diasRetencion: 1,
      );

      final materialManana = RecursoEducativoOffline(
        id: 'mat-manana',
        claseId: 'c1',
        materia: 'Ciencias',
        titulo: 'Laboratorio de Mañana',
        descripcion: 'Para mañana',
        tipoRecurso: TipoRecursoEducativo.pdf,
        remoteUrl: 'https://cdn.com/manana.pdf',
        localPath: '/data/manana.pdf',
        tamanoBytes: 3 * 1024 * 1024,
        checksumSha256: 'h_manana',
        esObligatorio: true,
        fechaUsoClase: ahora.add(const Duration(hours: 26)), // En 26 horas (< 48h)
        diasRetencion: 1,
      );

      final analisis = gestor.evaluarCandidatos(
        recursos: [materialHoy, materialManana],
        hayInternet: true,
        ahora: ahora,
      );

      expect(analisis.candidatos, isEmpty);
      expect(analisis.bytesALiberar, equals(0));
    });

    test('REGLA 3: NUNCA elimina archivos marcados como fijados / intocables por el usuario', () {
      final materialFijadoAntiguo = RecursoEducativoOffline(
        id: 'fijado-intocable',
        claseId: 'c1',
        materia: 'Matemáticas',
        titulo: 'Fórmulas Anuales (Intocable)',
        descripcion: 'Formulario de consulta permanente',
        tipoRecurso: TipoRecursoEducativo.pdf,
        remoteUrl: 'https://cdn.com/formulas.pdf',
        localPath: '/data/formulas.pdf',
        tamanoBytes: 15 * 1024 * 1024,
        checksumSha256: 'h_formulas',
        esObligatorio: true,
        esFijado: true, // INTOCABLE
        fechaUsoClase: ahora.subtract(const Duration(days: 60)), // Hace 2 meses
        ultimoAcceso: ahora.subtract(const Duration(days: 50)),
        diasRetencion: 7,
      );

      final analisis = gestor.evaluarCandidatos(
        recursos: [materialFijadoAntiguo],
        hayInternet: true,
        ahora: ahora,
      );

      expect(analisis.candidatos, isEmpty);
      expect(analisis.bytesALiberar, equals(0));
    });

    test('REGLA 4: Prioriza desalojar lo más antiguo y ya visto por el estudiante', () {
      // Archivo de hace 20 días que ya fue visto
      final archivoVistoAntiguo = RecursoEducativoOffline(
        id: 'visto-antiguo',
        claseId: 'c1',
        materia: 'Historia',
        titulo: 'Lectura Semana 1',
        descripcion: 'Visto',
        tipoRecurso: TipoRecursoEducativo.pdf,
        remoteUrl: 'https://cdn.com/s1.pdf',
        localPath: '/data/s1.pdf',
        tamanoBytes: 5 * 1024 * 1024,
        checksumSha256: 'h1',
        esObligatorio: true,
        fechaUsoClase: ahora.subtract(const Duration(days: 20)),
        ultimoAcceso: ahora.subtract(const Duration(days: 18)),
        diasRetencion: 7,
      );

      // Archivo de hace 10 días que NO ha sido visto
      final archivoNoVisto = RecursoEducativoOffline(
        id: 'no-visto',
        claseId: 'c1',
        materia: 'Física',
        titulo: 'Lectura Semana 2',
        descripcion: 'No visto',
        tipoRecurso: TipoRecursoEducativo.pdf,
        remoteUrl: 'https://cdn.com/s2.pdf',
        localPath: '/data/s2.pdf',
        tamanoBytes: 5 * 1024 * 1024,
        checksumSha256: 'h2',
        esObligatorio: true,
        fechaUsoClase: ahora.subtract(const Duration(days: 10)),
        ultimoAcceso: null, // No visto
        diasRetencion: 7,
      );

      final puntajeVisto =
          gestor.calcularPuntajeDesalojo(archivoVistoAntiguo, ahora: ahora);
      final puntajeNoVisto =
          gestor.calcularPuntajeDesalojo(archivoNoVisto, ahora: ahora);

      expect(puntajeVisto, greaterThan(puntajeNoVisto));

      final analisis = gestor.evaluarCandidatos(
        recursos: [archivoNoVisto, archivoVistoAntiguo],
        hayInternet: true,
        ahora: ahora,
      );

      expect(analisis.candidatos.first.id, equals('visto-antiguo'));
    });

    test('REGLA 5: Avisa y requiere confirmación previa si la liberación supera el umbral significativo', () {
      final archivoPesadoAntiguo = RecursoEducativoOffline(
        id: 'video-antiguo',
        claseId: 'c1',
        materia: 'Biología',
        titulo: 'Video Antiguo Unidad 1',
        descripcion: '60 MB',
        tipoRecurso: TipoRecursoEducativo.video,
        remoteUrl: 'https://cdn.com/video_u1.mp4',
        localPath: '/data/video_u1.mp4',
        tamanoBytes: 60 * 1024 * 1024, // 60 MB (> 50 MB umbral)
        checksumSha256: 'h_vid_u1',
        esObligatorio: false,
        fechaUsoClase: ahora.subtract(const Duration(days: 25)),
        ultimoAcceso: ahora.subtract(const Duration(days: 20)),
        diasRetencion: 7,
      );

      // Intento sin confirmación del usuario
      final resultadoSinConfirmar = gestor.ejecutarLimpieza(
        recursos: [archivoPesadoAntiguo],
        hayInternet: true,
        confirmadoPorUsuario: false,
        ahora: ahora,
      );

      expect(resultadoSinConfirmar.exitosa, isFalse);
      expect(resultadoSinConfirmar.requiereConfirmacionPrevia, isTrue);
      expect(resultadoSinConfirmar.bytesLiberados, equals(0));

      // Intento con confirmación del usuario
      final resultadoConfirmado = gestor.ejecutarLimpieza(
        recursos: [archivoPesadoAntiguo],
        hayInternet: true,
        confirmadoPorUsuario: true,
        ahora: ahora,
      );

      expect(resultadoConfirmado.exitosa, isTrue);
      expect(resultadoConfirmado.requiereConfirmacionPrevia, isFalse);
      expect(resultadoConfirmado.bytesLiberados, equals(60 * 1024 * 1024));
      expect(resultadoConfirmado.archivosEliminados.first.id, equals('video-antiguo'));
    });
  });
}
