import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/datos/coordinador_sincronizacion_offline.dart';
import 'package:proyecto/datos/fuente_datos_materiales_offline.dart';
import 'package:proyecto/dominio/modelos/recurso_educativo_offline.dart';

void main() {
  group('CoordinadorSincronizacionOffline (Resiliencia y Descargas en Segundo Plano)', () {
    late FuenteDatosMaterialesOffline repo;
    late CoordinadorSincronizacionOffline coordinador;
    final ahora = DateTime(2026, 9, 21, 9, 0);

    setUp(() {
      final recursoPendiente = RecursoEducativoOffline(
        id: 'rec-test-01',
        claseId: 'c1',
        materia: 'Matemáticas',
        titulo: 'Guía de Prueba',
        descripcion: 'Descarga resiliente',
        tipoRecurso: TipoRecursoEducativo.pdf,
        remoteUrl: 'https://cdn.com/test_guia.pdf',
        localPath: null, // Pendiente
        tamanoBytes: 3 * 1024 * 1024, // 3 MB
        checksumSha256: 'sha256_valido_123',
        esObligatorio: true,
        fechaUsoClase: ahora.add(const Duration(hours: 20)),
      );

      repo = FuenteDatosMaterialesOffline(
        materialesIniciales: [recursoPendiente],
      );

      coordinador = CoordinadorSincronizacionOffline(
        repositorio: repo,
        condicionesIniciales: const CondicionesDispositivo(
          hayWifi: true,
          bateriaPorcentaje: 70,
          estaCargando: false,
          dispositivoInactivo: true,
        ),
      );
    });

    test('Condiciones de hardware restringen la sincronización en background', () {
      // Con WiFi y 70% batería -> permitido
      expect(coordinador.condiciones.permiteDescargaEnSegundoPlano, isTrue);

      // Sin WiFi -> bloqueado
      const sinWifi = CondicionesDispositivo(
        hayWifi: false,
        bateriaPorcentaje: 70,
        estaCargando: false,
      );
      expect(sinWifi.permiteDescargaEnSegundoPlano, isFalse);
      expect(sinWifi.causaBloqueo, equals(CausaPausa.sinWifi));

      // Con WiFi pero batería 10% sin cargar -> bloqueado
      const bateriaBaja = CondicionesDispositivo(
        hayWifi: true,
        bateriaPorcentaje: 10,
        estaCargando: false,
      );
      expect(bateriaBaja.permiteDescargaEnSegundoPlano, isFalse);
      expect(bateriaBaja.causaBloqueo, equals(CausaPausa.bateriaBaja));

      // Con WiFi y batería 10% PERO cargando -> permitido
      const cargando = CondicionesDispositivo(
        hayWifi: true,
        bateriaPorcentaje: 10,
        estaCargando: true,
      );
      expect(cargando.permiteDescargaEnSegundoPlano, isTrue);
    });

    test('Descarga automática en background se completa sin confirmación manual', () async {
      final tareaInicial = await repo.obtenerTarea('rec-test-01');
      expect(tareaInicial?.estado, equals(EstadoSincronizacion.pendiente));

      // Ejecutar ciclo
      await coordinador.procesarColaDescargas(ahora: ahora);

      final tareaFinal = await repo.obtenerTarea('rec-test-01');
      expect(tareaFinal?.estado, equals(EstadoSincronizacion.completado));
      expect(tareaFinal?.bytesDescargados, equals(3 * 1024 * 1024));

      final recursoActualizado = await repo.obtenerMaterialPorId('rec-test-01');
      expect(recursoActualizado?.estaDescargado, isTrue);
      expect(recursoActualizado?.localPath, contains('test_guia.pdf'));
    });

    test('Pausa y reanudación resiliente conserva bytes descargados ante corte de WiFi', () async {
      // Iniciar con tarea parcialmente descargada (1 MB ya obtenido)
      await repo.actualizarTareaSincronizacion(
        TareaSincronizacion(
          recursoId: 'rec-test-01',
          estado: EstadoSincronizacion.pausado,
          causaPausa: CausaPausa.sinWifi,
          bytesDescargados: 1024 * 1024, // 1 MB
          totalBytes: 3 * 1024 * 1024,
          fechaActualizacion: DateTime.now(),
        ),
      );

      // Simular que no hay WiFi: el procesador no debe descargar
      await coordinador.actualizarCondicionesDispositivo(
        const CondicionesDispositivo(
          hayWifi: false,
          bateriaPorcentaje: 80,
          estaCargando: false,
        ),
      );

      await coordinador.procesarColaDescargas(ahora: ahora);
      var tarea = await repo.obtenerTarea('rec-test-01');
      expect(tarea?.bytesDescargados, equals(1024 * 1024)); // Intacto en 1 MB

      // Vuelve el WiFi
      await coordinador.actualizarCondicionesDispositivo(
        const CondicionesDispositivo(
          hayWifi: true,
          bateriaPorcentaje: 80,
          estaCargando: false,
        ),
      );

      // Esperar a que el ciclo complete la descarga desde el offset previo
      await coordinador.procesarColaDescargas(ahora: ahora);
      tarea = await repo.obtenerTarea('rec-test-01');
      expect(tarea?.estado, equals(EstadoSincronizacion.completado));
      expect(tarea?.bytesDescargados, equals(3 * 1024 * 1024));
    });

    test('Falla de integridad criptográfica detecta archivo corrupto', () async {
      final recursoCorrupto = RecursoEducativoOffline(
        id: 'rec-corrupto',
        claseId: 'c1',
        materia: 'Historia',
        titulo: 'Archivo Corrupto',
        descripcion: 'Checksum incorrecto',
        tipoRecurso: TipoRecursoEducativo.pdf,
        remoteUrl: 'https://cdn.com/corrupto.pdf',
        tamanoBytes: 1024 * 1024,
        checksumSha256: 'invalido_bad_checksum',
        esObligatorio: true,
        fechaUsoClase: ahora.add(const Duration(hours: 10)),
      );

      await repo.guardarMaterial(recursoCorrupto);
      await coordinador.procesarColaDescargas(ahora: ahora);

      final tarea = await repo.obtenerTarea('rec-corrupto');
      expect(tarea?.estado, equals(EstadoSincronizacion.errorIntegridad));
      expect(tarea?.ultimoError, contains('checksum'));

      final material = await repo.obtenerMaterialPorId('rec-corrupto');
      expect(material?.estaDescargado, isFalse);
    });
  });
}
