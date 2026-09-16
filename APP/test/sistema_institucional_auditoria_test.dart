import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/datos/fuente_datos_auditoria.dart';
import 'package:proyecto/datos/fuente_datos_politicas.dart';
import 'package:proyecto/datos/fuente_datos_sesiones_clase.dart';
import 'package:proyecto/dominio/modelos/permiso_institucional.dart';
import 'package:proyecto/dominio/modelos/registro_auditoria.dart';
import 'package:proyecto/dominio/modelos/sesion_modo_clase.dart';
import 'package:proyecto/dominio/modelos/usuario_app.dart';

void main() {
  group('Trazabilidad y Auditoría Inmutable (Fase 11)', () {
    late FuenteDatosAuditoria repoAuditoria;
    late FuenteDatosPoliticas repoPoliticas;
    late FuenteDatosSesionesClase repoSesiones;

    setUp(() {
      repoAuditoria = FuenteDatosAuditoria();
      repoPoliticas = FuenteDatosPoliticas();
      repoSesiones = FuenteDatosSesionesClase(
        repositorioPoliticas: repoPoliticas,
        repositorioAuditoria: repoAuditoria,
      );
    });

    test('Inicio de Modo Clase genera evento de auditoría', () async {
      const docente = UsuarioApp(
        uid: 'prof-auditoria',
        nombre: 'Docente Auditoría',
        rol: RolUsuario.profesor,
        institucionId: 'INST-SAN-MARTIN',
      );

      final sesion = await repoSesiones.iniciarSesion(
        claseId: 'CLASE-AUD-1',
        cursoNombre: '4° Básico',
        materia: 'Ciencias',
        docente: docente,
        tipoModo: TipoModoClase.clase,
      );
      expect(sesion.id, isNotEmpty);

      final eventos = await repoAuditoria.obtenerEventosPorInstitucion('INST-SAN-MARTIN');
      final eventoInicio = eventos.firstWhere((e) => e.tipo == TipoEventoAuditoria.inicioModoClase);

      expect(eventoInicio.usuarioUid, equals('prof-auditoria'));
      expect(eventoInicio.usuarioNombre, equals('Docente Auditoría'));
      expect(eventoInicio.cursoId, equals('CLASE-AUD-1'));
      expect(eventoInicio.descripcion, contains('inició'));
    });

    test('Fin de Modo Clase genera evento de auditoría con duración', () async {
      const docente = UsuarioApp(
        uid: 'prof-auditoria-2',
        nombre: 'Docente Auditoría 2',
        rol: RolUsuario.profesor,
        institucionId: 'INST-SAN-MARTIN',
      );

      final sesion = await repoSesiones.iniciarSesion(
        claseId: 'CLASE-AUD-2',
        cursoNombre: '4° Básico B',
        materia: 'Historia',
        docente: docente,
        tipoModo: TipoModoClase.clase,
      );

      await repoSesiones.finalizarSesion(sesionId: sesion.id, docente: docente);

      final eventos = await repoAuditoria.obtenerEventosPorInstitucion('INST-SAN-MARTIN');
      final eventoFin = eventos.firstWhere((e) => e.tipo == TipoEventoAuditoria.finModoClase);

      expect(eventoFin.usuarioUid, equals('prof-auditoria-2'));
      expect(eventoFin.descripcion, contains('finalizó'));
      expect(eventoFin.detalles['duracionMinutos'], isNotNull);
    });

    test('Activación de Emergencia Institucional genera evento crítico auditado', () async {
      const direccion = UsuarioApp(
        uid: 'dir-auditor',
        nombre: 'Directora Auditora',
        rol: RolUsuario.direccion,
        institucionId: 'INST-SAN-MARTIN',
      );

      await repoSesiones.suspenderRestriccionesEmergencia(
        institucionId: 'INST-SAN-MARTIN',
        direccion: direccion,
        motivo: 'Falla general de suministro eléctrico',
      );

      final eventos = await repoAuditoria.obtenerEventosPorInstitucion('INST-SAN-MARTIN');
      final eventoEmergencia = eventos.firstWhere((e) => e.tipo == TipoEventoAuditoria.activacionEmergencia);

      expect(eventoEmergencia.usuarioUid, equals('dir-auditor'));
      expect(eventoEmergencia.descripcion, contains('EMERGENCIA INSTITUCIONAL ACTIVADA'));
      expect(eventoEmergencia.detalles['motivo'], equals('Falla general de suministro eléctrico'));
    });

    test('Excepción temporal de app queda registrada con minutos y motivo', () async {
      const docente = UsuarioApp(
        uid: 'prof-auditoria-3',
        nombre: 'Profesor de Computación',
        rol: RolUsuario.profesor,
        institucionId: 'INST-SAN-MARTIN',
        permisosEspecificos: [PermisoInstitucional.permitirAppTemporalmente],
      );

      final sesion = await repoSesiones.iniciarSesion(
        claseId: 'CLASE-AUD-3',
        cursoNombre: 'Computación 6°',
        materia: 'Informática',
        docente: docente,
        tipoModo: TipoModoClase.clase,
      );

      await repoSesiones.concederExcepcionTemporal(
        sesionId: sesion.id,
        docente: docente,
        appId: 'app_geogebra',
        appNombre: 'GeoGebra 3D',
        minutos: 15,
        motivo: 'Taller de sólidos platónicos',
      );

      final eventos = await repoAuditoria.obtenerEventosPorInstitucion('INST-SAN-MARTIN');
      final eventoExcepcion = eventos.firstWhere((e) => e.tipo == TipoEventoAuditoria.excepcionTemporal);

      expect(eventoExcepcion.descripcion, contains('15 min'));
      expect(eventoExcepcion.descripcion, contains('GeoGebra 3D'));
      expect(eventoExcepcion.detalles['minutos'], equals(15));
    });
  });
}
