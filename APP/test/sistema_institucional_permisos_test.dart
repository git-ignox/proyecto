import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/datos/fuente_datos_auditoria.dart';
import 'package:proyecto/datos/fuente_datos_politicas.dart';
import 'package:proyecto/datos/fuente_datos_sesiones_clase.dart';
import 'package:proyecto/dominio/modelos/permiso_institucional.dart';
import 'package:proyecto/dominio/modelos/politica_dispositivo.dart';
import 'package:proyecto/dominio/modelos/sesion_modo_clase.dart';
import 'package:proyecto/dominio/modelos/usuario_app.dart';

void main() {
  group('Sistema de Permisos y Autoridad de Backend', () {
    late FuenteDatosPoliticas repoPoliticas;
    late FuenteDatosAuditoria repoAuditoria;
    late FuenteDatosSesionesClase repoSesiones;

    setUp(() {
      repoPoliticas = FuenteDatosPoliticas();
      repoAuditoria = FuenteDatosAuditoria();
      repoSesiones = FuenteDatosSesionesClase(
        repositorioPoliticas: repoPoliticas,
        repositorioAuditoria: repoAuditoria,
      );
    });

    test('Alumno no tiene permisos de administración ni control', () {
      const alumno = UsuarioApp(
        uid: 'alu-01',
        nombre: 'Estudiante',
        rol: RolUsuario.alumno,
      );

      expect(alumno.tienePermiso(PermisoInstitucional.activarModoClase), isFalse);
      expect(alumno.tienePermiso(PermisoInstitucional.activarModoExamen), isFalse);
      expect(alumno.tienePermiso(PermisoInstitucional.administrarInstitucion), isFalse);
      expect(alumno.tienePermiso(PermisoInstitucional.permitirAppTemporalmente), isFalse);
    });

    test('Profesor sin permiso explícito NO puede activar Modo Examen', () async {
      const profesorSinExamen = UsuarioApp(
        uid: 'prof-basico',
        nombre: 'Profesor Sin Examen',
        rol: RolUsuario.profesor,
        permisosEspecificos: [], // No tiene activarModoExamen
      );

      expect(profesorSinExamen.tienePermiso(PermisoInstitucional.activarModoExamen), isFalse);

      // Comprobación de Backend: debe rechazar la creación
      expect(
        () async => await repoSesiones.iniciarSesion(
          claseId: 'CLASE-1',
          cursoNombre: 'Curso 1',
          materia: 'Matemáticas',
          docente: profesorSinExamen,
          tipoModo: TipoModoClase.examen,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Profesor con permiso explícito SÍ puede activar Modo Examen', () async {
      const profesorConExamen = UsuarioApp(
        uid: 'prof-autorizado',
        nombre: 'Profesor Autorizado',
        rol: RolUsuario.profesor,
        permisosEspecificos: [PermisoInstitucional.activarModoExamen],
      );

      expect(profesorConExamen.tienePermiso(PermisoInstitucional.activarModoExamen), isTrue);

      final sesion = await repoSesiones.iniciarSesion(
        claseId: 'CLASE-2',
        cursoNombre: 'Curso 2',
        materia: 'Historia',
        docente: profesorConExamen,
        tipoModo: TipoModoClase.examen,
      );

      expect(sesion.tipoModo, equals(TipoModoClase.examen));
      expect(sesion.estado, equals(EstadoSesionModo.activa));
    });

    test('Profesor no puede modificar ni guardar políticas institucionales en backend', () async {
      const profesor = UsuarioApp(
        uid: 'prof-01',
        nombre: 'Profesor Común',
        rol: RolUsuario.profesor,
      );

      final nuevaPolitica = PlantillaPolitica.modoClaseEstandar(
        institucionId: 'INST-SAN-MARTIN',
        id: 'POL-HACK',
      );

      // Backend debe impedir que un profesor guarde la política
      expect(
        () async => await repoPoliticas.guardarPolitica(
          nuevaPolitica,
          usuario: profesor,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Profesor con permiso puede conceder excepción temporal de app', () async {
      const profesorConExcepcion = UsuarioApp(
        uid: 'prof-exc',
        nombre: 'Profesor con Excepción',
        rol: RolUsuario.profesor,
        permisosEspecificos: [PermisoInstitucional.permitirAppTemporalmente],
      );

      final sesion = await repoSesiones.iniciarSesion(
        claseId: 'CLASE-3',
        cursoNombre: 'Curso 3',
        materia: 'Física',
        docente: profesorConExcepcion,
        tipoModo: TipoModoClase.clase,
      );

      await repoSesiones.concederExcepcionTemporal(
        sesionId: sesion.id,
        docente: profesorConExcepcion,
        appId: 'app_youtube',
        appNombre: 'YouTube Educativo',
        minutos: 10,
        motivo: 'Ver documental de gravedad',
      );

      final sesionActualizada = await repoSesiones.obtenerSesionActivaPorClase('CLASE-3');
      expect(sesionActualizada!.excepcionesTemporales.length, equals(1));
      expect(sesionActualizada.excepcionesTemporales.first.appNombre, equals('YouTube Educativo'));
      expect(sesionActualizada.excepcionesTemporales.first.minutosValidez, equals(10));
      expect(sesionActualizada.excepcionesTemporales.first.estaVigente, isTrue);
    });
  });
}
