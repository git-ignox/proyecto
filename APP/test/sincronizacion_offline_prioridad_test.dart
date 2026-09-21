import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/dominio/modelos/recurso_educativo_offline.dart';
import 'package:proyecto/dominio/sincronizacion/motor_prioridad_sincronizacion.dart';

void main() {
  group('MotorPrioridadSincronizacion (Cola con Prioridad y Cobertura Amplia)', () {
    late MotorPrioridadSincronizacion motor;
    final ahora = DateTime(2026, 9, 21, 8, 0); // Lunes 8:00 AM

    setUp(() {
      motor = const MotorPrioridadSincronizacion();
    });

    test('Material de clase en las próximas 24h tiene W_time máximo (100.0)', () {
      final guiaManana = RecursoEducativoOffline(
        id: 'guia-1',
        claseId: 'clase-1',
        materia: 'Matemáticas',
        titulo: 'Guía de Mañana',
        descripcion: 'Ejercicios',
        tipoRecurso: TipoRecursoEducativo.pdf,
        remoteUrl: 'https://cdn.com/g1.pdf',
        tamanoBytes: 2 * 1024 * 1024, // 2 MB
        checksumSha256: 'hash_valido',
        esObligatorio: true,
        fechaUsoClase: ahora.add(const Duration(hours: 12)), // Hoy a las 20:00
      );

      final puntaje = motor.calcularPuntaje(guiaManana, ahora: ahora);
      expect(puntaje.pesoTemporal, equals(100.0));
      expect(puntaje.pesoRequerido, equals(3.0));
    });

    test('Material obligatorio tiene triple peso que material opcional con misma fecha y tamaño', () {
      final fecha = ahora.add(const Duration(hours: 10));

      final obligatorio = RecursoEducativoOffline(
        id: 'req-1',
        claseId: 'c1',
        materia: 'Física',
        titulo: 'Guía Obligatoria',
        descripcion: 'Test',
        tipoRecurso: TipoRecursoEducativo.pdf,
        remoteUrl: 'https://cdn.com/req.pdf',
        tamanoBytes: 5 * 1024 * 1024,
        checksumSha256: 'hash1',
        esObligatorio: true,
        fechaUsoClase: fecha,
      );

      final opcional = obligatorio.copyWith(
        id: 'opc-1',
        esObligatorio: false,
      );

      final puntajeReq = motor.calcularPuntaje(obligatorio, ahora: ahora);
      final puntajeOpc = motor.calcularPuntaje(opcional, ahora: ahora);

      expect(puntajeReq.puntajeTotal, closeTo(puntajeOpc.puntajeTotal * 3.0, 0.001));
    });

    test('Favorece cobertura amplia: archivo liviano esencial de mañana supera a video gigante de mañana', () {
      final fechaManana = ahora.add(const Duration(hours: 18));

      // PDF de 1.5 MB para mañana
      final pdfGuia = RecursoEducativoOffline(
        id: 'pdf-guia',
        claseId: 'c1',
        materia: 'Matemáticas',
        titulo: 'Guía de Fracciones',
        descripcion: 'Esencial',
        tipoRecurso: TipoRecursoEducativo.pdf,
        remoteUrl: 'https://cdn.com/guia.pdf',
        tamanoBytes: (1.5 * 1024 * 1024).round(),
        checksumSha256: 'h_pdf',
        esObligatorio: true,
        fechaUsoClase: fechaManana,
      );

      // Video de 150 MB para mañana (mismo día y también obligatorio)
      final videoGigante = RecursoEducativoOffline(
        id: 'video-gigante',
        claseId: 'c1',
        materia: 'Matemáticas',
        titulo: 'Grabación de la clase completa',
        descripcion: 'Video HD',
        tipoRecurso: TipoRecursoEducativo.video,
        remoteUrl: 'https://cdn.com/video.mp4',
        tamanoBytes: 150 * 1024 * 1024,
        checksumSha256: 'h_vid',
        esObligatorio: true,
        fechaUsoClase: fechaManana,
      );

      final puntajePdf = motor.calcularPuntaje(pdfGuia, ahora: ahora);
      final puntajeVideo = motor.calcularPuntaje(videoGigante, ahora: ahora);

      // El PDF liviano debe ganar por mucho en prioridad para asegurar que el alumno tenga material
      expect(puntajePdf.puntajeTotal, greaterThan(puntajeVideo.puntajeTotal * 5.0));
    });

    test('ordenarCola coloca primero los materiales que garantizan mayor preparación', () {
      final fechaHoy = ahora.add(const Duration(hours: 4));
      final fechaViernes = ahora.add(const Duration(days: 4));

      final r1 = RecursoEducativoOffline(
        id: 'r1-video-viernes',
        claseId: 'c1',
        materia: 'Historia',
        titulo: 'Documental Largo',
        descripcion: 'Viernes',
        tipoRecurso: TipoRecursoEducativo.video,
        remoteUrl: 'https://cdn.com/v.mp4',
        tamanoBytes: 200 * 1024 * 1024,
        checksumSha256: 'h1',
        esObligatorio: false,
        fechaUsoClase: fechaViernes,
      );

      final r2 = RecursoEducativoOffline(
        id: 'r2-pdf-hoy',
        claseId: 'c1',
        materia: 'Matemáticas',
        titulo: 'Guía Rápida Hoy',
        descripcion: 'Hoy',
        tipoRecurso: TipoRecursoEducativo.pdf,
        remoteUrl: 'https://cdn.com/hoy.pdf',
        tamanoBytes: 1024 * 1024,
        checksumSha256: 'h2',
        esObligatorio: true,
        fechaUsoClase: fechaHoy,
      );

      final r3 = RecursoEducativoOffline(
        id: 'r3-web-manana',
        claseId: 'c1',
        materia: 'Ciencias',
        titulo: 'Página Web MHTML',
        descripcion: 'Mañana',
        tipoRecurso: TipoRecursoEducativo.paginaWebMhtml,
        remoteUrl: 'https://cdn.com/web.mhtml',
        tamanoBytes: 2 * 1024 * 1024,
        checksumSha256: 'h3',
        esObligatorio: true,
        fechaUsoClase: ahora.add(const Duration(hours: 20)),
      );

      final ordenados = motor.ordenarCola([r1, r2, r3], ahora: ahora);

      expect(ordenados.first.id, equals('r2-pdf-hoy'));
      expect(ordenados[1].id, equals('r3-web-manana'));
      expect(ordenados.last.id, equals('r1-video-viernes'));
    });
  });
}
